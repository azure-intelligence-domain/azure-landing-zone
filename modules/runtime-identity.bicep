// The runtime identity of a building block: what its Function or Logic App runs as, to call
// APIs through the gateway, publish events and read data. Separate from the deploy identity.

param name string
param location string
param tags object

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
output id string = identity.id
