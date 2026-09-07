"! <p class="shorttext synchronized">HR360 - ABAP Unit for the check framework</p>
"!
"! Tests ZI_HR360_ISSUE (the UNION check framework) in isolation from real PA
"! data, using the CDS Test Double Framework. Adapted from
"! HR_DataQuality_RAP_PoC. One method per representative branch; keep
"! put_complete_employee in sync with every check that reads a field.
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
      td_qual    TYPE STANDARD TABLE OF zi_hr360_qualif      WITH EMPTY KEY,
      td_leave   TYPE STANDARD TABLE OF zi_hr360_leave       WITH EMPTY KEY,
      td_doc     TYPE STANDARD TABLE OF zi_hr360_document    WITH EMPTY KEY.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.

    METHODS full_employee_no_issues   FOR TESTING.
    METHODS missing_dob_flagged       FOR TESTING.
    METHODS missing_iban_flagged      FOR TESTING.
    METHODS local_bank_key_is_ok      FOR TESTING.
    METHODS missing_orgunit_flagged   FOR TESTING.
    METHODS missing_mobile_flagged    FOR TESTING.
    METHODS incomplete_payscale_flag  FOR TESTING.
    METHODS missing_paymethod_flagged FOR TESTING.
    METHODS no_documents_flagged      FOR TESTING.
    METHODS no_leave_quota_flagged    FOR TESTING.
    METHODS expired_quals_flagged     FOR TESTING.

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
        ( i_for_entity = 'ZI_HR360_QUALIF' )
        ( i_for_entity = 'ZI_HR360_LEAVE' )
        ( i_for_entity = 'ZI_HR360_DOCUMENT' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    environment->clear_doubles( ).
    CLEAR: td_basic, td_pay, td_contact, td_bank, td_edu, td_qual, td_leave, td_doc.
  ENDMETHOD.

  METHOD put_complete_employee.
    " every field that any ZI_HR360_ISSUE branch inspects must be non-initial here
    td_basic = VALUE #( BASE td_basic
      ( employeeid       = iv_pernr
        lastname         = 'Doe'
        firstname        = 'Jane'
        dateofbirth      = '19900101'
        gender           = 'F'
        nationality      = 'US'
        maritalstatus    = '1'
        companycode      = '1000'
        personnelarea    = '1000'
        personnelsubarea = '0001'
        employeegroup    = '1'
        employeesubgroup = 'U2'
        orgunit          = '50000001'
        costcenter       = '0000001000'
        positionid       = '99999999'
        job              = '50000123'
        payrolladmin     = 'PAY01'
        timeadmin        = 'TIM01'
        hradmin          = 'HR01' ) ).
    td_pay     = VALUE #( BASE td_pay
      ( employeeid = iv_pernr payscaletype = '01' payscalearea = '01'
        payscalegroup = 'A1' payscalelevel = '01' ) ).
    td_contact = VALUE #( BASE td_contact
      ( employeeid = iv_pernr emailaddress = 'jane.doe@corp.com'
        mobilenumber = '+1 555 0100' street = '1 Main St' city = 'Town'
        postalcode = '12345' country = 'US' ) ).
    td_bank    = VALUE #( BASE td_bank
      ( employeeid = iv_pernr iban = 'DE00000000000000000000'
        bankkey = '10000000' bankaccount = '1234567890' paymentmethod = 'T' ) ).
    td_edu     = VALUE #( BASE td_edu
      ( employeeid = iv_pernr educationtypecode = '0001' validfrom = '20100101' ) ).
    td_qual    = VALUE #( BASE td_qual
      ( employeeid = iv_pernr qualificationid = 'Q0000001'
        validfrom = '20150101' validto = '99991231' isexpired = ' ' ) ).
    td_leave   = VALUE #( BASE td_leave
      ( employeeid = iv_pernr quotatype = '01'
        deductionfrom = '20000101' deductionto = '99991231'
        entitlement = 30 deducted = 5 remaining = 25 ) ).
    td_doc     = VALUE #( BASE td_doc
      ( employeeid = iv_pernr archivdocid = 'DOC0000000000000000000000000000000000001' ) ).
  ENDMETHOD.

  METHOD insert_all.
    environment->insert_test_data( td_basic ).
    environment->insert_test_data( td_pay ).
    environment->insert_test_data( td_contact ).
    environment->insert_test_data( td_bank ).
    environment->insert_test_data( td_edu ).
    environment->insert_test_data( td_qual ).
    environment->insert_test_data( td_leave ).
    environment->insert_test_data( td_doc ).
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
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000002' iv_check = 'MAND_DOB' ) exp = 1 ).
  ENDMETHOD.

  METHOD missing_iban_flagged.
    put_complete_employee( '00000003' ).
    td_bank[ employeeid = '00000003' ]-iban        = ''.
    td_bank[ employeeid = '00000003' ]-bankkey     = ''.
    td_bank[ employeeid = '00000003' ]-bankaccount = ''.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000003' iv_check = 'BANK_IBAN' ) exp = 1 ).
  ENDMETHOD.

  METHOD local_bank_key_is_ok.
    " IBAN blank but bank key + account present -> NOT an issue (rule loosened)
    put_complete_employee( '00000004' ).
    td_bank[ employeeid = '00000004' ]-iban = ''.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000004' iv_check = 'BANK_IBAN' ) exp = 0 ).
  ENDMETHOD.

  METHOD missing_orgunit_flagged.
    put_complete_employee( '00000005' ).
    td_basic[ employeeid = '00000005' ]-orgunit = '00000000'.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000005' iv_check = 'ORG_ORGUNIT' ) exp = 1 ).
  ENDMETHOD.

  METHOD missing_mobile_flagged.
    put_complete_employee( '00000006' ).
    td_contact[ employeeid = '00000006' ]-mobilenumber = ''.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000006' iv_check = 'COMM_MOBILE' ) exp = 1 ).
  ENDMETHOD.

  METHOD incomplete_payscale_flag.
    put_complete_employee( '00000007' ).
    td_pay[ employeeid = '00000007' ]-payscalegroup = ''.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000007' iv_check = 'PSCL_GRP' ) exp = 1 ).
  ENDMETHOD.

  METHOD missing_paymethod_flagged.
    put_complete_employee( '00000008' ).
    td_bank[ employeeid = '00000008' ]-paymentmethod = ''.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000008' iv_check = 'BANK_PAYMETH' ) exp = 1 ).
  ENDMETHOD.

  METHOD no_documents_flagged.
    put_complete_employee( '00000009' ).
    CLEAR td_doc.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000009' iv_check = 'DOC_NONE' ) exp = 1 ).
  ENDMETHOD.

  METHOD no_leave_quota_flagged.
    put_complete_employee( '00000010' ).
    CLEAR td_leave.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000010' iv_check = 'LEAVE_NOQUOTA' ) exp = 1 ).
  ENDMETHOD.

  METHOD expired_quals_flagged.
    " has a qualification, but it has lapsed -> QUAL_EXPIRED, not QUAL_MISSING
    put_complete_employee( '00000011' ).
    td_qual[ employeeid = '00000011' ]-validto   = '20200101'.
    td_qual[ employeeid = '00000011' ]-isexpired = 'X'.
    cl_abap_unit_assert=>assert_equals(
      act = count_check( iv_pernr = '00000011' iv_check = 'QUAL_EXPIRED' ) exp = 1 ).
  ENDMETHOD.

ENDCLASS.
