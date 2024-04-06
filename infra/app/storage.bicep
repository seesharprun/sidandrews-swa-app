metadata description = 'Create storage resources.'

param storName string

param location string = resourceGroup().location
param tags object = {}

module storage '../core/storage/account.bicep' = {
  name: 'function-app-storage'
  params: {
    name: storName
    location: location
    tags: tags
    httpsOnly: true
    publicBlobAccess: false
    allowSharedKeyAccess: false
    defaultToEntraAuthentication: true
    allowPublicNetworkAccess: true
  }
}

output name string = storage.outputs.name
