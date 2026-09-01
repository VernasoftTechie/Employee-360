// TEMP v0.18 diagnostic - restore to #CHECK once data is confirmed
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Organization'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_ORGASSIGN
  as select from pa0001 as O
{
  key O.pernr as EmployeeID,
      O.bukrs as CompanyCode,
      O.werks as PersonnelArea,
      O.btrtl as PersonnelSubarea,
      O.persg as EmployeeGroup,
      O.persk as EmployeeSubgroup,
      O.orgeh as OrgUnit,
      O.plans as PositionId,
      O.stell as Job,
      O.kostl as CostCenter
}
where O.begda <= $session.system_date
  and O.endda >= $session.system_date
