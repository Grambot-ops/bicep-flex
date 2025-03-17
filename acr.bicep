//Creates Azure Container Registry 
param acrName string = 'r0984339acr'
param location string = 'Sweden Central'


resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name:acrName
  location: location
  sku:{
    name: 'Basic'
  }
  properties:{adminUserEnabled:true}
}


