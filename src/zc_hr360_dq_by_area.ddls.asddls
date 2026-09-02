@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ by Area'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Area', typeNamePlural: 'By Personnel Area' }
@UI.chart: [{ qualifier: 'A', chartType: #BAR,
  dimensions: [ 'PersonnelArea' ], measures: [ 'AvgCompleteness' ] }]
@UI.presentationVariant: [{ sortOrder: [{ by: 'AvgCompleteness', direction: #ASC }],
  visualizations: [{ type: #AS_CHART, qualifier: 'A' }, { type: #AS_LINEITEM }] }]

define view entity ZC_HR360_DQ_BY_AREA
  as select from ZI_HR360_EMP_BASIC as b
    inner join ZI_HR360_EMP_KPI as k on k.EmployeeID = b.EmployeeID
{
      @UI.lineItem: [{ position: 10 }]
  key b.CompanyCode                          as CompanyCode,
      @UI.lineItem: [{ position: 20 }]
  key b.PersonnelArea                        as PersonnelArea,
      @UI.lineItem: [{ position: 30 }]
      @Aggregation.default: #SUM
      cast( count( * ) as abap.int4 )        as EmployeeCount,
      @UI.lineItem: [{ position: 40 }]
      @Aggregation.default: #SUM
      cast( sum( k.CriticalIssueCount ) as abap.int4 ) as CriticalCount,
      @UI.lineItem: [{ position: 50 }]
      cast( division( sum( 12 - k.TotalIssueCount ) * 100,
                      count( * ) * 12, 1 ) as abap.dec( 5, 1 ) ) as AvgCompleteness
}
group by
  b.CompanyCode,
  b.PersonnelArea
