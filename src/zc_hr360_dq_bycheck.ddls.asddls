@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ by Check'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Check', typeNamePlural: 'Data Quality Checks' }
@UI.chart: [{
  qualifier: 'ByCheck', chartType: #COLUMN,
  dimensions: [ 'CheckID' ], measures: [ 'FailureCount' ]
}]
@UI.presentationVariant: [{
  sortOrder: [{ by: 'FailureCount', direction: #DESC }],
  visualizations: [{ type: #AS_CHART, qualifier: 'ByCheck' }, { type: #AS_LINEITEM }]
}]

// Plain pre-aggregated: one row per data-quality check with the number of
// employees failing it. Feeds the "where the data breaks" chart.

define view entity ZC_HR360_DQ_BYCHECK
  as select from ZI_HR360_ISSUE
{
      @UI.lineItem:       [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
  key CheckID                as CheckID,
      @UI.lineItem:       [{ position: 20 }]
      @UI.selectionField: [{ position: 20 }]
  key Category               as Category,
      @UI.lineItem:       [{ position: 30 }]
  key Severity               as Severity,
      max( SeverityCriticality ) as SeverityCriticality,
      @UI.lineItem: [{ position: 40 }]
      count( * )              as FailureCount
}
group by
  CheckID,
  Category,
  Severity
