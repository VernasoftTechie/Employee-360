@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Education'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

define view entity ZI_HR360_EDUCATION
  as select from pa0022 as E

    left outer join t517t as ETyp on  ETyp.sprsl = $session.system_language
                                  and ETyp.slart = E.slart
    left outer join t517x as ECrt on  ECrt.sprsl = $session.system_language
                                  and ECrt.sltp1 = E.sltp1

  association to parent ZI_HR360_EMPLOYEE as _Employee
    on $projection.EmployeeID = _Employee.EmployeeID

{
  key E.pernr        as EmployeeID,
  key E.subty        as EducationType,
  key E.begda        as ValidFrom,
      E.seqnr        as EducationSeqNr,
      ETyp.stext     as EducationTypeName,
      E.slabs        as Establishment,
      E.insti        as InstituteName,
      E.sltp1        as Certificate,
      ECrt.stext     as CertificateName,
      E.sltp2        as Discipline,
      E.ausbi        as EducationalEstablishmentKey,
      E.endda        as ValidTo,

      _Employee
}
