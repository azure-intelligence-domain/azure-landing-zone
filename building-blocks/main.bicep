// Building blocks: per block one or more resource groups and one deploy identity with, on those
// groups only, Contributor plus a role administrator limited to data-plane roles (ADR 0006, 0011).
// Adding a building block is one entry in main.bicepparam.

targetScope = 'subscription'

@description('A resource group of a building block.')
type group = {
  @description('Resource group name suffix: rg-intplat-<name>.')
  name: string
  @description('true: never deleted by the kill switch (no costguard tag). For data that must survive, like the tap.')
  keep: bool
}

@description('A building block: one repository, one deploy identity, its own resource groups.')
type buildingBlock = {
  @description('Short name, used in resource names: id-intplat-<name>.')
  name: string
  @description('GitHub repository that deploys this block.')
  repo: string
  @description('Numeric ID of that repository (gh api repos/<org>/<repo> --jq .id).')
  repoId: string
  @description('Owning team, as in the EventCatalog teams.')
  owner: string
  @description('Its resource groups. Default: one group named after the block, deleted by the kill switch.')
  groups: group[]?
  @description('true: also a runtime identity id-intplat-<name>-runtime for its Function or Logic App (ADR 0014).')
  runtimeIdentity: bool?
}

param blocks buildingBlock[]
param githubOrg string = 'azure-intelligence-domain'
param githubOrgId string = '343586903'
param githubEnvironment string = 'azure'
param location string = 'belgiumcentral'

var groupsOfBlocks = flatten(map(range(0, length(blocks)), i => map(
  blocks[i].?groups ?? [{ name: blocks[i].name, keep: false }],
  g => { block: i, name: g.name, keep: g.keep }
)))

resource groups 'Microsoft.Resources/resourceGroups@2024-03-01' = [
  for g in groupsOfBlocks: {
    name: 'rg-intplat-${g.name}'
    location: location
    tags: union(
      {
        project: 'ai-intelligence-domain'
        component: blocks[g.block].name
        owner: blocks[g.block].owner
      },
      g.keep ? {} : { costguard: 'delete' } // the kill switch may delete it; the pipelines rebuild it
    )
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

module runtimeIdentities '../modules/runtime-identity.bicep' = [
  for block in filter(blocks, b => b.?runtimeIdentity ?? false): {
    name: 'runtime-identity-${block.name}'
    scope: resourceGroup('rg-intplat-identities')
    params: {
      name: 'id-intplat-${block.name}-runtime'
      deployPrincipalId: identities[indexOf(map(blocks, b => b.name), block.name)].outputs.principalId
      location: location
      tags: {
        project: 'ai-intelligence-domain'
        component: 'identities'
        owner: block.owner
      }
    }
  }
]

module access '../modules/contributor.bicep' = [
  for (g, i) in groupsOfBlocks: {
    name: 'access-${g.name}'
    scope: resourceGroup(groups[i].name)
    params: {
      principalId: identities[g.block].outputs.principalId
    }
  }
]

// The platform registers every block's API in API Management and routes to it, so it may read
// every building block's resource groups.
module platformReads '../modules/reader.bicep' = [
  for (g, i) in groupsOfBlocks: if (blocks[g.block].name != 'platform') {
    name: 'platform-reads-${g.name}'
    scope: resourceGroup(groups[i].name)
    params: {
      principalId: identities[indexOf(map(blocks, b => b.name), 'platform')].outputs.principalId
      reason: 'Platform: reads building blocks to register their APIs and route to them.'
    }
  }
]

// Every block may read the platform's resource group (gateways, topics, Application Insights).
module platformLookup '../modules/reader.bicep' = [
  for (block, i) in blocks: if (block.name != 'platform') {
    name: 'platform-lookup-${block.name}'
    scope: resourceGroup('rg-intplat-platform')
    params: {
      principalId: identities[i].outputs.principalId
      reason: 'Building block ${block.name}: finds the gateways, topics and Application Insights.'
    }
  }
]

// Lets each block look up other blocks' identities, e.g. to grant a consumer its queue.
module identityLookup '../modules/reader.bicep' = [
  for (block, i) in blocks: {
    name: 'identity-lookup-${block.name}'
    scope: resourceGroup('rg-intplat-identities')
    params: {
      principalId: identities[i].outputs.principalId
      reason: 'Building block ${block.name}: look up other building blocks\' identities.'
    }
  }
]

output runtimeIdentities array = [
  for (block, i) in filter(blocks, b => b.?runtimeIdentity ?? false): {
    block: block.name
    name: 'id-intplat-${block.name}-runtime'
    clientId: runtimeIdentities[i].outputs.clientId
    principalId: runtimeIdentities[i].outputs.principalId
  }
]

output identities array = [
  for (block, i) in blocks: {
    block: block.name
    repo: block.repo
    clientId: identities[i].outputs.clientId
    principalId: identities[i].outputs.principalId
  }
]
