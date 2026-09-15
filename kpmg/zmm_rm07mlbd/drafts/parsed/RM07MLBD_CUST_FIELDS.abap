***INCLUDE RM07MLBD_CUST_FIELDS .

* correction Nov. 2005 MM                                   "n890109
* allow the inter active functions 'Specify drill-down'     "n890109
* and 'Choose' from the menu 'Settings -> Summation levels' "n890109

* Improvements :                       March 2003 MM        "n599218
* - allow to process the fields MAT_KDAUF, MAT_KDPOS, and   "n599218
*   MAT_PSPNR from release 4.5B and higher                  "n599218

* representation of tied empties improved    August 2002 MM "n547170

* field "SJAHR" was moved to report RM07MBLD                "n497992
* new custimizing settings                                  "n497992
* - customizing for the selection of remaining BSIM entries "n497992
* - customizing for the processing of tied empties          "n497992

*----------------------------------------------------------------------*
* report RM07MLBD and its includes improved  May 10th, 2001 "n400992
*----------------------------------------------------------------------*

* This include contains the structure for additional fields for report
* RM07MLBD ( transaction MB5B )

* the following fields are not shown in the list of report
* RM07MLBD
* If you want to insert some of these fields in the list of the
* hidden fields delete the '*' in the type definition.
*
* There are only fields from database table MSEG possible
* Please use only the following fields, because these fields
* are considered during the creation of the field catalog;
* plaese consider, that each active field will cost performance

ENHANCEMENT-SECTION RM07MLBD_CUST_FIELDS_01 SPOTS ES_RM07MLBD_CUST_FIELDS STATIC .
TYPES : BEGIN OF STYPE_MB5B_ADD,
          DUMMY(01)          TYPE C,             "filler
*
* the following fields of database table MSEG can be activated
*         insmk    like      mseg-insmk,    "Bestandsart
*         LIFNR    LIKE      MSEG-LIFNR,    "Kontonummer Lieferant
*         KUNNR    LIKE      MSEG-KUNNR,    "Kontonummer Kunde

*  Caution : functionalitiy was changed after release 4.0B  "n599218
*  you will find the sales order in the following fields :  "n599218
*  Field       Description           release                "n599218
*  MAT_KDAUF   sales order number    4.5B and higher        "n599218
*  MAT_KDPOS   sales order item      4.5B and higher        "n599218
*  KDAUF       sales order number    4.0B                   "n599218
*  KDPOS       sales order item      4.0B                   "n599218
*                                                           "n599218
*         MAT_KDAUF  like    mseg-mat_kdauf,                "n599218
*         MAT_KDPOS  like    mseg-mat_kdpos,                "n599218
*         KDAUF    LIKE      MSEG-KDAUF,    "Kundenauftragsnummer
*         KDPOS    LIKE      MSEG-KDPOS,    "Positionsnummer

*         KDEIN    LIKE      MSEG-KDEIN,    "Einteilung Kundenauftrag
*
* please activate or deactivate the following two fields togehter
*        erfmg    like      mseg-erfmg,    "Menge in ERFME
*         erfme    like      mseg-erfme,    "Erfassungsmengeneinheit
*
* please activate or deactivate the following two fields togehter
*         BPMNG    LIKE      MSEG-BPMNG,    " Menge in BPRME
*         BPRME    LIKE      MSEG-BPRME,    " Bestellpreismengeneinheit
*
*         EBELN    LIKE      MSEG-EBELN,    " Bestellnummer
*         EBELP    LIKE      MSEG-EBELP,    " Positionsnummer
*
*         ELIKZ    LIKE      MSEG-ELIKZ,    " Endlieferungskennzeichen
*         SGTXT    LIKE      MSEG-SGTXT,    " Segment-Text
*         WEMPF    LIKE      MSEG-WEMPF,    " Warenempfänger
*         ABLAD    LIKE      MSEG-ABLAD,    " Abladestelle
*         GSBER    LIKE      MSEG-GSBER,    " Geschäftsbereich
*
*         PARGB    LIKE      MSEG-PARGB,    " Geschäftsbereich
*         PARBU    LIKE      MSEG-PARBU,    " Verrechnender
*         KOSTL    LIKE      MSEG-KOSTL,    " Kostenstelle
*         AUFNR    LIKE      MSEG-AUFNR,    " Auftragsnummer
*         ANLN1    LIKE      MSEG-ANLN1,    " Anlagen-Hauptnummer
*
*         RSNUM    LIKE      MSEG-RSNUM,    " Nummer der Reservierung/
*         RSPOS    LIKE      MSEG-RSPOS,    " Positionsnummer der
*         KZEAR    LIKE      MSEG-KZEAR,    " Kennzeichen Endausfassung
*         UMMAT    LIKE      MSEG-UMMAT,    " Empfangendes/Abgebendes
*         UMWRK    LIKE      MSEG-UMWRK,    " Empfangendes/Abgebendes
*
*         UMLGO    LIKE      MSEG-UMLGO,    " Empfangender/Abgebender
*         UMCHA    LIKE      MSEG-UMCHA,    " Empfangende/Abgebende
*         UMBAR    LIKE      MSEG-UMBAR,    " Bewertungsart der
*         UMSOK    LIKE      MSEG-UMSOK,    " Sonderbestandskennzeichen
*         WEUNB    LIKE      MSEG-WEUNB,    " Kennzeichen Wareneingang
*
*         GRUND    LIKE      MSEG-GRUND,    " Kennzeichen: Grund
*         KSTRG    LIKE      MSEG-KSTRG,    " Kostenträger
*         PAOBJNR  LIKE      MSEG-PAOBJNR,  " Nummer für
*         PRCTR    LIKE      MSEG-PRCTR,    " Profit Center

