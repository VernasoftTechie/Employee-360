# Employee-360 — Version History (Doc 12)

All notable changes to the design and the repository.

---

## v0.3 — 2026-08-31 — Design baseline (docs) + initial build

**Docs**
- Docs 02–08 approved as a batch (RAP BO model, persistence/source model, CDS
  design, behavior design, service definition, UI & navigation, executable
  reports).
- Docs 09–13 added (functional spec, technical spec, test scenarios, this file,
  demo guide).

**Build (initial commit of `/src`)**
- Interface CDS: `ZI_HR360_EMP_BASIC/_CONTACT/_BANK/_PAY` (renamed from
  `HR_DataQuality_RAP_PoC`), `ZI_HR360_PERSONAL`, `_ORGASSIGN`, `_EDUCATION`,
  `_QUALIF`, `_LEAVE`, `_ATTENDANCE`, `_PAYROLL`, `_DOCUMENT`, `_HIREDATE`,
  `_MANAGER`, `_ORG_NODE`, `_TIMELINE`, `_ISSUE`, `_EMPLOYEE` (root),
  `_ORG_HIER` (hierarchy).
- Projection CDS + metadata extensions for all consumption views.
- Behavior definitions (interface, projection, hierarchy) + 12 behavior pools.
- DCL roles on `P_ORGIN` (display).
- Service definition `ZHR360_UI_SRVD`.
- Message class `ZMSG_HR360`.
- Classes `ZIF_/ZCL_HR360_REPORT_ENGINE`, `ZCL_HR360_ORG_READER`, test classes.
- Reports `ZHR360_R_EMP_MASTER_EXPORT`, `_MISSING_DATA`, `_HR_AUDIT`.
- Reference UI files under `/ui/orgTree/` for the freestyle org-navigation
  section.

---

## v0.2 — 2026-08-31 — Architecture rev 2

- **Standard tables only** — removed all custom DDIC (`ZT_HR360_CHECK_CAT`,
  `ZT_HR360_CERT`). Check metadata inlined into `ZI_HR360_ISSUE` as CDS
  literals; certifications merged into `_Qualification` (PA0024).
- ABAP package fixed to **`Z001`** (existing).
- Open items D-7.1 / 7.3 / 7.4 / 7.5 / 7.6 / 7.7 / 11.2 / 13 / 5 resolved to
  defaults.

---

## v0.1 — 2026-08-31 — Architecture rev 1

- `01_solution_architecture.md` first draft.
- Confirmed: read-only unmanaged RAP BO; reuse & extend
  `HR_DataQuality_RAP_PoC`; HR-admin persona (`P_ORGIN`); embedded Fiori
  OData V4; deploy to `VernasoftTechie/Employee-360`.

---

## Conventions

- Versioning: `v<major>.<minor>` during pre-production; `v1.0` at first
  productive release.
- Every change to an approved design doc is logged here with date and reason.
- Defect fixes are tracked in `BUGS_AND_ISSUES.md` and summarised here per
  release.
