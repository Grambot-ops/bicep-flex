param acrName string = 'DeployToAzure'
param location string = resourceGroup().location


resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name:acrName
  location: location
  sku:{
    name: 'Basic'
  }
  properties:{
    adminUserEnabled: true
  }

}
