# Employee-360 — Solution Architecture

**Project:** HR Employee 360 — complete employee profile in one Fiori application
**Repository:** https://github.com/VernasoftTechie/Employee-360.git
**Status:** DRAFT (rev 2) — awaiting architecture approval before any ABAP is written
(Rulebook §8: *"Never generate implementation before architecture approval"*).

**Rev 2 changes:** standard tables only — **zero custom DDIC objects**
(no `ZT_HR360_CHECK_CAT`, no `ZT_HR360_CERT`); ABAP package = **`Z001`**
(existing, assigned by you on abapGit pull).

---

## 1. Scope Recap

A **read-only** RAP application that assembles a 360° view of an employee from
classic SAP HCM (PA/OM) data, plus an HR data-quality / audit reporting layer.

**In scope (Phase 1):**

| Requirement block | Delivered as |
|---|---|
| Personal Details, Org Structure, Position, Department | Root entity + Personal / Org child facets |
| Education | Child composition (0..n) — PA0022 |
| Skills, Certifications | Single `_Qualification` child (0..n) — PA0024 (no standard IT distinguishes the two) |
| Leave, Attendance, Payroll | Child compositions (0..n) |
| Documents | Child composition (0..n), metadata only |
| Employee Dashboard | Fiori Elements Object Page (rich header + facets) |
| Timeline | Derived child composition (union over infotype history) |
| Smart Search | CDS `@Search` + Fiori search field |
| Organizational Navigation | CDS hierarchy view + freestyle UI5 tree section |
| Employee Master Export | Executable report (OO ALV, background-enabled) |
| Missing Data Validation | Executable report over the CDS check framework (`ZI_HR360_ISSUE`) |
| HR Audit Report | Executable report (issues + KPI summary) |
| Background Processing | Variant + `JOB_OPEN`/`JOB_SUBMIT` on all three reports |

**Explicitly out of scope (Future Scope per the spec):** Performance Review,
Training Matrix, Succession Planning. No write-back to any HR infotype. No
manager-self-service or employee-self-service personas (HR-admin only, see §9).

---

## 2. Target Platform (confirmed)

| Dimension | Decision |
|---|---|
| System | SAP S/4HANA 2023, On-Premise |
| ABAP language version | Standard ABAP (not the ABAP Cloud restricted syntax) |
| HR data | Classic PA infotypes + OM (HRP1000/HRP1001) on the same system |
| RAP object type | **Unmanaged, read-only, non-draft** (§4) |
| OData | V4, UI |
| Fiori | Embedded (S/4 front-end server); service **binding created by you** |
| Consumers | HR / HR-admin viewing **any** employee (§9) |
| Multi-client / tenant sharding | No — standard single-client handling |

---

## 3. Layered Architecture (Rulebook §3)

```
┌───────────────────────────────────────────────────────────────┐
│  Fiori Elements — Object Page (Employee 360 dashboard)         │
│  + Analytical List Page / Overview Page (HR-wide KPI audit)    │
│  + one freestyle UI5 section (Org Navigation tree)             │
├───────────────────────────────────────────────────────────────┤
│  Service Binding  (OData V4, UI)               ← owned by you  │
├───────────────────────────────────────────────────────────────┤
│  Service Definition — ZHR360_UI_SRVD                           │
├───────────────────────────────────────────────────────────────┤
│  CDS Projections  ZC_HR360_*   + Behavior Projections          │
├───────────────────────────────────────────────────────────────┤
│  Root Interface View  ZI_HR360_EMPLOYEE                        │
│  + Behavior Definition (unmanaged, read-only)                  │
├───────────────────────────────────────────────────────────────┤
│  CDS Interface Views  ZI_HR360_*  (one per information domain) │
│  + derived views: ZI_HR360_TIMELINE, ZI_HR360_ISSUE,          │
│    ZI_HR360_ORG_HIER                                           │
├──────────────────────────────┬────────────────────────────────┤
│  Persistence (READ-ONLY,      │  Execution-time components:    │
│  standard tables only —       │   - ZCL_HR360_REPORT_ENGINE    │
│  ZERO custom DDIC objects):    │     (executable-report logic)  │
│   - PA0000/0001/0002/0006/     │   - ZCL_HR360_ORG_READER       │
│     0008/0009/0022/0024/       │     (OM hierarchy traversal)   │
│     0105, PA2001/2002/2006     │                                │
│   - HRP1000/HRP1001, T5*       │                                │
│   - TOA01/TOAAT (ArchiveLink)  │                                │
└──────────────────────────────┴────────────────────────────────┘
```

