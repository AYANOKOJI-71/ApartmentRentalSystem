using ApartmentRental.Api.Models;
using BCrypt.Net;
using Microsoft.EntityFrameworkCore;

namespace ApartmentRental.Api.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(ApplicationDbContext db)
    {
        await db.Database.EnsureCreatedAsync();
        if (await db.Users.AnyAsync()) return;

        var amina = new Tenant { FirstName = "Amina", LastName = "Rahman", Email = "amina.rahman@example.test", Phone = "+8801700000001", EmergencyContactName = "Fatima Rahman", EmergencyContactPhone = "+8801700000101" };
        var karim = new Tenant { FirstName = "Karim", LastName = "Ahmed", Email = "karim.ahmed@example.test", Phone = "+8801700000002" };
        var sadia = new Tenant { FirstName = "Sadia", LastName = "Islam", Email = "sadia.islam@example.test", Phone = "+8801700000003" };
        db.Tenants.AddRange(amina, karim, sadia);
        var maple = new Property { Name = "Maple Heights", StreetAddress = "12 Example Avenue", City = "Dhaka", PostalCode = "1205" };
        var riverside = new Property { Name = "Riverside Court", StreetAddress = "45 Demo Road", City = "Dhaka", PostalCode = "1212" };
        db.Properties.AddRange(maple, riverside);
        var a101 = new Unit { Property = maple, UnitNumber = "A-101", FloorNumber = 1, Bedrooms = 2, Bathrooms = 1, SquareFeet = 760, ListedMonthlyRent = 28000 };
        var a202 = new Unit { Property = maple, UnitNumber = "A-202", FloorNumber = 2, Bedrooms = 3, Bathrooms = 2, SquareFeet = 1120, ListedMonthlyRent = 42000 };
        var b305 = new Unit { Property = riverside, UnitNumber = "B-305", FloorNumber = 3, Bedrooms = 1, Bathrooms = 1, SquareFeet = 540, ListedMonthlyRent = 22000 };
        var b410 = new Unit { Property = riverside, UnitNumber = "B-410", FloorNumber = 4, Bedrooms = 2, Bathrooms = 2, SquareFeet = 900, ListedMonthlyRent = 35000, IsListed = false };
        db.Units.AddRange(a101, a202, b305, b410);
        var active = new Lease { Unit = a101, Tenant = amina, LeaseStart = new DateOnly(2026, 1, 1), LeaseEnd = new DateOnly(2026, 12, 31), MonthlyRent = 28000, SecurityDeposit = 28000, Status = LeaseStatus.Active };
        var ended = new Lease { Unit = a202, Tenant = karim, LeaseStart = new DateOnly(2025, 1, 1), LeaseEnd = new DateOnly(2025, 12, 31), MonthlyRent = 40000, SecurityDeposit = 40000, Status = LeaseStatus.Ended };
        var draft = new Lease { Unit = b410, Tenant = sadia, LeaseStart = new DateOnly(2026, 8, 1), LeaseEnd = new DateOnly(2027, 7, 31), MonthlyRent = 35000, SecurityDeposit = 35000, Status = LeaseStatus.Draft };
        db.Leases.AddRange(active, ended, draft);
        db.Payments.AddRange(
            new Payment { Lease = active, PaymentPeriod = new DateOnly(2026, 1, 1), DueDate = new DateOnly(2026, 1, 5), AmountDue = 28000, AmountPaid = 28000, PaidAtUtc = DateTime.UtcNow.AddDays(-200), Method = PaymentMethod.BankTransfer, ReferenceCode = "DEMO-202601-A" },
            new Payment { Lease = active, PaymentPeriod = new DateOnly(2026, 2, 1), DueDate = new DateOnly(2026, 2, 5), AmountDue = 28000, AmountPaid = 28000, PaidAtUtc = DateTime.UtcNow.AddDays(-170), Method = PaymentMethod.MobileBanking, ReferenceCode = "DEMO-202602-A" },
            new Payment { Lease = active, PaymentPeriod = new DateOnly(2026, 3, 1), DueDate = new DateOnly(2026, 3, 5), AmountDue = 28000, AmountPaid = 12000, PaidAtUtc = DateTime.UtcNow.AddDays(-140), Method = PaymentMethod.BankTransfer, ReferenceCode = "DEMO-202603-A" });
        db.MaintenanceRequests.AddRange(
            new MaintenanceRequest { Unit = a101, ReportedByTenant = amina, Category = MaintenanceCategory.Plumbing, Priority = MaintenancePriority.Medium, Description = "Kitchen tap requires inspection." },
            new MaintenanceRequest { Unit = b305, Category = MaintenanceCategory.Appliance, Priority = MaintenancePriority.Low, Description = "Refrigerator inspection before listing.", Status = MaintenanceStatus.InProgress });
        db.Users.AddRange(
            new AppUser { Email = "admin@apartment.local", DisplayName = "System Administrator", PasswordHash = global::BCrypt.Net.BCrypt.HashPassword("Admin123!"), Role = UserRole.Admin },
            new AppUser { Email = "agent@apartment.local", DisplayName = "Leasing Agent", PasswordHash = global::BCrypt.Net.BCrypt.HashPassword("Agent123!"), Role = UserRole.Agent },
            new AppUser { Email = "amina.rahman@example.test", DisplayName = "Amina Rahman", PasswordHash = global::BCrypt.Net.BCrypt.HashPassword("Tenant123!"), Role = UserRole.Tenant, Tenant = amina });
        await db.SaveChangesAsync();
    }
}
