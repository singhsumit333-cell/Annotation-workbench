# Annotation Workbench in Power Apps

Build guide for the Power Apps (canvas app) version of the workbench. It works the
same way as the HTML version:

- one section per review source, each marked Clear / Concern / N/A, with quick-pick phrases;
- a live checker panel listing what is missing (red) and what looks inconsistent (amber);
- **Complete annotation** blocks the note until the red items are fixed and the amber ones are acknowledged;
- the final note is generated in a standard format, copied to the clipboard and saved to a SharePoint list, so QA and team leads can report on handle time and on which checks get missed most.

Build time: about 1.5–2 hours the first time. All the long formulas are in
[`formulas/`](formulas). Copy them from there instead of retyping them.

| File | Paste into |
|---|---|
| `formulas/01-App.OnStart.fx` | **App → OnStart** (configuration lives here) |
| `formulas/02-btnNewCase.OnSelect.fx` | `btnNewCase` → **OnSelect** |
| `formulas/03-galSources.Items.fx` | `galSources` → **Items** |
| `formulas/04-galIssues.Items.fx` | `galIssues` → **Items** (the checker rules) |
| `formulas/05-btnComplete.OnSelect.fx` | `btnComplete` → **OnSelect** |
| `formulas/06-txtNote.Default.fx` | `txtNote` → **Default** |
| `formulas/07-btnSubmit.OnSelect.fx` | `btnSubmit` → **OnSelect** |

---

## 1. Create the SharePoint list

Run `create-sharepoint-list.ps1`, or create a list called **RiskAnnotations** by hand
with these columns. Keep the internal names exactly as written, because the app
writes to them.

| Column | Type |
|---|---|
| Title (rename the display name to *Case ID*) | Single line of text |
| Reviewer, CaseType, Decision, MissedAtFirstCheck | Single line of text |
| ProfileStatus, PriorNotesStatus, DocumentsStatus, ATOStatus, LinkedChecksStatus, ServiceLogStatus, MoneyMovementStatus, CounterpartyStatus, LinkedReviewStatus | Single line of text |
| ProfileNotes, PriorNotesNotes, DocumentsNotes, ATONotes, LinkedChecksNotes, ServiceLogNotes, MoneyMovementNotes, CounterpartyNotes, LinkedReviewNotes | Multiple lines of text (plain) |
| Rationale, RFIRequested, WarningsAcknowledged, FinalNote | Multiple lines of text (plain) |
| HandleTimeMin | Number (1 decimal) |
| CompletedOn | Date and time |

Give reviewers **Contribute** permission on the list.

## 2. Create the app

1. make.powerapps.com → **Create → Blank app → Blank canvas app**, format **Tablet**.
2. **Data → Add data → SharePoint** → your site → **RiskAnnotations**.
3. **Settings → Display**: screen size 1366 × 768, turn off *Scale to fit* if you want it to fill wide monitors.
4. Select **App** in the tree view and paste `01-App.OnStart.fx` into **OnStart**. Then right-click **App → Run OnStart**.
5. Rename `Screen1` to `scrWorkbench` and set its **Fill** to `clrBg`.

Use **classic** controls (Insert → Classic) so the property names below match.

## 3. Header (top strip, height ≈ 64)

| Control | Type | Key properties |
|---|---|---|
| `lblAppTitle` | Label | Text `"Annotation Workbench"`, FontWeight Bold, Size 16 |
| `txtCaseId` | Text input | Default `varCaseId` · OnChange `Set(varCaseId, Self.Text)` · HintText `"Case / account ID"` |
| `txtReviewer` | Text input | Default `varReviewer` · OnChange `Set(varReviewer, Self.Text)` |
| `ddCaseType` | Drop down | Items `["Restriction review", "Onboarding"]` · Default `If(varCaseType = "onboarding", "Onboarding", "Restriction review")` · OnChange `Set(varCaseType, If(Self.Selected.Value = "Onboarding", "onboarding", "review")); Set(varDecision, "")` |
| `tmrAHT` | Timer | Duration `1000` · Repeat `true` · AutoStart `true` · Visible `false` · OnTimerEnd `Set(varNow, Now())` |
| `lblTimer` | Label | Text: see below · Color `If(DateDiff(varStart, varNow, TimeUnit.Minutes) >= varTargetAHTMin, clrWarn, clrAccent)` · Font size 18 |
| `btnNewCase` | Button | Text `"New case"` · OnSelect: `02-btnNewCase.OnSelect.fx` |
| `btnComplete` | Button | Text `"Complete annotation"` · Fill `clrAccent` · OnSelect: `05-btnComplete.OnSelect.fx` |

