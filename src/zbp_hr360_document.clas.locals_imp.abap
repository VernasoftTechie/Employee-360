CLASS lhc_document DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ Document RESULT result.
ENDCLASS.

CLASS lhc_document IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_document
      FIELDS *
      FOR ALL ENTRIES IN @keys
        WHERE employeeid = @keys-employeeid
          AND archivdocid = @keys-archivdocid
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
