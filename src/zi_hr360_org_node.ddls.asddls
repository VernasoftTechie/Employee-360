@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Org Hierarchy Node'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC

// Flat node set for the organizational hierarchy. One row per OM object
// (org unit / position / person). ParentNodeID is derived from HRP1001
// "belongs to" (003) / "reports to" (002) relationships.

define view entity ZI_HR360_ORG_NODE
  as select from hrp1000 as N

    left outer join hrp1001 as R on  R.plvar = N.plvar
                                 and R.otype = N.otype
                                 and R.objid = N.objid
                                 and R.rsign = 'A'
                                 and R.relat in ( '002', '003' )
                                 and R.begda <= $session.system_date
                                 and R.endda >= $session.system_date

  where N.plvar = '01'
    and N.otype in ( 'O', 'S', 'P' )
    and N.begda <= $session.system_date
    and N.endda >= $session.system_date
    and N.langu = $session.system_language

{
  key concat( N.otype, N.objid )                as NodeID,
      N.otype                                   as NodeType,
      N.objid                                   as ObjectID,
      N.stext                                   as NodeText,
      cast( concat( R.sclas, R.sobid ) as abap.char( 34 ) ) as ParentNodeID,
      case when N.otype = 'O' then N.objid else cast( '' as orgeh ) end as OrgUnit
}
