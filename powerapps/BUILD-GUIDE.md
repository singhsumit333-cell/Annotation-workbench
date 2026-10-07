# Annotation Workbench in Power Apps

Build guide for the Power Apps (canvas app) version of the workbench. It works the
same way as the HTML version:

- one section per review source, each marked Clear / Concern / N/A, with quick-pick phrases;
- a live checker panel listing what is missing (red) and what looks inconsistent (amber);
- **Complete annotation** blocks the note until the red items are fixed and the amber ones are acknowledged;
- the final note is generated in a standard format for the reviewer to copy into the case tool;
- what gets saved is up to you: nothing, check results and handle time only (no customer data), or the full case (see **Privacy and saving** below);
- cases are erased from the app as soon as they're cleared, and the app asks before clearing or closing a case in progress.

## Privacy and saving

The HTML version runs fully offline. Power Apps can't: it is a Microsoft 365 cloud service,
so the app loads from your company's Microsoft tenant and needs a connection. What you type
stays in the app in your browser until a reviewer presses **Save & start next case**. At that
point, the setting `varSaveMode` in **App → OnStart** decides what is written to the
RiskAnnotations list:

| `varSaveMode` | Saved to SharePoint | Use when |
|---|---|---|
| `"none"` | Nothing. The button becomes **Clear & start next case**. | You want the same behaviour as the HTML version. No SharePoint list is needed for saving. |
| `"metrics"` (default) | Status of each source (Clear / Concern / N/A), verdict, handle time, checks missed at first try, warnings acknowledged, reviewer, date. **No case ID, notes, rationale or final note.** | You want QA and handle-time reporting without customer data. |
| `"full"` | Everything above, plus case ID, all notes, rationale, requested info and the final note. | Your data policy allows case notes in SharePoint. |

Whatever the mode:

- the case is erased from the app as soon as it is cleared; nothing stays between cases;
- **New case** and **Show example** ask before clearing a case that has something in it;
- closing or refreshing the browser tab with a case in progress asks for confirmation first;
- the example case is never saved;
- a label in the header tells reviewers what the current mode saves.

Check with your InfoSec or data-protection team which mode is allowed before rolling the app out.

Build time: about 1.5–2 hours the first time. All the long formulas are in
[`formulas/`](formulas). Copy them from there instead of retyping them.

| File | Paste into |
|---|---|
| `formulas/01-App.OnStart.fx` | **App → OnStart** (configuration lives here) |
| `formulas/02-btnResetCase.OnSelect.fx` | `btnResetCase` (hidden) → **OnSelect** |
| `formulas/03-galSources.Items.fx` | `galSources` → **Items** |
| `formulas/04-galIssues.Items.fx` | `galIssues` → **Items** (the checker rules) |
| `formulas/05-btnComplete.OnSelect.fx` | `btnComplete` → **OnSelect** |
| `formulas/06-txtNote.Default.fx` | `txtNote` → **Default** |
| `formulas/07-btnSubmit.OnSelect.fx` | `btnSubmit` → **OnSelect** |
| `formulas/08-tglHasContent.Default.fx` | `tglHasContent` (hidden) → **Default** |
| `formulas/09-btnLoadExample.OnSelect.fx` | `btnLoadExample` (hidden) → **OnSelect** |

---

## 1. Create the SharePoint list

Skip this step if you will use `varSaveMode = "none"`. In that case, also delete the
`With({full: …})` block and the `If(IsEmpty(Errors(…)))` block from `07-btnSubmit.OnSelect.fx`.
They are the only parts that use the list.

Run `create-sharepoint-list.ps1`, or create a list called **RiskAnnotations** by hand
with these columns. Keep the internal names exactly as written, because the app
writes to them.

| Column | Type |
|---|---|
| Title (rename the display name to *Case ID*) | Single line of text |
| Reviewer, CaseType, Decision, MissedAtFirstCheck | Single line of text |
| ProfileStatus, PriorNotesStatus, DocumentsStatus, ATOStatus, LinkedReviewStatus, ServiceLogStatus, MoneyMovementStatus, TransactionLogStatus, CounterpartyStatus, ExternalSearchStatus | Single line of text |
| ProfileNotes, PriorNotesNotes, DocumentsNotes, ATONotes, LinkedReviewNotes, ServiceLogNotes, MoneyMovementNotes, TransactionLogNotes, CounterpartyNotes, ExternalSearchNotes | Multiple lines of text (plain) |
| Rationale, VerdictDetail, WarningsAcknowledged, FinalNote | Multiple lines of text (plain) |
| HandleTimeMin | Number (1 decimal) |
| CompletedOn | Date and time |

