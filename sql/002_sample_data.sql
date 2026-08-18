-- Clearly fictional sample data for local development and query demonstrations.
-- Run 001_schema.sql before executing this file.

USE apartment_rental;

INSERT INTO properties (property_name, street_address, city, postal_code)
VALUES
  ('Maple Heights', '12 Example Avenue', 'Dhaka', '1205'),
  ('Riverside Court', '45 Demo Road', 'Dhaka', '1212')
ON DUPLICATE KEY UPDATE property_name = VALUES(property_name);

INSERT INTO units (property_id, unit_number, floor_number, bedrooms, bathrooms, square_feet, listed_monthly_rent, is_listed)
VALUES
  (1, 'A-101', 1, 2, 1.0, 760, 28000.00, TRUE),
  (1, 'A-202', 2, 3, 2.0, 1120, 42000.00, TRUE),
  (2, 'B-305', 3, 1, 1.0, 540, 22000.00, TRUE),
  (2, 'B-410', 4, 2, 2.0, 900, 35000.00, FALSE)
ON DUPLICATE KEY UPDATE listed_monthly_rent = VALUES(listed_monthly_rent), is_listed = VALUES(is_listed);

INSERT INTO tenants (first_name, last_name, email, phone, emergency_contact_name, emergency_contact_phone)
VALUES
  ('Amina', 'Rahman', 'amina.rahman@example.test', '+8801700000001', 'Fatima Rahman', '+8801700000101'),
  ('Karim', 'Ahmed', 'karim.ahmed@example.test', '+8801700000002', 'Nadia Ahmed', '+8801700000102'),
  ('Sadia', 'Islam', 'sadia.islam@example.test', '+8801700000003', 'Rafi Islam', '+8801700000103')
ON DUPLICATE KEY UPDATE phone = VALUES(phone);

INSERT INTO leases (unit_id, tenant_id, lease_start, lease_end, monthly_rent, security_deposit, status)
VALUES
  (1, 1, '2026-01-01', '2026-12-31', 28000.00, 28000.00, 'active'),
  (2, 2, '2025-01-01', '2025-12-31', 40000.00, 40000.00, 'ended'),
  (4, 3, '2026-08-01', '2027-07-31', 35000.00, 35000.00, 'draft')
ON DUPLICATE KEY UPDATE monthly_rent = VALUES(monthly_rent), status = VALUES(status);

INSERT INTO payments (lease_id, payment_period, due_date, amount_due, amount_paid, paid_at, payment_method, reference_code)
VALUES
  (1, '2026-01-01', '2026-01-05', 28000.00, 28000.00, '2026-01-03 09:10:00', 'bank_transfer', 'DEMO-202601-A'),
  (1, '2026-02-01', '2026-02-05', 28000.00, 28000.00, '2026-02-04 11:40:00', 'mobile_banking', 'DEMO-202602-A'),
  (1, '2026-03-01', '2026-03-05', 28000.00, 12000.00, '2026-03-05 14:25:00', 'bank_transfer', 'DEMO-202603-A')
ON DUPLICATE KEY UPDATE amount_paid = VALUES(amount_paid), paid_at = VALUES(paid_at);

INSERT INTO maintenance_requests (unit_id, reported_by_tenant_id, category, priority, description, status, resolved_at)
VALUES
  (1, 1, 'plumbing', 'medium', 'Fictional sample: kitchen tap requires inspection.', 'open', NULL),
  (3, NULL, 'appliance', 'low', 'Fictional sample: refrigerator inspection before listing.', 'in_progress', NULL)
ON DUPLICATE KEY UPDATE priority = VALUES(priority), status = VALUES(status), resolved_at = VALUES(resolved_at);
