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

- [ ] **21 tables have RLS enabled but NO policies** — these tables are currently inaccessible to all roles (deny-by-default). Confirm which of these are actually needed by the live app, then add appropriate policies:
  `backup_logs`, `disciplinary_actions`, `download_logs`, `duty_schedule`, `employee_exit`, `employee_ranking`, `grievances`, `helpdesk_tickets`, `holiday_master`, `issues`, `kpi_calculation_log`, `notification_preferences`, `payroll_forecast`, `penalty_history`, `responsibility_assignment`, `responsibility_master`, `salary_history`, `system_settings`, `task_updates`, `user_access`, `version_control`

- [ ] **Overly permissive RLS policies (`WITH CHECK (true)`)** — these bypass row-level security for INSERT:
  - `audit_logs` → policy `System insert into audit_logs` (role: `-`)
  - `login_logs` → policy `login_logs_anon_insert` (role: `anon`)
  - `security_incidents` → policy `security_incidents_self_insert` (role: `authenticated`)
  Review whether `true` is intentional (e.g. system-level inserts) or needs tightening.

- [ ] **SECURITY DEFINER functions callable by `anon` / `authenticated` without restriction:**
  `apply_task_delay_penalty()`, `calculate_kpi_for_employee()`, `get_my_employee_id()`, `get_my_tier()`, `log_rule_change()`, `tier1_unlock_payroll()`
  Decide per-function whether public/authenticated execution is intended; revoke EXECUTE or switch to SECURITY INVOKER where not.

## 🟠 Medium Priority

- [ ] **8 functions missing `search_path`** (mutable search_path — potential security risk):
  `get_my_tier`, `get_my_employee_id`, `calculate_kpi_for_employee`, `apply_task_delay_penalty`, `tier1_unlock_payroll`, `enforce_sequential_task_lock`, `enforce_task_assignment_matrix`, `log_rule_change`
  Fix: add `SET search_path = public` (or appropriate schema) to each function definition.

- [ ] **Leaked Password Protection disabled** in Supabase Auth — enable HaveIBeenPwned check for new passwords.

- [ ] **~40+ unindexed foreign keys** across tables (`attendance`, `disciplinary_actions`, `payroll`, `task_master`, `meetings`, etc. — full list in audit). Add covering indexes for frequently-queried FKs.

- [ ] **30+ "multiple permissive policies" findings** — several tables have overlapping RLS policies for the same role+action (e.g. `attendance`, `audit_logs`, `call_log`, `daily_reports`, `data_entry_log`, `employee_master`, `gps_exception_requests`, `gps_log`, `help_requests`, `intelligence_alerts`, `kpi_scores`, `payroll`, `rules_regulations`, `task_master`, `task_timer`). Each policy runs on every query — consolidate where possible for performance.

- [ ] **15+ RLS policies re-evaluate `auth.<function>()` per row** instead of once per query. Fix pattern: replace `auth.uid()` with `(select auth.uid())` inside policy definitions. Affected tables: `task_timer`, `recurring_task_schedule`, `notifications`, `user_sessions`, `security_incidents`, `employee_master`, `gps_exception_requests`, `rules_regulations`, `rule_change_log`, `data_entry_log`, `call_log`, `help_requests`.

## 🟢 Low Priority

- [ ] **10 unused indexes** (never used since creation) — candidates for removal if confirmed genuinely unused after more production traffic: `idx_attendance_status`, `idx_gps_log_risk`, `idx_task_master_deadline`, `idx_payroll_employee_month`, `idx_kpi_scores_employee`, `idx_audit_logs_user`, `idx_audit_logs_risk`, `idx_audit_logs_module`, `idx_penalty_history_employee`, `idx_gps_exception_employee_status`, `idx_data_entry_employee_date`, `idx_call_log_employee_date`, `idx_help_requests_status`, `idx_task_timer_task_running`, `idx_notifications_employee_unread`. (Note: dataset is still small — revisit after more real usage before removing.)

## 📝 Documentation / Process Notes

- [ ] Blueprint v1.2 (`docs/BLUEPRINT.md`) references **Google AppSheet + Supabase** as the platform, but the actual live repo is pure HTML/JS + Supabase (no AppSheet). Confirm with GP Bhai whether to update the Blueprint wording to reflect the actual stack.
- [ ] No `README.md` currently in repo root — consider adding one that links to `docs/BLUEPRINT.md` and this file for onboarding.

---

## ✅ Resolved

*(none yet)*

---

## Reference — Access & Environment

- **GitHub repo:** `md-noore-alam/BWAPMS` (branch: `main`)
- **Supabase project:** `BWAPMS-Database`, ref `lznqbrynniziquzawpfs`, region `ap-south-1`, Postgres 17.6.1
- **Frontend:** Plain HTML/JS (`index.html`, `dashboard-tier1-4.html`, `attendance.html`, `leave.html`, `tasks.html`, `app.js`, `styles.css`) — no build step, no framework
- **Auth:** Supabase Auth (`signInWithPassword`) + `get_my_tier()` RPC for tier-based redirect
- **48 tables total in `public` schema, all with RLS enabled** (21 currently have no policies — see High Priority above)
