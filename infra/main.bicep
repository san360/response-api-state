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

@description('Set to true if redeploying after a failed run left soft-deleted Key Vaults')
param recoverKeyVault bool = false

// Create the resource group
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Deploy three Azure AI Foundry instances (each with AI Services + Hub + Project)
module foundry1 'modules/foundry-instance.bicep' = {
  scope: rg
  name: 'foundry-instance-1'
  params: {
    name: 'fnd1-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '1' })
    recoverKeyVault: recoverKeyVault
  }
}

module foundry2 'modules/foundry-instance.bicep' = {
  scope: rg
  name: 'foundry-instance-2'
  params: {
    name: 'fnd2-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '2' })
    recoverKeyVault: recoverKeyVault
  }
}

module foundry3 'modules/foundry-instance.bicep' = {
  scope: rg
  name: 'foundry-instance-3'
  params: {
    name: 'fnd3-${uniqueSuffix}'
    location: location
    tags: union(tags, { instance: '3' })
    recoverKeyVault: recoverKeyVault
  }
}

// Outputs
output resourceGroupName string = rg.name

output instance1Endpoint string = foundry1.outputs.openaiEndpoint
output instance1AiServicesName string = foundry1.outputs.aiServicesName
output instance1HubName string = foundry1.outputs.hubName
output instance1ProjectName string = foundry1.outputs.projectName

output instance2Endpoint string = foundry2.outputs.openaiEndpoint
output instance2AiServicesName string = foundry2.outputs.aiServicesName
output instance2HubName string = foundry2.outputs.hubName
output instance2ProjectName string = foundry2.outputs.projectName

output instance3Endpoint string = foundry3.outputs.openaiEndpoint
output instance3AiServicesName string = foundry3.outputs.aiServicesName
output instance3HubName string = foundry3.outputs.hubName
output instance3ProjectName string = foundry3.outputs.projectName
