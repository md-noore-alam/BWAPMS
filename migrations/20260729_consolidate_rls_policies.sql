-- Migration: Consolidate duplicate/overlapping RLS policies on 19 tables
-- Date: 2026-07-29
-- Reference: docs/PENDING_ISSUES.md -- Medium Priority "multiple permissive policies"
-- Scope: only tables where BOTH overlapping policies were created in the
-- 2026-07-29 RLS migration (known exact definitions, safe to merge).
-- Legacy pre-existing overlaps on attendance/audit_logs/call_log/daily_reports/
-- data_entry_log/employee_master/gps_exception_requests/gps_log/help_requests/
-- kpi_scores/payroll/task_master/task_timer/intelligence_alerts/rules_regulations
-- are intentionally NOT touched here -- their exact original intent/roles need
-- a manual table-by-table review before merging (see docs/PENDING_ISSUES.md).

-- Pattern: split "Tier1_2 full access" (FOR ALL) into command-specific
-- INSERT/UPDATE/DELETE policies, and merge the SELECT-only Tier1/2 and
-- Tier3/4-own conditions into ONE combined SELECT policy per table.

-- 1. disciplinary_actions
DROP POLICY "Tier1_2 full access to disciplinary_actions" ON public.disciplinary_actions;
DROP POLICY "Tier3_4 read own disciplinary_actions" ON public.disciplinary_actions;
CREATE POLICY "select_disciplinary_actions" ON public.disciplinary_actions FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_disciplinary_actions" ON public.disciplinary_actions FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_disciplinary_actions" ON public.disciplinary_actions FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_disciplinary_actions" ON public.disciplinary_actions FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 2. download_logs
DROP POLICY "Tier1_2 full access to download_logs" ON public.download_logs;
DROP POLICY "Tier3_4 insert own download_logs" ON public.download_logs;
DROP POLICY "Tier3_4 read own download_logs" ON public.download_logs;
CREATE POLICY "select_download_logs" ON public.download_logs FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "insert_download_logs" ON public.download_logs FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "update_download_logs" ON public.download_logs FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_download_logs" ON public.download_logs FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 3. duty_schedule
DROP POLICY "Tier1_2 full access to duty_schedule" ON public.duty_schedule;
DROP POLICY "Tier3_4 read own duty_schedule" ON public.duty_schedule;
CREATE POLICY "select_duty_schedule" ON public.duty_schedule FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_duty_schedule" ON public.duty_schedule FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_duty_schedule" ON public.duty_schedule FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_duty_schedule" ON public.duty_schedule FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 4. employee_exit
DROP POLICY "Tier1_2 full access to employee_exit" ON public.employee_exit;
DROP POLICY "Tier3_4 read own employee_exit" ON public.employee_exit;
CREATE POLICY "select_employee_exit" ON public.employee_exit FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_employee_exit" ON public.employee_exit FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_employee_exit" ON public.employee_exit FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_employee_exit" ON public.employee_exit FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 5. employee_ranking
DROP POLICY "Tier1_2 full access to employee_ranking" ON public.employee_ranking;
DROP POLICY "Tier3_4 read own employee_ranking" ON public.employee_ranking;
CREATE POLICY "select_employee_ranking" ON public.employee_ranking FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_employee_ranking" ON public.employee_ranking FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_employee_ranking" ON public.employee_ranking FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_employee_ranking" ON public.employee_ranking FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 6. grievances
DROP POLICY "Tier1_2 full access to grievances" ON public.grievances;
DROP POLICY "Tier3_4 insert own grievances" ON public.grievances;
DROP POLICY "Tier3_4 read own grievances" ON public.grievances;
CREATE POLICY "select_grievances" ON public.grievances FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "insert_grievances" ON public.grievances FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "update_grievances" ON public.grievances FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_grievances" ON public.grievances FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 7. helpdesk_tickets
DROP POLICY "Tier1_2 full access to helpdesk_tickets" ON public.helpdesk_tickets;
DROP POLICY "Tier3_4 insert own helpdesk_tickets" ON public.helpdesk_tickets;
DROP POLICY "Tier3_4 read own helpdesk_tickets" ON public.helpdesk_tickets;
CREATE POLICY "select_helpdesk_tickets" ON public.helpdesk_tickets FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "insert_helpdesk_tickets" ON public.helpdesk_tickets FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "update_helpdesk_tickets" ON public.helpdesk_tickets FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_helpdesk_tickets" ON public.helpdesk_tickets FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 8. holiday_master
DROP POLICY "Tier1_2 full access to holiday_master" ON public.holiday_master;
DROP POLICY "All authenticated read holiday_master" ON public.holiday_master;
CREATE POLICY "select_holiday_master" ON public.holiday_master FOR SELECT TO authenticated USING (true);
CREATE POLICY "write_holiday_master" ON public.holiday_master FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_holiday_master" ON public.holiday_master FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_holiday_master" ON public.holiday_master FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 9. issues
DROP POLICY "Tier1_2 full access to issues" ON public.issues;
DROP POLICY "Tier3_4 insert issues" ON public.issues;
DROP POLICY "Tier3_4 read own or assigned issues" ON public.issues;
CREATE POLICY "select_issues" ON public.issues FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR reported_by = get_my_employee_id() OR assigned_to = get_my_employee_id());
CREATE POLICY "insert_issues" ON public.issues FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2 OR reported_by = get_my_employee_id());
CREATE POLICY "update_issues" ON public.issues FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_issues" ON public.issues FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 10. kpi_calculation_log
DROP POLICY "Tier1_2 full access to kpi_calculation_log" ON public.kpi_calculation_log;
DROP POLICY "Tier3_4 read own kpi_calculation_log" ON public.kpi_calculation_log;
CREATE POLICY "select_kpi_calculation_log" ON public.kpi_calculation_log FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_kpi_calculation_log" ON public.kpi_calculation_log FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_kpi_calculation_log" ON public.kpi_calculation_log FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_kpi_calculation_log" ON public.kpi_calculation_log FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 11. notification_preferences (both were FOR ALL -> merge into one FOR ALL)
DROP POLICY "Tier1_2 full access to notification_preferences" ON public.notification_preferences;
DROP POLICY "Employees manage own notification_preferences" ON public.notification_preferences;
CREATE POLICY "manage_notification_preferences" ON public.notification_preferences FOR ALL TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id())
  WITH CHECK (get_my_tier() <= 2 OR employee_id = get_my_employee_id());

