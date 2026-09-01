@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Data Quality Issue (projection)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_ISSUE
  as projection on ZI_HR360_ISSUE
{
  key EmployeeID,
  key CheckID,
      Category,
      Severity,
      case Severity
        when 'C' then 1
        when 'W' then 2
        else 3
      end            as SeverityCriticality,
      IssueDescription,
      FieldName
}
