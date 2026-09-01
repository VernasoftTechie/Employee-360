CLASS lhc_timeline DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS read FOR READ
      IMPORTING keys FOR READ timelineevent RESULT result.
ENDCLASS.

CLASS lhc_timeline IMPLEMENTATION.
  METHOD read.
    SELECT FROM zi_hr360_timeline
      FIELDS *
      FOR ALL ENTRIES IN @keys
      WHERE employeeid    = @keys-EmployeeID
        AND eventdate     = @keys-EventDate
        AND eventcategory = @keys-EventCategory
        AND eventkey      = @keys-EventKey
      INTO CORRESPONDING FIELDS OF TABLE @result.
  ENDMETHOD.
ENDCLASS.
