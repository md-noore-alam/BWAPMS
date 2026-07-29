# BWAPMS — Bangladesh Workforce & Programme Management System

**BRPHI Bangladesh Country Office | GramGP Programme**
**Enterprise System Blueprint — Version 1.2 (Ultimate Locked Edition)**

| Field | Value |
|---|---|
| Organization | Bangladesh Rural Primary Health Initiative (BRPHI) |
| Programme | GramGP |
| Office | BRPHI Bangladesh Country Office |
| Address | Rahim Tower, Subhanighat, Sylhet, Bangladesh |
| GPS (HQ) | Lat: 24.890144, Long: 91.879072, Radius: 50 m |
| Document Version | v1.2 — Ultimate Locked Edition |
| Workforce | 10 Employees (Permanent, Full-Time) |
| Version History | v1.0 (Baseline) → v1.1 (Interim) → v1.2 (Current) |

> CONFIDENTIAL — FOR INTERNAL USE ONLY

---

## Section 1 — System Overview & Objectives

BWAPMS v1.2 is an enterprise-grade, centralized workforce and programme management platform for BRPHI's GramGP programme at the Bangladesh Country Office. The system manages 10 permanent, full-time employees across four governance tiers. Built on plain HTML/CSS/JavaScript (no framework, no build step) with Supabase (PostgreSQL, Auth, Storage, and Edge Functions) as the backend, it operates as a responsive Progressive Web Application optimized for 3G/4G connectivity.

> **Note (2026-07-29):** Earlier drafts of this Blueprint referenced Google AppSheet as part of the platform. The live system does not use AppSheet — the frontend is hand-built static HTML/JS. This section has been corrected to match the actual deployed stack.

### 1.1 Core Management Domains

| Domain | Primary Functions | Key Outputs |
|---|---|---|
| Workforce Management | Employee profiles, 4-tier governance, onboarding, offboarding, responsibility assignment, task & progress management | Accountability records, task logs, work plans |
| Hybrid Attendance & GPS | Whitelisted GPS check-in/out (HQ + approved field locations), no continuous tracking, offline sync cache | Attendance reports, field visit compliance logs |
| Payroll & HR | Automated payroll with pro-rata late deduction, leave management, salary slips, disciplinary records | Payslips, leave balances, salary history |
| Performance Management | 4-tier KPI framework, productivity-per-hour tracking, automated penalty engine, predictive analytics | KPI scores, rankings, forecasts |
| Meeting & Collaboration | Meeting creation, minutes, action items, decision tracking, field visit compliance cross-reference | Meeting logs, action status reports |
| Governance & Compliance | Risk-scored audit trail, automated alerts, disciplinary process, grievance management | Audit trail, compliance reports, risk alerts |

---

## Section 2 — Four-Tier Role Hierarchy & Cascading Delegation

Tiers 2, 3, and 4 are subject to both office-based and intermittent official field visit workflows. Tier 1 is exempt from daily field/office operational modules.

### 2.1 Tier Definitions

- **Tier 1 — Super Admin (UK):** Executive Strategic Governance. Exempt from daily field/office modules. Holds absolute system authority: system configuration, payroll unlock, frozen audit override, all administrative decisions, final grievance resolution. Approves all BD Head leave and attendance corrections. Evaluates BD Head quarterly KPI. No attendance, leave, or payroll tracking — voluntary management role.
- **Tier 2 — Country Head (BD):** Full Local Administrative Authority. Subject to intermittent official field visits. Manages all employees (Tiers 3 & 4). Processes payroll (including own based on deduction data). Initiates disciplinary actions. Approves leave, attendance corrections, GPS exceptions, and emergency declarations for Tiers 3 & 4. Cannot self-approve own attendance corrections — escalates to Tier 1.
- **Tier 3 — Senior Staff:** Office Management & Review Layer. Subject to intermittent official field visits. Manages and reviews Tier 4 Staff. Can adjust task parameters and deadlines for Tier 4. Cannot modify attendance or payroll records. Cannot assign tasks upward to Tiers 1 or 2.
- **Tier 4 — Staff:** Office Execution & Field Execution Layer. Subject to intermittent official field visits. Task reception only — no assignment capabilities. Executes assigned tasks, submits progress updates, daily reports, and meeting action items.

### 2.2 Cascading Task Delegation Matrix

| Task Action | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---|---|---|---|---|
| Assign to Tier 1 | — | No | No | No |
| Assign to Tier 2 | Yes | — | No | No |
| Assign to Tier 3 | Yes | Yes | — | No |
| Assign to Tier 4 | Yes | Yes | Yes | — |
| Receive / Execute Tasks | — | Yes | Yes | Yes |
| Adjust Task Parameters / Deadlines | Yes | Yes | Tier 4 only | No |

### 2.3 Data Override Rights Matrix

| Override Action | Tier 1 | Tier 2 | Tier 3 | Tier 4 |
|---|---|---|---|---|
| System configuration & settings | Yes | Limited | No | No |
| Frozen payroll unlock | Yes | Pending Ratification (emergency only) | No | No |
| Audit trail — immutable override | Yes (absolute) | No | No | No |
| Attendance logs (Tier 3 & 4) | Yes | Yes | No | No |
| Attendance logs (Tier 2 own) | Yes (only) | No | No | No |
| Task assignments (Tier 3 & 4) | Yes | Yes | No | No |
| Task parameters / deadlines (Tier 4) | Yes | Yes | Yes | No |
| Leave requests (Tier 3 & 4) | Yes | Yes | No | No |
| Leave requests (Tier 2 own) | Yes (only) | No | No | No |
| Payroll records (Tier 3 & 4) | Yes | Yes | No | No |

---

## Section 3 — Authentication & Security

Security is enforced across three layers: authentication, session control, and access protection. Selfie/photograph attendance requirements are fully removed. Security is maintained entirely via Device ID Binding and Whitelisted GPS perimeters.

### 3.1 Authentication Controls

| Control | All Users (Tiers 2–4) | Tier 1 (Super Admin UK) |
|---|---|---|
| Login Credentials | Employee ID + Password (encrypted storage) | Same |
| Two-Factor Authentication (2FA) | OTP via registered mobile or email — all users | Same — mandatory |
| Device ID Binding | Device fingerprint captured on first login; stored in Employee_Master | Same |
| Trusted Device Auto-Login | Up to 2 devices (1 primary + 1 backup) | Same |
| New Device (beyond 2 limit) | Requires Tier 2 approval + revoke existing | Requires Tier 1 peer decision |
| Session Timeout | Auto-logout after 15 minutes inactivity | Same |
| Single Active Session | One session per user — simultaneous blocked | Same |
| Fingerprint Change Re-Verification | Required on OS update or significant browser change | Same |
| Failed Login Lockout | 5 consecutive failures → account lock. Yellow Alert at 3rd consecutive failure. | Same |

### 3.2 GPS Fraud Detection (10-Point Engine)

1. GPS vs IP geolocation mismatch > 500 m → Risk Score 8–10 → Red Alert + audit lock + KPI penalty
2. Speed anomaly > 120 km/h urban / > 40 km/h walking → Risk Score 6–7 → Yellow Alert + supervisor notification
3. Location jump > 5 km in < 1 minute (no intermediate points) → Risk Score 7 → Attendance flagged, supervisor alerted
4. GPS timestamp deviation > 2 minutes from server time → Risk Score 8 → Check-in rejected + instant account suspension pending hearing
5. GPS accuracy > 100 m after 3 retries → Exception workflow (Section 5.4) — Risk Score 4–5
6. Mock GPS app or suspicious browser signature detected → Risk Score 10 → Instant account suspension + 48-hour hearing + Red Alert
7. IP geolocation region does not match GPS location → Risk Score 6 → Flag for Tier 2 review
8. Rooted or jailbroken device capability anomalies → Risk Score 7 → Device violation log + Tier 2 notification
9. Static / impossible route pattern (behavioral anomaly) → Risk Score 5–6 → Auto-flag for Tier 2 review
10. Conflicting location sources on same device → Risk Score 5 → Supervisor alert

