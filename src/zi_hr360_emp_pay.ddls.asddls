@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Basic Pay presence'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_EMP_PAY
  as select from pa0008
{
  key pernr    as EmployeeID,
      trfar    as PayScaleType,
      trfgb    as PayScaleArea,
      trfgr    as PayScaleGroup,
      trfst    as PayScaleLevel
}
where begda <= $session.system_date
  and endda >= $session.system_date
