# INC01740 — reference as received (21/09/26)

Source: mail forwarded to Arnav, 21/09/26. Gaurav sir to connect on the ticket; functional
contact Omprakash ji. Verbatim below, kept as received — not yet clarified with either.

Ticket [INC01740](https://pal.diligenie.com/incident/1740/details):
Enhancement: Display/Show Item Text for S&D Documents in Manage Customer Line Items

* BTE (Business Transaction Event) 00001430 or SD-FI User Exit (EXIT_SAPLV60B_002):
   * Write a short ABAP snippet inside the user exit to fetch the text from STXH/STXL
     (the text cluster tables) for the respective Sales Order.
   * Sort the source Sales Orders by creation date/time or document number.
   * Read the Header Note 1 of the first Sales Order and assign it to xaccit-sgtxt
     (which maps directly to BSEG-SGTXT).

Why this fixes the Fiori App
The Manage Customer Line Items app reads directly from the Universal Journal (ACDOCA) and
classic FI index tables (BSEG). Once the data pipeline fills the SGTXT field during the
invoice posting phase, the text will instantly appear in the Fiori report, matching your
Statement of Account (SOA) view.
