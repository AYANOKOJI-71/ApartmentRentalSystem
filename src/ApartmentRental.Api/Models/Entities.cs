namespace ApartmentRental.Api.Models;

public enum UserRole { Admin, Agent, Tenant }
public enum LeaseStatus { Draft, Active, Ended, Terminated }
public enum PaymentMethod { BankTransfer, Card, Cash, MobileBanking }
public enum MaintenanceCategory { Plumbing, Electrical, Appliance, Structural, Other }
public enum MaintenancePriority { Low, Medium, High, Emergency }
public enum MaintenanceStatus { Open, InProgress, Resolved, Cancelled }

public class AppUser
{
    public long Id { get; set; }
    public string Email { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public UserRole Role { get; set; }
    public long? TenantId { get; set; }
    public Tenant? Tenant { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

public class Property
{
    public long Id { get; set; }
    public string Name { get; set; } = "";
    public string StreetAddress { get; set; } = "";
    public string City { get; set; } = "";
    public string PostalCode { get; set; } = "";
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public List<Unit> Units { get; set; } = [];
}

public class Unit
{
    public long Id { get; set; }
    public long PropertyId { get; set; }
    public Property Property { get; set; } = null!;
    public string UnitNumber { get; set; } = "";
    public int FloorNumber { get; set; }
    public int Bedrooms { get; set; }
    public decimal Bathrooms { get; set; }
    public int SquareFeet { get; set; }
    public decimal ListedMonthlyRent { get; set; }
    public bool IsListed { get; set; } = true;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public List<Lease> Leases { get; set; } = [];
    public List<MaintenanceRequest> MaintenanceRequests { get; set; } = [];
}

public class Tenant
{
    public long Id { get; set; }
    public string FirstName { get; set; } = "";
    public string LastName { get; set; } = "";
    public string Email { get; set; } = "";
    public string? Phone { get; set; }
    public string? EmergencyContactName { get; set; }
    public string? EmergencyContactPhone { get; set; }
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public List<Lease> Leases { get; set; } = [];
}

public class Lease
{
    public long Id { get; set; }
    public long UnitId { get; set; }
    public Unit Unit { get; set; } = null!;
    public long TenantId { get; set; }
    public Tenant Tenant { get; set; } = null!;
    public DateOnly LeaseStart { get; set; }
    public DateOnly LeaseEnd { get; set; }
    public decimal MonthlyRent { get; set; }
    public decimal SecurityDeposit { get; set; }
    public LeaseStatus Status { get; set; } = LeaseStatus.Draft;
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public List<Payment> Payments { get; set; } = [];
}

public class Payment
{
    public long Id { get; set; }
    public long LeaseId { get; set; }
    public Lease Lease { get; set; } = null!;
    public DateOnly PaymentPeriod { get; set; }
    public DateOnly DueDate { get; set; }
    public decimal AmountDue { get; set; }
    public decimal AmountPaid { get; set; }
    public DateTime? PaidAtUtc { get; set; }
    public PaymentMethod? Method { get; set; }
    public string? ReferenceCode { get; set; }
    public string Status => AmountPaid >= AmountDue ? "paid" : AmountPaid > 0 ? "partial" : "unpaid";
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}

public class MaintenanceRequest
{
    public long Id { get; set; }
    public long UnitId { get; set; }
    public Unit Unit { get; set; } = null!;
    public long? ReportedByTenantId { get; set; }
    public Tenant? ReportedByTenant { get; set; }
    public MaintenanceCategory Category { get; set; }
    public MaintenancePriority Priority { get; set; } = MaintenancePriority.Medium;
    public string Description { get; set; } = "";
    public MaintenanceStatus Status { get; set; } = MaintenanceStatus.Open;
    public DateTime ReportedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAtUtc { get; set; }
}

public class AuditEvent
{
    public long Id { get; set; }
    public string ActorEmail { get; set; } = "";
    public string Action { get; set; } = "";
    public string ResourceType { get; set; } = "";
    public long? ResourceId { get; set; }
    public string PayloadJson { get; set; } = "{}";
    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
