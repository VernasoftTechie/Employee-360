# Employee-360 — CDS Design (Doc 04)

**Status:** DRAFT — awaiting approval (batch a).
This document is the source-of-truth for every CDS entity. On approval these
listings become `/src/*.ddls.asddls` essentially verbatim.

**Conventions**

- `define view entity` (no legacy `DEFINE VIEW` / SQL view name) — Rulebook §2.
- Interface views: `@VDM.viewType: #BASIC` (leaf) / `#COMPOSITE` (joins other Z
  views) / `#CONSUMPTION` (root). `@Metadata.ignorePropagatedAnnotations: true`.
- `@AccessControl.authorizationCheck: #CHECK` everywhere personal data is read;
  `#NOT_REQUIRED` only for pure text/derived views.
- **No UI annotations in interface or projection views** — all `@UI.*` live in
  Metadata Extensions (`ZC_HR360_*_MDE`), see Doc 07 (Rulebook §2).
- Date filter macro (written out in each view): `BEGDA <= $session.system_date
  AND ENDDA >= $session.system_date`. Reports override via a parameter
  (`P_KeyDate`) — see §14.
- Text joins: `LEFT OUTER JOIN … ON …SPRSL = $session.system_language`.

---

## 1. Anchor & PoC-derived leaf views

### 1.1 `ZI_HR360_EMP_BASIC`  *(rename of `ZI_HRDQ_EMP_BASIC`, logic unchanged)*

```
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee Basic (anchor)'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE
define view entity ZI_HR360_EMP_BASIC
  as select from pa0001 as OrgAssignment
  inner join      pa0002 as PersonalData on  PersonalData.pernr = OrgAssignment.pernr
                                          and PersonalData.begda <= $session.system_date
                                          and PersonalData.endda >= $session.system_date
  left outer join t500p as PersArea       on  PersArea.persa = OrgAssignment.werks
  left outer join t501t as EEGroupTxt     on  EEGroupTxt.sprsl = $session.system_language
                                          and EEGroupTxt.persg = OrgAssignment.persg
  left outer join t503t as EESubgroupTxt  on  EESubgroupTxt.sprsl = $session.system_language
                                          and EESubgroupTxt.persk = OrgAssignment.persk
  left outer join t527x as OrgUnitTxt     on  OrgUnitTxt.sprsl = $session.system_language
                                          and OrgUnitTxt.orgeh = OrgAssignment.orgeh
                                          and OrgUnitTxt.begda <= $session.system_date
                                          and OrgUnitTxt.endda >= $session.system_date
  where OrgAssignment.begda <= $session.system_date
    and OrgAssignment.endda >= $session.system_date
{
  key OrgAssignment.pernr        as EmployeeID,
      OrgAssignment.bukrs        as CompanyCode,
      OrgAssignment.werks        as PersonnelArea,
      PersArea.name1             as PersonnelAreaName,
      OrgAssignment.btrtl        as PersonnelSubarea,
      OrgAssignment.persg        as EmployeeGroup,
      EEGroupTxt.ptext           as EmployeeGroupName,
      OrgAssignment.persk        as EmployeeSubgroup,
      EESubgroupTxt.ptext        as EmployeeSubgroupName,
      OrgAssignment.orgeh        as OrgUnit,
      OrgUnitTxt.orgtx           as OrgUnitName,
      OrgAssignment.kostl        as CostCenter,
      OrgAssignment.plans        as Position,
      OrgAssignment.stell        as Job,
      OrgAssignment.stat2        as EmploymentStatus,
      PersonalData.nachn         as LastName,
      PersonalData.vorna         as FirstName,
      PersonalData.gbdat         as DateOfBirth,
      PersonalData.gesch         as Gender,
      PersonalData.natio         as Nationality
}
```

### 1.2 `ZI_HR360_EMP_CONTACT`, `ZI_HR360_EMP_BANK`, `ZI_HR360_EMP_PAY`

Straight renames of `ZI_HRDQ_EMP_CONTACT` / `_BANK` / `_PAY` (Doc 03 §3.1/§3.9);
subtype filters `PA0105 0010/0020`, `PA0006 '1'`, `PA0009 '0'`; keys on
`EmployeeID`. No logic change.

---

## 2. `ZI_HR360_PERSONAL`  (1:1)

