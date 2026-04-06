PRAGMA foreign_keys = ON;

DROP TRIGGER IF EXISTS trg_bookings_no_overlap_insert;
DROP TRIGGER IF EXISTS trg_bookings_no_overlap_update;
DROP TRIGGER IF EXISTS trg_leases_no_overlap_insert;
DROP TRIGGER IF EXISTS trg_leases_no_overlap_update;
DROP TRIGGER IF EXISTS trg_leases_mark_booking_converted_insert;
DROP TRIGGER IF EXISTS trg_leases_mark_booking_converted_update;
DROP TRIGGER IF EXISTS trg_rent_payments_guard_insert;
DROP TRIGGER IF EXISTS trg_rent_payments_guard_update;
DROP TRIGGER IF EXISTS trg_rent_payments_sync_insert;
DROP TRIGGER IF EXISTS trg_rent_payments_sync_update;

CREATE TRIGGER trg_bookings_no_overlap_insert
BEFORE INSERT ON bookings
FOR EACH ROW
WHEN NEW.status = 'confirmed'
BEGIN
    SELECT
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM bookings AS b
                WHERE b.flat_id = NEW.flat_id
                  AND b.status = 'confirmed'
                  AND date(NEW.requested_move_in) <= date(b.requested_move_out)
                  AND date(NEW.requested_move_out) >= date(b.requested_move_in)
            )
            THEN RAISE(ABORT, 'Flat already has a confirmed booking in that period')
        END;
END;

CREATE TRIGGER trg_bookings_no_overlap_update
BEFORE UPDATE ON bookings
FOR EACH ROW
WHEN NEW.status = 'confirmed'
BEGIN
    SELECT
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM bookings AS b
                WHERE b.flat_id = NEW.flat_id
                  AND b.booking_id <> NEW.booking_id
                  AND b.status = 'confirmed'
                  AND date(NEW.requested_move_in) <= date(b.requested_move_out)
                  AND date(NEW.requested_move_out) >= date(b.requested_move_in)
            )
            THEN RAISE(ABORT, 'Flat already has a confirmed booking in that period')
        END;
END;

CREATE TRIGGER trg_leases_no_overlap_insert
BEFORE INSERT ON leases
FOR EACH ROW
WHEN NEW.lease_status <> 'cancelled'
BEGIN
    SELECT
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM leases AS l
                WHERE l.flat_id = NEW.flat_id
                  AND l.lease_status <> 'cancelled'
                  AND date(NEW.lease_start_date) <= date(COALESCE(l.actual_move_out_date, l.lease_end_date))
                  AND date(COALESCE(NEW.actual_move_out_date, NEW.lease_end_date)) >= date(l.lease_start_date)
            )
            THEN RAISE(ABORT, 'Lease dates overlap with an existing lease for this flat')
        END;
END;

CREATE TRIGGER trg_leases_no_overlap_update
BEFORE UPDATE ON leases
FOR EACH ROW
WHEN NEW.lease_status <> 'cancelled'
BEGIN
    SELECT
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM leases AS l
                WHERE l.flat_id = NEW.flat_id
                  AND l.lease_id <> NEW.lease_id
                  AND l.lease_status <> 'cancelled'
                  AND date(NEW.lease_start_date) <= date(COALESCE(l.actual_move_out_date, l.lease_end_date))
                  AND date(COALESCE(NEW.actual_move_out_date, NEW.lease_end_date)) >= date(l.lease_start_date)
            )
            THEN RAISE(ABORT, 'Lease dates overlap with an existing lease for this flat')
        END;
END;

CREATE TRIGGER trg_leases_mark_booking_converted_insert
AFTER INSERT ON leases
FOR EACH ROW
WHEN NEW.booking_id IS NOT NULL
BEGIN
    UPDATE bookings
    SET status = 'converted'
    WHERE booking_id = NEW.booking_id;
END;

CREATE TRIGGER trg_leases_mark_booking_converted_update
AFTER UPDATE OF booking_id ON leases
FOR EACH ROW
WHEN NEW.booking_id IS NOT NULL
BEGIN
    UPDATE bookings
    SET status = 'converted'
    WHERE booking_id = NEW.booking_id;
END;

CREATE TRIGGER trg_rent_payments_guard_insert
BEFORE INSERT ON rent_payments
FOR EACH ROW
WHEN NEW.amount_paid > (NEW.amount_due + NEW.late_fee)
BEGIN
    SELECT RAISE(ABORT, 'Amount paid cannot exceed the total due amount');
END;

CREATE TRIGGER trg_rent_payments_guard_update
BEFORE UPDATE ON rent_payments
FOR EACH ROW
WHEN NEW.amount_paid > (NEW.amount_due + NEW.late_fee)
BEGIN
    SELECT RAISE(ABORT, 'Amount paid cannot exceed the total due amount');
END;

CREATE TRIGGER trg_rent_payments_sync_insert
AFTER INSERT ON rent_payments
FOR EACH ROW
BEGIN
    UPDATE rent_payments
    SET payment_date = CASE
            WHEN NEW.amount_paid > 0 AND NEW.payment_date IS NULL THEN date('now')
            ELSE NEW.payment_date
        END,
        payment_status = CASE
            WHEN NEW.amount_due = 0 AND NEW.late_fee = 0 THEN 'waived'
            WHEN NEW.amount_paid >= (NEW.amount_due + NEW.late_fee) THEN 'paid'
            WHEN NEW.amount_paid > 0 THEN 'partial'
            WHEN date(NEW.due_date) < date('now') THEN 'overdue'
            ELSE 'pending'
        END
    WHERE payment_id = NEW.payment_id;
END;

CREATE TRIGGER trg_rent_payments_sync_update
AFTER UPDATE OF amount_due, late_fee, amount_paid, due_date, payment_date ON rent_payments
FOR EACH ROW
BEGIN
    UPDATE rent_payments
    SET payment_date = CASE
            WHEN NEW.amount_paid > 0 AND NEW.payment_date IS NULL THEN date('now')
            ELSE NEW.payment_date
        END,
        payment_status = CASE
            WHEN NEW.amount_due = 0 AND NEW.late_fee = 0 THEN 'waived'
            WHEN NEW.amount_paid >= (NEW.amount_due + NEW.late_fee) THEN 'paid'
            WHEN NEW.amount_paid > 0 THEN 'partial'
            WHEN date(NEW.due_date) < date('now') THEN 'overdue'
            ELSE 'pending'
        END
    WHERE payment_id = NEW.payment_id;
END;

