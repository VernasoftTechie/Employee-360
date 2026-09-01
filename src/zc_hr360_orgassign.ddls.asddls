@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Organization (proj)'
@Metadata.allowExtensions: true
define view entity ZC_HR360_ORGASSIGN as projection on ZI_HR360_ORGASSIGN
{
  key EmployeeID, CompanyCode, PersonnelArea, PersonnelSubarea, EmployeeGroup,
      EmployeeSubgroup, OrgUnit, PositionId, Job, CostCenter
}