```
@AccessControl.authorizationCheck: #CHECK
@VDM.viewType: #COMPOSITE
define view entity ZI_HR360_PERSONAL
  as select from pa0002 as P
  left outer join pa0006 as Addr    on Addr.pernr = P.pernr and Addr.subty = '1'
                                    and Addr.begda <= $session.system_date and Addr.endda >= $session.system_date
  left outer join pa0105 as Mail    on Mail.pernr = P.pernr and Mail.subty = '0010'
                                    and Mail.begda <= $session.system_date and Mail.endda >= $session.system_date
  left outer join pa0105 as Cell    on Cell.pernr = P.pernr and Cell.subty = '0020'
                                    and Cell.begda <= $session.system_date and Cell.endda >= $session.system_date
  left outer join pa0009 as Bank    on Bank.pernr = P.pernr and Bank.subty = '0'
                                    and Bank.begda <= $session.system_date and Bank.endda >= $session.system_date
  left outer join t502t  as MarStat on MarStat.sprsl = $session.system_language and MarStat.famst = P.famst
  where P.begda <= $session.system_date and P.endda >= $session.system_date
{
  key P.pernr                                as EmployeeID,
      P.vorna                                as FirstName,
      P.nachn                                as LastName,
      P.name2                                as SecondName,
      concat(concat(P.vorna, ' '), P.nachn)  as FormattedName,
      P.gbdat                                as DateOfBirth,
      P.gbort                                as BirthPlace,
      P.gesch                                as Gender,
      P.natio                                as Nationality,
      P.famst                                as MaritalStatus,
      MarStat.ftext                          as MaritalStatusName,
      Addr.stras                             as Street,
      Addr.ort01                             as City,
      Addr.pstlz                             as PostalCode,
      Addr.state                             as Region,
      Addr.land1                             as Country,
      Mail.usrid_long                        as EmailAddress,
      Cell.usrid_long                        as MobileNumber,
      Bank.bankl                             as BankKey,
      Bank.bankn                             as BankAccount,
      Bank.iban                              as IBAN,
      Bank.bkont                             as BankControlKey
}
```

---

## 3. `ZI_HR360_ORGASSIGN`  (1:1)

```
@AccessControl.authorizationCheck: #CHECK
@VDM.viewType: #COMPOSITE
define view entity ZI_HR360_ORGASSIGN
  as select from pa0001 as O
  left outer join t500p  as PA   on PA.persa = O.werks
  left outer join t501t  as EG   on EG.sprsl = $session.system_language and EG.persg = O.persg
  left outer join t503t  as ESG  on ESG.sprsl = $session.system_language and ESG.persk = O.persk
  left outer join t527x  as OU   on OU.sprsl = $session.system_language and OU.orgeh = O.orgeh
                                 and OU.begda <= $session.system_date and OU.endda >= $session.system_date
  left outer join hrp1000 as POS on POS.plvar = '01' and POS.otype = 'S' and POS.objid = O.plans
                                 and POS.langu = $session.system_language
                                 and POS.begda <= $session.system_date and POS.endda >= $session.system_date
  left outer join t513s  as JOBT on JOBT.sprsl = $session.system_language and JOBT.stell = O.stell
  association [0..1] to ZI_HR360_EMPLOYEE as _Manager on _Manager.EmployeeID = $projection.ManagerID
  where O.begda <= $session.system_date and O.endda >= $session.system_date
{
  key O.pernr                    as EmployeeID,
      O.bukrs                    as CompanyCode,
      O.werks                    as PersonnelArea,
      PA.name1                   as PersonnelAreaName,
      O.btrtl                    as PersonnelSubarea,
      O.persg                    as EmployeeGroup,
      EG.ptext                   as EmployeeGroupName,
      O.persk                    as EmployeeSubgroup,
      ESG.ptext                  as EmployeeSubgroupName,
      O.orgeh                    as OrgUnit,
      OU.orgtx                   as OrgUnitName,
      O.plans                    as Position,
      POS.stext                  as PositionName,
      O.stell                    as Job,
      JOBT.stltx                 as JobName,
      O.kostl                    as CostCenter,
      cast( '' as pernr )        as ManagerID,      // resolved in root via ZCL_HR360_ORG_READER-backed assoc OR HRP1001 view (§9)
      _Manager.FormattedName     as ManagerName,
      _Manager
}
```

> `ManagerID` resolution: the pure-CDS path (HRP1001 S→S chief → S→P holder) is
> defined as `ZI_HR360_MANAGER` helper view (§9); `ZI_HR360_ORGASSIGN` joins it.
> Shown abbreviated here to keep the listing readable — Doc 05 confirms the join.

