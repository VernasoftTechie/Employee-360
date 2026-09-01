@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Org Hierarchy Node'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC

// Flat node set for the organizational hierarchy: one row per OM object
// (org unit / position / person). ParentNodeID is the "belongs to" / "reports
// to" superior from HRP1001.

define view entity ZI_HR360_ORG_NODE
  as select from hrp1000 as N

    left outer join hrp1001 as R on  R.plvar = N.plvar
                                 and R.otype = N.otype
                                 and R.objid = N.objid
                                 and R.rsign = 'A'
                                 and ( R.relat = '002' or R.relat = '003' )
                                 and R.begda <= $session.system_date
                                 and R.endda >= $session.system_date
{
  key cast( concat( N.otype, N.objid ) as abap.char( 14 ) )              as NodeID,
      N.otype                                                            as NodeType,
      N.objid                                                            as ObjectID,
      N.stext                                                            as NodeText,
      cast( concat( R.sclas, cast( R.sobid as abap.char( 12 ) ) ) as abap.char( 14 ) ) as ParentNodeID,
      cast( N.objid as abap.char( 12 ) )                                 as OrgUnit
}
where N.plvar = '01'
  and ( N.otype = 'O' or N.otype = 'S' or N.otype = 'P' )
  and N.begda <= $session.system_date
  and N.endda >= $session.system_date
  and N.langu = $session.system_language
