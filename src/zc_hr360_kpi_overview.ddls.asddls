@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ KPI Overview'
@Metadata.allowExtensions: true

define view entity ZC_HR360_KPI_OVERVIEW
  as select from ZI_HR360_EMPLOYEE
{
  key CompanyCode                                            as CompanyCode,
  key PersonnelArea                                          as PersonnelArea,
  key EmployeeGroup                                          as EmployeeGroup,
  key OrgUnit                                                as OrgUnit,
  key QualityStatus                                          as QualityStatus,
      count( * )                                             as TotalEmployees,
      sum( case when TotalIssueCount = 0 then 1 else 0 end ) as EmployeesWithoutIssues,
      sum( case when TotalIssueCount > 0 then 1 else 0 end ) as EmployeesWithIssues,
      sum( TotalIssueCount )                                 as MissingDataCount,
      sum( CriticalIssueCount )                              as CriticalIssueCount,
      sum( WarningIssueCount )                               as WarningIssueCount,
      avg( CompletenessPercent as abap.dec( 5, 1 ) )         as AvgCompletenessPercent
}
group by
  CompanyCode,
  PersonnelArea,
  EmployeeGroup,
  OrgUnit,
  QualityStatus
