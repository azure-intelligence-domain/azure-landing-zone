// Bootstrap: the deploy identity of the azure-landing-zone repository.
// Deployed ONCE, manually, by a subscription Owner. Everything after this is
// deployed by GitHub Actions through this identity (GitHub OIDC, no secrets).

targetScope = 'subscription'

import { contributor, reader, rbacAdministrator, managedIdentityOperator, dataRoles, onlyRoles } from '../modules/roles.bicep'

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

module identity '../modules/github-identity.bicep' = {
  scope: rg
  params: {
    name: 'id-intplat-landing-zone'
    location: location
    tags: tags
    subject: 'repo:${githubOrg}@${githubOrgId}/${githubRepo}@${githubRepoId}:environment:${githubEnvironment}'
  }
}

// What the landing zone may hand out: Contributor and Reader, the (constrained) role
// administrator for building blocks, and the data-plane roles. Never Owner.
var grantableRoles = concat([contributor, reader, rbacAdministrator, managedIdentityOperator], dataRoles)

// Creates resource groups, guardrails and per-building-block resources.
resource contributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'landing-zone', contributor)
  properties: {
    principalId: identity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributor)
    description: 'azure-landing-zone pipeline: deploys guardrails and building-block resource groups.'
  }
}

// May grant and remove ONLY the grantable roles above, so it can give each building block
// rights on its own resource groups but can never grant Owner.
resource rbacAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'landing-zone', rbacAdministrator)
  properties: {
    principalId: identity.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', rbacAdministrator)
    description: 'azure-landing-zone pipeline: may assign the grantable roles only (never Owner).'
    conditionVersion: '2.0'
    condition: onlyRoles(grantableRoles)
  }
}

output clientId string = identity.outputs.clientId
output tenantId string = tenant().tenantId
output subscriptionId string = subscription().subscriptionId
