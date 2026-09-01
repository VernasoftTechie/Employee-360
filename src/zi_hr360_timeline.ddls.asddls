@AccessControl.authorizationCheck: #NOT_REQUIRED
// Exposed to the UI only by read-by-association from the checked root
// ZI_HR360_EMPLOYEE; the projection ZC_HR360_TIMELINE is #CHECK. An explicit
// DCL on this interface view is tracked in BUGS_AND_ISSUES.md for go-live
// hardening (union views cannot carry P_ORGIN org fields directly).
@EndUserText.label: 'HR360 - Employee Timeline'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

// Chronological event feed. UNION ALL - every branch emits the same 8 columns
// with identical types. Events are derived from infotype BEGDA time slices,
// not from change documents. Sort descending by SortDate in the consumer.

define view entity ZI_HR360_TIMELINE
  as select from pa0000 as Act

    left outer join t529t as ActTxt on  ActTxt.sprsl = $session.system_language
                                    and ActTxt.massn = Act.massn

{
  key Act.pernr                                              as EmployeeID,
  key Act.begda                                              as EventDate,
  key cast( 'ACTION' as abap.char( 12 ) )                    as EventCategory,
  key cast( Act.seqnr as abap.numc( 3 ) )                    as EventSeqNr,
      cast( Act.massn as abap.char( 12 ) )                   as EventType,
      cast( coalesce( ActTxt.mntext, cast( 'Personnel action' as abap.char( 40 ) ) ) as abap.char( 120 ) ) as Title,
      cast( '' as abap.char( 250 ) )                         as Detail,
      Act.begda                                              as SortDate
}

union all

  select from pa0001 as O
{
  key O.pernr                                                as EmployeeID,
  key O.begda                                                as EventDate,
  key cast( 'ORG_CHANGE' as abap.char( 12 ) )                as EventCategory,
  key cast( O.seqnr as abap.numc( 3 ) )                      as EventSeqNr,
      cast( 'ORGEH' as abap.char( 12 ) )                     as EventType,
      cast( concat( 'Org unit: ', O.orgeh ) as abap.char( 120 ) ) as Title,
      cast( concat( 'Position: ', O.plans ) as abap.char( 250 ) ) as Detail,
      O.begda                                                as SortDate
}

union all

  select from pa0008 as B
{
  key B.pernr                                                as EmployeeID,
  key B.begda                                                as EventDate,
  key cast( 'PAY_CHANGE' as abap.char( 12 ) )                as EventCategory,
  key cast( B.seqnr as abap.numc( 3 ) )                      as EventSeqNr,
      cast( 'BASICPAY' as abap.char( 12 ) )                  as EventType,
      cast( 'Basic pay changed' as abap.char( 120 ) )        as Title,
      cast( concat( 'Pay scale: ', concat( B.trfgr, B.trfst ) ) as abap.char( 250 ) ) as Detail,
      B.begda                                                as SortDate
}

union all

  select from pa0022 as E
{
  key E.pernr                                                as EmployeeID,
  key E.begda                                                as EventDate,
  key cast( 'EDUCATION' as abap.char( 12 ) )                 as EventCategory,
  key cast( E.seqnr as abap.numc( 3 ) )                      as EventSeqNr,
      cast( E.slart as abap.char( 12 ) )                     as EventType,
      cast( concat( 'Education: ', E.slart ) as abap.char( 120 ) ) as Title,
      cast( E.insti as abap.char( 250 ) )                    as Detail,
      E.begda                                                as SortDate
}

union all

  select from pa0024 as Q
{
  key Q.pernr                                                as EmployeeID,
  key Q.begda                                                as EventDate,
  key cast( 'QUALIFICATION' as abap.char( 12 ) )             as EventCategory,
  key cast( Q.seqnr as abap.numc( 3 ) )                      as EventSeqNr,
      cast( 'QUAL' as abap.char( 12 ) )                      as EventType,
      cast( concat( 'Qualification: ', Q.quali ) as abap.char( 120 ) ) as Title,
      cast( concat( 'Proficiency: ', Q.auspr ) as abap.char( 250 ) ) as Detail,
      Q.begda                                                as SortDate
}

union all

  select from pa2001 as Ab
{
  key Ab.pernr                                               as EmployeeID,
  key Ab.begda                                               as EventDate,
  key cast( 'ABSENCE' as abap.char( 12 ) )                   as EventCategory,
  key cast( Ab.seqnr as abap.numc( 3 ) )                     as EventSeqNr,
      cast( Ab.awart as abap.char( 12 ) )                    as EventType,
      cast( concat( 'Absence: ', Ab.awart ) as abap.char( 120 ) ) as Title,
      cast( concat( 'Calendar days: ', cast( Ab.abwtg as abap.char( 15 ) ) ) as abap.char( 250 ) ) as Detail,
      Ab.begda                                               as SortDate
}
