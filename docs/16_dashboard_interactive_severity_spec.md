# 16 — Interactive Data-Health Dashboard: user-defined severity + org-scoped drill

**Status:** approved for build — Tier 1 first
**Date:** 2026-09-07
**Applies to:** the S/4 on-stack build (`ui/dashboard`, CDS in `src/`).
The same interaction model carries to the BTP/CAP rebuild (`docs/15`) — only the
data source swaps.
**Catalogue version:** `CAT_2026_09` (Tier 1). Completeness % is relative to the
checks active in this catalogue version — see §6.

---

## 1. What changes

Two capabilities on top of the current dashboard:

1. **User decides severity.** A checklist panel lets the user mark every check as
   **Critical** or **Warning** (two states only — no "ignore"). The overview KPIs,
   the status donut, the "failures by check" chart and the detail table all
   recompute against that choice. Severity is no longer hard-coded in CDS.
2. **Drill scopes the whole dashboard.** Clicking an org bar (Company code →
   Personnel area → Org unit) re-scopes **every** card and chart — not just the
   org bar and detail table as today. Drill again → everything follows.

---

## 2. Interaction model

### 2.1 Severity checklist

- A panel (collapsible, top of the page) lists **categories**, each expandable to
  its **checks**.
- Each check has a `Critical | Warning` toggle. A category-level toggle sets all
  its checks at once.
- **Apply** recomputes the dashboard. **Reset** returns to the default mapping.
- The chosen mapping is stored in the browser (`localStorage`, key
  `hr360.dh.severity`). Default mapping (§5) ships in code and is used when
  nothing is stored. *(Org-wide persistence would need a Z customising table —
  out of scope here under the "standard tables only" rule; it comes with the CAP
  rebuild as a proper user-settings entity.)*

### 2.2 Org drill

- Unchanged UX: one bar chart, in-place drill, breadcrumb, "View employees"
  button.
- **New:** the current org path is a filter applied to the KPI strip, the donut,
  the "failures by check" chart and the detail table.
- Levels: `L0` all companies → `L1` personnel areas of the picked company → `L2`
  org units of the picked company + personnel area. "View employees" / a leaf
  click cross-navigates to Employee 360 filtered by the path.

### 2.3 Classification (per employee, evaluated client-side)

```
failedCritical = the employee fails ≥ 1 check currently marked Critical
failedWarning  = the employee fails ≥ 1 check currently marked Warning

status = CRITICAL  if failedCritical
       = WARNING   if failedWarning and not failedCritical
       = OK         otherwise   (fails no check)
```

`OK / "Fully clean"` = fails **zero** checks in the catalogue.

---

## 3. Data design

### 3.1 One new view — `ZC_HR360_EMP_DQ`

One row per employee. Built with the working `ZI_HR360_EMP_KPI` pattern
(`ZI_HR360_EMP_BASIC` left join `ZI_HR360_ISSUE`, group by employee) — no
aggregate-over-aggregate, no A28 dump risk.

| Field | Type | Note |
|---|---|---|
| `EmployeeID` | key | |
| `CompanyCode` | | from PA0001 |
| `PersonnelArea` | | |
| `PersonnelSubarea` | | |
| `EmployeeGroup` | | |
| `OrgUnit` | | `'00000000'` → treated as unassigned |
| `CostCenter` | | |
| `FailedCheckCount` | int4 | `count( distinct Iss.CheckID )` |
| `FailedChecks` | string | comma list, e.g. `MAND_DOB,BANK_IBAN` — `string_agg( Iss.CheckID, ',' )` |

Exposed as entity set **`EmployeeDq`** on `ZHR360_UI_SRVD`.

*Fallback if `string_agg` misbehaves on this release:* keep `ZC_HR360_EMP_DQ`
without `FailedChecks`, and additionally page the existing issue-grain
`DataQualityIssue` entity (one row per employee+check) — the client joins the two
by `EmployeeID`. `ZC_HR360_EMP_DQ` is still needed for the OK population (no issue
rows).

### 3.2 Client-side aggregation

- On load the dashboard pages **all** `EmployeeDq` rows into memory
  (~41,439 rows ≈ 3–4 MB JSON, ≈ 400 KB gzipped; 2–4 s first load).
