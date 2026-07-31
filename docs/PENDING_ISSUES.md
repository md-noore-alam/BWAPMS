# BWAPMS — Pending Issues Tracker

> Purpose: This file tracks known issues, findings, and pending work on BWAPMS so that any future session (Claude or otherwise) can pick up exactly where the last one left off — without the user needing to re-explain context.
>
> **How to use:** When starting a new session, read this file first. When the user says "pending issues fix koro" / "fix the pending issues", work through the unresolved items below in priority order, without asking for step-by-step confirmation on each one. Mark items `[x]` and move them to the "Resolved" section with the date once fixed and verified.

**Standing rule — Backend/Frontend parity:** For every new rule or feature request, always deliver a *complete* implementation, not a partial one:
- If the backend (Supabase table/column/function/RLS policy) already exists but the frontend has no UI/JS to use it → **build the frontend piece.**
- If the frontend has a form/UI element but there's no backend table/column/function/policy to support it → **build the backend piece.**
- Never leave a feature half-done on only one side. Check both sides before marking anything complete.

**Last updated:** 2026-07-29
**Source:** Supabase Security & Performance Advisors (project `lznqbrynniziquzawpfs`, BWAPMS-Database) + GitHub repo review (`md-noore-alam/BWAPMS`, main branch)

---

## 🔴 High Priority

*(none currently open)*

## 🔴 High Priority

- [ ] **2FA + Device ID Binding not implemented** (Blueprint §3.1) — mandatory OTP-based 2FA for all users, device fingerprint binding, 2-device trusted-device limit, 5-failure lockout. Currently only email+password login exists. `employee_master.trusted_devices` / `twofa_enabled` columns exist but unused. Needs: OTP delivery service (email/SMS), device fingerprint capture on frontend, login flow rework.

- [ ] **GPS Fraud Detection 10-point engine not implemented** (Blueprint §3.2) — mock-GPS detection, speed anomaly, location jump, timestamp deviation, etc. `gps_log.mock_gps_flag` and `risk_score` columns exist but nothing populates them. This is the core anti-fraud mechanism for attendance and isn't running.

- [ ] **Pro-rata Payroll Calculation Engine not automated** (Blueprint §12.2-12.3) — the late-deduction/absent-deduction formulas (exact-Taka-fraction, 480-minute-day basis) exist only as columns on the `payroll` table; nothing calculates them. Tier 2 appears to be entering deduction values manually today.

## 🟠 Medium Priority

- [ ] **Report & Download Matrix — Tier 1 fully complete (all §5.8/§6.3/§12.9/§15.2 rows), Tier 2/3/4 not yet extended** — every report row across the full blueprint (not just the §15.2 summary table, which undercounted at ~11) is now built and downloadable on the **Tier 1 Executive Dashboard** as of 2026-07-31: Daily Attendance Slip, Monthly Attendance Report, Yearly Attendance Summary, Late Attendance Report, Absentee Report, Field Visit Compliance Report, Leave Balance Slip, Monthly Leave Summary, Yearly Leave Summary, Payroll Summary, Deduction Breakdown, Salary History, Individual Salary Slip, Next-Month Payroll Forecast (dashboard + PDF export), KPI Score, Performance Ranking, Task, Meeting & Action Items, Issue, Monthly Donor Audit Readiness, Audit Log — 21 report/slip types total, each CSV/Excel/PDF where the blueprint specifies (slips are PDF-only by design). This was GP Bhai's original "UK team can't download anything" report — root cause was the §15.2 summary table alone undercounting what §5.8/§6.3/§12.9 actually specify in detail; first two passes only covered the summary table's 11 rows before a third pass caught the remaining 7-10 items via a full blueprint re-read. `download_logs` table still exists with RLS ready but nothing writes to it yet — low-priority follow-up. Tier 2/3/4 dashboards still only have basic Attendance (and Leave, CSV-only) downloads — extend the same report set to those dashboards when needed, respecting each tier's narrower RLS scope (own-record-only for Tier 3/4 on several tables).
  - [x] Attendance PDF added to Tier 1 dashboard (2026-07-31) — was CSV/Excel-only, now matches Tier 2's PDF export (print-to-PDF window). See Resolved below.
  - [x] Payroll Summary + Deduction Breakdown reports added to Tier 1 dashboard (2026-07-31), CSV/Excel/PDF each — pulls from existing `payroll` table, no backend changes needed. See Resolved below.
  - [x] KPI Score + Performance Ranking reports added to Tier 1 dashboard (2026-07-31), CSV/Excel/PDF each — pulls from existing `kpi_scores` table. See Resolved below.
  - [x] Salary History, Task, Meeting & Action Items, Issue, Monthly Donor Audit Readiness, and Audit Log reports all added to Tier 1 dashboard (2026-07-31) in a new "More Reports" nav section, CSV/Excel/PDF each. See Resolved below.

