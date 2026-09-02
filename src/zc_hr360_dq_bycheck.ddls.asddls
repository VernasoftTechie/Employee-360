@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ by Check'
@Metadata.allowExtensions: true
@Analytics.query: true
@ObjectModel.usageType: { serviceQuality: #A, sizeCategory: #S, dataClass: #MIXED }
@UI.headerInfo: { typeName: 'Check', typeNamePlural: 'Data Quality Checks' }
@UI.chart: [{
  qualifier: 'ByCheck', chartType: #COLUMN,
  dimensions: [ 'CheckID' ], measures: [ 'FailureCount' ],
  measureAttributes: [{ measure: 'FailureCount', role: #AXIS_1 }]
}]
@UI.presentationVariant: [{
  sortOrder: [{ by: 'FailureCount', direction: #DESC }],
  visualizations: [{ type: #AS_CHART, qualifier: 'ByCheck' }, { type: #AS_LINEITEM }]
}]

define view entity ZC_HR360_DQ_BYCHECK
  as select from ZI_HR360_ISSUE
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
      @AnalyticsDetails.query.axis: #ROWS
      CheckID,
      @UI.lineItem:       [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
      @AnalyticsDetails.query.axis: #ROWS
      Category,
      @UI.lineItem: [{ position: 30 }]
      @AnalyticsDetails.query.axis: #FREE
      Severity,
      @UI.lineItem: [{ position: 40 }]
      @DefaultAggregation: #SUM
      cast( 1 as abap.int4 )                as FailureCount
}
