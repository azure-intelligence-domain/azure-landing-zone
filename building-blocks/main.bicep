// Building blocks: per block a resource group and a deploy identity with rights on that group only.
// Adding a building block is one entry in main.bicepparam (ADR 0006).

targetScope = 'subscription'

@description('A building block: one repository, one resource group, one deploy identity.')
type buildingBlock = {
  @description('Short name, used in resource names: rg-intplat-<name>, id-intplat-<name>.')
  name: string
  @description('GitHub repository that deploys this block.')
  repo: string
  @description('Numeric ID of that repository (gh api repos/<org>/<repo> --jq .id).')
  repoId: string
  @description('Owning team, as in the EventCatalog teams.')
  owner: string
}

param blocks buildingBlock[]
param githubOrg string = 'azure-intelligence-domain'
param githubOrgId string = '343586903'
param githubEnvironment string = 'azure'
param location string = 'belgiumcentral'

resource groups 'Microsoft.Resources/resourceGroups@2024-03-01' = [
  for block in blocks: {
    name: 'rg-intplat-${block.name}'
    location: location
    tags: {
      project: 'ai-intelligence-domain'
      component: block.name
      owner: block.owner
      costguard: 'delete' // the kill switch may delete it; the pipelines rebuild it
    }
  }
]

// Identities live in rg-intplat-identities (never deleted), so a block can be rebuilt after a kill.
module identities '../modules/github-identity.bicep' = [
  for block in blocks: {
    name: 'identity-${block.name}'
    scope: resourceGroup('rg-intplat-identities')
    params: {
      name: 'id-intplat-${block.name}'
      location: location
      tags: {
        project: 'ai-intelligence-domain'
        component: 'identities'
        owner: block.owner
      }
      subject: 'repo:${githubOrg}@${githubOrgId}/${block.repo}@${block.repoId}:environment:${githubEnvironment}'
    }
  }
]

module access '../modules/contributor.bicep' = [
  for (block, i) in blocks: {
    name: 'access-${block.name}'
    scope: resourceGroup(groups[i].name)
    params: {
      principalId: identities[i].outputs.principalId
    }
  }
]

output identities array = [
  for (block, i) in blocks: {
    block: block.name
    repo: block.repo
    resourceGroup: groups[i].name
    clientId: identities[i].outputs.clientId
  }
]
