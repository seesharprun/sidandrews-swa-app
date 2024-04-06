metadata description = 'Create API application resources.'

param planName string
param funcName string

param serviceTag string
param location string = resourceGroup().location
param tags object = {}

@description('The name of the storage account to use for the function app.')
param storageAccountName string

@description('Allowed origins for client-side CORS request on the site.')
param allowedCorsOrigins string[] = []

type managedIdentity = {
  resourceId: string
  clientId: string
}

@description('Unique identifier for user-assigned managed identity.')
param userAssignedManagedIdentity managedIdentity

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

module plan '../core/host/app-service/plan.bicep' = {
  name: 'function-app-plan'
  params: {
    name: planName
    location: location
    tags: tags
    kind: 'linux'
    sku: 'B1'
    tier: 'Basic'
  }
}

module systemAssignedManagedIdentityAssignment '../core/security/role/assignment.bicep' = {
  name: 'storage-role-assignment-blob-data-owner'
  params: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner built-in role
    )
    principalId: func.outputs.managedIdentityPrincipalId // Principal to assign role
    principalType: 'ServicePrincipal' // Application user
  }
}

module func '../core/host/app-service/site.bicep' = {
  name: 'function-app-site'
  params: {
    name: funcName
    location: location
    tags: union(
      tags,
      {
        'azd-service-name': serviceTag
      }
    )
    enableSystemAssignedManagedIdentity: true
    userAssignedManagedIdentityIds: [
      userAssignedManagedIdentity.resourceId
    ]
    alwaysOn: true
    parentPlanName: plan.outputs.name
    allowedCorsOrigins: allowedCorsOrigins
    kind: 'functionapp,linux'
    runtimeName: 'dotnet-isolated'
    runtimeVersion: '8.0'
    initialAppSettings: [
      {
        name: 'AzureWebJobsStorage__accountName'
        value: storageAccount.name
      }
    ]
  }
}

module config '../core/host/app-service/config-appsettings.bicep' = {
  name: 'function-app-config-app-settings'
  params: {
    parentSiteName: func.outputs.name
    appSettings: {
      SCM_DO_BUILD_DURING_DEPLOYMENT: false
      ENABLE_ORYX_BUILD: true
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet-isolated'
    }
  }
}

output name string = func.outputs.name
output endpoint string = func.outputs.endpoint
output managedIdentityPrincipalId string = func.outputs.managedIdentityPrincipalId
output managedIdentityTenantId string = func.outputs.managedIdentityTenantId
