@description('Name of the Azure OpenAI resource')
param name string

@description('Location for the resource')
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

@description('Tags for the resource')
param tags object = {}

resource openai 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: name
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  tags: tags
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
  }
}

resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openai
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

@description('The endpoint URL of the OpenAI resource')
output endpoint string = openai.properties.endpoint

@description('The resource name')
output resourceName string = openai.name

@description('The resource ID')
output resourceId string = openai.id
