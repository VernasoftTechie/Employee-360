@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Data Quality KPI Overview'
@Metadata.allowExtensions: true

// HR-wide data-quality KPIs, aggregated from ZI_HR360_EMPLOYEE by legal entity /
// personnel area / employee group / org unit / quality status. Plain aggregating
// view (no @Analytics.query) so it activates on any release; App 2 consumes it
// as a List Report / chart.

define view entity ZC_HR360_KPI_OVERVIEW
  as select from ZI_HR360_EMPLOYEE
{
  key CompanyCode                                             as CompanyCode,
  key PersonnelArea                                           as PersonnelArea,
  key EmployeeGroup                                           as EmployeeGroup,
  key OrgUnit                                                 as OrgUnit,
  key QualityStatus                                           as QualityStatus,
      max( PersonnelAreaName )                                as PersonnelAreaName,
      max( OrgUnitName )                                      as OrgUnitName,
      count( * )                                              as TotalEmployees,
      sum( case when TotalIssueCount = 0 then 1 else 0 end )  as EmployeesWithoutIssues,
      sum( case when TotalIssueCount > 0 then 1 else 0 end )  as EmployeesWithIssues,
      sum( TotalIssueCount )                                  as MissingDataCount,
      sum( CriticalIssueCount )                               as CriticalIssueCount,
      sum( WarningIssueCount )                                as WarningIssueCount,
      avg( CompletenessPercent as abap.dec( 5, 1 ) )          as AvgCompletenessPercent
}
group by
  CompanyCode,
  PersonnelArea,
  EmployeeGroup,
  OrgUnit,
  QualityStatus
