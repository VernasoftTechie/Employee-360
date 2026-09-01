# Employee-360 — Behavior Design (Doc 05)

**Status:** DRAFT — awaiting approval (batch a).
Unmanaged, read-only RAP BO. No create/update/delete, no actions, no
determinations, no validations. This document specifies the BDEFs, the behavior
pool classes, the read + read-by-association (RBA) handlers, instance
features/authorization, and DCL.

---

## 1. Interface Behavior Definition — `ZI_HR360_EMPLOYEE`

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

define behavior for ZI_HR360_PERSONAL      alias Personal          { }
define behavior for ZI_HR360_ORGASSIGN     alias OrgAssignment     { }
define behavior for ZI_HR360_EDUCATION     alias Education         { }
define behavior for ZI_HR360_QUALIF        alias Qualification     { }
define behavior for ZI_HR360_LEAVE         alias LeaveBalance      { }
define behavior for ZI_HR360_ATTENDANCE    alias Attendance        { }
define behavior for ZI_HR360_PAYROLL       alias PayrollItem       { }
define behavior for ZI_HR360_DOCUMENT      alias Document          { }
define behavior for ZI_HR360_TIMELINE      alias TimelineEvent     { }
define behavior for ZI_HR360_ISSUE         alias DataQualityIssue  { }
```

Notes:
- No `persistent table`, no `lock master`, no `etag` — read-only unmanaged.
- Only the root declares `authorization master ( instance )`. Children carry no
  authorization; they are reachable only by RBA from an authorised root
  instance, and every child interface view also has
  `@AccessControl.authorizationCheck: #CHECK` + DCL (defense in depth).
- No `mapping for` — field names in CDS already match; the read handlers
  `SELECT ... INTO CORRESPONDING FIELDS OF TABLE @result`.

### 1.1 `ZI_HR360_ORG_HIER` behavior (separate BO)

```abap
unmanaged;
strict ( 2 );
define behavior for ZI_HR360_ORG_HIER alias OrgNode
{
  // hierarchy read only; RAP provides hierarchy navigation for a
  // 'define hierarchy' CDS entity with no handler code required for READ
}
```

`ZC_HR360_KPI_OVERVIEW` is an analytical query — **no behavior definition**.

---

## 2. Projection Behavior Definitions

```abap
projection;
strict ( 2 );
define behavior for ZC_HR360_EMPLOYEE alias Employee
{
  use association _Personal      { }
  use association _OrgAssignment  { }
  use association _Education      { }
  use association _Qualification  { }
  use association _LeaveBalance   { }
  use association _Attendance     { }
  use association _Payroll        { }
  use association _Document       { }
  use association _Timeline       { }
  use association _DataQuality    { }
  use association _Manager        { }
  use association _DirectReport   { }
}
define behavior for ZC_HR360_PERSONAL      alias Personal          { }
define behavior for ZC_HR360_ORGASSIGN     alias OrgAssignment     { }
define behavior for ZC_HR360_EDUCATION     alias Education         { }
define behavior for ZC_HR360_QUALIF        alias Qualification     { }
define behavior for ZC_HR360_LEAVE         alias LeaveBalance      { }
define behavior for ZC_HR360_ATTENDANCE    alias Attendance        { }
define behavior for ZC_HR360_PAYROLL       alias PayrollItem       { }
define behavior for ZC_HR360_DOCUMENT      alias Document          { }
define behavior for ZC_HR360_TIMELINE      alias TimelineEvent     { }
define behavior for ZC_HR360_ISSUE         alias DataQualityIssue  { }
```

---

## 3. Behavior Pool Classes

| Class | For behavior of | Local handler(s) |
|---|---|---|
| `ZBP_HR360_EMPLOYEE` | `ZI_HR360_EMPLOYEE` | `lhc_Employee` (READ, RBA ×12, FEATURES, AUTH) |
| `ZBP_HR360_CHILDREN` | *(one pool per child entity — see note)* | `lhc_Personal`, `lhc_OrgAssignment`, … each READ only |

> RAP requires **one behavior pool per behavior definition**. Since every child
> has its own `define behavior for …`, each needs its own pool class
> `ZBP_HR360_<ENTITY>`. They are near-identical 15-line READ-only classes; §5
> gives the single template they all follow. Alternative (fewer objects): make
> the children **associations of the root without their own behavior** — but
> then they cannot be exposed as independent OData entity sets. We keep separate
> pools (matches PoC `zbp_hrdq_issue`).

