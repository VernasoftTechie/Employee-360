# Employee-360

**HR Employee 360** — a read-only SAP RAP application that assembles a complete
employee profile (personal, organizational, developmental, time, pay,
documents, timeline) in one Fiori app, plus an HR data-quality / audit
reporting layer.

- Platform: **S/4HANA 2023 On-Premise, Standard ABAP, OData V4**
- RAP object: **unmanaged, read-only, non-draft**
- **Standard SAP tables only — zero custom DDIC objects**
- Data-quality check framework **reused & extended from
  `HR_DataQuality_RAP_PoC`**
- Package: **`Z001`** — assign it in abapGit when you pull; this repo creates
  no package.

Design is fully documented under [`/docs`](docs) (01–13). Nothing here should be
activated before reading `docs/01_solution_architecture.md`.

---

## Repository layout

```
/docs   01..13  functional + technical design (approved before build)
/src            abapGit source (FOLDER_LOGIC = PREFIX, flat)
/ui/orgTree     reference files for the freestyle org-navigation section
```

## Pull with abapGit

1. Clone into your system, map the package to **`Z001`**, pull.
2. Activate in the order below (or right-click the package →
   *Activate All Inactive ABAP Development Objects* once everything exists).

### Activation order

| # | Objects |
|---|---|
| 1 | Message class `ZMSG_HR360` |
| 2 | `ZI_HR360_EMP_BASIC`, `ZI_HR360_EMP_CONTACT`, `ZI_HR360_EMP_BANK`, `ZI_HR360_EMP_PAY`, `ZI_HR360_HIREDATE`, `ZI_HR360_MANAGER`, `ZI_HR360_ORG_NODE` |
| 3 | `ZI_HR360_PERSONAL`, `ZI_HR360_ORGASSIGN`, `ZI_HR360_EDUCATION`, `ZI_HR360_QUALIF`, `ZI_HR360_LEAVE`, `ZI_HR360_ATTENDANCE`, `ZI_HR360_PAYROLL`, `ZI_HR360_DOCUMENT` |
| 4 | `ZI_HR360_ISSUE`, `ZI_HR360_TIMELINE` |
| 5 | `ZI_HR360_EMPLOYEE` (root), `ZI_HR360_ORG_HIER` (hierarchy) |
| 6 | DCL roles `ZI_HR360_*_DCL` |
| 7 | Behavior definitions `ZI_HR360_EMPLOYEE`, `ZI_HR360_TIMELINE`, `ZI_HR360_ISSUE`, `ZI_HR360_ORG_HIER` → behavior pools (see caveat below) |
| 8 | Projections `ZC_HR360_*`, then `ZC_HR360_KPI_OVERVIEW` |
| 9 | Projection behavior definitions `ZC_HR360_*` |
| 10 | Metadata extensions `ZC_HR360_*_MDE` |
| 11 | Service definition `ZHR360_UI_SRVD` |
| 12 | `ZIF_HR360_REPORT_ENGINE`, `ZCL_HR360_REPORT_ENGINE`, `ZCL_HR360_ORG_READER` |
| 13 | Reports `ZHR360_R_EMP_MASTER_EXPORT`, `ZHR360_R_MISSING_DATA`, `ZHR360_R_HR_AUDIT` |
| 14 | Test class `ZCL_HR360_ISSUE_TEST` (run ABAP Unit) |

### Behavior-pool caveat (important)

`ZBP_HR360_EMPLOYEE`, `ZBP_HR360_TIMELINE`, `ZBP_HR360_ISSUE` ship as abapGit
source, but the RAP handler **method signatures** (`FOR READ`,
`FOR READ … \_assoc`, `FOR INSTANCE AUTHORIZATION`) are tied to your kernel's
RAP runtime version. If ADT flags a signature mismatch on activation:

1. Activate the behavior definition.
2. On the behavior pool, use Quick Fix *"Add missing method implementations"*
   to regenerate the local handler class skeleton with correct signatures.
3. Paste the method **bodies** back from `*.clas.locals_imp.abap` (the SELECT
   logic is system-independent).

## Post-pull steps (not in the repo)

1. **SLG0** — create Application Log object `ZHR360`, subobject `REPORT`.
2. **Service binding** — create `ZHR360_UI_SRVB_O4` (OData V4 – UI) on
   `ZHR360_UI_SRVD`, activate, publish on the front-end server.
3. **Fiori** — in SAP Business Application Studio, generate:
   - a *List Report + Object Page* app on `Employee`
   - an *Analytical List Page* on `KpiOverview`
   Then add the `/ui/orgTree` custom section to the Object Page app.
4. **Authorizations** — business role `ZHR360_DISPLAY` = Fiori catalog +
   `P_ORGIN` (activity *Display*) + the OData V4 service authorization.
5. **ATC** — run with the Clean-ABAP + S/4HANA Readiness variants; release C1
   on the interfaces + service after the first clean run.

## Known items

See [`BUGS_AND_ISSUES.md`](BUGS_AND_ISSUES.md). Highlights:

- `ZI_HR360_TIMELINE` / `ZI_HR360_ISSUE` are `#NOT_REQUIRED` at interface level
  (row filtering is inherited / RBA-only) — add an explicit DCL before go-live.
- Skills vs Certifications split (`QualificationType`) defaults to all-`SKILL`
  until the client supplies certification qualification-group ids.
- Structural authorization (`P_ORGINCON`) is not implemented — go-live
  prerequisite for most HR deployments.
