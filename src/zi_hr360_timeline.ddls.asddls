@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Employee Timeline'
@Metadata.ignorePropagatedAnnotations: true

// Chronological event feed. UNION ALL - every branch projects the SAME element
// names/types AND the SAME key markers (see docs/BUILD_ISSUES_LOG.md A5/A6).

define view entity ZI_HR360_TIMELINE
  as select from pa0000 as Act
{
  key Act.pernr                               as EmployeeID,
  key cast( Act.begda as abap.dats )          as EventDate,
  key cast( 'ACTION' as abap.char( 20 ) )     as EventCategory,
  key cast( Act.massn as abap.char( 20 ) )    as EventKey,
      cast( 'Personnel action' as abap.char( 120 ) ) as Title
}

union all
  select from pa0001 as O
{
  key O.pernr                                 as EmployeeID,
  key cast( O.begda as abap.dats )            as EventDate,
  key cast( 'ORG_CHANGE' as abap.char( 20 ) ) as EventCategory,
  key cast( O.orgeh as abap.char( 20 ) )      as EventKey,
      cast( concat( 'Org unit ', O.orgeh ) as abap.char( 120 ) ) as Title
}

union all
  select from pa0008 as B
{
  key B.pernr                                 as EmployeeID,
  key cast( B.begda as abap.dats )            as EventDate,
  key cast( 'PAY_CHANGE' as abap.char( 20 ) ) as EventCategory,
  key cast( B.trfst as abap.char( 20 ) )      as EventKey,
      cast( 'Basic pay changed' as abap.char( 120 ) ) as Title
}

union all
  select from pa0022 as E
{
  key E.pernr                                 as EmployeeID,
  key cast( E.begda as abap.dats )            as EventDate,
  key cast( 'EDUCATION' as abap.char( 20 ) )  as EventCategory,
  key cast( E.slart as abap.char( 20 ) )      as EventKey,
      cast( concat( 'Education ', E.slart ) as abap.char( 120 ) ) as Title
}

union all
  select from pa0024 as Q
{
  key Q.pernr                                     as EmployeeID,
  key cast( Q.begda as abap.dats )            as EventDate,
  key cast( 'QUALIFICATION' as abap.char( 20 ) )  as EventCategory,
  key cast( Q.quali as abap.char( 20 ) )          as EventKey,
      cast( concat( 'Qualification ', Q.quali ) as abap.char( 120 ) ) as Title
}

union all
  select from pa2001 as Ab
{
  key Ab.pernr                                as EmployeeID,
  key cast( Ab.begda as abap.dats )           as EventDate,
  key cast( 'ABSENCE' as abap.char( 20 ) )    as EventCategory,
  key cast( Ab.awart as abap.char( 20 ) )     as EventKey,
      cast( concat( 'Absence ', Ab.awart ) as abap.char( 120 ) ) as Title
}
