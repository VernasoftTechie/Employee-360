@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ by Status'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Status', typeNamePlural: 'By Status' }
@UI.chart: [{ qualifier: 'S', chartType: #DONUT,
  dimensions: [ 'QualityStatus' ], measures: [ 'EmployeeCount' ] }]

define view entity ZC_HR360_DQ_BY_STATUS
  as select from ZI_HR360_EMP_BASIC as b
    inner join ZI_HR360_EMP_KPI as k on k.EmployeeID = b.EmployeeID
{
      @UI.lineItem: [{ position: 10 }]
  key k.QualityStatus                       as QualityStatus,
      @UI.lineItem: [{ position: 20 }]
      @Aggregation.default: #SUM
      cast( count( * ) as abap.int4 )        as EmployeeCount,
      max( k.QualityStatusCriticality )      as StatusCriticality
}
group by
  k.QualityStatus
