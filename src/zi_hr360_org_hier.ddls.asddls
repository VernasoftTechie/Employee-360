@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Organizational Hierarchy'
@Metadata.ignorePropagatedAnnotations: true

// Parent-child hierarchy over ZI_HR360_ORG_NODE for the Fiori org-navigation
// tree. The start node (root org unit) is supplied by the consuming UI via the
// p_root_node parameter (NodeID, e.g. 'O50000123').

define hierarchy ZI_HR360_ORG_HIER
  as parent child hierarchy(
    source ZI_HR360_ORG_NODE

    child to parent association _Parent
      on $projection.ParentNodeID = _Parent.NodeID

    start where
      NodeID = $parameters.p_root_node

    siblings order by
      NodeText ascending

    directory strategy #DEPTH_FIRST
  )
  with parameters
    p_root_node : abap.char( 34 )
{
  key NodeID,
      NodeType,
      ObjectID,
      NodeText,
      ParentNodeID,
      OrgUnit,
      _Parent
}
