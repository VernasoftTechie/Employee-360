# 16 — Interactive Data-Health Dashboard: user-defined severity + org-scoped drill

**Status:** approved for build — **Tier 1 + Tier 2 together** (v1). Payroll parked (§7).
**Date:** 2026-09-07
**Applies to:** the S/4 on-stack build (`ui/dashboard`, CDS in `src/`).
The same interaction model carries to the BTP/CAP rebuild (`docs/15`) — only the
data source swaps.
**Catalogue version:** `CAT_2026_09` — **46 checks** (Tier 1 ≈ 34 + Tier 2 ≈ 12).
Completeness % is relative to the checks active in this catalogue version — §6.

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

Two data sets, both read with proven CDS patterns — **no `string_agg`, no
aggregate-over-aggregate, no A28 dump risk.**

### 3.1 `ZC_HR360_EMP_DQ` — the roster (one row per employee)

Built with the working `ZI_HR360_EMP_KPI` pattern (`ZI_HR360_EMP_BASIC` left join
`ZI_HR360_ISSUE`, group by employee + the org fields).

| Field | Type | Note |
|---|---|---|
| `EmployeeID` | key | |
| `CompanyCode` `PersonnelArea` `PersonnelSubarea` `EmployeeGroup` `EmployeeSubgroup` `OrgUnit` `CostCenter` | | from PA0001; `OrgUnit` `'00000000'` → shown as `(unassigned)` |
| `FailedCheckCount` | int4 | `count( distinct Iss.CheckID )` |

Exposed as entity set **`EmployeeDq`**. Needed for the total population, the
completeness denominator, and the **OK employees** (who have no issue rows).

### 3.2 `DataQualityIssue` — the failures (one row per employee + failed check)

The existing entity, from `ZI_HR360_ISSUE`. **Extended** with the org fields
(`CompanyCode, PersonnelArea, PersonnelSubarea, EmployeeGroup, OrgUnit,
CostCenter`) — `ZI_HR360_ISSUE` already selects from `ZI_HR360_EMP_BASIC`, so this
is just projecting columns it already has. Lets the client filter/group failures
by org without a join.

