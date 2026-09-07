@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Qualification Status'
@Metadata.ignorePropagatedAnnotations: true

// Per-employee roll-up of PA0024 qualifications: how many on file, how many
// still valid today. Feeds the QUAL_EXPIRED check in ZI_HR360_ISSUE
// (has qualifications, but every one has lapsed).

define view entity ZI_HR360_QUAL_STATUS
  as select from ZI_HR360_QUALIF as Q
{
  key Q.EmployeeID                                                             as EmployeeID,
      cast( count( * ) as abap.int4 )                                          as TotalQuals,
      cast( sum( case when Q.IsExpired = 'X' then 0 else 1 end ) as abap.int4 ) as CurrentQuals
}
group by
  Q.EmployeeID
