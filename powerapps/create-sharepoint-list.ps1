<#
  Creates the "RiskAnnotations" SharePoint list used by the Power Apps workbench.

  Needs PnP.PowerShell (Install-Module PnP.PowerShell -Scope CurrentUser) and an
  Entra ID app registration your IT team has approved for PnP (ClientId).

  Usage:
    ./create-sharepoint-list.ps1 -SiteUrl https://contoso.sharepoint.com/sites/RiskOps -ClientId <app-id>

  You can also create the same columns by hand: see BUILD-GUIDE.md, step 1.
#>
param(
  [Parameter(Mandatory)] [string] $SiteUrl,
  [Parameter(Mandatory)] [string] $ClientId,
  [string] $ListName = "RiskAnnotations"
)

Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Interactive

if (-not (Get-PnPList -Identity $ListName -ErrorAction SilentlyContinue)) {
  New-PnPList -Title $ListName -Template GenericList -OnQuickLaunch | Out-Null
}
Set-PnPField -List $ListName -Identity "Title" -Values @{ Title = "Case ID" } | Out-Null

$text = @("Reviewer","CaseType","Decision","MissedAtFirstCheck")
$note = @("Rationale","VerdictDetail","WarningsAcknowledged","FinalNote")
$sources = @("Profile","PriorNotes","Documents","ATO","LinkedReview","ServiceLog","MoneyMovement","Counterparty")
foreach ($s in $sources) { $text += "${s}Status"; $note += "${s}Notes" }

$existing = (Get-PnPField -List $ListName).InternalName
function Add-Col($name, $type) {
  if ($existing -notcontains $name) {
    Add-PnPField -List $ListName -DisplayName $name -InternalName $name -Type $type -AddToDefaultView | Out-Null
    Write-Host "Added $name ($type)"
  }
}
foreach ($c in $text) { Add-Col $c "Text" }
foreach ($c in $note) { Add-Col $c "Note" }
Add-Col "HandleTimeMin" "Number"
Add-Col "CompletedOn" "DateTime"

Write-Host "Done. List '$ListName' is ready at $SiteUrl"
