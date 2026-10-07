// btnComplete.OnSelect  —  runs the checker and opens the right popup
If(!varChecked,
   Set(varChecked, true);
   // remember what was missing the first time (for QA reporting)
   Set(varFirstMissed, Concat(Distinct(Filter(galIssues.AllItems, Sev = "Missing"), Sec), Value, ";"))
);
Reset(chkAck);
If(
  CountRows(Filter(galIssues.AllItems, Sev = "Missing")) > 0, Set(varPopup, "missing"),
  CountRows(Filter(galIssues.AllItems, Sev = "Check")) > 0,   Set(varPopup, "warnings"),
  Set(varPopup, "note")
)
