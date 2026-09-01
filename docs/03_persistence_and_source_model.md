# Employee-360 — Persistence & Source Model (Doc 03)

**Status:** DRAFT — awaiting approval (batch a: docs 03–08).
**Persistence owned by this project:** none. **Standard SAP tables only, read-only.**

This document is the field-level contract between SAP standard tables and the
`ZI_HR360_*` interface views. Column names here are the *source*; the CDS element
names are fixed in Doc 04.

---

## 1. Source Table Inventory

| Table | Text | Key (business) | Time-dep. | Used by |
|---|---|---|---|---|
| PA0000 | Actions | PERNR, SUBTY, BEGDA/ENDDA | yes | root (hire date, status), timeline |
| PA0001 | Org. Assignment | PERNR, BEGDA/ENDDA | yes | root, `_OrgAssignment`, `ZI_HR360_EMP_BASIC` |
| PA0002 | Personal Data | PERNR, BEGDA/ENDDA | yes | root, `_Personal`, `ZI_HR360_EMP_BASIC` |
| PA0006 | Addresses | PERNR, SUBTY, BEGDA/ENDDA | yes | `_Personal`, `ZI_HR360_EMP_CONTACT` |
| PA0009 | Bank Details | PERNR, SUBTY, BEGDA/ENDDA | yes | `_Personal`, `ZI_HR360_EMP_BANK` |
| PA0008 | Basic Pay | PERNR, BEGDA/ENDDA | yes | `_Payroll`, `ZI_HR360_EMP_PAY`, timeline |
| PA0022 | Education | PERNR, SUBTY, BEGDA/ENDDA, SEQNR | yes | `_Education`, timeline |
| PA0024 | Qualifications | PERNR, BEGDA/ENDDA, QUALI | yes | `_Qualification`, timeline |
| PA0105 | Communication | PERNR, SUBTY, BEGDA/ENDDA | yes | `_Personal`, `ZI_HR360_EMP_CONTACT` |
| PA2001 | Absences | PERNR, SUBTY, BEGDA/ENDDA | yes | `_LeaveBalance` (taken), timeline |
| PA2002 | Attendances | PERNR, SUBTY, BEGDA/ENDDA | yes | `_Attendance` |
| PA2006 | Absence Quotas | PERNR, SUBTY, DESTA/DEEND | yes | `_LeaveBalance` |
| HRP1000 | OM Object | PLVAR, OTYPE, OBJID, BEGDA/ENDDA | yes | `_OrgAssignment` (position/orgunit text), `_Qualification` (catalog), `ZI_HR360_ORG_HIER` |
| HRP1001 | OM Relationships | as above + RSIGN, RELAT, SCLAS, SOBID | yes | `ZI_HR360_ORG_HIER`, manager resolution |
| TOA01 | ArchiveLink links | SAP_OBJECT, OBJECT_ID, ARCHIV_ID, ARC_DOC_ID | no | `_Document` |
| TOAAT | ArchiveLink attributes | ARC_DOC_ID | no | `_Document` (title) |

### Text tables (all language-keyed on `SPRSL`/`SPRAS` = `$session.system_language`)

`T500P` (pers. area), `T501T` (EE group), `T503T` (EE subgroup), `T527X` (org
unit), `T528T` (position), `T513S` (job), `T517T`/`T517X` (education),
`T554T` (absence/attendance type), `T556B`/`T556A` (quota type), `T512T` (wage
type), `T529T` (action type), `T591S` (subtype texts).

---

## 2. The Anchor — `ZI_HR360_EMP_BASIC` (one row per active employee)

Reused from `ZI_HRDQ_EMP_BASIC`, renamed. Unchanged logic:

```
FROM pa0001 (OrgAssignment)
  INNER JOIN pa0002 (PersonalData)  on pernr, date-valid
  LEFT JOIN  t500p, t501t, t503t, t527x  (texts, language + date)
WHERE OrgAssignment date-valid on $session.system_date
```