- [ ] **Leave Balance auto-credit/reset not automated** (Blueprint §6.1) — 1.5 days/month CL, 14 days/year SL, 31 Dec expiry + 1 Jan fresh allocation. `leave_balance` table exists, no cron job updates it.

- [ ] **Field Visit Compliance cross-reference not automated** (Blueprint §10.2) — should auto-set `meetings.field_visit_compliance_status` to VERIFIED/UNVERIFIED by matching meeting minutes against GPS check-ins at the same whitelisted location/day. Nothing populates this today.

- [ ] **Next-Month Payroll Forecast + Turnover Risk Analyzer have no backend calculation** (Blueprint §12.8, §13.5) — `payroll_forecast` and `turnover_risk_flags` tables exist, and the Tier 2 dashboard already has a `payrollforecast` UI section, but no function generates the data, so it will render empty. Quick win since the frontend already exists.

- [ ] **Leaked Password Protection disabled** in Supabase Auth — cannot be toggled via SQL/API, no MCP tool covers Auth config either. Still needs manual action.
  **Action needed (GP Bhai):** Supabase Dashboard → Authentication → Providers → Email → enable "Leaked password protection" (HaveIBeenPwned check).

- [ ] **Legacy overlapping policies on 15 pre-existing tables** — NOT auto-merged (deliberately): `attendance`, `audit_logs`, `call_log`, `daily_reports`, `data_entry_log`, `employee_master`, `gps_exception_requests`, `gps_log`, `help_requests`, `intelligence_alerts`, `kpi_scores`, `payroll`, `rules_regulations`, `task_master`, `task_timer`. These policies predate this tracker and their exact original intent isn't fully documented, so merging them risks accidentally narrowing or widening access. Needs a table-by-table review with GP Bhai before combining.
  (Note: the 19 tables where *both* overlapping policies were created in the 2026-07-29 RLS migration — i.e. known, safe to merge — have already been consolidated. See Resolved section below.)

## 🟢 Low Priority

- [ ] **Responsibility Management + Duty Schedule have no frontend** — `responsibility_master`, `responsibility_assignment`, `duty_schedule` tables and RLS policies are fully ready (as of 2026-07-29 migration), but no dashboard has a UI section for them yet.

- [ ] **Employee Exit/Offboarding + Salary Increment workflows have no frontend** — `employee_exit` and `salary_history` tables exist but there's no offboarding checklist UI or annual-increment-approval UI. Low priority given infrequent events (10-person team).

- [ ] **10 unused indexes** (never used since creation) — candidates for removal if confirmed genuinely unused after more production traffic: `idx_attendance_status`, `idx_gps_log_risk`, `idx_task_master_deadline`, `idx_payroll_employee_month`, `idx_kpi_scores_employee`, `idx_audit_logs_user`, `idx_audit_logs_risk`, `idx_audit_logs_module`, `idx_penalty_history_employee`, `idx_gps_exception_employee_status`, `idx_data_entry_employee_date`, `idx_call_log_employee_date`, `idx_help_requests_status`, `idx_task_timer_task_running`, `idx_notifications_employee_unread`. (Note: dataset is still small — revisit after more real usage before removing.)

## 📝 Documentation / Process Notes

*(none currently open)*

---

## ✅ Resolved

### 2026-08-01 — CRITICAL: Dashboard "Approve" button silently rejected leave requests (bug)

