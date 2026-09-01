@AccessControl.authorizationCheck: #NOT_REQUIRED
// Row-level authorization is inherited: every UNION branch selects FROM the
// checked view ZI_HR360_EMP_BASIC, so only employees the caller's P_ORGIN
// permits are ever returned. The projection ZC_HR360_ISSUE is #CHECK.
@EndUserText.label: 'HR360 - Data Quality Issue'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

//----------------------------------------------------------------------------
// THE EXTENSIBLE CHECK FRAMEWORK  (reused & extended from HR_DataQuality_RAP_PoC)
//
// Each UNION ALL branch = one HR data-quality check. Standard tables only:
// there is NO catalog table - CheckID / Category / Severity / IssueDescription
// are CDS literals in the branch itself.
//
// Every branch:
//   1. FROM ZI_HR360_EMP_BASIC  (one row per active employee -> "record missing
//      entirely" is caught, not only "field blank")
//   2. optional LEFT OUTER JOIN to the domain view holding the field
//   3. WHERE <field> IS INITIAL   (or an invalid-value predicate)
//
// TO ADD A CHECK: copy one branch, change the literals + predicate, and bump
// ZI_HR360_ISSUE_CONST.branch_count (used by CompletenessPercent in the root).
// No other object changes - not the root, behavior, service or UI.
//
// ACTIVE BRANCH COUNT = 12
//----------------------------------------------------------------------------

define view entity ZI_HR360_ISSUE
  as select from ZI_HR360_EMP_BASIC as Emp
  where Emp.DateOfBirth is initial
{
  key Emp.EmployeeID                                   as EmployeeID,
  key cast( 'MAND_DOB' as abap.char( 12 ) )            as CheckID,
      cast( 'MANDATORY' as abap.char( 20 ) )           as Category,
      cast( 'C' as abap.char( 1 ) )                    as Severity,
      cast( 'Date of birth is missing' as abap.char( 60 ) )       as IssueDescription,
      cast( 'DateOfBirth' as abap.char( 30 ) )         as FieldName
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
  where Emp.Gender is initial
{
  key Emp.EmployeeID,
  key cast( 'MAND_GENDER' as abap.char( 12 ) ),
      cast( 'MANDATORY' as abap.char( 20 ) ),
      cast( 'C' as abap.char( 1 ) ),
      cast( 'Gender is missing' as abap.char( 60 ) ),
      cast( 'Gender' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
  where Emp.Nationality is initial
{
  key Emp.EmployeeID,
  key cast( 'STAT_NATION' as abap.char( 12 ) ),
      cast( 'STATUTORY' as abap.char( 20 ) ),
      cast( 'C' as abap.char( 1 ) ),
      cast( 'Nationality is missing' as abap.char( 60 ) ),
      cast( 'Nationality' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
  where Emp.CostCenter is initial
{
  key Emp.EmployeeID,
  key cast( 'ORG_COSTCTR' as abap.char( 12 ) ),
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) ),
      cast( 'C' as abap.char( 1 ) ),
      cast( 'Cost center assignment is missing' as abap.char( 60 ) ),
      cast( 'CostCenter' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
  where Emp.Position is initial
{
  key Emp.EmployeeID,
  key cast( 'ORG_POSITION' as abap.char( 12 ) ),
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) ),
      cast( 'C' as abap.char( 1 ) ),
      cast( 'Position is not assigned' as abap.char( 60 ) ),
      cast( 'Position' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_PAY as Pay on Pay.EmployeeID = Emp.EmployeeID
  where Pay.EmployeeID is initial
{
  key Emp.EmployeeID,
  key cast( 'PAY_BASICPAY' as abap.char( 12 ) ),
      cast( 'PAYROLL_TIME' as abap.char( 20 ) ),
      cast( 'W' as abap.char( 1 ) ),
      cast( 'Basic pay record is missing' as abap.char( 60 ) ),
      cast( 'BasicPay' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
  where Con.EmailAddress is initial
{
  key Emp.EmployeeID,
  key cast( 'CONTACT_MAIL' as abap.char( 12 ) ),
      cast( 'CONTACT' as abap.char( 20 ) ),
      cast( 'W' as abap.char( 1 ) ),
      cast( 'Email address is missing' as abap.char( 60 ) ),
      cast( 'EmailAddress' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_BANK as Bnk on Bnk.EmployeeID = Emp.EmployeeID
  where Bnk.IBAN is initial
{
  key Emp.EmployeeID,
  key cast( 'BANK_IBAN' as abap.char( 12 ) ),
      cast( 'BANK' as abap.char( 20 ) ),
      cast( 'C' as abap.char( 1 ) ),
      cast( 'IBAN / bank details are missing' as abap.char( 60 ) ),
      cast( 'IBAN' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EDUCATION as Edu on Edu.EmployeeID = Emp.EmployeeID
  where Edu.EmployeeID is initial
{
  key Emp.EmployeeID,
  key cast( 'EDU_MISSING' as abap.char( 12 ) ),
      cast( 'EDUCATION' as abap.char( 20 ) ),
      cast( 'W' as abap.char( 1 ) ),
      cast( 'No education record on file' as abap.char( 60 ) ),
      cast( 'Education' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_QUALIF as Qlf on Qlf.EmployeeID = Emp.EmployeeID
  where Qlf.EmployeeID is initial
{
  key Emp.EmployeeID,
  key cast( 'QUAL_MISSING' as abap.char( 12 ) ),
      cast( 'QUALIFICATION' as abap.char( 20 ) ),
      cast( 'W' as abap.char( 1 ) ),
      cast( 'No qualification or skill on file' as abap.char( 60 ) ),
      cast( 'Qualification' as abap.char( 30 ) )
}

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
  where Con.Country is initial
{
  key Emp.EmployeeID,
  key cast( 'CONTACT_ADDR' as abap.char( 12 ) ),
      cast( 'CONTACT' as abap.char( 20 ) ),
      cast( 'W' as abap.char( 1 ) ),
      cast( 'Permanent address is missing' as abap.char( 60 ) ),
      cast( 'Address' as abap.char( 30 ) )
}

union all
  // invalid-value check (kept from the PoC) - framework covers consistency, not only completeness
  select from ZI_HR360_EMP_BASIC as Emp
  where Emp.DateOfBirth > $session.system_date
    and Emp.DateOfBirth is not initial
{
  key Emp.EmployeeID,
  key cast( 'INVALID_DOB' as abap.char( 12 ) ),
      cast( 'INVALID' as abap.char( 20 ) ),
      cast( 'C' as abap.char( 1 ) ),
      cast( 'Date of birth is in the future' as abap.char( 60 ) ),
      cast( 'DateOfBirth' as abap.char( 30 ) )
}
