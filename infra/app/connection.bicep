metadata description = 'Create web application connection credentials.'

@description('The name of the function app to configure.')
param parentFunctionAppName string

@description('The endpoint for the Azure SQL server.')
param sqlServerEndpoint string

@description('The name of the Azure SQL database.')
param sqlDatabaseName string

var connectionString = 'Server=${sqlServerEndpoint};Authentication=Active Directory Managed Identity;Encrypt=True;Database=${sqlDatabaseName}'

resource functionApp 'Microsoft.Web/sites@2022-09-01' existing = {
  name: parentFunctionAppName
}

module config '../core/host/app-service/config-connectionstrings.bicep' = {
  name: 'function-app-config-connection-strings'
  params: {
    parentSiteName: functionApp.name
    conenctionStrings: {
      SqlConnectionString: {
        value: connectionString
        type: 'SQLAzure'
      }
    }
  }
}
