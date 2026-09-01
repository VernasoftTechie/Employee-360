# Employee-360 — Technical Specification (Doc 10)

**Status:** Baselined with docs 01–08.
**Audience:** ABAP / RAP developers, Basis, transport owners.

---

## 1. System & Toolset

| Item | Value |
|---|---|
| Platform | SAP S/4HANA 2023, On-Premise |
| ABAP language version | Standard ABAP |
| Data model | CDS View Entities, RAP (unmanaged, read-only) |
| Service | OData V4, UI |
| UI | Fiori Elements (List Report, Object Page, Analytical List Page) + one freestyle SAPUI5 custom section |
| Repository | abapGit, `github.com/VernasoftTechie/Employee-360`, `/src` flat, `FOLDER_LOGIC = PREFIX` |
| ABAP package | **`ZHR_UTIL`** — one package for every object; `src/package.devc.xml` carries its description, repo linked to `ZHR_UTIL` in abapGit on pull (no sub-packages) |
| Transport | one workbench TR for all objects |

---

## 2. Object Inventory

### 2.1 CDS — interface / helper (`/src/zi_hr360_*.ddls.asddls`)

`ZI_HR360_EMP_BASIC`, `ZI_HR360_EMP_CONTACT`, `ZI_HR360_EMP_BANK`,
`ZI_HR360_EMP_PAY`, `ZI_HR360_PERSONAL`, `ZI_HR360_ORGASSIGN`,
`ZI_HR360_EDUCATION`, `ZI_HR360_QUALIF`, `ZI_HR360_LEAVE`,
`ZI_HR360_ATTENDANCE`, `ZI_HR360_PAYROLL`, `ZI_HR360_DOCUMENT`,
`ZI_HR360_HIREDATE`, `ZI_HR360_MANAGER`, `ZI_HR360_ORG_NODE`,
`ZI_HR360_TIMELINE`, `ZI_HR360_ISSUE`, `ZI_HR360_EMPLOYEE` (root),
`ZI_HR360_ORG_HIER` (hierarchy).

### 2.2 CDS — projection (`/src/zc_hr360_*.ddls.asddls`)

`ZC_HR360_EMPLOYEE`, `ZC_HR360_PERSONAL`, `ZC_HR360_ORGASSIGN`,
`ZC_HR360_EDUCATION`, `ZC_HR360_QUALIF`, `ZC_HR360_LEAVE`,
`ZC_HR360_ATTENDANCE`, `ZC_HR360_PAYROLL`, `ZC_HR360_DOCUMENT`,
`ZC_HR360_TIMELINE`, `ZC_HR360_ISSUE`, `ZC_HR360_KPI_OVERVIEW` (analytical).

### 2.3 Metadata extensions (`/src/zc_hr360_*_mde.ddlx.asddlx`)

One per projection listed in Doc 07 §8.

### 2.4 Behavior (`/src/*.bdef.asbdef`) — as built

Child detail entities are modelled as **compositions** of the root, so the root
BDEF covers the root + all 8 composition children in one file:

- `ZI_HR360_EMPLOYEE` — root + `Personal` / `OrgAssignment` / `Education` /
  `Qualification` / `LeaveBalance` / `Attendance` / `PayrollItem` / `Document`
- `ZI_HR360_TIMELINE`, `ZI_HR360_ISSUE` — standalone (derived UNION views reached
  by association, own BDEF — the PoC pattern)
- `ZI_HR360_ORG_HIER` — hierarchy BDEF
- `ZC_HR360_EMPLOYEE`, `ZC_HR360_TIMELINE`, `ZC_HR360_ISSUE` — projection BDEFs

### 2.5 Behavior pools (`/src/zbp_hr360_*.clas.abap` + `.clas.locals_imp.abap`) — as built

Three pools (one per interface BDEF that needs handlers):

- `ZBP_HR360_EMPLOYEE` — `lhc_employee` (read, 12× `rba_*`, global + instance
  `P_ORGIN` authorization) and `lhc_child_reader` (read for the 8 composition
  children)
- `ZBP_HR360_TIMELINE` — `lhc_timeline` (read)
- `ZBP_HR360_ISSUE` — `lhc_issue` (read)

