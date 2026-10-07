// btnSubmit.OnSelect  —  "Save & start next case" (or "Clear & start next case" when varSaveMode = "none")
// Saves according to varSaveMode, then erases the case from the app.
// Copying the note is a separate button (btnCopy), so reviewers paste it before clearing.
If(
  varExample,
    Notify("Example case: nothing was saved.", NotificationType.Information, 2500);
    Select(btnResetCase),

  varSaveMode = "none",
    Notify("Case cleared. Nothing was saved.", NotificationType.Success, 2500);
    Select(btnResetCase),

  // "metrics" or "full"
  With({full: varSaveMode = "full"},
    Patch(RiskAnnotations, Defaults(RiskAnnotations), {
      Title:                If(full, varCaseId, "Case " & Text(Now(), "yyyymmdd-hhmmss")),
      Reviewer:             varReviewer,
      CaseType:             Switch(varCaseType, "onboarding", "Onboarding", "payout", "Payout review", "Restriction review"),
      ProfileStatus:        LookUp(colReview, Id = "profile").Status,
      ProfileNotes:         If(full, LookUp(colReview, Id = "profile").Notes, ""),
      PriorNotesStatus:     LookUp(colReview, Id = "prior").Status,
      PriorNotesNotes:      If(full, LookUp(colReview, Id = "prior").Notes, ""),
      DocumentsStatus:      LookUp(colReview, Id = "documents").Status,
      DocumentsNotes:       If(full, LookUp(colReview, Id = "documents").Notes, ""),
      ATOStatus:            LookUp(colReview, Id = "ato").Status,
      ATONotes:             If(full, LookUp(colReview, Id = "ato").Notes, ""),
      LinkedReviewStatus:   LookUp(colReview, Id = "linked").Status,
      LinkedReviewNotes:    If(full, LookUp(colReview, Id = "linked").Notes, ""),
      ServiceLogStatus:     LookUp(colReview, Id = "service").Status,
      ServiceLogNotes:      If(full, LookUp(colReview, Id = "service").Notes, ""),
      MoneyMovementStatus:  LookUp(colReview, Id = "money").Status,
      MoneyMovementNotes:   If(full, LookUp(colReview, Id = "money").Notes, ""),
      TransactionLogStatus: LookUp(colReview, Id = "txnlog").Status,
      TransactionLogNotes:  If(full, LookUp(colReview, Id = "txnlog").Notes, ""),
      CounterpartyStatus:   LookUp(colReview, Id = "counterparty").Status,
      CounterpartyNotes:    If(full, LookUp(colReview, Id = "counterparty").Notes, ""),
      ExternalSearchStatus: LookUp(colReview, Id = "external").Status,
      ExternalSearchNotes:  If(full, LookUp(colReview, Id = "external").Notes, ""),
      AccountAgeStatus:     LookUp(colReview, Id = "acctAge").Status,
      AccountAgeNotes:      If(full, LookUp(colReview, Id = "acctAge").Notes, ""),
      EmailDomainStatus:    LookUp(colReview, Id = "email").Status,
      EmailDomainNotes:     If(full, LookUp(colReview, Id = "email").Notes, ""),
      ProcessingStatus:     LookUp(colReview, Id = "processing").Status,
      ProcessingNotes:      If(full, LookUp(colReview, Id = "processing").Notes, ""),
      BusinessModelStatus:  LookUp(colReview, Id = "bizModel").Status,
      BusinessModelNotes:   If(full, LookUp(colReview, Id = "bizModel").Notes, ""),
      MCCStatus:            LookUp(colReview, Id = "mcc").Status,
      MCCNotes:             If(full, LookUp(colReview, Id = "mcc").Notes, ""),
      Decision:             LookUp(colDecisions, Key = varDecision).Label,
      Rationale:            If(full, varRationale, ""),
      VerdictDetail:         If(full, varDetail, ""),
      HandleTimeMin:        Round(DateDiff(varStart, Now(), TimeUnit.Seconds) / 60, 1),
      MissedAtFirstCheck:   varFirstMissed,
      WarningsAcknowledged: Concat(Filter(galIssues.AllItems, Sev = "Check"), Msg, Char(10)),
      FinalNote:            If(full, txtNote.Text, ""),
      CompletedOn:          Now()
    })
  );
  If(IsEmpty(Errors(RiskAnnotations)),
     Notify("Case saved. Starting the next one.", NotificationType.Success, 2500);
     Select(btnResetCase),
     Notify("Saving to SharePoint failed, so the case was kept: " & First(Errors(RiskAnnotations)).Message, NotificationType.Error)
  )
)
