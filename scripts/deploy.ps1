[CmdletBinding()]
param(
  [Parameter(Mandatory)] [string] $SshPublicKey,
  [switch] $DeployPremiumNetworkFeatures,
  [string] $SubscriptionId = '23d7b6f5-d09b-44e0-9b30-2c4de3ce5dab',
  [string] $ResourceGroupName = 'rg-azure-networking-stack-demo',
  [string] $Location = 'westeurope'
)

$ErrorActionPreference = 'Stop'
az account set --subscription $SubscriptionId
$activeSubscription = az account show --query id -o tsv
if ($activeSubscription -ne $SubscriptionId) { throw "Active subscription does not match the demo subscription." }

Write-Host "Target subscription: $activeSubscription"
Write-Host "Target resource group: $ResourceGroupName"
$confirmation = Read-Host "Type DEPLOY to create/update only this demo resource group"
if ($confirmation -cne 'DEPLOY') { throw 'Deployment cancelled.' }

az group create --name $ResourceGroupName --location $Location --tags workload=azure-networking-stack-demo lifecycle=disposable managedBy=bicep | Out-Null
$root = Split-Path -Parent $PSScriptRoot
az deployment group create --resource-group $ResourceGroupName --template-file "$root/infra/main.bicep" --parameters "$root/infra/main.parameters.json" sshPublicKey="$SshPublicKey" deployPremiumNetworkFeatures=$DeployPremiumNetworkFeatures
