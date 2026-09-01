@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ Issue (query)'
@Metadata.allowExtensions: true

// Plain read-only query view over the check framework. Not a RAP projection -
// exposed directly in the service, queried by EmployeeID. (A18: standalone
// "as projection on" needs its own root BO + provider contract; not worth it
// for a read-only list.)

define view entity ZC_HR360_ISSUE
  as select from ZI_HR360_ISSUE
{
  key EmployeeID,
  key CheckID,
      Category,
      Severity,
      SeverityCriticality,
      IssueDescription,
      FieldName
}