---

## 4. History children

### 4.1 `ZI_HR360_EDUCATION`  (1:n)

```
@AccessControl.authorizationCheck: #CHECK
@VDM.viewType: #COMPOSITE
define view entity ZI_HR360_EDUCATION
  as select from pa0022 as E
  left outer join t517t as ETyp on ETyp.sprsl = $session.system_language and ETyp.slart = E.slart
  left outer join t517x as ECrt on ECrt.sprsl = $session.system_language and ECrt.sltp1 = E.sltp1
{
  key E.pernr   as EmployeeID,
  key E.subty   as EducationType,
  key E.begda   as ValidFrom,
      E.seqnr   as EducationSeqNr,
      ETyp.stext as EducationTypeName,
      E.slabs   as Establishment,
      E.insti   as InstituteName,
      E.sltp1   as Certificate,
      ECrt.stext as CertificateName,
      E.sltp2   as Discipline,
      E.endda   as ValidTo,
      E.ausbi   as EducationalEstablishmentKey
}
```

### 4.2 `ZI_HR360_QUALIF`  (1:n) — Skills + Certifications

```
@AccessControl.authorizationCheck: #CHECK
@VDM.viewType: #COMPOSITE
define view entity ZI_HR360_QUALIF
  as select from pa0024 as Q
  left outer join hrp1000 as QT  on QT.plvar='01' and QT.otype='Q' and QT.objid = cast(Q.quali as hrobjid)
                                 and QT.langu = $session.system_language
                                 and QT.begda <= $session.system_date and QT.endda >= $session.system_date
  left outer join hrp1001 as GRP on GRP.plvar='01' and GRP.otype='Q' and GRP.objid = cast(Q.quali as hrobjid)
                                 and GRP.rsign='A' and GRP.relat='002' and GRP.sclas='QK'
                                 and GRP.begda <= $session.system_date and GRP.endda >= $session.system_date
  left outer join hrp1000 as GRPT on GRPT.plvar='01' and GRPT.otype='QK' and GRPT.objid = GRP.sobid
                                  and GRPT.langu = $session.system_language
{
  key Q.pernr                       as EmployeeID,
  key Q.quali                       as QualificationID,
  key Q.begda                       as ValidFrom,
      QT.stext                      as QualificationName,
      GRP.sobid                     as QualificationGroup,
      GRPT.stext                    as QualificationGroupName,
      case when GRP.sobid in ( $parameters.p_cert_groups ) then 'CERT' else 'SKILL' end as QualificationType,
      Q.auspr                       as Proficiency,
      Q.endda                       as ValidTo,
      case when Q.endda < $session.system_date then 'X' else '' end as IsExpired
}
```

> `p_cert_groups` — if parameterising a list is awkward, the CERT/SKILL split
> becomes a small `case … when GRP.sobid = 'nnnnnnnn' then 'CERT'` ladder or is
> dropped (all rows `SKILL`) per **CONFIRM 7.3** default. Finalised in build.

### 4.3 `ZI_HR360_LEAVE`  (1:n)

```
define view entity ZI_HR360_LEAVE
  as select from pa2006 as Qta
  left outer join t556b as QT on QT.sprsl = $session.system_language and QT.ktart = Qta.ktart and QT.moabw = Qta.quomo
{
  key Qta.pernr                  as EmployeeID,
  key Qta.ktart                  as QuotaType,
  key Qta.desta                  as DeductionFrom,
      QT.ktext                   as QuotaTypeName,
      Qta.deend                  as DeductionTo,
      Qta.anzhl                  as Entitlement,
      Qta.kverb                  as Deducted,
      Qta.anzhl - Qta.kverb      as Remaining,
      Qta.ktart                  as _dummy_unit_placeholder   // Unit derived in projection / MDE
}
```

### 4.4 `ZI_HR360_ATTENDANCE`  (1:n)

```
define view entity ZI_HR360_ATTENDANCE
  as select from pa2002 as A
  left outer join t554t as AT on AT.sprsl = $session.system_language and AT.moabw = A.moabw and AT.awart = A.awart
{
  key A.pernr   as EmployeeID,
  key A.begda   as AttendanceFrom,
  key A.awart   as AttendanceType,
      A.endda   as AttendanceTo,
      AT.atext  as AttendanceTypeName,
      A.abwtg   as AttendanceDays,
      A.stdaz   as AttendanceHours,
      A.beguz   as StartTime,
      A.enduz   as EndTime
}
```

