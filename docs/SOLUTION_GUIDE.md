# Employee-360 — Solution Guide (what it is, how it works)

Plain-language walkthrough of the running app. Companion to the design docs
(01–13) and `BUILD_ISSUES_LOG.md`.

---

## 1. There are only two "pages" — the rest are sections

The app is a **Fiori Elements** app generated automatically from the CDS
annotations. Fiori Elements has exactly two page templates and you are seeing
both:

### 1a. List Report (the first screen)

- **Filter bar** — one field per `@UI.selectionField` in `ZC_HR360_EMPLOYEE`
  (Company Code, Personnel area, Employee group, Org unit, QualityStatus) + a
  free-text Search box (`@Search.searchable`).
- **Results table** — `Employees (30,532)` — one column per `@UI.lineItem`.
  The extra lines under each row (`TotalIssueCount`, `QualityStatus`,
  `CompletenessPercent`…) are just more `@UI.lineItem` fields; the responsive
  table stacks them when the window is narrow.
- **Data source:** `ZHR360_UI_SRVD` → entity set `Employee` →
  `ZC_HR360_EMPLOYEE` → `ZI_HR360_EMPLOYEE` → standard PA tables. **Live data —
  nothing to maintain.**

### 1b. Object Page (when you click a row)

- **Header** — `FormattedName` as title, `EmployeeID` as subtitle
  (`@UI.headerInfo`).
- **Tabs / sections** — one per `@UI.facet` entry: Education, Skills & Certs,
  Leave & Quotas, Attendance, Pay History, Documents, Timeline, Data Quality.
  Each tab is a table bound to one association (`_Education`, `_Qualification`, …)
  that filters the corresponding entity set by this employee's `EmployeeID`.

So "so many pages" = **one List Report + one Object Page**; the tabs are
sections inside the Object Page.

---

## 2. What is an "app" here, and how is it maintained

| Layer | What it is | Where you change it |
|---|---|---|
| Data | Standard SAP HCM infotypes (PA0000/0001/0002/0006/0008/0009/0022/0024/0105, PA2001/2002/2006, HRP*, TOA01) | maintained in PA30 etc. — the app only reads |
| Semantics | CDS views `ZI_HR360_*` (raw reads) → `ZC_HR360_*` (query views for the UI) | edit the `.ddls` sources in the repo |
| Screen layout | `@UI.*` annotations (columns, filters, sections, colours) — currently **inline** in the `ZC_HR360_*` views | edit the annotations; the plan (Rulebook §2) is to move them to **Metadata Extensions** so the view and the layout are separated |
| Service | `ZHR360_UI_SRVD` (which views are exposed) + `ZHR360_UI_SRVB_O4` (OData V4 binding) | edit the service definition |
| The actual app | Right now this is the **ADT "Preview"** — an on-the-fly Fiori Elements app. It is **not** a Launchpad tile yet. | For production: generate a Fiori Elements app in **SAP Business Application Studio** against the service, or use the Launchpad "Manage" flow, and assign it to a catalog/role |

Nothing in the app needs periodic "maintenance" — it is a live window on HR
data. You only touch it to change *what* is shown (annotations) or *which*
data (CDS).

---

## 3. Why clicking a row inside a detail tab shows a blank page

The detail entities (`Data Quality Issue`, `Education`, …) are exposed as
**list tables only** — they have columns (`@UI.lineItem`) but no Object Page of
their own. Fiori Elements still renders a chevron `>` on each row and tries to
navigate to a sub-page that does not exist → blank screen (`VUYHJGU /`).

This is cosmetic — every field is already visible in the row. Fix (next
increment): either suppress the row navigation, or give the useful ones (e.g.
Education) a small sub-detail page. It does not affect the data.

---

## 4. How **Data Quality** and **Completeness %** are calculated

### 4a. The 12 checks — `ZI_HR360_ISSUE`

`ZI_HR360_ISSUE` is a `UNION ALL` of **12 SELECTs**. Each SELECT is **one
data-quality rule**. Every rule scans all active employees and returns a row
**only for the employees that fail that rule**.