**No custom DDIC objects.** All CDS interface views select only from SAP
**standard** tables. Standard tables are **never exposed directly** (Rulebook §3)
— every read goes through a `ZI_HR360_*` interface view with
`@AccessControl.authorizationCheck` set.

The right-hand column is plain ABAP OO — invoked from the executable reports and
(where needed) from the behavior pool. It is unit-testable in isolation from the
RAP runtime.

---

## 4. RAP Object Type — Unmanaged, Read-Only, Non-Draft

**Decision: Unmanaged RAP Business Object, read-only, non-draft.**

Rationale (mirrors the approved `HR_DataQuality_RAP_PoC` reasoning):

- The root `ZI_HR360_EMPLOYEE` is **not 1:1 with a single table** — it joins
  PA0001 + PA0002 + org/position texts and carries computed columns (data-quality
  KPI counts, completeness %). SAP's own documented criterion for choosing
  **unmanaged** over managed. (There is also no custom persistence table to
  "manage" — reinforcing the unmanaged choice.)
- **Read-only:** no CREATE / UPDATE / DELETE is generated on any entity. Defense
  in depth — the BDEF declares no modifying operations, and the behavior pool
  additionally disables edit features and denies edit authorization.
- **Non-draft:** nothing is edited, so there is no draft use case.
- Every child is a **read-only composition** — the `read` handler is a straight
  `SELECT` from the corresponding interface view; all computation already happens
  on the database in CDS.

### 4.1 Composition Hierarchy

Root: `ZI_HR360_EMPLOYEE` (one row per employee active on the key date)

```
Employee (ZI_HR360_EMPLOYEE)
 ├─ _Personal      (ZI_HR360_PERSONAL)      1:1   PA0002 / PA0006 / PA0105 / PA0009 / PA0000
 ├─ _OrgAssignment (ZI_HR360_ORGASSIGN)     1:1   PA0001 + T500P/T501T/T503T/T527X + HRP1000
 ├─ _Education     (ZI_HR360_EDUCATION)     0..n  PA0022 (+ T517T / T517X / TB039 texts)
 ├─ _Qualification (ZI_HR360_QUALIF)        0..n  PA0024 (+ OM catalog HRP1000 for names, §7.4) — covers Skills AND Certifications
 ├─ _LeaveBalance  (ZI_HR360_LEAVE)         0..n  PA2006 (quotas) + PA2001 (absences)
 ├─ _Attendance    (ZI_HR360_ATTENDANCE)    0..n  PA2002
 ├─ _Payroll       (ZI_HR360_PAYROLL)       0..n  PA0008 (basic-pay history)
 ├─ _Document      (ZI_HR360_DOCUMENT)      0..n  ArchiveLink TOA01/TOAAT metadata (see §7.5)
 ├─ _Timeline      (ZI_HR360_TIMELINE)      0..n  derived — union over infotype begda history
 └─ _DataQuality   (ZI_HR360_ISSUE)         0..n  CDS check framework (see §6)
```

All children are keyed by `EmployeeID` (+ their own sub-key). Time-dependent
infotypes are filtered to the key date (`$session.system_date`) in the interface
views, consistent with the PoC's pattern (`begda <= … and endda >= …`).

**Skills vs Certifications:** no standard infotype separates them — both live in
PA0024 (Qualifications). `_Qualification` exposes a `QualificationType` column
derived from the OM qualification group so the UI can still show two facets
("Skills", "Certifications") filtered off one entity. Expiry-style certifications
use the PA0024 `endda` as validity end.

---

## 5. Reuse of `HR_DataQuality_RAP_PoC` (confirmed: reuse & extend)

The following objects are **taken into this repository** and renamed to the
`HR360` stem so Employee-360 is self-contained (no cross-repo dependency).
The PoC's one custom table (`ZHRDQ_CHECK_CAT`) is **dropped** — standard tables
only (§6).

