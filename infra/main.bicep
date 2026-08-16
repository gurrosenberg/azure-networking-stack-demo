targetScope = 'resourceGroup'

@description('Azure region for the lab.')
param location string = resourceGroup().location
@description('Short DNS-safe prefix for all resource names.')
param namePrefix string = 'aznetdemo'
@secure()
@description('SSH public key for the two demo virtual machines.')
param sshPublicKey string
@description('Set true only for an active demo; this enables billed network appliances.')
param deployPremiumNetworkFeatures bool = false

var commonTags = {
  workload: 'azure-networking-stack-demo'
  managedBy: 'bicep'
  lifecycle: 'disposable'
}

resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${namePrefix}-law'
  location: location
  tags: commonTags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

resource flowStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: toLower(replace('${namePrefix}flows${uniqueString(resourceGroup().id)}', '-', ''))
  location: location
  tags: commonTags
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    namePrefix: namePrefix
    tags: commonTags
    workspaceId: logWorkspace.id
    storageId: flowStorage.id
    sshPublicKey: sshPublicKey
    deployPremiumNetworkFeatures: deployPremiumNetworkFeatures
  }
}

output workspaceName string = logWorkspace.name
output applicationGatewayPublicIp string = network.outputs.applicationGatewayPublicIp
output clientVmName string = network.outputs.clientVmName
