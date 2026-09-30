sap.ui.define([
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function (MessageToast, MessageBox) {
    "use strict";

    // BOC By Arnav on 24/09/26
    // Fiscal year is not entered by the user: it is derived from "Date To".
    // Indian fiscal year, April to March: FY = year of Date To when its month
    // is April or later, otherwise the year before (rule agreed 24/09/26).
    // The global filter entity ZDPR_Q_DASH_FILTER keeps the P_FiscalYear
    // parameter because cards 2, 3 and 4 receive it by NAME from the filter
    // bar; this extension fills it whenever the dates change and takes the
    // field out of the filter bar, so the mandatory parameter is always set
    // before Go without the user seeing it.
    //
    // Facts taken from the sap.ui.core, sap.ovp and sap.ui.comp 1.136
    // sources (not assumptions):
    // 0. A manifest extension under "sap.ui.controllerExtensions" must be a
    //    PLAIN OBJECT. UI5 mixes its members into sap.ovp.app.Main; a class
    //    made with Controller.extend() is loaded and then ignored without any
    //    visible error. Earlier versions of this file failed exactly there.
    //    Inside these functions "this" is the OVP Main controller itself.
    // 1. sap.ovp.app.Main is an async XML view; the filter bar does not exist
    //    at onInit. OVP itself waits for getView().loaded(). So do we.
    // 2. Filter bar id is "ovpGlobalFilter"; parameter keys in getFilterData
    //    and setFilterData are "$Parameter.<name>".
    // 3. A mandatory field can be removed from the bar with
    //    setVisibleInFilterBar(false) ONLY once it has a value; without a
    //    value the FilterBar reverts the change. Hence: fill first, hide after.
    // 4. Never call setVisible(false) on the item: an invisible item drops
    //    out of getFilterData, OVP's mandatory check then fails and no card
    //    loads. VisibleInFilterBar=false with a value keeps it in the data.
    // 5. determineControlByName() returns null for parameters, so the
    //    fallback (hide label + input controls) goes through the internal
    //    _determineEnsuredItemByName(); the item itself stays visible.
    // Member names carry the prefix _zfy so they cannot collide with OVP's
    // own controller methods.

    // Set to false before deployment. While true, messages report what the
    // extension does: a pop-up when the filter bar is ready and one when the
    // field has been hidden, grey toasts for the rest.
    var DEBUG = false;

    var KEY_TO = "$Parameter.P_DateTo";
    var KEY_FY = "$Parameter.P_FiscalYear";

    function toDate(vValue) {
        if (!vValue) {
            return null;
        }
        if (vValue instanceof Date) {
            return isNaN(vValue.getTime()) ? null : vValue;
        }
        // DateRangeType shape: { ranges: [ { value1: Date } ] }
        if (typeof vValue === "object" && vValue.ranges && vValue.ranges[0]) {
            return toDate(vValue.ranges[0].value1);
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

    function fiscalYearOf(oDate) {
        var iYear = oDate.getFullYear();
        var iMonth = oDate.getMonth() + 1;      // 1..12
        return String(iMonth >= 4 ? iYear : iYear - 1);
    }

    function say(sText) {
        if (DEBUG) {
            MessageToast.show("FY ext: " + sText, { duration: 6000, width: "40em" });
        }
    }

    function shout(sText) {
        if (DEBUG) {
            MessageBox.information("FY ext: " + sText);
        }
    }

    return {

        // runs after OVP's own onInit (legacy extension lifecycle: "After")
        onInit: function () {
            var oView = this.getView();
            if (!oView || !oView.loaded) {
                return;
            }
            oView.loaded().then(function () {
                var oFilterBar = oView.byId("ovpGlobalFilter");
                if (!oFilterBar) {
                    shout("page loaded, but no filter bar with id ovpGlobalFilter");
                    return;
                }
                var fnApply = function () {
                    this._zfyApply(oFilterBar);
                }.bind(this);
                var fnFirst = function () {
                    var aNames = (oFilterBar.getAllFilterItems(false) || []).map(function (oItem) {
                        return oItem.getName();
                    });
                    shout("filter bar ready. Fields: " + aNames.join(", "));
                    fnApply();
                };
                if (oFilterBar.isInitialised && oFilterBar.isInitialised()) {
                    fnFirst();
                } else if (oFilterBar.attachInitialized) {
                    oFilterBar.attachInitialized(fnFirst);
                } else {
                    oFilterBar.attachInitialise(fnFirst);
                }
                // user typed a date, a variant was applied, or setFilterData ran
                oFilterBar.attachFilterChange(fnApply);
                if (oFilterBar.attachAfterVariantLoad) {
                    oFilterBar.attachAfterVariantLoad(fnApply);
                }
            }.bind(this));
        },

        _zfyApply: function (oFilterBar) {
            var oData = oFilterBar.getFilterData() || {};
            var oDateTo = toDate(oData[KEY_TO]);
            // no Date To yet: seed from today so the field can be hidden at
            // once; it is corrected as soon as Date To is entered
            var sFy = fiscalYearOf(oDateTo || new Date());
            if (oData[KEY_FY] !== sFy) {
                var oPatch = {};
                oPatch[KEY_FY] = sFy;
                oFilterBar.setFilterData(oPatch);        // merge; fires filterChange
                say((oDateTo ? "Date To -> " : "no Date To yet, today -> ") + "fiscal year " + sFy);
                return;                                  // the filterChange re-entry hides it
            }
            this._zfyHide(oFilterBar);
        },

        _zfyHide: function (oFilterBar) {
            var oFyItem = null;
            (oFilterBar.getAllFilterItems(false) || []).forEach(function (oItem) {
                if (oItem.getName && oItem.getName() === KEY_FY) {
                    oFyItem = oItem;
                }
            });
            if (!oFyItem) {
                say("no field named " + KEY_FY + " in the filter bar");
                return;
            }
            if (oFyItem.getVisibleInFilterBar()) {
                oFyItem.setVisibleInFilterBar(false);    // allowed: the field has a value
                if (!oFyItem.getVisibleInFilterBar()) {
                    shout("fiscal year field hidden (item)");
                    return;
                }
                // reverted by the FilterBar: hide the label and input instead;
                // the item stays visible, so the value still reaches the cards
                var oEntry = oFilterBar._determineEnsuredItemByName ?
                    oFilterBar._determineEnsuredItemByName(KEY_FY) : null;
                var oCtrl = oEntry && oEntry.control;
                var oLabel = oEntry && oEntry.filterItem && oEntry.filterItem._oLabel;
                if (oCtrl && oCtrl.setVisible) {
                    oCtrl.setVisible(false);
                }
                if (oLabel && oLabel.setVisible) {
                    oLabel.setVisible(false);
                }
                shout("item hide was reverted; " + (oCtrl ? "input and label hidden instead" : "no control found"));
            }
        }
    };
    // EOC By Arnav on 24/09/26
});
