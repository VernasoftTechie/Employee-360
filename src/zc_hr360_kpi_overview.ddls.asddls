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

// Aggregated from the flat EMP_BASIC join EMP_KPI. All measures explicitly cast
// (HANA sum/avg return wide types SADL can't map -> RAISE_SHORTDUMP, A28).
// QualityStatus is a plain field from EMP_KPI, so it groups cleanly (A29: a CASE
// expression cannot be a key element / group-by term here).

define view entity ZC_HR360_KPI_OVERVIEW
  as select from ZI_HR360_EMP_BASIC as b
    inner join ZI_HR360_EMP_KPI as k on k.EmployeeID = b.EmployeeID
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
  key b.CompanyCode                                                     as CompanyCode,
      @UI.lineItem:       [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
  key b.PersonnelArea                                                   as PersonnelArea,
      @UI.lineItem:       [{ position: 30 }]
      @UI.selectionField: [{ position: 30 }]
  key b.EmployeeGroup                                                   as EmployeeGroup,
      @UI.lineItem:       [{ position: 40 }]
      @UI.selectionField: [{ position: 40 }]
  key b.OrgUnit                                                         as OrgUnit,
      @UI.lineItem:       [{ position: 50 }]
      @UI.selectionField: [{ position: 50 }]
  key k.QualityStatus                                                   as QualityStatus,

      @UI.lineItem: [{ position: 60 }]
      @Aggregation.default: #SUM
      cast( count( * ) as abap.int4 )                                   as EmployeeCount,
      @UI.lineItem: [{ position: 70 }]
      @Aggregation.default: #SUM
      cast( sum( case when k.TotalIssueCount > 0 then 1 else 0 end ) as abap.int4 ) as EmployeesWithIssues,
      @UI.lineItem: [{ position: 80 }]
      @Aggregation.default: #SUM
      cast( sum( k.TotalIssueCount ) as abap.int4 )                     as MissingDataCount,
      @UI.lineItem: [{ position: 90 }]
      @Aggregation.default: #SUM
      cast( sum( k.CriticalIssueCount ) as abap.int4 )                  as CriticalCount,
      @UI.lineItem: [{ position: 100 }]
      @Aggregation.default: #SUM
      cast( sum( k.WarningIssueCount ) as abap.int4 )                   as WarningCount,
      @UI.lineItem: [{ position: 110 }]
      @Aggregation.default: #AVG
      cast( division( sum( 12 - k.TotalIssueCount ) * 100,
                      count( * ) * 12, 2 ) as abap.dec( 6, 2 ) )        as AvgCompleteness
}
group by
  b.CompanyCode,
  b.PersonnelArea,
  b.EmployeeGroup,
  b.OrgUnit,
  k.QualityStatus