| PoC object | Becomes | Change |
|---|---|---|
| `ZHRDQ_CHECK_CAT` (table) | — | **dropped**; check metadata inlined into CDS (§6) |
| `ZI_HRDQ_CHECK_CAT` (view) | — | dropped (no catalog table to expose) |
| `ZI_HRDQ_EMP_BASIC` | `ZI_HR360_EMP_BASIC` | rename; feeds root + checks |
| `ZI_HRDQ_EMP_CONTACT` | `ZI_HR360_EMP_CONTACT` | rename |
| `ZI_HRDQ_EMP_BANK` | `ZI_HR360_EMP_BANK` | rename |
| `ZI_HRDQ_EMP_PAY` | `ZI_HR360_EMP_PAY` | rename |
| `ZI_HRDQ_ISSUE` (UNION framework) | `ZI_HR360_ISSUE` | rename + **extend** with new checks (education / qualification / leave-quota / attendance / position) + inline check metadata as literals |
| `ZI_HRDQ_EMP_QUALITY` (KPI root) | folded into `ZI_HR360_EMPLOYEE` header | KPI counts become root columns, as in the PoC |
| `ZC_HRDQ_KPI_OVERVIEW` (analytical) | `ZC_HR360_KPI_OVERVIEW` | rename; drives the HR audit dashboard |
| `ZCL_HRDQ_ISSUE_TEST` | `ZCL_HR360_ISSUE_TEST` | rename + one test method per new check |

---

## 6. Data-Quality / Audit Layer (no custom table)

