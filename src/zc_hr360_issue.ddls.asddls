@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ Issue (proj)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_ISSUE
  as projection on ZI_HR360_ISSUE
{
  key EmployeeID,
  key CheckID,
      Category,
      Severity,
      SeverityCriticality,
      IssueDescription,
      FieldName
}
