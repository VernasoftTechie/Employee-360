@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee Basic (anchor)'
@Metadata.ignorePropagatedAnnotations: true

// Anchor: one row per employee with a date-valid PA0001 + PA0002 slice.
// Raw infotype fields only. Text-table joins removed after repeated
// "column unknown" errors - see docs/BUILD_ISSUES_LOG.md A10.

define view entity ZI_HR360_EMP_BASIC
  as select from pa0001 as O
    inner join pa0002 as P on  P.pernr = O.pernr
                           and P.begda <= $session.system_date
                           and P.endda >= $session.system_date
{
  key O.pernr    as EmployeeID,
      O.bukrs    as CompanyCode,
      O.werks    as PersonnelArea,
      O.btrtl    as PersonnelSubarea,
      O.persg    as EmployeeGroup,
      O.persk    as EmployeeSubgroup,
      O.orgeh    as OrgUnit,
      O.kostl    as CostCenter,
      O.plans    as Position,
      O.stell    as Job,
      O.stat2    as EmploymentStatus,
      P.nachn    as LastName,
      P.vorna    as FirstName,
      P.gbdat    as DateOfBirth,
      P.gesch    as Gender,
      P.natio    as Nationality
}
where O.begda <= $session.system_date
  and O.endda >= $session.system_date