`lblTimer.Text`:

```
With({s: DateDiff(varStart, varNow, TimeUnit.Seconds)},
  Text(RoundDown(s / 60, 0), "00") & ":" & Text(Mod(s, 60), "00") & "  /  target " & varTargetAHTMin & ":00")
```

## 4. Review sources (left, `galSources`)

Insert a **Blank flexible height** gallery named `galSources`:
X `16`, Y `76`, Width `840`, Height `Parent.Height - 92`, TemplatePadding `8`,
**Items** = `03-galSources.Items.fx`.

Inside the template, add these controls (top to bottom):

| Control | Type | Key properties |
|---|---|---|
| `recCard` | Rectangle | X `0`, Y `0`, Width `Parent.TemplateWidth`, Height `txtNotes.Y + txtNotes.Height + If(chkForce.Visible, 40, 0) + 12`, Fill `White`, BorderColor `If(ThisItem.Id = varJump, clrAccent, clrLine)`, BorderThickness `If(ThisItem.Id = varJump, 3, 1)` |
| `recStripe` | Rectangle | X `0`, Y `0`, Width `5`, Height `recCard.Height`, Fill: see below |
| `lblSecTitle` | Label | X `16`, Y `8`, Text `Text(ThisItem.Order, "00") & "   " & ThisItem.Title`, FontWeight Semibold |
| `lblReq` | Label | X `420`, Y `8`, Text `If(ThisItem.IsReq, "REQUIRED", "IF NEEDED")`, Color `If(ThisItem.IsReq, clrAccent, clrMuted)`, Size 9 |
| `btnClear` | Button | X `560`, Y `6`, W `80`, Text `"Clear"` · OnSelect: see below · Fill `If(ThisItem.Status = "Clear", clrOkSoft, White)` · Color `If(ThisItem.Status = "Clear", clrOk, clrMuted)` |
| `btnConcern` | Button | X `644`, same pattern with `"Concern"`, `clrBadSoft` / `clrBad` |
| `btnNA` | Button | X `728`, same pattern with `"N/A"`, `clrBg` / `Black` |
| `lblWhere` | Label | X `16`, Y `44`, Width `Parent.TemplateWidth - 32`, Text `ThisItem.Where`, AutoHeight `true`, Color `clrMuted`, Size 10 |
| `galChips` | Blank vertical gallery | X `16`, Y `lblWhere.Y + lblWhere.Height + 4`, Width `Parent.TemplateWidth - 32`, WrapCount `3`, TemplateSize `34`, Height `RoundUp(CountRows(Split(ThisItem.Chips, "\|")) / 3, 0) * 38`, Items `AddColumns(Split(ThisItem.Chips, "\|"), SrcId, ThisItem.Id)` |
| `txtNotes` | Text input | X `16`, Y `galChips.Y + galChips.Height + 6`, Width `Parent.TemplateWidth - 32`, Height `80`, Mode `Multiline`, Default `ThisItem.Notes`, HintText `"What did you check and what did you find?"` · OnChange: see below |
| `chkForce` | Checkbox | X `16`, Y `txtNotes.Y + txtNotes.Height + 6`, Visible `IsBlank(ThisItem.Required)`, Text `"Required for this case"`, Default `ThisItem.Force`, OnCheck `Patch(colReview, LookUp(colReview, Id = ThisItem.Id), {Force: true})`, OnUncheck the same with `false` |

In the table, `\|` means a plain `|` character. The backslash only escapes it for Markdown.

**`btnClear.OnSelect`** (for `btnConcern` and `btnNA`, replace `"Clear"` with `"Concern"` or `"N/A"` in both places):

```
Patch(colReview, LookUp(colReview, Id = ThisItem.Id),
      {Status: If(ThisItem.Status = "Clear", "", "Clear")})
```

**`txtNotes.OnChange`**:

```
Patch(colReview, LookUp(colReview, Id = ThisItem.Id), {Notes: Self.Text})
```

**`recStripe.Fill`** (red = missing, amber = check, green = done, grey = not started):

```
If(CountRows(Filter(galIssues.AllItems, Sev = "Missing" && Sec = ThisItem.Id)) > 0, clrBad,
   CountRows(Filter(galIssues.AllItems, Sec = ThisItem.Id)) > 0, clrWarn,
   !IsBlank(ThisItem.Status), clrOk,
   clrLine)
```

**Inside `galChips`**, add one button `btnChip` (Width `Parent.TemplateWidth - 6`, Height `30`,
Fill `clrBg`, Color `Black`, BorderColor `clrLine`, RadiusTopLeft/… `15`, Size 10):

