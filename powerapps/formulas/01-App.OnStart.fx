// ================================================================
// App.OnStart  —  paste into App > OnStart
// Everything team-specific is in the CONFIGURATION block.
// ================================================================

// ===== CONFIGURATION (team lead edits here) =====================
Set(varTargetAHTMin, 20);     // target handle time in minutes
Set(varMinNoteChars, 12);     // shortest acceptable note per source

// Review sources.
//   Required   : case types where the source is mandatory ("review", "onboarding")
//   RequiredIf : Id of another source; this one becomes mandatory when that one is "Concern"
//   Chips      : quick-pick phrases separated by |
//                prefix "!" = a concern phrase (sets status to Concern if empty)
//                prefix "~" = neutral phrase (does not set status)
//                no prefix  = clear phrase (sets status to Clear if empty)
ClearCollect(colSources,
  {Order:1, Id:"profile", Title:"Account profile",
   Where:"Profile page: business type, account age, ownership, contact & bank details, restriction reason.",
   Required:"review,onboarding", RequiredIf:"",
   Chips:"Profile details consistent with business type|!Account age < 90 days|!Recent bank account change|!Business category mismatch|~Restriction reason: "},
  {Order:2, Id:"prior", Title:"Previous teammate notes",
   Where:"Case history: earlier annotations, open RFIs, past verdicts and escalations.",
   Required:"review,onboarding", RequiredIf:"",
   Chips:"No prior reviews|Prior review cleared with no concerns|!Pending RFI from previous review|!Previously escalated|~Prior verdict: "},
  {Order:3, Id:"documents", Title:"Documents provided",
   Where:"Document store: ID, proof of address, business registration, bank statements, invoices.",
   Required:"review,onboarding", RequiredIf:"",
   Chips:"All requested documents received and valid|ID verified|Proof of address verified|!Document appears altered|!Document name mismatch with account|!Documents outstanding: "},
  {Order:4, Id:"ato", Title:"ATO indicators",
   Where:"Login & security history: password/email/phone changes, new devices, IP/geo, 2FA resets.",
   Required:"review", RequiredIf:"",
   Chips:"No ATO indicators|!Password reset followed by bank change|!Login from new device/country|!Email or phone changed recently|!2FA reset"},
  {Order:5, Id:"linked", Title:"Linked account checks",
   Where:"Linking tool: shared device, IP, bank, address, phone, email with other accounts.",
   Required:"review,onboarding", RequiredIf:"",
   Chips:"No linked accounts|Linked accounts found, all in good standing|!Linked to restricted/closed account|!Shared bank account with other seller|!Shared device/IP"},
  {Order:6, Id:"service", Title:"Service log",
   Where:"Contacts: calls, chats, emails with the seller and what they claimed.",
   Required:"review,onboarding", RequiredIf:"",
   Chips:"No contacts on record|~Seller contacted about restriction|Seller explanation consistent with evidence|!Seller explanation inconsistent with evidence|!Threat of chargeback/legal"},
  {Order:7, Id:"money", Title:"Money movement & cash advancing",
   Where:"Transactions: inflow vs outflow, rapid withdrawals, round amounts, refunds, cash-advance patterns.",
   Required:"review", RequiredIf:"",
   Chips:"Money movement in line with business|!Rapid in-and-out (pass-through) funds|!Round-amount transactions|!Possible cash advancing: self-funded card payments|!Refunds to different instrument"},
  {Order:8, Id:"counterparty", Title:"Counterparty review",
   Where:"Buyers/payers: repeat payers, related parties, disputes and chargebacks.",
   Required:"", RequiredIf:"money",
   Chips:"Counterparties look genuine|!Same payer repeatedly|!Counterparty linked to seller|!High dispute/chargeback rate"},
  {Order:9, Id:"linkedReview", Title:"Linked account review",
   Where:"Review each linked account flagged above: status, restriction reasons, verdicts.",
   Required:"", RequiredIf:"linked",
   Chips:"Linked account review shows no risk|!Linked account restricted for fraud|!Linked account closed by us"}
);

// Verdict options per case type. Clears = releases/approves the account, Exits = ends the relationship.
ClearCollect(colDecisions,
  {CaseType:"review",     Key:"lift",     Label:"Lift restrictions",       Clears:true,  Exits:false},
  {CaseType:"review",     Key:"partways", Label:"Part ways",               Clears:false, Exits:true},
  {CaseType:"review",     Key:"rfi",      Label:"Request additional info", Clears:false, Exits:false},
  {CaseType:"onboarding", Key:"approve",  Label:"Approve onboarding",      Clears:true,  Exits:false},
  {CaseType:"onboarding", Key:"decline",  Label:"Decline",                 Clears:false, Exits:true},
  {CaseType:"onboarding", Key:"rfi",      Label:"Request additional info", Clears:false, Exits:false}
);

// If any of these words appear in OTHER sections' notes (or the rationale),
// the named source should be marked Concern. Words separated by |
ClearCollect(colKeywords,
  {Sec:"ato",       Words:"password reset|password change|new device|email change|email changed|phone change|phone changed|2fa|unrecognised login|unrecognized login|takeover|hacked"},
  {Sec:"money",     Words:"cash advance|cash advancing|pass-through|round amount|rapid withdrawal|self-funded|structuring"},
  {Sec:"linked",    Words:"linked to|shared device|shared bank|same ip|same device|related account"},
  {Sec:"documents", Words:"altered|forged|fake document|edited document|expired id|pending document|outstanding document"}
);
// ===== END CONFIGURATION ========================================

// Colours (match the HTML version)
Set(clrAccent,  RGBA(13,104,112,1));
Set(clrBg,      RGBA(238,242,243,1));
Set(clrLine,    RGBA(214,222,225,1));
Set(clrMuted,   RGBA(86,103,110,1));
Set(clrOk,      RGBA(44,122,75,1));   Set(clrOkSoft,   RGBA(225,241,231,1));
Set(clrWarn,    RGBA(154,92,0,1));    Set(clrWarnSoft, RGBA(251,239,217,1));
Set(clrBad,     RGBA(176,39,31,1));   Set(clrBadSoft,  RGBA(249,225,223,1));

// Start an empty case (same as btnNewCase.OnSelect)
Set(varReviewer, User().FullName);
Set(varCaseType, "review");
ClearCollect(colReview, AddColumns(colSources, Status, "", Notes, "", Force, false));
Set(varCaseId, ""); Set(varDecision, ""); Set(varRationale, ""); Set(varRFI, "");
Set(varPopup, ""); Set(varJump, ""); Set(varChecked, false); Set(varFirstMissed, "");
Set(varStart, Now()); Set(varNow, Now());