> ⚠ Mock GPS detection (Method 6) and device-clock tampering (Method 4) are HIGH RISK (Score 8–10) events. They trigger instant account suspension, Red Alert to Tier 1 dashboard, immutable audit lock, and a mandatory administrative hearing within 48 hours.

### 3.3 Security Monitoring

- **Login Logs:** every attempt (success/failure) recorded with timestamp, device fingerprint, IP, 2FA status.
- **Session Logs:** all active sessions tracked; forced logout available to Tier 2 (for Tiers 3–4) and Tier 1 (all).
- **Audit Logs:** every data change recorded with before/after values, Risk_Score, Risk_Level — immutable.
- **Security Incidents:** GPS fraud, unauthorized access, device violations — logged with severity and action.

---

## Section 4 — Employee Management

BWAPMS manages 10 permanent, full-time employees across four tiers. Tier 1 (UK Team) members are voluntary management — no salary, attendance, or leave tracking. The system is structured to scale to additional employees without architectural changes.

### 4.1 Employee Data Structure

| Category | Fields | Notes |
|---|---|---|
| Personal | Employee ID, Full Name, Official Email, Mobile Number, Photo URL, NID Number | Core identification data |
| Employment | Designation, Department, Tier (1–4), Reporting Manager, Joining Date, Employment Status | Status: Active / Probation / Resigned / Terminated |
| Salary | Monthly Gross Salary, Previous Salary, Increment Effective Date | Linked to payroll — increment annually |
| Banking | Bank Name, Bank Account Number | For salary disbursement |
| System | Device Fingerprint, 2FA_Enabled, Trusted_Devices (JSON), Is_Active | Authentication and security binding |

### 4.2 Employment Status & Probation

| Status | Description | System Behaviour |
|---|---|---|
| Active | Permanent full-time, currently working | Full access to all authorized modules |
| Probation | New hire in evaluation period (placeholder for future use) | Same access as Active; flagged in KPI reports for monitoring |
| Resigned | Resignation submitted; exit workflow in progress | Access restricted; exit checklist activated |
| Terminated | Employment ended by organization | Immediate access revocation; exit workflow completed |

### 4.3 Onboarding Workflow

1. Tier 2 (Country Head) creates employee profile — all fields required.
2. System assigns Employee ID and sends welcome notification with login credentials.
3. Employee logs in — 2FA OTP triggered, device fingerprint captured, trusted device registered.
4. Tier 2 assigns responsibilities from Responsibility_Master based on designation and tier.
5. Tier 2 creates and assigns initial tasks with priority, due dates, and Performance Impact Score.
6. System sends onboarding confirmation — all steps logged in Audit_Logs with Risk_Score 1.

### 4.4 Employee Exit (Offboarding) Workflow

1. Employee submits resignation, or Tier 2 initiates termination — Tier 1 approves exit.
2. Tier 1 sets last working date. System generates exit checklist: pending tasks, reports, handover items.
3. Tier 2 confirms all handover items completed.
4. Final payroll calculated — all deductions reconciled, pro-rata applied for partial month if applicable.
5. All system access revoked; device fingerprint and 2FA credentials removed.
6. Employee data retained active until last working date, archived to read-only store after 3 months.
7. Exit audit record permanently retained — Risk_Score 3, immutable.

### 4.5 Annual Salary Increment Workflow

Increments are processed annually — effective 1 January each year.

1. Tier 2 reviews all KPI scores and proposes increment amounts for Tiers 3 & 4 with justification.
2. Tier 1 reviews proposals and approves, adjusts, or rejects.
3. Effective date set as 1 January. Payroll auto-updates from that month.
4. Employee notified via system notification.
5. Salary_History record created: proposed by Tier 2, approved by Tier 1, timestamp — Risk_Score 2.

---

## Section 5 — Hybrid GPS Attendance & Whitelisted GeoCampus Engine

BWAPMS v1.2 replaces continuous background GPS route tracking with a Whitelisted GeoCampus Engine. Employees check in and out only from pre-authorized, whitelisted GPS perimeters. No selfie or photograph is required; security is enforced entirely via Device ID Binding and GPS perimeter validation.

### 5.1 Attendance Mode Structure

| Mode | Who | GPS Validation Rule |
|---|---|---|
| Office Mode (Default) | Tiers 2, 3, 4 | Must be within 50-metre radius of Rahim Tower HQ (Lat: 24.890144, Long: 91.879072) |
| Field / Official Visit Mode | Tiers 2, 3, 4 (intermittent — approx. 3–10 times/month) | Must be within defined radius of a pre-authorized Whitelisted_Location entry |
| Tier 1 (Super Admin UK) | Exempt | No attendance, check-in, or GPS tracking required |

### 5.2 Whitelisted Locations (Approved Field Sites)

| Category | Examples | GPS Validation Radius |
|---|---|---|
| Government Upazila Offices | Upazila Parishad offices, Upazila Nirbahi Officer offices | 50 metres |
| Upazila Health Offices | Upazila Health Complex, Health & FP offices | 50 metres |
| Upazila Meetings (Scheduled) | Coordination meetings at government premises | 50 metres from declared venue |
| Internal Clinics (BRPHI-operated) | GramGP-affiliated clinic locations | 50 metres |

> ⚠ Only Tier 1 or Tier 2 may add, edit, or remove entries in the Whitelisted_Locations table. All changes are audit-logged with Risk_Score 4.

### 5.3 Early Check-In / Late Check-Out Policy

- Early check-ins (before 10:00 AM) are permitted — no system error generated.
- Late check-outs (after 6:00 PM) are permitted — no system error generated.
- There is NO overtime policy. The payroll engine uses 10:00 AM and 6:00 PM as evaluation boundaries only.
- Hours worked before 10:00 AM or after 6:00 PM are logged for records but do NOT accumulate additional compensation.
- Productivity Per Hour metric uses only validated hours within the 10:00 AM – 6:00 PM window.

### 5.4 Office Hours & Attendance Thresholds

| Parameter | Value | Rule |
|---|---|---|
| Evaluation Start (Payroll Boundary) | 10:00 AM | Hours before this are not counted for payroll or productivity |
| Grace Period End (Late Threshold) | 10:10 AM | Late status applied to arrivals after 10:10 AM — pro-rata deduction begins |
| Auto-Absent Trigger | 12:00 PM — no check-in recorded | Automatically marked Absent |
| Evaluation End (Payroll Boundary) | 6:00 PM | Hours after this not counted for payroll |
| Missing Check-Out Flag | 8:00 PM | Supervisor alerted next working day |

### 5.5 Attendance Status Values

| Status | When Applied |
|---|---|
| Present | Checked in on time (by 10:10 AM) at HQ or whitelisted field location |
| Late | Checked in after 10:10 AM but before 12:00 PM — pro-rata deduction applied |
| Absent | No check-in recorded by 12:00 PM |
| Leave | Approved leave covers the day |
| Holiday | Declared weekly or special holiday |
| Weekend | Friday (mandatory) or assigned Shift Holiday (future feature) |
| Half-Day | Present for partial day — Admin-applied |
| Field / Official Visit | Checked in from an approved Whitelisted_Location |
| Emergency Exemption | Admin-declared emergency/force majeure — no penalty |
| Maintenance Exemption | System maintenance window — no penalty |
| GPS Accuracy Exception | GPS > 100 m — pending Tier 2 / Tier 1 approval |

