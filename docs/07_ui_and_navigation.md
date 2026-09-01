# Employee-360 — UI & Navigation (Doc 07)

**Status:** DRAFT — awaiting approval (batch a).

UI annotations live in **Metadata Extensions** (`ZC_HR360_*_MDE`), never in the
CDS views (Rulebook §2). `@Metadata.allowExtensions: true` on every projection.

---

## 1. Applications

| # | App | Type | Service entity | Purpose |
|---|---|---|---|---|
| 1 | **Employee 360** | Fiori Elements — List Report + Object Page | `Employee` | search employees → full 360 profile |
| 2 | **HR Data Quality Audit** | Fiori Elements — Analytical List Page (or Overview Page) | `KpiOverview` | HR-wide completeness / issue KPIs with drill-down |
| 3 | *(embedded, not a separate app)* Org Navigation | Freestyle SAPUI5 view inside app 1's Object Page | `OrgNode` | reports-to / org tree |

Both FE apps are generated from the service; only app 3 is hand-written UI5
(one `.view.xml` + one controller, ~120 lines) — see §5.

---

## 2. App 1 — List Report (`ZC_HR360_EMPLOYEE_MDE`)

### 2.1 Selection fields (filter bar)

`CompanyCode`, `PersonnelArea`, `EmployeeGroup`, `OrgUnit`, `EmploymentStatus`,
`QualityStatus` — all `@UI.selectionField`.

### 2.2 Smart search

```
@Search.searchable: true                       // on the view (Doc 04 §7)
@UI.headerInfo: { typeName: 'Employee', typeNamePlural: 'Employees',
                  title: { value: 'FormattedName' }, description: { value: 'EmployeeID' } }
```
`$search` box active — fuzzy over `LastName`, `FirstName`, `OrgUnit`
(`@Search.defaultSearchElement` in the view).

### 2.3 Line items (result table)

| pos | field | note |
|---|---|---|
| 10 | EmployeeID | |
| 20 | FormattedName | |
| 30 | OrgUnitName | |
| 40 | PositionName *(from _OrgAssignment)* | via `@UI.lineItem` on the assoc field or a text element on the root |
| 50 | CompanyCode | |
| 60 | EmploymentStatus | |
| 70 | TotalIssueCount | |
| 80 | QualityStatus | `criticality: 'QualityStatusCriticality'` |
| 90 | CompletenessPercent | `@UI.dataPoint` progress, target 100 |

```
@UI.lineItem: [{ position: 80, criticality: 'QualityStatusCriticality',
                 type: #STANDARD }]
QualityStatus;
```

---

## 3. App 1 — Object Page (`ZC_HR360_EMPLOYEE_MDE` facets)

### 3.1 Header

- Title `FormattedName`, subtitle `EmployeeID`.
- Header facets (`@UI.headerFacet`):
  - `#DATAPOINT` — `CompletenessPercent` (progress indicator, criticality from
    `QualityStatusCriticality`).
  - `#DATAPOINT` — `TotalIssueCount` (with `CriticalIssueCount` as secondary).
  - `#IDENTIFICATION` mini — `OrgUnitName`, `PositionName`, `ManagerName`.

### 3.2 Section facets (`@UI.facet` on the root MDE)

| pos | id | type | target | label |
|---|---|---|---|---|
| 10 | Personal | `#IDENTIFICATION_REFERENCE` | `_Personal` | Personal Details |
| 20 | Org | `#IDENTIFICATION_REFERENCE` | `_OrgAssignment` | Organization & Position |
| 30 | OrgTree | `#REFERENCE` (custom section) | — | Org Navigation *(§5)* |
| 40 | Education | `#LINEITEM_REFERENCE` | `_Education` | Education |
| 50 | Skills | `#LINEITEM_REFERENCE` | `_Qualification` (filtered `QualificationType='SKILL'`) | Skills |
| 60 | Certifications | `#LINEITEM_REFERENCE` | `_Qualification` (filtered `='CERT'`) | Certifications |
| 70 | Leave | `#LINEITEM_REFERENCE` | `_LeaveBalance` | Leave & Quotas |
| 80 | Attendance | `#LINEITEM_REFERENCE` | `_Attendance` | Attendance |
| 90 | Payroll | `#LINEITEM_REFERENCE` | `_Payroll` | Pay History |
| 100 | Documents | `#LINEITEM_REFERENCE` | `_Document` | Documents |
| 110 | Timeline | `#REFERENCE` (custom, `sap.suite…Timeline`) or `#LINEITEM_REFERENCE` | `_Timeline` | Timeline |
| 120 | DataQuality | `#LINEITEM_REFERENCE` | `_DataQuality` | Data Quality Issues |

> Skills vs Certifications: two facets both pointing at `_Qualification` with an
> `@UI.facet.targetQualifier` + a `@UI.presentationVariant` filtering on
> `QualificationType`. If FE filtered-facet support on the target UI5 version is
> weak, fall back to a single "Qualifications" facet with `QualificationType` as
> the first column.

### 3.3 Child MDE example — `ZC_HR360_ISSUE_MDE` (kept from PoC)

