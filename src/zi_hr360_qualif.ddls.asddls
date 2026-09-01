@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Skills and Certifications'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_QUALIF
  as select from pa0024 as Q
{
  key Q.pernr as EmployeeID,
  key Q.quali as QualificationID,
  key Q.begda as ValidFrom,
      cast( 'SKILL' as abap.char( 5 ) ) as QualificationType,
      Q.auspr as Proficiency,
      Q.endda as ValidTo,
      case when Q.endda < $session.system_date
           then cast( 'X' as abap.char( 1 ) )
           else cast( ' ' as abap.char( 1 ) )
      end     as IsExpired
}