Give reviewers **Contribute** permission on the list. In `"metrics"` mode the Notes, Rationale,
VerdictDetail and FinalNote columns stay empty. You can delete them, but then also delete
those lines from `07-btnSubmit.OnSelect.fx`.

## 2. Create the app

1. make.powerapps.com → **Create → Blank app → Blank canvas app**, format **Tablet**.
2. **Data → Add data → SharePoint** → your site → **RiskAnnotations**.
3. **Settings → Display**: screen size 1366 × 768, turn off *Scale to fit* if you want it to fill wide monitors.
4. Select **App** in the tree view and paste `01-App.OnStart.fx` into **OnStart**. Then right-click **App → Run OnStart**.
5. Rename `Screen1` to `scrWorkbench` and set its **Fill** to `clrBg`.
6. Still on **App**, set **ConfirmExit** to `tglHasContent.Value` and **ConfirmExitMessage** to
   `"This case isn't finished. Leaving will erase it."` (add `tglHasContent` in step 3 first, then come back).
   ConfirmExit works in the browser. Teams and the mobile apps ignore it.

Use **classic** controls (Insert → Classic) so the property names below match.

## 3. Header (top strip, height ≈ 64)

| Control | Type | Key properties |
|---|---|---|
| `lblAppTitle` | Label | Text `"Annotation Workbench"`, FontWeight Bold, Size 16 |
| `txtCaseId` | Text input | Default `varCaseId` · OnChange `Set(varCaseId, Self.Text)` · HintText `"Case / account ID"` |
| `txtReviewer` | Text input | Default `varReviewer` · OnChange `Set(varReviewer, Self.Text)` |
| `ddCaseType` | Drop down | Items `["Restriction review", "Onboarding"]` · Default `If(varCaseType = "onboarding", "Onboarding", "Restriction review")` · OnChange `Set(varCaseType, If(Self.Selected.Value = "Onboarding", "onboarding", "review"))` |
| `tmrAHT` | Timer | Duration `1000` · Repeat `true` · AutoStart `true` · Visible `false` · OnTimerEnd `Set(varNow, Now())` |
| `lblTimer` | Label | Text: see below · Color `If(DateDiff(varStart, varNow, TimeUnit.Minutes) >= varTargetAHTMin, clrWarn, clrAccent)` · Font size 18 |
| `lblPrivacy` | Label | Under the title. Text: see below · Size 9 · Color `clrOk` · Fill `clrOkSoft` |
| `btnShowExample` | Button | Text `"Show example"` · OnSelect `If(tglHasContent.Value, Set(varPopup, "confirmExample"), Select(btnLoadExample))` |
| `btnNewCase` | Button | Text `"New case"` · OnSelect `If(tglHasContent.Value, Set(varPopup, "confirmNew"), Select(btnResetCase))` |
| `lblExampleBanner` | Label | Below the header, full width · Visible `varExample` · Fill `clrWarnSoft` · Text `"Example case with made-up details, so you can see the checker working. Select New case to clear it and start a real one."` |
| `btnResetCase` | Button | **Visible `false`** · OnSelect: `02-btnResetCase.OnSelect.fx` |
| `btnLoadExample` | Button | **Visible `false`** · OnSelect: `09-btnLoadExample.OnSelect.fx` |
| `tglHasContent` | Toggle | **Visible `false`** · Default: `08-tglHasContent.Default.fx` |
| `btnComplete` | Button | Text `"Complete annotation"` · Fill `clrAccent` · OnSelect: `05-btnComplete.OnSelect.fx` |

`lblPrivacy.Text`:

```
Switch(varSaveMode,
  "none",    "Nothing is saved · the case is erased when you clear it or leave",
  "metrics", "Only check results and handle time are saved · no case ID or notes",
  "Completed cases are saved in full to the RiskAnnotations list")
```

`lblTimer.Text`:

```
With({s: DateDiff(varStart, varNow, TimeUnit.Seconds)},
  Text(RoundDown(s / 60, 0), "00") & ":" & Text(Mod(s, 60), "00") & "  /  target " & varTargetAHTMin & ":00")
```

## 4. Review sources (left, `galSources`)

