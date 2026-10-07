// galIssues.Items  —  THE CHECKER. Returns one row per open item: {Sev, Sec, Msg}
//   Sev "Missing" = blocker (must fix), "Check" = warning (must acknowledge)
// Add your own SOP rules as extra rows in the verdict-rules Table() at the bottom.
With(
  {
    rs: AddColumns(colReview, IsReq,
          (varCaseType in Split(Required, ",")) ||
          Force ||
          (!IsBlank(RequiredIf) && LookUp(colReview As r, r.Id = RequiredIf).Status = "Concern")),
    concerns: Filter(colReview, Status = "Concern"),
    dec: LookUp(colDecisions, CaseType = varCaseType && Key = varDecision),
    hits: ForAll(colKeywords As k,
            {Sec: k.Sec,
             Hit: First(Filter(Split(k.Words, "|") As w,
                    w.Value in (Concat(Filter(colReview, Id <> k.Sec), Notes & " ") & " " & varRationale))).Value})
  },
  Sort(
    Ungroup(
      Table(
        // 1. Required source not reviewed (no result picked AND nothing written)
        {T: ForAll(Filter(rs, IsReq && IsBlank(Status) && IsBlank(Trim(Notes))) As s,
              {Sev: "Missing", Sec: s.Id,
               Msg: If(!(varCaseType in Split(s.Required, ",")) && !s.Force,
                       s.Title & " is now required because " & LookUp(colSources, Id = s.RequiredIf).Title & " is marked Concern.",
                       s.Title & " not reviewed yet.")})},

        // 2. Result picked but no real note
        {T: ForAll(Filter(rs, !IsBlank(Status) && Len(Trim(Notes)) < varMinNoteChars) As s,
              {Sev: "Missing", Sec: s.Id,
               Msg: If(s.Status = "N/A",
                       s.Title & ": give the reason it is not applicable.",
                       s.Title & ": write what you saw (type it or use a quick-pick).")})},

        // 3. Mandatory source marked N/A
        {T: ForAll(Filter(rs, Status = "N/A" && (varCaseType in Split(Required, ",")) && Len(Trim(Notes)) >= varMinNoteChars) As s,
              {Sev: "Check", Sec: s.Id, Msg: s.Title & " is normally mandatory for this case type but marked N/A."})},

        // 4. Keyword cross-check: mentioned elsewhere, but the source is not Concern
        {T: ForAll(Filter(hits As h, !IsBlank(h.Hit) && LookUp(colReview, Id = h.Sec).Status <> "Concern") As h2,
              {Sev: "Check", Sec: h2.Sec,
               Msg: "'" & h2.Hit & "' is mentioned in your notes, but " & LookUp(colSources, Id = h2.Sec).Title & " is " &
                    If(!IsBlank(LookUp(colReview, Id = h2.Sec).Status), "marked " & LookUp(colReview, Id = h2.Sec).Status,
                       !IsBlank(Trim(LookUp(colReview, Id = h2.Sec).Notes)), "not marked Concern",
                       "not reviewed") & "."})},

        // 5. Case and verdict rules
        {T: ShowColumns(Filter(Table(
              {Sev: "Missing", Sec: "case", Msg: "Enter the case / account ID.",
               Show: IsBlank(Trim(varCaseId))},
              {Sev: "Missing", Sec: "verdict", Msg: "Choose a verdict.",
               Show: IsBlank(varDecision)},
              {Sev: "Missing", Sec: "verdict", Msg: "Explain the verdict in the rationale (why this decision).",
               Show: !IsBlank(varDecision) && Len(Trim(varRationale)) < 25},
              {Sev: "Missing", Sec: "verdict", Msg: "List the documents / information requested from the seller.",
               Show: varDecision = "rfi" && Len(Trim(varRFI)) < 5},
              {Sev: "Missing", Sec: "verdict",
               Msg: "Verdict clears the account but concerns are open (" & Concat(concerns, Title, ", ") & "). Say how each one is mitigated.",
               Show: dec.Clears && CountRows(concerns) > 0 && Len(Trim(varRationale)) < 80},
              {Sev: "Check", Sec: "verdict",
               Msg: "Clearing the account with open concerns: " & Concat(concerns, Title, ", ") & ". Confirm the rationale covers each.",
               Show: dec.Clears && CountRows(concerns) > 0 && Len(Trim(varRationale)) >= 80},
              {Sev: "Check", Sec: "verdict", Msg: "ATO concern is open. Lifting may release funds to a fraudster; consider RFI or escalation.",
               Show: dec.Clears && LookUp(colReview, Id = "ato").Status = "Concern"},
              {Sev: "Check", Sec: "verdict", Msg: "Document concern is open. Consider Request additional info instead.",
               Show: dec.Clears && LookUp(colReview, Id = "documents").Status = "Concern"},
              {Sev: "Missing", Sec: "verdict", Msg: "Exiting the account but no source is marked Concern. Record the evidence that supports it.",
               Show: dec.Exits && CountRows(concerns) = 0},
              {Sev: "Check", Sec: "documents", Msg: "Previous notes mention a pending RFI. Confirm whether those documents arrived.",
               Show: !IsBlank(varDecision) && varDecision <> "rfi" && LookUp(colReview, Id = "documents").Status <> "Clear" &&
                     ("rfi" in LookUp(colReview, Id = "prior").Notes || "pending" in LookUp(colReview, Id = "prior").Notes)}
            ), Show), Sev, Sec, Msg)}
      ),
      T
    ),
    Sev, SortOrder.Descending   // "Missing" rows first
  )
)
