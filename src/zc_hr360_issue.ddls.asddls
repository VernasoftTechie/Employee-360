@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ Issue (query)'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: 'Data Quality Issue',
  typeNamePlural: 'Data Quality Issues'
}

define view entity ZC_HR360_ISSUE
  as select from ZI_HR360_ISSUE
{
      @UI.lineItem:      [{ position: 10 }]
      @UI.selectionField: [{ position: 10 }]
  key EmployeeID,

      @UI.lineItem: [{ position: 20 }]
  key CheckID,

      @UI.lineItem:      [{ position: 30 }]
      @UI.selectionField: [{ position: 20 }]
      Category,

      @UI.lineItem: [{ position: 40, criticality: 'SeverityCriticality' }]
      Severity,

      SeverityCriticality,

      @UI.lineItem: [{ position: 50 }]
      IssueDescription,

      @UI.lineItem: [{ position: 60 }]
      FieldName
}