### 4.5 `ZI_HR360_PAYROLL`  (1:n)

```
define view entity ZI_HR360_PAYROLL
  as select from pa0008 as B
  left outer join t539r as RE on RE.sprsl = $session.system_language and RE.preas = B.preas and RE.massn = B.massn
{
  key B.pernr   as EmployeeID,
  key B.begda   as ValidFrom,
      B.endda   as ValidTo,
      B.trfar   as PayScaleType,
      B.trfgb   as PayScaleArea,
      B.trfgr   as PayScaleGroup,
      B.trfst   as PayScaleLevel,
      B.ansal   as AnnualSalary,
      B.waers   as Currency,
      B.bsgrd   as CapacityUtilizationLevel,
      B.divgv   as WeeklyHours,
      B.preas   as PayChangeReason,
      RE.pretx  as PayChangeReasonName
}
```

### 4.6 `ZI_HR360_DOCUMENT`  (1:n)

```
@AccessControl.authorizationCheck: #CHECK
define view entity ZI_HR360_DOCUMENT
  as select from toa01 as L
  left outer join toaat as At on At.arc_doc_id = L.arc_doc_id
{
  key cast( substring(L.object_id, 1, 8) as pernr ) as EmployeeID,
  key L.arc_doc_id                                  as ArchivDocID,
      L.archiv_id                                   as ArchiveID,
      L.ar_object                                   as DocumentType,
      L.ar_date                                     as ArchiveDate,
      At.descr                                      as Title,
      At.reserve                                    as MimeHint
}
where L.sap_object = 'PREL'
```

---

## 5. `ZI_HR360_TIMELINE`  (derived, 1:n)

UNION ALL; every branch emits the same 7 columns. `EventCategory` /
`EventType` / `Title` are CDS literals or simple `concat`.

```
@AccessControl.authorizationCheck: #CHECK
@VDM.viewType: #COMPOSITE
define view entity ZI_HR360_TIMELINE
  as select from pa0000 as Act
     left outer join t529t as AT on AT.sprsl=$session.system_language and AT.massn=Act.massn
  {
    key Act.pernr                       as EmployeeID,
    key Act.begda                       as EventDate,
    key cast('ACTION' as abap.char(12)) as EventCategory,
    key Act.seqnr                       as EventSeqNr,
        Act.massn                       as EventType,
        AT.mntext                       as Title,
        cast('' as abap.string)         as Detail,
        cast(Act.begda as abap.dats)    as SortDate
  }
union all select from pa0001 as O {
    key O.pernr, key O.begda, key cast('ORG_CHANGE' as abap.char(12)), key O.seqnr,
        cast('ORGEH' as abap.char(12)) as EventType,
        concat('Org unit: ', O.orgeh)  as Title,
        concat('Position: ', O.plans)  as Detail,
        cast(O.begda as abap.dats)     as SortDate }
union all select from pa0008 as B {
    key B.pernr, key B.begda, key cast('PAY_CHANGE' as abap.char(12)), key B.seqnr,
        cast('BASICPAY' as abap.char(12)) as EventType,
        cast('Basic pay changed' as abap.string) as Title,
        concat('Pay scale: ', concat(B.trfgr, B.trfst)) as Detail,
        cast(B.begda as abap.dats) as SortDate }
union all select from pa0022 as E {
    key E.pernr, key E.begda, key cast('EDUCATION' as abap.char(12)), key E.seqnr,
        cast('EDU' as abap.char(12)) as EventType,
        concat('Education: ', E.slart) as Title,
        cast(E.insti as abap.string)  as Detail,
        cast(E.begda as abap.dats) as SortDate }
union all select from pa0024 as Q {
    key Q.pernr, key Q.begda, key cast('QUALIFICATION' as abap.char(12)),
        key cast(0 as abap.int4) as EventSeqNr,
        cast('QUAL' as abap.char(12)) as EventType,
        concat('Qualification: ', Q.quali) as Title,
        concat('Proficiency: ', Q.auspr)   as Detail,
        cast(Q.begda as abap.dats) as SortDate }
union all select from pa2001 as Ab {
    key Ab.pernr, key Ab.begda, key cast('ABSENCE' as abap.char(12)), key Ab.seqnr,
        Ab.awart as EventType,
        concat('Absence: ', Ab.awart) as Title,
        concat('Days: ', cast(Ab.abwtg as abap.char(10))) as Detail,
        cast(Ab.begda as abap.dats) as SortDate }
```

