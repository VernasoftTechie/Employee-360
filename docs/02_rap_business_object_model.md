# Employee-360 — RAP Business Object Model (Doc 02)

**Status:** DRAFT — awaiting approval. Depends on approved `01_solution_architecture.md` (rev 2).
No ABAP until docs 02–08 are approved (Rulebook §7/§8).

---

## 1. Object Type

| Property | Value | Why |
|---|---|---|
| Implementation type | **Unmanaged** | Root is not 1:1 with a table (joins PA0001+PA0002, computed KPI columns); no custom persistence to "manage" |
| Transactional behavior | **Read-only** | No CREATE / UPDATE / DELETE on any entity; no actions in Phase 1 |
| Draft | **No** | Nothing is edited |
| Strictness | `strict ( 2 )` | Current RAP strict mode, matches the PoC |
| Concurrency / ETag | none | read-only |
| Number ranges | none | no created data |

**As built (v0.3):** the 8 employee-detail entities (Personal, OrgAssignment,
Education, Qualification, LeaveBalance, Attendance, PayrollItem, Document) are
modelled as **read-only compositions** of the root, so the whole tree lives in
one behavior definition (`ZI_HR360_EMPLOYEE`) and one behavior pool
(`ZBP_HR360_EMPLOYEE`). The two derived UNION views (`ZI_HR360_TIMELINE`,
`ZI_HR360_ISSUE`) stay association-linked with their own small BDEF + pool — the
`HR_DataQuality_RAP_PoC` `association _Issue { }` pattern. `_Manager` /
`_DirectReport` are self-associations on the root. See Doc 10 §2.4 / §2.5 for the
final object list.

---

## 2. Entities

### 2.1 Composition tree (one BO, root = `ZI_HR360_EMPLOYEE`)

| # | Interface entity | Alias | Card. (from root) | Key | Primary source |
|---|---|---|---|---|---|
| 0 | `ZI_HR360_EMPLOYEE` | `Employee` | root, 1 row / active employee | `EmployeeID` | PA0001 ⋈ PA0002 (+ texts) |
| 1 | `ZI_HR360_PERSONAL` | `Personal` | 1:1 | `EmployeeID` | PA0002 / PA0006 / PA0105 / PA0009 / PA0000 |
| 2 | `ZI_HR360_ORGASSIGN` | `OrgAssignment` | 1:1 | `EmployeeID` | PA0001 + T500P/T501T/T503T/T527X + HRP1000 |
| 3 | `ZI_HR360_EDUCATION` | `Education` | 1:n | `EmployeeID, EducationSeqNr` | PA0022 (+ T517T/T517X/TB039) |
| 4 | `ZI_HR360_QUALIF` | `Qualification` | 1:n | `EmployeeID, QualificationID, ValidFrom` | PA0024 (+ HRP1000 catalog) |
| 5 | `ZI_HR360_LEAVE` | `LeaveBalance` | 1:n | `EmployeeID, QuotaType, DeductionFrom` | PA2006 (+ PA2001, T556B/T556) |
| 6 | `ZI_HR360_ATTENDANCE` | `Attendance` | 1:n | `EmployeeID, AttendanceFrom, AttendanceType` | PA2002 (+ T554T) |
| 7 | `ZI_HR360_PAYROLL` | `PayrollItem` | 1:n | `EmployeeID, ValidFrom, WageType` | PA0008 (+ T512T) |
| 8 | `ZI_HR360_DOCUMENT` | `Document` | 1:n | `EmployeeID, ArchivDocID` | TOA01/TOAAT (+ TOASP) |
| 9 | `ZI_HR360_TIMELINE` | `TimelineEvent` | 1:n (derived) | `EmployeeID, EventDate, EventCategory, EventSeqNr` | union over PA0000/0001/0008/0022/0024/2001 |
| 10 | `ZI_HR360_ISSUE` | `DataQualityIssue` | 1:n (derived) | `EmployeeID, CheckID` | `ZI_HR360_EMP_BASIC` ⋈ domain views |

All child keys carry `EmployeeID` as the first component. Time-dependent
infotypes are filtered to the reporting key date (`$session.system_date`) in the
interface views (`begda <= @date AND endda >= @date`), except history-style
children (`Education`, `Qualification`, `PayrollItem`, `TimelineEvent`) which
deliberately return **all** time slices.