### 5.6 GPS Accuracy Exception Workflow

1. System prompts employee to retry GPS capture (up to 3 attempts).
2. If all 3 exceed 100 m, check-in is blocked and flagged as 'GPS Accuracy Exception' — Risk_Score 4.
3. Employee submits exception request with written explanation.
4. Tier 2 reviews and approves or rejects — attendance marked accordingly.
5. If Tier 2 is the affected employee, Tier 1 reviews and decides.
6. Unapproved exceptions are not counted as attendance for that day.
7. All steps audit-logged with full GPS readings, device info, and Risk_Score.

### 5.7 Offline Mode Cache (Attendance)

When internet connectivity is unavailable during check-in or check-out:

- The device captures and stores GPS coordinates, timestamp, and Device ID locally in encrypted cache.
- A visible 'OFFLINE — CACHED' indicator displays to the employee during the action.
- On connectivity restoration, cached data automatically syncs to the server with the original device-validated timestamp.
- Sync is logged in Audit_Logs with an 'Offline_Sync' flag — Risk_Score 2 (routine).
- If cached GPS coordinates fall outside whitelisted perimeters on sync, the record is flagged — Risk_Score 6 — and queued for Tier 2 review.

### 5.8 Attendance Reports & Slips

| Report / Slip | Period | Download Format |
|---|---|---|
| Daily Attendance Slip | Per day | PDF |
| Monthly Attendance Report | Per month | PDF, Excel, CSV |
| Yearly Attendance Summary | Per year | PDF, Excel, CSV |
| Late Attendance Report | Monthly / Yearly | PDF, Excel, CSV |
| Absentee Report | Monthly / Yearly | PDF, Excel, CSV |
| Field Visit Compliance Report | Monthly | PDF, Excel, CSV |

- Employees (Tiers 2–4) can download own attendance slips from personal dashboard.
- Tier 2 can download attendance reports for all employees (Tiers 3–4).
- Tier 1 can download all reports across all tiers.

---

## Section 6 — Leave & Request Management

### 6.1 Leave Entitlement

| Leave Type | Allocation & Accrual | Year-End Policy |
|---|---|---|
| Casual Leave (CL) | 1.5 days auto-credited per month = 18 days/year | Expires 31 December — no carry forward. Fresh 18-day allocation auto-generated 1 January. |
| Sick Leave (SL) | 14 days per year — annual allocation | Expires 31 December — no carry forward. Fresh 14-day allocation auto-generated 1 January. |
| Maternity Leave | 16 weeks — full pay (reserved; allocated when applicable) | Not subject to year-end expiry |

> ⚠ No festival (Eid) bonus is applicable. All unused CL and SL balances expire on 31 December each year. Fresh allocations are auto-generated on 1 January. There are no carry-forward provisions.

### 6.2 Request Types & Approval Authority

| Category | Types | Approval Authority |
|---|---|---|
| Leave Requests | Casual, Sick, Maternity (future), Emergency | Tier 2 for Tiers 3–4; Tier 1 for Tier 2 |
| Attendance Requests | Correction, Missing Check-In/Out, GPS Exception, Regularization | Tier 2 for Tiers 3–4; Tier 1 for Tier 2 |
| Justification Requests | Late Arrival, Early Departure, Field Visit Justification | Tier 2 for Tiers 3–4; Tier 1 for Tier 2 |

### 6.3 Leave Slip Downloads

| Report / Slip | Period | Format |
|---|---|---|
| Leave Balance Slip | Current balance snapshot | PDF |
| Monthly Leave Summary | Per month | PDF, Excel, CSV |
| Yearly Leave Summary | Per year | PDF, Excel, CSV |

### 6.4 Grievance & Appeal Process

- Employee who disagrees with a KPI penalty, payroll deduction, or attendance decision submits a formal grievance via the system.
- Tier 2 (Country Head) provides a formal written finding within 48 hours.
- If unresolved, grievance escalates to Tier 1 (Super Admin UK) — final binding resolution within 72 hours.
- All stages, decisions, and comments permanently audit-logged — Risk_Score 3.

---

## Section 7 — Holiday & Duty Management

| Holiday Type | Details |
|---|---|
| Weekly Holiday — Friday | Fixed for all employees (Tiers 2–4). Mandatory. Cannot be overridden. |
| Shift Holiday (Future Feature) | One additional off-day per employee — Saturday to Thursday. Additive to Friday. Not yet active — reserved for future release. |
| Government Holidays | Per Bangladesh national calendar — configured annually by Tier 2. |
| Religious Holidays | Per applicable observances — configured by Tier 2. |
| Organizational Holidays | Declared by BRPHI management — added by Tier 2. |

> ⚠ Shift Holiday is additional to (not a replacement of) the Friday weekly holiday. All employees retain Friday. Shift Holiday is a future feature — not active in v1.2.

### 7.1 Emergency / Force Majeure Protocol

- Tier 2 may declare an Emergency Day for natural disaster, severe weather, hartal, or civil unrest.
- All Tier 2–4 employees automatically granted 'Emergency Exemption' status — no absence penalty, no leave deduction.
- Declaration must include reason — subject to Tier 1 review.
- Risk_Score 2 logged for declaration. Risk_Score 1 for each exemption granted.

### 7.2 System Maintenance Window Protocol

1. Tier 1 and Tier 2 agree on maintenance window — minimum 48 hours notice to all via Announcements.
2. Tier 2 activates 'Maintenance Window' flag in System_Settings with start and end time.
3. Employees who would have checked in during the window receive automatic 'Maintenance Exemption' — no penalty.
4. Post-maintenance, Tier 2 confirms system live and notifies all employees.
5. Maintenance window and all exemptions audit-logged — Risk_Score 1.

---

## Section 8 — Responsibility Management

Responsibilities define employee accountability per designation and tier. They link directly to task assignment, KPI evaluation, daily reporting, and performance scoring.

| Function | Details |
|---|---|
| Assignment | Based on designation (Responsibility_Master) or custom assignment by Tier 1/2 |
| Tier 3 Adjustment | Tier 3 may adjust Tier 4 task parameters within assigned responsibilities — cannot reassign core responsibilities |
| Modification | Only Tier 1 or Tier 2 can modify core responsibilities — audit-logged Risk_Score 3 |
| Completion Tracking | Pending, In Progress, Completed, Overdue — monitored on Tier 2 Admin dashboard |
| KPI Link | Responsibility fulfillment score feeds into Task Performance KPI (35%) component |
| History | All responsibility changes and completion records retained permanently |

---

## Section 9 — Task & Progress Management

The task system enforces the cascading delegation matrix (Section 2.2). Tier 1 assigns to any tier. Tier 2 assigns to Tiers 3–4. Tier 3 assigns strictly downward to Tier 4. Tier 4 receives tasks only.

### 9.1 Task Types, Priority & Status

- **Task Types:** Auto-Generated Tasks, Manual Tasks (Tier 1 or 2 assigned), Tier 3-assigned Tasks (to Tier 4), Collaborative Tasks (multi-assignee)
- **Priority Levels:** Low, Medium, High, Critical
- **Status Values:** Pending, In Progress, Completed On Time, Completed Late / Overdue / Cancelled

### 9.2 Automated Task Delay Penalty Engine

For High and Critical priority tasks past their hard deadline:

