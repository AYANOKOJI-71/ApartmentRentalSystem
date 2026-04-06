PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS rent_payments;
DROP TABLE IF EXISTS leases;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS tenants;
DROP TABLE IF EXISTS flats;
DROP TABLE IF EXISTS buildings;

CREATE TABLE buildings (
    building_id INTEGER PRIMARY KEY,
    building_name TEXT NOT NULL,
    street_address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    postal_code TEXT NOT NULL,
    total_units INTEGER NOT NULL CHECK (total_units > 0),
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE flats (
    flat_id INTEGER PRIMARY KEY,
    building_id INTEGER NOT NULL,
    flat_number TEXT NOT NULL,
    floor_number INTEGER NOT NULL,
    bedrooms INTEGER NOT NULL CHECK (bedrooms >= 0),
    bathrooms NUMERIC NOT NULL CHECK (bathrooms > 0),
    square_feet INTEGER NOT NULL CHECK (square_feet > 0),
    monthly_rent NUMERIC NOT NULL CHECK (monthly_rent >= 0),
    security_deposit NUMERIC NOT NULL CHECK (security_deposit >= 0),
    furnishing_status TEXT NOT NULL
        CHECK (furnishing_status IN ('unfurnished', 'semi-furnished', 'furnished')),
    listing_status TEXT NOT NULL DEFAULT 'available'
        CHECK (listing_status IN ('available', 'maintenance', 'inactive')),
    available_from TEXT NOT NULL,
    description TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (building_id, flat_number),
    CHECK (date(available_from) IS NOT NULL),
    FOREIGN KEY (building_id) REFERENCES buildings(building_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE tenants (
    tenant_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT NOT NULL UNIQUE,
    date_of_birth TEXT,
    government_id TEXT NOT NULL UNIQUE,
    occupation TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (date_of_birth IS NULL OR date(date_of_birth) IS NOT NULL)
);

CREATE TABLE bookings (
    booking_id INTEGER PRIMARY KEY,
    flat_id INTEGER NOT NULL,
    tenant_id INTEGER NOT NULL,
    booking_date TEXT NOT NULL DEFAULT (date('now')),
    requested_move_in TEXT NOT NULL,
    requested_move_out TEXT NOT NULL,
    quoted_rent NUMERIC NOT NULL CHECK (quoted_rent >= 0),
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'cancelled', 'converted', 'expired')),
    notes TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (date(booking_date) IS NOT NULL),
    CHECK (date(requested_move_in) IS NOT NULL),
    CHECK (date(requested_move_out) IS NOT NULL),
    CHECK (date(requested_move_out) > date(requested_move_in)),
    FOREIGN KEY (flat_id) REFERENCES flats(flat_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE leases (
    lease_id INTEGER PRIMARY KEY,
    flat_id INTEGER NOT NULL,
    tenant_id INTEGER NOT NULL,
    booking_id INTEGER UNIQUE,
    lease_start_date TEXT NOT NULL,
    lease_end_date TEXT NOT NULL,
    actual_move_out_date TEXT,
    monthly_rent NUMERIC NOT NULL CHECK (monthly_rent >= 0),
    security_deposit NUMERIC NOT NULL CHECK (security_deposit >= 0),
    payment_due_day INTEGER NOT NULL CHECK (payment_due_day BETWEEN 1 AND 28),
    lease_status TEXT NOT NULL DEFAULT 'draft'
        CHECK (lease_status IN ('draft', 'active', 'completed', 'terminated', 'cancelled')),
    signed_on TEXT,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (date(lease_start_date) IS NOT NULL),
    CHECK (date(lease_end_date) IS NOT NULL),
    CHECK (date(lease_end_date) > date(lease_start_date)),
    CHECK (actual_move_out_date IS NULL OR date(actual_move_out_date) IS NOT NULL),
    CHECK (signed_on IS NULL OR date(signed_on) IS NOT NULL),
    CHECK (
        actual_move_out_date IS NULL
        OR date(actual_move_out_date) >= date(lease_start_date)
    ),
    FOREIGN KEY (flat_id) REFERENCES flats(flat_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

CREATE TABLE rent_payments (
    payment_id INTEGER PRIMARY KEY,
    lease_id INTEGER NOT NULL,
    billing_month TEXT NOT NULL,
    due_date TEXT NOT NULL,
    amount_due NUMERIC NOT NULL CHECK (amount_due >= 0),
    late_fee NUMERIC NOT NULL DEFAULT 0 CHECK (late_fee >= 0),
    amount_paid NUMERIC NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
    payment_date TEXT,
    payment_method TEXT
        CHECK (payment_method IN (
            'bank_transfer',
            'cash',
            'card',
            'upi',
            'check',
            'online_portal'
        )),
    payment_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (payment_status IN ('pending', 'partial', 'paid', 'overdue', 'waived')),
    transaction_reference TEXT UNIQUE,
    created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (lease_id, billing_month),
    CHECK (date(billing_month) = date(billing_month, 'start of month')),
    CHECK (date(due_date) IS NOT NULL),
    CHECK (payment_date IS NULL OR date(payment_date) IS NOT NULL),
    FOREIGN KEY (lease_id) REFERENCES leases(lease_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

CREATE INDEX idx_flats_building_status
    ON flats (building_id, listing_status);

CREATE INDEX idx_bookings_flat_status_dates
    ON bookings (flat_id, status, requested_move_in, requested_move_out);

CREATE INDEX idx_leases_flat_status_dates
    ON leases (flat_id, lease_status, lease_start_date, lease_end_date);

CREATE INDEX idx_rent_payments_lease_month_status
    ON rent_payments (lease_id, billing_month, payment_status);

