@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ KPI Overview'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'KPI Row', typeNamePlural: 'Data Quality KPIs' }
@UI.chart: [
  { qualifier: 'ByStatus', chartType: #DONUT,
    dimensions: [ 'QualityStatus' ], measures: [ 'EmployeeCount' ] },
  { qualifier: 'ByArea', chartType: #BAR,
    dimensions: [ 'PersonnelArea' ], measures: [ 'AvgCompleteness' ] }
]
@UI.presentationVariant: [{
  sortOrder: [{ by: 'EmployeeCount', direction: #DESC }],
  visualizations: [{ type: #AS_CHART, qualifier: 'ByStatus' }, { type: #AS_LINEITEM }]
}]

// Plain pre-aggregated view (grain = company / pers.area / EE group / org unit /
// status). No @Analytics.query - kept simple after earlier analytical-query
// activation trouble (BUILD_ISSUES_LOG.md A18). Fiori still renders @UI.chart
// from the pre-grouped rows.

define view entity ZC_HR360_KPI_OVERVIEW
  as select from ZI_HR360_EMPLOYEE
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
  key CompanyCode                                        as CompanyCode,
      @UI.lineItem:       [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
  key PersonnelArea                                      as PersonnelArea,
      @UI.lineItem:       [{ position: 30 }]
      @UI.selectionField: [{ position: 30 }]
  key EmployeeGroup                                      as EmployeeGroup,
      @UI.lineItem:       [{ position: 40 }]
      @UI.selectionField: [{ position: 40 }]
  key OrgUnit                                            as OrgUnit,
      @UI.lineItem:       [{ position: 50 }]
      @UI.selectionField: [{ position: 50 }]
  key QualityStatus                                     as QualityStatus,

      @UI.lineItem: [{ position: 60 }]
      count( * )                                         as EmployeeCount,
      @UI.lineItem: [{ position: 70 }]
      sum( case when TotalIssueCount > 0 then 1 else 0 end ) as EmployeesWithIssues,
      @UI.lineItem: [{ position: 80 }]
      sum( TotalIssueCount )                             as MissingDataCount,
      @UI.lineItem: [{ position: 90 }]
      sum( CriticalIssueCount )                          as CriticalCount,
      @UI.lineItem: [{ position: 100 }]
      sum( WarningIssueCount )                           as WarningCount,
      @UI.lineItem: [{ position: 110 }]
      avg( CompletenessPercent as abap.dec( 5, 1 ) )     as AvgCompleteness
}
group by
  CompanyCode,
  PersonnelArea,
  EmployeeGroup,
  OrgUnit,
  QualityStatus