`ZI_HR360_ORG_HIER` is a `define hierarchy` entity — READ needs no handler code.

### 2.6 DCL (`/src/zi_hr360_*_dcl.dcls.asdcls`) — as built

- `ZI_HR360_EMP_BASIC_DCL`, `ZI_HR360_ORGASSIGN_DCL` — direct `aspect pfcg_auth
  ( P_ORGIN, PERSA, PERSG, PERSK, INFTY = '0001', AUTHC = 'R' )`
- `ZI_HR360_EMPLOYEE_DCL` — `inheriting conditions from entity ZI_HR360_EMP_BASIC`
- `ZI_HR360_{PERSONAL,EDUCATION,QUALIF,LEAVE,ATTENDANCE,PAYROLL,DOCUMENT}_DCL` —
  `inheriting conditions from entity ZI_HR360_EMPLOYEE`
- `ZI_HR360_EMP_CONTACT` / `_BANK` / `_PAY`, `ZI_HR360_ISSUE`, `ZI_HR360_TIMELINE`
  — `#NOT_REQUIRED` (filter inherited via the view they are selected from / RBA
  only). Explicit DCL for `TIMELINE` is BUGS_AND_ISSUES #001.

### 2.7 Classes (`/src/zcl_hr360_*` / `zif_hr360_*`) — as built

`ZIF_HR360_REPORT_ENGINE` (local types, no custom DDIC), `ZCL_HR360_REPORT_ENGINE`,
`ZCL_HR360_ORG_READER`, and the ABAP Unit class `ZCL_HR360_ISSUE_TEST` (CDS Test
Double Framework, one method per check branch). The additional test classes named
in Doc 11 (`ZCL_HR360_EMPLOYEE_TEST`, `_ORG_READER_TEST`, `_REPORT_ENGINE_TEST`)
are follow-on work — not in the initial push.

### 2.8 Reports (`/src/zhr360_r_*.prog.abap`)

`ZHR360_R_EMP_MASTER_EXPORT`, `ZHR360_R_MISSING_DATA`, `ZHR360_R_HR_AUDIT`.

### 2.9 Service (`/src/zhr360_ui_srvd.srvd.srvdsrv`)

`ZHR360_UI_SRVD`. **Service binding `ZHR360_UI_SRVB_O4` is created by the
implementer, not shipped in the repo** (per project note).

### 2.10 Other

Package `ZHR_UTIL` (`/src/package.devc.xml` — description only).
Message class `ZMSG_HR360` (`/src/zmsg_hr360.msag.xml`).
Application Log object `ZHR360` — **created manually via SLG0** (not
transportable as source in the same way; see §7).

### 2.11 NOT in the repo

No DDIC tables, domains or data elements (standard tables only). No service
binding. No generated Fiori Elements apps (generated in BAS by the implementer
from the service). The freestyle org-tree section files are provided under
`/ui/orgTree/` as reference to paste into the generated app.

---

## 3. Clean-Core / Clean-ABAP Compliance

| Rule | Compliance |
|---|---|
| Released APIs / standard tables only | ✔ read-only access to SAP standard PA/OM/ArchiveLink tables via CDS |
| CDS View Entity (no legacy) | ✔ `define view entity` throughout |
| Metadata Extensions for UI | ✔ no `@UI` in views |
| No modifications to SAP objects | ✔ none |
| Inline decl / `VALUE` / `REDUCE` / `CORRESPONDING` / `FILTER` | ✔ reports & classes |
| No header lines / `OCCURS` / `TABLES` / `SELECT` in `LOOP` / native SQL | ✔ |
| OO only | ✔ reports are thin shells over classes |
| ATC clean | target — run ATC with the S/4HANA Readiness + Clean-ABAP variants before C1 release |

---

## 4. Key Technical Decisions

1. **Unmanaged read-only RAP** — root not 1:1 with a table; no persistence to
   manage. Read handlers are single set-based `SELECT`s from the CDS views.
2. **Child detail entities as compositions of the root** (Personal, OrgAssignment,
   Education, Qualification, LeaveBalance, Attendance, PayrollItem, Document) — one
   BDEF + one behavior pool for the whole tree. `Timeline` / `DataQualityIssue`
   stay association-linked with their own BDEF (derived UNION views, PoC pattern).
