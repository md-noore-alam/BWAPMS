-- Migration: Add RLS policies to 21 tables that had RLS enabled but no policies
-- Date: 2026-07-29
-- Reference: docs/PENDING_ISSUES.md — High Priority item 1
-- Pattern follows existing convention: "Tier1_2 full access to X" / "Tier3_4 read own X"
-- using get_my_tier() and get_my_employee_id() helper functions already in use.

-- 1. backup_logs (system log, no employee_id — Tier 1/2 visibility only, per Section 18/20)
CREATE POLICY "Tier1_2 full access to backup_logs" ON public.backup_logs
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));

-- 2. disciplinary_actions (Section 11.1)
CREATE POLICY "Tier1_2 full access to disciplinary_actions" ON public.disciplinary_actions
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 read own disciplinary_actions" ON public.disciplinary_actions
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 3. download_logs (own downloads + Tier1_2 sees all, per Section 15.1/17)
CREATE POLICY "Tier1_2 full access to download_logs" ON public.download_logs
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 insert own download_logs" ON public.download_logs
  FOR INSERT TO authenticated WITH CHECK (employee_id = get_my_employee_id());
CREATE POLICY "Tier3_4 read own download_logs" ON public.download_logs
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 4. duty_schedule (Section 22.2)
CREATE POLICY "Tier1_2 full access to duty_schedule" ON public.duty_schedule
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 read own duty_schedule" ON public.duty_schedule
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 5. employee_exit (Section 4.4 — Tier1 approves, Tier2 confirms handover)
CREATE POLICY "Tier1_2 full access to employee_exit" ON public.employee_exit
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 read own employee_exit" ON public.employee_exit
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 6. employee_ranking (Section 13.7 — visible on own dashboard)
CREATE POLICY "Tier1_2 full access to employee_ranking" ON public.employee_ranking
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 read own employee_ranking" ON public.employee_ranking
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 7. grievances (Section 6.4 — employee submits own, Tier2/Tier1 decide)
CREATE POLICY "Tier1_2 full access to grievances" ON public.grievances
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 insert own grievances" ON public.grievances
  FOR INSERT TO authenticated WITH CHECK (employee_id = get_my_employee_id());
CREATE POLICY "Tier3_4 read own grievances" ON public.grievances
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 8. helpdesk_tickets (Section 19.1 — employee raises own ticket)
CREATE POLICY "Tier1_2 full access to helpdesk_tickets" ON public.helpdesk_tickets
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 insert own helpdesk_tickets" ON public.helpdesk_tickets
  FOR INSERT TO authenticated WITH CHECK (employee_id = get_my_employee_id());
CREATE POLICY "Tier3_4 read own helpdesk_tickets" ON public.helpdesk_tickets
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 9. holiday_master (Section 7 — visible to all as holiday calendar widget)
CREATE POLICY "Tier1_2 full access to holiday_master" ON public.holiday_master
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "All authenticated read holiday_master" ON public.holiday_master
  FOR SELECT TO authenticated USING (true);

-- 10. issues (Section 11 — any tier can report; Tier1_2 manage)
CREATE POLICY "Tier1_2 full access to issues" ON public.issues
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 insert issues" ON public.issues
  FOR INSERT TO authenticated WITH CHECK (reported_by = get_my_employee_id());
CREATE POLICY "Tier3_4 read own or assigned issues" ON public.issues
  FOR SELECT TO authenticated USING (reported_by = get_my_employee_id() OR assigned_to = get_my_employee_id());

-- 11. kpi_calculation_log (Section 13.6 — audit trail, own visibility)
CREATE POLICY "Tier1_2 full access to kpi_calculation_log" ON public.kpi_calculation_log
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 read own kpi_calculation_log" ON public.kpi_calculation_log
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 12. notification_preferences (Section 16 — each employee manages own)
CREATE POLICY "Tier1_2 full access to notification_preferences" ON public.notification_preferences
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Employees manage own notification_preferences" ON public.notification_preferences
  FOR ALL TO authenticated USING (employee_id = get_my_employee_id()) WITH CHECK (employee_id = get_my_employee_id());

-- 13. payroll_forecast (Section 12.8 — Tier 1 Executive Dashboard only, per blueprint)
CREATE POLICY "Tier1_2 full access to payroll_forecast" ON public.payroll_forecast
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));

-- 14. penalty_history (Section 9.2/13 — employee should see own penalties, per grievance transparency)
CREATE POLICY "Tier1_2 full access to penalty_history" ON public.penalty_history
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 read own penalty_history" ON public.penalty_history
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 15. responsibility_assignment (Section 8)
CREATE POLICY "Tier1_2 full access to responsibility_assignment" ON public.responsibility_assignment
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 read own responsibility_assignment" ON public.responsibility_assignment
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 16. responsibility_master (Section 8 — master/reference data, all read)
CREATE POLICY "Tier1_2 full access to responsibility_master" ON public.responsibility_master
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "All authenticated read responsibility_master" ON public.responsibility_master
  FOR SELECT TO authenticated USING (true);

-- 17. salary_history (Section 4.5 — sensitive, own visibility + Tier1_2)
CREATE POLICY "Tier1_2 full access to salary_history" ON public.salary_history
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 read own salary_history" ON public.salary_history
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 18. system_settings (Section 7.2/17 — config; all need to read e.g. maintenance flag)
CREATE POLICY "Tier1_2 full access to system_settings" ON public.system_settings
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "All authenticated read system_settings" ON public.system_settings
  FOR SELECT TO authenticated USING (true);

-- 19. task_updates (Section 9.6 — own task progress log)
CREATE POLICY "Tier1_2 full access to task_updates" ON public.task_updates
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Tier3_4 insert own task_updates" ON public.task_updates
  FOR INSERT TO authenticated WITH CHECK (employee_id = get_my_employee_id());
CREATE POLICY "Tier3_4 read own task_updates" ON public.task_updates
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 20. user_access (sensitive — session/permissions; own read only, Tier1_2 manage)
CREATE POLICY "Tier1_2 full access to user_access" ON public.user_access
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "Employees read own user_access" ON public.user_access
  FOR SELECT TO authenticated USING (employee_id = get_my_employee_id());

-- 21. version_control (Section 19.2 — change log, transparency to all)
CREATE POLICY "Tier1_2 full access to version_control" ON public.version_control
  FOR ALL TO authenticated USING (get_my_tier() = ANY (ARRAY[1,2]));
CREATE POLICY "All authenticated read version_control" ON public.version_control
  FOR SELECT TO authenticated USING (true);