Full class list: `ZBP_HR360_EMPLOYEE`, `ZBP_HR360_PERSONAL`,
`ZBP_HR360_ORGASSIGN`, `ZBP_HR360_EDUCATION`, `ZBP_HR360_QUALIF`,
`ZBP_HR360_LEAVE`, `ZBP_HR360_ATTENDANCE`, `ZBP_HR360_PAYROLL`,
`ZBP_HR360_DOCUMENT`, `ZBP_HR360_TIMELINE`, `ZBP_HR360_ISSUE`.

---

## 4. Root Handler — `lhc_Employee`

```abap
CLASS lhc_Employee DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Employee RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Employee RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Employee RESULT result.
    METHODS read FOR READ
      IMPORTING keys FOR READ Employee RESULT result.
    METHODS rba_Personal      FOR READ IMPORTING keys_rba FOR READ Employee\_Personal      FULL result_requested RESULT result LINK association_links.
    METHODS rba_OrgAssignment FOR READ IMPORTING keys_rba FOR READ Employee\_OrgAssignment FULL result_requested RESULT result LINK association_links.
    METHODS rba_Education      FOR READ IMPORTING keys_rba FOR READ Employee\_Education      FULL result_requested RESULT result LINK association_links.
    METHODS rba_Qualification  FOR READ IMPORTING keys_rba FOR READ Employee\_Qualification  FULL result_requested RESULT result LINK association_links.
    METHODS rba_LeaveBalance   FOR READ IMPORTING keys_rba FOR READ Employee\_LeaveBalance   FULL result_requested RESULT result LINK association_links.
    METHODS rba_Attendance     FOR READ IMPORTING keys_rba FOR READ Employee\_Attendance     FULL result_requested RESULT result LINK association_links.
    METHODS rba_Payroll        FOR READ IMPORTING keys_rba FOR READ Employee\_Payroll        FULL result_requested RESULT result LINK association_links.
    METHODS rba_Document       FOR READ IMPORTING keys_rba FOR READ Employee\_Document       FULL result_requested RESULT result LINK association_links.
    METHODS rba_Timeline       FOR READ IMPORTING keys_rba FOR READ Employee\_Timeline       FULL result_requested RESULT result LINK association_links.
    METHODS rba_DataQuality    FOR READ IMPORTING keys_rba FOR READ Employee\_DataQuality    FULL result_requested RESULT result LINK association_links.
    METHODS rba_DirectReport   FOR READ IMPORTING keys_rba FOR READ Employee\_DirectReport   FULL result_requested RESULT result LINK association_links.
    METHODS rba_Manager        FOR READ IMPORTING keys_rba FOR READ Employee\_Manager        FULL result_requested RESULT result LINK association_links.
ENDCLASS.
```

> **Signature caveat (Doc 01 §13):** the exact `FOR READ … \_Assoc` syntax is
> framework-version-sensitive. On the target system: activate the BDEF, use
> ADT's *"Add all missing methods"* Quick Fix to generate the pool skeleton,
> then paste the method **bodies** below.

### 4.1 `read`

```abap
METHOD read.
  SELECT FROM zi_hr360_employee
    FIELDS *
    FOR ALL ENTRIES IN @keys
    WHERE EmployeeID = @keys-EmployeeID
    INTO CORRESPONDING FIELDS OF TABLE @result.
ENDMETHOD.
```

All KPI aggregation is already done in the CDS view — no ABAP-side computation.

### 4.2 RBA template (every `rba_*` follows this shape)

```abap
METHOD rba_Education.
  " 1. read the child rows for all requested parent keys
  SELECT FROM zi_hr360_education
    FIELDS *
    FOR ALL ENTRIES IN @keys_rba
    WHERE EmployeeID = @keys_rba-EmployeeID
    INTO TABLE @DATA(children).

  " 2. association links (parent key -> child key)
  association_links = VALUE #( FOR c IN children
    ( source-EmployeeID = c-EmployeeID
      target-EmployeeID   = c-EmployeeID
      target-ValidFrom    = c-ValidFrom
      target-EducationType = c-EducationType ) ).

  " 3. the child data itself (only if requested)
  IF result_requested = abap_true.
    result = CORRESPONDING #( children ).
  ENDIF.
ENDMETHOD.
```

