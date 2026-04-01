// Creates an Azure OpenAI instance (kind: OpenAI) with model deployments.
// This is distinct from the AIServices (Foundry) instances — it uses the
// pure OpenAI resource kind to test whether Response API state is portable
// across Azure OpenAI instances as well.

@description('Base name for this OpenAI instance')
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
// Azure OpenAI account (kind: OpenAI)
// ──────────────────────────────────────────────────────────────
resource openaiAccount 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: 'oai-${name}'
  location: location
  tags: union(tags, { SecurityControl: 'Ignore' })
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'oai-${name}'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

// ──────────────────────────────────────────────────────────────
// Model deployment (gpt-4.1-mini)
// ──────────────────────────────────────────────────────────────
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openaiAccount
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
// Second model deployment (gpt-5-mini)
// ──────────────────────────────────────────────────────────────
resource modelDeployment2 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openaiAccount
  name: 'gpt-5-mini'
  dependsOn: [modelDeployment]
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-5-mini'
      version: '2025-08-07'
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Outputs
// ──────────────────────────────────────────────────────────────
@description('The OpenAI-specific endpoint URL (used for Response API base_url)')
output openaiEndpoint string = 'https://${openaiAccount.properties.customSubDomainName}.openai.azure.com/'

@description('The general endpoint URL')
output endpoint string = openaiAccount.properties.endpoint

@description('The OpenAI resource name (used to retrieve API keys)')
output openaiName string = openaiAccount.name

@description('The custom subdomain name of the OpenAI account')
output customSubDomainName string = openaiAccount.properties.customSubDomainName
