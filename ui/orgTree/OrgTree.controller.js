/*
 * HR Employee 360 - Organizational Navigation custom section controller.
 * Reference implementation - see docs/07_ui_and_navigation.md section 5.
 *
 * Behaviour:
 *  - on section render, rebinds the TreeTable with p_root_node = "O" + the
 *    displayed employee's OrgUnit
 *  - on selecting a Person ("P") node, cross-navigates to that employee's
 *    Object Page via the standard Fiori intent  Employee-display
 */
sap.ui.define([
    "sap/ui/core/mvc/ControllerExtension",
    "sap/ui/model/Filter",
    "sap/ui/model/FilterOperator"
], function (ControllerExtension, Filter, FilterOperator) {
    "use strict";

    return ControllerExtension.extend("employee360.ext.orgTree.OrgTree", {

        override: {
            onAfterRendering: function () {
                this._bindTree();
            }
        },

        _bindTree: function () {
            var oView = this.base.getView();
            var oContext = oView.getBindingContext();
            if (!oContext) { return; }

            var sOrgUnit = oContext.getProperty("OrgUnit");
            if (!sOrgUnit) { return; }

            var oTable = oView.byId("orgTreeTable");
            if (!oTable) { return; }

            oTable.bindRows({
                path: "/OrgNode",
                parameters: {
                    $$aggregation: { hierarchyQualifier: "OrgHierarchy" },
                    "p_root_node": "O" + sOrgUnit
                }
            });
        },

        onNodePress: function (oEvent) {
            var oRow = oEvent.getParameter("rowContext");
            if (!oRow) { return; }
            if (oRow.getProperty("NodeType") !== "P") { return; }

            var sPernr = oRow.getProperty("ObjectID");
            var oCrossNav = sap.ushell &&
                sap.ushell.Container &&
                sap.ushell.Container.getService("CrossApplicationNavigation");

            if (oCrossNav) {
                oCrossNav.toExternal({
                    target: { semanticObject: "Employee", action: "display" },
                    params: { EmployeeID: sPernr }
                });
            }
        }
    });
});
