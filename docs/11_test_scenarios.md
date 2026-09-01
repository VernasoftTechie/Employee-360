# Employee-360 — Test Scenarios (Doc 11)

**Status:** Baselined with docs 01–08.

Two layers: **ABAP Unit** (automated, CDS test doubles — no real PA data) and
**functional / integration** (manual, against sandbox PA30 employees).

---

## 1. ABAP Unit (automated)

### 1.1 `ZCL_HR360_ISSUE_TEST` (from PoC pattern)

| # | Test | Arrange | Assert |
|---|---|---|---|
| U01 | `missing_dob_is_flagged` | employee, DOB initial | exactly 1 `MAND_DOB` issue |
| U02 | `missing_gender_is_flagged` | GESCH initial | 1 `MAND_GENDER` |
| U03 | `missing_nationality_flagged` | NATIO initial | 1 `STAT_NATION` |
| U04 | `missing_costcenter_flagged` | KOSTL initial | 1 `ORG_COSTCTR` |
| U05 | `missing_position_flagged` | PLANS initial | 1 `ORG_POSITION` |
| U06 | `missing_basicpay_flagged` | no PA0008 row | 1 `PAY_BASICPAY` (Warning) |
| U07 | `missing_email_flagged` | no contact email | 1 `CONTACT_MAIL` (Warning) |
| U08 | `missing_iban_flagged` | bank row, IBAN initial | 1 `BANK_IBAN` |
| U09 | `no_education_flagged` | no PA0022 | 1 `EDU_MISSING` (Warning) |
| U10 | `no_qualification_flagged` | no PA0024 | 1 `QUAL_MISSING` (Warning) |
| U11 | `future_dob_flagged` | DOB > today | 1 `INVALID_DOB` |
| U12 | `complete_employee_no_issues` | all fields filled | 0 issues |
| U13 | `multiple_issues_counted` | 3 gaps | 3 distinct `CheckID` rows |

### 1.2 `ZCL_HR360_EMPLOYEE_TEST`

| # | Test | Assert |
|---|---|---|
| U20 | `kpi_total_issue_count` | root `TotalIssueCount` = seeded issue count |
| U21 | `kpi_status_ok` | 0 issues → `QualityStatus = 'OK'`, criticality 3 |
| U22 | `kpi_status_warning` | only warnings → `'WARNING'`, criticality 2 |
| U23 | `kpi_status_critical` | ≥1 critical → `'CRITICAL'`, criticality 1 |
| U24 | `completeness_percent` | 3 of 12 failed → `CompletenessPercent = 75.0` |
| U25 | `one_row_per_employee` | root returns exactly 1 row per active employee |

### 1.3 `ZCL_HR360_ORG_READER_TEST`

| # | Test | Assert |
|---|---|---|
| U30 | `manager_from_chief_position` | HRP1001 S→S(002)→P(008) resolves to expected PERNR |
| U31 | `no_manager_when_chain_broken` | missing chief relation → ManagerID blank, no dump |
| U32 | `direct_reports_listed` | employees under a manager's position returned |
| U33 | `org_tree_depth` | traversal stops at leaf, no infinite loop on cyclic data |

### 1.4 `ZCL_HR360_REPORT_ENGINE_TEST`

| # | Test | Assert |
|---|---|---|
| U40 | `master_scope_filter_orgunit` | only in-scope org units returned |
| U41 | `master_active_only` | `active_only = X` → only `EmploymentStatus = '3'` |
| U42 | `missing_data_sorted_severity` | Critical rows precede Warning |
| U43 | `audit_summary_math` | with/without-issue counts + avg completeness correct |
| U44 | `csv_record_layout` | field order, separator, UTF-8, trailing newline |
| U45 | `empty_scope_no_dump` | no matching employees → 0 rows, clean return |

**Coverage target:** ≥ 80 % statement coverage on `ZCL_HR360_REPORT_ENGINE`
and `ZCL_HR360_ORG_READER`; every `ZI_HR360_ISSUE` branch hit at least once.

---

## 2. Functional / Integration (manual, sandbox)

Prerequisites: 3–5 PA30 test employees —
one **complete**, one with **several gaps**, one with a **manager & direct
reports**, one with **education + qualifications**, one with **absences/quota**.

### 2.1 Employee 360 — Object Page

