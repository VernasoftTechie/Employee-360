# Requirement Specification — Employee Data Health Dashboard (Doc 14)

**Companion visual:** the published mockup "Employee Data Health".
**Backend:** complete — all entity sets below are live in `ZHR360_UI_SRVD`
(binding `ZHR360_UI_SRVB_O4`). This doc is the spec to build the **UI app** in
SAP Business Application Studio.

---

## 1. Purpose & users

A single screen for HR operations / data stewards to see **how complete and
correct employee master data is across the workforce**: how many employees need
attention, which fields break most often, and which parts of the organization
have the worst data — with one click into the affected employees.

| User | Uses it to |
|---|---|
| HR data steward | find and prioritise the biggest data gaps |
| HR operations lead | track data-health trend, report to management |
| HR admin | jump from a problem area to the exact employees to fix |

Read-only. Filtered by the viewer's `P_ORGIN` display authorization (DCL).

---

## 2. App type & shell

- **Fiori Elements Overview Page (OVP)**, OData V4.
- One app: **"Employee Data Health"** (`hr360.datahealth`).
- Deployed as a BSP app in package `ZHR_UTIL`, tile on the Fiori Launchpad,
  business role `ZHR360_DISPLAY`.
- Resizable card container; compact + cozy density.

---

## 3. Global filter bar

Drives every card. Entity type `KpiOverviewType`. Fields (all optional,
type-ahead + value help):

| Field | Element | Source |
|---|---|---|
| Company Code | `CompanyCode` | PA0001-BUKRS |
| Personnel Area | `PersonnelArea` | PA0001-WERKS |
| Employee Group | `EmployeeGroup` | PA0001-PERSG |
| Organizational Unit | `OrgUnit` | PA0001-ORGEH |
| Quality Status | `QualityStatus` | derived: OK / WARNING / CRITICAL |

`enableLiveFilter: true` — cards refresh on filter change.

---

## 4. Cards

### Card 1 — KPI: Employees needing attention  *(numeric card)*
- **Source:** `StatusSplit`, filtered `QualityStatus ne 'OK'` (or sum of
  CRITICAL + WARNING rows).
- **Value:** total `EmployeeCount`. **Subtitle:** "of {total} employees".
- **Criticality:** red.
- **Nav:** → Employee list filtered `QualityStatus ne 'OK'`.

### Card 2 — KPI: Fully clean  *(numeric card)*
- **Source:** `StatusSplit`, filtered `QualityStatus eq 'OK'`.
- **Value:** `EmployeeCount`. **Subtitle:** "{pct}% of the workforce".
- **Criticality:** green.
- **Nav:** → Employee list filtered `QualityStatus eq 'OK'`.

### Card 3 — KPI: Critical issues  *(numeric card)*
- **Source:** `KpiOverview` aggregated → sum `CriticalCount`.
- **Value:** total critical issues. **Subtitle:** "across {n} employees".
- **Criticality:** red.

### Card 4 — Chart: Workforce by data-quality status  *(donut / analytical card)*
- **Source:** `StatusSplit` · `@UI.Chart#S` (DONUT).
- **Dimension:** `QualityStatus` · **Measure:** `EmployeeCount`.
- **Colour:** by `StatusCriticality` (1 red / 2 orange / 3 green).
- **Nav:** click a slice → Employee list filtered by that status.

### Card 5 — Chart: Where the data breaks  *(column / analytical card)*
- **Source:** `CheckFailure` · `@UI.Chart#ByCheck` (COLUMN).
- **Dimension:** `CheckID` · **Measure:** `FailureCount` · sorted desc.
- **Tooltip / drill columns:** `Category`, `Severity`, `IssueDescription`.
- **Nav:** click a bar → `DataQualityIssue` list filtered `CheckID eq …`.
- **Purpose:** identifies the 2-3 checks that, if fixed, move the completeness
  number the most.

### Card 6 — Chart: Completeness by organization  *(bar / analytical card)*
- **Source:** `AreaHealth` · `@UI.Chart#A` (BAR).
- **Dimension:** `PersonnelArea` · **Measure:** `AvgCompleteness` · sorted asc
  (worst first).
- Also expose `CriticalCount`, `EmployeeCount` as drill columns.
- **Nav:** click a bar → Employee list filtered `PersonnelArea eq …`.

### Card 7 — Table: KPI detail  *(table card)*
- **Source:** `KpiOverview` · `@UI.LineItem`.
- Columns: Company Code, Personnel Area, Employee Group, Org Unit,
  Quality Status, Employees, With Issues, Missing Data Count, Critical Count,
  Warning Count, Avg Completeness.
- **Nav:** row → Employee list filtered by that row's dimension combination.

### Card 8 — Trend  *(line card — PHASE 2, needs a snapshot table)*
- Weekly "fully clean %" over the last N snapshots.
- Requires a small custom history table + a scheduled report writing one row
  per week (`ZHR360_R_HR_AUDIT` computes the number). Out of scope for v1.

---

## 5. Entity sets (already built — reference)

