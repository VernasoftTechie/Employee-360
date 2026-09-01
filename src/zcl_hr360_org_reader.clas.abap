"! <p class="shorttext synchronized">HR360 organizational reader</p>
"!
"! Bulk OM traversal helper (HRP1000 / HRP1001) for the report programs and any
"! caller that needs a deeper org hierarchy than the single-level CDS views
"! provide. Reads sets into internal tables - no SELECT inside LOOP.
CLASS zcl_hr360_org_reader DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_node,
        node_id     TYPE char34,
        node_type   TYPE otype,
        object_id   TYPE hrobjid,
        node_text   TYPE stext,
        parent_id   TYPE char34,
        level       TYPE i,
      END OF ty_node,
      ty_nodes TYPE STANDARD TABLE OF ty_node WITH EMPTY KEY.

    "! Employees assigned (directly or below) a given org unit.
    METHODS get_employees_in_orgunit
      IMPORTING iv_orgunit       TYPE orgeh
                iv_key_date      TYPE dats DEFAULT sy-datum
                iv_incl_subtree  TYPE abap_bool DEFAULT abap_true
      RETURNING VALUE(rt_pernr)  TYPE STANDARD TABLE OF pernr_d WITH EMPTY KEY.

    "! Org / position tree rooted at an org unit.
    METHODS get_org_tree
      IMPORTING iv_root_orgunit TYPE orgeh
                iv_key_date     TYPE dats DEFAULT sy-datum
                iv_max_depth    TYPE i    DEFAULT 20
      RETURNING VALUE(rt_nodes) TYPE ty_nodes.

  PRIVATE SECTION.
    CONSTANTS c_plvar TYPE plvar VALUE '01'.
ENDCLASS.


CLASS zcl_hr360_org_reader IMPLEMENTATION.

  METHOD get_employees_in_orgunit.

    DATA lt_orgunits TYPE STANDARD TABLE OF orgeh WITH EMPTY KEY.
    APPEND iv_orgunit TO lt_orgunits.

    IF iv_incl_subtree = abap_true.
      " expand the org-unit subtree breadth-first, one bulk read per level
      DATA(lt_frontier) = lt_orgunits.
      DO iv_max_depth = 20 TIMES.
        SELECT FROM hrp1001
          FIELDS sobid
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
        IF lt_children IS INITIAL.
          EXIT.
        ENDIF.
        DATA lt_next TYPE STANDARD TABLE OF orgeh WITH EMPTY KEY.
        CLEAR lt_next.
        LOOP AT lt_children INTO DATA(ls_child).
          APPEND CONV orgeh( ls_child-sobid ) TO lt_orgunits.
          APPEND CONV orgeh( ls_child-sobid ) TO lt_next.
        ENDLOOP.
        lt_frontier = lt_next.
      ENDDO.
    ENDIF.

    SORT lt_orgunits.
    DELETE ADJACENT DUPLICATES FROM lt_orgunits.

    SELECT FROM pa0001
      FIELDS pernr
      FOR ALL ENTRIES IN @lt_orgunits
      WHERE orgeh = @lt_orgunits-table_line
        AND begda <= @iv_key_date
        AND endda >= @iv_key_date
      INTO TABLE @rt_pernr.

    SORT rt_pernr.
    DELETE ADJACENT DUPLICATES FROM rt_pernr.

  ENDMETHOD.


  METHOD get_org_tree.

    DATA(lv_root_id) = |O{ iv_root_orgunit }|.

    SELECT SINGLE FROM hrp1000
      FIELDS stext
      WHERE plvar = @c_plvar AND otype = 'O' AND objid = @iv_root_orgunit
        AND begda <= @iv_key_date AND endda >= @iv_key_date
      INTO @DATA(lv_root_text).

    APPEND VALUE #( node_id   = lv_root_id
                    node_type = 'O'
                    object_id = iv_root_orgunit
                    node_text = lv_root_text
                    level     = 0 ) TO rt_nodes.

    DATA(lt_frontier) = VALUE hrobjid_t( ( CONV hrobjid( iv_root_orgunit ) ) ).
    DATA(lv_level)    = 1.

    WHILE lt_frontier IS NOT INITIAL AND lv_level <= iv_max_depth.

      SELECT FROM hrp1001 AS r
        INNER JOIN hrp1000 AS n
          ON  n~plvar = r~plvar
          AND n~otype = r~sclas
          AND n~objid = r~sobid
          AND n~begda <= @iv_key_date
          AND n~endda >= @iv_key_date
        FIELDS r~objid AS parent_objid, r~sclas AS child_type,
               r~sobid AS child_objid, n~stext AS child_text
        FOR ALL ENTRIES IN @lt_frontier
        WHERE r~plvar = @c_plvar
          AND r~otype = 'O'
          AND r~objid = @lt_frontier-table_line
          AND r~rsign = 'B'
          AND r~relat = '003'
          AND r~sclas IN ( 'O', 'S' )
          AND r~begda <= @iv_key_date
          AND r~endda >= @iv_key_date
        INTO TABLE @DATA(lt_rel).

      IF lt_rel IS INITIAL.
        EXIT.
      ENDIF.

      DATA lt_next TYPE hrobjid_t.
      CLEAR lt_next.
      LOOP AT lt_rel INTO DATA(ls_rel).
        APPEND VALUE #( node_id   = |{ ls_rel-child_type }{ ls_rel-child_objid }|
                        node_type = ls_rel-child_type
                        object_id = ls_rel-child_objid
                        node_text = ls_rel-child_text
                        parent_id = |O{ ls_rel-parent_objid }|
                        level     = lv_level ) TO rt_nodes.
        IF ls_rel-child_type = 'O'.
          APPEND ls_rel-child_objid TO lt_next.
        ENDIF.
      ENDLOOP.

      lt_frontier = lt_next.
      lv_level    = lv_level + 1.

    ENDWHILE.

  ENDMETHOD.

ENDCLASS.
