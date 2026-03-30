// Creates a complete Azure AI Foundry instance:
//   - Storage Account
//   - Key Vault
//   - AI Services account (with model deployment)
//   - AI Foundry Hub
//   - AI Foundry Project
//   - AI Services connection on the Hub

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
// Storage Account (required by Foundry Hub)
// ──────────────────────────────────────────────────────────────
var storageNameCleaned = replace('st${name}', '-', '')

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: length(storageNameCleaned) > 24 ? substring(storageNameCleaned, 0, 24) : storageNameCleaned
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

// ──────────────────────────────────────────────────────────────
// Key Vault (required by Foundry Hub)
// ──────────────────────────────────────────────────────────────
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${name}'
  location: location
  tags: tags
  properties: {
    createMode: 'default'
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
  }
}

// ──────────────────────────────────────────────────────────────
// AI Services account (kind: AIServices — the Foundry resource)
// ──────────────────────────────────────────────────────────────
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: 'ais-${name}'
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: 'ais-${name}'
    publicNetworkAccess: 'Enabled'
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
// Azure AI Foundry Hub
// ──────────────────────────────────────────────────────────────
resource aiHub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: 'aih-${name}'
  location: location
  tags: tags
  kind: 'hub'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'AI Foundry Hub — ${name}'
    description: 'Foundry hub for Response API stateless cross-instance testing'
    keyVault: keyVault.id
    storageAccount: storageAccount.id
  }

  // Connection from the Hub to the AI Services account
  resource aiServicesConnection 'connections@2024-10-01' = {
    name: '${name}-connection-AIServices'
    properties: {
      category: 'AzureOpenAI'
      target: aiServices.properties.endpoint
      authType: 'ApiKey'
      isSharedToAll: true
      credentials: {
        key: aiServices.listKeys().key1
      }
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiServices.id
      }
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Azure AI Foundry Project
// ──────────────────────────────────────────────────────────────
resource aiProject 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: 'aip-${name}'
  location: location
  tags: tags
  kind: 'project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: 'Stateless Test Project — ${name}'
    hubResourceId: aiHub.id
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

@description('The Foundry Hub name')
output hubName string = aiHub.name

@description('The Foundry Project name')
output projectName string = aiProject.name