Fields the client uses: `EmployeeID, CheckID, CategoryCode` + the org fields.
(`Severity` / `IssueDescription` stay for tooltips but the client ignores the CDS
severity — that is now the user's runtime choice.)

### 3.3 Client-side aggregation

- On load the dashboard pages **all** `EmployeeDq` rows (~41,439 ≈ 2 MB, ≈ 250 KB
  gzipped) **and all** `DataQualityIssue` rows (~60–90 k ≈ 3 MB, ≈ 300 KB
  gzipped). Total first load ≈ 4–6 s.
- Builds `Map<EmployeeID, Set<CheckID>>` from the issues; every roster employee
  not in the map (or with an empty set) is OK.
- Holds the severity map from `localStorage` / default.
- Every visual is a pure function of `(rows in current org scope, severity map)`:
  - **KPI strip** — counts of total / CRITICAL / WARNING / OK, plus % for each.
  - **Status donut** — the same three buckets.
  - **Failures by check** — `DataQualityIssue` counted by `CheckID`; toggle
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

### 3.4 Existing views

`ZC_HR360_DQ_BY_STATUS`, `ZC_HR360_DQ_BYCHECK`, `ZC_HR360_DQ_BY_AREA`,
`ZC_HR360_KPI_OVERVIEW` stay (used by the Fiori Elements previews / other
consumers) but **no longer drive the dashboard**.

---

## 4. Check catalogue — v1 (Tier 1 + Tier 2)

`CheckID` ≤ 12 chars. "Rule" = the condition that raises the issue. `Src` column:
**T1** = no new infotype access (field add to an existing source view + a `UNION`
branch); **T2** = one small new source view over a standard infotype.
`*` = already implemented today (rule unchanged except `BANK_IBAN`, loosened).

### Personal Data  (PA0002 — already in `ZI_HR360_EMP_BASIC`)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `MAND_DOB` * | Date of birth missing | `GBDAT` initial | Critical |
| `INVALID_DOB` * | Date of birth in the future | `GBDAT` > today | Critical |
| `PERS_DOBAGE` | Age implausible (< 15 / > 75) | deferred to increment C (needs `dats_add_days` verified) | Warning |
| `MAND_GENDER` * | Gender missing | `GESCH` initial | Critical |
| `STAT_NATION` * | Nationality missing | `NATIO` initial | Critical |
| `PERS_LASTNM` | Last name missing | `NACHN` initial | Critical |
| `PERS_FIRSTN` | First name missing | `VORNA` initial | Critical |
| `PERS_MARITAL` | Marital status missing | `FAMST` initial | Warning |
| `PERS_LANG` | Language key missing | `SPRSL` initial — **deferred** (LANG type cannot be `cast`; select raw in increment C) | Warning |

### Organizational Assignment  (PA0001 — already in `ZI_HR360_EMP_BASIC`)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `ORG_ORGUNIT` | Org unit missing | `ORGEH` initial / `00000000` | Critical |
| `ORG_POSITION` * | Position not assigned | `PLANS` initial / `99999999` | Critical |
| `ORG_JOB` | Job (Stelle) missing | `STELL` initial | Warning |
| `ORG_COSTCTR` * | Cost center missing | `KOSTL` initial | Critical |
| `ORG_EEGROUP` | Employee group / subgroup missing | `PERSG` or `PERSK` initial | Critical |
| `ORG_PSUBAREA` | Personnel subarea missing | `BTRTL` initial | Warning |
| `ORG_ADMIN` | No HR administrator assigned | `SACHA` **and** `SACHP` **and** `SACHZ` all initial | Warning |

### Basic Pay — structure only  (PA0008 via `ZI_HR360_EMP_PAY`; amounts are parked, §7)

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `PAY_BASICPAY` * | Basic pay record missing | no PA0008 valid today | Critical |
| `PSCL_TYPE` | Pay scale type / area missing | `TRFAR` or `TRFGB` initial | Warning |
| `PSCL_GRP` | Pay scale group / level missing | `TRFGR` or `TRFST` initial | Warning |

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
| `ADDR_STREET` | Street missing | address record exists (`LAND1` set) but `STRAS` initial | Warning |
| `ADDR_CITY` | City missing | address record exists but `ORT01` initial | Warning |
| `ADDR_POSTAL` | Postal code missing | address record exists but `PSTLZ` initial | Warning |

*(`ADDR_COUNTRY` folded into `CONTACT_ADDR` — "no address record OR country blank".)*

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

### Documents  (ArchiveLink TOA01)  — T1

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `DOC_NONE` | No documents on file | zero TOA01 entries for the PREL object | Warning |

---

### Identification & Statutory  (PA0185 — new view `ZI_HR360_EMP_ID`)  — T2

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `ID_NATIONAL` | National ID / identity document missing | zero PA0185 records valid today (or: no record of the client's national-ID subtype — §12 Q2) | Critical |
| `ID_EXPIRED` | All identity documents expired | ≥ 1 PA0185 record and every one has expiry (`ICNUM` date / `ENDDA`) < today | Warning |

### Employment & Status  (PA0000 — new view `ZI_HR360_EMP_STATUS`)  — T2

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `EMP_NOHIRE` | No hiring action on record | zero PA0000 records, or no record with a hire-category action (§12 Q3) | Warning |
| `EMP_STATINC` | Employment status inconsistent | `STAT2` = active but no PA0001/PA0002 valid today, **or** `STAT2` = withdrawn but infotypes valid today | Critical |
| `EMP_RETIRE` | Active employee past retirement age | `STAT2` active and age ≥ retirement threshold (default **60** — §12 Q1) | Warning |

### Working Time  (PA0007 — new view `ZI_HR360_EMP_WTIME`)  — T2

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `WT_NOSCHED` | Work schedule rule missing | no PA0007 valid today, or `SCHKZ` initial | Critical |
| `WT_CAPACITY` | Capacity utilisation / employment percent zero | `EMPCT` = 0 | Warning |
| `WT_HOURS` | Weekly working hours zero | `WOSTD` = 0 | Warning |

### Contract  (PA0016 — new view `ZI_HR360_EMP_CONTRACT`)  — T2

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `CT_NOTYPE` | Contract type missing | no PA0016 valid today, or `CTTYP` initial | Warning |
| `CT_FIXNOEND` | Fixed-term contract with no end date | `CTTYP` maintained and `CTEDT` (contract end) initial | Warning |

### Emergency & Family  (PA0021 — new view `ZI_HR360_EMP_FAMILY`)  — T2

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `FAM_NOEMERG` | No emergency contact | zero PA0021 subtype `6` records (§12 Q4) | Warning |

### Bank — referential  (BNKA join in `ZI_HR360_EMP_BANK`)  — T2

| CheckID | Check | Rule | Default |
|---|---|---|---|
| `BANK_KEYINV` | Bank key not in bank master | PA0009 `BANKL` not found in `BNKA` for `BANKS` (country) | Warning |

---

`*` = already implemented today (rule unchanged except `BANK_IBAN`, which is
loosened per this spec).

**v1 total: 46 checks** (Tier 1 ≈ 34 + Tier 2 ≈ 12). `N = 46` for the
completeness denominator in catalogue version `CAT_2026_09`.

---

## 5. Default severity mapping

Shipped in code, overridable per user (§2.1).

**Critical (default) — 20:** `MAND_DOB`, `INVALID_DOB`, `MAND_GENDER`,
`STAT_NATION`, `PERS_LASTNM`, `PERS_FIRSTN`, `ORG_ORGUNIT`, `ORG_POSITION`,
`ORG_COSTCTR`, `ORG_EEGROUP`, `PAY_BASICPAY`, `BANK_IBAN`, `BANK_PAYMETH`,
`BANK_XFERNOBK`, `CONTACT_ADDR`, `LEAVE_NEGBAL`, `ID_NATIONAL`,
`EMP_STATINC`, `WT_NOSCHED`.

**Warning (default) — 25:** `PERS_MARITAL`, `ORG_JOB`,
`ORG_PSUBAREA`, `ORG_ADMIN`, `PSCL_TYPE`, `PSCL_GRP`, `ADDR_STREET`,
`ADDR_CITY`, `ADDR_POSTAL`, `CONTACT_MAIL`, `COMM_MOBILE`, `EDU_MISSING`,
`QUAL_MISSING`, `QUAL_EXPIRED`, `LEAVE_NOQUOTA`, `DOC_NONE`, `ID_EXPIRED`,
`EMP_NOHIRE`, `EMP_RETIRE`, `WT_CAPACITY`, `WT_HOURS`, `CT_NOTYPE`, `CT_FIXNOEND`,
`FAM_NOEMERG`, `BANK_KEYINV`.

---

## 6. Completeness %

```
Completeness %(employee) = (N − FailedCheckCount) / N × 100
    N = number of checks in the active catalogue version (CAT_2026_09: N = 46)
```

- Every catalogue check counts toward `N` (D = Critical/Warning only, no "ignore").
- Completeness is **relative to the catalogue version**. When checks are added or
  removed, `N` changes and the metric re-bases — record the catalogue version
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

## 8. Tier 2 — new source views (in v1)

| New view | Infotype | Feeds checks |
|---|---|---|
| `ZI_HR360_EMP_ID` | PA0185 | `ID_NATIONAL`, `ID_EXPIRED` |
| `ZI_HR360_EMP_STATUS` | PA0000 | `EMP_NOHIRE`, `EMP_STATINC`, `EMP_RETIRE` |
| `ZI_HR360_EMP_WTIME` | PA0007 | `WT_NOSCHED`, `WT_CAPACITY`, `WT_HOURS` |
| `ZI_HR360_EMP_CONTRACT` | PA0016 | `CT_NOTYPE`, `CT_FIXNOEND` |
| `ZI_HR360_EMP_FAMILY` | PA0021 | `FAM_NOEMERG` |
| BNKA join added to `ZI_HR360_EMP_BANK` | BNKA | `BANK_KEYINV` |

Same pattern as Tier 1 for the dashboard: it re-aggregates whatever the service
returns — **no dashboard code change** when checks are added or removed.

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

Delivered in increments the user can import and verify one at a time (per
`BUILD_ISSUES_LOG.md` §F — fix the first real error, re-activate, repeat).

1. **CDS increment A — Tier 1 checks that need no source-view change** + create
   `ZC_HR360_EMP_DQ` + extend `ZI_HR360_ISSUE`/`DataQualityIssue` with the org
   fields + expose `EmployeeDq`. Import, activate all, preview `EmployeeDq` and
   `DataQualityIssue`.
2. **CDS increment B — remaining Tier 1**: add the extra fields to the 6 source
   views (`FAMST`, `SPRSL`, `SACHA/P/Z`, `ZLSCH`), new presence views for PA2006
   and TOA01, the rest of the Tier-1 `UNION` branches.
3. **CDS increment C — Tier 2**: the 5 new source views (`ZI_HR360_EMP_ID`,
   `_STATUS`, `_WTIME`, `_CONTRACT`, `_FAMILY`) + the BNKA join + their `UNION`
   branches.
4. **Dashboard controller** — page all `EmployeeDq` + `DataQualityIssue` rows;
   severity model (default + `localStorage`); rewrite every visual as a
   client-side aggregation of `(scope, severity)`.
5. **Checklist panel** — categories → checks, `Critical | Warning` toggles,
   Apply / Reset, persistence.
6. **Chart fixes** — §10.
7. **Help & tooltips** — §13.
8. **Test** — counts reconcile against the executable reports; drill + severity
   toggle behave; first-load timing acceptable.

Estimated ~2 weeks.

---

## 12. Assumptions to confirm

Small config-dependent choices. Where unconfirmed, the build uses the **generic
rule** in the right column and the check is refined later — no rework of the
framework, just the one `WHERE` clause.

| # | Question | Generic rule used if unconfirmed |
|---|---|---|
| Q1 | `EMP_RETIRE` retirement age threshold — 60 or 65? | age ≥ **60** |
| Q2 | `ID_NATIONAL` — is there a specific PA0185 subtype for the statutory national ID? | flag if **zero** PA0185 records valid today |
| Q3 | `EMP_NOHIRE` — which `MASSN` action types count as "hire"? | flag if **zero** PA0000 records |
| Q4 | `FAM_NOEMERG` — emergency-contact subtype (standard `6`)? | PA0021 subtype **`6`** |
| Q5 | `BANK_PAYMETH` / `BANK_XFERNOBK` — which `ZLSCH` values are bank transfer? | `BANK_IBAN` ships first; these two added once the codes are confirmed |
| Q6 | `CT_FIXNOEND` — which `CTTYP` values are fixed-term? | flag if `CTTYP` maintained **and** `CTEDT` empty (any type) |
| Q7 | Birthplace / country of birth (PA0002 `GBORT` / `GBLND`) — add as checks? | **not** included in v1 |

---

## 13. In-dashboard Help & tooltips

The dashboard ships with its own guidance so a business user needs no external
document.

### 13.1 Help panel (`?` button in the page header → dialog / side panel)

Sections:

1. **What this dashboard shows** — one paragraph: a point-in-time data-quality
   scan of every employee's HR master data against a catalogue of checks; you
   choose which checks are Critical vs Warning; the whole page can be drilled by
   organisation.
2. **How an employee is classified** — the CRITICAL / WARNING / OK rule (§2.3),
   and the completeness % formula (§6) in plain words.
3. **The checks** — the full catalogue grouped by category, each with: friendly
   name, what it looks at (infotype in business terms — "Bank details (IT0009)"),
   the exact rule, and its current severity. Rendered from the same catalogue
   metadata that drives the checklist, so it never drifts.
4. **Using the severity checklist** — how to change a check's severity, that
   changes are per-user and remembered in this browser, Reset restores defaults.
5. **Drilling by organisation** — click a bar to go Company → Personnel area →
   Org unit; the breadcrumb and every card follow; "View employees" opens the
   filtered employee list.
6. **Reading each card** — a short "how to read this" for the KPI strip, the
   status donut, "failures by check", the org bar (and its metric toggle), and
   the detail table.
7. **Data currency & scope** — data is as of the last dashboard load; scope is
   employees with a current organisational assignment; the user only sees
   organisations they are authorised for.
8. **What is *not* covered yet** — Payroll checks (parked, §7); Tier 3 checks
   (§9). Stated so users don't assume completeness.

### 13.2 Catalogue metadata (single source of truth)

A JSON block in the app (`model/checkCatalogue.json`) — one entry per check:
`{ id, category, name, description, infotypeLabel, ruleText, defaultSeverity }`.
Drives the checklist panel, the Help "checks" section, the per-check chart labels
and every check-related tooltip. Update this one file when a check is
added/changed.

### 13.3 Tooltips (hover / long-press)

| Element | Tooltip |
|---|---|
| KPI card "Critical" | "Employees failing at least one check you marked Critical. {n} of {total} ({pct} %)." |
| KPI card "Warning" | "Employees failing only Warning-level checks." |
| KPI card "Fully clean" | "Employees passing all {N} checks in the catalogue." |
| Donut segment | "{status}: {n} employees ({pct} %) in the current scope." |
| "Failures by check" bar | the check's `name` + `ruleText` + `infotypeLabel` + "{n} employees affected in scope." |
| Category bar (collapsed view) | "{category}: {n} employees failing one or more of its {k} checks." |
| Org bar | "{node}: {metric label} {value}. Click to drill in." + current metric explanation |
| Org-bar metric toggle | "% Critical = share of employees in the node that are CRITICAL. # Critical = count. Avg completeness = average of member completeness %." |
| Breadcrumb node | "Showing {Company / Personnel area / Org unit} = {key}. Click a higher level to widen." |
| Detail table "Critical" column header | "Number of employees (not issues) with CRITICAL status." |
| Detail table "Compl. %" cell | "Average completeness of the {n} employees in this row." |
| Checklist check row | the check's `ruleText` + `infotypeLabel` |
| Checklist category header | "Set every check in {category} to the same severity." |
| "Apply" | "Recalculate the dashboard with the current severity choices." |
| "Reset" | "Restore the default Critical / Warning mapping." |
| Refresh | "Reload employee data from the system." |

Tooltips use `sap.m` `tooltip` / `sap.ui.core.Popup` where richer content is
needed; all text comes from i18n so it is translatable.

### 13.4 Enhancement suggestions shown to the user

The Help panel ends with a **"Where you could take this next"** list — framed as
options for the customer, not commitments:

1. **Turn on the parked Payroll checks** (§7) once the payroll configuration is
   confirmed — wage-type presence, pay-scale completeness, tax & social-insurance
   infotypes.
2. **Add the Tier 3 checks** (§9) — cost-centre validity in CO, position/org-unit
   existence in OM, org-assignment gap analysis, retirement-age vs status.
3. **Schedule a periodic snapshot** — persist the daily counts so the dashboard
   can show a trend line ("critical employees down 4 % this month") instead of
   only today's picture.
4. **Push worklists to HR administrators** — email each `SACHP`/`SACHZ` owner the
   list of their employees failing Critical checks, so the numbers actually move.
5. **Org-wide severity policy** — instead of each user choosing, let an HR admin
   publish one approved Critical/Warning mapping everyone sees by default (needs a
   small settings store — arrives with the BTP/CAP rebuild, `docs/15`).
6. **Bring the drill down to employee level** — from a bar or the detail table,
   open the filtered Employee 360 list, then the individual 360 page, then the
   infotype in SAP GUI / Fiori to fix it.
7. **Add a "fix-by" target** — mark checks with an SLA (e.g. bank details within
   3 days of hire) and report on breaches, not just presence.
8. **Export** the current scope to spreadsheet for offline distribution.

---

## 14. Build status

| Increment | Contents | Catalogue branches | Commit | State |
|---|---|---|---|---|
| **A** | `ZC_HR360_EMP_DQ` roster view; `ZI_HR360_ISSUE` + `DataQualityIssue` extended with 6 org fields; Tier-1 checks needing no source-view change (`PERS_LASTNM`, `PERS_FIRSTN`, `ORG_ORGUNIT`, `ORG_JOB`, `ORG_EEGROUP`, `ORG_PSUBAREA`, `PSCL_TYPE`, `PSCL_GRP`, `COMM_MOBILE`); `BANK_IBAN` loosened (IBAN **or** bank key + account); completeness divisor 12 → 21 in the 3 aggregate views; test class refreshed | **21** | v0.36 | ✅ imported & activated by ABAP |
| **B** | `ZI_HR360_EMP_BASIC` += `FAMST`/`SACHA-P-Z`; `ZI_HR360_EMP_BANK` += `ZLSCH`; 2 helper views (`ZI_HR360_QUAL_STATUS`, `ZI_HR360_LEAVE_NEG`); +10 checks (`PERS_MARITAL`, `ORG_ADMIN`, `BANK_PAYMETH`, `ADDR_STREET`, `ADDR_CITY`, `ADDR_POSTAL`, `QUAL_EXPIRED`, `LEAVE_NOQUOTA`, `LEAVE_NEGBAL`, `DOC_NONE`); divisor 21 → 31; test class +4 methods | **31** | v0.38 | awaiting import + activation + preview |
| C | Tier-2 source views (PA0185/PA0000/PA0007/PA0016/PA0021) + BNKA join + branches; `PERS_DOBAGE` (deferred from B — needs `dats_add_days` syntax verified); `ZI_HR360_CHECK_CATALOG` (removes the hard-coded divisor) | ~45 | — | not started |
| D-G | dashboard rewrite: client-side aggregation of EmployeeDq + DataQualityIssue; org drill re-scopes every card; severity checklist panel (Critical/Warning per check, localStorage); metric toggle on org bar; by-check/by-category toggle; detail table shows # critical EMPLOYEES; Help panel (9 topics + enhancement list) + checkCatalogue.json single-source | — | v0.39 | UI - awaiting local test by Fiori consultant |
| E | severity checklist panel + persistence | — | — | not started |
| F | chart fixes (§10) | — | — | not started |
| G | Help panel + tooltips + `Checks` catalogue source (§13) | — | — | not started |

**The completeness divisor is a literal (`21`) in `ZI_HR360_EMP_KPI`,
`ZI_HR360_EMPLOYEE`, `ZC_HR360_KPI_OVERVIEW`** — increment B replaces it with a
count from `ZI_HR360_CHECK_CATALOG`. Until then, bump all three together with the
`ZI_HR360_ISSUE` branch count.