Per-association specifics (the target key fields differ):

| RBA | child view | target key beyond EmployeeID |
|---|---|---|
| rba_Personal | ZI_HR360_PERSONAL | — (1:1) |
| rba_OrgAssignment | ZI_HR360_ORGASSIGN | — (1:1) |
| rba_Education | ZI_HR360_EDUCATION | EducationType, ValidFrom |
| rba_Qualification | ZI_HR360_QUALIF | QualificationID, ValidFrom |
| rba_LeaveBalance | ZI_HR360_LEAVE | QuotaType, DeductionFrom |
| rba_Attendance | ZI_HR360_ATTENDANCE | AttendanceFrom, AttendanceType |
| rba_Payroll | ZI_HR360_PAYROLL | ValidFrom |
| rba_Document | ZI_HR360_DOCUMENT | ArchivDocID |
| rba_Timeline | ZI_HR360_TIMELINE | EventDate, EventCategory, EventSeqNr |
| rba_DataQuality | ZI_HR360_ISSUE | CheckID |
| rba_Manager | ZI_HR360_EMPLOYEE | EmployeeID = parent.ManagerID (read parent first) |
| rba_DirectReport | ZI_HR360_EMPLOYEE | where ManagerID = parent.EmployeeID |

`rba_Manager` / `rba_DirectReport` read `zi_hr360_employee` filtered on
`ManagerID` — one extra round trip to get the parent's `ManagerID` for the
Manager case.

### 4.3 `get_instance_features`

```abap
METHOD get_instance_features.
  result = VALUE #( FOR k IN keys
    ( %tky = k-%tky
      %assoc-_Manager      = if_abap_behv=>fc-o-enabled
      %assoc-_DirectReport = if_abap_behv=>fc-o-enabled ) ).
  " no editable elements/actions exist; nothing to disable beyond defaults
ENDMETHOD.
```

### 4.4 Authorization — `get_global_authorizations` + `get_instance_authorizations`

```abap
METHOD get_global_authorizations.
  " gate the whole entity set: user must hold P_ORGIN display somewhere
  AUTHORITY-CHECK OBJECT 'P_ORGIN' ID 'AUTHC' FIELD 'R'
    ID 'INFTY' DUMMY ID 'PERSA' DUMMY ID 'PERSG' DUMMY
    ID 'PERSK' DUMMY ID 'VDSK1' DUMMY.
  DATA(ok) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                       ELSE if_abap_behv=>auth-unauthorized ).
  result-%read   = ok.
  result-%update = if_abap_behv=>auth-unauthorized.
  result-%delete = if_abap_behv=>auth-unauthorized.
ENDMETHOD.

METHOD get_instance_authorizations.
  SELECT FROM zi_hr360_orgassign
    FIELDS EmployeeID, CompanyCode, PersonnelArea, EmployeeGroup, EmployeeSubgroup
    FOR ALL ENTRIES IN @keys
    WHERE EmployeeID = @keys-EmployeeID
    INTO TABLE @DATA(orgs).

  LOOP AT keys INTO DATA(key).
    DATA(org) = VALUE #( orgs[ EmployeeID = key-EmployeeID ] OPTIONAL ).
    AUTHORITY-CHECK OBJECT 'P_ORGIN'
      ID 'INFTY' FIELD '0001'
      ID 'PERSA' FIELD org-PersonnelArea
      ID 'PERSG' FIELD org-EmployeeGroup
      ID 'PERSK' FIELD org-EmployeeSubgroup
      ID 'VDSK1' DUMMY
      ID 'AUTHC' FIELD 'R'.
    DATA(ok) = COND #( WHEN sy-subrc = 0 THEN if_abap_behv=>auth-allowed
                                         ELSE if_abap_behv=>auth-unauthorized ).
    APPEND VALUE #( %tky = key-%tky %auth-%read = ok ) TO result.
  ENDLOOP.
ENDMETHOD.
```

> **Structural authorization** (`P_ORGINCON` / profile-based) is deliberately not
> implemented (Doc 01 §9). If required at go-live, replace the
> `AUTHORITY-CHECK` above with `HR_CHECK_AUTHORIZATION` / a call to the client's
> structural-auth helper — isolated to this one method.