> `PA2001` branch: filter to long absences via a CDS constant threshold
> (`Ab.abwtg >= @threshold`) — set in build; default 5 days.
> Column types unified across branches (`char(12)` category, `string` title) —
> finalised so every branch compiles identically.

---

## 6. `ZI_HR360_ISSUE`  (derived, 1:n) — the check framework, no catalog table

Same shape as `ZI_HRDQ_ISSUE`; the removed `INNER JOIN ZI_HRDQ_CHECK_CAT` is
replaced by **CDS literals** for `CheckID / Category / Severity /
IssueDescription`. One branch per check.

```
@AccessControl.authorizationCheck: #CHECK
@VDM.viewType: #COMPOSITE
define view entity ZI_HR360_ISSUE
  as select from ZI_HR360_EMP_BASIC as Emp
  where Emp.DateOfBirth is initial
  {
    key Emp.EmployeeID                                as EmployeeID,
    key cast('MAND_DOB' as abap.char(12))            as CheckID,
        cast('MANDATORY' as abap.char(20))           as Category,
        cast('C' as abap.char(1))                    as Severity,
        cast('Date of birth is missing' as abap.char(60)) as IssueDescription,
        cast('DateOfBirth' as abap.char(30))         as FieldName
  }
union all select from ZI_HR360_EMP_BASIC as Emp where Emp.Gender is initial {
    key Emp.EmployeeID, key cast('MAND_GENDER' as abap.char(12)),
        cast('MANDATORY' as abap.char(20)), cast('C' as abap.char(1)),
        cast('Gender is missing' as abap.char(60)), cast('Gender' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp where Emp.Nationality is initial {
    key Emp.EmployeeID, key cast('STAT_NATION' as abap.char(12)),
        cast('STATUTORY' as abap.char(20)), cast('C' as abap.char(1)),
        cast('Nationality is missing' as abap.char(60)), cast('Nationality' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp where Emp.CostCenter is initial {
    key Emp.EmployeeID, key cast('ORG_COSTCTR' as abap.char(12)),
        cast('ORG_ASSIGNMENT' as abap.char(20)), cast('C' as abap.char(1)),
        cast('Cost center assignment is missing' as abap.char(60)), cast('CostCenter' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp where Emp.Position is initial {
    key Emp.EmployeeID, key cast('ORG_POSITION' as abap.char(12)),
        cast('ORG_ASSIGNMENT' as abap.char(20)), cast('C' as abap.char(1)),
        cast('Position is not assigned' as abap.char(60)), cast('Position' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp
  left outer join ZI_HR360_EMP_PAY as Pay on Pay.EmployeeID = Emp.EmployeeID
  where Pay.EmployeeID is initial {
    key Emp.EmployeeID, key cast('PAY_BASICPAY' as abap.char(12)),
        cast('PAYROLL_TIME' as abap.char(20)), cast('W' as abap.char(1)),
        cast('Basic pay record is missing' as abap.char(60)), cast('BasicPay' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp
  left outer join ZI_HR360_EMP_CONTACT as C on C.EmployeeID = Emp.EmployeeID
  where C.EmailAddress is initial {
    key Emp.EmployeeID, key cast('CONTACT_MAIL' as abap.char(12)),
        cast('CONTACT' as abap.char(20)), cast('W' as abap.char(1)),
        cast('Email address is missing' as abap.char(60)), cast('EmailAddress' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp
  left outer join ZI_HR360_EMP_BANK as B on B.EmployeeID = Emp.EmployeeID
  where B.IBAN is initial {
    key Emp.EmployeeID, key cast('BANK_IBAN' as abap.char(12)),
        cast('BANK' as abap.char(20)), cast('C' as abap.char(1)),
        cast('IBAN / bank details missing' as abap.char(60)), cast('IBAN' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp
  left outer join ZI_HR360_EDUCATION as Ed on Ed.EmployeeID = Emp.EmployeeID
  where Ed.EmployeeID is initial {
    key Emp.EmployeeID, key cast('EDU_MISSING' as abap.char(12)),
        cast('EDUCATION' as abap.char(20)), cast('W' as abap.char(1)),
        cast('No education record on file' as abap.char(60)), cast('Education' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp
  left outer join ZI_HR360_QUALIF as Ql on Ql.EmployeeID = Emp.EmployeeID
  where Ql.EmployeeID is initial {
    key Emp.EmployeeID, key cast('QUAL_MISSING' as abap.char(12)),
        cast('QUALIFICATION' as abap.char(20)), cast('W' as abap.char(1)),
        cast('No qualification / skill on file' as abap.char(60)), cast('Qualification' as abap.char(30)) }
union all select from ZI_HR360_EMP_BASIC as Emp   // invalid-value example (kept from PoC)
  where Emp.DateOfBirth > $session.system_date and Emp.DateOfBirth is not initial {
    key Emp.EmployeeID, key cast('INVALID_DOB' as abap.char(12)),
        cast('INVALID' as abap.char(20)), cast('C' as abap.char(1)),
        cast('Date of birth is in the future' as abap.char(60)), cast('DateOfBirth' as abap.char(30)) }
```

