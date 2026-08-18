-- Apartment Rental System
-- Target: MySQL 8.0+
-- This file is idempotent for local development. It intentionally does not drop existing data.

CREATE DATABASE IF NOT EXISTS apartment_rental
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE apartment_rental;

CREATE TABLE IF NOT EXISTS properties (
  property_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  property_name VARCHAR(120) NOT NULL,
  street_address VARCHAR(180) NOT NULL,
  city VARCHAR(80) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (property_id),
  UNIQUE KEY uq_properties_name_address (property_name, street_address, city)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS units (
  unit_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  property_id BIGINT UNSIGNED NOT NULL,
  unit_number VARCHAR(20) NOT NULL,
  floor_number SMALLINT UNSIGNED NOT NULL,
  bedrooms TINYINT UNSIGNED NOT NULL,
  bathrooms DECIMAL(3,1) NOT NULL,
  square_feet INT UNSIGNED NOT NULL,
  listed_monthly_rent DECIMAL(10,2) NOT NULL,
  is_listed BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (unit_id),
  UNIQUE KEY uq_units_property_number (property_id, unit_number),
  KEY idx_units_listing (property_id, is_listed, listed_monthly_rent),
  CONSTRAINT fk_units_property
    FOREIGN KEY (property_id) REFERENCES properties(property_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_units_floor CHECK (floor_number <= 250),
  CONSTRAINT chk_units_bedrooms CHECK (bedrooms <= 12),
  CONSTRAINT chk_units_bathrooms CHECK (bathrooms > 0 AND bathrooms <= 12),
  CONSTRAINT chk_units_square_feet CHECK (square_feet >= 100),
  CONSTRAINT chk_units_listed_rent CHECK (listed_monthly_rent > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS tenants (
  tenant_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(254) NOT NULL,
  phone VARCHAR(30) NULL,
  emergency_contact_name VARCHAR(160) NULL,
  emergency_contact_phone VARCHAR(30) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (tenant_id),
  UNIQUE KEY uq_tenants_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS leases (
  lease_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  unit_id BIGINT UNSIGNED NOT NULL,
  tenant_id BIGINT UNSIGNED NOT NULL,
  lease_start DATE NOT NULL,
  lease_end DATE NOT NULL,
  monthly_rent DECIMAL(10,2) NOT NULL,
  security_deposit DECIMAL(10,2) NOT NULL DEFAULT 0,
  status ENUM('draft', 'active', 'ended', 'terminated') NOT NULL DEFAULT 'draft',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (lease_id),
  KEY idx_leases_unit_status_dates (unit_id, status, lease_start, lease_end),
  KEY idx_leases_tenant_status (tenant_id, status),
  CONSTRAINT fk_leases_unit
    FOREIGN KEY (unit_id) REFERENCES units(unit_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_leases_tenant
    FOREIGN KEY (tenant_id) REFERENCES tenants(tenant_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_leases_date_range CHECK (lease_end > lease_start),
  CONSTRAINT chk_leases_rent CHECK (monthly_rent > 0),
  CONSTRAINT chk_leases_deposit CHECK (security_deposit >= 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS payments (
  payment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  lease_id BIGINT UNSIGNED NOT NULL,
  payment_period DATE NOT NULL,
  due_date DATE NOT NULL,
  amount_due DECIMAL(10,2) NOT NULL,
  amount_paid DECIMAL(10,2) NOT NULL DEFAULT 0,
  paid_at DATETIME NULL,
  payment_method ENUM('bank_transfer', 'card', 'cash', 'mobile_banking') NULL,
  reference_code VARCHAR(80) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id),
  UNIQUE KEY uq_payments_lease_period (lease_id, payment_period),
  KEY idx_payments_due_status (due_date, paid_at),
  CONSTRAINT fk_payments_lease
    FOREIGN KEY (lease_id) REFERENCES leases(lease_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT chk_payments_amount_due CHECK (amount_due > 0),
  CONSTRAINT chk_payments_amount_paid CHECK (amount_paid >= 0 AND amount_paid <= amount_due),
  CONSTRAINT chk_payments_paid_at CHECK (paid_at IS NULL OR amount_paid > 0)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS maintenance_requests (
  request_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  unit_id BIGINT UNSIGNED NOT NULL,
  reported_by_tenant_id BIGINT UNSIGNED NULL,
  category ENUM('plumbing', 'electrical', 'appliance', 'structural', 'other') NOT NULL,
  priority ENUM('low', 'medium', 'high', 'emergency') NOT NULL DEFAULT 'medium',
  description TEXT NOT NULL,
  status ENUM('open', 'in_progress', 'resolved', 'cancelled') NOT NULL DEFAULT 'open',
  reported_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME NULL,
  PRIMARY KEY (request_id),
  KEY idx_maintenance_unit_status (unit_id, status, priority),
  CONSTRAINT fk_maintenance_unit
    FOREIGN KEY (unit_id) REFERENCES units(unit_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_maintenance_tenant
    FOREIGN KEY (reported_by_tenant_id) REFERENCES tenants(tenant_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT chk_maintenance_resolution CHECK (
    (status = 'resolved' AND resolved_at IS NOT NULL)
    OR (status <> 'resolved' AND resolved_at IS NULL)
  )
) ENGINE=InnoDB;

-- A reporting view avoids storing a mutable unit-availability flag that can drift from lease data.
CREATE OR REPLACE VIEW vw_unit_availability AS
SELECT
  u.unit_id,
  p.property_name,
  p.city,
  u.unit_number,
  u.floor_number,
  u.bedrooms,
  u.bathrooms,
  u.square_feet,
  u.listed_monthly_rent,
  u.is_listed,
  CASE
    WHEN active_lease.lease_id IS NOT NULL THEN 'occupied'
    WHEN open_maintenance.request_id IS NOT NULL THEN 'maintenance_review'
    WHEN u.is_listed THEN 'available'
    ELSE 'off_market'
  END AS availability_status,
  active_lease.lease_end AS active_lease_end
FROM units AS u
JOIN properties AS p ON p.property_id = u.property_id
LEFT JOIN leases AS active_lease
  ON active_lease.unit_id = u.unit_id
  AND active_lease.status = 'active'
  AND CURRENT_DATE BETWEEN active_lease.lease_start AND active_lease.lease_end
LEFT JOIN maintenance_requests AS open_maintenance
  ON open_maintenance.unit_id = u.unit_id
  AND open_maintenance.status IN ('open', 'in_progress');