The PoC's catalog table (`CHECK_ID / CATEGORY / SEVERITY / DESCRIPTION /
IS_ACTIVE`) gave two things: (a) shared check metadata, (b) a runtime on/off
toggle. With **standard tables only**, both move into CDS:

- `ZI_HR360_ISSUE` — UNION ALL framework, one branch per check. Each branch
  starts `FROM ZI_HR360_EMP_BASIC` (guarantees one row per active employee, so
  "record missing entirely" is caught), LEFT JOINs the domain view, and
  `WHERE <field> IS INITIAL` (or an invalid-value predicate). The
  `CheckId / Category / Severity / IssueDescription / FieldName` columns are
  **CDS string literals** in each branch (the PoC already did this for
  `FieldName`).
- **Consequence — accepted:** no runtime "deactivate a check" switch. Adding or
  removing a check = one `UNION ALL` branch edited in `ZI_HR360_ISSUE` and
  re-activate. No other object changes. This is the trade-off for zero custom
  DDIC.
- `CompletenessPercent` denominator = a CDS constant equal to the number of
  active branches, defined once at the top of `ZI_HR360_ISSUE` / the root and
  referenced by name (documented inline — same discipline as the PoC, minus the
  table lookup).
- `ZC_HR360_KPI_OVERVIEW` — `@Analytics.query` view aggregating issues by
  CompanyCode / PersonnelArea / EmployeeGroup / OrgUnit / QualityStatus →
  measures: TotalEmployees, EmployeesWithIssues, MissingDataCount,
  CriticalIssueCount, WarningIssueCount, AvgCompletenessPercent.

No seed report is needed (nothing to seed).

---

## 7. Data Sources — per domain (SAP standard tables only)

All views select from SAP standard tables only. A few remaining points still
need your confirmation (marked **⚠ CONFIRM**) but none require a custom object —
if a source turns out not to be populated in your system, that child simply
returns no rows (CDS shell still ships).

### 7.1 Personal & Org (reused from PoC)
- PA0000 (status/action), PA0002 (name, DOB, gender, nationality),
  PA0006 subty `1` (address), PA0105 subty `0010`/`0020` (email/mobile),
  PA0009 subty `0` (bank).
- PA0001 (company code, personnel area/subarea, EE group/subgroup, org unit,
  cost center, position) + texts T500P / T501T / T503T / T527X.
- Position / Org unit long texts from HRP1000; reporting line from HRP1001
  (evaluation path O-S-P; relationship A/B 002 "reports to", 003 "belongs to").
- **⚠ CONFIRM 7.1:** PA0105 subtypes `0010` (email) / `0020` (mobile) match your
  client's IT0105 customizing (the PoC flagged this too).

### 7.2 Education
- PA0022 (education/training) + text tables T517T / T517X / TB039.

### 7.3 Certifications — PA0024 (no custom table)
Merged with Skills into `_Qualification` (§4.1). Certifications are read from
**PA0024** (Qualifications), distinguished from skills by the OM qualification
group. Fields available without a custom object: qualification id, name (from
catalog), proficiency/scale, `begda`/`endda` (validity — `endda` doubles as
"expiry"). **Not available** from standard: external issuer, external certificate
number, attachment link — the UI omits those columns. **⚠ CONFIRM 7.3:**
acceptable, or drop the Certifications facet entirely for Phase 1?

### 7.4 Skills / Qualifications
- PA0024 = qualification id + proficiency per employee.
- Readable names need the **OM qualifications catalog** (object types `Q` / `QK`
  via HRP1000/HRP1001). **⚠ CONFIRM 7.4:** catalog maintained? If not,
  `_Qualification` shows ids + proficiency only (flagged, not a gap).

### 7.5 Documents — ArchiveLink metadata (standard tables TOA01/TOAAT)
Read ArchiveLink link entries (**TOA01 / TOAAT** — SAP standard) for HR business
object `PREL` (personnel file); expose **metadata only** (archive doc id, doc
type + text, title, archive date, MIME type). UI renders a link to the content
server; no content copied into SAP. **⚠ CONFIRM 7.5:** is ArchiveLink for `PREL`
actually in use? If GOS attachments instead → still standard tables
(SRGBTBREL/SOOD), just a different view. If nothing configured → `_Document`
ships as a CDS shell returning no rows.

### 7.6 Leave & Attendance — raw infotypes only
- `_LeaveBalance` — PA2006 (absence quotas) + PA2001 (recorded absences, type
  text from T554T).
- `_Attendance` — PA2002 (recorded attendances).
- No time-evaluation cluster (PTQUODED / cluster B2). **⚠ CONFIRM 7.6.**

### 7.7 Payroll — PA0008 only
PA0008 basic-pay history (wage type, amount, currency, pay scale group/level,
valid-from). No payroll results cluster (RT / cluster RD). **⚠ CONFIRM 7.7.**

---

## 8. Timeline

`ZI_HR360_TIMELINE` — UNION ALL producing a uniform event row:

`( EmployeeID, EventDate, EventType, EventCategory, Title, Detail, SortTimestamp )`

Event sources (all read from infotype `begda` time-slices — **not** CDHDR/CDPOS
change documents):

| EventCategory | Source | Example title |
|---|---|---|
| HIRING / ACTION | PA0000 (massn / massg + T529T) | "Hire", "Organizational reassignment" |
| ORG_CHANGE | PA0001 slice starts | "Moved to Org Unit 50000123" |
| PAY_CHANGE | PA0008 slice starts | "Basic pay changed" |
| EDUCATION | PA0022 | "Completed B.Tech" |
| QUALIFICATION | PA0024 (covers skills + certifications) | "Acquired qualification Q 30000045" |
| ABSENCE | PA2001 (long absences only, configurable threshold) | "Maternity leave" |

Sorted descending by `SortTimestamp`. Rendered as a Fiori Elements
`@UI.lineItem` timeline facet (or `sap.suite.ui.commons.Timeline` in the
freestyle section — decided in doc 07).

---

## 9. Authorization (Rulebook §6)

- **Object:** `P_ORGIN` (HR: org assignment), `AUTHC = 'R'` (display).
- **Where enforced:**
  - `@AccessControl.authorizationCheck: #CHECK` on every `ZI_HR360_*` view.
  - Instance authorization in the behavior pool (`FOR INSTANCE AUTHORIZATION`)
    for the root — denies edit unconditionally, grants read per `P_ORGIN`.
  - `AUTHORITY-CHECK OBJECT 'P_ORGIN'` in each executable report before output.
- **Structural authorization** (`PLOG` / `P_ORGINCON`, profile-based via
  `HRBAS00_STRUAUTH`): **flagged, not implemented in Phase 1** — same explicit
  stance as the PoC. Most production HR deployments need it; call it out in the
  Technical Spec as a go-live prerequisite.
- **Application Log:** BAL object `ZHR360` (created manually via SLG0) — used by
  the executable reports for run logging.
- **Messages:** message class `ZMSG_HR360`. All report / behavior messages route
  through it (Rulebook §6).

---