| # | Scenario | Steps | Expected |
|---|---|---|---|
| F01 | Open a complete profile | search by name → open | header shows 100 % completeness, `QualityStatus` OK (green); all sections populated |
| F02 | Open a profile with gaps | open the "gaps" employee | completeness < 100 %, `QualityStatus` Critical/Warning; Data Quality facet lists each gap with severity colour |
| F03 | Personal details | check Personal facet | name, DOB, address, email, mobile, IBAN match PA30 |
| F04 | Organization | check Org facet | company code, org unit, position, cost center, manager match PA0001/OM |
| F05 | Education | check Education facet | rows match PA0022 (type, establishment, certificate, dates) |
| F06 | Skills / Certifications | check both facets | PA0024 rows split by type; proficiency shown; expired certs flagged |
| F07 | Leave & Attendance | check facets | quota entitlement/taken/remaining from PA2006; absences from PA2001; attendances from PA2002 |
| F08 | Pay history | check Payroll facet | PA0008 slices: pay-scale group/level, annual salary, currency, effective dates |
| F09 | Documents | check Documents facet | ArchiveLink docs listed with title/type/date; link opens content server in new tab |
| F10 | Timeline | check Timeline facet | events in reverse-chronological order: hire, org changes, pay changes, education, qualifications, long absences |
| F11 | No-data area | open employee with no ArchiveLink docs | Documents facet empty, no error |

### 2.2 Smart search & filters

| # | Scenario | Expected |
|---|---|---|
| F20 | Fuzzy name search ("Jonson" for "Johnson") | employee found |
| F21 | Filter by org unit | list restricted correctly |
| F22 | Filter by Quality Status = Critical | only employees with ≥1 critical issue |
| F23 | Search returns > 1 page | server paging works, scroll loads more |

### 2.3 Organizational navigation

| # | Scenario | Expected |
|---|---|---|
| F30 | Expand org tree from an employee | tree roots at the employee's org unit; children load on expand |
| F31 | Click a person node | navigates to that employee's Object Page |
| F32 | Headcount rollup | node shows count of persons beneath it |

### 2.4 HR Data Quality Audit (ALP)

| # | Scenario | Expected |
|---|---|---|
| F40 | Open dashboard | KPI header shows avg completeness, critical count, missing-data count |
| F41 | Chart by org unit | stacked bars with/without issues per org unit |
| F42 | Drill into a bar | employee list opens filtered to that org unit |
| F43 | Filter by personnel area | all KPIs and chart recompute |

### 2.5 Authorization

| # | Scenario | Setup | Expected |
|---|---|---|---|
| F50 | Full HR admin | `P_ORGIN` display for all | sees all employees |
| F51 | Restricted HR admin | `P_ORGIN` display for one personnel area | sees only that area's employees; others absent (not an error) |
| F52 | No HR authorization | tile assigned, no `P_ORGIN` | empty list, no dump |
| F53 | Report respects auth | run `ZHR360_R_MISSING_DATA` as F51 user | only in-scope rows |

### 2.6 Executable reports

| # | Scenario | Expected |
|---|---|---|
| F60 | Master export — ALV | selection by org unit → ALV with all columns; layout save works |
| F61 | Master export — file (background) | schedule via SM36; CSV written to app-server path; spool created; SLG1 log under `ZHR360` |
| F62 | Missing data report | ALV grouped by severity; subtotals per severity/category match the Object Page issue counts |
| F63 | HR audit report | summary figures match the ALP dashboard for the same selection |
| F64 | As-of date | run with a past key date → results reflect that date's infotype slices |

---

## 3. Regression Anchor

The reused PoC checks (`MAND_DOB`, `MAND_GENDER`, `ORG_COSTCTR`,
`PAY_BASICPAY`, `CONTACT_MAIL`, `BANK_IBAN`, `STAT_NATION`, `INVALID_DOB`)
must behave identically to `HR_DataQuality_RAP_PoC`. U01–U08, U11 are the
regression guard.

---

## 4. Exit Criteria

- All ABAP Unit tests green; coverage targets met.
- F01–F64 executed and passed on the sandbox.
- ATC clean (Clean-ABAP + S/4HANA Readiness variants).
- No open Critical/High defects in `BUGS_AND_ISSUES.md`.
