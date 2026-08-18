-- Portfolio-ready reporting queries for Apartment Rental System.
-- Run 001_schema.sql and optionally 002_sample_data.sql first.

USE apartment_rental;

-- 1. Available units suitable for marketing or an agent dashboard.
SELECT
  property_name,
  city,
  unit_number,
  bedrooms,
  bathrooms,
  square_feet,
  listed_monthly_rent
FROM vw_unit_availability
WHERE availability_status = 'available'
ORDER BY listed_monthly_rent, property_name, unit_number;

-- 2. Current active tenancy register.
SELECT
  p.property_name,
  u.unit_number,
  CONCAT(t.first_name, ' ', t.last_name) AS tenant_name,
  t.email,
  l.lease_start,
  l.lease_end,
  l.monthly_rent
FROM leases AS l
JOIN units AS u ON u.unit_id = l.unit_id
JOIN properties AS p ON p.property_id = u.property_id
JOIN tenants AS t ON t.tenant_id = l.tenant_id
WHERE l.status = 'active'
  AND CURRENT_DATE BETWEEN l.lease_start AND l.lease_end
ORDER BY l.lease_end;

-- 3. Receivables: unpaid and partially paid rent with days past due.
SELECT
  p.property_name,
  u.unit_number,
  CONCAT(t.first_name, ' ', t.last_name) AS tenant_name,
  pay.payment_period,
  pay.due_date,
  pay.amount_due,
  pay.amount_paid,
  pay.amount_due - pay.amount_paid AS outstanding_balance,
  GREATEST(DATEDIFF(CURRENT_DATE, pay.due_date), 0) AS days_past_due
FROM payments AS pay
JOIN leases AS l ON l.lease_id = pay.lease_id
JOIN tenants AS t ON t.tenant_id = l.tenant_id
JOIN units AS u ON u.unit_id = l.unit_id
JOIN properties AS p ON p.property_id = u.property_id
WHERE pay.amount_paid < pay.amount_due
ORDER BY pay.due_date, outstanding_balance DESC;

-- 4. Monthly collections and outstanding balance by property.
SELECT
  p.property_name,
  DATE_FORMAT(pay.payment_period, '%Y-%m') AS billing_month,
  SUM(pay.amount_due) AS billed_amount,
  SUM(pay.amount_paid) AS collected_amount,
  SUM(pay.amount_due - pay.amount_paid) AS outstanding_amount
FROM payments AS pay
JOIN leases AS l ON l.lease_id = pay.lease_id
JOIN units AS u ON u.unit_id = l.unit_id
JOIN properties AS p ON p.property_id = u.property_id
GROUP BY p.property_name, DATE_FORMAT(pay.payment_period, '%Y-%m')
ORDER BY billing_month DESC, p.property_name;

-- 5. Leases due to expire in the next 60 days.
SELECT
  p.property_name,
  u.unit_number,
  CONCAT(t.first_name, ' ', t.last_name) AS tenant_name,
  l.lease_end,
  DATEDIFF(l.lease_end, CURRENT_DATE) AS days_until_expiry
FROM leases AS l
JOIN units AS u ON u.unit_id = l.unit_id
JOIN properties AS p ON p.property_id = u.property_id
JOIN tenants AS t ON t.tenant_id = l.tenant_id
WHERE l.status = 'active'
  AND l.lease_end BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 60 DAY)
ORDER BY l.lease_end;

-- 6. Open maintenance queue, with highest-priority tickets first.
SELECT
  p.property_name,
  u.unit_number,
  mr.category,
  mr.priority,
  mr.status,
  mr.description,
  mr.reported_at
FROM maintenance_requests AS mr
JOIN units AS u ON u.unit_id = mr.unit_id
JOIN properties AS p ON p.property_id = u.property_id
WHERE mr.status IN ('open', 'in_progress')
ORDER BY FIELD(mr.priority, 'emergency', 'high', 'medium', 'low'), mr.reported_at;
