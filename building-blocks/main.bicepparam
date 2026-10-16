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
]