> Task Delay Penalty = −2% per 24-hour window past deadline | Applied to Task Completion (35%) KPI component | No human intervention permitted

- Penalty calculated and applied automatically by the system at each 24-hour mark post-deadline.
- Applies strictly to High and Critical priority tasks.
- Low and Medium priority tasks: overdue flag applied but no automated hourly/daily deduction.
- Penalty cannot be reversed by Tier 2 — only Tier 1 may override with documented justification.
- All automated penalties logged in Penalty_History — Risk_Score 2.

### 9.3 Multi-Employee Collaborative Tasks

- A task may have one Primary Assignee and one or more Supporting Members.
- Primary Assignee: full KPI impact (100% of Performance Impact Score).
- Supporting Members: participation recorded in performance history; no direct score deduction but contribution tracked.
- Roles assigned at task creation by Tier 1 or Tier 2.

### 9.4 Task Delegation

- If an employee is on leave or unable to complete a task, Tier 2 (or Tier 3 for Tier 4 tasks) may delegate to another eligible employee.
- Delegation requires documented reason — Risk_Score 2.
- Original assignment record fully retained in Task_Master for audit.
- Delegated task marked 'Delegated' with original assignee reference.

### 9.5 Performance Impact Score

Each task carries a Performance Impact Score (1–10) set at creation. Score 10 = critical business impact; 1 = minimal. This weights the task's contribution to the Task Performance KPI (35%). Auto-generated tasks receive default scores by task type.

### 9.6 Task Update Requirements

1. Submit Start Update when task begins.
2. Submit Progress Updates during execution — mandatory for High and Critical priority.
3. Submit Completion Update with evidence (photos/documents mandatory for Critical tasks).
4. Next assigned task available only after current task update submitted.
5. Tiers 1 and 2 monitor all updates via real-time Admin dashboard.

### 9.7 Daily Reporting (Mandatory — All Tiers 2–4)

| Report Field | Requirement |
|---|---|
| Completed Tasks | Mandatory |
| Pending Tasks | Mandatory |
| Key Achievements | Mandatory |
| Problems Faced | Mandatory |
| Support Needed | Optional |
| Tomorrow Plan | Mandatory |
| Priority Activities | Mandatory |

- Missing daily reports: −5% Reporting Discipline KPI per day — automated, no human intervention.
- Incomplete reports rejected and must be resubmitted — counted as missing until resubmission.

---

## Section 10 — Meeting & Action Tracking

The Meeting module manages internal meetings, decisions, and follow-up action items. Field Visit Compliance cross-references meeting minutes and daily reports with GPS check-in records at whitelisted Upazila/clinic locations to verify visit authenticity.

### 10.1 Meeting Record Fields

Meeting ID, Title, Date & Time, Location / Platform, Meeting Type (Internal / Field Visit / Virtual), Organizer, Participants, Agenda, Minutes, Decisions Taken, Field Visit GPS Reference, Status, Closed By / Closed Date.

### 10.2 Field Visit Compliance Cross-Reference

For meetings held at whitelisted field locations:

- System automatically cross-references submitted meeting minutes with the employee's GPS check-in record for that location and date.
- If GPS check-in at the whitelisted location exists for the same day and time window: `Field_Visit_Compliance_Status = VERIFIED`.
- If no matching GPS check-in found: `Field_Visit_Compliance_Status = UNVERIFIED` — flagged for Tier 2 review — Risk_Score 5.
- Compliance status displayed on Field Visit Compliance Report.

### 10.3 Action Item Fields & Rules

Action ID / Meeting ID, Action Description / Assigned To / Assigned By, Due Date / Priority / Status, Progress Notes / Completion Evidence.

- Employees (all tiers 2–4) can update their own assigned action items.
- No user can delete meeting records or action items.
- Only Tier 2 or Tier 1 can close a meeting.
- Overdue action items: −5% Issue Resolution KPI; on-time Critical: +2% bonus.

---

## Section 11 — Issue & Follow-Up Management

**Issue Categories:** Operational, Clinic, EMR (Electronic Medical Records), Financial, Documentation / HR / Technical / Field Operations
**Priority Levels:** Low, Medium, High, Critical
**Status Values:** Open / Under Review, In Progress, Pending External Action, Resolved / Closed / Reopened

### 11.1 Disciplinary Action Process

| Stage | Initiated By | Approved By |
|---|---|---|
| Verbal Warning | Tier 2 (Country Head) | Tier 2 |
| Written Warning | Tier 2 | Tier 2 |
| Show Cause Notice | Tier 2 | Tier 2 + Tier 1 |
| Suspension (Pending Hearing) | Tier 2 (propose) | Tier 1 — or auto-triggered by High-Risk GPS fraud |
| Termination | Tier 2 (propose) | Tier 1 (final) |

> ⚠ Any High-Risk security breach (Mock GPS detection, device-clock tampering — Risk Score 8–10) triggers INSTANT account suspension pending an administrative hearing within 48 hours. No Tier 2 approval required for instant suspension in these cases.

- All stages permanently audit-logged with reason, evidence, and authorizing tier — Risk_Score 4–8.
- Employee notified via system notification at each stage.

---

## Section 12 — Payroll Management

### 12.1 Payroll Calculation Formula

> Net Salary = Gross Salary − Pro-Rata Late Deduction − Absent Deduction − Early Departure Deduction − Other Deductions + Approved Adjustments

### 12.2 Pro-Rata Late Deduction Policy

Arrival past the 10:10 AM grace period constitutes a structural breach of the operational employment framework. The payroll engine enforces non-negotiable, linear, pro-rata deductions based on the exact hours and minutes missed, calculated from the 10:00 AM benchmark.

> Pro-Rata Deduction = (Minutes Late from 10:00 AM ÷ Total Daily Working Minutes [480]) × Daily Gross Salary

- Calculated to the exact Taka fraction — no rounding until final payslip generation.
- Applied automatically by the payroll engine — no human intervention permitted.
- Early check-in (before 10:00 AM) does NOT offset late deductions on other days.
- No overtime compensation — late check-out hours are logged but not paid.

### 12.3 Absent Deduction

> Absent Deduction = (1 ÷ Total Working Days in Month) × Monthly Gross Salary | Per absent day

### 12.4 Deduction Categories

- Pro-rata late deduction — auto-calculated per incident.
- Per-day absent deduction — auto-calculated from attendance.
- Early departure deduction — pro-rata from 6:00 PM benchmark.
- Income tax — as applicable per Bangladesh Income Tax law.
- KPI or disciplinary penalties — entered as Other Deductions with documented reason.

### 12.5 Tier 2 (BD Head) Payroll Processing

Tier 2 processes all payroll including their own. Tier 2 may enter and adjust deduction values. All changes auto-logged in Audit_Logs with before/after values — Risk_Score 4. Tier 1 may review and override any payroll entry if discrepancies are found.

### 12.6 Emergency Payroll Unlock — EMERGENCY_BD_OVERRIDE

If a critical payroll unlock requires immediate action and Tier 1 is unreachable due to time-zone differences:

- Tier 2 activates `EMERGENCY_BD_OVERRIDE` status — payroll processed under 'Pending UK Ratification' flag.
- This is a Risk_Score 8–9 event — triggers immediate Red Alert to Tier 1 dashboard.
- Tier 1 must ratify or reject within 72 hours of alert.
- If Tier 1 rejects, payroll adjustments are reversed and reprocessed.
- `EMERGENCY_BD_OVERRIDE` is audit-locked — immutable record, permanently flagged.

### 12.7 Payroll Governance

