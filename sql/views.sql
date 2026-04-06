DROP VIEW IF EXISTS vw_flat_availability;
DROP VIEW IF EXISTS vw_active_leases;
DROP VIEW IF EXISTS vw_overdue_rent;
DROP VIEW IF EXISTS vw_monthly_revenue;

CREATE VIEW vw_flat_availability AS
WITH occupied AS (
    SELECT
        flat_id,
        MAX(COALESCE(actual_move_out_date, lease_end_date)) AS occupied_until
    FROM leases
    WHERE lease_status IN ('active', 'terminated', 'completed')
      AND date(lease_start_date) <= date('now')
      AND date(COALESCE(actual_move_out_date, lease_end_date)) >= date('now')
    GROUP BY flat_id
),
reserved AS (
    SELECT
        flat_id,
        MAX(requested_move_out) AS reserved_until
    FROM bookings
    WHERE status = 'confirmed'
      AND date(requested_move_out) >= date('now')
    GROUP BY flat_id
)
SELECT
    f.flat_id,
    b.building_name,
    b.city,
    b.state,
    f.flat_number,
    f.floor_number,
    f.bedrooms,
    f.bathrooms,
    f.square_feet,
    f.monthly_rent,
    CASE
        WHEN f.listing_status = 'inactive' THEN 'inactive'
        WHEN o.flat_id IS NOT NULL THEN 'occupied'
        WHEN r.flat_id IS NOT NULL THEN 'reserved'
        WHEN f.listing_status = 'maintenance' THEN 'maintenance'
        ELSE 'available'
    END AS availability_status,
    CASE
        WHEN o.flat_id IS NOT NULL THEN date(o.occupied_until, '+1 day')
        WHEN r.flat_id IS NOT NULL THEN date(r.reserved_until, '+1 day')
        ELSE f.available_from
    END AS next_available_on
FROM flats AS f
JOIN buildings AS b
    ON b.building_id = f.building_id
LEFT JOIN occupied AS o
    ON o.flat_id = f.flat_id
LEFT JOIN reserved AS r
    ON r.flat_id = f.flat_id;

CREATE VIEW vw_active_leases AS
SELECT
    l.lease_id,
    b.building_name,
    f.flat_number,
    t.tenant_id,
    t.first_name || ' ' || t.last_name AS tenant_name,
    t.email,
    t.phone,
    l.lease_start_date,
    l.lease_end_date,
    l.monthly_rent,
    l.payment_due_day,
    CAST(
        julianday(COALESCE(l.actual_move_out_date, l.lease_end_date)) - julianday(date('now'))
        AS INTEGER
    ) AS days_remaining
FROM leases AS l
JOIN flats AS f
    ON f.flat_id = l.flat_id
JOIN buildings AS b
    ON b.building_id = f.building_id
JOIN tenants AS t
    ON t.tenant_id = l.tenant_id
WHERE l.lease_status = 'active'
  AND date(lease_start_date) <= date('now')
  AND date(COALESCE(l.actual_move_out_date, l.lease_end_date)) >= date('now');

CREATE VIEW vw_overdue_rent AS
SELECT
    rp.payment_id,
    rp.billing_month,
    rp.due_date,
    t.first_name || ' ' || t.last_name AS tenant_name,
    b.building_name,
    f.flat_number,
    rp.amount_due,
    rp.late_fee,
    rp.amount_paid,
    (rp.amount_due + rp.late_fee - rp.amount_paid) AS outstanding_balance,
    CAST(julianday(date('now')) - julianday(rp.due_date) AS INTEGER) AS days_overdue
FROM rent_payments AS rp
JOIN leases AS l
    ON l.lease_id = rp.lease_id
JOIN flats AS f
    ON f.flat_id = l.flat_id
JOIN buildings AS b
    ON b.building_id = f.building_id
JOIN tenants AS t
    ON t.tenant_id = l.tenant_id
WHERE date(rp.due_date) < date('now')
  AND rp.amount_paid < (rp.amount_due + rp.late_fee);

CREATE VIEW vw_monthly_revenue AS
SELECT
    billing_month,
    SUM(amount_due + late_fee) AS billed_amount,
    SUM(amount_paid) AS collected_amount,
    SUM(amount_due + late_fee - amount_paid) AS outstanding_amount,
    COUNT(*) AS invoices_issued
FROM rent_payments
GROUP BY billing_month
ORDER BY billing_month;

