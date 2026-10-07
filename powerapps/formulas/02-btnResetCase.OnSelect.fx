// btnResetCase.OnSelect  (hidden button)  —  erases the case and starts the next one.
// Reviewer and case type are kept. Nothing about the erased case stays in the app.
ClearCollect(colReview, AddColumns(colSources, Status, "", Notes, "", Force, false));
Set(varCaseId, ""); Set(varDecision, ""); Set(varRationale, ""); Set(varRFI, "");
Set(varPopup, ""); Set(varJump, ""); Set(varChecked, false); Set(varFirstMissed, "");
Set(varStart, Now()); Set(varNow, Now()); Set(varExample, false); Set(varCopied, false);
Reset(txtCaseId); Reset(txtRationale); Reset(txtRFI); Reset(chkAck); Reset(txtNote);
SetFocus(txtCaseId)
