CLASS lhc_leavebalance DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ LeaveBalance RESULT result.
ENDCLASS.

CLASS lhc_leavebalance IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_leave
      FIELDS *
      FOR ALL ENTRIES IN @keys
        WHERE employeeid = @keys-employeeid
          AND quotatype = @keys-quotatype
          AND deductionfrom = @keys-deductionfrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