A source counts as covered when the reviewer picks a result (Clear / Concern / N/A) **or**
writes their own note. The result buttons and quick-picks are shortcuts. Picking a result
is still worth it, because rules such as "Counterparty review is required when Money movement
is Concern" only react to the Concern mark.

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

In the tables in this guide, `\|` means a plain `|` character. The backslash only escapes it for Markdown.

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
   !IsBlank(ThisItem.Status) || !IsBlank(Trim(ThisItem.Notes)), clrOk,
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
| `galDecisions` | Blank **vertical** gallery | WrapCount `3`, TemplateSize `40`, Height `84`, Items `Sort(colDecisions, Order)` |
| ↳ `btnDecision` | Button (inside) | Text `ThisItem.Label` · OnSelect `Set(varDecision, If(varDecision = ThisItem.Key, "", ThisItem.Key))` · Fill `If(varDecision = ThisItem.Key, clrAccent, White)` · Color `If(varDecision = ThisItem.Key, White, clrAccent)` · Size 10 |
| `txtRationale` | Text input | Mode Multiline, Height `90`, Default `varRationale`, OnChange `Set(varRationale, Self.Text)`, HintText `"Why this decision? Tie it to the findings."`, BorderColor `If(varJump = "verdict", clrAccent, clrLine)` |
| `lblDetail` | Label | Visible `!IsBlank(LookUp(colDecisions, Key = varDecision).Detail)`, Text `LookUp(colDecisions, Key = varDecision).Detail`, Size 9, Color `clrMuted` |
| `txtDetail` | Text input | Mode Multiline, Height `60`, Visible `lblDetail.Visible`, Default `varDetail`, OnChange `Set(varDetail, Self.Text)`, HintText `LookUp(colDecisions, Key = varDecision).Hint` |
| `lblScore` | Label | Text: see below, FontWeight Semibold |
| `galIssues` | Blank vertical gallery | Items = `04-galIssues.Items.fx`, TemplateSize `58`, Height to the bottom of the screen · OnSelect: see below |
| ↳ `lblIssue` | Label (inside) | Width `Parent.TemplateWidth`, Height `52`, Text `If(ThisItem.Sev = "Missing", "Missing: ", "Check: ") & ThisItem.Msg`, Fill `If(ThisItem.Sev = "Missing", clrBadSoft, clrWarnSoft)`, Size 10, VerticalAlign Top, PaddingLeft 8 |
| `lblAllClear` | Label | Visible `CountRows(galIssues.AllItems) = 0`, Text `"All clear. Every required source is covered."`, Color `clrOk`, Fill `clrOkSoft` |

**`lblScore.Text`**:

```
With({req: Filter(galSources.AllItems, IsReq || !IsBlank(Status) || !IsBlank(Trim(Notes)))},
  CountRows(Filter(req As s, (!IsBlank(s.Status) || !IsBlank(Trim(s.Notes))) &&
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
| `galPopupIssues` | Blank vertical gallery | Visible `varPopup = "missing" \|\| varPopup = "warnings"`, Items `Filter(galIssues.AllItems, Sev = If(varPopup = "missing", "Missing", "Check"))`, OnSelect `Set(varJump, ThisItem.Sec); Set(varPopup, "")`, with a label inside: Text `ThisItem.Msg`, Fill `If(ThisItem.Sev = "Missing", clrBadSoft, clrWarnSoft)` |
| `chkAck` | Checkbox | Visible `varPopup = "warnings"`, Text `"I have looked at each of these"`, Default `false` |
| `btnAckGo` | Button | Visible `varPopup = "warnings"`, Text `"Acknowledge & generate note"`, DisplayMode `If(chkAck.Value, DisplayMode.Edit, DisplayMode.Disabled)`, OnSelect `Set(varPopup, "note")` |
| `btnConfirmClear` | Button | Visible `varPopup = "confirmNew" \|\| varPopup = "confirmExample"`, Text `"Clear case"`, Fill `clrBad`, OnSelect: see below |
| `txtNote` | Text input | Visible `varPopup = "note"`, Mode Multiline, Height `400`, Font `Font.'Courier New'`, Size 10, Default = `06-txtNote.Default.fx` (reviewers can still edit it) |
| `btnCopy` | Button | Visible `varPopup = "note"`, Text `If(varCopied, "Copied", "Copy note")`, Fill `clrAccent`, OnSelect `Copy(txtNote.Text); Set(varCopied, true); Notify("Note copied", NotificationType.Success, 1500)` |
| `btnSubmit` | Button | Visible `varPopup = "note"`, Text `If(varSaveMode = "none" \|\| varExample, "Clear & start next case", "Save & start next case")`, OnSelect = `07-btnSubmit.OnSelect.fx` |
| `lblNoteHint` | Label | Visible `varPopup = "note"`, Color `clrMuted`, Size 10, Text `"Paste the note into the case tool before clearing. Clearing erases this case from the app."` |
| `btnClose` | Button | Text `Switch(varPopup, "missing", "Close", "confirmNew", "Keep case", "confirmExample", "Keep case", "Back to case")`, OnSelect `Set(varPopup, "")` |

**`btnConfirmClear.OnSelect`** (it remembers which button asked, closes the popup, then clears):

```
With({act: varPopup},
  Set(varPopup, "");
  If(act = "confirmExample", Select(btnLoadExample), Select(btnResetCase)))
