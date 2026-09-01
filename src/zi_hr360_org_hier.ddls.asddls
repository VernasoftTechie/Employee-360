@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Organizational Hierarchy'
@Metadata.ignorePropagatedAnnotations: true

// Parent-child hierarchy over ZI_HR360_ORG_NODE for the Fiori org-navigation
// tree. p_root_node is the NodeID of the start node ('O' + org-unit id).

define hierarchy ZI_HR360_ORG_HIER
  with parameters
    p_root_node : abap.char( 14 )
  as parent child hierarchy(
    source ZI_HR360_ORG_NODE
    child to parent association _Parent
      on $projection.ParentNodeID = _Parent.NodeID
    start where NodeID = $parameters.p_root_node
    siblings order by NodeText ascending
  )
{
  key NodeID,
      NodeType,
      ObjectID,
      NodeText,
      ParentNodeID,
      OrgUnit
}
