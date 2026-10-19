@AbapCatalog.sqlViewAppendName: 'ZCPURORDTP'
@EndUserText.label: 'Extension of C_PurchaseOrderTP'
extend view C_PurchaseOrderTP with ZC_PurchaseOrderTP_EXT
{
PurchaseOrderTP.zzt_nature     as zzt_nature,
    PurchaseOrderTP.zztnd_dt       as zztnd_dt,
    PurchaseOrderTP.zzlst_sel_date as zzlst_sel_date,
    PurchaseOrderTP.zzsub_time     as zzsub_time,
    PurchaseOrderTP.zztb_op_dt     as zztb_op_dt,
    PurchaseOrderTP.zztb_op_tm     as zztb_op_tm,
    PurchaseOrderTP.zzpb_op_dt     as zzpb_op_dt,
    PurchaseOrderTP.zzpb_op_tm     as zzpb_op_tm,
    PurchaseOrderTP.zzpre_bid_dt   as zzpre_bid_dt,
    PurchaseOrderTP.zzbd_type      as zzbd_type,
    PurchaseOrderTP.zzt_duration   as zzt_duration,
    PurchaseOrderTP.zzlst_dt_que   as zzlst_dt_que,

    @UI.identification: [{ position: 120 }]
    PurchaseOrderTP.zzinsp_typ     as zzinsp_typ,

    @UI.identification: [{ position: 130 }]
    PurchaseOrderTP.zzvend_cat     as zzvend_cat,

    @UI.identification: [{ position: 140 }]
    PurchaseOrderTP.zzinsp_auth    as zzinsp_auth,

    PurchaseOrderTP.zzpre_awd      as zzpre_awd,
    PurchaseOrderTP.zzpst_awd      as zzpst_awd,
    PurchaseOrderTP.zzarbit        as zzarbit,
    PurchaseOrderTP.zzar_op_dt     as zzar_op_dt,
    PurchaseOrderTP.zzar_cl_dt     as zzar_cl_dt,

    @UI.identification: [{ position: 150 }]
    PurchaseOrderTP.zztpi_add      as zztpi_add,

    @UI.identification: [{ position: 160 }]
    PurchaseOrderTP.zzqad_det      as zzqad_det,

    @UI.identification: [{ position: 170 }]
    PurchaseOrderTP.zzport_con     as zzport_con,

    @UI.identification: [{ position: 170 }]
    PurchaseOrderTP.zzult_con      as zzult_con,

    PurchaseOrderTP.zupflag        as zupflag,

    @UI.identification: [{ position: 180 }]
    PurchaseOrderTP.zznat_proc     as zznat_proc,

    @UI.identification: [{ position: 190 }]
    PurchaseOrderTP.zznitdt        as zznitdt,

    PurchaseOrderTP.zzbider_agr    as zzbider_agr,

    @UI.identification: [{ position: 200 }]
    PurchaseOrderTP.zzsch_st_dt    as zzsch_st_dt,

    @UI.identification: [{ position: 210 }]
    PurchaseOrderTP.zzsch_en_dt    as zzsch_en_dt,

    PurchaseOrderTP.zzsubmi        as zzsubmi,
    PurchaseOrderTP.zzepc          as zzepc,
    PurchaseOrderTP.zzexchng_rate  as zzexchng_rate,
    PurchaseOrderTP.zzusr          as zzusr,
    PurchaseOrderTP.zzpsa          as zzpsa,
    PurchaseOrderTP.zzcpo          as zzcpo,
    PurchaseOrderTP.zzphone        as zzphone,
    PurchaseOrderTP.zzfax          as zzfax,
    PurchaseOrderTP.zzmobile       as zzmobile,
    PurchaseOrderTP.zzemail        as zzemail,
    PurchaseOrderTP.zzindper       as zzindper,
    PurchaseOrderTP.zzindphone     as zzindphone,
    PurchaseOrderTP.zzindfax       as zzindfax,
    PurchaseOrderTP.zzindmobile    as zzindmobile,
    PurchaseOrderTP.zzindemail     as zzindemail,
    PurchaseOrderTP.zzreldate      as zzreldate,
    PurchaseOrderTP.zzrelcode      as zzrelcode,
    PurchaseOrderTP.zzloino        as zzloino,
    PurchaseOrderTP.zzloidt        as zzloidt,
    PurchaseOrderTP.zzfaxdt        as zzfaxdt,
    PurchaseOrderTP.zzflag_kol     as zzflag_kol,
    PurchaseOrderTP.zzflag_mum     as zzflag_mum,
    PurchaseOrderTP.zzflag_chen    as zzflag_chen,
    PurchaseOrderTP.zzflag_del     as zzflag_del,
    PurchaseOrderTP.zzmse          as zzmse,

    @UI.identification: [{ position: 220 }]
    PurchaseOrderTP.zzdmep         as zzdmep,

    PurchaseOrderTP.zsupconct      as zsupconct,
    PurchaseOrderTP.zsupemail      as zsupemail,
    PurchaseOrderTP.zfileno        as zfileno,
    PurchaseOrderTP.zultname       as zultname,
    PurchaseOrderTP.zultstreet     as zultstreet,
    PurchaseOrderTP.zultstreet1    as zultstreet1,
    PurchaseOrderTP.zultcity       as zultcity,
    PurchaseOrderTP.zultcontct     as zultcontct,
    PurchaseOrderTP.zultemail      as zultemail,
    PurchaseOrderTP.zinvname       as zinvname,
    PurchaseOrderTP.zinvstreet     as zinvstreet,
    PurchaseOrderTP.zinvstreet1    as zinvstreet1,
    PurchaseOrderTP.zinvcity       as zinvcity,
    PurchaseOrderTP.zinvcontct     as zinvcontct,
    PurchaseOrderTP.zinvemail      as zinvemail,
    PurchaseOrderTP.zinsname       as zinsname,
    PurchaseOrderTP.zinsstreet     as zinsstreet,
    PurchaseOrderTP.zinsstreet1    as zinsstreet1,
    PurchaseOrderTP.zinscity       as zinscity,
    PurchaseOrderTP.zinscontct     as zinscontct,
    PurchaseOrderTP.zinsemail      as zinsemail,
    PurchaseOrderTP.zpayname       as zpayname,
    PurchaseOrderTP.zpaystreet     as zpaystreet,
    PurchaseOrderTP.zpaystreet1    as zpaystreet1,
    PurchaseOrderTP.zpaycity       as zpaycity,
    PurchaseOrderTP.zpaycontct     as zpaycontct,
    PurchaseOrderTP.zpayemail      as zpayemail,
    PurchaseOrderTP.zgempo         as zgempo
}