-- 12. penalty_history
DROP POLICY "Tier1_2 full access to penalty_history" ON public.penalty_history;
DROP POLICY "Tier3_4 read own penalty_history" ON public.penalty_history;
CREATE POLICY "select_penalty_history" ON public.penalty_history FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_penalty_history" ON public.penalty_history FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_penalty_history" ON public.penalty_history FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_penalty_history" ON public.penalty_history FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 13. responsibility_assignment
DROP POLICY "Tier1_2 full access to responsibility_assignment" ON public.responsibility_assignment;
DROP POLICY "Tier3_4 read own responsibility_assignment" ON public.responsibility_assignment;
CREATE POLICY "select_responsibility_assignment" ON public.responsibility_assignment FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_responsibility_assignment" ON public.responsibility_assignment FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_responsibility_assignment" ON public.responsibility_assignment FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_responsibility_assignment" ON public.responsibility_assignment FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 14. responsibility_master
DROP POLICY "Tier1_2 full access to responsibility_master" ON public.responsibility_master;
DROP POLICY "All authenticated read responsibility_master" ON public.responsibility_master;
CREATE POLICY "select_responsibility_master" ON public.responsibility_master FOR SELECT TO authenticated USING (true);
CREATE POLICY "write_responsibility_master" ON public.responsibility_master FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_responsibility_master" ON public.responsibility_master FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_responsibility_master" ON public.responsibility_master FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 15. salary_history
DROP POLICY "Tier1_2 full access to salary_history" ON public.salary_history;
DROP POLICY "Tier3_4 read own salary_history" ON public.salary_history;
CREATE POLICY "select_salary_history" ON public.salary_history FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_salary_history" ON public.salary_history FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_salary_history" ON public.salary_history FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_salary_history" ON public.salary_history FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 16. system_settings
DROP POLICY "Tier1_2 full access to system_settings" ON public.system_settings;
DROP POLICY "All authenticated read system_settings" ON public.system_settings;
CREATE POLICY "select_system_settings" ON public.system_settings FOR SELECT TO authenticated USING (true);
CREATE POLICY "write_system_settings" ON public.system_settings FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_system_settings" ON public.system_settings FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_system_settings" ON public.system_settings FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 17. task_updates
DROP POLICY "Tier1_2 full access to task_updates" ON public.task_updates;
DROP POLICY "Tier3_4 insert own task_updates" ON public.task_updates;
DROP POLICY "Tier3_4 read own task_updates" ON public.task_updates;
CREATE POLICY "select_task_updates" ON public.task_updates FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "insert_task_updates" ON public.task_updates FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "update_task_updates" ON public.task_updates FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_task_updates" ON public.task_updates FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 18. user_access
DROP POLICY "Tier1_2 full access to user_access" ON public.user_access;
DROP POLICY "Employees read own user_access" ON public.user_access;
CREATE POLICY "select_user_access" ON public.user_access FOR SELECT TO authenticated
  USING (get_my_tier() <= 2 OR employee_id = get_my_employee_id());
CREATE POLICY "write_user_access" ON public.user_access FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_user_access" ON public.user_access FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_user_access" ON public.user_access FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);

-- 19. version_control
DROP POLICY "Tier1_2 full access to version_control" ON public.version_control;
DROP POLICY "All authenticated read version_control" ON public.version_control;
CREATE POLICY "select_version_control" ON public.version_control FOR SELECT TO authenticated USING (true);
CREATE POLICY "write_version_control" ON public.version_control FOR INSERT TO authenticated
  WITH CHECK (get_my_tier() <= 2);
CREATE POLICY "update_version_control" ON public.version_control FOR UPDATE TO authenticated
  USING (get_my_tier() <= 2);
CREATE POLICY "delete_version_control" ON public.version_control FOR DELETE TO authenticated
  USING (get_my_tier() <= 2);
