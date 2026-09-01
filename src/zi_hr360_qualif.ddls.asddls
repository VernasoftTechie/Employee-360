@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Skills and Certifications'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

// Skills and certifications both originate from PA0024 (Qualifications).
// QualificationName / Group require the OM qualifications catalog (Q / QK).
// NOTE (Doc 03 CONFIRM 7.3, default "PA0024 only"): QualificationType is set to
// 'SKILL' for every row. When the client supplies the certification group ids,
// replace the literal with a CASE over GrpRel.sobid.

define view entity ZI_HR360_QUALIF
  as select from pa0024 as Q

    left outer join hrp1000 as QualTxt  on  QualTxt.plvar = '01'
                                        and QualTxt.otype = 'Q'
                                        and QualTxt.objid = cast(Q.quali as hrobjid)
                                        and QualTxt.langu = $session.system_language
                                        and QualTxt.begda <= $session.system_date
                                        and QualTxt.endda >= $session.system_date

    left outer join hrp1001 as GrpRel   on  GrpRel.plvar = '01'
                                        and GrpRel.otype = 'Q'
                                        and GrpRel.objid = cast(Q.quali as hrobjid)
                                        and GrpRel.rsign = 'A'
                                        and GrpRel.relat = '002'
                                        and GrpRel.sclas = 'QK'
                                        and GrpRel.begda <= $session.system_date
                                        and GrpRel.endda >= $session.system_date

    left outer join hrp1000 as GrpTxt   on  GrpTxt.plvar = '01'
                                        and GrpTxt.otype = 'QK'
                                        and GrpTxt.objid = GrpRel.sobid
                                        and GrpTxt.langu = $session.system_language
                                        and GrpTxt.begda <= $session.system_date
                                        and GrpTxt.endda >= $session.system_date

  association to parent ZI_HR360_EMPLOYEE as _Employee
    on $projection.EmployeeID = _Employee.EmployeeID

{
  key Q.pernr                                    as EmployeeID,
  key Q.quali                                    as QualificationID,
  key Q.begda                                    as ValidFrom,
      QualTxt.stext                              as QualificationName,
      GrpRel.sobid                               as QualificationGroup,
      GrpTxt.stext                               as QualificationGroupName,
      cast( 'SKILL' as abap.char( 5 ) )          as QualificationType,
      Q.auspr                                    as Proficiency,
      Q.endda                                    as ValidTo,
      case when Q.endda < $session.system_date
           then cast( 'X' as abap.char( 1 ) )
           else cast( ' ' as abap.char( 1 ) )
      end                                        as IsExpired,

      _Employee
}