- [x] **GP Bhai reported "Tier 2 feels helpless"** — traced to a duplicate `approveLeave()` function definition in `dashboard-tier2.html`: an old 1-argument version (`approveLeave(id)`) and a newer 2-argument version (`approveLeave(id, approve)`) both existed. JS silently lets the later declaration win, so only the 2-arg version was ever active — but the Dashboard's "Pending Approvals" widget (the very first thing Tier 2 sees on login, per GP Bhai's screenshot) called it with just 1 argument. `approve` resolved to `undefined` → falsy → the leave request status was always set to `'Rejected'`, regardless of whether "Approve" or "Reject" was clicked. The dedicated Leave section's buttons were unaffected (already passed `true`/`false` explicitly) — only the Dashboard shortcut was broken. Fixed the widget's `onclick` handlers to pass `true`/`false` explicitly and removed the dead duplicate function pair entirely. Also swept the whole codebase (`dashboard-tier1/2/3/4.html`, `attendance.html`, `leave.html`, `tasks.html`, `index.html`, `app.js`) for other duplicate function names — none found; this was isolated to Tier 2.
  → `dashboard-tier2.html`

### 2026-08-01 — Add Employee (app-based, replacing SQL) + duplicate bell icon (feature + fix)

- [x] **Add Employee UI added to Tier 1 dashboard** — GP Bhai requested employee creation move fully into the app (both Tier 1 and Tier 2), replacing manual SQL inserts. The `create-employee` Supabase Edge Function already permitted Tier 1 and Tier 2 callers server-side; only Tier 2 had the frontend modal. Replicated the modal + flow to Tier 1's Employees section. No backend change needed.
  → `dashboard-tier1.html`
- [x] **Duplicate bell icon removed from Tier 2 topbar** — there were two bell icons: the notification dropdown and a separate "Alerts" shortcut button that just navigated to the same section the sidebar's "Alerts" nav item already links to (complete with its own live count badge). Removed the redundant topbar button and its unused CSS.
  → `dashboard-tier2.html`

### 2026-07-31 — Final full-blueprint re-audit: 7 more report/slip types added (feature)

- [x] **GP Bhai flagged that earlier passes had missed items** — a re-read of §5.8 (Attendance Reports & Slips), §6.3 (Leave Slip Downloads), and §12.9 (Salary Slip & Payroll Reports) — not just the §15.2 summary table — surfaced 7 more report/slip types that hadn't been built yet. Added to the Tier 1 dashboard:
  - **Daily Attendance Slip** (PDF, per employee/day) — attendance section
  - **Yearly Attendance Summary** (CSV/Excel/PDF) — attendance section
  - **Late Attendance Report** (CSV/Excel/PDF) — attendance section
  - **Absentee Report** (CSV/Excel/PDF) — attendance section
  - **Field Visit Compliance Report** (CSV/Excel/PDF, from `meetings.field_visit_compliance_status`) — attendance section
  - **Leave Balance Slip** (PDF, per employee current-year snapshot, from `leave_balance`) — More Reports section
  - **Monthly + Yearly Leave Summary** (CSV/Excel/PDF, from `leave_request` where status='Approved') — More Reports section
  - **Individual Salary Slip** (PDF, per employee/month, from `payroll`) — payroll section
  - **Next-Month Payroll Forecast PDF export** — payroll section, exports the existing forecast widget

  Added two new shared helpers: `openSlipWindow()` for single-record PDF slips (distinct look from the tabular `exportRows()`), and `populateReportEmployeeDropdowns()` to fill the three new employee-select dropdowns on init. All column names and RLS policies verified directly against the live schema before writing each query — no backend migration needed.

  **Lesson for future sessions:** when a blueprint has both a summary table (§15.2) and detailed per-module sections (§5.8, §6.3, §12.9) describing the same feature area, always cross-check the detailed sections too — the summary table is not guaranteed to be exhaustive.
  → `dashboard-tier1.html`

### 2026-07-31 — Tier 1 remaining 6 reports: Salary History, Task, Meeting & Action Items, Issue, Donor Audit Readiness, Audit Log (feature)

