// btnSubmit.OnSelect  —  copies the note and saves the case to SharePoint for QA reporting
Copy(txtNote.Text);
Patch(RiskAnnotations, Defaults(RiskAnnotations), {
  Title:                varCaseId,
  Reviewer:             varReviewer,
  CaseType:             If(varCaseType = "review", "Restriction review", "Onboarding"),
  ProfileStatus:        LookUp(colReview, Id = "profile").Status,
  ProfileNotes:         LookUp(colReview, Id = "profile").Notes,
  PriorNotesStatus:     LookUp(colReview, Id = "prior").Status,
  PriorNotesNotes:      LookUp(colReview, Id = "prior").Notes,
  DocumentsStatus:      LookUp(colReview, Id = "documents").Status,
  DocumentsNotes:       LookUp(colReview, Id = "documents").Notes,
  ATOStatus:            LookUp(colReview, Id = "ato").Status,
  ATONotes:             LookUp(colReview, Id = "ato").Notes,
  LinkedChecksStatus:   LookUp(colReview, Id = "linked").Status,
  LinkedChecksNotes:    LookUp(colReview, Id = "linked").Notes,
  ServiceLogStatus:     LookUp(colReview, Id = "service").Status,
  ServiceLogNotes:      LookUp(colReview, Id = "service").Notes,
  MoneyMovementStatus:  LookUp(colReview, Id = "money").Status,
  MoneyMovementNotes:   LookUp(colReview, Id = "money").Notes,
  CounterpartyStatus:   LookUp(colReview, Id = "counterparty").Status,
  CounterpartyNotes:    LookUp(colReview, Id = "counterparty").Notes,
  LinkedReviewStatus:   LookUp(colReview, Id = "linkedReview").Status,
  LinkedReviewNotes:    LookUp(colReview, Id = "linkedReview").Notes,
  Decision:             LookUp(colDecisions, CaseType = varCaseType && Key = varDecision).Label,
  Rationale:            varRationale,
  RFIRequested:         varRFI,
  HandleTimeMin:        Round(DateDiff(varStart, Now(), TimeUnit.Seconds) / 60, 1),
  MissedAtFirstCheck:   varFirstMissed,
  WarningsAcknowledged: Concat(Filter(galIssues.AllItems, Sev = "Check"), Msg, Char(10)),
  FinalNote:            txtNote.Text,
  CompletedOn:          Now()
});
If(IsEmpty(Errors(RiskAnnotations)),
   Notify("Note copied and case saved", NotificationType.Success, 2500);
   Select(btnNewCase),
   Notify("Note copied, but saving to SharePoint failed: " & First(Errors(RiskAnnotations)).Message, NotificationType.Error)
)
