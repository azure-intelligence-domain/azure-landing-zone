// A user-assigned managed identity that one GitHub workflow can log in as,
// via OpenID Connect. Reused for every building block's deploy identity.

param name string
param location string
param tags object

@description('GitHub OIDC subject, e.g. repo:<org>@<orgId>/<repo>@<repoId>:environment:<env>.')
param subject string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

resource github 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: identity
  name: 'github'
  properties: {
    issuer: 'https://token.actions.githubusercontent.com'
    subject: subject
    audiences: ['api://AzureADTokenExchange']
  }
}

output principalId string = identity.properties.principalId
output clientId string = identity.properties.clientId