- [x] **Completed Blueprint §15.2's Report & Download Matrix on the Tier 1 dashboard** — added a new "More Reports" sidebar section with 6 cards, each exporting CSV/Excel/PDF:
  - Salary History Report — `salary_history` table, filterable by year or all-time
  - Task Report — `task_master` table, filterable by due-date range
  - Meeting & Action Items Report — `meetings` + `meeting_action_items` tables joined, filterable by meeting date range
  - Issue Report — `issues` table, filterable by created-date range
  - Monthly Donor Audit Readiness Report — `audit_logs` table, sorted HIGH-risk-first, filterable by date range, title shows HIGH-risk event count
  - Audit Log Report — `audit_logs` table, filterable by date range

  Introduced two shared helpers (`exportRows()` for CSV/Excel/PDF generation, `getEmployeeMap()` for name lookups) to avoid duplicating the export logic across 6 more report types, and to sidestep ambiguous PostgREST embeds on tables with multiple foreign keys into `employee_master` (e.g. `salary_history` has `employee_id`, `proposed_by_tier2`, `approved_by_tier1` all pointing there). All RLS policies already granted Tier 1 full read access on these tables — no backend migration needed.

  This completes all 17 report categories from the Blueprint §15.2 matrix on the Tier 1 dashboard, resolving GP Bhai's original "UK team can't download anything" report. Tier 2/3/4 dashboards were not touched — extending the same reports there (with narrower RLS-appropriate scope) is tracked as a follow-up under Medium priority above.
  → `dashboard-tier1.html`

### 2026-07-31 — Tier 1 Payroll Summary + Deduction Breakdown downloads (feature)

- [x] **Payroll Summary Report and Deduction Breakdown Report missing on Tier 1 dashboard** (Blueprint §12.9) — added a new "Download Payroll Reports" card to the Payroll Forecast section: month picker + CSV/Excel/PDF export for both report types. Reads directly from the existing `payroll` table (RLS already grants Tier 1 full read access — `Tier1_2 full access to payroll` policy — no migration needed). Follows the same download pattern as the Attendance reports (blob download for CSV/Excel, print-to-PDF popup for PDF).
  → `dashboard-tier1.html`

### 2026-07-31 — Tier 1 Attendance PDF export (feature)

- [x] **Tier 1 (UK Team) dashboard missing PDF export on Attendance Reports** — reported by GP Bhai as "UK team can't download anything." Investigation found the RLS/backend layer was fine (Tier 1 has full `get_my_tier() <= 2` access everywhere); the gap was purely frontend — `dashboard-tier1.html` only had CSV/Excel buttons, no PDF, while Tier 2's equivalent section already had all three. Added the missing PDF branch to `downloadAdminAttendance()`, identical to Tier 2's print-to-PDF implementation. Broader finding: most of Blueprint §15.2's 17-category Report & Download Matrix is unbuilt across all tiers — tracked as a new Medium priority item above, to be built incrementally.
  → `dashboard-tier1.html`

### 2026-07-29 — Blueprint compliance audit + critical cron bug fixes

- [x] **NEWLY DISCOVERED & FIXED — `calculate_kpi_for_employee()` broke the monthly KPI cron job (Critical):** The Tier1/2 authorization check added earlier the same day used `auth.uid()`, which is NULL in a `pg_cron` context (no JWT). This meant `v_caller_tier` was NULL, and `NULL IS DISTINCT FROM 1` evaluates true, so the RAISE EXCEPTION fired for every employee at every month-end, silently breaking KPI scoring. Fixed by only enforcing the check when `auth.uid() IS NOT NULL` (a NULL auth context = trusted server-side call).
  → `migrations/20260729_audit_bugfixes.sql`

- [x] **NEWLY DISCOVERED & FIXED — duplicate pg_cron jobs racing on attendance (Medium):** `auto-absent-daily` and `bwapms-auto-absent-daily` were both scheduled at the same time doing the same "mark absent" job, racing against the `attendance` table's `UNIQUE(employee_id, attendance_date)` constraint. Removed the older, less complete job (the surviving one includes an `Audit_Logs` entry per Blueprint §14.2).
  → `migrations/20260729_audit_bugfixes.sql`

