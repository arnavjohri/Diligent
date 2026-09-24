sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageToast"
], function (Controller, MessageToast) {
    "use strict";

    // BOC By Arnav on 24/09/26
    // Fiscal year is not entered by the user: it is derived from "Date To".
    // Indian fiscal year, April to March: FY = year of Date To when its month
    // is April or later, otherwise the year before (rule agreed 24/09/26).
    // The global filter entity ZDPR_Q_DASH_FILTER keeps the P_FiscalYear
    // parameter because cards 2, 3 and 4 receive it by NAME from the filter
    // bar; this extension hides the field and fills it whenever the dates
    // change, so the mandatory parameter is always set before Go.
    // Nothing here depends on the exact field key: the filter bar is located
    // by control type and the two parameters by the tail of their names, so
    // "$Parameter.P_DateTo" and "P_DateTo" are both accepted.

    // Set to false before deployment. While true, a short message is shown
    // at the bottom of the page when the dashboard starts, listing what the
    // extension found. Harmless for users but not meant for them.
    var DEBUG = true;

    var TAIL_TO = "P_DateTo";
    var TAIL_FY = "P_FiscalYear";

    function endsWith(sName, sTail) {
        sName = String(sName || "");
        return sName === sTail || sName.slice(-(sTail.length + 1)) === "." + sTail;
    }

    function toDate(vValue) {
        if (!vValue) {
            return null;
        }
        if (vValue instanceof Date) {
            return isNaN(vValue.getTime()) ? null : vValue;
        }
        var s = String(vValue);
        // yyyymmdd (Edm.String dates of the analytical services)
        if (/^\d{8}$/.test(s)) {
            return new Date(Number(s.substr(0, 4)), Number(s.substr(4, 2)) - 1, Number(s.substr(6, 2)));
        }
        // yyyy-mm-dd or yyyy-mm-ddThh:mm:ss (Edm.DateTime as text)
        var m = /^(\d{4})-(\d{2})-(\d{2})/.exec(s);
        if (m) {
            return new Date(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
        }
        var d = new Date(s);
        return isNaN(d.getTime()) ? null : d;
    }

    function fiscalYearOf(vDateTo) {
        var d = toDate(vDateTo);
        if (!d) {
            return null;
        }
        var iYear = d.getFullYear();
        var iMonth = d.getMonth() + 1;          // 1..12
        return String(iMonth >= 4 ? iYear : iYear - 1);
    }

    function say(sText) {
        if (DEBUG) {
            MessageToast.show("FY ext: " + sText, { duration: 8000, width: "40em" });
        }
    }

    return Controller.extend("zdprdashboard.ext.controller.FiscalYear", {

        onInit: function () {
            var oView = this.getView();
            var oFilterBar = oView && oView.byId("ovpGlobalFilter");
            if (!oFilterBar && oView) {
                // id assumption failed: find the global SmartFilterBar by type
                oFilterBar = oView.findAggregatedObjects(true, function (oCtrl) {
                    return oCtrl.isA && oCtrl.isA("sap.ui.comp.smartfilterbar.SmartFilterBar");
                })[0];
            }
            if (!oFilterBar) {
                say("started, but no filter bar found in the view");
                return;
            }
            say("started, filter bar " + oFilterBar.getId());
            var fnInit = function () {
                this._hideFiscalYear(oFilterBar);
                this._deriveFiscalYear(oFilterBar);
                say("fields: " + this._itemNames(oFilterBar).join(", "));
            }.bind(this);
            if (oFilterBar.isInitialised && oFilterBar.isInitialised()) {
                fnInit();
            } else {
                oFilterBar.attachInitialise(fnInit);
            }
            oFilterBar.attachFilterChange(function () {
                this._deriveFiscalYear(oFilterBar);
                this._hideFiscalYear(oFilterBar);   // idempotent; survives late init
            }, this);
        },

        _items: function (oFilterBar) {
            var aItems = [];
            if (oFilterBar.getAllFilterItems) {
                aItems = aItems.concat(oFilterBar.getAllFilterItems(false) || []);
            }
            if (oFilterBar.getFilterGroupItems) {
                aItems = aItems.concat(oFilterBar.getFilterGroupItems() || []);
            }
            return aItems;
        },

        _itemNames: function (oFilterBar) {
            var aNames = [];
            this._items(oFilterBar).forEach(function (oItem) {
                var sName = oItem.getName ? String(oItem.getName()) : "?";
                if (aNames.indexOf(sName) < 0) {
                    aNames.push(sName);
                }
            });
            return aNames;
        },

        _hideFiscalYear: function (oFilterBar) {
            // Mandatory fields stay in the bar whatever "visible in filter bar"
            // says, so the item is hidden fully, and its control as a fallback.
            this._items(oFilterBar).forEach(function (oItem) {
                if (oItem.getName && endsWith(oItem.getName(), TAIL_FY)) {
                    if (oItem.setVisibleInFilterBar) {
                        oItem.setVisibleInFilterBar(false);
                    }
                    if (oItem.setVisible) {
                        oItem.setVisible(false);
                    }
                }
            });
            var oData = oFilterBar.getFilterData ? (oFilterBar.getFilterData() || {}) : {};
            Object.keys(oData).forEach(function (sKey) {
                if (endsWith(sKey, TAIL_FY) && oFilterBar.determineControlByName) {
                    var oCtrl = oFilterBar.determineControlByName(sKey);
                    var oParent = oCtrl && oCtrl.getParent && oCtrl.getParent();
                    if (oParent && oParent.setVisible) {
                        oParent.setVisible(false);
                    }
                }
            });
        },

        _deriveFiscalYear: function (oFilterBar) {
            var oData = oFilterBar.getFilterData() || {};
            var sKeyTo = null;
            var sKeyFy = null;
            Object.keys(oData).forEach(function (sKey) {
                if (endsWith(sKey, TAIL_TO)) {
                    sKeyTo = sKey;
                }
                if (endsWith(sKey, TAIL_FY)) {
                    sKeyFy = sKey;
                }
            });
            if (!sKeyTo) {
                return;                          // no Date To in the data yet
            }
            var sFy = fiscalYearOf(oData[sKeyTo]);
            if (!sFy) {
                return;
            }
            sKeyFy = sKeyFy || sKeyTo.replace(TAIL_TO, TAIL_FY);
            if (oData[sKeyFy] === sFy) {
                return;                          // already set, avoids re-entry
            }
            var oPatch = {};
            oPatch[sKeyFy] = sFy;
            oFilterBar.setFilterData(oPatch);    // merge, keeps the other fields
            say("Date To " + oData[sKeyTo] + " -> fiscal year " + sFy);
        }
    });
    // EOC By Arnav on 24/09/26
});
