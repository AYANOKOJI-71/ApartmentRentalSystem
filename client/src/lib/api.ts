export type Role = 'Admin' | 'Agent' | 'Tenant'
export type Unit = {
  unitId: number; propertyId: number; propertyName: string; address: string; city: string; unitNumber: string
  floorNumber: number; bedrooms: number; bathrooms: number; squareFeet: number; listedMonthlyRent: number
  availabilityStatus: string; activeLeaseEnd?: string
}
export type Dashboard = { billed: number; collected: number; outstanding: number; openMaintenance: number; activeLeases: number }
export type Lease = { id: number; unitId: number; unitNumber: string; tenantId: number; tenantName: string; leaseStart: string; leaseEnd: string; monthlyRent: number; securityDeposit: number; status: string }
export type Payment = { id: number; leaseId: number; paymentPeriod: string; dueDate: string; amountDue: number; amountPaid: number; status: string; paidAtUtc?: string; method?: string; referenceCode?: string }
export type Maintenance = { id: number; unitId: number; unitNumber: string; category: string; priority: string; status: string; description: string; reportedAtUtc: string; resolvedAtUtc?: string }

const base = import.meta.env.VITE_API_URL ?? ''
export async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('havenly-token')
  const response = await fetch(`${base}${path}`, {
    ...options,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...(options.headers ?? {}) }
  })
  if (!response.ok) throw new Error(response.status === 401 ? 'Please sign in to continue.' : await response.text())
  return response.status === 204 ? (undefined as T) : response.json()
}
export const searchUnits = (params: URLSearchParams) => api<Unit[]>(`/api/properties/search?${params}`)
export const login = (email: string, password: string) => api<{ accessToken: string; email: string; displayName: string; role: Role }>('/api/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) })
export const getDashboard = () => api<Dashboard>('/api/dashboard')
export const getLeases = () => api<Lease[]>('/api/leases')
export const getPayments = (leaseId?: number) => api<Payment[]>(`/api/payments${leaseId ? `?leaseId=${leaseId}` : ''}`)
export const getMaintenance = () => api<Maintenance[]>('/api/maintenance')
export const recordPayment = (leaseId: number, body: unknown) => api<Payment>(`/api/leases/${leaseId}/payments`, { method: 'POST', body: JSON.stringify(body) })
export const createMaintenance = (body: unknown) => api<Maintenance>('/api/maintenance', { method: 'POST', body: JSON.stringify(body) })
export const updateMaintenance = (id: number, body: unknown) => api<void>(`/api/maintenance/${id}`, { method: 'PATCH', body: JSON.stringify(body) })
