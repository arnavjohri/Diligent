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

---

# Ticket text as raised (received 21/09/26)

ISSUE:

The Manage Customer Line Items report does not display the item text for documents
generated through S&D. In comparison, item texts for documents posted directly in FI are
displayed as expected.

EXPECTED RESULT:

Regardless of the source of the document, whether issued directly through FI or through
S&D, the item text should be viewable in Manage Customer Line Items, similar to the
descriptions shown in the SOA.

For documents issued through S&D, the details or text maintained in Header Note 1 may be
used as the item text to be displayed in Manage Customer Line Items. In cases where
multiple Sales Orders are included in a single invoice, although this is uncommon, the
Header Note 1 details from the first-created Sales Order may be used.
