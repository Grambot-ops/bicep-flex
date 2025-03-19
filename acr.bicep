// Create Azure Container Repository
param acrName string = 'r0984339acr'
param location string = 'Sweden Central'
param tokenName string = 'acipull'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Create a scope map for pull-only access
resource pullScopeMap 'Microsoft.ContainerRegistry/registries/scopeMaps@2023-07-01' = {
  parent: acr
  name: 'pullScope'
  properties: {
    actions: [
      'repositories/*/content/read'
    ]
  }
}

// Create token with pull-only access
resource acrToken 'Microsoft.ContainerRegistry/registries/tokens@2023-07-01' = {
  parent: acr
  name: tokenName
  properties: {
    scopeMapId: pullScopeMap.id
    status: 'enabled'
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
