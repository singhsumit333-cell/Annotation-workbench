// galSources.Items  —  review rows plus a live IsReq (required) flag
Sort(
  AddColumns(colReview, IsReq,
    (varCaseType in Split(Required, ",")) ||
    Force ||
    (!IsBlank(RequiredIf) && LookUp(colReview As r, r.Id = RequiredIf).Status = "Concern")
  ),
  Order
)