- Holds the severity map from `localStorage` / default.
- Every visual is a pure function of `(rows in current org scope, severity map)`:
  - **KPI strip** — counts of total / CRITICAL / WARNING / OK, plus % for each.
  - **Status donut** — the same three buckets.
  - **Failures by check** — `FailedChecks` exploded and counted; toggle
    per-check ↔ per-category.
  - **Org bar** — group rows by the current drill level; measure = **% critical**
    (default) with a toggle to **# critical** and **avg completeness %**.
    *(Fixes the "every bar ~90 %" problem — completeness barely varies, % critical
    discriminates.)*
  - **Detail table** — group by `Company / Personnel area / Org unit`; columns:
    Employees, **# CRITICAL employees** (not # issues — fixes the current
    "1180 > 815" bug), # WARNING, Completeness %, Status.
- Drill / severity change = re-run the in-memory aggregation. No server round-trip
  after the initial load. Re-compute < 100 ms.

### 3.3 Existing views

`ZC_HR360_DQ_BY_STATUS`, `ZC_HR360_DQ_BYCHECK`, `ZC_HR360_DQ_BY_AREA`,
`ZC_HR360_KPI_OVERVIEW` stay (used by the Fiori Elements previews / other
consumers) but **no longer drive the dashboard**.

---

## 4. Check catalogue — Tier 1 (v1 build)

Every Tier-1 check needs **no new infotype access** — only field additions to the
six source views already in the build, plus `UNION` branches in
`ZI_HR360_ISSUE`. `CheckID` ≤ 12 chars. "Rule" = condition that raises the issue.

### Personal Data  (PA0002 — already in `ZI_HR360_EMP_BASIC`)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `MAND_DOB` * | Date of birth missing | `GBDAT` initial | Critical |
| `INVALID_DOB` * | Date of birth implausible | `GBDAT` in the future, or age < 15 / > 75 | Critical |
| `MAND_GENDER` * | Gender missing | `GESCH` initial | Critical |
| `STAT_NATION` * | Nationality missing | `NATIO` initial | Critical |
| `PERS_LASTNM` | Last name missing | `NACHN` initial | Critical |
| `PERS_FIRSTN` | First name missing | `VORNA` initial | Critical |
| `PERS_MARITAL` | Marital status missing | `FAMST` initial | Warning |
| `PERS_LANG` | Language key missing | `SPRSL` initial | Warning |

### Organizational Assignment  (PA0001 — already in `ZI_HR360_EMP_BASIC`)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `ORG_ORGUNIT` | Org unit missing | `ORGEH` initial / `00000000` | Critical |
| `ORG_POSITION` * | Position not assigned | `PLANS` initial / `99999999` | Critical |
| `ORG_JOB` | Job (Stelle) missing | `STELL` initial | Warning |
| `ORG_COSTCTR` * | Cost center missing | `KOSTL` initial | Critical |
| `ORG_EEGROUP` | Employee group / subgroup missing | `PERSG` or `PERSK` initial | Critical |
| `ORG_PSUBAREA` | Personnel subarea missing | `BTRTL` initial | Warning |
| `ORG_ADMIN` | Payroll / time / HR administrator missing | `SACHA` or `SACHP` or `SACHZ` initial | Warning |

### Basic Pay — structure only  (PA0008 via `ZI_HR360_EMP_PAY`; amounts are parked, §7)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `PAY_BASICPAY` * | Basic pay record missing | no PA0008 valid today | Critical |
| `PSCL_TYPEAREA` | Pay scale type / area missing | `TRFAR` or `TRFGB` initial | Warning |
| `PSCL_GRPLEVEL` | Pay scale group / level missing | `TRFGR` or `TRFST` initial | Warning |

### Bank & Payment  (PA0009 via `ZI_HR360_EMP_BANK`)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `BANK_IBAN` * | Bank details missing | no PA0009 (main bank) valid today **with** `IBAN` filled **or** (`BANKL` and `BANKN` both filled) | Critical |
| `BANK_PAYMETH` | Payment method missing | `ZLSCH` initial on the main bank record | Critical |
| `BANK_XFERNOBK` | Payment method is transfer but no bank details | `ZLSCH` in (transfer methods) and bank details absent | Critical |

