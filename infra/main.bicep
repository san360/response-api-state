targetScope = 'subscription'

@description('Location for all resources')
param location string = 'swedencentral'

@description('Unique suffix to avoid naming collisions')
param uniqueSuffix string = uniqueString(subscription().id, location)

@description('Resource group name')
param resourceGroupName string = 'rg-response-api-stateless-test'

@description('Tags for all resources')
param tags object = {
  project: 'response-api-stateless-test'
  purpose: 'testing-response-api-state-across-foundry-instances'
  SecurityControl: 'Ignore'
}

// Create the resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy three Azure AI Services instances (each with a model deployment)
module foundry1 'modules/foundry-instance.bicep' = {
  scope: rg
  name: 'foundry-instance-1'
  params: {
    name: 'fnd1-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '1' })
  }
}

module foundry2 'modules/foundry-instance.bicep' = {
  scope: rg
  name: 'foundry-instance-2'
  params: {
    name: 'fnd2-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '2' })
  }
}

module foundry3 'modules/foundry-instance.bicep' = {
  scope: rg
  name: 'foundry-instance-3'
  params: {
    name: 'fnd3-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '3' })
  }
}

// Deploy three Azure OpenAI instances (kind: OpenAI) with the same model deployments
module openai1 'modules/openai-instance.bicep' = {
  scope: rg
  name: 'openai-instance-1'
  params: {
    name: 'oai1-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: 'oai-1' })
  }
}

module openai2 'modules/openai-instance.bicep' = {
  scope: rg
  name: 'openai-instance-2'
  params: {
    name: 'oai2-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: 'oai-2' })
  }
}

module openai3 'modules/openai-instance.bicep' = {
  scope: rg
  name: 'openai-instance-3'
  params: {
    name: 'oai3-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: 'oai-3' })
  }
}

// Outputs — AI Services (Foundry) instances
output resourceGroupName string = rg.name

output instance1Endpoint string = foundry1.outputs.openaiEndpoint
output instance1AiServicesName string = foundry1.outputs.aiServicesName

output instance2Endpoint string = foundry2.outputs.openaiEndpoint
output instance2AiServicesName string = foundry2.outputs.aiServicesName

output instance3Endpoint string = foundry3.outputs.openaiEndpoint
output instance3AiServicesName string = foundry3.outputs.aiServicesName

// Outputs — Azure OpenAI instances
output openai1Endpoint string = openai1.outputs.openaiEndpoint
output openai1Name string = openai1.outputs.openaiName

output openai2Endpoint string = openai2.outputs.openaiEndpoint
output openai2Name string = openai2.outputs.openaiName

output openai3Endpoint string = openai3.outputs.openaiEndpoint
output openai3Name string = openai3.outputs.openaiName