### 2.2 Supporting interface views (not BO entities — building blocks, from the PoC)

| View | Renamed from | Role |
|---|---|---|
| `ZI_HR360_EMP_BASIC` | `ZI_HRDQ_EMP_BASIC` | one row / active employee — anchor for root + issue framework |
| `ZI_HR360_EMP_CONTACT` | `ZI_HRDQ_EMP_CONTACT` | email / mobile / address |
| `ZI_HR360_EMP_BANK` | `ZI_HRDQ_EMP_BANK` | bank / IBAN |
| `ZI_HR360_EMP_PAY` | `ZI_HRDQ_EMP_PAY` | basic-pay presence + pay-scale |

### 2.3 Standalone entities (exposed in the same service, outside the composition tree)

| Entity | Type | Key | Purpose |
|---|---|---|---|
| `ZI_HR360_ORG_HIER` | CDS **hierarchy** (`define hierarchy`) | `NodeID` (HRP object) | Organizational Navigation tree — parent/child over HRP1001 (eval. path O-S-P). Read-only, its own tiny behavior (READ + hierarchy nav). |
| `ZC_HR360_KPI_OVERVIEW` | CDS **analytical query** (`@Analytics.query`) | dimensions | HR-wide audit dashboard (ALP / Overview Page). Not a transactional entity — no behavior. |

---

## 3. Root Entity — `ZI_HR360_EMPLOYEE`

### 3.1 Field groups

| Group | Fields (names finalised in Doc 04) |
|---|---|
| Key | `EmployeeID` |
| Identity | `FirstName`, `LastName`, `FormattedName`, `DateOfBirth`, `Gender`, `Nationality` |
| Employment | `EmploymentStatus`, `HireDate`, `CompanyCode`, `PersonnelArea` (+name), `PersonnelSubarea`, `EmployeeGroup` (+name), `EmployeeSubgroup` (+name) |
| Org snapshot | `OrgUnit` (+name), `Position` (+name), `CostCenter`, `ManagerID`, `ManagerName` |
| Contact snapshot | `EmailAddress`, `MobileNumber` |
| DQ KPIs (computed, from the PoC pattern) | `TotalIssueCount`, `CriticalIssueCount`, `WarningIssueCount`, `QualityStatus` (`OK`/`WARNING`/`CRITICAL`), `QualityStatusCriticality`, `CompletenessPercent` |

### 3.2 Computed KPI columns

Same technique as `ZI_HRDQ_EMP_QUALITY`: `LEFT OUTER JOIN ZI_HR360_ISSUE` +
`GROUP BY` all non-aggregated columns; `count(distinct …)` / `CASE` for the
counts and status. `CompletenessPercent` denominator = a **CDS constant**
(`ZI_HR360_ISSUE` active-branch count) referenced by name — the rev-2 replacement
for the PoC's hardcoded `8` / catalog lookup.

### 3.3 Associations exposed on the root

```
_Personal        [1..1]  to ZI_HR360_PERSONAL     on EmployeeID
_OrgAssignment   [1..1]  to ZI_HR360_ORGASSIGN    on EmployeeID
_Education        [0..*]  to ZI_HR360_EDUCATION    on EmployeeID
_Qualification   [0..*]  to ZI_HR360_QUALIF       on EmployeeID
_LeaveBalance    [0..*]  to ZI_HR360_LEAVE        on EmployeeID
_Attendance      [0..*]  to ZI_HR360_ATTENDANCE   on EmployeeID
_Payroll         [0..*]  to ZI_HR360_PAYROLL      on EmployeeID
_Document        [0..*]  to ZI_HR360_DOCUMENT     on EmployeeID
_Timeline        [0..*]  to ZI_HR360_TIMELINE     on EmployeeID
_DataQuality     [0..*]  to ZI_HR360_ISSUE        on EmployeeID
_Manager         [0..1]  to ZI_HR360_EMPLOYEE     on ManagerID  (self-assoc, for org nav)
_DirectReport    [0..*]  to ZI_HR360_EMPLOYEE     on $projection.EmployeeID = _DirectReport.ManagerID
```

---

## 4. Behavior Definition (interface layer)

