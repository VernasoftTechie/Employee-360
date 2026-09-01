@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'HR360 - Personnel File Documents'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE

// ArchiveLink link entries for HR business object 'PREL' (personnel file).
// Metadata only. EmployeeID is the leading 8 chars of OBJECT_ID (default HR
// ArchiveLink key layout). If ArchiveLink is not configured this returns no rows.

define view entity ZI_HR360_DOCUMENT
  as select from toa01 as L

    left outer join toaat as At on At.arc_doc_id = L.arc_doc_id

  association to parent ZI_HR360_EMPLOYEE as _Employee
    on $projection.EmployeeID = _Employee.EmployeeID

  where L.sap_object = 'PREL'

{
  key cast( substring( L.object_id, 1, 8 ) as pernr_d )  as EmployeeID,
  key L.arc_doc_id                                       as ArchivDocID,
      L.archiv_id                                        as ArchiveID,
      L.ar_object                                        as DocumentType,
      L.ar_date                                          as ArchiveDate,
      At.descr                                           as Title,
      At.reserve                                         as MimeHint,

      _Employee
}