*  Caution : functionalitiy was changed after release 4.0B  "n599218
*  you will find the WBS element in the following fields :  "n599218
*  Field       Description           use in release         "n599218
*  MAT_PSPNR   WBS elemnet           4.5B and higher        "n599218
*  PS_PSP_PNR  WBS element           4.0B                   "n599218
*                                                           "n599218
*         MAT_PSPNR   like   mseg-mat_pspnr,                "n599218
*         PS_PSP_PNR  LIKE   MSEG-PS_PSP_PNR, "Projektstrukturplanel.
*
*         NPLNR    LIKE      MSEG-NPLNR,    " Netzplannummer
*         AUFPL    LIKE      MSEG-AUFPL,    " Plannummer zu Vorgängen
*         AUFPS    LIKE      MSEG-AUFPS,    " Nummer der
*
* please activate or deactivate the following two fields togehter
*         BSTMG    LIKE      MSEG-BSTMG,    " Wareneingangsmenge
*         BSTME    LIKE      MSEG-BSTME,    " Bestellmengeneinheit
*
*         EXBWR    LIKE      MSEG-EXBWR,    " Extern eingegebener
*         VKWRT    LIKE      MSEG-VKWRT,    " Wert zu Verkaufspreisen
*         VFDAT    LIKE      MSEG-VFDAT,    " Verfallsdatum oder
*         EXVKW    LIKE      MSEG-EXVKW,    " Extern eingegebener
*         PPRCTR   LIKE      MSEG-PPRCTR,   " Partner-Profit Center
*
*         MATBF    LIKE      MSEG-MATBF,    " Material, auf dem der
*         UMMAB    LIKE      MSEG-UMMAB,    " Empfangendes/Abgebendes
*         LBKUM    LIKE      MSEG-LBKUM,    " Gesamter bewerteter
*         SALK3    LIKE      MSEG-SALK3,    " Wert des gesamten
*         VPRSV    LIKE      MSEG-VPRSV,    " Preissteuerungskennz.
*
*         VKWRA    LIKE      MSEG-VKWRA,    " Wert zu Verkaufspreisen
*         URZEI    LIKE      MSEG-URZEI,    " Ursprungszeile im
*
* please activate or deactivate the following two fields togehter
*         LSMNG    LIKE      MSEG-LSMNG,    " Menge in Mengeneinheit
*         LSMEH    LIKE      MSEG-LSMEH,    " Mengeneinheit aus
        END OF STYPE_MB5B_ADD.
END-ENHANCEMENT-SECTION.
*$*$-Start: RM07MLBD_CUST_FIELDS_01-------------------------------------------------------------$*$*
ENHANCEMENT 1  OIH_RM07MLBD_CUST_FIELDS.    "active version
TYPES : BEGIN OF STYPE_MB5B_ADD,
          DUMMY(01)          TYPE C,             "filler
*
* the following fields of database table MSEG can be activated
*         insmk    like      mseg-insmk,    "Bestandsart
*         LIFNR    LIKE      MSEG-LIFNR,    "Kontonummer Lieferant
*         KUNNR    LIKE      MSEG-KUNNR,    "Kontonummer Kunde

*  Caution : functionalitiy was changed after release 4.0B  "n599218
*  you will find the sales order in the following fields :  "n599218
*  Field       Description           release                "n599218
*  MAT_KDAUF   sales order number    4.5B and higher        "n599218
*  MAT_KDPOS   sales order item      4.5B and higher        "n599218
*  KDAUF       sales order number    4.0B                   "n599218
*  KDPOS       sales order item      4.0B                   "n599218
*                                                           "n599218
*         MAT_KDAUF  like    mseg-mat_kdauf,                "n599218
*         MAT_KDPOS  like    mseg-mat_kdpos,                "n599218
*         KDAUF    LIKE      MSEG-KDAUF,    "Kundenauftragsnummer
*         KDPOS    LIKE      MSEG-KDPOS,    "Positionsnummer