```abap
unmanaged;
strict ( 2 );

define behavior for ZI_HR360_EMPLOYEE alias Employee
authorization master ( instance )
{
  association _Personal      { }
  association _OrgAssignment  { }
  association _Education      { }
  association _Qualification  { }
  association _LeaveBalance   { }
  association _Attendance     { }
  association _Payroll        { }
  association _Document       { }
  association _Timeline       { }
  association _DataQuality    { }
  association _Manager        { }
  association _DirectReport   { }
}

define behavior for ZI_HR360_PERSONAL     alias Personal        { }
define behavior for ZI_HR360_ORGASSIGN    alias OrgAssignment   { }
define behavior for ZI_HR360_EDUCATION    alias Education        { }
define behavior for ZI_HR360_QUALIF       alias Qualification    { }
define behavior for ZI_HR360_LEAVE        alias LeaveBalance     { }
define behavior for ZI_HR360_ATTENDANCE   alias Attendance       { }
define behavior for ZI_HR360_PAYROLL      alias PayrollItem      { }
define behavior for ZI_HR360_DOCUMENT     alias Document         { }
define behavior for ZI_HR360_TIMELINE     alias TimelineEvent    { }
define behavior for ZI_HR360_ISSUE        alias DataQualityIssue { }
```

- No `create` / `update` / `delete` / `action` on any entity.
- Only the root carries authorization (`authorization master ( instance )`);
  child reads inherit access through read-by-association from an authorised root
  instance (PoC pattern).

### 4.1 Behavior pool responsibilities (`ZBP_HR360_*`)

| Handler | Method kind | Body |
|---|---|---|
| `lhc_Employee.read` | `FOR READ` | `SELECT … FROM zi_hr360_employee FOR ALL ENTRIES IN keys WHERE EmployeeID = keys-EmployeeID` |
| `lhc_Employee.rba_*` | `FOR READ … AUGMENTING` / RBA per association | `SELECT` from the child view filtered by the parent keys, fill `links` + `result` |
| `lhc_Employee.get_instance_features` | `FOR INSTANCE FEATURES` | disable everything editable (defense in depth) |
| `lhc_Employee.get_instance_authorizations` | `FOR INSTANCE AUTHORIZATION` | `AUTHORITY-CHECK OBJECT 'P_ORGIN' … ID 'AUTHC' FIELD 'R'` → allowed / unauthorized |
| `lhc_<child>.read` | `FOR READ` | straight `SELECT` from the child interface view |

RBA methods are the one place ADT must regenerate the exact signature on the
target system (Doc 01 §13 caveat).

---

## 5. Projection Layer (consumption)

One projection per exposed interface entity, `provider contract
transactional_query`, all read-only:

| Projection | on | Notes |
|---|---|---|
| `ZC_HR360_EMPLOYEE` (root) | `ZI_HR360_EMPLOYEE` | `@UI.headerInfo`, `@Search.searchable`, facets → all child associations |
| `ZC_HR360_PERSONAL` | `ZI_HR360_PERSONAL` | IDENTIFICATION facet |
| `ZC_HR360_ORGASSIGN` | `ZI_HR360_ORGASSIGN` | IDENTIFICATION facet |
| `ZC_HR360_EDUCATION` | `ZI_HR360_EDUCATION` | LINEITEM facet |
| `ZC_HR360_QUALIF` | `ZI_HR360_QUALIF` | LINEITEM facet ×2 (filtered Skills / Certifications on `QualificationType`) |
| `ZC_HR360_LEAVE` | `ZI_HR360_LEAVE` | LINEITEM facet |
| `ZC_HR360_ATTENDANCE` | `ZI_HR360_ATTENDANCE` | LINEITEM facet |
| `ZC_HR360_PAYROLL` | `ZI_HR360_PAYROLL` | LINEITEM facet |
| `ZC_HR360_DOCUMENT` | `ZI_HR360_DOCUMENT` | LINEITEM facet, `@Semantics` link to content server |
| `ZC_HR360_TIMELINE` | `ZI_HR360_TIMELINE` | timeline facet (`@UI.lineItem` sorted desc) |
| `ZC_HR360_ISSUE` | `ZI_HR360_ISSUE` | LINEITEM facet, severity criticality colouring |

