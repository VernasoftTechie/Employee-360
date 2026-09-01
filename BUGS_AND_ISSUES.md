# Employee-360 — Bugs & Issues Log

**Last updated:** 2026-09-01

## Issue template

### Issue #NNN: [title]
- **Date:** YYYY-MM-DD
- **Component:** DDIC / CDS / Behavior / DCL / Service / UI / Report
- **Severity:** Critical / High / Medium / Low
- **Status:** Open / In Progress / Resolved / Closed
- **Description / Root cause / Resolution / Test / Lesson**

---

## Open items carried from the design (to close before go-live)

### Issue #001: Explicit DCL for `ZI_HR360_TIMELINE` and `ZI_HR360_ISSUE`
- **Component:** DCL
- **Severity:** High
- **Status:** Open
- **Description:** Both are UNION view entities and cannot carry the P_ORGIN
  org fields directly, so they ship with `@AccessControl.authorizationCheck:
  #NOT_REQUIRED`. Row filtering is currently inherited — `ZI_HR360_ISSUE`
  selects from the checked `ZI_HR360_EMP_BASIC` in every branch;
  `ZI_HR360_TIMELINE` is exposed to the UI only via read-by-association from
  the checked root and its projection `ZC_HR360_TIMELINE` is `#CHECK`.
- **Resolution (planned):** add an association to `ZI_HR360_EMP_BASIC` on each
  and switch to `#CHECK` with `inheriting conditions from entity
  ZI_HR360_EMP_BASIC`; verify a direct `/TimelineEvent` query is filtered.

### Issue #002: Skills vs Certifications split
- **Component:** CDS (`ZI_HR360_QUALIF`)
- **Severity:** Medium
- **Status:** Open
- **Description:** `QualificationType` is hard-coded to `'SKILL'`; the
  Certifications facet will be empty until the client supplies the
  qualification-group ids that represent certifications.
- **Resolution (planned):** replace the literal with `CASE … WHEN
  GrpRel.sobid IN ( '<id>', … ) THEN 'CERT' ELSE 'SKILL' END`.

### Issue #003: Structural authorization not implemented
- **Component:** Behavior / DCL
- **Severity:** High (go-live prerequisite)
- **Status:** Open
- **Description:** Only `P_ORGIN` (context-free) is enforced. Most productive
  HR deployments also require structural authorization (`P_ORGINCON` /
  profile-based `HRBAS00_STRUAUTH`).
- **Resolution (planned):** replace the `AUTHORITY-CHECK` in
  `ZBP_HR360_EMPLOYEE→get_instance_authorizations` with a call to the
  client's structural-auth helper; isolated to that one method.

### Issue #004: `ZI_HR360_MANAGER` single-level only
- **Component:** CDS
- **Severity:** Low
- **Status:** Open
- **Description:** The pure-CDS manager view resolves position → A002 superior
  position → A008 holder. Clients with a different chief-position model, or
  multi-path reporting lines, need `ZCL_HR360_ORG_READER` semantics folded in.
- **Resolution (planned):** confirm the client's chief-position relationship
  and adjust the `HRP1001` filter, or expose a table-function backed by
  `ZCL_HR360_ORG_READER`.

### Issue #005: `HireDate` action set
- **Component:** CDS (`ZI_HR360_HIREDATE`)
- **Severity:** Low
- **Status:** Open
- **Description:** Hiring actions are hard-coded to `MASSN IN ( '01' )`.
- **Resolution (planned):** extend the `IN` list per the client's T529A
  customizing.

### Issue #006: Behavior-pool signature regeneration
- **Component:** Behavior
- **Severity:** Medium (one-time, on pull)
- **Status:** Open
- **Description:** RAP handler signatures may not match the target kernel byte
  for byte (see README). Method bodies are system-independent.
- **Resolution:** documented Quick-Fix regeneration step in the README.

---

## Debugging checklist

- [ ] `ZMSG_HR360` activated?
- [ ] All `ZI_HR360_*` views active? (`Activate All Inactive` on the package)
- [ ] DCL roles active and assigned in the PFCG role?
- [ ] Behavior pools regenerated (signature step) and active?
- [ ] Service definition + binding active and published on the FES?
- [ ] Test employee has valid PA0001/PA0002 slices on the key date?
- [ ] `P_ORGIN` display authorization present for the test user?
- [ ] SLG1 under object `ZHR360` for report run logs.

## #007 - Metadata extensions deferred

The 12 `ZC_HR360_*_MDE` metadata extensions were removed in v0.8: the abapGit
DDLX metadata files failed to import ("description is missing"), which poisoned
the whole "Activate All Inactive" run. UI annotations will be re-added directly
in SAP Business Application Studio when the Fiori app is generated (or as
hand-written `.ddlx` created in ADT). The projections keep
`@Metadata.allowExtensions: true` so nothing else changes.
