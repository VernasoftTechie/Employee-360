@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ KPI Overview'
@Metadata.allowExtensions: true
@Analytics.query: true
@ObjectModel.usageType: { serviceQuality: #A, sizeCategory: #M, dataClass: #MIXED }
@UI.headerInfo: { typeName: 'KPI Row', typeNamePlural: 'Data Quality KPIs' }
@UI.chart: [
  { qualifier: 'ByStatus', chartType: #DONUT,
    dimensions: [ 'QualityStatus' ], measures: [ 'EmployeeCount' ] },
  { qualifier: 'ByArea', chartType: #BAR,
    dimensions: [ 'PersonnelArea' ], measures: [ 'AvgCompleteness' ],
    measureAttributes: [{ measure: 'AvgCompleteness', role: #AXIS_1 }] }
]
@UI.presentationVariant: [{
  sortOrder: [{ by: 'EmployeeCount', direction: #DESC }],
  visualizations: [{ type: #AS_CHART, qualifier: 'ByStatus' }, { type: #AS_LINEITEM }]
}]

define view entity ZC_HR360_KPI_OVERVIEW
  as select from ZI_HR360_EMP_BASIC as b
    inner join ZI_HR360_EMP_KPI as k on k.EmployeeID = b.EmployeeID
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
      @AnalyticsDetails.query.axis: #ROWS
      b.CompanyCode                          as CompanyCode,
      @UI.lineItem:       [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
      @AnalyticsDetails.query.axis: #ROWS
      b.PersonnelArea                        as PersonnelArea,
      @UI.lineItem:       [{ position: 30 }]
      @UI.selectionField: [{ position: 30 }]
      @AnalyticsDetails.query.axis: #FREE
      b.EmployeeGroup                        as EmployeeGroup,
      @UI.lineItem:       [{ position: 40 }]
      @UI.selectionField: [{ position: 40 }]
      @AnalyticsDetails.query.axis: #FREE
      b.OrgUnit                              as OrgUnit,
      @UI.lineItem:       [{ position: 50 }]
      @UI.selectionField: [{ position: 50 }]
      @AnalyticsDetails.query.axis: #COLUMNS
      k.QualityStatus                        as QualityStatus,

      @UI.lineItem: [{ position: 60 }]
      @DefaultAggregation: #SUM
      cast( 1 as abap.int4 )                 as EmployeeCount,
      @UI.lineItem: [{ position: 70 }]
      @DefaultAggregation: #SUM
      case when k.TotalIssueCount > 0 then cast( 1 as abap.int4 ) else cast( 0 as abap.int4 ) end as EmployeesWithIssues,
      @UI.lineItem: [{ position: 80 }]
      @DefaultAggregation: #SUM
      k.TotalIssueCount                      as MissingDataCount,
      @UI.lineItem: [{ position: 90 }]
      @DefaultAggregation: #SUM
      k.CriticalIssueCount                   as CriticalCount,
      @UI.lineItem: [{ position: 100 }]
      @DefaultAggregation: #SUM
      k.WarningIssueCount                    as WarningCount,
      @UI.lineItem: [{ position: 110 }]
      @DefaultAggregation: #AVG
      k.CompletenessPercent                  as AvgCompleteness
}
