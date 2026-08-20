# Apartment Rental System v2

Apartment Rental System v2 is a rebuilt full-stack rental operations platform for property teams and residents. The original repository contained a MySQL schema and reporting queries; this version preserves that business model while adding a production-oriented application layer with **ASP.NET Core**, **React/TypeScript**, **SQL Server**, **JWT RBAC**, property search, lease management, rent collection, maintenance workflows, xUnit coverage, Playwright coverage, and container deployment.

## Architecture

| Layer | Technology | Responsibility |
|---|---|---|
| Client | React, TypeScript, Vite, CSS | Public property discovery and authenticated rental workspace |
| API | ASP.NET Core 8 minimal APIs | Authentication, authorization, search, leases, payments, maintenance, audit events |
| Persistence | EF Core 8, SQL Server 2022 | Relational model, constraints, indexes, transactional payment updates |
| Unit tests | xUnit, EF Core InMemory | Search filters, derived availability, maintenance review rules |
| Browser tests | Playwright | Public search, sign-in, and protected workspace smoke flows |
| Deployment | Docker Compose, Nginx | SQL Server + API + static SPA with `/api` reverse proxy |

## Functional scope

The public experience supports city, bedroom, budget, and keyword search. Availability is derived rather than manually duplicated: an active lease produces `occupied`, an open or in-progress maintenance request produces `maintenance_review`, a listed unit produces `available`, and an unlisted unit produces `off_market`.

Authenticated users have one of three roles. **Admins** can inspect audit events and perform all operational actions. **Agents** can manage leases, payments, and maintenance. **Tenants** can see only their own leases and payments, submit maintenance requests, and record payments against their own lease. Every state-changing workflow appends an audit event.

The rent workflow is period-based and prevents overpayment. Payment rows preserve amount due, amount paid, due date, payment method, reference code, and paid timestamp. Lease creation validates date ranges, positive rent, non-negative deposits, and overlapping active or draft leases. Maintenance tickets support priority, status, resolution timestamps, and tenant scoping.

## Demo users

| Role | Email | Password |
|---|---|---|
| Admin | `admin@apartment.local` | `Admin123!` |
| Agent | `agent@apartment.local` | `Agent123!` |
| Tenant | `amina.rahman@example.test` | `Tenant123!` |

Change all demo credentials and the JWT key before any non-development deployment.

## Run locally with Docker

Docker Compose starts SQL Server 2022, the ASP.NET Core API, and the React/Nginx client.

```bash
docker compose up --build
```

Then open [http://localhost:5173](http://localhost:5173). The API is available at [http://localhost:5000](http://localhost:5000), health checks are at `/api/health`, and OpenAPI is available at `/swagger`.

The API calls `EnsureCreated` on startup to make a clean local database usable immediately. For production, replace this with reviewed EF Core migrations and a controlled migration step.

## Run without Docker

Install .NET 8 SDK, Node.js 22+, and SQL Server. Set the connection string in `src/ApartmentRental.Api/appsettings.json` or through `ConnectionStrings__DefaultConnection`, then run:

```bash
dotnet run --project src/ApartmentRental.Api --urls http://localhost:5000
cd client
npm install
npm run dev
```

## Tests

Run API unit tests:

```bash
dotnet test tests/ApartmentRental.Api.Tests
```

Run the frontend build:

```bash
cd client
npm install
npm run build
```

Run Playwright after starting the API and client:

```bash
cd tests/ApartmentRental.E2E
npm install
npx playwright install chromium
npm test
```

## Deployment

The included `docker-compose.yml` is suitable for a single-host deployment after replacing demo secrets, adding a durable SQL Server backup strategy, placing TLS in front of Nginx, and configuring a real domain. The API container listens on port `8080`; the client container listens on port `80` and proxies `/api` requests to the API service.

For a managed cloud deployment, the same images can be published to a container registry and deployed as separate API and frontend services, while SQL Server should be replaced by a managed SQL Server instance with private networking, backups, monitoring, and secret storage. The repository also includes CI configuration that runs .NET tests, client builds, and Playwright installation checks on every push and pull request.

## Repository history

The original SQL artifacts remain under `sql/` as historical reference and as documentation of the pre-rebuild data model. The rebuilt application lives under `src/`, `client/`, `tests/`, and deployment files at the repository root.
