*"* Local handler for ZBP_HR360_EMPLOYEE (unmanaged, read-only).
*"* If ADT reports a signature mismatch on activation, delete the METHODS line
*"* (not the body) and re-add it via Quick Fix, then paste the body back.

CLASS lhc_employee DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR employee RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ employee RESULT result.

ENDCLASS.


CLASS lhc_employee IMPLEMENTATION.

  METHOD get_global_authorizations.
    AUTHORITY-CHECK OBJECT 'P_ORGIN'
      ID 'INFTY' FIELD '0001'
      ID 'SUBTY' DUMMY
      ID 'AUTHC' FIELD 'R'
      ID 'PERSA' DUMMY
      ID 'PERSG' DUMMY
      ID 'PERSK' DUMMY
      ID 'VDSK1' DUMMY.
    DATA(allowed) = COND #( WHEN sy-subrc = 0
                            THEN if_abap_behv=>auth-allowed
                            ELSE if_abap_behv=>auth-unauthorized ).
    result-%read   = allowed.
    result-%update = if_abap_behv=>auth-unauthorized.
    result-%delete = if_abap_behv=>auth-unauthorized.
  ENDMETHOD.

  METHOD read.
    SELECT FROM zi_hr360_employee
      FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

ENDCLASS.
