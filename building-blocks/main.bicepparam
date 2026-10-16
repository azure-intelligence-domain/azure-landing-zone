using 'main.bicep'

// One entry per building block. Get the repository ID with:
//   gh api repos/azure-intelligence-domain/<repo> --jq .id
param blocks = [
  {
    name: 'eventcatalog'
    repo: 'eventcatalog'
    repoId: '1422370332'
    owner: 'platform-team'
  }
  {
    name: 'platform'
    repo: 'integration-platform'
    repoId: '1422449270'
    owner: 'platform-team'
    groups: [
      { name: 'platform', keep: false }
      { name: 'tap', keep: true } // the tap's history survives the kill switch (ADR 0011)
    ]
  }
  {
    name: 'backend-systems'
    repo: 'backend-systems'
    repoId: '1422617211'
    owner: 'platform-team'
  }
  {
    name: 'system-api-salesforce'
    repo: 'system-api-salesforce'
    repoId: '1422617268'
    owner: 'sales-team'
    runtimeIdentity: true
  }
  {
    name: 'process-api-order'
    repo: 'process-api-order'
    repoId: '1422595726'
    owner: 'order-team'
    runtimeIdentity: true
  }
]
