// A building block's rights on one of its own resource groups:
// Contributor, plus a role administrator that may grant data-plane roles only.

import { contributor, rbacAdministrator, dataRoles, onlyRoles } from 'roles.bicep'

param principalId string

resource contributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, contributor)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributor)
    description: 'Building block deploy identity: Contributor on its own resource group only.'
  }
}

resource dataRoleAdministrator 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, rbacAdministrator)
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacAdministrator)
    description: 'Building block deploy identity: may grant data-plane roles only, within this resource group.'
    conditionVersion: '2.0'
    condition: onlyRoles(dataRoles)
  }
}