- Locked payroll records cannot be edited by any user.
- Only Tier 1 can unlock a locked payroll record — Risk_Score 5 — audit-logged.
- Salary slip PDF auto-generated on processing → employee dashboard (downloadable) + auto-sent to official email.

### 12.8 Next-Month Payroll Forecast (Predictive Engine)

The Executive Dashboard displays a predictive payroll forecast for the upcoming month:

- Analyzes rolling late arrival trends (trailing 30 days) to project likely late deductions.
- Incorporates approved leave schedules to project absent-day deductions.
- Factors in unpaid absence metrics from current month.
- Outputs projected Gross Salary, Total Deductions, and Net Salary per employee for the next month.
- Displayed as a table and bar chart on the Tier 1 Executive Dashboard.
- Refreshed daily — non-binding forecast only, clearly labelled 'PROJECTED'.

### 12.9 Salary Slip & Payroll Reports

| Report / Slip | Period | Format |
|---|---|---|
| Individual Salary Slip | Per month | PDF |
| Payroll Summary Report | Monthly | PDF, Excel, CSV |
| Salary History Report | Yearly / All-time | PDF, Excel, CSV |
| Deduction Breakdown Report | Monthly | PDF, Excel, CSV |
| Next-Month Payroll Forecast | Rolling monthly | Dashboard display + PDF export |

---

## Section 13 — KPI & Performance Management

### 13.1 KPI Component Weights & Calculation

| KPI Component | Weight | Calculation Method | Automated Penalty |
|---|---|---|---|
| Attendance | 15% | (Present Days / Total Working Days) × 100 | −2% per late day; −5% per absent day — auto-applied |
| Task Performance | 35% | (Tasks Completed On Time / Total Tasks) × 100, weighted by Performance Impact Score | −2% per 24-hr window past deadline (High/Critical); −10% overdue (Low/Medium) |
| Reporting Discipline | 15% | (Daily Reports Submitted / Required) × 100 | −5% missing; −3% incomplete — auto-applied |
| Issue & Action Resolution | 10% | (Issues Resolved + Action Items Completed) / Total Assigned × 100 | −5% overdue; +2% bonus on-time Critical — auto-applied |
| Work Efficiency | 10% | (Expected Completion Time / Actual Time) × 100, capped at 100 | Based on task completion vs expected — auto-calculated |
| Management Evaluation | 15% | Standardized quarterly assessment by reporting manager (Section 13.3) | Tier 2 evaluates Tiers 3–4; Tier 1 evaluates Tier 2 |

### 13.2 Productivity Per Hour — Informational Metric (Non-Scoring)

> **GOVERNANCE OVERRIDE — EFFECTIVE IMMEDIATELY:** Productivity Per Hour is re-classified as an Informational Metric only. It carries zero mathematical weight in the final KPI performance score and has no direct influence on payroll calculations or deductions. It is displayed exclusively as a dashboard analytics widget for leadership review and trend monitoring.

> Productivity Per Hour = Total Validated Task Points Completed ÷ Cumulative Logged Attendance Hours (10:00 AM–6:00 PM boundary)

- 'Validated Task Points' = sum of Performance Impact Scores of all tasks marked Completed On Time in the period.
- 'Cumulative Logged Attendance Hours' = total hours within 10:00 AM – 6:00 PM boundary for the month.
- Displayed on Admin and Executive dashboards. Trend chart shown over 6-month rolling window.
- Does NOT contribute to the final KPI performance score, does NOT influence payroll calculations, and does NOT trigger any automated penalties or deductions.
- Used as a supplementary reference signal for the Staff Turnover Trend Analyzer (informational flag only — no automated action).

### 13.3 Management Evaluation Rubric (Standardized Quarterly)

The 15% Management Evaluation uses a standardized rubric — rated quarterly by the reporting manager (Tier 2 for Tiers 3–4; Tier 1 for Tier 2). Each criterion scored 0–10, multiplied by 2.5 to give a 0–100 total.

| Criterion (×2.5 each) | 0–4: Needs Improvement | 5–7: Meets Standard | 8–10: Exceeds Standard |
|---|---|---|---|
| Work Quality | Frequent errors or incomplete work | Meets required standard with minor issues | Consistently accurate, thorough, exceeds expectations |
| Initiative | Waits for instruction; rarely proactive | Takes initiative on familiar tasks | Consistently identifies problems; acts without prompting |
| Teamwork | Does not collaborate effectively | Cooperates when asked; contributes adequately | Actively supports teammates; enhances team effectiveness |
| Communication | Reports frequently late or unclear | Reports on time and clearly most of the time | Proactive, clear communication; adds value to decisions |

> ⚠ Tier 2 cannot self-evaluate — Tier 1 conducts quarterly evaluation for Tier 2. Evaluation records are permanently retained — Risk_Score 2.

### 13.4 Performance Score Bands

| Score | Level | Required Action |
|---|---|---|
| 90–100 | Excellent | Eligible for recognition and increment consideration |
| 80–89 | Good | Continue current trajectory |
| 70–79 | Satisfactory | Monitoring with targeted improvement guidance |
| 60–69 | Needs Improvement | Formal performance improvement plan required |
| Below 60 | Unsatisfactory | Immediate review — may initiate disciplinary process |

### 13.5 Staff Turnover Trend Analyzer

The Executive Dashboard flags employee profiles showing combined retention risk indicators:

- Prolonged Office Productivity Per Hour drop — 30+ consecutive days below 50% of 3-month average.
- High absenteeism — 3+ unapproved absences in a rolling 30-day window.
- Combined flag: system displays 'RETENTION RISK' alert on Tier 1 Executive Dashboard for the flagged employee.
- Alert is informational only — no automated action taken. Tier 1 and Tier 2 notified for leadership review.

### 13.6 KPI Override Policy

- Only Tier 1 may override a KPI score — exceptional circumstances only (system error, documented emergency, approved medical leave).
- System logs: Employee ID, original score, revised score, reason, Tier 1 user, timestamp — Risk_Score 5.
- Employee and Tier 2 automatically notified of override.
- Maximum 2 overrides per employee per quarter without Tier 1 executive justification.
- No user may override their own KPI score.

### 13.7 Employee Ranking

| Ranking | Award Basis | Period |
|---|---|---|
| Top Performer | Highest overall KPI score | Monthly / Quarterly |
| Highest Productivity Per Hour | Best productivity-per-hour metric | Monthly |
| Best Attendance | Highest attendance component | Monthly |
| Best Reporter | Highest reporting discipline | Monthly |
| Best Task Executor | Highest task performance | Monthly |
| Best Problem Solver | Highest issue resolution | Monthly |
| Most Improved | Largest positive KPI trend | Quarterly |
| Retention Risk | Lowest combined productivity + attendance — flagged | Rolling 30-day |

---

## Section 14 — Automated Risk Scoring & Risk-Based Audit

Every system-generated record in the Audit_Logs table is programmatically assigned a Risk_Score (0–10) and Risk_Level (Low / Medium / High) at the moment of creation.

### 14.1 Risk Score Classification

| Score | Level | Trigger Examples | System Response |
|---|---|---|---|
| 1–3 | LOW | Routine late check-in (>10:10 AM), standard leave request, early check-in, late check-out, normal task update, offline sync | Archived passively. No alert generated. Available in standard audit reports. |
| 4–7 | MEDIUM | GPS check-in outside whitelisted perimeter, multiple failed logins, payroll deduction entry, Whitelisted_Locations table change, offline sync with location mismatch | Yellow Alert on Tier 2 Admin Dashboard. Queued for next routine review. Logged in Monthly Operations Report. |
| 8–10 | HIGH | EMERGENCY_BD_OVERRIDE activation, Mock GPS or fake GPS app detection, device-clock tampering, unauthorized system access attempt | Immediate Red Alert to Tier 1 Executive Dashboard. Audit log record immutably locked. Appended to Monthly Donor Audit Readiness Report. May trigger instant account suspension. |

