// Creates an Azure AI Services instance with a model deployment.
// No Hub, Project, Storage, or Key Vault — just the bare Foundry resource
// needed to test the Response API across independent instances.

@description('Base name for this Foundry instance')
param name string

@description('Location for all resources')
param location string

@description('Model deployment name')
param deploymentName string = 'gpt-4-1-mini'

@description('Model name to deploy')
param modelName string = 'gpt-4.1-mini'

@description('Model version')
param modelVersion string = '2025-04-14'

@description('SKU name for deployment capacity')
param skuName string = 'GlobalStandard'

@description('Deployment capacity (tokens per minute in thousands)')
param deploymentCapacity int = 10

@description('Tags for the resources')
param tags object = {}

// ──────────────────────────────────────────────────────────────
// AI Services account (kind: AIServices — the Foundry resource)
// ──────────────────────────────────────────────────────────────
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: 'ais-${name}'
  location: location
  tags: union(tags, { SecurityControl: 'Ignore' })
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'ais-${name}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

// ──────────────────────────────────────────────────────────────
// Model deployment on the AI Services account
// ──────────────────────────────────────────────────────────────
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: aiServices
  name: deploymentName
  sku: {
    name: skuName
    capacity: deploymentCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────────────────────
@description('The OpenAI-specific endpoint URL (used for Response API base_url)')
output openaiEndpoint string = 'https://${aiServices.properties.customSubDomainName}.openai.azure.com/'

@description('The AI Services endpoint URL (general cognitive services endpoint)')
output aiServicesEndpoint string = aiServices.properties.endpoint

@description('The AI Services resource name (used to retrieve API keys)')
output aiServicesName string = aiServices.name

@description('The custom subdomain name of the AI Services account')
output customSubDomainName string = aiServices.properties.customSubDomainName