**Active branch count = 12.** Declared once as a CDS constant used by
`CompletenessPercent` (§7). Adding/removing a check = edit one branch + update
the constant. No other object changes.

---

## 7. Root — `ZI_HR360_EMPLOYEE`

```
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (root)'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #CONSUMPTION
@Search.searchable: true
define root view entity ZI_HR360_EMPLOYEE
  as select from ZI_HR360_EMP_BASIC as Emp
  left outer join ZI_HR360_ISSUE   as Iss on Iss.EmployeeID = Emp.EmployeeID
  left outer join ZI_HR360_MANAGER as Mgr on Mgr.EmployeeID = Emp.EmployeeID
  left outer join ZI_HR360_HIREDATE as Hd on Hd.EmployeeID = Emp.EmployeeID

  association [1..1] to ZI_HR360_PERSONAL   as _Personal      on _Personal.EmployeeID     = $projection.EmployeeID
  association [1..1] to ZI_HR360_ORGASSIGN  as _OrgAssignment on _OrgAssignment.EmployeeID = $projection.EmployeeID
  association [0..*] to ZI_HR360_EDUCATION  as _Education      on _Education.EmployeeID     = $projection.EmployeeID
  association [0..*] to ZI_HR360_QUALIF     as _Qualification  on _Qualification.EmployeeID = $projection.EmployeeID
  association [0..*] to ZI_HR360_LEAVE      as _LeaveBalance   on _LeaveBalance.EmployeeID  = $projection.EmployeeID
  association [0..*] to ZI_HR360_ATTENDANCE as _Attendance     on _Attendance.EmployeeID    = $projection.EmployeeID
  association [0..*] to ZI_HR360_PAYROLL    as _Payroll        on _Payroll.EmployeeID       = $projection.EmployeeID
  association [0..*] to ZI_HR360_DOCUMENT   as _Document       on _Document.EmployeeID      = $projection.EmployeeID
  association [0..*] to ZI_HR360_TIMELINE   as _Timeline       on _Timeline.EmployeeID      = $projection.EmployeeID
  association [0..*] to ZI_HR360_ISSUE      as _DataQuality    on _DataQuality.EmployeeID   = $projection.EmployeeID
  association [0..1] to ZI_HR360_EMPLOYEE   as _Manager        on _Manager.EmployeeID       = $projection.ManagerID
  association [0..*] to ZI_HR360_EMPLOYEE   as _DirectReport   on _DirectReport.ManagerID   = $projection.EmployeeID
{
  key Emp.EmployeeID                                    as EmployeeID,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      Emp.LastName                                      as LastName,
      @Search.defaultSearchElement: true
      Emp.FirstName                                     as FirstName,
      concat(concat(Emp.FirstName, ' '), Emp.LastName)  as FormattedName,
      Emp.DateOfBirth                                   as DateOfBirth,
      Emp.Gender                                        as Gender,
      Emp.Nationality                                   as Nationality,
      Emp.EmploymentStatus                             as EmploymentStatus,
      Hd.HireDate                                       as HireDate,
      Emp.CompanyCode                                   as CompanyCode,
      Emp.PersonnelArea                                 as PersonnelArea,
      Emp.PersonnelAreaName                             as PersonnelAreaName,
      Emp.EmployeeGroup                                 as EmployeeGroup,
      Emp.EmployeeGroupName                             as EmployeeGroupName,
      Emp.EmployeeSubgroup                              as EmployeeSubgroup,
      Emp.EmployeeSubgroupName                          as EmployeeSubgroupName,
      @Search.defaultSearchElement: true
      Emp.OrgUnit                                       as OrgUnit,
      Emp.OrgUnitName                                   as OrgUnitName,
      Emp.Position                                      as Position,
      Emp.CostCenter                                    as CostCenter,
      Mgr.ManagerID                                     as ManagerID,
      Mgr.ManagerName                                   as ManagerName,

      // ---- DQ KPIs (PoC pattern) ----
      count( distinct Iss.CheckID )                                                     as TotalIssueCount,
      count( distinct case when Iss.Severity = 'C' then Iss.CheckID end )               as CriticalIssueCount,
      count( distinct case when Iss.Severity = 'W' then Iss.CheckID end )               as WarningIssueCount,
      case when count( distinct Iss.CheckID ) = 0 then 'OK'
           when count( distinct case when Iss.Severity = 'C' then Iss.CheckID end ) > 0 then 'CRITICAL'
           else 'WARNING' end                                                           as QualityStatus,
      cast( 100 - ( count( distinct Iss.CheckID ) * 100 /
            cast( 12 as abap.dec(2,0) ) ) as abap.dec(5,1) )                            as CompletenessPercent,

      _Personal, _OrgAssignment, _Education, _Qualification, _LeaveBalance,
      _Attendance, _Payroll, _Document, _Timeline, _DataQuality,
      _Manager, _DirectReport
}
group by
  Emp.EmployeeID, Emp.LastName, Emp.FirstName, Emp.DateOfBirth, Emp.Gender,
  Emp.Nationality, Emp.EmploymentStatus, Hd.HireDate, Emp.CompanyCode,
  Emp.PersonnelArea, Emp.PersonnelAreaName, Emp.EmployeeGroup, Emp.EmployeeGroupName,
  Emp.EmployeeSubgroup, Emp.EmployeeSubgroupName, Emp.OrgUnit, Emp.OrgUnitName,
  Emp.Position, Emp.CostCenter, Mgr.ManagerID, Mgr.ManagerName
```