Key: `EmployeeID = PA0001.PERNR`. This is the anchor for the root and every
`ZI_HR360_ISSUE` branch — guarantees "record missing entirely" is detectable, not
just "field blank". "Active" = has a date-valid PA0001 + PA0002 slice on the key
date; optionally further filtered by `PA0001.STAT2 = '3'` (active) — **default:
include all with a valid slice**, expose `EmploymentStatus` for the UI to filter.

---

## 3. Field Mapping — per interface view

### 3.1 `ZI_HR360_PERSONAL` (1:1)

| CDS element | Source | Filter |
|---|---|---|
| EmployeeID | PA0002.PERNR | date-valid |
| FirstName / LastName / SecondName | PA0002.VORNA / NACHN / NAME2 | |
| FormattedName | PA0002.VORNA `&&` `' '` `&&` PA0002.NACHN | |
| DateOfBirth / Gender / Nationality | PA0002.GBDAT / GESCH / NATIO | |
| MaritalStatus | PA0002.FAMST (+ T502T text) | |
| BirthPlace | PA0002.GBORT | |
| Street / City / PostalCode / Region / Country | PA0006 (SUBTY = `'1'` permanent) STRAS/ORT01/PSTLZ/STATE/LAND1 | SUBTY='1', date-valid |
| EmailAddress | PA0105 (SUBTY = `'0010'`) USRID_LONG | SUBTY='0010', date-valid |
| MobileNumber | PA0105 (SUBTY = `'0020'`) USRID_LONG | SUBTY='0020', date-valid |
| BankKey / BankAccount / IBAN / BankControlKey | PA0009 (SUBTY = `'0'` main) BANKL/BANKN/IBAN/BKONT | SUBTY='0', date-valid |
| HireDate | `min(PA0000.BEGDA)` where MASSN in (hiring actions) — see §3.9 | |

> **CONFIRM 7.1 (defaulted):** PA0105 subtypes `0010` email / `0020` mobile.

### 3.2 `ZI_HR360_ORGASSIGN` (1:1)

| CDS element | Source |
|---|---|
| EmployeeID | PA0001.PERNR (date-valid) |
| CompanyCode / PersonnelArea (+Name) / PersonnelSubarea | PA0001.BUKRS / WERKS (+T500P.NAME1) / BTRTL |
| EmployeeGroup (+Name) / EmployeeSubgroup (+Name) | PA0001.PERSG (+T501T.PTEXT) / PERSK (+T503T.PTEXT) |
| OrgUnit (+Name) | PA0001.ORGEH (+T527X.ORGTX, date+lang) |
| Position (+Name) | PA0001.PLANS (+HRP1000 STEXT where OTYPE='S', OBJID=PLANS, date+lang) |
| Job (+Name) | via HRP1001 S→C (`RELAT 007`) or PA0001.STELL (+T513S.STLTX) |
| CostCenter | PA0001.KOSTL |
| ManagerID / ManagerName | HRP1001 chief-position path (§3.8) → PERNR via HRP1001 S→P (`A008`) |
| OrgPath | derived text "CompanyCode / PersArea / OrgUnit / Position" |

### 3.3 `ZI_HR360_EDUCATION` (1:n, all slices)

| CDS element | Source |
|---|---|
| EmployeeID | PA0022.PERNR |
| EducationSeqNr | PA0022.SEQNR |
| EducationType (+Text) | PA0022.SLART (+T517T) |
| Establishment (+Text) | PA0022.SLABS (+T517X) / INSTITUTE |
| Certificate (+Text) | PA0022.SLTP1 (+T517X) |
| Discipline / Branch | PA0022.SLTP2 / FIELD |
| ValidFrom / ValidTo | PA0022.BEGDA / ENDDA |
| DurationYears | PA0022.ANZKL or derived |

> Exact PA0022 field usage is client-config dependent; Doc 04 pins the final set
> and any that resolve empty are simply blank columns.

