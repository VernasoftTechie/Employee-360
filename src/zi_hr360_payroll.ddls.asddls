@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Pay History'
@Metadata.ignorePropagatedAnnotations: true

// Amount / quantity fields cast to plain decimal - CURR/QUAN need a reference
// field + @Semantics otherwise (BUILD_ISSUES_LOG.md A13).

define view entity ZI_HR360_PAYROLL
  as select from pa0008 as B
{
  key B.pernr as EmployeeID,
  key cast( B.begda as abap.dats ) as ValidFrom,
      cast( B.endda as abap.dats ) as ValidTo,
      B.trfar as PayScaleType,
      B.trfgb as PayScaleArea,
      B.trfgr as PayScaleGroup,
      B.trfst as PayScaleLevel,
      cast( B.ansal as abap.dec( 15, 2 ) ) as AnnualSalary,
      B.waers as Currency,
      cast( B.bsgrd as abap.dec( 5, 2 ) )  as CapacityUtilLevel,
      cast( B.divgv as abap.dec( 7, 2 ) )  as WeeklyHours
}