## 10. Executable Reports (Rulebook §5 — OO, no header lines / OCCURS / SELECT-in-LOOP)

Shared engine class **`ZCL_HR360_REPORT_ENGINE`** (interface `ZIF_HR360_REPORT_ENGINE`),
plus one thin report program each:

| Report | Purpose | Output | Background |
|---|---|---|---|
| `ZHR360_R_EMP_MASTER_EXPORT` | Employee master export | `CL_SALV_TABLE` ALV + spool; optional file (CSV/XLSX via `XCO`) to app server as a parameter | variant + `JOB_OPEN`/`JOB_SUBMIT`/`JOB_CLOSE` |
| `ZHR360_R_MISSING_DATA` | Missing Data Validation | ALV of `ZI_HR360_ISSUE` rows, grouped by severity | same |
| `ZHR360_R_HR_AUDIT` | HR Audit Report | ALV summary from `ZC_HR360_KPI_OVERVIEW` + detail list | same |

All reports: selection screen (pernr range, org unit, company code, key date),
`AUTHORITY-CHECK` before read, BAL logging to `ZHR360`, no `SELECT` inside `LOOP`
(single set-based read via the CDS views), constructor-operator table building
(`VALUE` / `CORRESPONDING` / `REDUCE` / `FILTER`). No seed report — the check
framework is entirely in CDS (§6).

---

## 11. Smart Search & Organizational Navigation

### 11.1 Smart Search
- `@Search.searchable: true` on `ZC_HR360_EMPLOYEE`;
  `@Search.defaultSearchElement: true` + `@Search.fuzzinessThreshold` on
  LastName, FirstName, EmployeeID, OrgUnitName, PositionText.
- Fiori Elements search field on the List Report; no separate Enterprise Search
  (ESH) model in Phase 1 (can be added later without touching the BO).

### 11.2 Organizational Navigation — **⚠ CONFIRM 11.2**
- CDS **hierarchy view** `ZI_HR360_ORG_HIER` (`define hierarchy … child to parent
  association` over HRP1001, evaluation path O-O / O-S-P) exposed in the service.
- Consumed by a **freestyle SAPUI5 section** (`sap.ui.table.TreeTable`) embedded
  in the Object Page — Fiori Elements has no native tree control (same call the
  `RAP_Migration_Tool` architecture made for its Dependency Explorer).
- Confirm: acceptable to include one freestyle UI5 artifact in the repo, or must
  the whole UI stay pure Fiori Elements (in which case Org Navigation degrades to
  flat "Manager / Direct Reports" facets)?

---

## 12. Naming (Rulebook §4)

| Object type | Prefix / name |
|---|---|
| CDS interface views | `ZI_HR360_*` |
| CDS projection views | `ZC_HR360_*` |
| CDS root entity | `ZI_HR360_EMPLOYEE` |
| Behavior definitions | share entity name (`ZI_HR360_EMPLOYEE`, `ZC_HR360_EMPLOYEE`) |
| Behavior pools | `ZBP_HR360_*` |
| Classes | `ZCL_HR360_*` |
| Interfaces | `ZIF_HR360_*` |
| Tables | **none** — standard tables only, zero custom DDIC |
| Service definition | `ZHR360_UI_SRVD` |
| Reports | `ZHR360_R_*` |
| Message class | `ZMSG_HR360` (repository object, not a data table — required by Rulebook §6) |
| Application Log object | `ZHR360` (created by you via SLG0 — config, not a custom table) |
| Package | **`Z001`** (existing) — assigned by you in abapGit on pull; not created here |

---

## 13. Repository Layout & Delivery Format — **⚠ CONFIRM 13**

**Proposed (matches `RAP_Migration_Tool`):** proper abapGit format —
`/.abapgit.xml` (`STARTING_FOLDER=/src/`, `FOLDER_LOGIC=PREFIX`,
`MASTER_LANGUAGE=E`), all objects under `/src` as serialized abapGit files
(`*.ddls.asddls` + `.xml`, `*.clas.abap` + `.xml`, `*.srvd.asrvd`, `*.msag.xml`,
etc.), documentation under `/docs`. You map all objects to package **`Z001`** on
pull. With zero custom DDIC there are **no `*.tabl.xml`** files.

