"! <p class="shorttext synchronized">HR360 - ABAP Unit for the check framework</p>
"!
"! Tests ZI_HR360_ISSUE (the UNION check framework) in isolation from real PA
"! data, using the CDS Test Double Framework. Adapted from
"! HR_DataQuality_RAP_PoC. Extend with one method per branch as needed.
CLASS zcl_hr360_issue_test DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CLASS-DATA environment TYPE REF TO if_cds_test_environment.

    DATA:
      td_basic   TYPE STANDARD TABLE OF zi_hr360_emp_basic   WITH EMPTY KEY,
      td_pay     TYPE STANDARD TABLE OF zi_hr360_emp_pay     WITH EMPTY KEY,
      td_contact TYPE STANDARD TABLE OF zi_hr360_emp_contact WITH EMPTY KEY,
      td_bank    TYPE STANDARD TABLE OF zi_hr360_emp_bank    WITH EMPTY KEY,
      td_edu     TYPE STANDARD TABLE OF zi_hr360_education   WITH EMPTY KEY,
      td_qual    TYPE STANDARD TABLE OF zi_hr360_qualif      WITH EMPTY KEY.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.

    METHODS full_employee_no_issues FOR TESTING.
    METHODS missing_dob_flagged     FOR TESTING.
    METHODS missing_iban_flagged    FOR TESTING.

    METHODS put_complete_employee IMPORTING iv_pernr TYPE pernr_d.
    METHODS insert_all.
    METHODS count_check
      IMPORTING iv_pernr        TYPE pernr_d
                iv_check        TYPE string
      RETURNING VALUE(rv_count) TYPE i.

ENDCLASS.


CLASS zcl_hr360_issue_test IMPLEMENTATION.

  METHOD class_setup.
    environment = cl_cds_test_environment=>create(
      i_for_entity      = 'ZI_HR360_ISSUE'
      i_dependency_list = VALUE #(
        ( i_for_entity = 'ZI_HR360_EMP_BASIC' )
        ( i_for_entity = 'ZI_HR360_EMP_PAY' )
        ( i_for_entity = 'ZI_HR360_EMP_CONTACT' )
        ( i_for_entity = 'ZI_HR360_EMP_BANK' )
        ( i_for_entity = 'ZI_HR360_EDUCATION' )
        ( i_for_entity = 'ZI_HR360_QUALIF' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    environment->clear_doubles( ).
    CLEAR: td_basic, td_pay, td_contact, td_bank, td_edu, td_qual.
  ENDMETHOD.

  METHOD put_complete_employee.
    td_basic = VALUE #( BASE td_basic
      ( employeeid = iv_pernr lastname = 'Doe' firstname = 'Jane'
        dateofbirth = '19900101' gender = 'F' nationality = 'US'
        costcenter = '0000001000' positionid = '99999999'
        orgunit = '50000001' companycode = '1000' employmentstatus = '3' ) ).
    td_pay     = VALUE #( BASE td_pay     ( employeeid = iv_pernr trfgr = 'A1' ) ).
    td_contact = VALUE #( BASE td_contact ( employeeid = iv_pernr emailaddress = 'jane.doe@corp.com' country = 'US' ) ).
    td_bank    = VALUE #( BASE td_bank    ( employeeid = iv_pernr iban = 'DE00000000000000000000' ) ).
    td_edu     = VALUE #( BASE td_edu     ( employeeid = iv_pernr educationtypecode = '0001' validfrom = '20100101' ) ).
    td_qual    = VALUE #( BASE td_qual    ( employeeid = iv_pernr qualificationid = 'Q0000001' validfrom = '20150101' ) ).
  ENDMETHOD.

  METHOD insert_all.
    environment->insert_test_data( td_basic ).
    environment->insert_test_data( td_pay ).
    environment->insert_test_data( td_contact ).
    environment->insert_test_data( td_bank ).
    environment->insert_test_data( td_edu ).
    environment->insert_test_data( td_qual ).
  ENDMETHOD.

  METHOD count_check.
    insert_all( ).
    SELECT COUNT(*) FROM zi_hr360_issue
      WHERE employeeid = @iv_pernr AND checkid = @iv_check
      INTO @rv_count.
  ENDMETHOD.

  METHOD full_employee_no_issues.
    put_complete_employee( '00000001' ).
    insert_all( ).
    SELECT COUNT(*) FROM zi_hr360_issue WHERE employeeid = '00000001' INTO @DATA(cnt).
    cl_abap_unit_assert=>assert_equals( act = cnt exp = 0
      msg = 'A fully populated employee must have zero issues' ).
  ENDMETHOD.

  METHOD missing_dob_flagged.
    put_complete_employee( '00000002' ).
    td_basic[ employeeid = '00000002' ]-dateofbirth = '00000000'.
    cl_abap_unit_assert=>assert_equals( act = count_check( iv_pernr = '00000002' iv_check = 'MAND_DOB' ) exp = 1 ).
  ENDMETHOD.

  METHOD missing_iban_flagged.
    put_complete_employee( '00000003' ).
    td_bank[ employeeid = '00000003' ]-iban = ''.
    cl_abap_unit_assert=>assert_equals( act = count_check( iv_pernr = '00000003' iv_check = 'BANK_IBAN' ) exp = 1 ).
  ENDMETHOD.

ENDCLASS.
