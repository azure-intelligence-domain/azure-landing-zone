// Bootstrap: the deploy identity of the azure-landing-zone repository.
// Deployed ONCE, manually, by a subscription Owner. Everything after this is
// deployed by GitHub Actions through this identity (GitHub OIDC, no secrets).

targetScope = 'subscription'

// GitHub puts immutable numeric IDs in the OIDC subject (org@id/repo@id), so a
// deleted and recreated repository with the same name does not get access.
@description('GitHub organisation that owns the repository.')
param githubOrg string = 'azure-intelligence-domain'

@description('Numeric ID of the GitHub organisation (gh api orgs/<org> --jq .id).')
param githubOrgId string = '343586903'

@description('Repository allowed to use this identity.')
param githubRepo string = 'azure-landing-zone'

@description('Numeric ID of the repository (gh api repos/<org>/<repo> --jq .id).')
param githubRepoId string = '1422302934'

@description('GitHub environment the deploy job runs in. Restricted to the main branch.')
param githubEnvironment string = 'azure'

param location string = 'belgiumcentral'

var tags = {
  project: 'ai-intelligence-domain'
  component: 'identities'
  owner: 'platform-team'
}

// Deliberately NOT tagged costguard=delete: after a kill switch run, these
// identities must still exist so the pipelines can rebuild everything.
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-intplat-identities'
  location: location
  tags: tags
}

module identity 'modules/github-identity.bicep' = {
  scope: rg
  params: {
    name: 'id-intplat-landing-zone'
    location: location
    tags: tags
    subject: 'repo:${githubOrg}@${githubOrgId}/${githubRepo}@${githubRepoId}:environment:${githubEnvironment}'
  }
}

var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacAdminRoleId = 'f58310d9-a9f6-439a-9e8d-f62e7b41a168' // Role Based Access Control Administrator

// Creates resource groups, guardrails and per-building-block resources.
resource contributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'landing-zone', contributorRoleId)
  properties: {
    principalId: identity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    description: 'azure-landing-zone pipeline: deploys guardrails and building-block resource groups.'
  }
}

// May grant and remove ONLY the Contributor role, so it can give each building
// block rights on its own resource group but can never escalate to Owner.
resource rbacAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'landing-zone', rbacAdminRoleId)
  properties: {
    principalId: identity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacAdminRoleId)
    description: 'azure-landing-zone pipeline: may assign the Contributor role only.'
    conditionVersion: '2.0'
    condition: '((!(ActionMatches{\'Microsoft.Authorization/roleAssignments/write\'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${contributorRoleId}})) AND ((!(ActionMatches{\'Microsoft.Authorization/roleAssignments/delete\'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${contributorRoleId}}))'
  }
}

output clientId string = identity.outputs.clientId
output tenantId string = tenant().tenantId
output subscriptionId string = subscription().subscriptionId