```
@Metadata.layer: #CORE
@UI: { headerInfo: { typeName: 'Issue', typeNamePlural: 'Issues' } }
annotate entity ZC_HR360_ISSUE with {
  @UI.lineItem: [{ position: 10 }] Category;
  @UI.lineItem: [{ position: 20, criticality: 'SeverityCriticality' }] Severity;
  @UI.lineItem: [{ position: 30 }] IssueDescription;
  @UI.lineItem: [{ position: 40 }] FieldName;
}
```

### 3.4 Documents facet — link to content server

`ZC_HR360_DOCUMENT_MDE`: `Title`, `DocumentType`+text, `ArchiveDate` as line
items; a `@UI.lineItem` of `type: #WITH_URL` (or a field with
`@Semantics.url.mimeType`) building the ArchiveLink content URL from
`ArchiveID` + `ArchivDocID`. Opening = new browser tab to the content server; no
content proxied through the app.

### 3.5 Timeline facet

Preferred: custom section hosting `sap.suite.ui.commons.Timeline` bound to
`_Timeline` (sorted `EventDate desc`), grouping by year. Fallback: plain
`@UI.lineItem` table on `_Timeline` with a default `@UI.presentationVariant`
`sortOrder` on `EventDate desc`.

---

## 4. App 2 — HR Data Quality Audit (`ZC_HR360_KPI_OVERVIEW_MDE`)

- Analytical List Page (chart + table) or Overview Page (KPI cards). **Default:
  ALP** (single focused analytical app; OVP is heavier to configure).
- Chart: stacked column `EmployeesWithIssues` / `EmployeesWithoutIssues` by
  `OrgUnitName`; KPI header: `AvgCompletenessPercent`, `CriticalIssueCount`,
  `MissingDataCount`.
- Filter bar: `CompanyCode`, `PersonnelArea`, `EmployeeGroup`, `OrgUnit`,
  `QualityStatus`.
- Table drill-down rows navigate (intent-based) to **app 1** filtered by the
  drill context (`OrgUnit`, `QualityStatus`) — §7.

---

## 5. Org Navigation — freestyle UI5 section (**CONFIRM 11.2 default: included**)

- One custom section in app 1's Object Page (Fiori Elements *custom section*
  extension point), containing a `sap.ui.table.TreeTable`.
- Binds `OrgNode` with OData V4 hierarchy (`$$aggregation` / hierarchy
  annotations from `define hierarchy`), root = viewed employee's `OrgUnit`.
- Columns: Node (icon by `NodeType`), `NodeText`, `HeadcountUnder`.
- Row action on a `NodeType = 'P'` (person) node → intent navigation to that
  employee's Object Page (`#Employee-display?EmployeeID=...`).
- Files: `webapp/ext/orgTree/OrgTree.fragment.xml`,
  `webapp/ext/orgTree/OrgTree.controller.js`, manifest `extends` entry.
- If **CONFIRM 11.2** comes back "pure Fiori Elements only": drop this section;
  Org Navigation degrades to two plain facets — `_Manager` (single) and
  `_DirectReport` (`#LINEITEM_REFERENCE`) — both already in the model.

---

## 6. Launchpad

| Tile | Target | Semantic object-action |
|---|---|---|
| Employee 360 | app 1 List Report | `Employee-display` |
| HR Data Quality Audit | app 2 ALP | `EmployeeDataQuality-analyze` |

Both in one Fiori catalog + group `ZHR360`; role `ZHR360_DISPLAY` (business
role) bundles catalog + `P_ORGIN` display + OData service auth.

---

## 7. Cross-app navigation map

```
Launchpad
  ├─► Employee 360 (LR) ──select──► Employee 360 (OP)
  │        ▲                            │
  │        │ (filtered by OrgUnit /     ├─ Org Tree section ──person node──► Employee 360 (OP)
  │        │  QualityStatus)            └─ Data Quality facet
  │        │
  └─► HR Data Quality Audit (ALP) ──drill-down row──┘
```

All navigation is standard Fiori intent-based (`CrossApplicationNavigation`);
no hard-coded URLs. Parameters passed: `EmployeeID`, or `OrgUnit` +
`QualityStatus` for the filtered LR entry.

---

## 8. Metadata Extension inventory

`ZC_HR360_EMPLOYEE_MDE` (header, facets, line items, selection, datapoints),
`ZC_HR360_PERSONAL_MDE`, `ZC_HR360_ORGASSIGN_MDE`, `ZC_HR360_EDUCATION_MDE`,
`ZC_HR360_QUALIF_MDE`, `ZC_HR360_LEAVE_MDE`, `ZC_HR360_ATTENDANCE_MDE`,
`ZC_HR360_PAYROLL_MDE`, `ZC_HR360_DOCUMENT_MDE`, `ZC_HR360_TIMELINE_MDE`,
`ZC_HR360_ISSUE_MDE`, `ZC_HR360_KPI_OVERVIEW_MDE`. `@Metadata.layer: #CORE`.

---

## 9. Accessibility / i18n

- All labels from `@EndUserText.label` / data element labels → translatable.
- Criticality always paired with an icon/text, never colour-only (WCAG).
- Numbers (`CompletenessPercent`, counts) formatted by UI5 locale.

**Approve to proceed — Doc 08 (Executable Reports) follows in this batch.**
