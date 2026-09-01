CLASS lhc_payrollitem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ PayrollItem RESULT result.
ENDCLASS.

CLASS lhc_payrollitem IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_payroll
      FIELDS *
      FOR ALL ENTRIES IN @keys
        WHERE employeeid = @keys-employeeid
          AND validfrom = @keys-validfrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