### 14.2 Risk Score Assignment Reference Table

| Audit Event | Risk Score | Risk Level |
|---|---|---|
| Routine check-in (on time, whitelisted location) | 1 | Low |
| Late check-in (>10:10 AM) | 2 | Low |
| Early check-in / late check-out (within policy) | 1 | Low |
| Standard leave request submitted | 1 | Low |
| Task update submitted | 1 | Low |
| Offline sync — location verified | 2 | Low |
| Failed login (1st–2nd consecutive) | 2 | Low |
| GPS accuracy exception flagged (>100 m) | 4 | Medium |
| GPS check-in outside whitelisted perimeter | 6 | Medium |
| Offline sync — location mismatch on sync | 6 | Medium |
| Failed login (3rd consecutive — Yellow Alert + lock trigger) | 6 | Medium |
| Payroll deduction entry by Tier 2 | 4 | Medium |
| Whitelisted_Locations table modified | 4 | Medium |
| KPI score override by Tier 1 | 5 | Medium |
| Payroll unlock by Tier 1 | 5 | Medium |
| EMERGENCY_BD_OVERRIDE activation | 9 | High |
| Mock GPS / fake GPS detection | 10 | High |
| Device-clock tampering detected | 9 | High |
| Unauthorized system access attempt | 8 | High |

### 14.3 Alert & Response Workflow

- **LOW Risk (1–3):** Archived passively. Visible in standard audit trail. No notification generated.
- **MEDIUM Risk (4–7):** Yellow Alert generated on Tier 2 Admin Dashboard. Tier 2 may dismiss after review (dismissal logged).
- **HIGH Risk (8–10):** Red Alert simultaneously delivered to Tier 1 Executive Dashboard. Audit record immediately and permanently locked. Appended to Monthly Donor Audit Readiness Report. If event triggers account suspension, employee notified immediately.

---

## Section 15 — Dashboards & Reports

### 15.1 Dashboard Specifications

| Dashboard | Key Widgets | Access |
|---|---|---|
| Employee Dashboard (Tiers 2–4) | Attendance summary + daily slip download, leave balance, task list, KPI score breakdown, salary slip download, meeting action items, personal reports centre, announcements, holiday calendar, productivity-per-hour trend | Tiers 2, 3, 4 — own data only |
| Admin Dashboard (Tier 2) | Live GPS attendance status (HQ + field), pending approvals queue, task monitoring, Yellow Alerts panel, KPI analytics, payroll overview, issue tracker, meeting tracker, performance rankings, field visit compliance report, system statistics | Tier 2 — all Tiers 3 & 4 data |
| Executive Dashboard (Tier 1) | Organisational KPI trends, Productivity Per Hour matrix, Staff Turnover Risk panel, Red Alerts feed, next-month payroll forecast, system health status, risk-based audit summary, high-risk audit report | Tier 1 — all data across all tiers |

### 15.2 Complete Report & Download Matrix

| Report Category | Available Periods | Formats |
|---|---|---|
| Daily Attendance Slip | Per day | PDF |
| Monthly Attendance Report | Per month | PDF, Excel, CSV |
| Yearly Attendance Summary | Per year | PDF, Excel, CSV |
| Field Visit Compliance Report | Monthly | PDF, Excel, CSV |
| Monthly Leave Summary | Per month | PDF, Excel, CSV |
| Yearly Leave Summary | Per year | PDF, Excel, CSV |
| Monthly Salary Slip | Per month | PDF |
| Payroll Summary Report | Monthly | PDF, Excel, CSV |
| Deduction Breakdown Report | Monthly | PDF, Excel, CSV |
| Salary History Report | Yearly / All-time | PDF, Excel, CSV |
| KPI Score Report | Monthly / Quarterly | PDF, Excel, CSV |
| Performance Ranking Report | Monthly / Quarterly | PDF, Excel, CSV |
| Task Report | Daily / Weekly / Monthly | PDF, Excel, CSV |
| Meeting & Action Items Report | Monthly | PDF, Excel, CSV |
| Issue Report | Monthly | PDF, Excel, CSV |
| Monthly Donor Audit Readiness Report | Monthly | PDF, Excel, CSV |
| Audit Log Report | Monthly / Yearly | PDF, Excel, CSV |
| Next-Month Payroll Forecast | Rolling monthly | Dashboard + PDF |

### 15.3 Reporting Period

Calendar year (1 January – 31 December) for annual KPI evaluation, leave allocation, and salary increments. Quarterly KPI periods: Q1 (Jan–Mar), Q2 (Apr–Jun), Q3 (Jul–Sep), Q4 (Oct–Dec).

---

## Section 16 — Notifications & Announcements

| Announcement Type | Features | Governance |
|---|---|---|
| Notice | Role-based visibility by tier | Expiry management |
| Holiday Notice | Read tracking with timestamp | Priority highlighting |
| Meeting Notice | Acknowledgement required | Permanent audit log |
| Circular | Priority highlighting | Instant delivery to all tiers |
| Risk Alert (Yellow) | Tier 2 dashboard — dismissible after review | Dismissal logged — Risk_Score 2 |
| Risk Alert (Red) | Tier 1 dashboard — non-dismissible until resolved | Immutable alert record |

- Critical security and compliance notifications cannot be disabled — always delivered.
- Employees configure notification preferences (email / in-app / both) per notification type via Notification_Preferences table.

---

## Section 17 — Audit, Compliance & Data Governance

### 17.1 Audit Trail

Every system record in Audit_Logs is immutable, permanently retained, and carries a Risk_Score and Risk_Level. No user — including Tier 1 — may delete an audit log. High-Risk records (Score 8–10) are additionally locked at the database level and included in the Monthly Donor Audit Readiness Report.

### 17.2 Data Retention Policy

| Data Category | Retention Policy |
|---|---|
| Active Employee Data | Live — indefinitely while employed |
| Resigned / Terminated Employee Data | Archived 3 months post-exit; read-only store |
| Audit Logs | Permanent — never deleted — immutable |
| High-Risk Audit Records (Score 8–10) | Permanently locked — additional immutable layer |
| GPS Tracking Data | Active 6 months; daily summary in archive thereafter |
| Payroll Records | Permanent — legal compliance |
| Meeting Records | Permanent — governance record |
| Backup Logs | 1 year retention |

### 17.3 Data Access Policy

System data is for internal BRPHI operational use only. BD Head (Tier 2) accesses all Tier 3–4 data within the system. UK Team (Tier 1) has full access to all data. No external data sharing is configured or permitted without Tier 1 authorization and an audit-log entry.

### 17.4 Quarterly Governance Review — Formal Mandate

> **GOVERNANCE DIRECTIVE — EFFECTIVE IMMEDIATELY AND BINDING ON ALL SYSTEM VERSIONS:** Quarterly Governance Reviews — encompassing Payroll Audits, KPI Reviews, Security Audits, and Compliance Audits — are formally mandated to be personally handled, executed, and signed off by the Country Head (BD) (Tier 2). This obligation is non-delegable.

The Super Admin (UK) (Tier 1) holds voluntary ratification visibility rights over all Quarterly Governance Review outcomes. Tier 1 may review, ratify, query, or escalate any finding at their discretion. Tier 1 ratification is recorded as a voluntary co-sign in the audit trail (Risk_Score 2) and does not transfer operational execution responsibility away from the Country Head (BD).

