@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Skills & Certifications (projection)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_QUALIF
  as projection on ZI_HR360_QUALIF
{
  key EmployeeID,
  key QualificationID,
  key ValidFrom,
      QualificationName,
      QualificationGroup,
      QualificationGroupName,
      QualificationType,
      Proficiency,
      ValidTo,
      IsExpired
}