```

**`lblPopupTitle.Text`**:

```
Switch(varPopup,
  "missing",  "You missed " & CountRows(Filter(galIssues.AllItems, Sev = "Missing")) & " item(s)",
  "warnings", "Double-check " & CountRows(Filter(galIssues.AllItems, Sev = "Check")) & " thing(s)",
  "confirmNew", "Clear this case?",
  "confirmExample", "Replace this case with the example?",
  "Annotation ready")
```

**`lblPopupHelp.Text`**:

```
Switch(varPopup,
  "missing",  "Fix these before the note can be generated. Select one to go to it.",
  "warnings", "Nothing is missing, but these look inconsistent. Fix them, or acknowledge them to continue.",
  "confirmNew", "Everything typed for this case will be erased. It has not been saved.",
  "confirmExample", "Everything typed for this case will be erased and the example loaded. It has not been saved.",
  "Handle time " & lblTimer.Text & ". Copy the note into the case tool.")
```

## 7. Test, publish, share

Test these cases in preview (F5):

1. **Empty case → Complete.** Expect a list of every required source plus *Choose a verdict*.
2. **Money movement = Concern.** Counterparty review switches to REQUIRED.
3. **Write "new device" in Service log with ATO = Clear.** Expect an amber *'new device' is mentioned…* item.
4. **Lift limitation with any Concern and a short rationale.** Expect a red item asking for mitigation.
5. **Pick Raised URP ticket.** A *URP ticket number and reason* box appears and stays red until it is filled. The note ends with that line.
6. **Fill everything correctly → Complete → Copy note → Save & start next case.** The note is on the clipboard and the screen resets. In `"metrics"` mode a new row appears in RiskAnnotations with statuses and handle time, but no case ID or notes.
7. **Type something, then click New case.** Expect *Clear this case?*. **Keep case** leaves it as it was.
8. **Show example → Save & start next case.** Expect *Example case: nothing was saved.* and no new row.
9. **Type something, then close the browser tab** (published app in a browser). Expect a leave-page warning.

Then **File → Save → Publish** and **Share** the app with the team. Reviewers also need
Contribute permission on the list.

## 8. Changing rules and sources (team lead)

- **What is saved:** change `varSaveMode` in **App → OnStart** (see **Privacy and saving**).
- **Verdict options:** edit `colDecisions` in **App → OnStart**. Give a verdict a `Detail` label to make an extra box appear (and be required) when it is picked.
- **Sources, quick-pick phrases, keywords, target handle time:** edit the
  CONFIGURATION block in **App → OnStart**, then save and publish. No other change is needed,
  unless you add a new source. For a new source, also add its two columns to the list
  and two lines to `btnSubmit.OnSelect`.
- **A new SOP rule:** add one row to the *Case and verdict rules* table in `galIssues.Items`:
  `{Sev: "Missing" or "Check", Sec: "<source id or verdict>", Msg: "<what to tell the reviewer>", Show: <condition>}`.
  For example, require a counterparty review on every Deny limitation:
  `{Sev: "Missing", Sec: "counterparty", Msg: "Deny limitation needs a counterparty review.", Show: varDecision = "deny" && IsBlank(LookUp(colReview, Id = "counterparty").Status)}`

## 9. Reporting ideas

In `"metrics"` or `"full"` mode, the RiskAnnotations list doubles as a QA dataset. Connect Power BI, or use list views
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
- **Clicking New case or Save does nothing.** `Select()` runs the hidden buttons `btnResetCase` and
  `btnLoadExample`. If your environment won't select hidden controls, set them to Visible `true`,
  Width and Height `1`, and move them behind the header.