**Mandatory quarterly review scope:**

- **Payroll Audit:** verification of all payroll records, deductions, pro-rata calculations, and salary disbursements for the quarter.
- **KPI Review:** assessment of all employee KPI scores, component data integrity, and any override actions for the quarter.
- **Security Audit:** review of all High-Risk (Score 8–10) audit events, GPS fraud attempts, device violations, unauthorized access incidents, and security alert resolution status.
- **Compliance Audit:** confirmation of data retention adherence, audit log integrity, disciplinary process compliance, and regulatory readiness for the quarter.

Each completed Quarterly Governance Review is signed off by the Country Head (BD) within the system and recorded as a permanent, immutable audit entry (Risk_Score 3). Failure to complete any quarterly review within 14 calendar days of the quarter end triggers an automatic Yellow Alert to the Super Admin (UK) Executive Dashboard.

---

## Section 18 — Backup & Disaster Recovery

| Backup Type | Schedule | Retention |
|---|---|---|
| Incremental Backup | Daily at 2:00 AM | Last 30 daily backups |
| Full Backup | Every Sunday at 2:00 AM | Included in 30-day window |
| Monthly Snapshot | 1st of each month at 2:00 AM | Permanent retention |
| Code Backup (GitHub & Supabase) | Monthly export to Google Drive & Supabase backup | Permanent retention |
| CSV Offline Export | Monthly — all critical tables | 1 year (extreme disaster safeguard) |

- Recovery Time Objective (RTO): 4 hours for full system restore.
- Recovery Point Objective (RPO): Maximum 24 hours data loss.
- Quarterly restoration drills conducted by Tier 1.
- Backup failure: immediate email alert to Tier 1 and Tier 2 — Risk_Score 7.
- Tier 1 maintains access to secondary Google account with shared backup folder.

---

## Section 19 — Help Desk & Change Management

### 19.1 Help Desk

| Attribute | Details | SLA |
|---|---|---|
| Ticket Categories | Login/Access, GPS/Attendance, Payroll, Task/Reporting, System Errors, Feature Requests, Data Corrections | — |
| Medium Priority | Tier 2 initial review → Tier 1 escalation if needed | 48-hour resolution target |
| High Priority | Tier 2 immediate action → Tier 1 if needed | 24-hour resolution target |
| Critical (system down) | Immediate Tier 1 escalation | 4-hour resolution target |
| Auto-Close | Resolved tickets close after 7 days without user response | Re-openable by user |

### 19.2 Change Management

Semantic versioning (MAJOR.MINOR.PATCH). No production changes without Tier 1 approval. Emergency security patches deployed immediately with mandatory post-hoc documentation within 24 hours. All users notified of major changes 48 hours before deployment via Announcements.

---

## Section 20 — Intelligence Engine & Smart Alerts

| Domain | Monitored Indicators | Tier Notified |
|---|---|---|
| Performance Intelligence | Score drops, low KPI, trend declines | Tier 2 (Yellow); Tier 1 (Red if critical) |
| Productivity Per Hour | Drop > 50% of 3-month average for 30+ days | Tier 1 — Retention Risk flag |
| Attendance Intelligence | Absence patterns, late arrivals, attendance risk | Tier 2 (Yellow Alert) |
| Behavioral Intelligence | Reporting discipline, delay patterns, update compliance | Tier 2 (Yellow Alert) |
| Security Intelligence | GPS fraud, unauthorized access, device violations | Tier 1 (Red Alert — Risk Score 8–10) |
| Field Visit Compliance | Unverified field visit submissions | Tier 2 (Yellow Alert — Risk Score 5) |
| Meeting Action Items | Overdue action items, unresolved decisions | Tier 2 (Yellow Alert) |
| Payroll Intelligence | EMERGENCY_BD_OVERRIDE activation, payroll anomalies | Tier 1 (Red Alert — Risk Score 8–9) |
| System Health | Supabase API quota (alert at 80%), PostgreSQL table size, backup failures | Tier 1 + Tier 2 |

---

## Section 21 — Technical Constraints & Mitigations

BWAPMS runs on plain HTML/JS with Supabase (PostgreSQL, Auth, Storage, Edge Functions) as the backend. These platform constraints are acknowledged and actively mitigated to achieve a 99.9% annualized uptime target.

> Note: the "6-minute script execution limit" row below originally referred to Google Apps Script / AppSheet automation limits. Since the platform no longer uses AppSheet, this constraint does not directly apply — Supabase Edge Functions have their own execution limits instead. Kept here for historical context on the batch-job timing strategy, which is still followed.

| Constraint | Risk | Mitigation Strategy |
|---|---|---|
| 6-minute script execution limit | Heavy operations timeout | Batch jobs: payroll at 1:00 AM, KPI scoring at 3:00 AM, GPS analysis on separate trigger, archival on weekly trigger |
| Supabase (PostgreSQL) row growth | GPS_Tracking and Audit_Logs grow large over time | Archive GPS data every 6 months; table size monitoring; monthly CSV export as offline safeguard |
| Concurrent write race conditions | Simultaneous check-ins corrupt data | Supabase Row-Level Security (RLS) + PostgreSQL transactions on all critical write operations |
| Daily API quota limits | GPS + notifications + backup exhaust quota | System Health monitor at 80% usage; stagger batch operations across off-peak hours |
| No native database transactions | Partial write failures cause inconsistent state | Validate each write step; rollback flags for multi-step operations; step-by-step logging |
| API response time target | < 3 seconds per API call target | Indexed lookups, batched reads, minimize sequential sheet operations |
| Database query performance | < 5 seconds per complex query | Sheet indexing via helper lookup tables, caching frequently accessed data in memory |

### 21.1 QA & Pre-Launch Testing Checklist

| Test Category | Test Requirements |
|---|---|
| Pro-Rata Payroll Formula Verification | Automated UAT scripts verifying pro-rata deduction calculations to the exact Taka fraction across multiple late arrival scenarios |
| Concurrent Check-In Stress Test | Simulate 10 simultaneous check-ins — verify LockService prevents data corruption; verify all records written correctly |
| Mock GPS Blockade Verification | Active verification that mock GPS applications are detected and blocked on both Android and iOS devices before launch |
| Whitelisted GPS Perimeter Test | Verify check-in accepted within 50 m of each whitelisted location and rejected outside perimeter on both device types |
| Offline Cache Sync Test | Test GPS capture during internet cutout; verify cached data syncs correctly with original device timestamp on reconnection |
| Risk Score Assignment Test | Verify correct Risk_Score and Risk_Level assigned to each audit event type — spot-check 20+ event types |
| 2FA Flow Test | Verify OTP delivery and validation across mobile and email channels for all user tiers |
| API Response Time Test | Verify all API endpoints respond within 3-second target under normal load |
| Database Query Performance Test | Verify complex queries (KPI calculation, payroll processing) complete within 5-second target |
| Predictive Forecast Accuracy Test | Run forecast model against historical data — verify payroll projection within ±5% of actual figures |
| Automated Penalty Engine Test | Verify 2% task delay penalty applied at each 24-hour mark with no human intervention; verify no penalty applied to Low/Medium tasks |
| Backup & Recovery Drill | Full system restore from backup in test environment — verify RTO ≤ 4 hours |

---

## Section 22 — Database Architecture

All tables include standard audit fields: `Created_By`, `Created_Date`, `Updated_By`, `Updated_Date`, `Is_Active` (soft delete). Records are never physically deleted — `Is_Active = FALSE` marks inactive records. All queries filter by `Is_Active = TRUE` by default. `Audit_Logs` table does not use `Is_Active` — records are permanently immutable.

