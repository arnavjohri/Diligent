* Reference copy, standard SAP method as pasted by Arnav on 16/10/26, with the team's
* existing implicit enhancement ZEI_GL_WORKLFOW_INTR at the end. Not ours. Do not edit.
* Message FDC_POSTING_001 092 "Parked document is no GL posting" comes from the KOARS check:
*   IF iv_koars CO cl_fdc_accdoc_park_access=>co_allowed_acct_ty_for_parking.
* A customer credit memo carries account type 'D' and fails it. The existing enhancement
* clears the error only for post mode '2' on gl_posting documents.
