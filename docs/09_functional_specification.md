# Employee-360 — Functional Specification (Doc 09)

**Status:** Baselined with docs 01–08.
**Audience:** HR process owners, functional consultants, testers.

---

## 1. Purpose

Give HR a single Fiori application that shows the **complete profile of any
employee** — personal, organizational, developmental, time and pay information —
plus a reporting layer that surfaces **data-quality gaps** across the workforce.

The solution is **display-only**. No employee data is created or changed through
it; corrections are made in the standard HR maintenance transactions.

---

## 2. Actors

| Actor | Description | Access |
|---|---|---|
| HR Administrator | Central HR / HR operations staff | Can view **any** employee permitted by their `P_ORGIN` display authorization |
| HR Manager (reporting) | Consumes the audit dashboard | Same authorization object; typically broader org scope |

Managers-of-teams and employees-viewing-themselves are **not** in scope for
Phase 1 (see Future Scope).

---

## 3. Functional Scope

### 3.1 Employee 360 profile (App 1)

| Area | Content | Source module |
|---|---|---|
| Header | Name, employee ID, org unit, position, manager, data-completeness %, open-issue count | PA / OM |
| Personal Details | Name, date & place of birth, gender, nationality, marital status, address, email, mobile, bank/IBAN | PA0002/0006/0105/0009 |
| Organization & Position | Company code, personnel area/subarea, employee group/subgroup, org unit, position, job, cost center, manager | PA0001 + OM |
| Org Navigation | Interactive reports-to / org-unit tree, drill to any node, jump to a colleague's profile | OM (HRP1001) |
| Education | Education & training records with establishment, certificate, discipline, dates | PA0022 |
| Skills | Qualifications held, proficiency, validity | PA0024 |
| Certifications | Qualifications flagged as certifications, with validity/expiry | PA0024 |
| Leave & Quotas | Absence quota entitlement, taken, remaining; recorded absences | PA2006 / PA2001 |
| Attendance | Recorded attendances with type, dates, hours | PA2002 |
| Pay History | Pay-scale group/level, annual salary, currency, change reason, effective dates | PA0008 |
| Documents | Personnel-file documents (metadata + link to content server) | ArchiveLink `PREL` |
| Timeline | Chronological feed of hires/actions, org changes, pay changes, education, qualifications, long absences | derived |
| Data Quality Issues | Per-employee list of failed completeness/validity checks with severity | derived |

### 3.2 Smart Search (App 1)

Free-text / fuzzy search on last name, first name and org unit; structured
filters on company code, personnel area, employee group, org unit, employment
status and data-quality status.

### 3.3 HR Data Quality Audit (App 2)

Analytical dashboard: employees with / without issues, missing-data count,
critical vs warning counts, average completeness %, broken down by company
code, personnel area, employee group and org unit, with drill-down into the
employee list.

### 3.4 Executable reports

| Report | Business use |
|---|---|
| Employee Master Export | Periodic full extract of employee master data for audit / downstream systems (ALV or file) |
| Missing Data Validation | Operational worklist of data gaps for HR to correct |
| HR Audit Report | Management summary of data-completeness health by organization |

All three run online or as scheduled background jobs.

---

## 4. Data-Quality Checks (Phase 1)

| Check | Severity | Trigger |
|---|---|---|
| Date of birth missing | Critical | PA0002-GBDAT initial |
| Gender missing | Critical | PA0002-GESCH initial |
| Nationality missing | Critical | PA0002-NATIO initial |
| Cost center missing | Critical | PA0001-KOSTL initial |
| Position not assigned | Critical | PA0001-PLANS initial |
| Basic pay record missing | Warning | no valid PA0008 |
| Email address missing | Warning | no PA0105 subtype 0010 |
| IBAN / bank details missing | Critical | PA0009 main record without IBAN |
| No education record | Warning | no PA0022 |
| No qualification / skill | Warning | no PA0024 |
| Date of birth in the future | Critical | PA0002-GBDAT > today |
| *(reserved for growth — one CDS branch each)* | | |

Completeness % = 100 − (failed checks ÷ total checks × 100).
Quality status: **OK** (0 issues) / **Warning** (only warnings) / **Critical**
(≥1 critical).

Adding a new check is a CDS-only change (one UNION branch) — no new tables,
services or UI.

---

## 5. Business Rules

1. All data is read **as of the current date** in the Fiori app; the reports
   allow an "as of" key date.
2. A user only ever sees employees within their HR display authorization
   (`P_ORGIN`, activity *Display*).
3. If a data area is not configured in the system (e.g. no ArchiveLink), the
   corresponding section simply shows no rows — never an error.
4. Certifications and skills both originate from PA0024; the split is derived
   from the qualification group.
5. Manager is derived from the position hierarchy (chief position → holder);
   where the hierarchy is incomplete, manager is blank.

---

## 6. Assumptions

- Classic SAP HCM (PA + OM) is the system of record and is reasonably
  maintained.
- PA0105 subtypes: 0010 = email, 0020 = mobile.
- ArchiveLink object `PREL` is used for personnel-file documents (if at all).
- Qualifications catalog (object types Q / QK) is maintained for readable
  skill names.

Each assumption degrades gracefully (blank columns) if untrue.

---

## 7. Out of Scope / Future

Performance Review, Training Matrix, Succession Planning, manager-self-service,
employee-self-service, write-back / data maintenance, payroll-results detail,
wage-type-level pay breakdown, time-evaluation cluster results.
