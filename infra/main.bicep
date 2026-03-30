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
}

// Create the resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy three Azure OpenAI (Foundry) instances
module openai1 'modules/openai.bicep' = {
  scope: rg
  name: 'openai-instance-1'
  params: {
    name: 'oai-stateless-1-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '1' })
  }
}

module openai2 'modules/openai.bicep' = {
  scope: rg
  name: 'openai-instance-2'
  params: {
    name: 'oai-stateless-2-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '2' })
  }
}

module openai3 'modules/openai.bicep' = {
  scope: rg
  name: 'openai-instance-3'
  params: {
    name: 'oai-stateless-3-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '3' })
  }
}

// Outputs
output resourceGroupName string = rg.name

output instance1Endpoint string = openai1.outputs.endpoint
output instance1Name string = openai1.outputs.resourceName

output instance2Endpoint string = openai2.outputs.endpoint
output instance2Name string = openai2.outputs.resourceName

output instance3Endpoint string = openai3.outputs.endpoint
output instance3Name string = openai3.outputs.resourceName
