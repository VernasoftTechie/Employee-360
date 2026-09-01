@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Data Quality KPIs'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC

// Per-employee data-quality KPI aggregation over ZI_HR360_ISSUE. Kept separate
// from the root so the root itself is not an aggregating view.
// CompletenessPercent denominator 12 = active branch count of ZI_HR360_ISSUE
// (keep in sync when branches are added/removed).

define view entity ZI_HR360_EMP_KPI
  as select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_ISSUE  as Iss on Iss.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID                                                                as EmployeeID,

      count( distinct Iss.CheckID )                                                 as TotalIssueCount,
      count( distinct case when Iss.Severity = 'C' then Iss.CheckID end )            as CriticalIssueCount,
      count( distinct case when Iss.Severity = 'W' then Iss.CheckID end )            as WarningIssueCount,

      case
        when count( distinct Iss.CheckID ) = 0
          then cast( 'OK' as abap.char( 8 ) )
        when count( distinct case when Iss.Severity = 'C' then Iss.CheckID end ) > 0
          then cast( 'CRITICAL' as abap.char( 8 ) )
        else cast( 'WARNING' as abap.char( 8 ) )
      end                                                                           as QualityStatus,

      cast( 100 - ( count( distinct Iss.CheckID ) * 100 / 12 ) as abap.dec( 5, 1 ) ) as CompletenessPercent
}
group by
  Emp.EmployeeID
