@AccessControl.authorizationCheck: #NOT_REQUIRED
// Row-level authorization is inherited: every UNION branch selects FROM the
// checked view ZI_HR360_EMP_BASIC, so only employees the caller's P_ORGIN
// permits are returned. The projection ZC_HR360_ISSUE is #CHECK.
@EndUserText.label: 'HR360 - Data Quality Issue'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

//----------------------------------------------------------------------------
// EXTENSIBLE CHECK FRAMEWORK (reused & extended from HR_DataQuality_RAP_PoC).
// Standard tables only - no catalog table; CheckID / Category / Severity /
// IssueDescription are CDS literals in each branch. One branch per check.
// Every branch must project the SAME element names/types (UNION rule).
// To add a check: copy a branch, change the literals + predicate, and bump the
// denominator "12" in ZI_HR360_EMPLOYEE.CompletenessPercent.
// ACTIVE BRANCH COUNT = 12
//----------------------------------------------------------------------------

define view entity ZI_HR360_ISSUE
  as select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                          as EmployeeID,
  key cast( 'MAND_DOB' as abap.char( 12 ) )                   as CheckID,
      cast( 'MANDATORY' as abap.char( 20 ) )                  as Category,
      cast( 'C' as abap.char( 1 ) )                           as Severity,
      cast( 'Date of birth is missing' as abap.char( 60 ) )   as IssueDescription,
      cast( 'DateOfBirth' as abap.char( 30 ) )                as FieldName
}
where Emp.DateOfBirth is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'MAND_GENDER' as abap.char( 12 ) )                as CheckID,
      cast( 'MANDATORY' as abap.char( 20 ) )                  as Category,
      cast( 'C' as abap.char( 1 ) )                           as Severity,
      cast( 'Gender is missing' as abap.char( 60 ) )          as IssueDescription,
      cast( 'Gender' as abap.char( 30 ) )                     as FieldName
}
where Emp.Gender is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'STAT_NATION' as abap.char( 12 ) )                as CheckID,
      cast( 'STATUTORY' as abap.char( 20 ) )                  as Category,
      cast( 'C' as abap.char( 1 ) )                           as Severity,
      cast( 'Nationality is missing' as abap.char( 60 ) )     as IssueDescription,
      cast( 'Nationality' as abap.char( 30 ) )                as FieldName
}
where Emp.Nationality is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'ORG_COSTCTR' as abap.char( 12 ) )                as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )             as Category,
      cast( 'C' as abap.char( 1 ) )                           as Severity,
      cast( 'Cost center assignment is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'CostCenter' as abap.char( 30 ) )                 as FieldName
}
where Emp.CostCenter is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'ORG_POSITION' as abap.char( 12 ) )               as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )             as Category,
      cast( 'C' as abap.char( 1 ) )                           as Severity,
      cast( 'Position is not assigned' as abap.char( 60 ) )   as IssueDescription,
      cast( 'Position' as abap.char( 30 ) )                   as FieldName
}
where Emp.Position is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_PAY as Pay on Pay.EmployeeID = Emp.EmployeeID
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'PAY_BASICPAY' as abap.char( 12 ) )               as CheckID,
      cast( 'PAYROLL_TIME' as abap.char( 20 ) )               as Category,
      cast( 'W' as abap.char( 1 ) )                           as Severity,
      cast( 'Basic pay record is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'BasicPay' as abap.char( 30 ) )                   as FieldName
}
where Pay.EmployeeID is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'CONTACT_MAIL' as abap.char( 12 ) )               as CheckID,
      cast( 'CONTACT' as abap.char( 20 ) )                    as Category,
      cast( 'W' as abap.char( 1 ) )                           as Severity,
      cast( 'Email address is missing' as abap.char( 60 ) )   as IssueDescription,
      cast( 'EmailAddress' as abap.char( 30 ) )               as FieldName
}
where Con.EmailAddress is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_BANK as Bnk on Bnk.EmployeeID = Emp.EmployeeID
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'BANK_IBAN' as abap.char( 12 ) )                  as CheckID,
      cast( 'BANK' as abap.char( 20 ) )                       as Category,
      cast( 'C' as abap.char( 1 ) )                           as Severity,
      cast( 'IBAN / bank details are missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'IBAN' as abap.char( 30 ) )                       as FieldName
}
where Bnk.IBAN is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EDUCATION as Edu on Edu.EmployeeID = Emp.EmployeeID
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'EDU_MISSING' as abap.char( 12 ) )                as CheckID,
      cast( 'EDUCATION' as abap.char( 20 ) )                  as Category,
      cast( 'W' as abap.char( 1 ) )                           as Severity,
      cast( 'No education record on file' as abap.char( 60 ) ) as IssueDescription,
      cast( 'Education' as abap.char( 30 ) )                   as FieldName
}
where Edu.EmployeeID is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_QUALIF as Qlf on Qlf.EmployeeID = Emp.EmployeeID
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'QUAL_MISSING' as abap.char( 12 ) )               as CheckID,
      cast( 'QUALIFICATION' as abap.char( 20 ) )              as Category,
      cast( 'W' as abap.char( 1 ) )                           as Severity,
      cast( 'No qualification or skill on file' as abap.char( 60 ) ) as IssueDescription,
      cast( 'Qualification' as abap.char( 30 ) )              as FieldName
}
where Qlf.EmployeeID is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'CONTACT_ADDR' as abap.char( 12 ) )               as CheckID,
      cast( 'CONTACT' as abap.char( 20 ) )                    as Category,
      cast( 'W' as abap.char( 1 ) )                           as Severity,
      cast( 'Permanent address is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'Address' as abap.char( 30 ) )                    as FieldName
}
where Con.Country is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
      Emp.EmployeeID                                          as EmployeeID,
      cast( 'INVALID_DOB' as abap.char( 12 ) )                as CheckID,
      cast( 'INVALID' as abap.char( 20 ) )                    as Category,
      cast( 'C' as abap.char( 1 ) )                           as Severity,
      cast( 'Date of birth is in the future' as abap.char( 60 ) ) as IssueDescription,
      cast( 'DateOfBirth' as abap.char( 30 ) )                as FieldName
}
where Emp.DateOfBirth > $session.system_date
  and Emp.DateOfBirth is not initial
