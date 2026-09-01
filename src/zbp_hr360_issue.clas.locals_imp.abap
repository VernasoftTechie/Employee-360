CLASS lhc_issue DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ dataqualityissue RESULT result.
ENDCLASS.

CLASS lhc_issue IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_issue
      FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
        AND checkid    = @keys-CheckID
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
