CLASS lhc_qualification DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ Qualification RESULT result.
ENDCLASS.

CLASS lhc_qualification IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_qualif
      FIELDS *
      FOR ALL ENTRIES IN @keys
        WHERE employeeid = @keys-employeeid
          AND qualificationid = @keys-qualificationid
          AND validfrom = @keys-validfrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