---

## 5. Child Handler Template (`lhc_Personal` … `lhc_DataQuality`)

Every child pool is this, with the view name and key fields swapped:

```abap
CLASS lhc_Education DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ IMPORTING keys FOR READ Education RESULT result.
ENDCLASS.

CLASS lhc_Education IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_education
      FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE EmployeeID     = @keys-EmployeeID
        AND EducationType  = @keys-EducationType
        AND ValidFrom      = @keys-ValidFrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
```

`ZI_HR360_ISSUE` child handler = exact PoC `zbp_hrdq_issue` logic
(`WHERE EmployeeID = keys-EmployeeID AND CheckID = keys-CheckID`).

---

## 6. Determinations / Validations / Actions

**None.** Read-only BO. Recorded here explicitly so a reviewer knows it is a
deliberate design, not an omission:

| RAP construct | Present? | Rationale |
|---|---|---|
| determination | no | nothing is written |
| validation | no | nothing is written; data-quality checks live in CDS (`ZI_HR360_ISSUE`), surfaced as a read-only child + report, not as RAP validations |
| action | no | Phase 1 has no operation beyond read |
| function | no | KPI values are CDS columns, not RAP functions |
| draft | no | nothing is edited |

---

## 7. DCL (Access Control)

```
@EndUserText.label: 'HR360 Employee - display auth (P_ORGIN)'
@MappingRole: true
define role ZI_HR360_EMPLOYEE_DCL {
  grant select on ZI_HR360_EMPLOYEE
    where ( PersonnelArea, EmployeeGroup, EmployeeSubgroup )
      = aspect pfcg_auth ( P_ORGIN,
                           PERSA, PERSG, PERSK,
                           AUTHC = 'R' );
}
```

Companion roles for the child interface views that are independently exposed
(`ZI_HR360_PERSONAL`, `_ORGASSIGN`, `_EDUCATION`, `_QUALIF`, `_LEAVE`,
`_ATTENDANCE`, `_PAYROLL`, `_DOCUMENT`, `_TIMELINE`, `_ISSUE`) — each grants
select where its `EmployeeID` is in the set permitted by the same
`P_ORGIN` aspect, via an inherited condition:

```
define role ZI_HR360_EDUCATION_DCL {
  grant select on ZI_HR360_EDUCATION
    where EmployeeID = aspect_ref( ZI_HR360_EMPLOYEE, EmployeeID );
}
```

> If `aspect_ref` inheritance is not viable on the target release, fall back to
> repeating the `pfcg_auth` clause against a join to `ZI_HR360_EMP_BASIC`
> (which carries PERSA/PERSG/PERSK). Decided at build against the live system.

`ZI_HR360_HIREDATE`, `ZI_HR360_MANAGER`, `ZI_HR360_ORG_NODE`,
`ZI_HR360_ORG_HIER` — `#NOT_REQUIRED`, no DCL (OM/derived, no personal data).

---

## 8. ABAP Unit

| Test class | Under test | Technique |
|---|---|---|
| `ZCL_HR360_ISSUE_TEST` | `ZI_HR360_ISSUE` (all 12 branches) | CDS Test Double Framework (`cl_cds_test_environment`) — from PoC; one `*_is_flagged` + one `*_clean` method per check |
| `ZCL_HR360_EMPLOYEE_TEST` | `ZI_HR360_EMPLOYEE` KPI columns | CDS test doubles for `ZI_HR360_EMP_BASIC` + `ZI_HR360_ISSUE`; assert `TotalIssueCount` / `QualityStatus` / `CompletenessPercent` |
| `ZCL_HR360_ORG_READER_TEST` | `ZCL_HR360_ORG_READER` | double HRP1000/HRP1001; assert manager resolution + hierarchy depth |
| `ZCL_HR360_REPORT_ENGINE_TEST` | `ZCL_HR360_REPORT_ENGINE` | double the CDS views; assert row selection, missing-data grouping, file record layout (Doc 08) |

RAP BO integration (EML `READ ENTITIES … BY \_association`) — one smoke test in
`ZCL_HR360_EMPLOYEE_TEST` using `cl_abap_behv_test_environment` if available on
the release; otherwise a manual test script documented in Doc 11.

**Approve to proceed — Doc 06 (Service Definition) follows in this batch.**