- Text:
  ```
  If(StartsWith(ThisItem.Value, "!") || StartsWith(ThisItem.Value, "~"), Mid(ThisItem.Value, 2), ThisItem.Value)
  ```
- OnSelect: appends the phrase to the notes. If no status is set yet, it sets one: `!` phrases set Concern, plain phrases set Clear, and `~` phrases leave it unset.
  ```
  With(
    {cur: LookUp(colReview, Id = ThisItem.SrcId),
     txt: Trim(If(StartsWith(ThisItem.Value, "!") || StartsWith(ThisItem.Value, "~"), Mid(ThisItem.Value, 2), ThisItem.Value))},
    Patch(colReview, cur, {
      Notes:  If(IsBlank(Trim(cur.Notes)), txt, Trim(cur.Notes) & "; " & txt),
      Status: If(!IsBlank(cur.Status), cur.Status,
                 StartsWith(ThisItem.Value, "!"), "Concern",
                 StartsWith(ThisItem.Value, "~"), "",
                 "Clear")
    })
  )
  ```

## 5. Verdict and checker (right panel, X `872`, Width `478`)

| Control | Type | Key properties |
|---|---|---|
| `lblVerdictHead` | Label | Text `"Verdict"`, FontWeight Semibold |
| `galDecisions` | Blank **horizontal** gallery | Height `44`, TemplateSize `155`, Items `Filter(colDecisions, CaseType = varCaseType)` |
| ↳ `btnDecision` | Button (inside) | Text `ThisItem.Label` · OnSelect `Set(varDecision, If(varDecision = ThisItem.Key, "", ThisItem.Key))` · Fill `If(varDecision = ThisItem.Key, clrAccent, White)` · Color `If(varDecision = ThisItem.Key, White, clrAccent)` · Size 10 |
| `txtRationale` | Text input | Mode Multiline, Height `90`, Default `varRationale`, OnChange `Set(varRationale, Self.Text)`, HintText `"Why this decision? Tie it to the findings."`, BorderColor `If(varJump = "verdict", clrAccent, clrLine)` |
| `txtRFI` | Text input | Mode Multiline, Height `60`, Visible `varDecision = "rfi"`, Default `varRFI`, OnChange `Set(varRFI, Self.Text)`, HintText `"Documents / information requested from the seller"` |
| `lblScore` | Label | Text: see below, FontWeight Semibold |
| `galIssues` | Blank vertical gallery | Items = `04-galIssues.Items.fx`, TemplateSize `58`, Height to the bottom of the screen · OnSelect: see below |
| ↳ `lblIssue` | Label (inside) | Width `Parent.TemplateWidth`, Height `52`, Text `If(ThisItem.Sev = "Missing", "Missing: ", "Check: ") & ThisItem.Msg`, Fill `If(ThisItem.Sev = "Missing", clrBadSoft, clrWarnSoft)`, Size 10, VerticalAlign Top, PaddingLeft 8 |
| `lblAllClear` | Label | Visible `CountRows(galIssues.AllItems) = 0`, Text `"All clear. Every required source is covered."`, Color `clrOk`, Fill `clrOkSoft` |

**`lblScore.Text`**:

```
With({req: Filter(galSources.AllItems, IsReq || !IsBlank(Status))},
  CountRows(Filter(req As s, !IsBlank(s.Status) &&
      CountRows(Filter(galIssues.AllItems, Sev = "Missing" && Sec = s.Id)) = 0))
  & " / " & CountRows(req) & " sources covered")
```

**`galIssues.OnSelect`** (selecting an item outlines that section, or focuses the field):

```
Set(varJump, ThisItem.Sec);
If(ThisItem.Sec = "verdict", SetFocus(txtRationale),
   ThisItem.Sec = "case",    SetFocus(txtCaseId))
```

## 6. Completion popup

Insert a **Container** `conPopup` at X `0`, Y `0`, Width `Parent.Width`, Height `Parent.Height`,
Visible `varPopup <> ""`. Keep it at the top of the tree view so it sits over everything else.
Inside it:

| Control | Type | Key properties |
|---|---|---|
| `recDim` | Rectangle | Full size, Fill `RGBA(8, 16, 19, 0.55)` |
| `recDialog` | Rectangle | X `(Parent.Width - 720) / 2`, Y `50`, W `720`, H `640`, Fill `White` |
| `lblPopupTitle` | Label | Text: see below, Size 16, FontWeight Bold |
| `lblPopupHelp` | Label | Text: see below, Color `clrMuted` |
| `galPopupIssues` | Blank vertical gallery | Visible `varPopup <> "note"`, Items `Filter(galIssues.AllItems, Sev = If(varPopup = "missing", "Missing", "Check"))`, OnSelect `Set(varJump, ThisItem.Sec); Set(varPopup, "")`, with a label inside: Text `ThisItem.Msg`, Fill `If(ThisItem.Sev = "Missing", clrBadSoft, clrWarnSoft)` |
| `chkAck` | Checkbox | Visible `varPopup = "warnings"`, Text `"I have looked at each of these"`, Default `false` |
| `btnAckGo` | Button | Visible `varPopup = "warnings"`, Text `"Acknowledge & generate note"`, DisplayMode `If(chkAck.Value, DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect `Set(varPopup, "note")` |
| `txtNote` | Text input | Visible `varPopup = "note"`, Mode Multiline, Height `420`, Font `Font.'Courier New'`, Size 10, Default = `06-txtNote.Default.fx` (reviewers can still edit it) |
| `btnSubmit` | Button | Visible `varPopup = "note"`, Text `"Copy note & save"`, Fill `clrAccent`, OnSelect = `07-btnSubmit.OnSelect.fx` |
| `btnClose` | Button | Text `If(varPopup = "missing", "Close", "Back to case")`, OnSelect `Set(varPopup, "")` |

**`lblPopupTitle.Text`**:

```
Switch(varPopup,
  "missing",  "You missed " & CountRows(Filter(galIssues.AllItems, Sev = "Missing")) & " item(s)",
  "warnings", "Double-check " & CountRows(Filter(galIssues.AllItems, Sev = "Check")) & " thing(s)",
  "Annotation ready")
```

**`lblPopupHelp.Text`**:

```
Switch(varPopup,
  "missing",  "Fix these before the note can be generated. Select one to go to it.",
  "warnings", "Nothing is missing, but these look inconsistent. Fix them, or acknowledge them to continue.",
  "Handle time " & lblTimer.Text & ". Copy the note into the case tool.")
```

## 7. Test, publish, share

Test these five cases in preview (F5):

1. **Empty case → Complete.** Expect a list of every required source plus *Choose a verdict*.
2. **Money movement = Concern.** Counterparty review switches to REQUIRED.
3. **Write "new device" in Service log with ATO = Clear.** Expect an amber *'new device' is mentioned…* item.
4. **Lift restrictions with any Concern and a short rationale.** Expect a red item asking for mitigation.
5. **Fill everything correctly → Complete → Copy note & save.** A new row appears in RiskAnnotations, the note is on the clipboard, and the screen resets.

Then **File → Save → Publish** and **Share** the app with the team. Reviewers also need
Contribute permission on the list.

## 8. Changing rules and sources (team lead)

- **Sources, quick-pick phrases, verdict options, keywords, target handle time:** edit the
  CONFIGURATION block in **App → OnStart**, then save and publish. No other change is needed,
  unless you add a new source. For a new source, also add its two columns to the list
  and two lines to `btnSubmit.OnSelect`.
- **A new SOP rule:** add one row to the *Case and verdict rules* table in `galIssues.Items`:
  `{Sev: "Missing" or "Check", Sec: "<source id or verdict>", Msg: "<what to tell the reviewer>", Show: <condition>}`.
  For example, require a counterparty review on every Part ways:
  `{Sev: "Missing", Sec: "counterparty", Msg: "Part ways needs a counterparty review.", Show: varDecision = "partways" && IsBlank(LookUp(colReview, Id = "counterparty").Status)}`

## 9. Reporting ideas

The RiskAnnotations list doubles as a QA dataset. Connect Power BI, or use list views
grouped by:

- **MissedAtFirstCheck**: which sources reviewers forget most often (coaching topics);
- **HandleTimeMin** by reviewer and case type: AHT trend;
- **Decision** against **WarningsAcknowledged**: verdicts made despite warnings, for QA sampling.

## Troubleshooting

- **Errors on `AddColumns(colSources, Status, "", …)` or `Ungroup(…, T)`.** Your environment uses
  the older formula syntax with quoted column names. Write `AddColumns(colSources, "Status", "", "Notes", "", "Force", false)`,
  `AddColumns(colReview, "IsReq", …)`, `AddColumns(Split(…), "SrcId", ThisItem.Id)`, `Ungroup(…, "T")`
  and `ShowColumns(…, "Sev", "Sec", "Msg")`.
- **The checker updates only when you leave a notes box.** That is how classic text inputs fire
  OnChange. The checker always re-runs before Complete annotation.
- **Copy does nothing** (some embedded hosts block the clipboard). The note is still saved. Select
  the text in the note box and press Ctrl+C.
- **Status buttons react but the stripe colour doesn't change.** Check that `galIssues.Items` has
  no formula errors. The stripe reads from it.
