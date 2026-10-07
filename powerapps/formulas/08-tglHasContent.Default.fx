// tglHasContent.Default  (hidden toggle)  —  true while a real case has something typed in it.
// Used by New case / Show example (ask before clearing) and App.ConfirmExit (warn before closing).
!varExample && (
  !IsBlank(Trim(varCaseId)) ||
  !IsBlank(varDecision) ||
  !IsBlank(Trim(varRationale)) ||
  !IsBlank(Trim(varDetail)) ||
  CountRows(Filter(colReview, !IsBlank(Status) || !IsBlank(Trim(Notes)))) > 0
)
