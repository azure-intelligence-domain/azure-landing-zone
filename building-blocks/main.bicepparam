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
  {
    name: 'system-api-sap'
    repo: 'system-api-sap'
    repoId: '1422717927'
    owner: 'finance-team'
    runtimeIdentity: true
  }
  {
    name: 'system-api-wms'
    repo: 'system-api-wms'
    repoId: '1422717992'
    owner: 'supply-team'
    runtimeIdentity: true
  }
  {
    name: 'system-api-3pl'
    repo: 'system-api-3pl'
    repoId: '1422718046'
    owner: 'logistics-team'
    runtimeIdentity: true
  }
  {
    name: 'finance-intake'
    repo: 'finance-intake'
    repoId: '1422718097'
    owner: 'finance-team'
    runtimeIdentity: true
  }
  {
    name: 'supply-intake'
    repo: 'supply-intake'
    repoId: '1422718141'
    owner: 'supply-team'
    runtimeIdentity: true
  }
  {
    name: 'logistics-intake'
    repo: 'logistics-intake'
    repoId: '1422718210'
    owner: 'logistics-team'
    runtimeIdentity: true
  }
  {
    name: 'experience-api-webshop'
    repo: 'experience-api-webshop'
    repoId: '1423018174'
    owner: 'channel-team'
    runtimeIdentity: true
  }
  {
    name: 'experience-api-customer-service'
    repo: 'experience-api-customer-service'
    repoId: '1423018231'
    owner: 'channel-team'
    runtimeIdentity: true
  }
  {
    name: 'customer-portal'
    repo: 'customer-portal'
    repoId: '1423018334'
    owner: 'channel-team'
  }
]
