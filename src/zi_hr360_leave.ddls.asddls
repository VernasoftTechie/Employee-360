@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Leave and Quotas'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_LEAVE
  as select from pa2006 as Q
{
  key Q.pernr           as EmployeeID,
  key Q.ktart           as QuotaType,
  key Q.desta           as DeductionFrom,
      Q.deend           as DeductionTo,
      Q.anzhl           as Entitlement,
      Q.kverb           as Deducted,
      Q.anzhl - Q.kverb as Remaining
}
