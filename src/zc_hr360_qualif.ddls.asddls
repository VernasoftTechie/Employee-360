@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Skills (proj)'
@Metadata.allowExtensions: true
define view entity ZC_HR360_QUALIF
  as projection on ZI_HR360_QUALIF
{
  key EmployeeID,
  key QualificationID,
  key ValidFrom,
      QualificationType,
      Proficiency,
      ValidTo,
      IsExpired
}