Projection behaviors: `projection; strict ( 2 );` with `use association …` for
every association on the root, `{ }` on the children (PoC pattern).

---

## 6. Entity-Relationship Diagram

```
                         ┌───────────────────────────┐
             _Manager ◄──┤   ZI_HR360_EMPLOYEE       ├──► _DirectReport
              (0..1)     │   (root, read-only)       │      (0..*)
                         │   key EmployeeID          │
                         │   + identity / employment │
                         │   + org snapshot          │
                         │   + DQ KPI columns        │
                         └────────────┬──────────────┘
                                      │ associations (all read-only)
   ┌───────────┬───────────┬──────────┼───────────┬───────────┬───────────┐
   ▼           ▼           ▼          ▼           ▼           ▼           ▼
_Personal  _OrgAssign  _Education  _Qualif   _LeaveBal   _Attendance  _Payroll
 (1..1)     (1..1)      (0..*)     (0..*)     (0..*)       (0..*)      (0..*)
 PA0002     PA0001      PA0022     PA0024     PA2006       PA2002      PA0008
 PA0006     +texts                 +HRP1000   +PA2001      +T554T      +T512T
 PA0105     HRP1000
 PA0009
   │           │
   ▼           ▼
_Document   _Timeline   _DataQuality
 (0..*)      (0..*)      (0..*)
 TOA01       union       ZI_HR360_ISSUE  (UNION ALL, one branch per check,
 TOAAT       IT history                   metadata as CDS literals)

  Standalone (same service, not in the tree):
   ZI_HR360_ORG_HIER      — CDS hierarchy over HRP1001 (O-S-P) → UI5 TreeTable
   ZC_HR360_KPI_OVERVIEW  — @Analytics.query over ZI_HR360_EMPLOYEE → ALP/OVP
```

---

## 7. Service Exposure (summary — full detail in Doc 06)

```
define service ZHR360_UI_SRVD {
  expose ZC_HR360_EMPLOYEE     as Employee;
  expose ZC_HR360_PERSONAL     as Personal;
  expose ZC_HR360_ORGASSIGN    as OrgAssignment;
  expose ZC_HR360_EDUCATION    as Education;
  expose ZC_HR360_QUALIF       as Qualification;
  expose ZC_HR360_LEAVE        as LeaveBalance;
  expose ZC_HR360_ATTENDANCE   as Attendance;
  expose ZC_HR360_PAYROLL      as PayrollItem;
  expose ZC_HR360_DOCUMENT     as Document;
  expose ZC_HR360_TIMELINE     as TimelineEvent;
  expose ZC_HR360_ISSUE        as DataQualityIssue;
  expose ZI_HR360_ORG_HIER     as OrgNode;
  expose ZC_HR360_KPI_OVERVIEW as KpiOverview;
}
```

Service binding (OData V4, UI) — created by you. Suggested name
`ZHR360_UI_SRVB_O4`.

---

## 8. Consequences / Notes

- **~11 read handlers + ~10 RBA handlers.** Mechanical but repetitive; Doc 05
  gives a single reusable RBA template and the per-entity `SELECT`.
- **Performance:** root KPI aggregation runs `ZI_HR360_ISSUE` (a wide UNION ALL)
  for every List Report page. `ZI_HR360_ISSUE` filters early on
  `ZI_HR360_EMP_BASIC` (active employees only) and each branch is a single
  indexed infotype access on `pernr` + date. Doc 04 sets the `@ObjectModel`
  buffering / `@Metadata` hints; Doc 10 (Technical Spec) records the volume
  assumptions.
- **`_Manager` / `_DirectReport`** are self-associations on the root for the
  flat "who reports to whom" facets; the full multi-level tree is the separate
  `ZI_HR360_ORG_HIER` hierarchy entity.
- **No determinations, no validations, no actions, no feature control beyond
  "disable edit".** If a later phase adds (e.g.) "flag record for HR review",
  that becomes an action on the root — no structural change to this model.

---

## 9. Open Points

None blocking. Field-level naming, annotation detail, and the exact
`ZI_HR360_ISSUE` check list are settled in **Doc 04 (CDS Design)**. RBA handler
signatures are settled in **Doc 05 (Behavior Design)**.

**Approve to proceed to Doc 03 (Persistence & Source Model).**
