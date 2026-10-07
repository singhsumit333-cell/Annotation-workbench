# Annotation Workbench

A notepad for seller-account risk reviews with a built-in checker. Reviewers write
their annotation source by source; the checker keeps watching and, when they press
**Complete annotation**, tells them what they missed before a note can be produced.

Open `app/annotation-workbench.html` in any browser (Edge/Chrome). No install,
no server, nothing leaves the machine: drafts are kept in the browser's local storage.

## What it does

| Problem | How the workbench handles it |
|---|---|
| Reviewer forgets a source (service log, linked accounts, ATO…) | Every source is a section with **Clear / Concern / N/A**. Required ones block completion until filled. |
| Conditional checks get skipped | Counterparty review becomes required when Money movement is **Concern**; Linked account review becomes required when Linked accounts is **Concern**. |
| Notes and verdict contradict each other | Lifting restrictions with open concerns needs a mitigation rationale; Part ways with no concern is blocked; RFI needs the list of requested docs; open ATO/document concerns on a Lift raise warnings. |
| Something is mentioned but not followed up | Keyword cross-check: e.g. "new device" written in the Service log while ATO is Clear → warning. |
| Slow, inconsistent writing (AHT) | Quick-pick phrases per section, handle-time timer against a target, `Alt+1…9` / `Alt+0` jumps, `Ctrl+Enter` to complete, and a standard formatted note generated for copy-paste into the case tool. |
| Onboarding vs restriction reviews | Case-type switch changes required sources and verdict options (Approve / Decline / RFI). |

Blockers (red) must be fixed. Warnings (amber) must each be acknowledged, and the
acknowledgements are written into the final note, which helps QA see the reviewer
considered them.

## Customising (team lead)

Everything team-specific lives in the **CONFIGURATION** block at the top of the
`<script>` in `app/annotation-workbench.html`:

- `SECTIONS` – sources, where-to-look hints, quick-pick phrases, which case types require them, `requiredIf` conditions.
- `DECISIONS` – verdict options per case type.
- `KEYWORDS` – words that should force a second look at a source.
- `TARGET_AHT_MIN`, `MIN_NOTE_CHARS`.

Add your SOP's rules to `evaluate()` in the same file (each rule is a few lines).

## Rolling it out at work

1. **Pilot as-is**: share the HTML file on SharePoint/Teams; reviewers open it in Edge.
2. **Power Apps version** (if IT prefers Microsoft 365): see
   [`powerapps/BUILD-GUIDE.md`](powerapps/BUILD-GUIDE.md). It has the same sources and rules,
   saves every completed case to a SharePoint list, and records handle time and which checks
   were missed at first try. All formulas are in `powerapps/formulas/`, and
   `powerapps/create-sharepoint-list.ps1` creates the list.
3. **Word alternative**: a .dotm template with content controls per section and a
   VBA macro on save that checks for empty controls – works, but it is the weakest
   option (macros are often blocked, no live checking).

Do not paste customer PII into tools not approved by your company's data policy.
