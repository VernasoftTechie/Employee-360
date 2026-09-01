@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Timeline'
@Metadata.ignorePropagatedAnnotations: true

// Chronological event feed. UNION ALL - every branch emits the same columns
// with identical types. Keys are defined by the first branch. Events come from
// infotype BEGDA time slices. Sort descending by EventDate in the consumer.

define view entity ZI_HR360_TIMELINE
  as select from pa0000 as Act
    left outer join t529t as ActTxt on  ActTxt.sprsl = $session.system_language
                                    and ActTxt.massn = Act.massn
{
  key Act.pernr                                              as EmployeeID,
  key Act.begda                                              as EventDate,
  key cast( 'ACTION' as abap.char( 12 ) )                    as EventCategory,
  key cast( Act.massn as abap.char( 12 ) )                   as EventKey,
      cast( ActTxt.mntxt as abap.char( 120 ) )               as Title,
      cast( '' as abap.char( 250 ) )                         as Detail
}

union all

  select from pa0001 as O
{
  O.pernr                                                    as EmployeeID,
  O.begda                                                    as EventDate,
  cast( 'ORG_CHANGE' as abap.char( 12 ) )                    as EventCategory,
  cast( O.orgeh as abap.char( 12 ) )                         as EventKey,
  cast( concat( 'Org unit: ', O.orgeh ) as abap.char( 120 ) ) as Title,
  cast( concat( 'Position: ', O.plans ) as abap.char( 250 ) ) as Detail
}

union all

  select from pa0008 as B
{
  B.pernr                                                    as EmployeeID,
  B.begda                                                    as EventDate,
  cast( 'PAY_CHANGE' as abap.char( 12 ) )                    as EventCategory,
  cast( B.trfst as abap.char( 12 ) )                         as EventKey,
  cast( 'Basic pay changed' as abap.char( 120 ) )            as Title,
  cast( concat( 'Pay scale: ', concat( B.trfgr, B.trfst ) ) as abap.char( 250 ) ) as Detail
}

union all

  select from pa0022 as E
{
  E.pernr                                                    as EmployeeID,
  E.begda                                                    as EventDate,
  cast( 'EDUCATION' as abap.char( 12 ) )                     as EventCategory,
  cast( E.slart as abap.char( 12 ) )                         as EventKey,
  cast( concat( 'Education: ', E.slart ) as abap.char( 120 ) ) as Title,
  cast( E.insti as abap.char( 250 ) )                        as Detail
}

union all

  select from pa0024 as Q
{
  Q.pernr                                                    as EmployeeID,
  Q.begda                                                    as EventDate,
  cast( 'QUALIFICATION' as abap.char( 12 ) )                 as EventCategory,
  cast( Q.quali as abap.char( 12 ) )                         as EventKey,
  cast( concat( 'Qualification: ', Q.quali ) as abap.char( 120 ) ) as Title,
  cast( concat( 'Proficiency: ', Q.auspr ) as abap.char( 250 ) ) as Detail
}

union all

  select from pa2001 as Ab
{
  Ab.pernr                                                   as EmployeeID,
  Ab.begda                                                   as EventDate,
  cast( 'ABSENCE' as abap.char( 12 ) )                       as EventCategory,
  cast( Ab.awart as abap.char( 12 ) )                        as EventKey,
  cast( concat( 'Absence: ', Ab.awart ) as abap.char( 120 ) ) as Title,
  cast( '' as abap.char( 250 ) )                             as Detail
}
