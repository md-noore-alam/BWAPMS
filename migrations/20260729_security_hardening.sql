-- Migration: Security hardening pass
-- Date: 2026-07-29
-- Reference: docs/PENDING_ISSUES.md — High/Medium Priority items

-- ============================================================
-- 1. Tighten overly permissive INSERT policies (WITH CHECK true)
-- ============================================================
DROP POLICY "System insert into audit_logs" ON public.audit_logs;
CREATE POLICY "Authenticated insert own audit_logs" ON public.audit_logs
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY "security_incidents_self_insert" ON public.security_incidents;
CREATE POLICY "security_incidents_self_insert" ON public.security_incidents
  FOR INSERT TO authenticated WITH CHECK (employee_id = get_my_employee_id());

DROP POLICY "login_logs_anon_insert" ON public.login_logs;
CREATE POLICY "login_logs_anon_insert" ON public.login_logs
  FOR INSERT TO anon, authenticated
  WITH CHECK (login_status IN ('Success','Failed'));

-- ============================================================
-- 2. Restrict SECURITY DEFINER function execution + fix bugs found during review
-- ============================================================
REVOKE EXECUTE ON FUNCTION public.apply_task_delay_penalty() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.calculate_kpi_for_employee(uuid, date, date) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.tier1_unlock_payroll(uuid, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.log_rule_change() FROM PUBLIC, anon, authenticated;

-- BUG FIX: tier1_unlock_payroll had two bugs —
--   (a) NULL-tier bypass: `v_caller_tier != 1` is NULL (not TRUE) when caller has no
--       employee_master row, so the RAISE EXCEPTION was silently skipped, allowing
--       ANY caller (including unauthenticated) to unlock payroll records.
--   (b) audit_logs insert used non-existent columns (event_type/table_affected/
--       record_id_affected), so every real call would have errored out.
CREATE OR REPLACE FUNCTION public.tier1_unlock_payroll(p_payroll_id uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
DECLARE v_caller_tier INT;
BEGIN
    SELECT tier INTO v_caller_tier FROM employee_master WHERE employee_id = auth.uid();
    IF v_caller_tier IS DISTINCT FROM 1 THEN
        RAISE EXCEPTION 'Access denied: শুধু Tier 1 payroll unlock করতে পারবেন';
    END IF;
    UPDATE payroll SET is_locked = FALSE, adjustment_reason = p_reason
    WHERE payroll_id = p_payroll_id;
    INSERT INTO audit_logs (action, user_id, table_name, record_id,
        risk_score, risk_level, description)
    VALUES ('Payroll_Unlock', auth.uid(), 'payroll', p_payroll_id, 5, 'Medium', p_reason);
END;
$function$;

-- BUG FIX: calculate_kpi_for_employee had no caller authorization check at all —
-- any authenticated user could recalculate/overwrite ANY other employee's KPI record
-- by calling this RPC with an arbitrary p_employee_id. Added Tier 1/2 gate.
CREATE OR REPLACE FUNCTION public.calculate_kpi_for_employee(p_employee_id uuid, p_period_start date, p_period_end date)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path = public
AS $function$
DECLARE
    v_caller_tier       INT;
    v_working_days      INT;
    v_present_days      INT;
    v_attendance_score  NUMERIC;
    v_task_score        NUMERIC;
    v_reporting_score   NUMERIC;
    v_issue_score       NUMERIC := 75;
    v_efficiency_score  NUMERIC := 75;
    v_mgmt_eval_score   NUMERIC;
BEGIN
    SELECT tier INTO v_caller_tier FROM employee_master WHERE employee_id = auth.uid();
    IF v_caller_tier IS DISTINCT FROM 1 AND v_caller_tier IS DISTINCT FROM 2 THEN
        RAISE EXCEPTION 'Access denied: শুধু Tier 1/2 KPI recalculate করতে পারবেন';
    END IF;

    SELECT COUNT(*) INTO v_working_days
    FROM generate_series(p_period_start, p_period_end, '1 day'::interval) d(day)
    WHERE EXTRACT(DOW FROM d.day) != 5;

    SELECT COUNT(*) INTO v_present_days
    FROM attendance
    WHERE employee_id = p_employee_id
      AND attendance_date BETWEEN p_period_start AND p_period_end
      AND status IN ('Present','Late','Field / Official Visit');

    v_attendance_score := CASE
        WHEN v_working_days > 0
        THEN ROUND((v_present_days::NUMERIC / v_working_days) * 100, 2)
        ELSE 0 END;

    SELECT COALESCE(ROUND(
        SUM(CASE WHEN status = 'Completed_On_Time' THEN performance_impact_score ELSE 0 END)::NUMERIC
        / NULLIF(SUM(performance_impact_score), 0) * 100, 2), 0)
    INTO v_task_score
    FROM task_master
    WHERE primary_assignee = p_employee_id
      AND due_date BETWEEN p_period_start AND p_period_end
      AND is_active = TRUE;

    SELECT COALESCE(ROUND(COUNT(*)::NUMERIC / NULLIF(v_working_days, 0) * 100, 2), 0)
    INTO v_reporting_score
    FROM daily_reports
    WHERE employee_id = p_employee_id
      AND report_date BETWEEN p_period_start AND p_period_end
      AND status = 'Submitted';

    SELECT total_score INTO v_mgmt_eval_score
    FROM performance_evaluation
    WHERE employee_id = p_employee_id
    ORDER BY created_at DESC LIMIT 1;

    INSERT INTO kpi_scores (
        employee_id, period_type, period_start, period_end,
        attendance_score, task_performance_score, reporting_discipline_score,
        issue_resolution_score, work_efficiency_score, management_eval_score,
        is_negative_allowed
    ) VALUES (
        p_employee_id, 'Monthly', p_period_start, p_period_end,
        v_attendance_score, v_task_score, v_reporting_score,
        v_issue_score, v_efficiency_score,
        COALESCE(v_mgmt_eval_score, 75), TRUE
    )
    ON CONFLICT (employee_id, period_type, period_start)
    DO UPDATE SET
        attendance_score           = EXCLUDED.attendance_score,
        task_performance_score     = EXCLUDED.task_performance_score,
        reporting_discipline_score = EXCLUDED.reporting_discipline_score,
        issue_resolution_score     = EXCLUDED.issue_resolution_score,
        work_efficiency_score      = EXCLUDED.work_efficiency_score,
        updated_at                 = NOW();
END;
$function$;

-- ============================================================
-- 3. Fix mutable search_path on all flagged functions
-- ============================================================
ALTER FUNCTION public.get_my_tier() SET search_path = public;
ALTER FUNCTION public.get_my_employee_id() SET search_path = public;
ALTER FUNCTION public.enforce_sequential_task_lock() SET search_path = public;
ALTER FUNCTION public.enforce_task_assignment_matrix() SET search_path = public;
ALTER FUNCTION public.log_rule_change() SET search_path = public;
-- (calculate_kpi_for_employee and tier1_unlock_payroll already include
--  SET search_path = public in their CREATE OR REPLACE above)

-- ============================================================
-- 4. Rewrap auth.uid() as (select auth.uid()) in RLS policies so it evaluates
--    once per query (initplan) instead of once per row — perf fix, 20 policies.
-- ============================================================
DROP POLICY "call_log_tier1_2_view" ON public.call_log;
CREATE POLICY "call_log_tier1_2_view" ON public.call_log FOR SELECT TO public
  USING ((SELECT employee_master.tier FROM employee_master WHERE employee_master.employee_id = (select auth.uid())) = ANY (ARRAY[1,2]));

DROP POLICY "call_log_own" ON public.call_log;
CREATE POLICY "call_log_own" ON public.call_log FOR ALL TO public
  USING (employee_id = (select auth.uid()));

DROP POLICY "data_entry_own" ON public.data_entry_log;
CREATE POLICY "data_entry_own" ON public.data_entry_log FOR ALL TO public
  USING (employee_id = (select auth.uid()));

DROP POLICY "data_entry_tier1_2_view" ON public.data_entry_log;
CREATE POLICY "data_entry_tier1_2_view" ON public.data_entry_log FOR SELECT TO public
  USING ((SELECT employee_master.tier FROM employee_master WHERE employee_master.employee_id = (select auth.uid())) = ANY (ARRAY[1,2]));

DROP POLICY "employee_master_select" ON public.employee_master;
CREATE POLICY "employee_master_select" ON public.employee_master FOR SELECT TO public
  USING (auth_user_id = (select auth.uid()) OR (SELECT get_my_tier()) <= 2);

DROP POLICY "gps_exc_tier1_2_full" ON public.gps_exception_requests;
CREATE POLICY "gps_exc_tier1_2_full" ON public.gps_exception_requests FOR ALL TO public
  USING ((SELECT employee_master.tier FROM employee_master WHERE employee_master.employee_id = (select auth.uid())) = ANY (ARRAY[1,2]));

DROP POLICY "gps_exc_own_select" ON public.gps_exception_requests;
CREATE POLICY "gps_exc_own_select" ON public.gps_exception_requests FOR SELECT TO public
  USING (employee_id = (select auth.uid()));

DROP POLICY "help_req_sender" ON public.help_requests;
CREATE POLICY "help_req_sender" ON public.help_requests FOR ALL TO public
  USING (from_employee_id = (select auth.uid()));

DROP POLICY "help_req_tier1_2" ON public.help_requests;
CREATE POLICY "help_req_tier1_2" ON public.help_requests FOR SELECT TO public
  USING ((SELECT employee_master.tier FROM employee_master WHERE employee_master.employee_id = (select auth.uid())) = ANY (ARRAY[1,2]));

DROP POLICY "help_req_receiver_update" ON public.help_requests;
CREATE POLICY "help_req_receiver_update" ON public.help_requests FOR UPDATE TO public
  USING (to_employee_id = (select auth.uid()));

DROP POLICY "help_req_receiver_view" ON public.help_requests;
CREATE POLICY "help_req_receiver_view" ON public.help_requests FOR SELECT TO public
  USING (to_employee_id = (select auth.uid()));

DROP POLICY "notifications_own" ON public.notifications;
CREATE POLICY "notifications_own" ON public.notifications FOR ALL TO public
  USING (employee_id = (select auth.uid()));

DROP POLICY "recurring_task_tier1_2" ON public.recurring_task_schedule;
CREATE POLICY "recurring_task_tier1_2" ON public.recurring_task_schedule FOR ALL TO public
  USING ((SELECT employee_master.tier FROM employee_master WHERE employee_master.employee_id = (select auth.uid())) = ANY (ARRAY[1,2]));

DROP POLICY "rule_log_tier1_2_view" ON public.rule_change_log;
CREATE POLICY "rule_log_tier1_2_view" ON public.rule_change_log FOR SELECT TO public
  USING ((SELECT employee_master.tier FROM employee_master WHERE employee_master.employee_id = (select auth.uid())) = ANY (ARRAY[1,2]));

DROP POLICY "rules_tier1_2_manage" ON public.rules_regulations;
CREATE POLICY "rules_tier1_2_manage" ON public.rules_regulations FOR ALL TO public
  USING ((SELECT employee_master.tier FROM employee_master WHERE employee_master.employee_id = (select auth.uid())) = ANY (ARRAY[1,2]));

DROP POLICY "security_incidents_tier12_select" ON public.security_incidents;
CREATE POLICY "security_incidents_tier12_select" ON public.security_incidents FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM employee_master WHERE employee_master.auth_user_id = (select auth.uid()) AND employee_master.tier = ANY (ARRAY[1,2])));

