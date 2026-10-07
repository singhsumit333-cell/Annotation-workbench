# Annotation Workbench

A notepad for seller-account risk reviews with a built-in checker. Reviewers write
their annotation source by source; the checker keeps watching and, when they press
**Complete annotation**, tells them what they missed before a note can be produced.

Open `app/annotation-workbench.html` in any browser (Edge/Chrome). No install and no server.

## Privacy: fully offline

- **No network.** A Content-Security-Policy in the page tells the browser to block every
  request (fonts, images, uploads, API calls). The page uses fonts already installed on the computer.
- **Nothing saved.** The case lives only in the open tab's memory. Nothing is written to
  disk, browser storage or cookies. Closing or refreshing the tab erases it, and the browser
  warns you first if a case is in progress.
- **Clearing.** *Clear & start next case* (after copying the note) and *New case* wipe the page.
- Use the file from your own laptop for real cases, not a hosted copy of the page.

Your company's data policy still decides which tools customer data may be entered into.

## What it does

| Problem | How the workbench handles it |
|---|---|
| Reviewer forgets a source (service log, linked accounts, ATO…) | Every source is a section. It counts as covered when the reviewer writes their own note **or** picks Clear / Concern / N/A or a quick-pick. Required ones block completion until filled. |
| Conditional checks get skipped | Counterparty review becomes required when Money movement is **Concern**. |
| Notes and verdict contradict each other | Lift limitation with open concerns needs a mitigation rationale; Deny limitation with no concern raises a warning; Request additional information, Waiting for internal review, Sent BCL and Raised URP ticket each require their detail (requested info, pending team, BCL details, URP ticket number); open ATO/document concerns on a Lift raise warnings. |
| Something is mentioned but not followed up | Keyword cross-check: e.g. "new device" written in the Service log while ATO is Clear → warning. |
| Slow, inconsistent writing (AHT) | Quick-pick phrases per section, handle-time timer against a target, `Alt+1…9` / `Alt+0` jumps, `Ctrl+Enter` to complete, and a standard formatted note generated for copy-paste into the case tool. |
| Onboarding vs restriction reviews | Case-type switch changes which sources are required. Verdict options are the same for both: Lift limitation, Deny limitation, Request additional information, Waiting for internal review, Sent BCL, Raised URP ticket. |

Blockers (red) must be fixed. Warnings (amber) must each be acknowledged, and the
acknowledgements are written into the final note, which helps QA see the reviewer
considered them.

## Customising (team lead)

Everything team-specific lives in the **CONFIGURATION** block at the top of the
`<script>` in `app/annotation-workbench.html`:

- `SECTIONS` – sources, where-to-look hints, quick-pick phrases, which case types require them, `requiredIf` conditions.
- `VERDICTS` – final verdict options, and which ones need an extra detail box.
- `KEYWORDS` – words that should force a second look at a source.
- `TARGET_AHT_MIN`, `MIN_NOTE_CHARS`.

Add your SOP's rules to `evaluate()` in the same file (each rule is a few lines).

## Rolling it out at work

1. **Pilot as-is**: share the HTML file on SharePoint/Teams; reviewers open it in Edge.
2. **Power Apps version** (if IT prefers Microsoft 365): see
   [`powerapps/BUILD-GUIDE.md`](powerapps/BUILD-GUIDE.md). It has the same sources and rules.
   Power Apps runs in Microsoft 365, so it can't be offline. Instead, one setting
   (`varSaveMode`) decides what completed cases save to a SharePoint list: nothing, check
   results and handle time only (the default, no customer data), or the full case. Cases are
   erased from the app when cleared, and it asks before clearing or closing a case in progress.
   All formulas are in `powerapps/formulas/`, and `powerapps/create-sharepoint-list.ps1` creates the list.
3. **Word alternative**: a .dotm template with content controls per section and a
   VBA macro on save that checks for empty controls – works, but it is the weakest
   option (macros are often blocked, no live checking).

Do not paste customer PII into tools not approved by your company's data policy.
