PRAGMA foreign_keys = ON;

INSERT INTO buildings (
    building_id,
    building_name,
    street_address,
    city,
    state,
    postal_code,
    total_units
) VALUES
    (1, 'Maple Residency', '12 Green Avenue', 'Pune', 'Maharashtra', '411001', 3),
    (2, 'Lakeview Towers', '44 Riverside Road', 'Bengaluru', 'Karnataka', '560001', 3);

INSERT INTO flats (
    flat_id,
    building_id,
    flat_number,
    floor_number,
    bedrooms,
    bathrooms,
    square_feet,
    monthly_rent,
    security_deposit,
    furnishing_status,
    listing_status,
    available_from,
    description
) VALUES
    (1, 1, '101', 1, 2, 2.0, 950, 1800, 3600, 'semi-furnished', 'available', date('now', '-60 day'), 'Corner flat with balcony and modular kitchen'),
    (2, 1, '102', 1, 1, 1.0, 620, 1200, 2400, 'unfurnished', 'available', date('now', '+15 day'), 'Compact starter flat close to lift lobby'),
    (3, 1, '201', 2, 3, 2.0, 1280, 2100, 4200, 'furnished', 'available', date('now', '-200 day'), 'Family flat with two balconies'),
    (4, 2, 'A-301', 3, 2, 2.0, 980, 1700, 3400, 'semi-furnished', 'available', date('now', '-10 day'), 'Recently repainted unit with lake-facing windows'),
    (5, 2, 'A-302', 3, 1, 1.0, 580, 1100, 2200, 'unfurnished', 'available', date('now', '+30 day'), 'Ideal for students and single occupants'),
    (6, 2, 'B-401', 4, 2, 2.0, 1010, 1900, 3800, 'furnished', 'maintenance', date('now', '+20 day'), 'Under maintenance after plumbing renovation');

INSERT INTO tenants (
    tenant_id,
    first_name,
    last_name,
    email,
    phone,
    date_of_birth,
    government_id,
    occupation,
    emergency_contact_name,
    emergency_contact_phone
) VALUES
    (1, 'Arjun', 'Mehta', 'arjun.mehta@example.com', '+91-9876543210', '1997-04-11', 'PAN-AM1234', 'Software Engineer', 'Rohan Mehta', '+91-9876543200'),
    (2, 'Nisha', 'Iyer', 'nisha.iyer@example.com', '+91-9876543211', '1994-09-22', 'PAN-NI9876', 'Product Manager', 'Vani Iyer', '+91-9876543201'),
    (3, 'Kabir', 'Shah', 'kabir.shah@example.com', '+91-9876543212', '1998-01-30', 'PAN-KS4567', 'Analyst', 'Meera Shah', '+91-9876543202'),
    (4, 'Sara', 'Thomas', 'sara.thomas@example.com', '+91-9876543213', '1996-12-17', 'PAN-ST2211', 'Architect', 'Anita Thomas', '+91-9876543203'),
    (5, 'Dev', 'Kapoor', 'dev.kapoor@example.com', '+91-9876543214', '1999-07-08', 'PAN-DK6001', 'Student', 'Sonia Kapoor', '+91-9876543204');

INSERT INTO bookings (
    booking_id,
    flat_id,
    tenant_id,
    booking_date,
    requested_move_in,
    requested_move_out,
    quoted_rent,
    status,
    notes
) VALUES
    (1, 2, 3, date('now', '-2 day'), date('now', '+15 day'), date('now', '+380 day'), 1200, 'confirmed', 'Approved after document verification'),
    (2, 5, 5, date('now', '-1 day'), date('now', '+30 day'), date('now', '+365 day'), 1100, 'pending', 'Awaiting co-signer details'),
    (3, 1, 1, date('now', '-70 day'), date('now', '-60 day'), date('now', '+305 day'), 1800, 'confirmed', 'Booking converted into lease'),
    (4, 4, 4, date('now', '-40 day'), date('now', '-30 day'), date('now', '+335 day'), 1700, 'cancelled', 'Tenant chose another location');

INSERT INTO leases (
    lease_id,
    flat_id,
    tenant_id,
    booking_id,
    lease_start_date,
    lease_end_date,
    actual_move_out_date,
    monthly_rent,
    security_deposit,
    payment_due_day,
    lease_status,
    signed_on
) VALUES
    (1, 1, 1, 3, date('now', '-60 day'), date('now', '+305 day'), NULL, 1800, 3600, 5, 'active', date('now', '-65 day')),
    (2, 3, 2, NULL, date('now', '-200 day'), date('now', '+165 day'), NULL, 2100, 4200, 8, 'active', date('now', '-205 day')),
    (3, 4, 4, NULL, date('now', '-500 day'), date('now', '-140 day'), date('now', '-145 day'), 1650, 3300, 5, 'completed', date('now', '-505 day'));

INSERT INTO rent_payments (
    payment_id,
    lease_id,
    billing_month,
    due_date,
    amount_due,
    late_fee,
    amount_paid,
    payment_date,
    payment_method,
    transaction_reference
) VALUES
    (1, 1, date('now', 'start of month', '-1 month'), date('now', 'start of month', '-1 month', '+4 day'), 1800, 0, 1800, date('now', 'start of month', '-1 month', '+2 day'), 'bank_transfer', 'TXN-L1-M1'),
    (2, 1, date('now', 'start of month'), date('now', 'start of month', '+4 day'), 1800, 0, 1800, date('now', 'start of month', '+2 day'), 'online_portal', 'TXN-L1-M2'),
    (3, 2, date('now', 'start of month', '-1 month'), date('now', 'start of month', '-1 month', '+7 day'), 2100, 0, 2100, date('now', 'start of month', '-1 month', '+6 day'), 'bank_transfer', 'TXN-L2-M1'),
    (4, 2, date('now', 'start of month'), date('now', '-7 day'), 2100, 150, 0, NULL, NULL, 'TXN-L2-M2');

