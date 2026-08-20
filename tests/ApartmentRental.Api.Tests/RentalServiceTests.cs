using ApartmentRental.Api.Contracts;
using ApartmentRental.Api.Data;
using ApartmentRental.Api.Models;
using ApartmentRental.Api.Services;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace ApartmentRental.Api.Tests;

public class RentalServiceTests
{
    private static ApplicationDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<ApplicationDbContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;
        return new ApplicationDbContext(options);
    }

    [Fact]
    public async Task SearchReturnsOnlyMatchingListedUnits()
    {
        await using var db = CreateDb();
        var property = new Property { Name = "Test Heights", StreetAddress = "1 Test Street", City = "Dhaka", PostalCode = "1200" };
        db.Properties.Add(property);
        db.Units.AddRange(
            new Unit { Property = property, UnitNumber = "A-1", Bedrooms = 2, Bathrooms = 1, SquareFeet = 700, ListedMonthlyRent = 25000, IsListed = true },
            new Unit { Property = property, UnitNumber = "A-2", Bedrooms = 1, Bathrooms = 1, SquareFeet = 500, ListedMonthlyRent = 18000, IsListed = false });
        await db.SaveChangesAsync();
        var results = await new RentalService(db).SearchAsync(new PropertySearchRequest("Dhaka", 2, 30000, true));
        Assert.Single(results);
        Assert.Equal("A-1", results[0].UnitNumber);
        Assert.Equal("available", results[0].AvailabilityStatus);
    }

    [Fact]
    public async Task ActiveLeaseMakesUnitOccupied()
    {
        await using var db = CreateDb();
        var tenant = new Tenant { FirstName = "Test", LastName = "Tenant", Email = "test@example.test" };
        var property = new Property { Name = "Test Court", StreetAddress = "2 Test Street", City = "Dhaka", PostalCode = "1201" };
        var unit = new Unit { Property = property, UnitNumber = "B-1", Bedrooms = 2, Bathrooms = 1, SquareFeet = 700, ListedMonthlyRent = 25000 };
        db.Add(new Lease { Unit = unit, Tenant = tenant, LeaseStart = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(-2)), LeaseEnd = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(30)), MonthlyRent = 25000, Status = LeaseStatus.Active });
        await db.SaveChangesAsync();
        var result = await new RentalService(db).SearchAsync(new PropertySearchRequest(null, null, null, false));
        Assert.Equal("occupied", Assert.Single(result).AvailabilityStatus);
    }

    [Fact]
    public async Task MaintenanceReviewOverridesAvailability()
    {
        await using var db = CreateDb();
        var property = new Property { Name = "Test Court", StreetAddress = "3 Test Street", City = "Dhaka", PostalCode = "1202" };
        var unit = new Unit { Property = property, UnitNumber = "C-1", Bedrooms = 1, Bathrooms = 1, SquareFeet = 500, ListedMonthlyRent = 18000 };
        db.Add(new MaintenanceRequest { Unit = unit, Category = MaintenanceCategory.Plumbing, Description = "Leak", Status = MaintenanceStatus.Open });
        await db.SaveChangesAsync();
        var result = await new RentalService(db).SearchAsync(new PropertySearchRequest(null, null, null, false));
        Assert.Equal("maintenance_review", Assert.Single(result).AvailabilityStatus);
    }
}
