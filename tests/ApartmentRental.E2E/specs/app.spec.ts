import { test, expect, type Page } from '@playwright/test'

async function mockApi(page: Page) {
  await page.route('**/api/properties/search**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([{ unitId: 1, propertyId: 1, propertyName: 'Maple Heights', address: '12 Example Avenue', city: 'Dhaka', unitNumber: 'A-101', floorNumber: 1, bedrooms: 2, bathrooms: 1, squareFeet: 760, listedMonthlyRent: 28000, availabilityStatus: 'available' }]) }))
  await page.route('**/api/auth/login', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ accessToken: 'test-token', email: 'admin@apartment.local', displayName: 'System Administrator', role: 'Admin' }) }))
  await page.route('**/api/dashboard', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ billed: 84000, collected: 68000, outstanding: 16000, openMaintenance: 2, activeLeases: 1 }) }))
  await page.route('**/api/leases**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([{ id: 1, unitId: 1, unitNumber: 'A-101', tenantId: 1, tenantName: 'Amina Rahman', leaseStart: '2026-01-01', leaseEnd: '2026-12-31', monthlyRent: 28000, securityDeposit: 28000, status: 'Active' }]) }))
  await page.route('**/api/payments**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([{ id: 1, leaseId: 1, paymentPeriod: '2026-03-01', dueDate: '2026-03-05', amountDue: 28000, amountPaid: 12000, status: 'partial' }]) }))
  await page.route('**/api/maintenance**', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([{ id: 1, unitId: 1, unitNumber: 'A-101', category: 'Plumbing', priority: 'Medium', status: 'Open', description: 'Kitchen tap requires inspection.', reportedAtUtc: '2026-03-05T10:00:00Z' }]) }))
}

test('visitor can search available homes', async ({ page }) => {
  await mockApi(page)
  await page.goto('/')
  await expect(page.getByRole('heading', { name: /Find a place that feels/i })).toBeVisible()
  await page.getByLabel('Bedrooms').selectOption('2')
  await page.getByRole('button', { name: /Search homes/i }).click()
  await expect(page.getByText(/homes available/i)).toBeVisible()
})

test('admin can open the rental workspace', async ({ page }) => {
  await mockApi(page)
  await page.goto('/')
  await page.getByRole('button', { name: 'Sign in' }).click()
  await page.getByLabel('Email').fill('admin@apartment.local')
  await page.getByLabel('Password').fill('Admin123!')
  await page.getByRole('button', { name: /Continue/i }).click()
  await expect(page.getByRole('button', { name: 'My workspace' })).toBeVisible()
  await expect(page.getByText(/workspace/i).first()).toBeVisible()
})
