# BWAPMS — Bangladesh Workforce & Programme Management System

Internal workforce/HR/performance management platform for **BRPHI's GramGP Programme**, Bangladesh Country Office (Sylhet). Manages a 4-tier team (Super Admin UK / Country Head BD / Senior Staff / Staff) — attendance, leave, tasks, payroll, KPIs, meetings, and governance/audit.

## 📚 Start here

- **[docs/BLUEPRINT.md](docs/BLUEPRINT.md)** — the full system specification (single source of truth): tier hierarchy, security rules, payroll formulas, KPI weights, database architecture, everything.
- **[docs/PENDING_ISSUES.md](docs/PENDING_ISSUES.md)** — live tracker of known issues, in-progress work, and what's already been fixed. **Read this before starting any new work.**

## 🧱 Stack

- **Frontend:** Plain HTML/CSS/JavaScript (no build step, no framework) — `index.html`, `dashboard-tier1.html` … `dashboard-tier4.html`, `attendance.html`, `leave.html`, `tasks.html`, `app.js`, `styles.css`
- **Backend:** Supabase (PostgreSQL + Auth + Storage + Edge Functions)
  - Project: `BWAPMS-Database` (ref `lznqbrynniziquzawpfs`, region `ap-south-1`)
  - 48 tables in `public` schema, all RLS-enabled
  - Edge Function: `create-employee` (Tier 1/2-only employee onboarding)
  - Storage bucket: `employee-photos`
- **Hosting:** static files, deployed as-is (no bundler)

## 🗂 Repo layout

```
index.html                 Login page
dashboard-tier1.html       Tier 1 — Super Admin (UK) Executive Dashboard
dashboard-tier2.html       Tier 2 — Country Head (BD) Admin Dashboard
dashboard-tier3.html       Tier 3 — Senior Staff Dashboard
dashboard-tier4.html       Tier 4 — Staff Dashboard
attendance.html            GPS attendance check-in/out
leave.html                 Leave requests
tasks.html                 Task management
app.js / styles.css        Shared logic and styling
docs/BLUEPRINT.md          Full system specification
docs/PENDING_ISSUES.md     Known issues / work tracker
migrations/                Dated .sql migration files (Extend-Don't-Replace — never edit an old migration, always add a new dated file)
```

## 🔐 Access model

Four tiers, cascading downward (see Blueprint §2 for full matrix):

| Tier | Role | Notes |
|---|---|---|
| 1 | Super Admin (UK) | Shared login, exempt from daily attendance/task modules |
| 2 | Country Head (BD) | Full local admin authority over Tiers 3–4 |
| 3 | Senior Staff | Manages Tier 4, no payroll/attendance edit rights |
| 4 | Staff | Task execution only |

Row-Level Security enforces this at the database level via `get_my_tier()` / `get_my_employee_id()` helper functions used throughout RLS policies.

## 🧑‍💻 Working on this repo

- No local build needed — these are static files editable directly.
- Every schema change goes in a new dated file under `migrations/` (e.g. `20260729_add_rls_policies_21_tables.sql`) — never edit or delete an old migration.
- Standing rule: any new feature must be delivered **full-stack** — both the Supabase piece (table/function/RLS) and the frontend piece (HTML/JS) — never just one side.
- Check `docs/PENDING_ISSUES.md` for current known issues before starting new work, and update it when you finish something.
