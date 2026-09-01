CLASS lhc_orgassignment DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ OrgAssignment RESULT result.
ENDCLASS.

CLASS lhc_orgassignment IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_orgassign
      FIELDS *
      FOR ALL ENTRIES IN @keys
        WHERE employeeid = @keys-employeeid
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
