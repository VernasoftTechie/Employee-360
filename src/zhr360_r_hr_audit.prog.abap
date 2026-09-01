*&---------------------------------------------------------------------*
*& Report ZHR360_R_HR_AUDIT
*&---------------------------------------------------------------------*
*& HR Employee 360 - HR Audit Report.
*& Management view of data-completeness health by organization, from
*& ZC_HR360_KPI_OVERVIEW. Summary block + detail ALV.
*&---------------------------------------------------------------------*
REPORT zhr360_r_hr_audit.

TABLES: pa0001.

SELECT-OPTIONS:
  s_bukrs FOR pa0001-bukrs,
  s_werks FOR pa0001-werks,
  s_orgeh FOR pa0001-orgeh.

PARAMETERS:
  p_keydt TYPE datum DEFAULT sy-datum.


CLASS lcl_app DEFINITION FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS run.
  PRIVATE SECTION.
    CLASS-METHODS build_scope RETURNING VALUE(rs_scope) TYPE zif_hr360_report_engine=>ty_scope.
    CLASS-METHODS print_summary IMPORTING is TYPE zif_hr360_report_engine=>ty_audit_summary.
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

    DATA(engine)  = CAST zif_hr360_report_engine( NEW zcl_hr360_report_engine( ) ).
    DATA(scope)   = build_scope( ).
    DATA(summary) = engine->get_audit_summary( scope ).
    DATA(detail)  = engine->get_audit_detail( scope ).

    IF detail IS INITIAL.
      MESSAGE s002(zmsg_hr360).
      RETURN.
    ENDIF.

    print_summary( summary ).

    DATA lt TYPE zif_hr360_report_engine=>ty_audit_tab.
    lt = detail.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = DATA(lo_alv)
                                CHANGING  t_table      = lt ).
        lo_alv->get_functions( )->set_all( ).
        lo_alv->get_columns( )->set_optimize( ).
        lo_alv->get_display_settings( )->set_list_header( 'HR Employee 360 - HR Audit (detail)' ).
        lo_alv->display( ).
      CATCH cx_salv_msg INTO DATA(lx).
        MESSAGE lx->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

  METHOD print_summary.
    WRITE: / 'HR Employee 360 - HR Audit Report'.
    WRITE: / 'Key date            :', p_keydt.
    ULINE.
    WRITE: / 'Total employees     :', is-total_employees.
    WRITE: / 'With issues         :', is-with_issues.
    WRITE: / 'Without issues      :', is-without_issues.
    WRITE: / 'Critical issues     :', is-critical_count.
    WRITE: / 'Warning issues      :', is-warning_count.
    WRITE: / 'Missing data points :', is-missing_data.
    WRITE: / 'Avg completeness %  :', is-avg_completeness.
    ULINE.
    SKIP.
  ENDMETHOD.

  METHOD build_scope.
    rs_scope = VALUE #(
      bukrs    = VALUE #( FOR r IN s_bukrs[] ( CORRESPONDING #( r ) ) )
      werks    = VALUE #( FOR r IN s_werks[] ( CORRESPONDING #( r ) ) )
      orgeh    = VALUE #( FOR r IN s_orgeh[] ( CORRESPONDING #( r ) ) )
      key_date = p_keydt ).
  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.
  lcl_app=>run( ).
