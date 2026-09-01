@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Employee Basic (anchor)'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE
@ObjectModel.usageType: { serviceQuality: #C, sizeCategory: #L, dataClass: #MIXED }

define view entity ZI_HR360_EMP_BASIC
  as select from pa0001 as OrgAssignment
    inner join   pa0002 as PersonalData     on  PersonalData.pernr = OrgAssignment.pernr
                                            and PersonalData.begda <= $session.system_date
                                            and PersonalData.endda >= $session.system_date
    left outer join t500p as PersArea       on  PersArea.persa = OrgAssignment.werks
    left outer join t501t as EEGroupTxt     on  EEGroupTxt.sprsl = $session.system_language
                                            and EEGroupTxt.persg = OrgAssignment.persg
    left outer join t503t as EESubgroupTxt  on  EESubgroupTxt.sprsl = $session.system_language
                                            and EESubgroupTxt.persk = OrgAssignment.persk
    left outer join t527x as OrgUnitTxt     on  OrgUnitTxt.sprsl = $session.system_language
                                            and OrgUnitTxt.orgeh = OrgAssignment.orgeh
                                            and OrgUnitTxt.begda <= $session.system_date
                                            and OrgUnitTxt.endda >= $session.system_date

  where OrgAssignment.begda <= $session.system_date
    and OrgAssignment.endda >= $session.system_date

{
  key OrgAssignment.pernr    as EmployeeID,

      OrgAssignment.bukrs    as CompanyCode,
      OrgAssignment.werks    as PersonnelArea,
      PersArea.name1         as PersonnelAreaName,
      OrgAssignment.btrtl    as PersonnelSubarea,
      OrgAssignment.persg    as EmployeeGroup,
      EEGroupTxt.ptext       as EmployeeGroupName,
      OrgAssignment.persk    as EmployeeSubgroup,
      EESubgroupTxt.ptext    as EmployeeSubgroupName,
      OrgAssignment.orgeh    as OrgUnit,
      OrgUnitTxt.orgtx       as OrgUnitName,
      OrgAssignment.kostl    as CostCenter,
      OrgAssignment.plans    as Position,
      OrgAssignment.stell    as Job,
      OrgAssignment.stat2    as EmploymentStatus,

      PersonalData.nachn     as LastName,
      PersonalData.vorna     as FirstName,
      PersonalData.gbdat     as DateOfBirth,
      PersonalData.gesch     as Gender,
      PersonalData.natio     as Nationality
}