*         KDEIN    LIKE      MSEG-KDEIN,    "Einteilung Kundenauftrag
*
* please activate or deactivate the following two fields togehter
*        erfmg    like      mseg-erfmg,    "Menge in ERFME
*         erfme    like      mseg-erfme,    "Erfassungsmengeneinheit
*
* please activate or deactivate the following two fields togehter
*         BPMNG    LIKE      MSEG-BPMNG,    " Menge in BPRME
*         BPRME    LIKE      MSEG-BPRME,    " Bestellpreismengeneinheit
*
*         EBELN    LIKE      MSEG-EBELN,    " Bestellnummer
*         EBELP    LIKE      MSEG-EBELP,    " Positionsnummer
*
*         ELIKZ    LIKE      MSEG-ELIKZ,    " Endlieferungskennzeichen
*         SGTXT    LIKE      MSEG-SGTXT,    " Segment-Text
*         WEMPF    LIKE      MSEG-WEMPF,    " Warenempfänger
*         ABLAD    LIKE      MSEG-ABLAD,    " Abladestelle
*         GSBER    LIKE      MSEG-GSBER,    " Geschäftsbereich
*
*         PARGB    LIKE      MSEG-PARGB,    " Geschäftsbereich
*         PARBU    LIKE      MSEG-PARBU,    " Verrechnender
*         KOSTL    LIKE      MSEG-KOSTL,    " Kostenstelle
*         AUFNR    LIKE      MSEG-AUFNR,    " Auftragsnummer
*         ANLN1    LIKE      MSEG-ANLN1,    " Anlagen-Hauptnummer
*
*         RSNUM    LIKE      MSEG-RSNUM,    " Nummer der Reservierung/
*         RSPOS    LIKE      MSEG-RSPOS,    " Positionsnummer der
*         KZEAR    LIKE      MSEG-KZEAR,    " Kennzeichen Endausfassung
*         UMMAT    LIKE      MSEG-UMMAT,    " Empfangendes/Abgebendes
*         UMWRK    LIKE      MSEG-UMWRK,    " Empfangendes/Abgebendes
*
*         UMLGO    LIKE      MSEG-UMLGO,    " Empfangender/Abgebender
*         UMCHA    LIKE      MSEG-UMCHA,    " Empfangende/Abgebende
*         UMBAR    LIKE      MSEG-UMBAR,    " Bewertungsart der
*         UMSOK    LIKE      MSEG-UMSOK,    " Sonderbestandskennzeichen
*         WEUNB    LIKE      MSEG-WEUNB,    " Kennzeichen Wareneingang
*
*         GRUND    LIKE      MSEG-GRUND,    " Kennzeichen: Grund
*         KSTRG    LIKE      MSEG-KSTRG,    " Kostenträger
*         PAOBJNR  LIKE      MSEG-PAOBJNR,  " Nummer für
*         PRCTR    LIKE      MSEG-PRCTR,    " Profit Center

