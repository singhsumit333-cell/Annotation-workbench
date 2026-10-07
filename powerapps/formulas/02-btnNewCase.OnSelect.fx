// btnNewCase.OnSelect  —  clears the screen for the next case (reviewer and case type are kept)
ClearCollect(colReview, AddColumns(colSources, Status, "", Notes, "", Force, false));
Set(varCaseId, ""); Set(varDecision, ""); Set(varRationale, ""); Set(varRFI, "");
Set(varPopup, ""); Set(varJump, ""); Set(varChecked, false); Set(varFirstMissed, "");
Set(varStart, Now()); Set(varNow, Now());
Reset(txtCaseId); Reset(txtRationale); Reset(txtRFI); Reset(chkAck);
SetFocus(txtCaseId)
