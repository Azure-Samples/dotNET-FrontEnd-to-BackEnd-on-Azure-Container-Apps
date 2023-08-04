targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Specifies if the store app exists')
param storeAppExists bool = false

@description('Specifies if the inventory app exists')
param inventoryAppExists bool = false

@description('Specifies if the products app exists')
param productsAppExists bool = false

var tags = { 'azd-env-name': environmentName }
var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: environmentName
  location: location
  tags: tags
}

// Container apps host (including container registry)
module containerApps 'core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: resourceGroup
  params: {
    name: 'app'
    containerAppsEnvironmentName: '${abbrs.appManagedEnvironments}${resourceToken}'
    containerRegistryName: '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
  }
}

// Monitor application with Azure Monitor
module monitoring 'core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: resourceGroup
  params: {
    location: location
    tags: tags
    logAnalyticsName: '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: '${abbrs.portalDashboards}${resourceToken}'
  }
}

// identities
module storeIdentity 'core/security/user-assigned-identity.bicep' = {
  scope: resourceGroup
  name: 'storeIdentity'
  params: {
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}store-${resourceToken}'
    location: location
  }
}
module inventoryIdentity 'core/security/user-assigned-identity.bicep' = {
  scope: resourceGroup
  name: 'inventoryIdentity'
  params: {
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}inventory-${resourceToken}'
    location: location
  }
}
module productsIdentity 'core/security/user-assigned-identity.bicep' = {
  scope: resourceGroup
  name: 'productsIdentity'
  params: {
    identityName: '${abbrs.managedIdentityUserAssignedIdentities}products-${resourceToken}'
    location: location
  }
}

// store front-end
module store 'app/store.bicep' = {
  name: 'store'
  scope: resourceGroup
  params: {
    name: 'store'
    location: location
    tags: tags
    exists: storeAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    identityName: storeIdentity.outputs.identityName
    aiConnectionString: monitoring.outputs.applicationInsightsConnectionString
    inventoryServiceName: inventory.outputs.SERVICE_INVENTORY_NAME
    productsServiceName: products.outputs.SERVICE_PRODUCTS_NAME
  }
}

// inventory api
module inventory 'app/inventory.bicep' = {
  name: 'inventory'
  scope: resourceGroup
  params: {
    name: 'inventory'
    location: location
    tags: tags
    exists: inventoryAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    identityName: inventoryIdentity.outputs.identityName
    aiConnectionString: monitoring.outputs.applicationInsightsConnectionString
  }
}

// products api
module products 'app/products.bicep' = {
  name: 'products'
  scope: resourceGroup
  params: {
    name: 'products'
    location: location
    tags: tags
    exists: productsAppExists
    containerAppsEnvironmentName: containerApps.outputs.environmentName
    containerRegistryName: containerApps.outputs.registryName
    identityName: productsIdentity.outputs.identityName
    aiConnectionString: monitoring.outputs.applicationInsightsConnectionString
  }
}

output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName
output ACA_ENVIRONMENT_NAME string = containerApps.outputs.environmentName
