// Gives one principal the Contributor role on the resource group this module is deployed to.

param principalId string

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource contributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, contributorRoleId)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    description: 'Building block deploy identity: Contributor on its own resource group only.'
  }
}
