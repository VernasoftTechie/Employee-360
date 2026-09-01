"! <p class="shorttext synchronized">HR360 - ABAP Unit for the check framework</p>
"!
"! Tests ZI_HR360_ISSUE (the 12-branch UNION check framework) in isolation from
"! real PA data, using the CDS Test Double Framework. Adapted from
"! HR_DataQuality_RAP_PoC (ZCL_HRDQ_ISSUE_TEST) - the catalog table is gone, so
"! there is no "inactive check" case; instead every branch is asserted directly.
"! Add one test method per branch when ZI_HR360_ISSUE is extended.
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

    METHODS full_employee_no_issues   FOR TESTING.
    METHODS missing_dob_flagged        FOR TESTING.
    METHODS missing_gender_flagged     FOR TESTING.
    METHODS missing_costcenter_flagged FOR TESTING.
    METHODS missing_email_flagged      FOR TESTING.
    METHODS missing_iban_flagged       FOR TESTING.
    METHODS future_dob_flagged         FOR TESTING.
    METHODS no_education_flagged        FOR TESTING.

    METHODS issues_for
      IMPORTING iv_pernr        TYPE pernr_d
      RETURNING VALUE(rt_result) TYPE STANDARD TABLE OF zi_hr360_issue.

    METHODS put_complete_employee
      IMPORTING iv_pernr TYPE pernr_d.

ENDCLASS.


CLASS zcl_hr360_issue_test IMPLEMENTATION.

  METHOD class_setup.
    environment = cl_cds_test_environment=>create(
      i_for_entity = 'ZI_HR360_ISSUE'
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
    APPEND VALUE #( employeeid = iv_pernr
                    lastname = 'Doe' firstname = 'Jane'
                    dateofbirth = '19900101' gender = 'F' nationality = 'US'
                    costcenter = '0000001000' position = '99999999'
                    orgunit = '50000001' companycode = '1000'
                    employmentstatus = '3' ) TO td_basic.
    APPEND VALUE #( employeeid = iv_pernr trfgr = 'A1' ) TO td_pay.
    APPEND VALUE #( employeeid = iv_pernr emailaddress = 'jane.doe@corp.com'
                    country = 'US' ) TO td_contact.
    APPEND VALUE #( employeeid = iv_pernr iban = 'DE00000000000000000000' ) TO td_bank.
    APPEND VALUE #( employeeid = iv_pernr educationtype = '0001'
                    validfrom = '20100101' ) TO td_edu.
    APPEND VALUE #( employeeid = iv_pernr qualificationid = 'Q0000001'
                    validfrom = '20150101' ) TO td_qual.
  ENDMETHOD.

  METHOD issues_for.
    environment->insert_test_data( td_basic ).
    environment->insert_test_data( td_pay ).
    environment->insert_test_data( td_contact ).
    environment->insert_test_data( td_bank ).
    environment->insert_test_data( td_edu ).
    environment->insert_test_data( td_qual ).
    SELECT * FROM zi_hr360_issue
      WHERE employeeid = @iv_pernr
      INTO TABLE @rt_result.
  ENDMETHOD.

  METHOD full_employee_no_issues.
    put_complete_employee( '00000001' ).
    cl_abap_unit_assert=>assert_initial(
      act = issues_for( '00000001' )
      msg = 'A fully populated employee must have zero issues' ).
  ENDMETHOD.

  METHOD missing_dob_flagged.
    put_complete_employee( '00000002' ).
    td_basic[ employeeid = '00000002' ]-dateofbirth = '00000000'.
    DATA(issues) = issues_for( '00000002' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( FILTER #( issues USING KEY primary_key WHERE checkid = 'MAND_DOB' ) )
      exp = 1 ).
  ENDMETHOD.

  METHOD missing_gender_flagged.
    put_complete_employee( '00000003' ).
    td_basic[ employeeid = '00000003' ]-gender = ''.
    cl_abap_unit_assert=>assert_equals(
      act = lines( FILTER #( issues_for( '00000003' ) USING KEY primary_key WHERE checkid = 'MAND_GENDER' ) )
      exp = 1 ).
  ENDMETHOD.

  METHOD missing_costcenter_flagged.
    put_complete_employee( '00000004' ).
    td_basic[ employeeid = '00000004' ]-costcenter = ''.
    cl_abap_unit_assert=>assert_equals(
      act = lines( FILTER #( issues_for( '00000004' ) USING KEY primary_key WHERE checkid = 'ORG_COSTCTR' ) )
      exp = 1 ).
  ENDMETHOD.

  METHOD missing_email_flagged.
    put_complete_employee( '00000005' ).
    td_contact[ employeeid = '00000005' ]-emailaddress = ''.
    cl_abap_unit_assert=>assert_equals(
      act = lines( FILTER #( issues_for( '00000005' ) USING KEY primary_key WHERE checkid = 'CONTACT_MAIL' ) )
      exp = 1 ).
  ENDMETHOD.

  METHOD missing_iban_flagged.
    put_complete_employee( '00000006' ).
    td_bank[ employeeid = '00000006' ]-iban = ''.
    cl_abap_unit_assert=>assert_equals(
      act = lines( FILTER #( issues_for( '00000006' ) USING KEY primary_key WHERE checkid = 'BANK_IBAN' ) )
      exp = 1 ).
  ENDMETHOD.

  METHOD future_dob_flagged.
    put_complete_employee( '00000007' ).
    td_basic[ employeeid = '00000007' ]-dateofbirth = cl_abap_context_info=>get_system_date( ) + 30.
    cl_abap_unit_assert=>assert_equals(
      act = lines( FILTER #( issues_for( '00000007' ) USING KEY primary_key WHERE checkid = 'INVALID_DOB' ) )
      exp = 1 ).
  ENDMETHOD.

  METHOD no_education_flagged.
    put_complete_employee( '00000008' ).
    CLEAR td_edu.
    cl_abap_unit_assert=>assert_equals(
      act = lines( FILTER #( issues_for( '00000008' ) USING KEY primary_key WHERE checkid = 'EDU_MISSING' ) )
      exp = 1 ).
  ENDMETHOD.

ENDCLASS.
