-- Register a new tenant
INSERT INTO tenants (
    first_name,
    last_name,
    email,
    phone,
    date_of_birth,
    government_id,
    occupation,
    emergency_contact_name,
    emergency_contact_phone
) VALUES (
    'Riya',
    'Sen',
    'riya.sen@example.com',
    '+91-9000000001',
    '1995-06-09',
    'PAN-RS8800',
    'Consultant',
    'Amit Sen',
    '+91-9000000002'
);

-- List flats available for a requested stay window
WITH requested_window AS (
    SELECT
        date('now', '+60 day') AS move_in_date,
        date('now', '+425 day') AS move_out_date
)
SELECT
    f.flat_id,
    b.building_name,
    f.flat_number,
    f.bedrooms,
    f.monthly_rent,
    rw.move_in_date,
    rw.move_out_date
FROM flats AS f
JOIN buildings AS b
    ON b.building_id = f.building_id
JOIN requested_window AS rw
WHERE f.listing_status = 'available'
  AND NOT EXISTS (
      SELECT 1
      FROM leases AS l
      WHERE l.flat_id = f.flat_id
        AND l.lease_status <> 'cancelled'
        AND date(rw.move_in_date) <= date(COALESCE(l.actual_move_out_date, l.lease_end_date))
        AND date(rw.move_out_date) >= date(l.lease_start_date)
  )
  AND NOT EXISTS (
      SELECT 1
      FROM bookings AS bk
      WHERE bk.flat_id = f.flat_id
        AND bk.status = 'confirmed'
        AND date(rw.move_in_date) <= date(bk.requested_move_out)
        AND date(rw.move_out_date) >= date(bk.requested_move_in)
  )
ORDER BY f.monthly_rent;

-- Create a new confirmed booking
INSERT INTO bookings (
    flat_id,
    tenant_id,
    requested_move_in,
    requested_move_out,
    quoted_rent,
    status,
    notes
) VALUES (
    4,
    5,
    date('now', '+14 day'),
    date('now', '+379 day'),
    1700,
    'confirmed',
    'Reserved after virtual tour and document check'
);

-- Convert a booking into a lease
INSERT INTO leases (
    flat_id,
    tenant_id,
    booking_id,
    lease_start_date,
    lease_end_date,
    monthly_rent,
    security_deposit,
    payment_due_day,
    lease_status,
    signed_on
) VALUES (
    2,
    3,
    1,
    date('now', '+15 day'),
    date('now', '+380 day'),
    1200,
    2400,
    5,
    'active',
    date('now')
);

-- Generate a new rent invoice for the current month
INSERT INTO rent_payments (
    lease_id,
    billing_month,
    due_date,
    amount_due,
    late_fee,
    amount_paid
) VALUES (
    1,
    date('now', 'start of month', '+1 month'),
    date('now', 'start of month', '+1 month', '+4 day'),
    1800,
    0,
    0
);

-- Record a payment against an existing invoice
UPDATE rent_payments
SET amount_paid = 2250,
    payment_date = date('now'),
    payment_method = 'bank_transfer'
WHERE payment_id = 4;
