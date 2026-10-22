* Reference only: flow logic of screen 0001 of SAPLZMEPOBADI_CUST_DATA_GRP (the Customer Data tab of
* ME21N/ME22N, BAdI customer screen), as pasted by Arnav on 22/10/26. Never edited here.
* F4 sources it proves: zznat_proc -> MODULE pop_up, zzmse -> MODULE pop_up_mse (PROCESS ON VALUE-REQUEST).
* GEM PO No. (ZSTR_HEADER-ZGEMPO, data element ZGEMPONO): search help ZGEM_ORDER on the field
* (Technical Information of the screen field, same day) - not on the data element.
process before output. " Screen 101.
  module event_pbo.
  module event_pbo_prepare.

  module status_0001.

  module get_domain_text.

  module display_text_header.

  module validate_qad.
  module disable_save.
*
process after input.

  module event_pai_prepare.


  chain.
    field : zstr_header-zzar_op_dt ,
            zstr_header-zzar_cl_dt .

    module validate_zaribt on chain-request.
  endchain.

  chain.
    field : zstr_header-zzsch_st_dt ,
            zstr_header-zzsch_en_dt .

    module check_date on chain-request.
  endchain.

  field zstr_header-zzvend_cat  module vend_cat.
  field zstr_header-zzult_con module validate_hult_con.
  field zstr_header-zzmse module check_obligatory .
  field zstr_header-zgempo module check_gempo.
  """"""""""""""""""""""""""""
  "added by lipsy on 10.11.2015  RD1K999117
  field zstr_header-zzdmep module check_obligatory_dmep .

  "end of addition by lipsy on 10.11.2015  RD1K999117
  """"""""""""""""""""""""""""""""""
  field: zstr_header-zzloino,
         zstr_header-zzloidt.

  module disable_on_save.
  module event_pai.

process on value-request .
  field zstr_header-zznat_proc module pop_up.
  field zstr_header-zzmse module pop_up_mse.