| Entity set | CDS view | Grain | Key fields | Measures |
|---|---|---|---|---|
| `StatusSplit` | `ZC_HR360_DQ_BY_STATUS` | per status | `QualityStatus` | `EmployeeCount`, `StatusCriticality` |
| `CheckFailure` | `ZC_HR360_DQ_BYCHECK` | per check | `CheckID`, `Category`, `Severity` | `FailureCount`, `SeverityCriticality` |
| `AreaHealth` | `ZC_HR360_DQ_BY_AREA` | per company / pers.area | `CompanyCode`, `PersonnelArea` | `EmployeeCount`, `CriticalCount`, `AvgCompleteness` |
| `KpiOverview` | `ZC_HR360_KPI_OVERVIEW` | company / area / EE group / org unit / status | 5 dimensions | `EmployeeCount`, `EmployeesWithIssues`, `MissingDataCount`, `CriticalCount`, `WarningCount`, `AvgCompleteness` |
| `DataQualityIssue` | `ZC_HR360_ISSUE` | per (employee, failed check) | `EmployeeID`, `CheckID` | — |
| `Employee` | `ZC_HR360_EMPLOYEE` | per employee | `EmployeeID` | issue counts, `CompletenessPercent`, `QualityStatus` |

All carry `@UI.Chart` / `@UI.PresentationVariant` / `@UI.LineItem` where noted,
so a chart/table control configures itself from the annotation.

---

## 6. KPI definitions (authoritative)

| KPI | Formula | Element |
|---|---|---|
| Total employees | `count(*)` of active employees (date-valid PA0001 + PA0002) | `EmployeeCount` |
| Employees with issues | employees with `TotalIssueCount > 0` | `EmployeesWithIssues` |
| Critical employees | employees with `CriticalIssueCount > 0` (`QualityStatus = 'CRITICAL'`) | `StatusSplit` row |
| Fully clean | employees with `TotalIssueCount = 0` (`QualityStatus = 'OK'`) | `StatusSplit` row |
| Missing data count | Σ `TotalIssueCount` (total failed checks) | `MissingDataCount` |
| Failure count (per check) | employees failing that specific `CheckID` | `FailureCount` |
| Completeness % (per employee) | `(12 - TotalIssueCount) / 12 * 100` | `CompletenessPercent` |
| Avg completeness (per group) | `Σ(12 - TotalIssueCount) * 100 / (employees * 12)` — weighted | `AvgCompleteness` |

`12` = number of active checks in `ZI_HR360_ISSUE`. Change both places if the
check set changes.

---

## 7. Navigation

Every card and table row navigates via **intent-based navigation** to the
**Employee 360** app's List Report (semantic object/action e.g.
`Employee-display`), passing the relevant filter(s):

| From | Passes |
|---|---|
| Status donut slice / KPI cards 1-2 | `QualityStatus` |
| By-check bar | `CheckID` (to the `DataQualityIssue` list) |
| By-area bar | `PersonnelArea` |
| KPI detail row | `CompanyCode` + `PersonnelArea` + `EmployeeGroup` + `OrgUnit` + `QualityStatus` |

No hard-coded URLs — `CrossApplicationNavigation`.

---

## 8. Build steps (BAS)

1. `ui/dashboard/webapp/manifest.json` in this repo is the **starter** — 4 cards
   (status donut, by-check column, by-area bar, KPI detail table).
2. BAS → *New Project from Template* → *SAP Fiori* → **Overview Page** →
   connect to the system → service `ZHR360_UI_SRVD` → main entity `KpiOverview`.
3. Merge the repo manifest's `sap.ovp.cards` into the generated one; add the
   3 KPI numeric cards (§4 cards 1-3) via *Page Map → Add Card → KPI*.
4. Set the global filter (`KpiOverviewType`, fields in §3).
5. Configure card navigation (§7) to the Employee 360 app's intent.
6. *Deploy to ABAP* → package `ZHR_UTIL`, transport → creates BSP app + FLP
   content.
7. Repeat for the **Employee 360** app (*List Report Object Page* template,
   entity `Employee` — annotations already complete).
8. Launchpad: catalog + group `ZHR360`, 2 tiles, role `ZHR360_DISPLAY`
   (= catalog + `P_ORGIN` activity Display + `S_SERVICE` for the OData V4 service).

---

## 9. Non-functional

- **Performance:** `KpiOverview` aggregates `EMP_BASIC ⋈ EMP_KPI` (EMP_KPI groups
  the 12-branch `ISSUE` union once per employee). Filtered by the global filter
  bar it is fine; unfiltered on 40k employees it is a few seconds — acceptable
  for a dashboard, cache in the FLP if needed.
- **Authorization:** DCL (`P_ORGIN`, Display) filters every entity set; a user
  with the tile but no HR auth sees an empty dashboard, not an error.
- **No writes**, no draft, no actions.
- **Refresh:** live from PA infotypes; no materialisation (except the optional
  Phase-2 trend snapshot).

---

## 10. Phase 2 (not in v1)

- Trend line (weekly snapshot table + scheduled job).
- "Assign to me / mark reviewed" workflow on an issue (would need a RAP BO +
  a small custom table).
- Per-country check profiles (IBAN mandatory only where relevant) — a
  customizing table + parameterised `ZI_HR360_ISSUE`.
- Export the scorecard to PDF per org unit.
