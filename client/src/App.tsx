import { useEffect, useMemo, useState } from 'react'
import { api, createMaintenance, getDashboard, getLeases, getMaintenance, getPayments, login, recordPayment, searchUnits, updateMaintenance, type Dashboard, type Lease, type Maintenance, type Payment, type Role, type Unit } from './lib/api'
import './styles.css'

type Session = { displayName: string; email: string; role: Role }
const money = (value: number) => new Intl.NumberFormat('en-BD', { style: 'currency', currency: 'BDT', maximumFractionDigits: 0 }).format(value)
const date = (value: string) => new Intl.DateTimeFormat('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }).format(new Date(value))

export default function App() {
  const [session, setSession] = useState<Session | null>(() => JSON.parse(localStorage.getItem('havenly-session') ?? 'null'))
  const [activeTab, setActiveTab] = useState<'explore' | 'operations'>('explore')
  const [units, setUnits] = useState<Unit[]>([])
  const [dashboard, setDashboard] = useState<Dashboard | null>(null)
  const [leases, setLeases] = useState<Lease[]>([])
  const [payments, setPayments] = useState<Payment[]>([])
  const [maintenance, setMaintenance] = useState<Maintenance[]>([])
  const [filters, setFilters] = useState({ city: 'Dhaka', bedrooms: '', maxRent: '', q: '' })
  const [loginOpen, setLoginOpen] = useState(false)
  const [error, setError] = useState('')

  const refreshSearch = async () => {
    const params = new URLSearchParams({ city: filters.city, listedOnly: 'true' })
    if (filters.bedrooms) params.set('bedrooms', filters.bedrooms)
    if (filters.maxRent) params.set('maxRent', filters.maxRent)
    if (filters.q) params.set('q', filters.q)
    try { setUnits(await searchUnits(params)); setError('') } catch (e) { setError(String(e)) }
  }
  const refreshOperations = async () => {
    try {
      const [d, l, p, m] = await Promise.all([getDashboard(), getLeases(), getPayments(), getMaintenance()])
      setDashboard(d); setLeases(l); setPayments(p); setMaintenance(m); setError('')
    } catch (e) { setError(String(e)) }
  }
  useEffect(() => { refreshSearch() }, [])
  useEffect(() => { if (session && activeTab === 'operations') refreshOperations() }, [session, activeTab])
  const unpaid = useMemo(() => payments.filter(p => p.status !== 'paid'), [payments])

  const signOut = () => { localStorage.removeItem('havenly-token'); localStorage.removeItem('havenly-session'); setSession(null); setActiveTab('explore') }
  const onLogin = (value: Session & { accessToken: string }) => {
    localStorage.setItem('havenly-token', value.accessToken)
    localStorage.setItem('havenly-session', JSON.stringify({ displayName: value.displayName, email: value.email, role: value.role }))
    setSession({ displayName: value.displayName, email: value.email, role: value.role }); setLoginOpen(false); setActiveTab('operations')
  }

  return <div className="app-shell">
    <header className="topbar">
      <button className="brand" onClick={() => setActiveTab('explore')}><span className="brand-mark">H</span><span>havenly<span className="brand-dot">.</span></span></button>
      <nav><button className={activeTab === 'explore' ? 'nav-active' : ''} onClick={() => setActiveTab('explore')}>Explore homes</button>{session && <button className={activeTab === 'operations' ? 'nav-active' : ''} onClick={() => setActiveTab('operations')}>My workspace</button>}</nav>
      <div className="top-actions">{session ? <><span className="user-chip"><span className="avatar">{session.displayName[0]}</span>{session.displayName}</span><button className="ghost-button" onClick={signOut}>Sign out</button></> : <button className="dark-button small" onClick={() => setLoginOpen(true)}>Sign in</button>}</div>
    </header>
    {error && <div className="error-banner">{error}<button onClick={() => setError('')}>×</button></div>}
    {activeTab === 'explore' ? <main>
      <section className="hero-section"><div className="eyebrow">A better way to rent in Bangladesh</div><h1>Find a place that feels<br /><em>like yours.</em></h1><p className="hero-copy">Thoughtfully designed homes, transparent pricing, and a rental experience built around the way you live.</p>
        <form className="search-panel" onSubmit={e => { e.preventDefault(); refreshSearch() }}><label>Location<input value={filters.city} onChange={e => setFilters({ ...filters, city: e.target.value })} placeholder="City or neighbourhood" /></label><label>Bedrooms<select value={filters.bedrooms} onChange={e => setFilters({ ...filters, bedrooms: e.target.value })}><option value="">Any</option><option value="1">1+</option><option value="2">2+</option><option value="3">3+</option></select></label><label>Monthly budget<input type="number" value={filters.maxRent} onChange={e => setFilters({ ...filters, maxRent: e.target.value })} placeholder="Max BDT" /></label><button className="search-button">Search homes <span>↗</span></button></form>
      </section>
      <section className="content-section"><div className="section-heading"><div><div className="eyebrow">Curated for you</div><h2>Homes worth coming home to</h2></div><span className="result-count">{units.length} homes available</span></div><div className="unit-grid">{units.map(unit => <article className="unit-card" key={unit.unitId}><div className="unit-image"><div className="image-sheen"></div><span className={`availability ${unit.availabilityStatus}`}>{unit.availabilityStatus === 'maintenance_review' ? 'Reviewing' : unit.availabilityStatus}</span><button className="heart">♡</button><div className="unit-image-label">{unit.propertyName}</div></div><div className="unit-info"><div className="unit-title"><h3>{unit.unitNumber}</h3><span className="rent">{money(unit.listedMonthlyRent)}<small>/month</small></span></div><p className="muted">{unit.address}, {unit.city}</p><div className="unit-meta"><span>{unit.bedrooms} bed</span><span>{unit.bathrooms} bath</span><span>{unit.squareFeet.toLocaleString()} sq ft</span></div><button className="outline-button full" onClick={() => session ? setActiveTab('operations') : setLoginOpen(true)}>View details <span>↗</span></button></div></article>)}{units.length === 0 && <div className="empty-state">No homes match those filters. Try a wider budget or fewer bedrooms.</div>}</div></section>
      <section className="trust-strip"><div><strong>2,400+</strong><span>happy residents</span></div><div><strong>98%</strong><span>renewal rate</span></div><div><strong>4.9/5</strong><span>resident rating</span></div><p>“Finally, renting that feels<br /><em>refreshingly simple.</em>”</p></section>
    </main> : <Operations dashboard={dashboard} leases={leases} payments={unpaid} maintenance={maintenance} role={session?.role ?? 'Tenant'} refresh={refreshOperations} />}
    <footer><span>© 2026 havenly.</span><span>Built for better renting.</span></footer>
    {loginOpen && <LoginDialog onClose={() => setLoginOpen(false)} onLogin={onLogin} />}
  </div>
}

function LoginDialog({ onClose, onLogin }: { onClose: () => void; onLogin: (value: Session & { accessToken: string }) => void }) {
  const [email, setEmail] = useState('admin@apartment.local'); const [password, setPassword] = useState('Admin123!'); const [busy, setBusy] = useState(false); const [error, setError] = useState('')
  const submit = async (e: React.FormEvent) => { e.preventDefault(); setBusy(true); try { onLogin(await login(email, password)) } catch { setError('Invalid credentials. Try the demo admin account.') } finally { setBusy(false) } }
  return <div className="modal-backdrop" onClick={onClose}><div className="login-modal" onClick={e => e.stopPropagation()}><button className="modal-close" onClick={onClose}>×</button><div className="eyebrow">Welcome back</div><h2>Sign in to havenly</h2><p className="muted">Access your rental workspace and payment history.</p><form onSubmit={submit}><label>Email<input type="email" value={email} onChange={e => setEmail(e.target.value)} /></label><label>Password<input type="password" value={password} onChange={e => setPassword(e.target.value)} /></label>{error && <p className="form-error">{error}</p>}<button className="dark-button full" disabled={busy}>{busy ? 'Signing in…' : 'Continue'} <span>↗</span></button></form><div className="demo-note">Demo: admin@apartment.local / Admin123!</div></div></div>
}

function Operations({ dashboard, leases, payments, maintenance, role, refresh }: { dashboard: Dashboard | null; leases: Lease[]; payments: Payment[]; maintenance: Maintenance[]; role: Role; refresh: () => Promise<void> }) {
  const [view, setView] = useState<'overview' | 'payments' | 'maintenance'>('overview'); const [paying, setPaying] = useState<Payment | null>(null); const [ticketOpen, setTicketOpen] = useState(false)
  return <main className="workspace"><div className="workspace-heading"><div><div className="eyebrow">{role} workspace</div><h1>Good morning.</h1><p className="hero-copy">Everything important about your rental, in one quiet place.</p></div><div className="workspace-actions"><button className={view === 'overview' ? 'tab-button active' : 'tab-button'} onClick={() => setView('overview')}>Overview</button><button className={view === 'payments' ? 'tab-button active' : 'tab-button'} onClick={() => setView('payments')}>Payments</button><button className={view === 'maintenance' ? 'tab-button active' : 'tab-button'} onClick={() => setView('maintenance')}>Maintenance</button></div></div>
    {view === 'overview' && <><div className="metric-grid"><Metric label="Outstanding balance" value={money(dashboard?.outstanding ?? 0)} tone="warm" /><Metric label="Collected to date" value={money(dashboard?.collected ?? 0)} /><Metric label="Active leases" value={String(dashboard?.activeLeases ?? leases.length)} /><Metric label="Open requests" value={String(dashboard?.openMaintenance ?? maintenance.length)} /></div><section className="workspace-grid"><div className="panel"><div className="panel-heading"><div><div className="eyebrow">Your home</div><h2>{leases[0]?.unitNumber ?? 'No active lease'}</h2></div><span className="status-pill">{leases[0]?.status ?? 'Explore'}</span></div><p className="muted">{leases[0]?.tenantName ?? 'Find a home that fits your life.'} {leases[0] && `· Lease ends ${date(leases[0].leaseEnd)}`}</p>{leases[0] && <div className="lease-detail"><span>Monthly rent<strong>{money(leases[0].monthlyRent)}</strong></span><span>Security deposit<strong>{money(leases[0].securityDeposit)}</strong></span><span>Term<strong>{date(leases[0].leaseStart)} – {date(leases[0].leaseEnd)}</strong></span></div>}</div><div className="panel accent-panel"><div className="eyebrow">Next payment</div><h2>{payments[0] ? money(payments[0].amountDue - payments[0].amountPaid) : 'All clear'}</h2><p>{payments[0] ? `Due ${date(payments[0].dueDate)}` : 'You are up to date on rent.'}</p>{payments[0] && <button className="dark-button" onClick={() => setPaying(payments[0])}>Make a payment <span>↗</span></button>}</div></section></>}
    {view === 'payments' && <section className="panel"><div className="panel-heading"><div><div className="eyebrow">Rent history</div><h2>Payments</h2></div>{payments.length > 0 && <span className="status-pill warm">{payments.length} outstanding</span>}</div><div className="table-wrap"><table><thead><tr><th>Period</th><th>Due</th><th>Amount due</th><th>Paid</th><th>Status</th><th></th></tr></thead><tbody>{payments.map(payment => <tr key={payment.id}><td>{date(payment.paymentPeriod)}</td><td>{date(payment.dueDate)}</td><td>{money(payment.amountDue)}</td><td>{money(payment.amountPaid)}</td><td><span className={`status-text ${payment.status}`}>{payment.status}</span></td><td><button className="text-button" onClick={() => setPaying(payment)}>Pay balance ↗</button></td></tr>)}</tbody></table></div></section>}
    {view === 'maintenance' && <section className="panel"><div className="panel-heading"><div><div className="eyebrow">Keep things easy</div><h2>Maintenance</h2></div><button className="dark-button" onClick={() => setTicketOpen(true)}>New request <span>+</span></button></div><div className="ticket-list">{maintenance.map(item => <div className="ticket" key={item.id}><span className={`priority-dot ${item.priority.toLowerCase()}`}></span><div><strong>{item.category}</strong><p>{item.description}</p></div><span className="status-pill">{item.status}</span>{role !== 'Tenant' && item.status !== 'Resolved' && <button className="text-button" onClick={async () => { await updateMaintenance(item.id, { status: 'Resolved', priority: item.priority }); await refresh() }}>Resolve</button>}</div>)}</div></section>}
    {paying && <PaymentDialog payment={paying} onClose={() => setPaying(null)} onDone={async () => { setPaying(null); await refresh() }} />}{ticketOpen && <MaintenanceDialog onClose={() => setTicketOpen(false)} onDone={async () => { setTicketOpen(false); await refresh() }} />}
  </main>
}
function Metric({ label, value, tone }: { label: string; value: string; tone?: string }) { return <div className={`metric-card ${tone ?? ''}`}><span>{label}</span><strong>{value}</strong><small>Updated just now</small></div> }
function PaymentDialog({ payment, onClose, onDone }: { payment: Payment; onClose: () => void; onDone: () => Promise<void> }) { const [amount, setAmount] = useState(String(payment.amountDue - payment.amountPaid)); const [busy, setBusy] = useState(false); const submit = async (e: React.FormEvent) => { e.preventDefault(); setBusy(true); await recordPayment(payment.leaseId, { paymentPeriod: payment.paymentPeriod, dueDate: payment.dueDate, amountDue: payment.amountDue, amountPaid: payment.amountPaid + Number(amount), method: 'MobileBanking', referenceCode: `HAV-${Date.now()}` }); await onDone(); setBusy(false) }; return <div className="modal-backdrop" onClick={onClose}><div className="login-modal" onClick={e => e.stopPropagation()}><button className="modal-close" onClick={onClose}>×</button><div className="eyebrow">Rent payment</div><h2>Settle this balance</h2><p className="muted">{date(payment.paymentPeriod)} · remaining {money(payment.amountDue - payment.amountPaid)}</p><form onSubmit={submit}><label>Amount to pay<input type="number" min="1" max={payment.amountDue - payment.amountPaid} value={amount} onChange={e => setAmount(e.target.value)} /></label><button className="dark-button full" disabled={busy}>{busy ? 'Processing…' : 'Confirm payment'} <span>↗</span></button></form></div></div> }
function MaintenanceDialog({ onClose, onDone }: { onClose: () => void; onDone: () => Promise<void> }) { const [unitId, setUnitId] = useState('1'); const [description, setDescription] = useState(''); const [busy, setBusy] = useState(false); const submit = async (e: React.FormEvent) => { e.preventDefault(); setBusy(true); await createMaintenance({ unitId: Number(unitId), category: 'Other', priority: 'Medium', description }); await onDone(); setBusy(false) }; return <div className="modal-backdrop" onClick={onClose}><div className="login-modal" onClick={e => e.stopPropagation()}><button className="modal-close" onClick={onClose}>×</button><div className="eyebrow">Maintenance request</div><h2>What needs attention?</h2><form onSubmit={submit}><label>Unit ID<input type="number" min="1" value={unitId} onChange={e => setUnitId(e.target.value)} /></label><label>Describe the issue<textarea rows={4} value={description} onChange={e => setDescription(e.target.value)} required placeholder="Tell us what happened…" /></label><button className="dark-button full" disabled={busy}>{busy ? 'Sending…' : 'Send request'} <span>↗</span></button></form></div></div> }
