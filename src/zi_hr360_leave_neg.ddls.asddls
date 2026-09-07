@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Negative Leave Balance'
@Metadata.ignorePropagatedAnnotations: true

// One row per employee who has at least one leave quota whose deduction period
// spans today and whose remaining balance is negative. Feeds LEAVE_NEGBAL.

define view entity ZI_HR360_LEAVE_NEG
  as select from ZI_HR360_LEAVE as Lv
{
  key Lv.EmployeeID as EmployeeID
}
where Lv.DeductionFrom <= $session.system_date
  and Lv.DeductionTo   >= $session.system_date
  and Lv.Remaining      < 0
group by
  Lv.EmployeeID
