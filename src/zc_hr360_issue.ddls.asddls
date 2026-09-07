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

      @UI.lineItem:       [{ position: 20 }]
      @UI.identification: [{ position: 20 }]
  key CheckID,

      @UI.lineItem:      [{ position: 30 }]
      @UI.selectionField: [{ position: 20 }]
      Category,

      @UI.lineItem: [{ position: 40, criticality: 'SeverityCriticality' }]
      Severity,

      SeverityCriticality,

      @UI.lineItem:       [{ position: 50 }]
      @UI.identification: [{ position: 50 }]
      IssueDescription,

      @UI.lineItem:       [{ position: 60 }]
      @UI.identification: [{ position: 60 }]
      FieldName,

      @UI.lineItem:       [{ position: 70 }]
      @UI.selectionField: [{ position: 30 }]
      CompanyCode,

      @UI.lineItem:       [{ position: 80 }]
      @UI.selectionField: [{ position: 40 }]
      PersonnelArea,

      @UI.lineItem:       [{ position: 90 }]
      PersonnelSubarea,

      @UI.lineItem:       [{ position: 100 }]
      @UI.selectionField: [{ position: 50 }]
      EmployeeGroup,

      @UI.lineItem:       [{ position: 110 }]
      @UI.selectionField: [{ position: 60 }]
      OrgUnit,

      @UI.lineItem:       [{ position: 120 }]
      CostCenter
}
