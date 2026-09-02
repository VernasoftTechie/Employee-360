@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - DQ Headline KPIs'
@Metadata.allowExtensions: true
@UI.headerInfo: { typeName: 'Headline', typeNamePlural: 'Headline KPIs' }

// Single grand-total row for the dashboard KPI number cards.

define view entity ZC_HR360_KPI_HEADLINE
  as select from ZI_HR360_EMP_BASIC as b
    inner join ZI_HR360_EMP_KPI as k on k.EmployeeID = b.EmployeeID
{
  key cast( 'HR360' as abap.char( 5 ) )                                                 as ReportId,

      @UI.dataPoint: { title: 'Employees', qualifier: 'Total' }
      cast( count( * ) as abap.int4 )                                                   as TotalEmployees,

      @UI.dataPoint: { title: 'Critical employees', qualifier: 'Critical', criticality: 'CritCriticality' }
      cast( sum( case when k.QualityStatus = 'CRITICAL' then 1 else 0 end ) as abap.int4 ) as CriticalEmployees,

      @UI.dataPoint: { title: 'With issues', qualifier: 'WithIssues' }
      cast( sum( case when k.TotalIssueCount > 0 then 1 else 0 end ) as abap.int4 )      as EmployeesWithIssues,

      @UI.dataPoint: { title: 'Fully clean', qualifier: 'Clean' }
      cast( sum( case when k.TotalIssueCount = 0 then 1 else 0 end ) as abap.int4 )      as CleanEmployees,

      @UI.dataPoint: { title: 'Avg completeness', qualifier: 'AvgComp', targetValue: 100, visualization: #PROGRESS }
      cast( division( sum( 12 - k.TotalIssueCount ) * 100, count( * ) * 12, 1 ) as abap.dec( 5, 1 ) ) as AvgCompleteness,

      @UI.dataPoint: { title: 'Clean rate', qualifier: 'CleanPct', targetValue: 100, visualization: #PROGRESS }
      cast( division( sum( case when k.TotalIssueCount = 0 then 1 else 0 end ) * 100, count( * ), 1 ) as abap.dec( 5, 1 ) ) as CleanPercent,

      cast( 1 as abap.int4 )                                                            as CritCriticality
}
group by
  cast( 'HR360' as abap.char( 5 ) )
