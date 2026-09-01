*&---------------------------------------------------------------------*
*& Report ZHR360_R_MISSING_DATA
*&---------------------------------------------------------------------*
*& HR Employee 360 - Missing Data Validation.
*& Operational worklist of data-quality gaps (ZI_HR360_ISSUE), grouped by
*& severity. Thin shell over ZCL_HR360_REPORT_ENGINE.
*&---------------------------------------------------------------------*
REPORT zhr360_r_missing_data.

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
  p_keydt TYPE datum DEFAULT sy-datum.


CLASS lcl_app DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS run.
  PRIVATE SECTION.
    CLASS-METHODS build_scope RETURNING VALUE(rs_scope) TYPE zif_hr360_report_engine=>ty_scope.
ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD run.
    AUTHORITY-CHECK OBJECT 'P_ORGIN'
      ID 'INFTY' FIELD '0001'
      ID 'AUTHC' FIELD 'R'
      ID 'PERSA' DUMMY ID 'PERSG' DUMMY ID 'PERSK' DUMMY ID 'VDSK1' DUMMY.
    IF sy-subrc <> 0.
      MESSAGE e001(zmsg_hr360).
    ENDIF.

    DATA(engine) = CAST zif_hr360_report_engine( NEW zcl_hr360_report_engine( ) ).
    DATA(data)   = engine->get_missing_data( build_scope( ) ).

    IF data IS INITIAL.
      MESSAGE s002(zmsg_hr360).
      RETURN.
    ENDIF.

    DATA(critical) = REDUCE i( INIT n = 0 FOR w IN data
                               NEXT n = COND #( WHEN w-severity = 'C' THEN n + 1 ELSE n ) ).
    MESSAGE s003(zmsg_hr360) WITH |{ lines( data ) }| |{ critical }|.

    DATA lt TYPE zif_hr360_report_engine=>ty_issue_tab.
    lt = data.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_alv)
                                CHANGING  t_table      = lt ).
        lo_alv->get_functions( )->set_all( ).
        lo_alv->get_columns( )->set_optimize( ).
        lo_alv->get_aggregations( ).
        DATA(lo_sorts) = lo_alv->get_sorts( ).
        lo_sorts->add_sort( columnname = 'SEVERITY'  subtotal = abap_true ).
        lo_sorts->add_sort( columnname = 'CATEGORY'  subtotal = abap_true ).
        lo_alv->get_display_settings( )->set_list_header( 'HR Employee 360 - Missing Data Validation' ).
        lo_alv->display( ).
      CATCH cx_salv_error INTO DATA(lx).
        MESSAGE lx->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD build_scope.
    rs_scope = VALUE #(
      pernr    = s_pernr[]
      bukrs    = s_bukrs[]
      werks    = s_werks[]
      orgeh    = s_orgeh[]
      key_date = p_keydt ).
  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.
  lcl_app=>run( ).