### 3.4 `ZI_HR360_QUALIF` (1:n, all slices) — Skills **and** Certifications

| CDS element | Source |
|---|---|
| EmployeeID | PA0024.PERNR |
| QualificationID | PA0024.QUALI (8-char OM object id, OTYPE='Q') |
| QualificationText | HRP1000 STEXT where OTYPE='Q', OBJID=QUALI, date+lang |
| QualificationGroup (+Text) | HRP1001 Q→QK (`RELAT 002`) → HRP1000 STEXT |
| QualificationType | **derived**: `'CERT'` if group ∈ (certification groups) else `'SKILL'` — mapping constant in CDS (CONFIRM 7.3 defaulted: PA0024 only) |
| Proficiency / ProficiencyText | PA0024.AUSPR (+ scale text T77TS / HRP1032) |
| ValidFrom / ValidTo | PA0024.BEGDA / ENDDA (ValidTo doubles as "expiry") |
| IsExpired | `ValidTo < $session.system_date` |

> **CONFIRM 7.4 (defaulted):** OM qualifications catalog maintained. If not,
> QualificationText / Group resolve empty; ids + proficiency still shown.

### 3.5 `ZI_HR360_LEAVE` (1:n)

| CDS element | Source |
|---|---|
| EmployeeID | PA2006.PERNR |
| QuotaType (+Text) | PA2006.KTART (+T556B/T556A, lang) |
| DeductionFrom / DeductionTo | PA2006.DESTA / DEEND |
| Entitlement | PA2006.ANZHL |
| Deducted | PA2006.KVERB |
| Remaining | `PA2006.ANZHL - PA2006.KVERB` |
| Unit | `'days'` (or PA2006.QUOMO-based) |
| TakenThisYear | `sum(PA2001.ABWTG)` for absence subtypes in the current year (LEFT JOIN + GROUP BY, optional column) |

### 3.6 `ZI_HR360_ATTENDANCE` (1:n)

| CDS element | Source |
|---|---|
| EmployeeID | PA2002.PERNR |
| AttendanceFrom / AttendanceTo | PA2002.BEGDA / ENDDA |
| AttendanceType (+Text) | PA2002.AWART / SUBTY (+T554T, lang) |
| Days / Hours | PA2002.ABWTG / STDAZ |
| StartTime / EndTime | PA2002.BEGUZ / ENDUZ |

### 3.7 `ZI_HR360_PAYROLL` (1:n, all slices) — pay-scale / salary history

| CDS element | Source |
|---|---|
| EmployeeID | PA0008.PERNR |
| ValidFrom / ValidTo | PA0008.BEGDA / ENDDA |
| PayScaleType / Area / Group / Level | PA0008.TRFAR / TRFGB / TRFGR / TRFST |
| AnnualSalary | PA0008.ANSAL |
| Currency | PA0008.WAERS |
| CapacityUtilLevel | PA0008.BSGRD |
| WeeklyHours | PA0008.DIVGV |
| PayChangeReason (+Text) | PA0008.PREAS (+T539R) |

> Wage-type-level detail (PA0008 LGA01..40 / BET01..40) is **not** unpivoted in
> Phase 1 — would need a table function. Flagged in Doc 10, out of scope now.

### 3.8 `ZI_HR360_DOCUMENT` (1:n) — ArchiveLink metadata

| CDS element | Source |
|---|---|
| EmployeeID | `substring(TOA01.OBJECT_ID, 1, 8)` where `TOA01.SAP_OBJECT = 'PREL'` |
| ArchivDocID | TOA01.ARC_DOC_ID |
| ArchiveID | TOA01.ARCHIV_ID |
| DocumentType (+Text) | TOA01.AR_OBJECT (+TOAOM / T585T) |
| ArchiveDate | TOA01.AR_DATE |
| Title | TOAAT.DESCR |
| MimeType | TOAAT.MIMETYPE / derived from reserve |
| ContentLink | `@Semantics` — built client-side from ArchiveID + ArchivDocID |