3. **Check framework in pure CDS** — the PoC's catalog table is removed;
   `CheckID/Category/Severity/Description` are CDS literals in each `ZI_HR360_ISSUE`
   UNION branch. Active-branch count is a CDS constant driving `CompletenessPercent`.
4. **One OData V4 service** for transactional + analytical + hierarchy entity
   sets.
5. **`P_ORGIN` (display)** enforced twice: DCL on the CDS views and
   global/instance authorization in the behavior pool. Structural authorization
   flagged as a go-live add-on, isolated to `get_instance_authorizations`.

---

## 5. Performance & Volume

| Concern | Handling |
|---|---|
| List Report page runs root KPI aggregation | `ZI_HR360_ISSUE` filters early on active employees; each UNION branch = one PERNR+date-indexed infotype read; aggregation on HANA, no ABAP loops |
| Large `_Timeline` / `_DataQuality` per employee | server-side paging on all entity sets; page-size hint in MDE if needed |
| Text joins | all against buffered `T*` tables |
| Reports over full workforce | single set-based `SELECT`; ALV streamed; file via `OPEN DATASET` on app server |
| Deep org traversal | `ZCL_HR360_ORG_READER` bulk-reads HRP1000/1001 into internal tables, no nested selects |

No secondary indexes (cannot add to standard tables). If a specific
customer dataset shows slow List Report response, options (documented, not
pre-implemented): a CDS `@ObjectModel.usageType` analytical flag, or
materialising the issue view via a scheduled snapshot report — both additive.

---

## 6. Error Handling

- All report / class messages via message class `ZMSG_HR360`; no hard-coded
  text.
- Reports log every run to Application Log object `ZHR360` (selection summary,
  row count, runtime, any "source not configured" notes).
- CDS/RAP read errors surface through standard RAP `reported`/`failed`
  structures; no custom exception flow (nothing is written).
- `ZCL_HR360_ORG_READER` raises `ZCX_HR360` *(local exception class; if a
  transportable exception class is preferred it is `ZCX_HR360` in `ZHR_UTIL` — no
  DDIC involved)* on unresolvable hierarchy input, caught and logged by callers.

---

## 7. Deployment Steps (implementer)

1. **abapGit:** clone the repo, map package to **`ZHR_UTIL`**, pull.
2. Resolve activation order — see repo `README.md` §"Activation order"
   (CDS leaves → derived → root → BDEF → behavior pools → projections → MDE →
   service → classes → reports).
3. **Behavior pools:** after activating each BDEF, use ADT Quick Fix
   *"Add missing method implementations"* to (re)generate the RAP handler
   **signatures** for the local system kernel, then keep the method **bodies**
   from the pulled `.clas.locals_imp.abap`. (Doc 01 §13 caveat.)
4. **SLG0:** create Application Log object `ZHR360` with subobject `REPORT`.
5. **Message class:** verify `ZMSG_HR360` messages activated.
6. **Service binding:** create `ZHR360_UI_SRVB_O4` (OData V4 UI) on
   `ZHR360_UI_SRVD`, activate, publish on the front-end server.
7. **ATC:** run against the package, resolve findings, release C1 on
   interfaces + service after first clean run.
8. **Fiori:** generate the List Report + Object Page app and the ALP in BAS
   from the service; add the `/ui/orgTree/` custom section to the OP app;
   create catalog/group/role `ZHR360*` and the launchpad tiles.
9. **Authorizations:** build business role `ZHR360_DISPLAY` = Fiori catalog +
   `P_ORGIN` (display) + OData service authorization.

---

## 8. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Behavior-pool signature mismatch on pull | documented regeneration step (§7.3); bodies are system-independent |
| Client uses non-standard PA0105 subtypes / ArchiveLink object | single-line change in the affected view; flagged inline |
| Qualifications catalog not maintained | skill/cert names blank; ids + proficiency still shown |
| `aspect_ref` DCL inheritance not supported on release | fallback DCL variant documented (Doc 05 §7) |
| CERT vs SKILL split needs config | defaults to all-SKILL; `case` ladder added at build if the client supplies groups |
