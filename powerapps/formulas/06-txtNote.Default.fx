// txtNote.Default  —  the final annotation in your team's standard format
"CASE " & Coalesce(varCaseId, "(no ID)") & " | " &
If(varCaseType = "review", "Restriction review", "Onboarding") & " | " &
varReviewer & " | " & Text(Now(), "dd mmm yyyy hh:mm") &
Char(10) & Char(10) &
Concat(
  Filter(Sort(colReview, Order), !IsBlank(Status) || !IsBlank(Trim(Notes))),
  Upper(Title) & If(IsBlank(Status), "", " [" & Upper(Status) & "]") & ": " & Trim(Notes),
  Char(10)
) &
Char(10) & Char(10) &
"VERDICT: " & Upper(LookUp(colDecisions, CaseType = varCaseType && Key = varDecision).Label) & Char(10) &
"Rationale: " & Trim(varRationale) &
If(varDecision = "rfi", Char(10) & "Requested from seller: " & Trim(varRFI), "") &
If(CountRows(Filter(galIssues.AllItems, Sev = "Check")) > 0,
   Char(10) & Char(10) & "Checker warnings acknowledged (" & CountRows(Filter(galIssues.AllItems, Sev = "Check")) & "):" & Char(10) &
   Concat(Filter(galIssues.AllItems, Sev = "Check"), "- " & Msg, Char(10)),
   "")
