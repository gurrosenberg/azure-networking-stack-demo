[CmdletBinding(SupportsShouldProcess)]
param(
  [string] $SubscriptionId = '23d7b6f5-d09b-44e0-9b30-2c4de3ce5dab',
  [string] $ResourceGroupName = 'rg-azure-networking-stack-demo'
)

$ErrorActionPreference = 'Stop'
az account set --subscription $SubscriptionId
$activeSubscription = az account show --query id -o tsv
if ($activeSubscription -ne $SubscriptionId) { throw 'Refusing deletion: unexpected active subscription.' }

$tags = az group show --name $ResourceGroupName --query tags -o json | ConvertFrom-Json
if ($tags.workload -ne 'azure-networking-stack-demo' -or $tags.lifecycle -ne 'disposable') {
  throw 'Refusing deletion: target is not the expected disposable demo resource group.'
}

$confirmation = Read-Host "Type DELETE $ResourceGroupName to permanently remove its Azure resources"
if ($confirmation -cne "DELETE $ResourceGroupName") { throw 'Deletion cancelled.' }
az group delete --name $ResourceGroupName --yes --no-wait
Write-Host "Deletion started for $ResourceGroupName in subscription $SubscriptionId."
