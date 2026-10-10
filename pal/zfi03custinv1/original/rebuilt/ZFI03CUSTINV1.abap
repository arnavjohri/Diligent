*======================================================================*
*                   Confidential and Proprietary                       *
*======================================================================*
*                                                                      |
*             /*******//       ///****//        //                     |
*             /**     **      /**     /**       /*                     |
*             /**     **      /**********       /*                     |
*             /**/////**      /**//////**       /*                     |
*             /**             /**     /**       /*                     |
*             /**             /**     /**       /*                     |
*             /**             //      //        //*******//            |
*                                                                      |
*      .-------------------------------------------------------.       |
*      |                 PROJECT TRANSFORM                     |       |
*      |    Evolving to a Stronger & Well-Positioned Future    |       |
*      '-------------------------------------------------------'       |
*                                                                      |
*======================================================================*
*     Program Name : ZFI03CUSTINV1
*     WRICEF ID    : 03
*     Created on   : 09/13/2022
*     Created by   : Dane Andrei Agoyaoy & Paul Bryan Puno
*     Functional   : Klara Denise Domingo
*     Description  : Customer Invoice, Credit Memo and Debit Memo Forms
*======================================================================*
*          M  O  D  I  F  I  C  A  T  I  O  N  -  L  O  G              *
*======================================================================*
* 01. Changed on   :
*     Changed by   :
*     Transport No.: DS4K900249
*     Description  :
*----------------------------------------------------------------------*

REPORT zfi03custinv1 MESSAGE-ID zndph_agoyaoy03.

INCLUDE zfi_03_custinv_top.
INCLUDE zfi_03_custinv_sel.
INCLUDE zfi_03_custinv_form.

*&----------------------------------------------------------------------------------------------*
*&        INITIALIZATION                                                                        *
*&----------------------------------------------------------------------------------------------*
*  This event occurs before the standard selection screen is called.                            *
*&----------------------------------------------------------------------------------------------*

INITIALIZATION.

  PERFORM f_initial_values.

*&----------------------------------------------------------------------------------------------*
*&        AT SELECTION-SCREEN                                                                   *
*&----------------------------------------------------------------------------------------------*
*&  This event is the basic form of a whole series of events that                               *
*&  occur while the selection screen is being processed.                                        *
*&----------------------------------------------------------------------------------------------*

AT SELECTION-SCREEN OUTPUT.

IF p_rbukrs IS INITIAL.

 AUTHORITY-CHECK OBJECT 'F_BKPF_BUK'
  FOR USER sy-uname
  ID 'BUKRS' FIELD 'PR01'.
*  ID 'ACTVT' FIELD '01'.

  IF sy-subrc <> 0. "auth check failed for PR01
   p_rbukrs = '2P01'.
  ELSE.
   p_rbukrs = 'PR01'.
  ENDIF.

ENDIF.

  PERFORM f_parameter.
  PERFORM f_billto.

* Customized help function for House Bank
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_hbank.
  PERFORM hbank_f4 CHANGING p_hbank.

* Customized help function for Account ID
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_accid.
  PERFORM accid_f4 CHANGING p_accid.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path.
  PERFORM f_filepath.


*&----------------------------------------------------------------------------------------------*
*&        START-OF-SELECTION                                                                    *
*&----------------------------------------------------------------------------------------------*
*&  This event occurs after the selection screen has been processed and                         *
*&  before data is read using the logical database.                                             *
*&----------------------------------------------------------------------------------------------*

START-OF-SELECTION.
*------------------------------------------------------------------*
*                    MANDATORY FIELDS
*------------------------------------------------------------------*
  IF p_rbukrs IS INITIAL.
    MESSAGE s000 DISPLAY LIKE 'E'. "M - Fill out all required entry fields
    EXIT.
  ENDIF.

  IF p_gjahr IS INITIAL.
    MESSAGE s000 DISPLAY LIKE 'E'. "M - Fill out all required entry fields
    EXIT.
  ENDIF.

  PERFORM f_get_data.
  PERFORM f_process_data.

*&----------------------------------------------------------------------------------------------*
*&        END-OF-SELECTION                                                                      *
*&----------------------------------------------------------------------------------------------*

END-OF-SELECTION.
