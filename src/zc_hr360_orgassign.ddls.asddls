@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Organization (projection)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_ORGASSIGN
  as projection on ZI_HR360_ORGASSIGN
{
  key EmployeeID,
      CompanyCode,
      PersonnelArea,
      PersonnelAreaName,
      PersonnelSubarea,
      EmployeeGroup,
      EmployeeGroupName,
      EmployeeSubgroup,
      EmployeeSubgroupName,
      OrgUnit,
      OrgUnitName,
      Position,
      PositionName,
      Job,
      JobName,
      CostCenter,
      ManagerID,
      ManagerName
}