*  Caution : functionalitiy was changed after release 4.0B  "n599218
*  you will find the WBS element in the following fields :  "n599218
*  Field       Description           use in release         "n599218
*  MAT_PSPNR   WBS elemnet           4.5B and higher        "n599218
*  PS_PSP_PNR  WBS element           4.0B                   "n599218
*                                                           "n599218
*         MAT_PSPNR   like   mseg-mat_pspnr,                "n599218
*         PS_PSP_PNR  LIKE   MSEG-PS_PSP_PNR, "Projektstrukturplanel.
*
*         NPLNR    LIKE      MSEG-NPLNR,    " Netzplannummer
*         AUFPL    LIKE      MSEG-AUFPL,    " Plannummer zu Vorgängen
*         AUFPS    LIKE      MSEG-AUFPS,    " Nummer der
*
* please activate or deactivate the following two fields togehter
*         BSTMG    LIKE      MSEG-BSTMG,    " Wareneingangsmenge
*         BSTME    LIKE      MSEG-BSTME,    " Bestellmengeneinheit
*
*         EXBWR    LIKE      MSEG-EXBWR,    " Extern eingegebener
*         VKWRT    LIKE      MSEG-VKWRT,    " Wert zu Verkaufspreisen
*         VFDAT    LIKE      MSEG-VFDAT,    " Verfallsdatum oder
*         EXVKW    LIKE      MSEG-EXVKW,    " Extern eingegebener
*         PPRCTR   LIKE      MSEG-PPRCTR,   " Partner-Profit Center
*
*         MATBF    LIKE      MSEG-MATBF,    " Material, auf dem der
*         UMMAB    LIKE      MSEG-UMMAB,    " Empfangendes/Abgebendes
*         LBKUM    LIKE      MSEG-LBKUM,    " Gesamter bewerteter
*         SALK3    LIKE      MSEG-SALK3,    " Wert des gesamten
*         VPRSV    LIKE      MSEG-VPRSV,    " Preissteuerungskennz.
*
*         VKWRA    LIKE      MSEG-VKWRA,    " Wert zu Verkaufspreisen
*         URZEI    LIKE      MSEG-URZEI,    " Ursprungszeile im
*
* please activate or deactivate the following two fields togehter
*         LSMNG    LIKE      MSEG-LSMNG,    " Menge in Mengeneinheit
*         LSMEH    LIKE      MSEG-LSMEH,    " Mengeneinheit aus
*
* Excise duty fields - IS-OIL              "v_n_1337790
*         OITAXFROM LIKE MSEG-OITAXFROM,     " Excise duty tax key for 'from' location
*         OITAXTO   LIKE MSEG-OITAXTO,       " Excise duty tax key for 'to' location
*         OIHANTYP  LIKE MSEG-OIHANTYP,      " Excise Duty Handling Type - Denotes Use of Material
*         OITAXGRP  LIKE MSEG-OITAXGRP,      " Excise duty tax group for material(s)
*         OIPRICIE  LIKE MSEG-OIPRICIE,      " ED pricing: external (indicator)
*         OIINVREC  LIKE MSEG-OIINVREC,      " Indicator whether ED pricing is external (not used?)
*         OIOILCON  LIKE MSEG-OIOILCON,      " Oil content in a material as a percentage
*         OIOILCON2 LIKE MSEG-OIOILCON2,     " Oil content of a material as a percentage (2)
*         OIFUTDT   LIKE MSEG-OIFUTDT,       " Future tax date
*         OIFUTDT2  LIKE MSEG-OIFUTDT2,      " Future tax date 2
*         OIUOMQT   LIKE MSEG-OIUOMQT,       " Base quantity for excise duty rate (e.g.per 1 or 100 UoM)
*         OITAXQT   LIKE MSEG-OITAXQT,       " Excise duty tax quantity in STBME
*         OIFUTQT   LIKE MSEG-OIFUTQT,       " Future tax quantity
*         OIFUTQT2  LIKE MSEG-OIFUTQT2,      " Future tax quantity 2
*         OITAXGRP2 LIKE MSEG-OITAXGRP2,     " Excise duty tax group for material(s) "^_n_1337790
        END OF STYPE_MB5B_ADD.
ENDENHANCEMENT.
*$*$-End:   RM07MLBD_CUST_FIELDS_01-------------------------------------------------------------$*$*

*----------------------------------------------------------------------*

* customizing for the color in the lines with documents
*      value 'X' : the fields with quantities will be colored
*      value ' ' : no colors ( improve the performance )
  data : G_cust_color(01)    type c    value 'X'.
* data : G_cust_color(01)    type c    value ' '.

*----------------------------------------------------------------------*

* customizing for the selection of remaining BSIM entries   "n497992
* ( FI document ) without matching MSEG ( MM document )     "n497992
* like price changes, account adjustments, etc...           "n497992
*                                                           "n497992
* value ' ' : (default) take all remaining BSIM entries     "n497992
* value 'X' : take only the remaining BSIM entries when     "n497992
*             when the original BSEG entry contains the     "n497992
*             transaction key ( KTOSL ) 'BSX'               "n497992
*             this mode will cost performance               "n497992
  data : G_cust_bseg_bsx(01) type c    value ' '.           "n497992
* data : G_cust_bseg_bsx(01) type c    value 'X'.           "n497992

*----------------------------------------------------------------------*

* customizing for the processing of tied emptied materials  "n497992
*                                                           "n497992
* value ' ' : (default) do not consider tied empties        "n497992
* value 'X' : consider tied empties materials with their    "n497992
*             special rules in the inventory management     "n497992
*             this mode will cost performance               "n497992
  data : G_cust_tied_empties(01)  type c    value ' '.      "n497992
* data : G_cust_tied_empties(01)  type c    value 'X'.      "n547170

*----------------------------------------------------------------------*

* customizing for the interactive functions                 "n890109
* 'Specify drill-down' and 'Choose' from the menu           "n890109
* 'Settings -> Summation levels'                            "n890109
*                                                           "n890109
* value 'X' : (default) allow the interactive functions     "n890109
*             'Specify drill-down' and 'Choose' from the    "n890109
*             menu 'Settings -> Summation levels'           "n890109
* value ' ' : do not allow these functions                  "n890109
  data : g_cust_sum_levels(01)    type c    value 'X'.      "n890109
* data : g_cust_sum_levels(01)    type c    value ' '.      "n890109
                                                            "n890109
*-----------------------------------------------------------"n890109
