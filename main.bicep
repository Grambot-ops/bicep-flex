param aciName string = 'r0984339aci'
param acrName string = 'r0984339acr'
param location string = 'Sweden Central'

// Create VNet with public and private subnets
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'r0984339vnet'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [
      {
        name: 'public-subnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgPublic.id
          }
        }
      }
      {
        name: 'private-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgPrivate.id
          }
          // Add delegation for Azure Container Instances
          delegations: [
            {
              name: 'delegation-aci'
              properties: {
                serviceName: 'Microsoft.ContainerInstance/containerGroups'
              }
            }
          ]
        }
      }
    ]
  }
}

// Create NSGs
resource nsgPublic 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'r0984339nsg-public'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 100
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource nsgPrivate 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'r0984339nsg-private'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-From-Public-Subnet'
        properties: {
          priority: 100
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '10.0.0.0/24'
          destinationAddressPrefix: '*'
          access: 'Allow'
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Public IP for Load Balancer
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'r0984339-lb-publicip'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

// Deploy ACI (private IP only)
// Update your ACI resource to include log analytics
resource aci 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: aciName
  location: location
  properties: {
    containers: [
      {
        name: 'crud-app'
        properties: {
          image: '${acrName}.azurecr.io/crud-app:latest'
          ports: [ { port: 80 } ]
          resources: { 
            requests: { 
              cpu: 1  // Reduced from 1 to save resources
              memoryInGB: 2 // Reduced from 2 to save resources
            } 
          }
          environmentVariables: [ { name: 'ENVIRONMENT', value: 'production' } ]
        }
      }
    ]
    imageRegistryCredentials: [
      {
        server: '${acrName}.azurecr.io'
        username: acr.listCredentials().username
        password: acr.listCredentials().passwords[0].value
      }
    ]
    ipAddress: { type: 'Private', ports: [ { protocol: 'TCP', port: 80 } ] }
    subnetIds: [ { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'private-subnet') } ]
    osType: 'Linux'
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalyticsWorkspace.properties.customerId
        workspaceKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// Reference to your ACR
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// Store ACI private IP as a variable
var aciPrivateIP = aci.properties.ipAddress.ip

// Load Balancer
resource loadBalancer 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: 'r0984339-lb'
  location: location
  sku: { name: 'Standard' }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'frontend'
        properties: {
          publicIPAddress: { id: publicIP.id }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    loadBalancingRules: [
      {
        name: 'http-rule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'r0984339-lb', 'frontend')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'r0984339-lb', 'backendPool')
          }
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'r0984339-lb', 'http-probe')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
        }
      }
    ]
    probes: [
      {
        name: 'http-probe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 15
          numberOfProbes: 2
        }
      }
    ]
  }
}


// Backend pool configuration - separate resource to avoid circular reference
resource backendPoolConfig 'Microsoft.Network/loadBalancers/backendAddressPools@2023-04-01' = {
  parent: loadBalancer
  name: 'backendPool'
  properties: {
    loadBalancerBackendAddresses: [
      {
        name: 'aci-backend'
        properties: {
          ipAddress: aciPrivateIP
          virtualNetwork: {
            id: vnet.id // Reference to the virtual network
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'private-subnet') // Reference to the private subnet
          }
        }
      }
    ]
  }
}

// Log Analytics workspace for container logs
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'r0984339-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}


output aciPrivateIP string = aciPrivateIP
