The hierarchy of data from IPS is

   IPSStatement:
     the top level, corresponding to the IQ Monthly Statement

     IPSStatementDetail:
       the thirty or so summary lines on the statement

       IpsDetailLine:
         Each Detail line (except CoOp) has a corresponding speadsheet
         containing the transactions that support t6hat detail.

Our process is to upload first, and then allow the user to import when all
the detail lines have been processed and the statement reconciles.

The upload looks like this:

1. The Statement XLSX file is downloaded from IPS, and then uploaded. The
   IpsStatement#show action displays this in a form similar to IPS, but each
   detail item will be waiting for its corresponding supporting lines.

2. The supporting lines are downloaded from IPS. They will often have the
   same base file name, so the browser will assign -1, -2, ... suffixes to
   some of them.

3. The user uploads this bunch of spreadsheets in one or more batches. Each is
   parsed according to its content (determined by the headers). Its total is
   then matched against the totals of the detail lines. When a match is
   found, the lines are assigned to that detail. (If the total matches more
   than one detail, an error is generated).

4. The majority of lines are associated with a particular EAN. We map this to
   a sku before storing the line data in the database.

5. The Co-Op detail is not associated with a SKU, and has no detail lines.
   In addition, there are some detail lines with no EAN (DF Shipping is an example).
   These lines are stored with a NULL sku_id.

During import, we summarize the detail lines into pip RoyaltyItems. Most of
this process is the mapping of IPS detail categories into appropriate PIP
terms. There are a couple of wrinkles:

* Revenue lines may generate either paid or return values in the RoyaltyItem.
  This lets us show the author information on returns.
  Expense items are always stored in the paid RI fields. These will normally
  be negative, but there are some (such as refunding fees on a return) which
  are negative. These will have a negative quantity and a positive value.

* Expenses that are not associated with a particular sku (that is, the CoOp
  detail and any detail lines with no EAN) are totalled. This total is then
  divided by the number of unique skus in the statement, and each sku
  receives the same prorata Misc charge.

