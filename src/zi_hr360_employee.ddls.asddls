@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee (root)'
@Metadata.ignorePropagatedAnnotations: true

// Minimal viable root: Personal + OrgAssignment flattened in (LEFT JOIN), plus
// the data-quality KPI counts and hire date. Detail children (education, leave,
// ...) are added back one at a time - see docs/BUILD_ISSUES_LOG.md A18.

define view entity ZI_HR360_EMPLOYEE
  as select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_PERSONAL as Per on Per.EmployeeID = Emp.EmployeeID
    left outer join ZI_HR360_EMP_KPI  as Kpi on Kpi.EmployeeID = Emp.EmployeeID
    left outer join ZI_HR360_HIREDATE as Hd  on Hd.EmployeeID  = Emp.EmployeeID
{
  key Emp.EmployeeID                                       as EmployeeID,
      Emp.LastName                                         as LastName,
      Emp.FirstName                                        as FirstName,
      concat( concat( Emp.FirstName, ' ' ), Emp.LastName ) as FormattedName,
      Emp.DateOfBirth                                      as DateOfBirth,
      Emp.Gender                                           as Gender,
      Emp.Nationality                                      as Nationality,
      cast( '' as abap.char( 2 ) )                         as EmploymentStatus,
      Hd.HireDate                                          as HireDate,
      Emp.CompanyCode                                      as CompanyCode,
      Emp.PersonnelArea                                    as PersonnelArea,
      Emp.PersonnelSubarea                                 as PersonnelSubarea,
      Emp.EmployeeGroup                                    as EmployeeGroup,
      Emp.EmployeeSubgroup                                 as EmployeeSubgroup,
      Emp.OrgUnit                                          as OrgUnit,
      Emp.PositionId                                       as PositionId,
      Emp.CostCenter                                       as CostCenter,
      Emp.Job                                              as Job,

      Per.BirthPlace                                       as BirthPlace,
      Per.MaritalStatus                                    as MaritalStatus,
      Per.Street                                           as Street,
      Per.City                                             as City,
      Per.PostalCode                                       as PostalCode,
      Per.Country                                          as Country,
      Per.EmailAddress                                     as EmailAddress,
      Per.MobileNumber                                     as MobileNumber,
      Per.IBAN                                             as IBAN,

      coalesce( Kpi.TotalIssueCount,    0 )                as TotalIssueCount,
      coalesce( Kpi.CriticalIssueCount, 0 )                as CriticalIssueCount,
      coalesce( Kpi.WarningIssueCount,  0 )                as WarningIssueCount,

      case
        when coalesce( Kpi.CriticalIssueCount, 0 ) > 0 then cast( 'CRITICAL' as abap.char( 8 ) )
        when coalesce( Kpi.TotalIssueCount,    0 ) > 0 then cast( 'WARNING'  as abap.char( 8 ) )
        else cast( 'OK' as abap.char( 8 ) )
      end                                                       as QualityStatus,

      case
        when coalesce( Kpi.CriticalIssueCount, 0 ) > 0 then cast( 1 as abap.int4 )
        when coalesce( Kpi.TotalIssueCount,    0 ) > 0 then cast( 2 as abap.int4 )
        else cast( 3 as abap.int4 )
      end                                                       as QualityStatusCriticality,

      cast( division( ( 12 - coalesce( Kpi.TotalIssueCount, 0 ) ) * 100, 12, 1 ) as abap.dec( 5, 1 ) ) as CompletenessPercent
}
