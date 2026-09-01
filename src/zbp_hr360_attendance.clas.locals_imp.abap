CLASS lhc_attendance DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ Attendance RESULT result.
ENDCLASS.

CLASS lhc_attendance IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_attendance
      FIELDS *
      FOR ALL ENTRIES IN @keys
        WHERE employeeid = @keys-employeeid
          AND attendancefrom = @keys-attendancefrom
          AND attendancetype = @keys-attendancetype
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
