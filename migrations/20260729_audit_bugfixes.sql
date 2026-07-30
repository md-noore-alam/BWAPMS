-- Migration: Fix critical bugs found during Blueprint compliance audit
-- Date: 2026-07-29

-- BUG FIX 1: calculate_kpi_for_employee() Tier1/2 auth check (added in the
-- 2026-07-29 security hardening pass) broke the "monthly-kpi-calculation"
-- pg_cron job, because auth.uid() returns NULL in a cron/service context
-- (no JWT), so the RAISE EXCEPTION fired for every employee every month end.
-- Fix: only enforce the tier check when there IS an authenticated caller.
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
    IF auth.uid() IS NOT NULL THEN
        SELECT tier INTO v_caller_tier FROM employee_master WHERE employee_id = auth.uid();
        IF v_caller_tier IS DISTINCT FROM 1 AND v_caller_tier IS DISTINCT FROM 2 THEN
            RAISE EXCEPTION 'Access denied: শুধু Tier 1/2 KPI recalculate করতে পারবেন';
        END IF;
    END IF;
    -- auth.uid() IS NULL means this is a trusted server-side call (pg_cron/service role) -- allowed.

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

REVOKE EXECUTE ON FUNCTION public.calculate_kpi_for_employee(uuid, date, date) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.calculate_kpi_for_employee(uuid, date, date) TO authenticated;

-- BUG FIX 2: Two pg_cron jobs ("auto-absent-daily" and "bwapms-auto-absent-daily")
-- were both scheduled at the same time doing the same job (mark absent employees
-- with no check-in), racing against attendance's UNIQUE(employee_id, attendance_date)
-- constraint. Removed the older, less complete one (no audit logging).
SELECT cron.unschedule('auto-absent-daily');
-- Kept: 'bwapms-auto-absent-daily' (includes Audit_Logs entry per Blueprint §14.2).
