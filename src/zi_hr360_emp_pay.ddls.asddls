@AccessControl.authorizationCheck: #NOT_REQUIRED  // building block - row filter inherited from consuming #CHECK views
@EndUserText.label: 'HR360 - Employee Basic Pay presence'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC

define view entity ZI_HR360_EMP_PAY
  as select from pa0008

  where begda <= $session.system_date
    and endda >= $session.system_date

{
  key pernr    as EmployeeID,
      trfar    as PayScaleType,
      trfgb    as PayScaleArea,
      trfgr    as PayScaleGroup,
      trfst    as PayScaleLevel
}
