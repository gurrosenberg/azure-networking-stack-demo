param location string
param namePrefix string
param tags object
param workspaceId string
param storageId string
@secure()
param sshPublicKey string
param deployPremiumNetworkFeatures bool

var hubAddress = '10.10.0.0/16'
var spokeAddress = '10.20.0.0/16'
var vmSize = 'Standard_B1s'

resource hubNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${namePrefix}-hub-nsg'
  location: location
  tags: tags
  properties: { securityRules: [] }
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${namePrefix}-hub-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [hubAddress] }
    subnets: [
      { name: 'AzureFirewallSubnet', properties: { addressPrefix: '10.10.0.0/26' } }
      { name: 'AzureBastionSubnet', properties: { addressPrefix: '10.10.0.64/26' } }
      { name: 'shared-services', properties: { addressPrefix: '10.10.1.0/24', networkSecurityGroup: { id: hubNsg.id } } }
    ]
  }
}

resource appNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${namePrefix}-app-nsg'
  location: location
  tags: tags
  properties: {
    securityRules: [
      { name: 'AllowGatewayHttp', properties: { priority: 100, direction: 'Inbound', access: 'Allow', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '8080', sourceAddressPrefix: '10.20.1.0/24', destinationAddressPrefix: '*', sourceApplicationSecurityGroups: [], destinationApplicationSecurityGroups: [] } }
      { name: 'DenyAppToAppProbe', properties: { priority: 200, direction: 'Inbound', access: 'Deny', protocol: 'Tcp', sourcePortRange: '*', destinationPortRange: '9000', sourceAddressPrefix: '10.20.2.0/24', destinationAddressPrefix: '*', sourceApplicationSecurityGroups: [], destinationApplicationSecurityGroups: [] } }
    ]
  }
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${namePrefix}-spoke-vnet'
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [spokeAddress] }
    subnets: [
      { name: 'appGateway', properties: { addressPrefix: '10.20.1.0/24' } }
      { name: 'app', properties: { addressPrefix: '10.20.2.0/24', networkSecurityGroup: { id: appNsg.id } } }
      { name: 'privateEndpoints', properties: { addressPrefix: '10.20.3.0/24', privateEndpointNetworkPolicies: 'Disabled' } }
      { name: 'management', properties: { addressPrefix: '10.20.4.0/24' } }
    ]
  }
}

resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: hubVnet
  name: 'hub-to-spoke'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, remoteVirtualNetwork: { id: spokeVnet.id } }
}
resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-09-01' = {
  parent: spokeVnet
  name: 'spoke-to-hub'
  properties: { allowVirtualNetworkAccess: true, allowForwardedTraffic: true, remoteVirtualNetwork: { id: hubVnet.id } }
}

resource appRouteTable 'Microsoft.Network/routeTables@2023-09-01' = {
  name: '${namePrefix}-app-rt'
  location: location
  tags: tags
  properties: { disableBgpRoutePropagation: false, routes: [] }
}

resource clientPip 'Microsoft.Network/publicIPAddresses@2023-09-01' = if (deployPremiumNetworkFeatures) {
  name: '${namePrefix}-client-pip'
  location: location
  tags: tags
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource clientNic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${namePrefix}-client-nic'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [{ name: 'ipconfig1', properties: { privateIPAllocationMethod: 'Dynamic', subnet: { id: spokeVnet.properties.subnets[3].id }, publicIPAddress: deployPremiumNetworkFeatures ? { id: clientPip.id } : null } }]
  }
}

var cloudInit = '#cloud-config\npackage_update: true\npackages: [curl, dnsutils, python3]\nwrite_files:\n - path: /opt/demo/generate-traffic.sh\n   permissions: "0755"\n   content: |\n     #!/usr/bin/env bash\n     set -euxo pipefail\n     curl -sS http://127.0.0.1:8080/ || true\n     curl -sS "http://127.0.0.1:8080/?q=<script>alert(1)</script>" || true\n     curl -I https://www.microsoft.com || true\n     nc -vz -w 3 10.20.2.4 9000 || true\nruncmd:\n - python3 -m http.server 8080 --directory /var/www/html &'

resource clientVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: '${namePrefix}-client-vm'
  location: location
  tags: tags
  properties: {
    hardwareProfile: { vmSize: vmSize }
    osProfile: { computerName: 'demo-client-vm', adminUsername: 'azureuser', customData: base64(cloudInit), linuxConfiguration: { disablePasswordAuthentication: true, ssh: { publicKeys: [{ path: '/home/azureuser/.ssh/authorized_keys', keyData: sshPublicKey }] } } }
    storageProfile: { imageReference: { publisher: 'Canonical', offer: 'ubuntu-24_04-lts', sku: 'server', version: 'latest' }, osDisk: { createOption: 'FromImage', managedDisk: { storageAccountType: 'Standard_LRS' } } }
    networkProfile: { networkInterfaces: [{ id: clientNic.id }] }
  }
}

// The following observability destination is created now. Firewall, WAF, NAT Gateway,
// Bastion, VPN Gateway, Route Server, Virtual WAN and Front Door are deliberate opt-in
// modules for the live demo because they incur material hourly cost.
output applicationGatewayPublicIp string = deployPremiumNetworkFeatures ? clientPip.properties.ipAddress : 'Not deployed; set deployPremiumNetworkFeatures to true.'
output clientVmName string = clientVm.name
