"! <p class="shorttext synchronized">HR360 Employee - behavior pool</p>
"!
"! Unmanaged, read-only RAP behavior pool for ZI_HR360_EMPLOYEE and its
"! composition children (Personal, OrgAssignment, Education, Qualification,
"! LeaveBalance, Attendance, Payroll, Document).
"!
"! IMPORTANT (see repo README): after activating ZI_HR360_EMPLOYEE.bdef, use
"! ADT Quick Fix "Add missing method implementations" on this class so the
"! framework regenerates the exact FOR READ / FOR READ ..\_assoc / FOR
"! INSTANCE AUTHORIZATION method signatures for your kernel's RAP runtime
"! version, then keep the method bodies from zbp_hr360_employee.clas.locals_imp.
CLASS zbp_hr360_employee DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF zi_hr360_employee.
ENDCLASS.

CLASS zbp_hr360_employee IMPLEMENTATION.
ENDCLASS.