- [x] **Full Blueprint v1.2 vs. live-system compliance audit performed** — cross-checked all 22 Blueprint sections against actual tables, functions, cron jobs, and frontend dashboard sections. Findings split into High/Medium/Low priority gaps above. Key takeaway: attendance/leave/tasks/meetings/KPI-display/payroll-display/audit logging are functional; the automated *calculation engines* behind payroll, GPS fraud detection, leave balances, and 2FA/device-binding security are the biggest gaps.

### 2026-07-29 — Docs cleanup + RLS policy consolidation

- [x] **No `README.md` in repo root** — added one linking to `docs/BLUEPRINT.md` and `docs/PENDING_ISSUES.md`, with stack summary and repo layout for onboarding.
  → `README.md`

- [x] **Blueprint referenced outdated "Google AppSheet" stack** — corrected all 3 mentions in `docs/BLUEPRINT.md` (system overview, backup table, technical constraints) to reflect the actual stack (plain HTML/JS + Supabase), with an inline note explaining the correction for anyone reading the historical document.
  → `docs/BLUEPRINT.md`

- [x] **19 tables had overlapping/duplicate RLS policies** (all from the 2026-07-29 RLS migration, so exact definitions were known and safe to merge) — consolidated `disciplinary_actions`, `download_logs`, `duty_schedule`, `employee_exit`, `employee_ranking`, `grievances`, `helpdesk_tickets`, `holiday_master`, `issues`, `kpi_calculation_log`, `notification_preferences`, `penalty_history`, `responsibility_assignment`, `responsibility_master`, `salary_history`, `system_settings`, `task_updates`, `user_access`, `version_control`. Pattern: one combined SELECT policy per table instead of two overlapping ones, with command-specific INSERT/UPDATE/DELETE policies. Verified zero remaining overlaps on these 19 tables via `pg_policies` query.
  → `migrations/20260729_consolidate_rls_policies.sql`
  → **Remaining 15 legacy tables intentionally left alone** — see Medium Priority above.

### 2026-07-29 — Employee creation UI + self-service photo upload (feature)

- [x] **In-app "Add Employee" flow (Tier 2/1 dashboard)** — previously Tier 2 had to add employees directly in Supabase Dashboard and manually create login credentials, which was error-prone. Now:
  - New Edge Function `create-employee` (service-role, JWT-verified, Tier 1/2-only internally) atomically creates the Supabase Auth login **and** the `employee_master` row in one call, generates a temporary password, and returns it once for Tier 2 to share with the employee. Rolls back the auth user if the `employee_master` insert fails.
  - New "+ Add Employee" modal in `dashboard-tier2.html` (Employee Management section) with all onboarding fields (name, email, mobile, NID, designation, department, tier, reporting manager, joining date, salary, bank details) plus an optional photo upload at creation time.
  - Employee list table now shows a photo/initials avatar column.
  → `create-employee` edge function (deployed), `dashboard-tier2.html`

