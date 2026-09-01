@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Education (projection)'
@Metadata.allowExtensions: true

define view entity ZC_HR360_EDUCATION
  as projection on ZI_HR360_EDUCATION
{
  key EmployeeID,
  key EducationType,
  key ValidFrom,
      EducationSeqNr,
      EducationTypeName,
      Establishment,
      InstituteName,
      Certificate,
      CertificateName,
      Discipline,
      EducationalEstablishmentKey,
      ValidTo
}
