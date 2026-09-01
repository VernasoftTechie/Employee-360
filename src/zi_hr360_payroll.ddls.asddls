@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Pay History'
@Metadata.ignorePropagatedAnnotations: true

// Pay-scale / salary history from PA0008 (Basic Pay), one row per time slice.
// Wage-type-level detail (LGA01..40 / BET01..40) is out of scope for Phase 1.

define view entity ZI_HR360_PAYROLL
  as select from pa0008 as B

    left outer join t539r as RE on  RE.sprsl = $session.system_language
                                and RE.massn = B.massn
                                and RE.preas = B.preas

{
  key B.pernr    as EmployeeID,
  key B.begda    as ValidFrom,
      B.endda    as ValidTo,
      B.trfar    as PayScaleType,
      B.trfgb    as PayScaleArea,
      B.trfgr    as PayScaleGroup,
      B.trfst    as PayScaleLevel,
      B.ansal    as AnnualSalary,
      B.waers    as Currency,
      B.bsgrd    as CapacityUtilizationLevel,
      B.divgv    as WeeklyHours,
      B.preas    as PayChangeReason,
      RE.pretx   as PayChangeReasonName
}
