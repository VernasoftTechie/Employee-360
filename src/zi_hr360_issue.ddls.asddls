@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Data Quality Issue'
@Metadata.ignorePropagatedAnnotations: true

// Extensible check framework (from HR_DataQuality_RAP_PoC). No catalog table -
// literals per branch. Every UNION branch projects the SAME element names/types
// AND the SAME key markers (BUILD_ISSUES_LOG.md A5/A6). SeverityCriticality is a
// literal per branch (1=critical/red, 2=warning/orange) so the projection needs
// no CASE (A14). The dashboard classifies severity at RUNTIME from the user's
// choice (docs/16) - the Severity/SeverityCriticality literals here are only the
// default seed used by the Employee 360 object page.
// Org fields (CompanyCode..CostCenter) are projected on EVERY branch so the
// dashboard can group/filter failures by organisation without a join.
// ACTIVE BRANCH COUNT = 32  (catalogue CAT_2026_09, increment B).

define view entity ZI_HR360_ISSUE
  as select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                        as EmployeeID,
  key cast( 'MAND_DOB' as abap.char( 12 ) )                 as CheckID,
      cast( 'MANDATORY' as abap.char( 20 ) )                as Category,
      cast( 'C' as abap.char( 1 ) )                         as Severity,
      cast( 1 as abap.int4 )                                as SeverityCriticality,
      cast( 'Date of birth is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'DateOfBirth' as abap.char( 30 ) )              as FieldName,
      Emp.CompanyCode                                       as CompanyCode,
      Emp.PersonnelArea                                     as PersonnelArea,
      Emp.PersonnelSubarea                                  as PersonnelSubarea,
      Emp.EmployeeGroup                                     as EmployeeGroup,
      Emp.OrgUnit                                           as OrgUnit,
      Emp.CostCenter                                        as CostCenter
}
where Emp.DateOfBirth is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                  as EmployeeID,
  key cast( 'MAND_GENDER' as abap.char( 12 ) )        as CheckID,
      cast( 'MANDATORY' as abap.char( 20 ) )          as Category,
      cast( 'C' as abap.char( 1 ) )                   as Severity,
      cast( 1 as abap.int4 )                          as SeverityCriticality,
      cast( 'Gender is missing' as abap.char( 60 ) )  as IssueDescription,
      cast( 'Gender' as abap.char( 30 ) )             as FieldName,
      Emp.CompanyCode                                 as CompanyCode,
      Emp.PersonnelArea                               as PersonnelArea,
      Emp.PersonnelSubarea                            as PersonnelSubarea,
      Emp.EmployeeGroup                               as EmployeeGroup,
      Emp.OrgUnit                                     as OrgUnit,
      Emp.CostCenter                                  as CostCenter
}
where Emp.Gender is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                     as EmployeeID,
  key cast( 'STAT_NATION' as abap.char( 12 ) )           as CheckID,
      cast( 'STATUTORY' as abap.char( 20 ) )             as Category,
      cast( 'C' as abap.char( 1 ) )                      as Severity,
      cast( 1 as abap.int4 )                             as SeverityCriticality,
      cast( 'Nationality is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'Nationality' as abap.char( 30 ) )           as FieldName,
      Emp.CompanyCode                                    as CompanyCode,
      Emp.PersonnelArea                                  as PersonnelArea,
      Emp.PersonnelSubarea                              as PersonnelSubarea,
      Emp.EmployeeGroup                                  as EmployeeGroup,
      Emp.OrgUnit                                        as OrgUnit,
      Emp.CostCenter                                     as CostCenter
}
where Emp.Nationality is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                      as EmployeeID,
  key cast( 'ORG_COSTCTR' as abap.char( 12 ) )            as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )         as Category,
      cast( 'C' as abap.char( 1 ) )                       as Severity,
      cast( 1 as abap.int4 )                              as SeverityCriticality,
      cast( 'Cost center is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'CostCenter' as abap.char( 30 ) )             as FieldName,
      Emp.CompanyCode                                     as CompanyCode,
      Emp.PersonnelArea                                   as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                   as EmployeeGroup,
      Emp.OrgUnit                                         as OrgUnit,
      Emp.CostCenter                                      as CostCenter
}
where Emp.CostCenter is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ORG_POSITION' as abap.char( 12 ) )            as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )          as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'Position is not assigned' as abap.char( 60 ) ) as IssueDescription,
      cast( 'PositionId' as abap.char( 30 ) )              as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                                as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.PositionId is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_PAY as Pay on Pay.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'PAY_BASICPAY' as abap.char( 12 ) )            as CheckID,
      cast( 'PAYROLL' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Basic pay record is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'BasicPay' as abap.char( 30 ) )                as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                                as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Pay.EmployeeID is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'CONTACT_MAIL' as abap.char( 12 ) )            as CheckID,
      cast( 'CONTACT' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Email address is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'EmailAddress' as abap.char( 30 ) )            as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Con.EmailAddress is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_BANK as Bnk on Bnk.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'BANK_IBAN' as abap.char( 12 ) )               as CheckID,
      cast( 'BANK' as abap.char( 20 ) )                    as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'IBAN / bank details missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'IBAN' as abap.char( 30 ) )                    as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Bnk.IBAN is initial
  and ( Bnk.BankKey is initial or Bnk.BankAccount is initial )

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EDUCATION as Edu on Edu.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'EDU_MISSING' as abap.char( 12 ) )             as CheckID,
      cast( 'EDUCATION' as abap.char( 20 ) )               as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'No education record on file' as abap.char( 60 ) ) as IssueDescription,
      cast( 'Education' as abap.char( 30 ) )               as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Edu.EmployeeID is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_QUALIF as Qlf on Qlf.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'QUAL_MISSING' as abap.char( 12 ) )            as CheckID,
      cast( 'QUALIFICATION' as abap.char( 20 ) )           as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'No qualification on file' as abap.char( 60 ) ) as IssueDescription,
      cast( 'Qualification' as abap.char( 30 ) )           as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Qlf.EmployeeID is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'CONTACT_ADDR' as abap.char( 12 ) )            as CheckID,
      cast( 'CONTACT' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Address is missing' as abap.char( 60 ) )      as IssueDescription,
      cast( 'Address' as abap.char( 30 ) )                 as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Con.Country is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'INVALID_DOB' as abap.char( 12 ) )             as CheckID,
      cast( 'INVALID' as abap.char( 20 ) )                 as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'Date of birth is in the future' as abap.char( 60 ) ) as IssueDescription,
      cast( 'DateOfBirth' as abap.char( 30 ) )             as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.DateOfBirth > $session.system_date
  and Emp.DateOfBirth is not initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'PERS_LASTNM' as abap.char( 12 ) )             as CheckID,
      cast( 'PERSONAL' as abap.char( 20 ) )                as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'Last name is missing' as abap.char( 60 ) )    as IssueDescription,
      cast( 'LastName' as abap.char( 30 ) )                as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.LastName is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'PERS_FIRSTN' as abap.char( 12 ) )             as CheckID,
      cast( 'PERSONAL' as abap.char( 20 ) )                as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'First name is missing' as abap.char( 60 ) )   as IssueDescription,
      cast( 'FirstName' as abap.char( 30 ) )               as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.FirstName is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ORG_ORGUNIT' as abap.char( 12 ) )             as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )          as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'Organizational unit is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'OrgUnit' as abap.char( 30 ) )                 as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.OrgUnit is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ORG_JOB' as abap.char( 12 ) )                 as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )          as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Job is not assigned' as abap.char( 60 ) )     as IssueDescription,
      cast( 'Job' as abap.char( 30 ) )                     as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.Job is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ORG_EEGROUP' as abap.char( 12 ) )             as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )          as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'Employee group/subgroup missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'EmployeeGroup' as abap.char( 30 ) )           as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.EmployeeGroup is initial
   or Emp.EmployeeSubgroup is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ORG_PSUBAREA' as abap.char( 12 ) )            as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )          as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Personnel subarea is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'PersonnelSubarea' as abap.char( 30 ) )        as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.PersonnelSubarea is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_PAY as Pay on Pay.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'PSCL_TYPE' as abap.char( 12 ) )               as CheckID,
      cast( 'PAYROLL' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Pay scale type/area is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'PayScaleType' as abap.char( 30 ) )            as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Pay.EmployeeID is not initial
  and ( Pay.PayScaleType is initial or Pay.PayScaleArea is initial )

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_PAY as Pay on Pay.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'PSCL_GRP' as abap.char( 12 ) )                as CheckID,
      cast( 'PAYROLL' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Pay scale group/level is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'PayScaleGroup' as abap.char( 30 ) )           as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Pay.EmployeeID is not initial
  and ( Pay.PayScaleGroup is initial or Pay.PayScaleLevel is initial )

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'COMM_MOBILE' as abap.char( 12 ) )             as CheckID,
      cast( 'CONTACT' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Mobile number is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'MobileNumber' as abap.char( 30 ) )            as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Con.MobileNumber is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'PERS_MARITAL' as abap.char( 12 ) )            as CheckID,
      cast( 'PERSONAL' as abap.char( 20 ) )                as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Marital status is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'MaritalStatus' as abap.char( 30 ) )           as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.MaritalStatus is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'PERS_LANG' as abap.char( 12 ) )               as CheckID,
      cast( 'PERSONAL' as abap.char( 20 ) )                as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Language key is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'LanguageKey' as abap.char( 30 ) )             as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.LanguageKey is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ORG_ADMIN' as abap.char( 12 ) )               as CheckID,
      cast( 'ORG_ASSIGNMENT' as abap.char( 20 ) )          as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'No HR administrator assigned' as abap.char( 60 ) ) as IssueDescription,
      cast( 'HrAdmin' as abap.char( 30 ) )                 as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Emp.HrAdmin is initial
  and Emp.PayrollAdmin is initial
  and Emp.TimeAdmin is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_BANK as Bnk on Bnk.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'BANK_PAYMETH' as abap.char( 12 ) )            as CheckID,
      cast( 'BANK' as abap.char( 20 ) )                    as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'Payment method is missing' as abap.char( 60 ) ) as IssueDescription,
      cast( 'PaymentMethod' as abap.char( 30 ) )           as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Bnk.EmployeeID is not initial
  and Bnk.PaymentMethod is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ADDR_STREET' as abap.char( 12 ) )             as CheckID,
      cast( 'CONTACT' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Street is missing' as abap.char( 60 ) )       as IssueDescription,
      cast( 'Street' as abap.char( 30 ) )                  as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Con.Country is not initial
  and Con.Street is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ADDR_CITY' as abap.char( 12 ) )               as CheckID,
      cast( 'CONTACT' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'City is missing' as abap.char( 60 ) )         as IssueDescription,
      cast( 'City' as abap.char( 30 ) )                    as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Con.Country is not initial
  and Con.City is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_EMP_CONTACT as Con on Con.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'ADDR_POSTAL' as abap.char( 12 ) )             as CheckID,
      cast( 'CONTACT' as abap.char( 20 ) )                 as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'Postal code is missing' as abap.char( 60 ) )  as IssueDescription,
      cast( 'PostalCode' as abap.char( 30 ) )              as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Con.Country is not initial
  and Con.PostalCode is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_QUAL_STATUS as Qs on Qs.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'QUAL_EXPIRED' as abap.char( 12 ) )            as CheckID,
      cast( 'QUALIFICATION' as abap.char( 20 ) )           as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'All qualifications have expired' as abap.char( 60 ) ) as IssueDescription,
      cast( 'Qualification' as abap.char( 30 ) )           as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Qs.TotalQuals > 0
  and Qs.CurrentQuals = 0

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_LEAVE as Lv on Lv.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'LEAVE_NOQUOTA' as abap.char( 12 ) )           as CheckID,
      cast( 'LEAVE' as abap.char( 20 ) )                   as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'No leave quota on file' as abap.char( 60 ) )  as IssueDescription,
      cast( 'LeaveQuota' as abap.char( 30 ) )              as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Lv.EmployeeID is initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_LEAVE_NEG as Ln on Ln.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'LEAVE_NEGBAL' as abap.char( 12 ) )            as CheckID,
      cast( 'LEAVE' as abap.char( 20 ) )                   as Category,
      cast( 'C' as abap.char( 1 ) )                        as Severity,
      cast( 1 as abap.int4 )                               as SeverityCriticality,
      cast( 'Leave balance is negative' as abap.char( 60 ) ) as IssueDescription,
      cast( 'LeaveBalance' as abap.char( 30 ) )            as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Ln.EmployeeID is not initial

union all
  select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_DOCUMENT as Doc on Doc.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
  key cast( 'DOC_NONE' as abap.char( 12 ) )                as CheckID,
      cast( 'DOCUMENT' as abap.char( 20 ) )                as Category,
      cast( 'W' as abap.char( 1 ) )                        as Severity,
      cast( 2 as abap.int4 )                               as SeverityCriticality,
      cast( 'No personnel documents on file' as abap.char( 60 ) ) as IssueDescription,
      cast( 'Documents' as abap.char( 30 ) )               as FieldName,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                               as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.CostCenter                                       as CostCenter
}
where Doc.EmployeeID is initial
