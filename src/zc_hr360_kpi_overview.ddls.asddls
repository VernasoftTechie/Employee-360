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

// Aggregated straight from the flat EMP_BASIC + EMP_KPI join (same pattern the
// executable reports use). Selecting from the fat ZI_HR360_EMPLOYEE and
// re-aggregating dumped at runtime (BUILD_ISSUES_LOG.md A28).

define view entity ZC_HR360_KPI_OVERVIEW
  as select from ZI_HR360_EMP_BASIC as b
    inner join ZI_HR360_EMP_KPI as k on k.EmployeeID = b.EmployeeID
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
  key b.CompanyCode                                              as CompanyCode,
      @UI.lineItem:       [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
  key b.PersonnelArea                                            as PersonnelArea,
      @UI.lineItem:       [{ position: 30 }]
      @UI.selectionField: [{ position: 30 }]
  key b.EmployeeGroup                                            as EmployeeGroup,
      @UI.lineItem:       [{ position: 40 }]
      @UI.selectionField: [{ position: 40 }]
  key b.OrgUnit                                                  as OrgUnit,
      @UI.lineItem:       [{ position: 50 }]
      @UI.selectionField: [{ position: 50 }]
  key case when k.CriticalIssueCount > 0 then 'CRITICAL'
           when k.TotalIssueCount    > 0 then 'WARNING'
           else 'OK' end                                         as QualityStatus,

      @UI.lineItem: [{ position: 60 }]
      count( * )                                                 as EmployeeCount,
      @UI.lineItem: [{ position: 70 }]
      sum( case when k.TotalIssueCount > 0 then 1 else 0 end )    as EmployeesWithIssues,
      @UI.lineItem: [{ position: 80 }]
      sum( k.TotalIssueCount )                                    as MissingDataCount,
      @UI.lineItem: [{ position: 90 }]
      sum( k.CriticalIssueCount )                                 as CriticalCount,
      @UI.lineItem: [{ position: 100 }]
      sum( k.WarningIssueCount )                                  as WarningCount,
      @UI.lineItem: [{ position: 110 }]
      avg( division( ( 12 - k.TotalIssueCount ) * 100, 12, 2 ) as abap.dec( 16, 2 ) ) as AvgCompleteness
}
group by
  b.CompanyCode,
  b.PersonnelArea,
  b.EmployeeGroup,
  b.OrgUnit,
  case when k.CriticalIssueCount > 0 then 'CRITICAL'
       when k.TotalIssueCount    > 0 then 'WARNING'
       else 'OK' end
