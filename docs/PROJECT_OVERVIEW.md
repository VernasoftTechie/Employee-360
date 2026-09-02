# Employee-360 — Project Overview (as-built)

**Read this first for continuation.** It is the current, accurate picture — the
design docs 01–08 describe the *original* plan, much of which changed during the
build (see `BUILD_ISSUES_LOG.md` for every reason). This file + the issues log +
`14_dashboard_requirement_spec.md` are the reference set.

**Repo:** `github.com/VernasoftTechie/Employee-360` · branch `main` · package `ZHR_UTIL`
**System:** SAP S/4HANA (SAP_BASIS 758), HANA, client 1000 has the live HR data.
**Status:** ✅ Employee 360 service + preview working on live data (41,439 employees).
Dashboard backend done; dashboard UI (Overview Page app) is the next work.

---

## 1. What it is

A **read-only** solution over standard SAP HCM (PA/OM) infotypes:

1. **Employee 360** — one Fiori page per employee: identity, org, personal
   details, education, skills, leave, attendance, pay history, documents,
   timeline, and a **data-quality panel**.
2. **Data-quality engine** — 12 checks over every active employee → per-employee
   issue list, counts, status (OK / Warning / Critical) and a completeness %.
3. **Data Health dashboard** (in progress) — HR-wide roll-up of the above.
4. **3 executable reports** — Employee Master Export, Missing Data Validation,
   HR Audit.

**Zero custom DDIC** — no Z tables, domains or data elements. Everything reads
standard tables.

---

## 2. Architecture (as-built)

```
Standard PA/OM/ArchiveLink tables
        │  (read-only, date-valid, DCL on P_ORGIN)
        ▼
CDS interface views  ZI_HR360_*        ← raw infotype reads, no text joins
        │
        ├── ZI_HR360_EMP_BASIC (anchor: 1 row per active employee)
        ├── ZI_HR360_ISSUE     (12-branch UNION = the check framework)
        ├── ZI_HR360_EMP_KPI   (per-employee counts + status + completeness %)
        └── ZI_HR360_EMPLOYEE  (flat root: EMP_BASIC ⋈ PERSONAL ⋈ EMP_KPI ⋈ HIREDATE)
        ▼
CDS query views  ZC_HR360_*            ← "as select from", read-only, inline @UI
        │
        ├── ZC_HR360_EMPLOYEE           (List Report + Object Page, 8 assoc facets)
        ├── ZC_HR360_<detail> ×8        (Education, Qualif, Leave, Attendance,
        │                                Payroll, Document, Timeline, Issue)
        └── ZC_HR360_KPI_OVERVIEW /_DQ_BY_STATUS /_DQ_BY_AREA /_DQ_BYCHECK
                                        (keyed aggregate views for the dashboard)
        ▼
Service definition  ZHR360_UI_SRVD  →  binding  ZHR360_UI_SRVB_O4  (OData V4 - UI)
        ▼
Fiori Elements  (currently the ADT preview; production = BAS-generated apps)
```

**Key deviation from the original design:** there is **no RAP Business Object**.
A read-only unmanaged BO on `strict(2)` requires lock + operation wiring that
does not fit a pure query with no persistent table (`BUILD_ISSUES_LOG.md` A19).
The views are plain read-only CDS exposed via OData — a valid S/4 pattern. The
transactional BO wrapper can be revisited later (`strict(1)` or managed shell).

---

## 3. Object inventory (`/src`, package `ZHR_UTIL`)

### Interface CDS (19)
`ZI_HR360_EMP_BASIC` · `_EMP_CONTACT` · `_EMP_BANK` · `_EMP_PAY` · `_PERSONAL` ·
`_ORGASSIGN` · `_HIREDATE` · `_EMP_KPI` · `_ISSUE` · `_EMPLOYEE` (root) ·
`_EDUCATION` · `_QUALIF` · `_LEAVE` · `_ATTENDANCE` · `_PAYROLL` · `_DOCUMENT` ·
`_TIMELINE`
*(`_ORGASSIGN` and 7 detail views are unwired-into-root but active and used by
`_ISSUE` / the detail query views.)*

