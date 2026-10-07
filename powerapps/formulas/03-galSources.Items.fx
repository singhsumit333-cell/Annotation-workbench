// galSources.Items  —  sources shown for the current case type, in that type's order, plus a live IsReq flag
Sort(
  AddColumns(
    Filter(colReview, varCaseType in Split(Types, ",")),
    IsReq,
    (varCaseType in Split(Required, ",")) ||
    Force ||
    (!IsBlank(RequiredIf) && LookUp(colReview As r, r.Id = RequiredIf).Status = "Concern")
  ),
  If(varCaseType = "payout", PayoutOrder, Order)
)
