@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Line Manager'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

// Manager resolution (common single-level case):
//   employee -> own position (PA0001.PLANS)
//   position --A002 "reports to"--> superior position (HRP1001)
//   superior position --A008 "holder"--> person (HRP1001)
// All joins are LEFT OUTER, so an incomplete hierarchy yields a blank manager
// rather than dropping the employee. Deep / multi-path cases are handled in
// ZCL_HR360_ORG_READER for the report programs.

define view entity ZI_HR360_MANAGER
  as select from pa0001 as Emp

    left outer join hrp1001 as RepTo   on  RepTo.plvar = '01'
                                       and RepTo.otype = 'S'
                                       and RepTo.objid = Emp.plans
                                       and RepTo.rsign = 'A'
                                       and RepTo.relat = '002'
                                       and RepTo.sclas = 'S'
                                       and RepTo.begda <= $session.system_date
                                       and RepTo.endda >= $session.system_date

    left outer join hrp1001 as Holder  on  Holder.plvar = '01'
                                       and Holder.otype = 'S'
                                       and Holder.objid = RepTo.sobid
                                       and Holder.rsign = 'A'
                                       and Holder.relat = '008'
                                       and Holder.sclas = 'P'
                                       and Holder.begda <= $session.system_date
                                       and Holder.endda >= $session.system_date

    left outer join pa0002 as MgrName  on  MgrName.pernr = cast(Holder.sobid as pernr_d)
                                       and MgrName.begda <= $session.system_date
                                       and MgrName.endda >= $session.system_date

  where Emp.begda <= $session.system_date
    and Emp.endda >= $session.system_date

{
  key Emp.pernr                                            as EmployeeID,
      cast(Holder.sobid as pernr_d)                        as ManagerID,
      RepTo.sobid                                          as ManagerPosition,
      concat(concat(MgrName.vorna, ' '), MgrName.nachn)    as ManagerName
}
