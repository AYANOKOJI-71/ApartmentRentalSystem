using System.Security.Claims;
using System.Text.Json;
using ApartmentRental.Api.Contracts;
using ApartmentRental.Api.Data;
using ApartmentRental.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace ApartmentRental.Api.Services;

public class RentalService(ApplicationDbContext db)
{
    public async Task<List<PropertySearchResult>> SearchAsync(PropertySearchRequest request)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow);
        var query = db.Units.AsNoTracking().Include(x => x.Property).Include(x => x.Leases).Include(x => x.MaintenanceRequests).AsQueryable();
        if (request.ListedOnly) query = query.Where(x => x.IsListed);
        if (!string.IsNullOrWhiteSpace(request.City)) query = query.Where(x => x.Property.City == request.City);
        if (request.Bedrooms.HasValue) query = query.Where(x => x.Bedrooms >= request.Bedrooms.Value);
        if (request.MaxRent.HasValue) query = query.Where(x => x.ListedMonthlyRent <= request.MaxRent.Value);
        if (!string.IsNullOrWhiteSpace(request.Query))
        {
            var q = request.Query.Trim();
            query = query.Where(x => x.Property.Name.Contains(q) || x.Property.City.Contains(q) || x.UnitNumber.Contains(q));
        }
        var units = await query.OrderBy(x => x.ListedMonthlyRent).ThenBy(x => x.Property.Name).ThenBy(x => x.UnitNumber).ToListAsync();
        return units.Select(x =>
        {
            var activeLease = x.Leases.FirstOrDefault(l => l.Status == LeaseStatus.Active && today >= l.LeaseStart && today <= l.LeaseEnd);
            var maintenance = x.MaintenanceRequests.Any(m => m.Status is MaintenanceStatus.Open or MaintenanceStatus.InProgress);
            var status = activeLease != null ? "occupied" : maintenance ? "maintenance_review" : x.IsListed ? "available" : "off_market";
            return new PropertySearchResult(x.Id, x.PropertyId, x.Property.Name, x.Property.StreetAddress, x.Property.City, x.UnitNumber, x.FloorNumber, x.Bedrooms, x.Bathrooms, x.SquareFeet, x.ListedMonthlyRent, status, activeLease?.LeaseEnd);
        }).Where(x => request.ListedOnly ? x.AvailabilityStatus is "available" or "maintenance_review" or "occupied" : true).ToList();
    }

    public async Task<List<LeaseDto>> GetLeasesAsync(ClaimsPrincipal user)
    {
        var query = db.Leases.AsNoTracking().Include(x => x.Unit).Include(x => x.Tenant).AsQueryable();
        if (user.IsInRole(nameof(UserRole.Tenant)))
        {
            var tenantId = TenantId(user);
            query = query.Where(x => x.TenantId == tenantId);
        }
        return await query.OrderByDescending(x => x.LeaseStart).Select(x => new LeaseDto(x.Id, x.UnitId, x.Unit.UnitNumber, x.TenantId, x.Tenant.FirstName + " " + x.Tenant.LastName, x.LeaseStart, x.LeaseEnd, x.MonthlyRent, x.SecurityDeposit, x.Status.ToString())).ToListAsync();
    }

    public async Task<LeaseDto?> CreateLeaseAsync(ClaimsPrincipal user, CreateLeaseRequest request)
    {
        if (!user.IsInRole(nameof(UserRole.Admin)) && !user.IsInRole(nameof(UserRole.Agent))) return null;
        if (request.LeaseEnd <= request.LeaseStart || request.MonthlyRent <= 0 || request.SecurityDeposit < 0) throw new InvalidOperationException("Invalid lease terms.");
        var unit = await db.Units.FirstOrDefaultAsync(x => x.Id == request.UnitId) ?? throw new KeyNotFoundException("Unit not found.");
        var tenant = await db.Tenants.FirstOrDefaultAsync(x => x.Id == request.TenantId) ?? throw new KeyNotFoundException("Tenant not found.");
        var overlap = await db.Leases.AnyAsync(x => x.UnitId == unit.Id && (x.Status == LeaseStatus.Active || x.Status == LeaseStatus.Draft) && request.LeaseStart <= x.LeaseEnd && request.LeaseEnd >= x.LeaseStart);
        if (overlap) throw new InvalidOperationException("The unit already has an overlapping active or draft lease.");
        var lease = new Lease { UnitId = unit.Id, TenantId = tenant.Id, LeaseStart = request.LeaseStart, LeaseEnd = request.LeaseEnd, MonthlyRent = request.MonthlyRent, SecurityDeposit = request.SecurityDeposit, Status = LeaseStatus.Draft };
        db.Leases.Add(lease);
        await db.SaveChangesAsync();
        await AddAuditAsync(user, "lease.created", "lease", lease.Id, request);
        await db.SaveChangesAsync();
        return new LeaseDto(lease.Id, lease.UnitId, unit.UnitNumber, lease.TenantId, tenant.FirstName + " " + tenant.LastName, lease.LeaseStart, lease.LeaseEnd, lease.MonthlyRent, lease.SecurityDeposit, lease.Status.ToString());
    }

    public async Task<List<PaymentDto>> GetPaymentsAsync(ClaimsPrincipal user, long? leaseId = null)
    {
        var query = db.Payments.AsNoTracking().Include(x => x.Lease).ThenInclude(x => x.Tenant).AsQueryable();
        if (leaseId.HasValue) query = query.Where(x => x.LeaseId == leaseId.Value);
        if (user.IsInRole(nameof(UserRole.Tenant))) query = query.Where(x => x.Lease.TenantId == TenantId(user));
        return await query.OrderByDescending(x => x.DueDate).Select(x => new PaymentDto(x.Id, x.LeaseId, x.PaymentPeriod, x.DueDate, x.AmountDue, x.AmountPaid, x.AmountPaid >= x.AmountDue ? "paid" : x.AmountPaid > 0 ? "partial" : "unpaid", x.PaidAtUtc, x.Method.HasValue ? x.Method.Value.ToString() : null, x.ReferenceCode)).ToListAsync();
    }

    public async Task<PaymentDto?> RecordPaymentAsync(ClaimsPrincipal user, long leaseId, CreatePaymentRequest request)
    {
        var lease = await db.Leases.Include(x => x.Unit).FirstOrDefaultAsync(x => x.Id == leaseId) ?? throw new KeyNotFoundException("Lease not found.");
        if (user.IsInRole(nameof(UserRole.Tenant)) && lease.TenantId != TenantId(user)) return null;
        if (request.AmountDue <= 0 || request.AmountPaid < 0 || request.AmountPaid > request.AmountDue) throw new InvalidOperationException("Payment amounts are invalid.");
        await using var transaction = await db.Database.BeginTransactionAsync();
        var payment = await db.Payments.FirstOrDefaultAsync(x => x.LeaseId == leaseId && x.PaymentPeriod == request.PaymentPeriod);
        if (payment == null)
        {
            payment = new Payment { LeaseId = leaseId, PaymentPeriod = request.PaymentPeriod, DueDate = request.DueDate, AmountDue = request.AmountDue };
            db.Payments.Add(payment);
        }
        if (request.AmountPaid < payment.AmountPaid) throw new InvalidOperationException("A payment cannot reduce the amount already collected.");
        payment.DueDate = request.DueDate;
        payment.AmountDue = request.AmountDue;
        payment.AmountPaid = request.AmountPaid;
        payment.Method = request.Method;
        payment.ReferenceCode = request.ReferenceCode;
        payment.PaidAtUtc = request.AmountPaid > 0 ? DateTime.UtcNow : null;
        await db.SaveChangesAsync();
        await AddAuditAsync(user, "payment.recorded", "payment", payment.Id, request);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return new PaymentDto(payment.Id, payment.LeaseId, payment.PaymentPeriod, payment.DueDate, payment.AmountDue, payment.AmountPaid, payment.Status, payment.PaidAtUtc, payment.Method?.ToString(), payment.ReferenceCode);
    }

    public async Task<List<MaintenanceDto>> GetMaintenanceAsync(ClaimsPrincipal user)
    {
        var query = db.MaintenanceRequests.AsNoTracking().Include(x => x.Unit).AsQueryable();
        if (user.IsInRole(nameof(UserRole.Tenant))) query = query.Where(x => x.ReportedByTenantId == TenantId(user));
        return await query.OrderByDescending(x => x.Priority).ThenBy(x => x.ReportedAtUtc).Select(x => new MaintenanceDto(x.Id, x.UnitId, x.Unit.UnitNumber, x.Category.ToString(), x.Priority.ToString(), x.Status.ToString(), x.Description, x.ReportedAtUtc, x.ResolvedAtUtc)).ToListAsync();
    }

    public async Task<MaintenanceDto?> CreateMaintenanceAsync(ClaimsPrincipal user, CreateMaintenanceRequest request)
    {
        var unit = await db.Units.FirstOrDefaultAsync(x => x.Id == request.UnitId) ?? throw new KeyNotFoundException("Unit not found.");
        long? tenantId = user.IsInRole(nameof(UserRole.Tenant)) ? TenantId(user) : null;
        if (tenantId.HasValue && !await db.Leases.AnyAsync(x => x.UnitId == unit.Id && x.TenantId == tenantId.Value && x.Status == LeaseStatus.Active)) return null;
        var item = new MaintenanceRequest { UnitId = unit.Id, ReportedByTenantId = tenantId, Category = request.Category, Priority = request.Priority, Description = request.Description.Trim() };
        db.MaintenanceRequests.Add(item);
        await db.SaveChangesAsync();
        await AddAuditAsync(user, "maintenance.created", "maintenance", item.Id, request);
        await db.SaveChangesAsync();
        return new MaintenanceDto(item.Id, item.UnitId, unit.UnitNumber, item.Category.ToString(), item.Priority.ToString(), item.Status.ToString(), item.Description, item.ReportedAtUtc, item.ResolvedAtUtc);
    }

    public async Task<bool> UpdateMaintenanceAsync(ClaimsPrincipal user, long id, UpdateMaintenanceRequest request)
    {
        if (user.IsInRole(nameof(UserRole.Tenant))) return false;
        var item = await db.MaintenanceRequests.FindAsync(id);
        if (item == null) return false;
        item.Priority = request.Priority;
        item.Status = request.Status;
        item.ResolvedAtUtc = request.Status == MaintenanceStatus.Resolved ? DateTime.UtcNow : null;
        await AddAuditAsync(user, "maintenance.updated", "maintenance", item.Id, request);
        await db.SaveChangesAsync();
        return true;
    }

    public async Task<ReconciliationDto> DashboardAsync()
    {
        var billed = await db.Payments.SumAsync(x => (decimal?)x.AmountDue) ?? 0;
        var collected = await db.Payments.SumAsync(x => (decimal?)x.AmountPaid) ?? 0;
        return new ReconciliationDto(billed, collected, billed - collected, await db.MaintenanceRequests.CountAsync(x => (x.Status == MaintenanceStatus.Open || x.Status == MaintenanceStatus.InProgress)), await db.Leases.CountAsync(x => x.Status == LeaseStatus.Active));
    }

    private async Task AddAuditAsync(ClaimsPrincipal user, string action, string resourceType, long resourceId, object payload)
    {
        db.AuditEvents.Add(new AuditEvent { ActorEmail = user.Identity?.Name ?? "system", Action = action, ResourceType = resourceType, ResourceId = resourceId, PayloadJson = JsonSerializer.Serialize(payload) });
        await Task.CompletedTask;
    }

    private static long TenantId(ClaimsPrincipal user) => long.Parse(user.FindFirstValue("tenant_id") ?? user.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
}