Caveat to confirm you accept: the RAP behavior-pool classes are shipped as
abapGit-serialized files, but on first `abapGit pull` into a system the
**behavior-pool method signatures** (`FOR READ`, `FOR INSTANCE AUTHORIZATION`)
may need one regeneration pass via ADT's Quick Fix on the activated BDEF, because
those signatures are tied to your kernel's RAP runtime version (the PoC README
documents this same caveat). All CDS / BDEF / SRVD / class-body / message-class
source is system-independent and pulls cleanly.

Alternative: HR DQ PoC style (loose `.asddls` source files + an ordered import
guide, manual paste into ADT). Safer first activation, but not a clean
`abapGit pull`.

`/docs` set (Rulebook §7 — all delivered and approved **before** any ABAP):

```
docs/
 01_solution_architecture.md      ← this document
 02_rap_business_object_model.md
 03_persistence_model.md
 04_cds_design.md
 05_behavior_design.md
 06_service_definition.md
 07_ui_navigation.md
 08_executable_reports.md
 09_functional_spec.md
 10_technical_spec.md
 11_test_scenarios.md
 12_version_history.md
 13_demo_guide.md
```

---

## 14. Build Order (after all docs approved)

1. Message class `ZMSG_HR360`; BAL object `ZHR360` (SLG0, manual).
2. Interface views — `ZI_HR360_EMP_BASIC` / `_CONTACT` / `_BANK` / `_PAY`
   (from PoC), then `_PERSONAL` / `_ORGASSIGN` / `_EDUCATION` / `_QUALIF` /
   `_LEAVE` / `_ATTENDANCE` / `_PAYROLL` / `_DOCUMENT`.
3. Derived views — `ZI_HR360_ISSUE`, `ZI_HR360_TIMELINE`, `ZI_HR360_ORG_HIER`.
4. Root — `ZI_HR360_EMPLOYEE` (+ compositions/associations).
5. BDEF (root + issue/child) → behavior pools `ZBP_HR360_*` (regenerate
   signatures, paste bodies).
6. Projections `ZC_HR360_*` (+ projection BDEFs), `ZC_HR360_KPI_OVERVIEW`.
7. Service definition `ZHR360_UI_SRVD` → **your service binding**.
8. Classes — `ZIF_/ZCL_HR360_REPORT_ENGINE`, `ZCL_HR360_ORG_READER`.
9. Reports — the three `ZHR360_R_*` reports.
10. ABAP Unit — `ZCL_HR360_ISSUE_TEST` (+ engine/org-reader tests).
11. Freestyle UI5 Org-Nav section (if §11.2 approved).

---

## 15. Settled vs Open

**Settled (rev 2):**
- Standard SAP tables only — zero custom DDIC (no check-catalog table, no
  certification table). Check framework fully in CDS (§6).
- Package `Z001` (existing), assigned on abapGit pull.
- Skills + Certifications merged into one `_Qualification` child on PA0024.
- Read-only unmanaged non-draft BO; HR-admin persona; `P_ORGIN` AUTHC=R.
- Reuse & rename the PoC's employee interface views + issue framework + KPI
  query + test class to the `HR360` stem (self-contained repo).

**Open — confirm before Doc 02:**

| # | Question | Default if silent |
|---|---|---|
| C-7.1 | PA0105 subtypes `0010`/`0020` = email/mobile in your client? | assume yes |
| C-7.3 | Certifications from PA0024 only (no issuer / cert-number / attachment columns) acceptable — or drop the Certifications facet? | PA0024 only |
| C-7.4 | OM qualifications catalog maintained (for readable skill names)? | assume yes; degrade to IDs |
| C-7.5 | Documents: ArchiveLink `PREL` in use? GOS instead? Nothing? | ArchiveLink `PREL`; empty shell if absent |
| C-7.6 | Leave/Attendance from raw infotypes only (no time-eval cluster)? | raw infotypes only |
| C-7.7 | Payroll = PA0008 basic pay only (no results cluster)? | PA0008 only |
| C-11.2 | One freestyle SAPUI5 tree section allowed for Org Navigation? | yes, include it |
| C-13 | Delivery format: abapGit `/src` (proposed) vs PoC loose-file style? | abapGit `/src` |

Once these are settled, Doc 02 (RAP Business Object Model) proceeds. No ABAP is
written until docs 02–08 are also approved (Rulebook §7, §8).
