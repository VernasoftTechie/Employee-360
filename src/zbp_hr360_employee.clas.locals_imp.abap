*"* Local handler classes for ZBP_HR360_EMPLOYEE (unmanaged, read-only).
*"*
*"* Signatures below are written to the standard unmanaged-RAP pattern. If ADT
*"* reports a signature mismatch on activation, delete the method signature (not
*"* the body) and re-add it via Quick Fix, then paste the body back.

CLASS lhc_employee DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR employee RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR employee RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ employee RESULT result.

    METHODS rba_personal FOR READ
      IMPORTING keys_rba FOR READ employee\_Personal FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_orgassignment FOR READ
      IMPORTING keys_rba FOR READ employee\_OrgAssignment FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_education FOR READ
      IMPORTING keys_rba FOR READ employee\_Education FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_qualification FOR READ
      IMPORTING keys_rba FOR READ employee\_Qualification FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_leavebalance FOR READ
      IMPORTING keys_rba FOR READ employee\_LeaveBalance FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_attendance FOR READ
      IMPORTING keys_rba FOR READ employee\_Attendance FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_payroll FOR READ
      IMPORTING keys_rba FOR READ employee\_Payroll FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_document FOR READ
      IMPORTING keys_rba FOR READ employee\_Document FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_timeline FOR READ
      IMPORTING keys_rba FOR READ employee\_Timeline FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_dataquality FOR READ
      IMPORTING keys_rba FOR READ employee\_DataQuality FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_manager FOR READ
      IMPORTING keys_rba FOR READ employee\_Manager FULL result_requested
      RESULT result LINK association_links.

    METHODS rba_directreport FOR READ
      IMPORTING keys_rba FOR READ employee\_DirectReport FULL result_requested
      RESULT result LINK association_links.

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

  METHOD get_instance_authorizations.
    IF keys IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM zi_hr360_orgassign
      FIELDS employeeid, personnelarea, employeegroup, employeesubgroup
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
      INTO TABLE @DATA(orgs).

    LOOP AT keys INTO DATA(key).
      DATA(org) = VALUE #( orgs[ employeeid = key-EmployeeID ] OPTIONAL ).
      AUTHORITY-CHECK OBJECT 'P_ORGIN'
        ID 'INFTY' FIELD '0001'
        ID 'SUBTY' DUMMY
        ID 'AUTHC' FIELD 'R'
        ID 'PERSA' FIELD org-personnelarea
        ID 'PERSG' FIELD org-employeegroup
        ID 'PERSK' FIELD org-employeesubgroup
        ID 'VDSK1' DUMMY.
      DATA(allowed) = COND #( WHEN sy-subrc = 0
                              THEN if_abap_behv=>auth-allowed
                              ELSE if_abap_behv=>auth-unauthorized ).
      APPEND VALUE #( %tky = key-%tky
                      %msg = ODATA
                      %auth-%read = allowed ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
    SELECT FROM zi_hr360_employee
      FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD rba_personal.
    SELECT FROM zi_hr360_personal
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID = r-employeeid
        target-%tky-EmployeeID = r-employeeid ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_orgassignment.
    SELECT FROM zi_hr360_orgassign
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID = r-employeeid
        target-%tky-EmployeeID = r-employeeid ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_education.
    SELECT FROM zi_hr360_education
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID    = r-employeeid
        target-%tky-EmployeeID    = r-employeeid
        target-%tky-EducationType = r-educationtype
        target-%tky-ValidFrom     = r-validfrom ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_qualification.
    SELECT FROM zi_hr360_qualif
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID      = r-employeeid
        target-%tky-EmployeeID      = r-employeeid
        target-%tky-QualificationID = r-qualificationid
        target-%tky-ValidFrom       = r-validfrom ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_leavebalance.
    SELECT FROM zi_hr360_leave
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID    = r-employeeid
        target-%tky-EmployeeID    = r-employeeid
        target-%tky-QuotaType     = r-quotatype
        target-%tky-DeductionFrom = r-deductionfrom ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_attendance.
    SELECT FROM zi_hr360_attendance
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID     = r-employeeid
        target-%tky-EmployeeID     = r-employeeid
        target-%tky-AttendanceFrom = r-attendancefrom
        target-%tky-AttendanceType = r-attendancetype ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_payroll.
    SELECT FROM zi_hr360_payroll
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID = r-employeeid
        target-%tky-EmployeeID = r-employeeid
        target-%tky-ValidFrom  = r-validfrom ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_document.
    SELECT FROM zi_hr360_document
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID  = r-employeeid
        target-%tky-EmployeeID  = r-employeeid
        target-%tky-ArchivDocID = r-archivdocid ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_timeline.
    SELECT FROM zi_hr360_timeline
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID    = r-employeeid
        target-%tky-EmployeeID    = r-employeeid
        target-%tky-EventDate     = r-eventdate
        target-%tky-EventCategory = r-eventcategory
        target-%tky-EventSeqNr    = r-eventseqnr ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_dataquality.
    SELECT FROM zi_hr360_issue
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID = r-employeeid
        target-%tky-EmployeeID = r-employeeid
        target-%tky-CheckID    = r-checkid ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

  METHOD rba_manager.
    " parent's ManagerID -> the manager employee row
    SELECT FROM zi_hr360_employee
      FIELDS *
      FOR ALL ENTRIES IN @keys_rba
      WHERE employeeid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(parents).

    LOOP AT parents INTO DATA(parent).
      CHECK parent-managerid IS NOT INITIAL.
      SELECT SINGLE FROM zi_hr360_employee
        FIELDS *
        WHERE employeeid = @parent-managerid
        INTO @DATA(mgr).
      IF sy-subrc = 0.
        APPEND VALUE #( source-%tky-EmployeeID = parent-employeeid
                        target-%tky-EmployeeID = mgr-employeeid ) TO association_links.
        IF result_requested = abap_true.
          APPEND CORRESPONDING #( mgr ) TO result.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_directreport.
    SELECT FROM zi_hr360_employee AS rep
      FIELDS rep~*
      FOR ALL ENTRIES IN @keys_rba
      WHERE rep~managerid = @keys_rba-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @DATA(rows).
    association_links = VALUE #( FOR r IN rows
      ( source-%tky-EmployeeID = r-managerid
        target-%tky-EmployeeID = r-employeeid ) ).
    IF result_requested = abap_true.
      result = CORRESPONDING #( rows ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


