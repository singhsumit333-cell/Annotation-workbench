// btnLoadExample.OnSelect  (hidden button)  —  loads a made-up example case so people can see the checker.
// Example cases are never saved.
ClearCollect(colReview, AddColumns(colSources, Status, "", Notes, "", Force, false));
Patch(colReview, LookUp(colReview, Id = "profile"),   {Status: "Clear",   Notes: "Sole trader, home décor, account opened 14 months ago. Restriction reason: high-risk payment review after spike in volume."});
Patch(colReview, LookUp(colReview, Id = "prior"),     {Status: "Clear",   Notes: "One prior review (Mar) cleared with no concerns."});
Patch(colReview, LookUp(colReview, Id = "documents"), {Status: "Clear",   Notes: "ID and proof of address verified; bank statement matches account name."});
Patch(colReview, LookUp(colReview, Id = "service"),   {Status: "Concern", Notes: "Seller called 2 days ago saying a new device was used because their phone was lost; asked for funds to be released urgently."});
Patch(colReview, LookUp(colReview, Id = "money"),     {Status: "Concern", Notes: "Rapid in-and-out (pass-through) funds: 8 round-amount payments of 500.00 withdrawn within 24h."});
Set(varCaseType, "review"); Set(varCaseId, "EX-2048-117");
Set(varDecision, "lift"); Set(varRationale, "Volume spike explained by seasonal sale."); Set(varRFI, "");
Set(varPopup, ""); Set(varJump, ""); Set(varChecked, false); Set(varFirstMissed, "");
Set(varStart, DateAdd(Now(), -9, TimeUnit.Minutes)); Set(varNow, Now());
Set(varExample, true); Set(varCopied, false);
Reset(txtCaseId); Reset(txtRationale); Reset(txtRFI); Reset(ddCaseType); Reset(chkAck)
