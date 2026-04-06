-- Availability across all flats
SELECT *
FROM vw_flat_availability
ORDER BY building_name, flat_number;

-- Current active leases with tenant contact details
SELECT *
FROM vw_active_leases
ORDER BY building_name, flat_number;

-- Outstanding rent balances that need collection follow-up
SELECT *
FROM vw_overdue_rent
ORDER BY days_overdue DESC, tenant_name;

-- Monthly billing and cash-collection summary
SELECT *
FROM vw_monthly_revenue
ORDER BY billing_month;

