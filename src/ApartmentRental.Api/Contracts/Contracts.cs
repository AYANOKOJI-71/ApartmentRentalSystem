using ApartmentRental.Api.Models;

namespace ApartmentRental.Api.Contracts;

public record LoginRequest(string Email, string Password);
public record LoginResponse(string AccessToken, string Email, string DisplayName, string Role);
public record UserDto(long Id, string Email, string DisplayName, string Role);
public record PropertySearchRequest(string? City, int? Bedrooms, decimal? MaxRent, bool ListedOnly = true, string? Query = null);
public record PropertySearchResult(long UnitId, long PropertyId, string PropertyName, string Address, string City, string UnitNumber, int FloorNumber, int Bedrooms, decimal Bathrooms, int SquareFeet, decimal ListedMonthlyRent, string AvailabilityStatus, DateOnly? ActiveLeaseEnd);
public record CreateLeaseRequest(long UnitId, long TenantId, DateOnly LeaseStart, DateOnly LeaseEnd, decimal MonthlyRent, decimal SecurityDeposit);
public record LeaseDto(long Id, long UnitId, string UnitNumber, long TenantId, string TenantName, DateOnly LeaseStart, DateOnly LeaseEnd, decimal MonthlyRent, decimal SecurityDeposit, string Status);
public record CreatePaymentRequest(DateOnly PaymentPeriod, DateOnly DueDate, decimal AmountDue, decimal AmountPaid, PaymentMethod? Method, string? ReferenceCode);
public record PaymentDto(long Id, long LeaseId, DateOnly PaymentPeriod, DateOnly DueDate, decimal AmountDue, decimal AmountPaid, string Status, DateTime? PaidAtUtc, string? Method, string? ReferenceCode);
public record CreateMaintenanceRequest(long UnitId, MaintenanceCategory Category, MaintenancePriority Priority, string Description);
public record UpdateMaintenanceRequest(MaintenanceStatus Status, MaintenancePriority Priority);
public record MaintenanceDto(long Id, long UnitId, string UnitNumber, string Category, string Priority, string Status, string Description, DateTime ReportedAtUtc, DateTime? ResolvedAtUtc);
public record ReconciliationDto(decimal Billed, decimal Collected, decimal Outstanding, int OpenMaintenance, int ActiveLeases);
