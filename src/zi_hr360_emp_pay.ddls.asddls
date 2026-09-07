@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Basic Pay presence'
@Metadata.ignorePropagatedAnnotations: true

// One row per employee. max() + GROUP BY guards against more than one current
// PA0008 record (BUILD_ISSUES_LOG A34). Presence of the row itself signals a
// basic-pay record exists; the pay-scale fields are the "best" current values.

define view entity ZI_HR360_EMP_PAY
  as select from pa0008
{
  key pernr           as EmployeeID,
      max( trfar )     as PayScaleType,
      max( trfgb )     as PayScaleArea,
      max( trfgr )     as PayScaleGroup,
      max( trfst )     as PayScaleLevel
}
where begda <= $session.system_date
  and endda >= $session.system_date
group by pernr
