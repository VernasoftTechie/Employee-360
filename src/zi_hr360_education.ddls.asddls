@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HR360 - Education'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_HR360_EDUCATION
  as select from pa0022 as E
{
  key E.pernr as EmployeeID,
  key E.subty as EducationTypeCode,
  key cast( E.begda as abap.dats ) as ValidFrom,
      E.seqnr as EducationSeqNr,
      E.slart as EducationCategory,
      E.slabs as Establishment,
      E.insti as InstituteName,
      cast( E.endda as abap.dats ) as ValidTo
}
