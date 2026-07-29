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

## 🟠 Medium Priority

- [ ] **Leaked Password Protection disabled** in Supabase Auth — cannot be toggled via SQL/API, needs manual action.
  **Action needed (GP Bhai):** Supabase Dashboard → Authentication → Providers → Email → enable "Leaked password protection" (HaveIBeenPwned check).

- [ ] **30+ "multiple permissive policies" findings** — several tables have overlapping RLS policies for the same role+action (e.g. `attendance`, `audit_logs`, `call_log`, `daily_reports`, `data_entry_log`, `employee_master`, `gps_exception_requests`, `gps_log`, `help_requests`, `intelligence_alerts`, `kpi_scores`, `payroll`, `rules_regulations`, `task_master`, `task_timer`). Each extra policy adds overhead per query. **Deliberately not auto-merged** — consolidating overlapping policies risks accidentally narrowing or widening access; needs a careful table-by-table review with GP Bhai before combining any of them.

## 🟢 Low Priority

- [ ] **10 unused indexes** (never used since creation) — candidates for removal if confirmed genuinely unused after more production traffic: `idx_attendance_status`, `idx_gps_log_risk`, `idx_task_master_deadline`, `idx_payroll_employee_month`, `idx_kpi_scores_employee`, `idx_audit_logs_user`, `idx_audit_logs_risk`, `idx_audit_logs_module`, `idx_penalty_history_employee`, `idx_gps_exception_employee_status`, `idx_data_entry_employee_date`, `idx_call_log_employee_date`, `idx_help_requests_status`, `idx_task_timer_task_running`, `idx_notifications_employee_unread`. (Note: dataset is still small — revisit after more real usage before removing.)

## 📝 Documentation / Process Notes

- [ ] Blueprint v1.2 (`docs/BLUEPRINT.md`) references **Google AppSheet + Supabase** as the platform, but the actual live repo is pure HTML/JS + Supabase (no AppSheet). Confirm with GP Bhai whether to update the Blueprint wording to reflect the actual stack.
- [ ] No `README.md` currently in repo root — consider adding one that links to `docs/BLUEPRINT.md` and this file for onboarding.

---

## ✅ Resolved

### 2026-07-29 — Employee creation UI + self-service photo upload (feature)

- [x] **In-app "Add Employee" flow (Tier 2/1 dashboard)** — previously Tier 2 had to add employees directly in Supabase Dashboard and manually create login credentials, which was error-prone. Now:
  - New Edge Function `create-employee` (service-role, JWT-verified, Tier 1/2-only internally) atomically creates the Supabase Auth login **and** the `employee_master` row in one call, generates a temporary password, and returns it once for Tier 2 to share with the employee. Rolls back the auth user if the `employee_master` insert fails.
  - New "+ Add Employee" modal in `dashboard-tier2.html` (Employee Management section) with all onboarding fields (name, email, mobile, NID, designation, department, tier, reporting manager, joining date, salary, bank details) plus an optional photo upload at creation time.
  - Employee list table now shows a photo/initials avatar column.
  → `create-employee` edge function (deployed), `dashboard-tier2.html`

- [x] **Employee self-service photo change** — employees can now click their own sidebar avatar (Tier 2/3/4 dashboards) to upload/replace their own photo. Backed by:
  - New public storage bucket `employee-photos` (2MB limit, image/jpeg|png|webp only) with RLS: Tier 1/2 can manage any employee's photo; an employee can manage only their own (path-scoped by `employee_id`).
  - New `update_my_photo(p_photo_url)` SECURITY DEFINER function — updates *only* the caller's own `photo_url` column (not a general own-row UPDATE policy, so employees still cannot edit their own tier/salary/etc.).
  → storage bucket + policies, `update_my_photo()` function, `dashboard-tier2.html`, `dashboard-tier3.html`, `dashboard-tier4.html`
  → **Not yet done for `dashboard-tier1.html`** — Tier 1's sidebar avatar is currently static/hardcoded ("UK") and not wired to `employee_master` at all; lower priority since Tier 1 is exempt from most tracked modules per Blueprint §2.1, but flagged here in case GP Bhai wants it added later.

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