### 22.1 Master & System Tables

| Table | Key Fields | Purpose |
|---|---|---|
| Employee_Master | Employee_ID, Tier (1–4), Employment_Status, Device_Fingerprint, TwoFA_Enabled, Trusted_Devices (JSON), Is_Active | Central employee registry — all tiers |
| User_Access | Access_ID, Employee_ID, Tier, Module_Permissions (JSON), Session_Token, Is_Active | Role and permission management |
| Responsibility_Master | Responsibility_ID, Designation_Mapping, Tier_Applicable, Is_Active | Responsibility definitions per tier |
| Whitelisted_Locations | Location_ID, Name, Category, GPS_Lat, GPS_Lng, Radius_Metres, Added_By, Is_Active | Approved field visit GPS perimeters |
| Holiday_Master | Holiday_ID, Holiday_Type, Holiday_Date, Is_Recurring, Is_Active | Centralised holiday calendar |
| System_Settings | Setting_ID, Setting_Key, Setting_Value | System configuration |
| Notification_Preferences | Pref_ID, Employee_ID, Notification_Type, Channel, Is_Enabled, Is_Active | Per-employee notification settings |

### 22.2 Attendance & GPS Tables

| Table | Key Fields | Purpose |
|---|---|---|
| Attendance | Attendance_ID, Employee_ID, Mode, Whitelisted_Location_ID, Status, GPS_Exception_Flag, Emergency_Flag, Maintenance_Flag, Offline_Sync_Flag, Approved_By, Is_Active | Daily attendance — all modes and exceptions |
| GPS_Log | GPS_ID, Employee_ID, Lat, Lng, Accuracy, Speed, Mock_GPS_Flag, Offline_Cached, Synced_At, Risk_Score, Is_Active | GPS point records — archived every 6 months |
| Leave_Request | Request_ID, Employee_ID, Leave_Type, Status, Approved_By, Is_Active | Leave request lifecycle |
| Leave_Balance | Balance_ID, Employee_ID, Leave_Type, Total_Allocated, Used, Balance, Year | Real-time leave balance — resets 1 January |
| Duty_Schedule | Schedule_ID, Employee_ID, Duty_Type, Whitelisted_Location_ID, Status, Is_Active | Duty scheduling |

### 22.3 Task & Meeting Tables

| Table | Key Fields | Purpose |
|---|---|---|
| Task_Master | Task_ID, Assigned_Tier, Primary_Assignee, Supporting_Members (JSON), Performance_Impact_Score, Delegated_From, Delay_Penalty_Applied, Is_Active | Task records with delegation and penalty tracking |
| Task_Updates | Update_ID, Task_ID, Progress_Percentage, Status, Work_Completed, Challenges, Support_Required, Evidence_URL, Is_Active | Task progress log |
| Daily_Reports | Report_ID, Employee_ID, Status, Submitted_At, Is_Active | Daily reporting records |
| Responsibility_Assignment | Assignment_ID, Employee_ID, Responsibility_ID, Status, Fulfillment_Score, Is_Active | Responsibility tracking |
| Meetings | Meeting_ID, Type, Organizer_Tier, Participants (JSON), Minutes, Decisions_Taken, Field_Visit_Compliance_Status, Field_GPS_Reference_ID, Status, Is_Active | Meeting records |
| Meeting_Action_Items | Action_ID, Meeting_ID, Assigned_To, Due_Date, Priority, Status, Evidence_URL, Is_Active | Action item tracking |

### 22.4 Issue, Payroll & HR Tables

| Table | Key Fields | Purpose |
|---|---|---|
| Issues | Issue_ID, Category, Priority, Status, Assigned_To, Is_Active | Issue tracking |
| Payroll | Payroll_ID, Employee_ID, Gross_Salary, ProRata_Late_Deduction, Absent_Deduction, Other_Deductions, Net_Salary, Is_Locked, Emergency_Override_Flag, Pending_Ratification, Is_Active | Monthly payroll — pro-rata deduction tracked |
| Payroll_Forecast | Forecast_ID, Employee_ID, Forecast_Month, Projected_Late_Deduction, Projected_Absent_Deduction, Projected_Net_Salary, Generated_Date | Next-month predictive payroll data |
| Salary_History | History_ID, Employee_ID, Proposed_By_Tier2, Approved_By_Tier1, Increment_Amount, Effective_Date, Is_Active | Annual increment trail |
| Grievances | Grievance_ID, Employee_ID, Subject, Tier2_Decision, Tier2_Response_Date, Tier1_Decision, Tier1_Response_Date, Status, Is_Active | Formal grievance records — SLA tracked |
| Disciplinary_Actions | Action_ID, Stage, Evidence_URL, Initiated_By_Tier, Approved_By_Tier, Is_Active | Disciplinary process trail |
| Employee_Exit | Exit_ID, Employee_ID, Exit_Type, Last_Working_Date, Handover_Status, Final_Payroll_ID, Is_Active | Offboarding trail |

### 22.5 KPI, Audit & Support Tables

| Table | Key Fields | Purpose |
|---|---|---|
| KPI_Scores | KPI_ID, Employee_ID, Period, Component_Scores (JSON), Total_Score, Productivity_Per_Hour, Is_Override, Is_Active | KPI records with productivity metric |
| KPI_Calculation_Log | Log_ID, Formula_Version, Override_Reason, Risk_Score, Is_Active | KPI audit trail |
| Performance_Evaluation | Evaluation_ID, Evaluator_Tier, Work_Quality, Initiative, Teamwork, Communication, Total_Score, Is_Active | Standardized quarterly evaluation |
| Penalty_History | Penalty_ID, Type, Points_Deducted, Applied_Automated (Y/N), Is_Active | Automated and manual penalty log |
| Employee_Ranking | Ranking_ID, Overall_Rank, Category_Ranks (JSON), Productivity_Rank, Retention_Risk_Flag, Is_Active | Periodic rankings |
| Audit_Logs | Log_ID, User_ID, Action, Module, Old_Value, New_Value, Risk_Score, Risk_Level, IP_Address, Is_High_Risk_Locked | System-wide audit — permanent, immutable (no Is_Active) |
| Login_Logs | Log_ID, Login_Status, Device_Fingerprint, TwoFA_Status, Risk_Score, Is_Active | Authentication events |
| Security_Incidents | Incident_ID, Type, Risk_Score, Action_Taken, Suspension_Triggered, Is_Active | Security violations |
| Download_Logs | Log_ID, Report_Type, Format, Risk_Score, IP_Address, Is_Active | Export audit |
| HelpDesk_Tickets | Ticket_ID, Priority, SLA_Deadline, Status, Is_Active | Support tickets |
| Version_Control | Version_ID, Version_Number, Rollback_Plan, Is_Active | Change log |
| Intelligence_Alerts | Alert_ID, Type, Risk_Score, Risk_Level, Alert_Tier (Yellow/Red), Status, Is_Active | Smart alert records |
| Backup_Logs | Log_ID, Backup_Type, Status, Risk_Score, Is_Active | Backup audit |
| Turnover_Risk_Flags | Flag_ID, Employee_ID, Trigger_Date, Productivity_Drop_Days, Absence_Count, Status, Is_Active | Staff retention risk tracking |

---

*END OF DOCUMENT — BWAPMS Enterprise Blueprint v1.2 | Ultimate Locked Edition*
*Bangladesh Rural Primary Health Initiative (BRPHI) | GramGP Programme | CONFIDENTIAL*
