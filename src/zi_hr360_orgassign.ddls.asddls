@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Organization and Position'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

define view entity ZI_HR360_ORGASSIGN
  as select from pa0001 as O

    left outer join t500p           as PA   on  PA.persa = O.werks
    left outer join t501t           as EG   on  EG.sprsl = $session.system_language
                                            and EG.persg = O.persg
    left outer join t503t           as ESG  on  ESG.sprsl = $session.system_language
                                            and ESG.persk = O.persk
    left outer join t527x           as OU   on  OU.sprsl = $session.system_language
                                            and OU.orgeh = O.orgeh
                                            and OU.begda <= $session.system_date
                                            and OU.endda >= $session.system_date
    left outer join hrp1000         as POS  on  POS.plvar = '01'
                                            and POS.otype = 'S'
                                            and POS.objid = O.plans
                                            and POS.langu = $session.system_language
                                            and POS.begda <= $session.system_date
                                            and POS.endda >= $session.system_date
    left outer join t513s           as JOBT on  JOBT.sprsl = $session.system_language
                                            and JOBT.stell = O.stell
    left outer join ZI_HR360_MANAGER as Mgr  on  Mgr.EmployeeID = O.pernr

  association to parent ZI_HR360_EMPLOYEE as _Employee
    on $projection.EmployeeID = _Employee.EmployeeID

  where O.begda <= $session.system_date
    and O.endda >= $session.system_date

{
  key O.pernr              as EmployeeID,
      O.bukrs              as CompanyCode,
      O.werks              as PersonnelArea,
      PA.name1             as PersonnelAreaName,
      O.btrtl              as PersonnelSubarea,
      O.persg              as EmployeeGroup,
      EG.ptext             as EmployeeGroupName,
      O.persk              as EmployeeSubgroup,
      ESG.ptext            as EmployeeSubgroupName,
      O.orgeh              as OrgUnit,
      OU.orgtx             as OrgUnitName,
      O.plans              as Position,
      POS.stext            as PositionName,
      O.stell              as Job,
      JOBT.stltx           as JobName,
      O.kostl              as CostCenter,
      Mgr.ManagerID        as ManagerID,
      Mgr.ManagerName      as ManagerName,

      _Employee
}
