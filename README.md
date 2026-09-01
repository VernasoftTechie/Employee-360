# Employee-360

**HR Employee 360** — a read-only SAP application over standard SAP HCM data:
an employee profile query service plus an HR data-quality / audit reporting layer.

- Platform: **S/4HANA On-Premise, Standard ABAP, OData V4**
- **Standard SAP tables only — zero custom DDIC objects**
- Data-quality check framework reused from `HR_DataQuality_RAP_PoC`
- Package: **`ZHR_UTIL`** — every `/src` object belongs to this one package.
  Link the repo to `ZHR_UTIL` in the abapGit repo settings on first pull.

> **Build status:** first green build (v0.15+). See `docs/BUILD_ISSUES_LOG.md`
> for the full activation-error trail and the current scope. The Fiori app is a
> read-only OData V4 service (no RAP BO wrapper yet); child facets, UI metadata
> extensions, org hierarchy and text columns are staged for later increments.

---

## Repository layout

```
/src               abapGit source — ONLY the active, wired objects (FOLDER_LOGIC = PREFIX, flat)
/staging           work-in-progress objects NOT yet wired in — abapGit ignores this folder
/docs              functional + technical design + BUILD_ISSUES_LOG.md
```

## What's in `/src` (the green build)

| Area | Objects |
|---|---|
| Interface CDS | `ZI_HR360_EMP_BASIC`, `_EMP_CONTACT`, `_EMP_BANK`, `_EMP_PAY`, `_PERSONAL`, `_HIREDATE`, `_EMP_KPI`, `_ISSUE` (12-check framework), `_EMPLOYEE` (root, flat) |
| Query views | `ZC_HR360_EMPLOYEE`, `ZC_HR360_ISSUE`, `ZC_HR360_KPI_OVERVIEW` (all read-only, inline `@UI`) |
| DCL | `ZI_HR360_EMP_BASIC_DCL`, `ZI_HR360_EMPLOYEE_DCL` (`P_ORGIN`, activity Display) |
| Service | `ZHR360_UI_SRVD` + `ZHR360_UI_SRVB_O4` (OData V4 – UI, **shipped in the repo** so a re-pull keeps it) |
| Classes | `ZIF_HR360_REPORT_ENGINE`, `ZCL_HR360_REPORT_ENGINE`, `ZCL_HR360_ISSUE_TEST` |
| Reports | `ZHR360_R_EMP_MASTER_EXPORT`, `ZHR360_R_MISSING_DATA`, `ZHR360_R_HR_AUDIT` |
| Messages | `ZMSG_HR360` |

## Pull & activate

1. Link the repo to package **`ZHR_UTIL`**, pull.
2. Right-click the package → **Activate All Inactive ABAP Development Objects**
   (run twice if the first pass leaves cross-references inactive).
3. The service binding `ZHR360_UI_SRVB_O4` is in the repo — after pull it should
   be present and published. If it shows inactive, activate it.
4. Preview: open `ZHR360_UI_SRVB_O4` → select `Employee` → **Preview**.

## Post-pull (not in the repo)

- **SLG0** — create Application Log object `ZHR360`, subobject `REPORT`
  (used by the executable reports; they run without it, just no log).
- **Authorization** — a role with `P_ORGIN` (activity *Display* = `R`) is
  required to see any employee rows (enforced by DCL).

## `/staging` — next increments

`orgassign`, `education`, `qualif`, `leave`, `attendance`, `payroll`, `document`,
`timeline` interface views are parked here (dates already cast, texts stripped).
They get moved into `/src` and wired one at a time — see `docs/BUILD_ISSUES_LOG.md`
§E and the "next increments" list in `docs/12_version_history.md`.

## Known items

`docs/BUILD_ISSUES_LOG.md` A1–A26 — every error hit during activation, its cause
and fix. Read it before changing CDS/RAP objects.
