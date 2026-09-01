@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Pay History (projection)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_PAYROLL
  as projection on ZI_HR360_PAYROLL
{
  key EmployeeID,
  key ValidFrom,
      ValidTo,
      PayScaleType,
      PayScaleArea,
      PayScaleGroup,
      PayScaleLevel,
      AnnualSalary,
      Currency,
      CapacityUtilizationLevel,
      WeeklyHours,
      PayChangeReason,
      PayChangeReasonName
}
