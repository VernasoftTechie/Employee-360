"! <p class="shorttext synchronized">HR360 organizational reader</p>
"!
"! Bulk OM traversal helper (HRP1000 / HRP1001) for callers that need a deeper
"! org hierarchy than the single-level CDS views provide. Reads sets into
"! internal tables - no SELECT inside LOOP.
CLASS zcl_hr360_org_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      ty_orgunits TYPE STANDARD TABLE OF orgeh WITH EMPTY KEY,
      ty_pernrs   TYPE STANDARD TABLE OF pernr_d WITH EMPTY KEY,
      BEGIN OF ty_node,
        node_id   TYPE char20,
        node_type TYPE otype,
        object_id TYPE hrobjid,
        node_text TYPE stext,
        parent_id TYPE char20,
        node_level TYPE i,
      END OF ty_node,
      ty_nodes TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY.

    "! Org units in the subtree rooted at iv_orgunit (breadth-first).
    METHODS get_orgunit_subtree
      IMPORTING iv_orgunit         TYPE orgeh
                iv_key_date        TYPE dats DEFAULT sy-datum
                iv_max_depth       TYPE i    DEFAULT 20
      RETURNING VALUE(rt_orgunits) TYPE ty_orgunits.

    "! Employees assigned to any org unit in the subtree rooted at iv_orgunit.
    METHODS get_employees_in_orgunit
      IMPORTING iv_orgunit      TYPE orgeh
                iv_key_date     TYPE dats DEFAULT sy-datum
                iv_incl_subtree TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(rt_pernr)  TYPE ty_pernrs.

  PRIVATE SECTION.
    CONSTANTS c_plvar TYPE plvar VALUE '01'.
ENDCLASS.


CLASS zcl_hr360_org_reader IMPLEMENTATION.

  METHOD get_orgunit_subtree.

    APPEND iv_orgunit TO rt_orgunits.
    DATA(lt_frontier) = rt_orgunits.

    DO iv_max_depth TIMES.

      IF lt_frontier IS INITIAL.
        EXIT.
      ENDIF.

      SELECT sobid
        FROM hrp1001
        FOR ALL ENTRIES IN @lt_frontier
        WHERE plvar = @c_plvar
          AND otype = 'O'
          AND objid = @lt_frontier-table_line
          AND rsign = 'B'
          AND relat = '003'
          AND sclas = 'O'
          AND begda <= @iv_key_date
          AND endda >= @iv_key_date
        INTO TABLE @DATA(lt_children).

      CLEAR lt_frontier.
      LOOP AT lt_children INTO DATA(ls_child).
        DATA(lv_org) = CONV orgeh( ls_child-sobid ).
        APPEND lv_org TO rt_orgunits.
        APPEND lv_org TO lt_frontier.
      ENDLOOP.

    ENDDO.

    SORT rt_orgunits.
    DELETE ADJACENT DUPLICATES FROM rt_orgunits.

  ENDMETHOD.


  METHOD get_employees_in_orgunit.

    DATA lt_orgunits TYPE ty_orgunits.

    IF iv_incl_subtree = abap_true.
      lt_orgunits = get_orgunit_subtree( iv_orgunit  = iv_orgunit
                                         iv_key_date = iv_key_date ).
    ELSE.
      APPEND iv_orgunit TO lt_orgunits.
    ENDIF.

    IF lt_orgunits IS INITIAL.
      RETURN.
    ENDIF.

    SELECT pernr
      FROM pa0001
      FOR ALL ENTRIES IN @lt_orgunits
      WHERE orgeh = @lt_orgunits-table_line
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date
      INTO TABLE @rt_pernr.

    SORT rt_pernr.
    DELETE ADJACENT DUPLICATES FROM rt_pernr.

  ENDMETHOD.

ENDCLASS.
