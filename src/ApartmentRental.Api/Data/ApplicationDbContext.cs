using ApartmentRental.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace ApartmentRental.Api.Data;

public class ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<Property> Properties => Set<Property>();
    public DbSet<Unit> Units => Set<Unit>();
    public DbSet<Tenant> Tenants => Set<Tenant>();
    public DbSet<Lease> Leases => Set<Lease>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<MaintenanceRequest> MaintenanceRequests => Set<MaintenanceRequest>();
    public DbSet<AuditEvent> AuditEvents => Set<AuditEvent>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AppUser>(e =>
        {
            e.HasIndex(x => x.Email).IsUnique();
            e.Property(x => x.Email).HasMaxLength(254).IsRequired();
            e.Property(x => x.Role).HasConversion<string>().HasMaxLength(20);
            e.HasOne(x => x.Tenant).WithMany().HasForeignKey(x => x.TenantId).OnDelete(DeleteBehavior.SetNull);
        });
        modelBuilder.Entity<Property>(e =>
        {
            e.HasIndex(x => new { x.Name, x.StreetAddress, x.City }).IsUnique();
            e.Property(x => x.Name).HasMaxLength(120).IsRequired();
            e.Property(x => x.StreetAddress).HasMaxLength(180).IsRequired();
            e.Property(x => x.City).HasMaxLength(80).IsRequired();
            e.Property(x => x.PostalCode).HasMaxLength(20).IsRequired();
        });
        modelBuilder.Entity<Unit>(e =>
        {
            e.HasIndex(x => new { x.PropertyId, x.UnitNumber }).IsUnique();
            e.HasIndex(x => new { x.IsListed, x.ListedMonthlyRent });
            e.Property(x => x.ListedMonthlyRent).HasPrecision(12, 2);
            e.Property(x => x.Bathrooms).HasPrecision(3, 1);
            e.ToTable(t => t.HasCheckConstraint("CK_Units_Rent", "[ListedMonthlyRent] > 0"));
        });
        modelBuilder.Entity<Tenant>(e =>
        {
            e.HasIndex(x => x.Email).IsUnique();
            e.Property(x => x.Email).HasMaxLength(254).IsRequired();
        });
        modelBuilder.Entity<Lease>(e =>
        {
            e.HasIndex(x => new { x.UnitId, x.Status, x.LeaseStart, x.LeaseEnd });
            e.HasIndex(x => new { x.TenantId, x.Status });
            e.Property(x => x.Status).HasConversion<string>().HasMaxLength(20);
            e.Property(x => x.MonthlyRent).HasPrecision(12, 2);
            e.Property(x => x.SecurityDeposit).HasPrecision(12, 2);
            e.ToTable(t =>
            {
                t.HasCheckConstraint("CK_Leases_DateRange", "[LeaseEnd] > [LeaseStart]");
                t.HasCheckConstraint("CK_Leases_Rent", "[MonthlyRent] > 0");
                t.HasCheckConstraint("CK_Leases_Deposit", "[SecurityDeposit] >= 0");
            });
        });
        modelBuilder.Entity<Payment>(e =>
        {
            e.HasIndex(x => new { x.LeaseId, x.PaymentPeriod }).IsUnique();
            e.HasIndex(x => new { x.DueDate, x.PaidAtUtc });
            e.Property(x => x.AmountDue).HasPrecision(12, 2);
            e.Property(x => x.AmountPaid).HasPrecision(12, 2);
            e.Property(x => x.Method).HasConversion<string>().HasMaxLength(30);
            e.ToTable(t =>
            {
                t.HasCheckConstraint("CK_Payments_Due", "[AmountDue] > 0");
                t.HasCheckConstraint("CK_Payments_Paid", "[AmountPaid] >= 0 AND [AmountPaid] <= [AmountDue]");
            });
        });
        modelBuilder.Entity<MaintenanceRequest>(e =>
        {
            e.HasIndex(x => new { x.UnitId, x.Status, x.Priority });
            e.Property(x => x.Category).HasConversion<string>().HasMaxLength(30);
            e.Property(x => x.Priority).HasConversion<string>().HasMaxLength(20);
            e.Property(x => x.Status).HasConversion<string>().HasMaxLength(20);
            e.HasOne(x => x.ReportedByTenant).WithMany().HasForeignKey(x => x.ReportedByTenantId).OnDelete(DeleteBehavior.SetNull);
        });
        modelBuilder.Entity<AuditEvent>(e =>
        {
            e.HasIndex(x => x.CreatedAtUtc);
            e.Property(x => x.PayloadJson).HasColumnType("nvarchar(max)");
        });
    }
}
