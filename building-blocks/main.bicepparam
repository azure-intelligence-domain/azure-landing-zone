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
]
