CLASS lhc_education DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ Education RESULT result.
ENDCLASS.

CLASS lhc_education IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_education
      FIELDS *
      FOR ALL ENTRIES IN @keys
        WHERE employeeid = @keys-employeeid
          AND educationtype = @keys-educationtype
          AND validfrom = @keys-validfrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
