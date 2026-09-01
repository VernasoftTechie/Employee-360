@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Skills and Certifications'
@Metadata.ignorePropagatedAnnotations: true

// Skills and certifications both originate from PA0024 (Qualifications).
// The OM qualifications-catalog joins (HRP1000/HRP1001 for readable names and
// the Skill/Certification split) are deferred - see BUGS_AND_ISSUES.md #002.
// Phase 1 exposes the PA0024 fields; QualificationType is 'SKILL' for every row.

define view entity ZI_HR360_QUALIF
  as select from pa0024 as Q
{
  key Q.pernr                                    as EmployeeID,
  key Q.quali                                    as QualificationID,
  key Q.begda                                    as ValidFrom,
      cast( '' as abap.char( 40 ) )              as QualificationName,
      cast( '' as abap.char( 12 ) )              as QualificationGroup,
      cast( '' as abap.char( 40 ) )              as QualificationGroupName,
      cast( 'SKILL' as abap.char( 5 ) )          as QualificationType,
      Q.auspr                                    as Proficiency,
      Q.endda                                    as ValidTo,
      case when Q.endda < $session.system_date
           then cast( 'X' as abap.char( 1 ) )
           else cast( ' ' as abap.char( 1 ) )
      end                                        as IsExpired
}
