@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Leave and Quotas'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

define view entity ZI_HR360_LEAVE
  as select from pa2006 as Qta

    left outer join t556b as QT on  QT.sprsl = $session.system_language
                                and QT.ktart = Qta.ktart
                                and QT.moabw = Qta.quomo

  association to parent ZI_HR360_EMPLOYEE as _Employee
    on $projection.EmployeeID = _Employee.EmployeeID

{
  key Qta.pernr                          as EmployeeID,
  key Qta.ktart                          as QuotaType,
  key Qta.desta                          as DeductionFrom,
      QT.ktext                           as QuotaTypeName,
      Qta.deend                          as DeductionTo,
      Qta.anzhl                          as Entitlement,
      Qta.kverb                          as Deducted,
      Qta.anzhl - Qta.kverb              as Remaining,
      cast( 'Days' as abap.char( 10 ) )  as Unit,

      _Employee
}
