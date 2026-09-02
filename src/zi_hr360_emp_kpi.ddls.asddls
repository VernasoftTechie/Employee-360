@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee DQ KPIs'
@Metadata.ignorePropagatedAnnotations: true

// Per-employee data-quality counts + derived status. Flat (EMP_BASIC left join
// ISSUE, grouped by employee). count(distinct) is required (BUILD_ISSUES_LOG A4).

define view entity ZI_HR360_EMP_KPI
  as select from ZI_HR360_EMP_BASIC as Emp
    left outer join ZI_HR360_ISSUE  as Iss on Iss.EmployeeID = Emp.EmployeeID
{
  key Emp.EmployeeID as EmployeeID,

      cast( count( distinct Iss.CheckID ) as abap.int4 )                       as TotalIssueCount,
      cast( sum( case when Iss.Severity = 'C' then 1 else 0 end ) as abap.int4 ) as CriticalIssueCount,
      cast( sum( case when Iss.Severity = 'W' then 1 else 0 end ) as abap.int4 ) as WarningIssueCount,

      case
        when sum( case when Iss.Severity = 'C' then 1 else 0 end ) > 0 then cast( 'CRITICAL' as abap.char( 8 ) )
        when count( distinct Iss.CheckID ) > 0                        then cast( 'WARNING'  as abap.char( 8 ) )
        else cast( 'OK' as abap.char( 8 ) )
      end                                                                       as QualityStatus,

      case
        when sum( case when Iss.Severity = 'C' then 1 else 0 end ) > 0 then cast( 1 as abap.int4 )
        when count( distinct Iss.CheckID ) > 0                        then cast( 2 as abap.int4 )
        else cast( 3 as abap.int4 )
      end                                                                       as QualityStatusCriticality,

      cast( division( ( 12 - count( distinct Iss.CheckID ) ) * 100, 12, 2 ) as abap.dec( 6, 2 ) ) as CompletenessPercent
}
group by
  Emp.EmployeeID