- [x] **Employee self-service photo change** — employees can now click their own sidebar avatar (Tier 2/3/4 dashboards) to upload/replace their own photo. Backed by:
  - New public storage bucket `employee-photos` (2MB limit, image/jpeg|png|webp only) with RLS: Tier 1/2 can manage any employee's photo; an employee can manage only their own (path-scoped by `employee_id`).
  - New `update_my_photo(p_photo_url)` SECURITY DEFINER function — updates *only* the caller's own `photo_url` column (not a general own-row UPDATE policy, so employees still cannot edit their own tier/salary/etc.).
  → storage bucket + policies, `update_my_photo()` function, `dashboard-tier1.html`, `dashboard-tier2.html`, `dashboard-tier3.html`, `dashboard-tier4.html` — all four tiers now covered. (Tier 1's login is a shared "UK Team" account per Blueprint §2.1; photo change applies to that shared account, not an individual.)

### 2026-07-29 — RLS & security hardening pass

- [x] **21 tables had RLS enabled but no policies** (deny-by-default, effectively inaccessible). Added tier-appropriate policies to all: `backup_logs`, `disciplinary_actions`, `download_logs`, `duty_schedule`, `employee_exit`, `employee_ranking`, `grievances`, `helpdesk_tickets`, `holiday_master`, `issues`, `kpi_calculation_log`, `notification_preferences`, `payroll_forecast`, `penalty_history`, `responsibility_assignment`, `responsibility_master`, `salary_history`, `system_settings`, `task_updates`, `user_access`, `version_control`.
  → `migrations/20260729_add_rls_policies_21_tables.sql`

- [x] **Overly permissive INSERT policies (`WITH CHECK (true)`)** on `audit_logs`, `login_logs`, `security_incidents` — tightened to require inserting user's own identity (or, for `login_logs`, a valid status value since pre-auth callers have no identity yet).
  → `migrations/20260729_security_hardening.sql`

- [x] **SECURITY DEFINER functions callable by anon/authenticated without restriction** — revoked EXECUTE from `anon`/`public` on `apply_task_delay_penalty()`, `calculate_kpi_for_employee()`, `tier1_unlock_payroll()`, `log_rule_change()`. `get_my_tier()`/`get_my_employee_id()` intentionally left open to `authenticated` (used throughout RLS policies).
  → `migrations/20260729_security_hardening.sql`

- [x] **8 functions missing `search_path`** — added `SET search_path = public` to all: `get_my_tier`, `get_my_employee_id`, `calculate_kpi_for_employee`, `apply_task_delay_penalty`, `tier1_unlock_payroll`, `enforce_sequential_task_lock`, `enforce_task_assignment_matrix`, `log_rule_change`.
  → `migrations/20260729_security_hardening.sql`

- [x] **NEWLY DISCOVERED & FIXED — `tier1_unlock_payroll()` NULL-tier bypass bug (Critical):** The check `IF v_caller_tier != 1 THEN RAISE EXCEPTION` silently passed when the caller had no `employee_master` row (e.g. was unauthenticated/anon), because `NULL != 1` evaluates to `NULL`, which PL/pgSQL's `IF` treats as false — so the exception never fired and ANY caller could unlock ANY payroll record. Fixed by changing to `IS DISTINCT FROM` (NULL-safe) **and** revoking anon's EXECUTE grant on the function as defense in depth.
  → `migrations/20260729_security_hardening.sql`

- [x] **NEWLY DISCOVERED & FIXED — `tier1_unlock_payroll()` broken audit log insert (Critical, functional bug):** The function inserted into `audit_logs` using columns (`event_type`, `table_affected`, `record_id_affected`) that don't exist on that table — every real invocation of this function would have errored out and failed to unlock payroll at all. Corrected to the actual column names (`action`, `table_name`, `record_id`).
  → `migrations/20260729_security_hardening.sql`

- [x] **NEWLY DISCOVERED & FIXED — `calculate_kpi_for_employee()` had no caller authorization check (Critical):** Any authenticated user (including Tier 3/4 staff) could call this RPC with an arbitrary `p_employee_id` and overwrite that employee's KPI scores. Added a Tier 1/2-only gate at the top of the function.
  → `migrations/20260729_security_hardening.sql`

- [x] **~40+ unindexed foreign keys** — found 67 via catalog scan, added covering `CREATE INDEX` for all of them.
  → `migrations/20260729_fk_indexes.sql`

- [x] **15+ RLS policies re-evaluating `auth.uid()` per row instead of once per query** — rewrote all 20 affected policies (`call_log`, `data_entry_log`, `employee_master`, `gps_exception_requests`, `help_requests`, `notifications`, `recurring_task_schedule`, `rule_change_log`, `rules_regulations`, `security_incidents`, `task_timer`, `user_sessions`) to wrap `auth.uid()` as `(select auth.uid())`, forcing it to evaluate once as an initplan.
  → `migrations/20260729_security_hardening.sql`

---

## Reference — Access & Environment

- **GitHub repo:** `md-noore-alam/BWAPMS` (branch: `main`)
- **Supabase project:** `BWAPMS-Database`, ref `lznqbrynniziquzawpfs`, region `ap-south-1`, Postgres 17.6.1
- **Frontend:** Plain HTML/JS (`index.html`, `dashboard-tier1-4.html`, `attendance.html`, `leave.html`, `tasks.html`, `app.js`, `styles.css`) — no build step, no framework
- **Auth:** Supabase Auth (`signInWithPassword`) + `get_my_tier()` RPC for tier-based redirect
- **48 tables total in `public` schema, all with RLS enabled and policies in place** (as of 2026-07-29)