DROP POLICY "task_timer_own" ON public.task_timer;
CREATE POLICY "task_timer_own" ON public.task_timer FOR ALL TO public
  USING (employee_id = (select auth.uid()));

DROP POLICY "task_timer_tier1_2_view" ON public.task_timer;
CREATE POLICY "task_timer_tier1_2_view" ON public.task_timer FOR SELECT TO public
  USING ((SELECT employee_master.tier FROM employee_master WHERE employee_master.employee_id = (select auth.uid())) = ANY (ARRAY[1,2]));

DROP POLICY "user_sessions_self_select" ON public.user_sessions;
CREATE POLICY "user_sessions_self_select" ON public.user_sessions FOR SELECT TO public
  USING (employee_id IN (SELECT employee_master.employee_id FROM employee_master WHERE employee_master.auth_user_id = (select auth.uid())));

DROP POLICY "user_sessions_self_update" ON public.user_sessions;
CREATE POLICY "user_sessions_self_update" ON public.user_sessions FOR UPDATE TO public
  USING (employee_id IN (SELECT employee_master.employee_id FROM employee_master WHERE employee_master.auth_user_id = (select auth.uid())));

-- NOTE: "Leaked Password Protection" (Supabase Auth setting) could NOT be enabled via
-- SQL/API — must be toggled manually in Supabase Dashboard: Authentication > Providers
-- > Email > Leaked password protection.