### Query CDS (13)
`ZC_HR360_EMPLOYEE` (root, `@Search`, `@UI` header+facets+datapoints) ·
`_EDUCATION` · `_QUALIF` · `_LEAVE` · `_ATTENDANCE` · `_PAYROLL` · `_DOCUMENT` ·
`_TIMELINE` · `_ISSUE` · **`_KPI_OVERVIEW`** · **`_DQ_BYCHECK`** ·
**`_DQ_BY_STATUS`** · **`_DQ_BY_AREA`**

### DCL (3)
`ZI_HR360_EMP_BASIC_DCL` · `_ORGASSIGN_DCL` · `_EMPLOYEE_DCL` — `P_ORGIN`,
activity Display (`AUTHC = 'R'`), maps PERSA/PERSG/PERSK.

### Service
`ZHR360_UI_SRVD` (14 entity sets) + `ZHR360_UI_SRVB_O4` (OData V4 – UI,
published, **shipped in the repo** with its `.sush` auth default).

### ABAP (7)
`ZIF_HR360_REPORT_ENGINE` + `ZCL_HR360_REPORT_ENGINE` (report logic) ·
`ZCL_HR360_ORG_READER` (OM traversal helper, not yet wired) ·
`ZCL_HR360_ISSUE_TEST` (ABAP Unit, CDS test doubles) ·
`ZHR360_R_EMP_MASTER_EXPORT` · `ZHR360_R_MISSING_DATA` · `ZHR360_R_HR_AUDIT`
(thin report programs over the engine, `CL_SALV_TABLE`, background-enabled).

### Other
`ZMSG_HR360` (message class) · `package.devc.xml`.
**Manual (not in repo):** SLG0 log object `ZHR360` (used by the reports).

---

## 4. The data-quality engine — how it is calculated

`ZI_HR360_ISSUE` — `UNION ALL` of **12 SELECTs**, each = one rule, each returns a
row **only for employees who fail it**:

| # | CheckID | Sev | Fails when |
|---|---|---|---|
| 1 | MAND_DOB | C | PA0002 date of birth blank |
| 2 | MAND_GENDER | C | PA0002 gender blank |
| 3 | STAT_NATION | C | PA0002 nationality blank |
| 4 | ORG_COSTCTR | C | PA0001 cost center blank |
| 5 | ORG_POSITION | C | PA0001 position not assigned |
| 6 | PAY_BASICPAY | W | no valid PA0008 |
| 7 | CONTACT_MAIL | W | no PA0105 subty 0010 |
| 8 | BANK_IBAN | C | PA0009 main record without IBAN |
| 9 | EDU_MISSING | W | no PA0022 |
| 10 | QUAL_MISSING | W | no PA0024 |
| 11 | CONTACT_ADDR | W | no PA0006 country |
| 12 | INVALID_DOB | C | date of birth in the future |

`ZI_HR360_EMP_KPI` (grouped by employee):
```
TotalIssueCount     = count(distinct CheckID)
CriticalIssueCount  = failed checks with Severity 'C'
WarningIssueCount   = failed checks with Severity 'W'
QualityStatus       = 'CRITICAL' if CriticalIssueCount > 0
                      'WARNING'  else if TotalIssueCount > 0
                      'OK'       else
CompletenessPercent = (12 - TotalIssueCount) / 12 * 100   (abap.dec 6,2)
```

**Current live numbers (whole system, no filter):** 38,263 CRITICAL, 3,176 OK,
0 WARNING-only. ~92 % of employees fail ≥ 1 critical check — the biggest driver
is almost certainly `BANK_IBAN` / `ORG_COSTCTR` / `CONTACT_MAIL` missing en
masse. `ZC_HR360_DQ_BYCHECK` breaks that down per check. **Tuning the check set
to the client's reality is a business decision** (e.g. IBAN is only mandatory in
some countries) — the framework makes adding / removing / re-severity-ing a
check a one-branch CDS edit + updating the `12` constant.

