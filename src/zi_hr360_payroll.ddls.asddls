@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Pay History'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_PAYROLL
  as select from pa0008 as B
{
  key B.pernr as EmployeeID,
  key B.begda as ValidFrom,
      B.endda as ValidTo,
      B.trfar as PayScaleType,
      B.trfgb as PayScaleArea,
      B.trfgr as PayScaleGroup,
      B.trfst as PayScaleLevel,
      B.ansal as AnnualSalary,
      B.waers as Currency,
      B.bsgrd as CapacityUtilLevel,
      B.divgv as WeeklyHours
}