| # | CheckID | Severity | An employee fails it when… |
|---|---|---|---|
| 1 | `MAND_DOB` | Critical | date of birth is blank (PA0002-GBDAT) |
| 2 | `MAND_GENDER` | Critical | gender is blank |
| 3 | `STAT_NATION` | Critical | nationality is blank |
| 4 | `ORG_COSTCTR` | Critical | cost center is blank (PA0001-KOSTL) |
| 5 | `ORG_POSITION` | Critical | position is not assigned (PA0001-PLANS) |
| 6 | `PAY_BASICPAY` | Warning | no valid basic-pay record (PA0008) |
| 7 | `CONTACT_MAIL` | Warning | no e-mail (PA0105 subty 0010) |
| 8 | `BANK_IBAN` | Critical | IBAN / bank details missing (PA0009) |
| 9 | `EDU_MISSING` | Warning | no education record (PA0022) |
| 10 | `QUAL_MISSING` | Warning | no qualification / skill (PA0024) |
| 11 | `CONTACT_ADDR` | Warning | no address country (PA0006) |
| 12 | `INVALID_DOB` | Critical | date of birth is in the future |

So for **employee 1 (JGU)** the DQ tab shows exactly one row:
`ORG_COSTCTR / ORG_ASSIGNMENT / Critical / "Cost center is missing" / CostCenter`
→ this employee has no cost center on PA0001.

### 4b. Per-employee counts — `ZI_HR360_EMP_KPI`

Groups `ZI_HR360_ISSUE` by employee:

```
TotalIssueCount    = COUNT( DISTINCT CheckID )                       -- failed checks
CriticalIssueCount = number of failed checks with Severity = 'C'
WarningIssueCount  = number of failed checks with Severity = 'W'
```

### 4c. Status + completeness — `ZI_HR360_EMPLOYEE` (root)

```
QualityStatus =
    'CRITICAL'  if CriticalIssueCount > 0
    'WARNING'   else if TotalIssueCount > 0
    'OK'        else

QualityStatusCriticality = 1 (red) / 2 (orange) / 3 (green)   -- drives the colour

CompletenessPercent = ( 12 − TotalIssueCount ) / 12 × 100      -- rounded to 1 decimal
```

`12` = the number of active checks. If you add or remove a `UNION` branch in
`ZI_HR360_ISSUE`, update that number in `ZI_HR360_EMPLOYEE` (it is flagged in a
comment there).

**Worked example — employee 1 (JGU):**
- Fails 1 check (`ORG_COSTCTR`, Critical)
- `TotalIssueCount` = 1, `CriticalIssueCount` = 1
- `QualityStatus` = CRITICAL (has a critical issue) → red icon
- `CompletenessPercent` = (12 − 1) / 12 × 100 = **91.7 %** ← matches the screen

### 4d. HR-wide roll-up — `ZC_HR360_KPI_OVERVIEW`

Aggregates the per-employee numbers by Company Code / Personnel Area /
Employee Group / Org Unit / QualityStatus:
`TotalEmployees`, `EmployeesWithIssues`, `EmployeesWithoutIssues`,
`MissingDataCount` (Σ TotalIssueCount), `CriticalIssueCount`,
`WarningIssueCount`, `AvgCompletenessPercent`.

### 4e. Adding / changing a check

1. Copy one `UNION ALL` branch in `ZI_HR360_ISSUE`, change the `CheckID` /
   `Category` / `Severity` / description / predicate.
2. Update the `12` constant in `ZI_HR360_EMPLOYEE.CompletenessPercent`.
3. Activate. Nothing else changes — the counts, status, colour and roll-up
   pick it up automatically.

The 3 executable reports (`ZHR360_R_MISSING_DATA`, `ZHR360_R_HR_AUDIT`,
`ZHR360_R_EMP_MASTER_EXPORT`) read the same views, so they stay in sync too.