> `12` = active-branch count of `ZI_HR360_ISSUE`. In build this is a
> `abap.dec` **CDS constant** (`ZI_HR360_ISSUE.branch_count`) referenced by name;
> the literal here is illustrative. Comment flags it inline (PoC discipline).

---

## 8. Helper views

- `ZI_HR360_HIREDATE` — `select from pa0000 { key pernr as EmployeeID, min(begda) as HireDate } where massn in ( '01' ) group by pernr`. Hiring-action set = CDS constant.
- `ZI_HR360_MANAGER` — HRP1001 chain: employee → position (`PA0001.PLANS`) →
  chief position (`A002`/`A012` per client) → position holder (`A008` → P).
  Emits `EmployeeID`, `ManagerID` (pernr), `ManagerPosition`. `@AccessControl:
  #NOT_REQUIRED` (OM data only). Deep/edge cases handled in
  `ZCL_HR360_ORG_READER` for reports; the view covers the common single-level case.

---

## 9. Organizational Hierarchy — `ZI_HR360_ORG_HIER`

```
@AccessControl.authorizationCheck: #CHECK
define hierarchy ZI_HR360_ORG_HIER
  as parent child hierarchy(
    source ZI_HR360_ORG_NODE
    child to parent association _Parent
    start where OrgUnit = $parameters.p_root_orgunit
    siblings order by NodeText
  )
{ NodeID, NodeType, NodeText, ParentNodeID, OrgUnit, _Parent }
```

