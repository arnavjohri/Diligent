*----------------------------------------------------------------------*
* Enhancement : ZEI_MM_PO_VH_MPC (enhancement implementation, source code)
* Where       : class CL_MM_PUR_PO_MAINT_V2_MPC_EXT, method DEFINE,
*               implicit enhancement option at the END of the method.
*               If DEFINE is not redefined there (Runtime Artifacts of
*               SEGW project MM_PUR_PO_MAINT_V2 decide), use the END of
*               DEFINE in CL_MM_PUR_PO_MAINT_V2_MPC instead. Never both.
* Author      : Arnav Johri (Diligent)      Created: 22.10.2026
* Ships by    : paste. Object 2 of 3; needs ZCL_MM_PO_VH_MPC active.
*----------------------------------------------------------------------*
* Path in the class editor: method DEFINE -> Enhance (spiral) -> Edit ->
* Enhancement Operations -> Show Implicit Enhancement Options -> the
* option after the last statement -> Create Implementation -> Code ->
* name ZEI_MM_PO_VH_MPC, short text "PO custom field value helps".
* Paste the two statements between ENHANCEMENT and ENDENHANCEMENT:
*----------------------------------------------------------------------*
*BOC By SAP_ABAP on 22/10/26
  " Value-help entity set + Common.ValueList for the EKKO custom fields.
  " Everything is inside TRY in the class: the PO model cannot be broken.
  zcl_mm_po_vh_mpc=>add_value_helps( io_model       = model
                                     io_vocan_model = vocab_anno_model ).
*EOC By SAP_ABAP on 22/10/26