*(`BANK_PAYMETH` / `BANK_XFERNOBK` need `ZLSCH` added to `ZI_HR360_EMP_BANK` — one
field. If `ZLSCH`/transfer-method config needs confirmation, ship `BANK_IBAN`
first and add these two right after.)*

### Address  (PA0006 subtype 1 via `ZI_HR360_EMP_CONTACT`)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `CONTACT_ADDR` * | Permanent address missing | no PA0006 subty 1 valid today | Critical |
| `ADDR_STREET` | Street missing | `STRAS` initial | Warning |
| `ADDR_CITY` | City missing | `ORT01` initial | Warning |
| `ADDR_POSTAL` | Postal code missing | `PSTLZ` initial | Warning |
| `ADDR_COUNTRY` | Country missing | `LAND1` initial | Critical |

### Communication  (PA0105 via `ZI_HR360_EMP_CONTACT`)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `CONTACT_MAIL` * | Business email missing | no PA0105 subty 0010 valid today | Warning |
| `COMM_MOBILE` | Mobile / phone missing | no PA0105 subty 0020 valid today | Warning |

### Education & Qualifications  (PA0022 / PA0024)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `EDU_MISSING` * | No education record | zero PA0022 rows | Warning |
| `QUAL_MISSING` * | No qualification / skill | zero PA0024 rows | Warning |
| `QUAL_EXPIRED` | All qualifications expired | ≥ 1 PA0024 row and every row `ENDDA` < today | Warning |

### Leave & Time Quotas  (PA2006)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `LEAVE_NOQUOTA` | No leave quota / entitlement | zero PA2006 rows valid this year | Warning |
| `LEAVE_NEGBAL` | Negative leave balance | `ANZHL − KVERB` < 0 on any current quota | Critical |

### Documents  (ArchiveLink TOA01)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `DOC_NONE` | No documents on file | zero TOA01 entries for the PREL object | Warning |

`*` = already implemented today (rule unchanged except `BANK_IBAN`, which is
loosened per this spec).

**Tier 1 total: ~31 checks.** `N = 31` for the completeness denominator in
catalogue version `CAT_2026_09`.

---

## 5. Default severity mapping

Shipped in code, overridable per user (§2.1).

**Critical (default):** `MAND_DOB`, `INVALID_DOB`, `MAND_GENDER`, `STAT_NATION`,
`PERS_LASTNM`, `PERS_FIRSTN`, `ORG_ORGUNIT`, `ORG_POSITION`, `ORG_COSTCTR`,
`ORG_EEGROUP`, `PAY_BASICPAY`, `BANK_IBAN`, `BANK_PAYMETH`, `BANK_XFERNOBK`,
`CONTACT_ADDR`, `ADDR_COUNTRY`, `LEAVE_NEGBAL`.

**Warning (default):** `PERS_MARITAL`, `PERS_LANG`, `ORG_JOB`, `ORG_PSUBAREA`,
`ORG_ADMIN`, `PSCL_TYPEAREA`, `PSCL_GRPLEVEL`, `ADDR_STREET`, `ADDR_CITY`,
`ADDR_POSTAL`, `CONTACT_MAIL`, `COMM_MOBILE`, `EDU_MISSING`, `QUAL_MISSING`,
`QUAL_EXPIRED`, `LEAVE_NOQUOTA`, `DOC_NONE`.

---

## 6. Completeness %

```
Completeness %(employee) = (N − FailedCheckCount) / N × 100
    N = number of checks in the active catalogue version (Tier 1: N = 31)
```

- Every catalogue check counts toward `N` (D = Critical/Warning only, no "ignore").
- Completeness is **relative to the catalogue version**. When Tier 2 checks are
  added, `N` grows and the metric re-bases — record the catalogue version
  alongside any stored/period comparison.
- Org / area completeness = simple average of member employees' completeness.

---

## 7. Payroll Data Quality — Additional Scope

> **Status: Based on Customer Specification — Action Pending for Discussions.**

**Parked.** Not in Tier 1 or Tier 2. To be scoped in a dedicated discussion.
Covers, subject to the customer's payroll configuration and country grouping(s)
(MOLGA):

- Wage-type presence and amounts — PA0008 `LGART` / `BETRG` / `ANSAL`
  ("at least one wage type with amount > 0", mandatory base-salary wage type
  present).