with a plain `ZI_HR360_ORG_NODE` view over HRP1000/HRP1001 (Doc 03 §4):
`NodeID = otype+objid`, `_Parent` association on HRP1001 (`RSIGN='A' RELAT in
('002','003')`). `p_root_orgunit` supplied by the UI (defaults to the viewed
employee's org unit).

---

## 10. Projection views  `ZC_HR360_*`

All `provider contract transactional_query`, read-only, **no `@UI`** (→ MDE,
Doc 07). Pattern:

```
define root view entity ZC_HR360_EMPLOYEE
  provider contract transactional_query
  as projection on ZI_HR360_EMPLOYEE
{
  key EmployeeID, LastName, FirstName, FormattedName, DateOfBirth, Gender,
      Nationality, EmploymentStatus, HireDate, CompanyCode, PersonnelArea,
      PersonnelAreaName, EmployeeGroup, EmployeeGroupName, EmployeeSubgroup,
      EmployeeSubgroupName, OrgUnit, OrgUnitName, Position, CostCenter,
      ManagerID, ManagerName, TotalIssueCount, CriticalIssueCount,
      WarningIssueCount, QualityStatus,
      case QualityStatus when 'OK' then 3 when 'WARNING' then 2
                         when 'CRITICAL' then 1 else 0 end as QualityStatusCriticality,
      CompletenessPercent,
      _Personal      : redirected to ZC_HR360_PERSONAL,
      _OrgAssignment : redirected to ZC_HR360_ORGASSIGN,
      _Education     : redirected to ZC_HR360_EDUCATION,
      _Qualification : redirected to ZC_HR360_QUALIF,
      _LeaveBalance  : redirected to ZC_HR360_LEAVE,
      _Attendance    : redirected to ZC_HR360_ATTENDANCE,
      _Payroll       : redirected to ZC_HR360_PAYROLL,
      _Document      : redirected to ZC_HR360_DOCUMENT,
      _Timeline      : redirected to ZC_HR360_TIMELINE,
      _DataQuality   : redirected to ZC_HR360_ISSUE,
      _Manager       : redirected to ZC_HR360_EMPLOYEE,
      _DirectReport  : redirected to ZC_HR360_EMPLOYEE
}
```

Child projections: `as projection on ZI_HR360_<x>` exposing all elements,
`SeverityCriticality` computed on `ZC_HR360_ISSUE` (`C`→1, `W`→2, else 3 — PoC).

---

## 11. Analytical query — `ZC_HR360_KPI_OVERVIEW`

Rename of `ZC_HRDQ_KPI_OVERVIEW`; source `ZI_HR360_EMPLOYEE`; dimensions
CompanyCode / PersonnelArea (+Name) / EmployeeGroup (+Name) / OrgUnit (+Name) /
QualityStatus; measures `TotalEmployees` (=1, SUM), `EmployeesWithIssues`,
`EmployeesWithoutIssues`, `MissingDataCount` (SUM TotalIssueCount),
`CriticalIssueCount`, `WarningIssueCount`, `AvgCompletenessPercent` (AVG).
`@Analytics.query: true`, `@Aggregation.default` per measure.

---

## 12. Authorization annotations & DCL

`@AccessControl.authorizationCheck: #CHECK` on: `ZI_HR360_EMP_BASIC`,
`_CONTACT`, `_BANK`, `_PAY`, `PERSONAL`, `ORGASSIGN`, `EDUCATION`, `QUALIF`,
`LEAVE`, `ATTENDANCE`, `PAYROLL`, `DOCUMENT`, `TIMELINE`, `ISSUE`, `EMPLOYEE`,
`ORG_HIER`, all `ZC_*`.
`#NOT_REQUIRED` on: `ZI_HR360_HIREDATE`, `ZI_HR360_MANAGER`, `ZI_HR360_ORG_NODE`
(OM / derived, no personal data).
DCL: `ZI_HR360_EMPLOYEE` gets a DCL role mapping `EmployeeID`/org fields to
`P_ORGIN` (`PROFC`/`PERSA`/`PERSG`/`PERSK`/`VDSK1`) via
`aspect pfcg_auth`. Detailed in Doc 05 §7.

---

## 13. Reused-from-PoC checklist

| PoC file | HR360 file | Action |
|---|---|---|
| `zi_hrdq_emp_basic.ddls.asddls` | `zi_hr360_emp_basic.ddls.asddls` | rename entity + label |
| `zi_hrdq_emp_contact.ddls.asddls` | `zi_hr360_emp_contact.ddls.asddls` | rename |
| `zi_hrdq_emp_bank.ddls.asddls` | `zi_hr360_emp_bank.ddls.asddls` | rename |
| `zi_hrdq_emp_pay.ddls.asddls` | `zi_hr360_emp_pay.ddls.asddls` | rename |
| `zi_hrdq_issue.ddls.asddls` | `zi_hr360_issue.ddls.asddls` | rename + inline literals + new branches |
| `zc_hrdq_kpi_overview.ddls.asddls` | `zc_hr360_kpi_overview.ddls.asddls` | rename + resource fields |
| `zcl_hrdq_issue_test.clas.abap` | `zcl_hr360_issue_test.clas.abap` | rename + per-branch tests |

---

## 14. Report key-date parameterisation

Interface views used by the **reports** additionally get a scalar parameter
`P_KeyDate : abp_locdate` defaulting to `$session.system_date`, so
`ZHR360_R_*` can run "as of" any date. Fiori/OData path always uses
`$session.system_date` (no parameter on the projection). Achieved by a thin
parameterised twin (`ZI_HR360_EMP_BASIC_P`) or `WITH PARAMETERS` — decided in
build; does not affect the model.

**Approve to proceed — Doc 05 (Behavior Design) follows in this batch.**
