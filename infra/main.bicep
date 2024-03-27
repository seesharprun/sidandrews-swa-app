targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention.')
param environmentName string

@minLength(1)
@description('Primary location for all resources.')
param location string

// Optional parameters
param sqlServerName string = ''
param sqlDatabaseName string = ''
param functionAppName string = ''
param staticWebAppName string = ''

// *ServiceName is used as value for the tag (azd-service-name) azd uses to identify deployment host
param webServiceName string = 'web'
param apiServiceName string = 'api'

var abbreviations = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = {
  'azd-env-name': environmentName
  repo: 'https://github.com/azure-samples/dab-azure-sql-quickstart'
}

// Define resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: environmentName
  location: location
  tags: tags
}

module db 'app/db.bicep' = {
  name: 'db'
  scope: resourceGroup
  params: {
    serverName: !empty(sqlServerName) ? sqlServerName : '${abbreviations.sqlServers}-${resourceToken}'
    databaseName: !empty(sqlDatabaseName) ? sqlDatabaseName : '${abbreviations.sqlDatabases}-${resourceToken}'
    location: location
    tags: tags
  }
}

module api 'app/api.bicep' = {
  name: 'api'
  scope: resourceGroup
  params: {
    appName: !empty(functionAppName) ? functionAppName : '${abbreviations.functionApps}-${resourceToken}'
    location: location
    tags: tags
    serviceTag: apiServiceName
  }
}

module web 'app/web.bicep' = {
  name: 'web'
  scope: resourceGroup
  params: {
    appName: !empty(staticWebAppName) ? staticWebAppName : '${abbreviations.staticWebApps}-${resourceToken}'
    location: location
    tags: tags
    serviceTag: webServiceName
  }
}

// Application outputs
output AZURE_STATIC_WEB_APP_ENDPOINT string = web.outputs.endpoint