> **CONFIRM 7.5 (defaulted):** ArchiveLink object `PREL`, `OBJECT_ID` leading 8
> chars = PERNR. If the client uses a different HR ArchiveLink object or key
> layout, only this view's WHERE/substring changes. If ArchiveLink is not
> configured, the view returns no rows (shell still ships).

### 3.9 `ZI_HR360_EMP_PAY` / hire date / status (root helpers)

- `ZI_HR360_EMP_PAY` (from PoC): PA0008 date-valid → TRFGR/TRFGB presence flag.
- **HireDate:** `min(PA0000.BEGDA)` where `MASSN` ∈ *hiring action types*. The
  hiring action set is client customizing (T529A `MASSN` with `MASSG`/feature).
  **Default:** `MASSN` in (`'01'`) — Doc 04 exposes it as a CDS constant list so
  a client can extend without touching logic.
- **EmploymentStatus:** `PA0001.STAT2` (0 withdrawn / 1 inactive / 2 retiree /
  3 active) + T529U-style text.

---

## 4. Organizational Hierarchy — `ZI_HR360_ORG_HIER`

`define hierarchy` source over HRP1001, plain-ABAP fallback in
`ZCL_HR360_ORG_READER` for deep traversal where the CDS hierarchy is not
sufficient (e.g. report programs).

| Node attribute | Source |
|---|---|
| NodeID | HRP1000.OBJID (OTYPE + OBJID) |
| NodeType | HRP1000.OTYPE (`O` org unit / `S` position / `P` person) |
| NodeText | HRP1000.STEXT (date + lang) |
| ParentNodeID | HRP1001 where RSIGN='A' RELAT='002'/'003' (reports-to / belongs-to), PLVAR='01', date-valid |
| HeadcountUnder | computed (hierarchy aggregate) |

Evaluation: start `OTYPE='O'` root(s), descend O→O (`003`), O→S (`003`),
S→P holder (`008`). `PLVAR` default `'01'`; `OTYPE` set and relationships are
CDS constants.

---

## 5. Common Rules

1. **Date validity:** every time-dependent table filtered
   `BEGDA <= @keydate AND ENDDA >= @keydate`; `@keydate` default
   `$session.system_date`, overridable by the report programs.
2. **Language:** all text joins on `SPRSL = $session.system_language`,
   `LEFT OUTER` (never drop a row for a missing translation).
3. **Client:** implicit (`@AbapCatalog` client-dependent); no `MANDT` in select
   lists.
4. **Authorization:** `@AccessControl.authorizationCheck: #CHECK` on every
   `ZI_HR360_*` that reads employee data; `#NOT_REQUIRED` only where there is no
   personal data. DCL — see Doc 05 §7.
5. **Absent source = empty view, never an error.** Each child view is
   independently activatable.
6. **No `SELECT` in loops, no native SQL** (Rulebook §5). The only ABAP-side data
   access is the RAP read handlers (single set reads) and `ZCL_HR360_ORG_READER`
   (bulk reads into internal tables).

---

## 6. Volume & Performance

| View | Row order of magnitude | Access pattern | Note |
|---|---|---|---|
| `ZI_HR360_EMP_BASIC` | active headcount | full scan on List Report page | HANA, acceptable; PoC-proven |
| `ZI_HR360_ISSUE` | headcount × active branches | driven from EMP_BASIC | each branch = 1 indexed infotype read on PERNR+date |
| `ZI_HR360_EMPLOYEE` root | = headcount | List Report + KPI GROUP BY | aggregation on DB, no ABAP loop |
| history children | slices per employee | RBA, single PERNR | negligible |
| `ZC_HR360_KPI_OVERVIEW` | aggregated | ALP query | runs `ZI_HR360_ISSUE` once, grouped |

Index reliance: standard PA infotype primary indexes (`PERNR` leading) cover all
access. No secondary indexes proposed (cannot add — standard tables).

**Approve to proceed to Doc 04 (CDS Design).**
