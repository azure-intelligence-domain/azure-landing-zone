// The runtime identity of a building block: what its Function or Logic App runs as, to call
// APIs through the gateway, publish events and read data. Separate from the deploy identity.

import { managedIdentityOperator } from 'roles.bicep'

param name string
param location string
param tags object

@description('The block\'s deploy identity: may attach this identity to the block\'s Function or Logic App.')
param deployPrincipalId string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

resource deployMayAttach 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identity.id, deployPrincipalId, managedIdentityOperator)
  scope: identity
  properties: {
    principalId: deployPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', managedIdentityOperator)
    description: 'The block\'s deploy identity attaches its runtime identity (ADR 0014).'
  }
}

output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
output id string = identity.id
