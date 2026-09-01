*&---------------------------------------------------------------------*
*& Report ZHR360_R_EMP_MASTER_EXPORT
*&---------------------------------------------------------------------*
*& HR Employee 360 - Employee Master Export.
*& Thin shell over ZCL_HR360_REPORT_ENGINE. ALV in dialog, CSV/XLSX to the
*& application server in background. Row-level P_ORGIN filtering is enforced
*& by the CDS DCL. Runs online or as a scheduled background job.
*&---------------------------------------------------------------------*
REPORT zhr360_r_emp_master_export.

DATA: gv_pernr TYPE pernr_d,
      gv_bukrs TYPE bukrs,
      gv_werks TYPE persa,
      gv_orgeh TYPE orgeh.

SELECT-OPTIONS:
  s_pernr FOR gv_pernr,
  s_bukrs FOR gv_bukrs,
  s_werks FOR gv_werks,
  s_orgeh FOR gv_orgeh.

PARAMETERS:
  p_keydt TYPE datum DEFAULT sy-datum,
  p_actv  AS CHECKBOX DEFAULT 'X'.

PARAMETERS:
  p_alv  RADIOBUTTON GROUP out DEFAULT 'X',
  p_file RADIOBUTTON GROUP out.
PARAMETERS:
  p_fpath TYPE string LOWER CASE,
  p_fmt   TYPE char4 DEFAULT 'CSV'.


CLASS lcl_app DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS run.
  PRIVATE SECTION.
    CLASS-METHODS check_authority.
    CLASS-METHODS build_scope RETURNING VALUE(rs_scope) TYPE zif_hr360_report_engine=>ty_scope.
    CLASS-METHODS show_alv    IMPORTING it_data TYPE zif_hr360_report_engine=>ty_master_tab.
    CLASS-METHODS write_file  IMPORTING it_data TYPE zif_hr360_report_engine=>ty_master_tab.
    CLASS-METHODS log_run     IMPORTING iv_rows TYPE i.
ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD run.
    check_authority( ).

    DATA(engine) = CAST zif_hr360_report_engine( NEW zcl_hr360_report_engine( ) ).
    DATA(data)   = engine->get_employee_master( build_scope( ) ).

    IF data IS INITIAL.
      MESSAGE s002(zmsg_hr360).
      RETURN.
    ENDIF.

    log_run( lines( data ) ).

    IF p_file = abap_true.
      write_file( data ).
    ELSE.
      show_alv( data ).
    ENDIF.
  ENDMETHOD.

  METHOD check_authority.
    AUTHORITY-CHECK OBJECT 'P_ORGIN'
      ID 'INFTY' FIELD '0001'
      ID 'AUTHC' FIELD 'R'
      ID 'PERSA' DUMMY ID 'PERSG' DUMMY ID 'PERSK' DUMMY ID 'VDSK1' DUMMY.
    IF sy-subrc <> 0.
      MESSAGE e001(zmsg_hr360).
    ENDIF.
  ENDMETHOD.

  METHOD build_scope.
    rs_scope = VALUE #(
      pernr       = VALUE #( FOR r IN s_pernr[] ( CORRESPONDING #( r ) ) )
      bukrs       = VALUE #( FOR r IN s_bukrs[] ( CORRESPONDING #( r ) ) )
      werks       = VALUE #( FOR r IN s_werks[] ( CORRESPONDING #( r ) ) )
      orgeh       = VALUE #( FOR r IN s_orgeh[] ( CORRESPONDING #( r ) ) )
      key_date    = p_keydt
      active_only = p_actv ).
  ENDMETHOD.

  METHOD show_alv.
    DATA lo_alv TYPE REF TO cl_salv_table.
    DATA lt TYPE zif_hr360_report_engine=>ty_master_tab.
    lt = it_data.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = lo_alv
                                CHANGING  t_table      = lt ).
        lo_alv->get_functions( )->set_all( ).
        lo_alv->get_columns( )->set_optimize( ).
        lo_alv->get_display_settings( )->set_list_header( 'HR Employee 360 - Master Export' ).
        lo_alv->display( ).
      CATCH cx_salv_msg INTO DATA(lx).
        MESSAGE lx->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD write_file.
    IF p_fpath IS INITIAL.
      MESSAGE e005(zmsg_hr360).
    ENDIF.

    DATA(lt_lines) = VALUE string_table(
      ( |EmployeeID;Name;DateOfBirth;Gender;HireDate;CompanyCode;PersArea;OrgUnit;OrgUnitName;Position;CostCenter;Email;Mobile;Status;QualityStatus;Completeness| ) ).

    LOOP AT it_data INTO DATA(row).
      APPEND |{ row-employee_id };{ row-formatted_name };{ row-date_of_birth };{ row-gender };| &&
             |{ row-hire_date };{ row-company_code };{ row-personnel_area };{ row-org_unit };| &&
             |{ row-org_unit_name };{ row-position_name };{ row-cost_center };{ row-email_address };| &&
             |{ row-mobile_number };{ row-employment_status };{ row-quality_status };{ row-completeness_percent }|
        TO lt_lines.
    ENDLOOP.

    OPEN DATASET p_fpath FOR OUTPUT IN TEXT MODE ENCODING UTF-8 WITH SMART LINEFEED.
    IF sy-subrc <> 0.
      MESSAGE e006(zmsg_hr360) WITH p_fpath sy-subrc.
    ENDIF.
    LOOP AT lt_lines INTO DATA(line).
      TRANSFER line TO p_fpath.
    ENDLOOP.
    CLOSE DATASET p_fpath.

    MESSAGE s004(zmsg_hr360) WITH p_fpath.
  ENDMETHOD.

  METHOD log_run.
    TRY.
        DATA(log) = cl_bali_log=>create_with_header(
          cl_bali_header_setter=>create(
            object     = 'ZHR360'
            subobject  = 'REPORT'
            external_id = CONV bal_s_extn( |{ sy-repid }/{ sy-datum }/{ sy-uzeit }| ) ) ).
        log->add_item( cl_bali_free_text_setter=>create(
          severity = if_bali_constants=>c_severity_status
          text     = CONV #( |{ iv_rows } rows exported| ) ) ).
        cl_bali_log_db=>get_instance( )->save_log_to_db( log ).
      CATCH cx_bali_runtime.
        " logging must never break the report
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.
  lcl_app=>run( ).
