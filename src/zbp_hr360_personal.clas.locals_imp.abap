CLASS lhc_personal DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ Personal RESULT result.
ENDCLASS.

CLASS lhc_personal IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_personal
      FIELDS *
      FOR ALL ENTRIES IN @keys
        WHERE employeeid = @keys-employeeid
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