*"* Composition child handlers - straight reads from the child interface views.

CLASS lhc_child_reader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read_personal      FOR READ IMPORTING keys FOR READ personal      RESULT result.
    METHODS read_orgassignment FOR READ IMPORTING keys FOR READ orgassignment RESULT result.
    METHODS read_education      FOR READ IMPORTING keys FOR READ education     RESULT result.
    METHODS read_qualification  FOR READ IMPORTING keys FOR READ qualification RESULT result.
    METHODS read_leavebalance   FOR READ IMPORTING keys FOR READ leavebalance  RESULT result.
    METHODS read_attendance     FOR READ IMPORTING keys FOR READ attendance    RESULT result.
    METHODS read_payroll        FOR READ IMPORTING keys FOR READ payrollitem   RESULT result.
    METHODS read_document       FOR READ IMPORTING keys FOR READ document      RESULT result.
ENDCLASS.

CLASS lhc_child_reader IMPLEMENTATION.

  METHOD read_personal.
    SELECT FROM zi_hr360_personal FIELDS *
      FOR ALL ENTRIES IN @keys WHERE employeeid = @keys-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD read_orgassignment.
    SELECT FROM zi_hr360_orgassign FIELDS *
      FOR ALL ENTRIES IN @keys WHERE employeeid = @keys-EmployeeID
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD read_education.
    SELECT FROM zi_hr360_education FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
        AND educationtype = @keys-EducationType
        AND validfrom = @keys-ValidFrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD read_qualification.
    SELECT FROM zi_hr360_qualif FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
        AND qualificationid = @keys-QualificationID
        AND validfrom = @keys-ValidFrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD read_leavebalance.
    SELECT FROM zi_hr360_leave FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
        AND quotatype = @keys-QuotaType
        AND deductionfrom = @keys-DeductionFrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD read_attendance.
    SELECT FROM zi_hr360_attendance FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
        AND attendancefrom = @keys-AttendanceFrom
        AND attendancetype = @keys-AttendanceType
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD read_payroll.
    SELECT FROM zi_hr360_payroll FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
        AND validfrom = @keys-ValidFrom
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

  METHOD read_document.
    SELECT FROM zi_hr360_document FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid = @keys-EmployeeID
        AND archivdocid = @keys-ArchivDocID
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.

ENDCLASS.
