@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Data Quality KPI Overview'
@Metadata.allowExtensions: true
@Analytics.query: true
@VDM.viewType: #CONSUMPTION

// HR-wide data-quality analytics. Aggregates ZI_HR360_EMPLOYEE by legal entity /
// personnel area / employee group / org unit / quality status.

define view entity ZC_HR360_KPI_OVERVIEW
  as select from ZI_HR360_EMPLOYEE
{
      @AnalyticsDetails.query.axis: #ROWS
      CompanyCode,
      @AnalyticsDetails.query.axis: #ROWS
      PersonnelArea,
      PersonnelAreaName,
      @AnalyticsDetails.query.axis: #ROWS
      EmployeeGroup,
      EmployeeGroupName,
      @AnalyticsDetails.query.axis: #ROWS
      OrgUnit,
      OrgUnitName,
      QualityStatus,

      @DefaultAggregation: #SUM
      @EndUserText.label: 'Total Employees'
      cast( 1 as abap.int4 )                                             as TotalEmployees,

      @DefaultAggregation: #SUM
      @EndUserText.label: 'Employees Without Issues'
      case when TotalIssueCount = 0 then 1 else 0 end                    as EmployeesWithoutIssues,

      @DefaultAggregation: #SUM
      @EndUserText.label: 'Employees With Issues'
      case when TotalIssueCount > 0 then 1 else 0 end                    as EmployeesWithIssues,

      @DefaultAggregation: #SUM
      @EndUserText.label: 'Missing Data Count'
      TotalIssueCount                                                    as MissingDataCount,

      @DefaultAggregation: #SUM
      CriticalIssueCount,

      @DefaultAggregation: #SUM
      WarningIssueCount,

      @DefaultAggregation: #AVG
      @EndUserText.label: 'Average Completeness %'
      CompletenessPercent                                               as AvgCompletenessPercent
}
