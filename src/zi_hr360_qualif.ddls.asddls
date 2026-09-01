@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Skills and Certifications'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_QUALIF
  as select from pa0024 as Q
{
  key Q.pernr as EmployeeID,
  key Q.quali as QualificationID,
  key cast( Q.begda as abap.dats ) as ValidFrom,
      cast( 'SKILL' as abap.char( 5 ) ) as QualificationTypeCode,
      cast( Q.auspr as abap.dec( 4, 2 ) ) as Proficiency,
      cast( Q.endda as abap.dats ) as ValidTo,
      case when Q.endda < $session.system_date
           then cast( 'X' as abap.char( 1 ) )
           else cast( ' ' as abap.char( 1 ) )
      end     as IsExpired
}