Adding a check → copy a `UNION` branch in `ZI_HR360_ISSUE`, set the literals +
predicate, bump `12` in `ZI_HR360_EMP_KPI`. Reports + dashboard update
automatically.

---

## 5. What works today

| Thing | State |
|---|---|
| `ZHR360_UI_SRVD` / `ZHR360_UI_SRVB_O4` | ✅ active, published |
| `Employee` List Report (ADT preview) | ✅ 41,439 rows, filters, completeness bar, quality traffic-light, worst-first sort |
| `Employee` Object Page | ✅ header + KPI datapoints + 8 detail sections (Education / Skills / Leave / Attendance / Pay / Documents / Timeline / Data Quality) |
| `KpiOverview` / `StatusSplit` / `AreaHealth` / `CheckFailure` | ✅ activate, return data (as tables in the plain preview) |
| 3 executable reports + engine + unit test | ✅ activate (not yet run end-to-end by the user) |
| `P_ORGIN` DCL | ✅ enforced (activity Display) |

## 6. What is pending

| Item | Where | Notes |
|---|---|---|
| **Data Health dashboard app** | BAS | Overview Page — see `14_dashboard_requirement_spec.md` + `DASHBOARD_BUILD.md`. Backend is ready. |
| **Employee 360 app** (real, not preview) | BAS | List Report + Object Page wizard on `Employee`; annotations already done. |
| Launchpad tiles + `ZHR360_DISPLAY` role | Fiori config | 2 tiles, catalog/group `ZHR360`, role = catalog + `P_ORGIN` + `S_SERVICE`. |
| Text columns (`*Name`) | CDS | All text-table joins were removed after "column unknown" errors (A10). Re-add per text table, verified in SE11 on the live system. |
| Manager resolution + org-nav tree | CDS + UI5 | Stubbed / removed. `ZCL_HR360_ORG_READER` is the starting point. |
| Move `@UI` to Metadata Extensions | CDS | Rulebook §2. Blocked on the abapGit DDLX format — create one MDE in ADT, read back how abapGit serialises it, then migrate. |
| RAP BO wrapper | CDS/RAP | Optional; only if a transactional/edit scenario appears. |
| Run + validate the 3 reports | ABAP | Create SLG0 object `ZHR360` first. |
| The clean-pull "push from system" | abapGit | User does Stage→Commit once from SAP so the repo mirrors abapGit's exact serialisation (baseinfo, xml order) — then pulls are clean forever (G3/G4). |

---

## 7. Key rules learned (full list in `BUILD_ISSUES_LOG.md`)

- CDS `WHERE` goes **after** the `{}`; no `IN()` in join `ON`; `/` needs decimals
  (use `division()`); `UNION` needs identical `key`+named elements in every branch.
- `@EndUserText.label` ≤ 40 chars.
- Never `cast` an integer literal to NUMC; **cast every infotype date to
  `abap.dats`** (conversion exit `PDATE` breaks OData); **cast every CURR/QUAN
  field** to `abap.dec`; **cast HANA `sum()`/`avg()` results** explicitly (they
  return BIGINT / wide decimal that SADL can't map → runtime dump).
- A CDS element must not be named `<X>Type` when `<X>` is an OData entity-set
  name (→ EDM name clash). A `CASE` or `cast()` **expression** cannot be a `key`
  element or a `GROUP BY` term.
- A projection view (`as projection on`) can't hold a `CASE`; computed columns
  live in the interface view.
- Read-only aggregate views for an OData V4 **UI** binding **must have keys** —
  so no `@Analytics.query` there.
- abapGit `.xml` metadata files need a **UTF-8 BOM**; source files must not have
  one. DDLS also needs a `.ddls.baseinfo`.