- Pay-scale reclassification due / overdue.
- Capacity utilisation level (`BSGRD`) 0 or > 100.
- Payment-method policy consistency beyond `BANK_PAYMETH` / `BANK_XFERNOBK`.
- Tax infotype missing — country infotype (e.g. PA0012 DE, PA0210 US, PA0161 IN…).
- Social-insurance infotype missing — country infotype (e.g. PA0013, PA0209…).
- Recurring payments / deductions — PA0014 / PA0015 completeness.
- Planned working time where payroll-relevant — PA0007 `SCHKZ` / `EMPCT` / `WOSTD`
  (note: PA0007 `SCHKZ` / `EMPCT` also appear in Tier 2 as org/time checks; the
  payroll angle is the amount/valuation impact).

**Open questions for the payroll discussion:**
1. Is SAP Payroll (PY) run in this S/4 system? Which MOLGA(s)?
2. Wage-type-level checks — generic "amount > 0", or named mandatory wage types?
3. Pay-scale structure completeness — flag, and at what severity?
4. Payment-method policy rules.
5. PA0014 / PA0015 in scope for a DQ baseline?
6. PA0007 completeness in scope?

---

## 8. Tier 2 — defined backlog (after Tier 1)

One small new source view each, over a standard infotype the client certainly
has. No country infotypes, no OM/CO joins.

| Infotype | New view | Checks |
|---|---|---|
| **PA0185** | `ZI_HR360_EMP_ID` | National ID / SSN missing (presence + type) |
| **PA0000** | `ZI_HR360_EMP_STATUS` | No hiring action / hire date missing; employment status inconsistent (active with no current PA0001, or withdrawn with active infotypes); active employee past retirement age (with PA0002) |
| **PA0007** | `ZI_HR360_EMP_WTIME` | Work schedule rule (`SCHKZ`) missing; capacity utilisation / employment percent (`EMPCT`) zero; weekly hours (`WOSTD`) zero |
| **PA0016** | `ZI_HR360_EMP_CONTRACT` | Contract type (`CTTYP`) missing; fixed-term contract with no end date; probation-period end missing |
| **PA0021** | `ZI_HR360_EMP_FAMILY` | No emergency contact (subtype 6) |
| **BNKA** (referential) | join in `ZI_HR360_EMP_BANK` | Bank key on PA0009 not present in the bank master |

Adding Tier 2 = new `UNION` branches in `ZI_HR360_ISSUE`, new `CheckID`s, extend
the default mapping, bump the catalogue version, increase `N`. **No dashboard code
change** — it re-aggregates whatever checks the service returns.

---

## 9. Tier 3 — requires a discovery workshop

- Tax / social-insurance infotypes — country-specific (needs MOLGA + the client's
  infotype list).
- Referential integrity via OM/CO joins: position / org unit exists in OM
  (HRP1000), chief position defined (HRP1001 A012), cost centre valid in CO
  (CSKS), cost centre ↔ company code consistency.
- Time-slice analysis: PA0001 org-assignment gaps / overlaps.

---

## 10. Bugs folded into this build (seen 2026-09-07)

| Symptom | Fix |
|---|---|
| Org bar chart — every bar ~85–92 %, not informative | default measure → **% critical**; toggle to # critical / avg completeness; fix truncated axis |
| Detail table "Critical" = 1180 for 815 employees | column becomes **# CRITICAL employees**, not # critical issues |
| Org unit shows `0` for unassigned employees | label `(unassigned)` |
| `BANK_IBAN` flags employees whose bank key + account are maintained | rule loosened — IBAN **or** (`BANKL` + `BANKN`) |

---

## 11. Build order

1. **CDS** — extend the six source views with the extra fields; add the Tier-1
   `UNION` branches to `ZI_HR360_ISSUE`; create `ZC_HR360_EMP_DQ`; expose
   `EmployeeDq` on the service. Re-activate, confirm preview.
2. **Dashboard controller** — page all `EmployeeDq` rows; severity model
   (default + `localStorage`); rewrite every visual as a client-side aggregation
   of `(scope, severity)`.
3. **Checklist panel** — categories → checks, `Critical | Warning` toggles,
   Apply / Reset, persistence.
4. **Chart fixes** — §10.
5. **Test** — counts reconcile against the executable reports; drill + severity
   toggle behave; first-load timing acceptable.

Estimated ~1–1.5 weeks.
