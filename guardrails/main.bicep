// Cost guardrails for the whole subscription (ADR 0003).
// Budget of €10/month with alerts, and a kill switch that deletes every
// resource group tagged costguard=delete when actual spend reaches 100%.

targetScope = 'subscription'

@description('Email address that receives the budget alerts. Passed at deploy time, never committed.')
param alertEmail string

@description('Monthly budget in the billing currency (EUR).')
param budgetAmount int = 10

@description('Region for the guardrails resource group and kill switch.')
param location string = 'belgiumcentral'

@description('First day of the month the budget started. Fixed: Azure rejects changing the start date of an existing budget.')
param budgetStartDate string = '2026-10-01'

var tags = {
  project: 'ai-intelligence-domain'
  component: 'guardrails'
  owner: 'platform-team'
}

// Deliberately NOT tagged costguard=delete: the guardrails must survive the kill switch.
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-intplat-guardrails'
  location: location
  tags: tags
}

module killSwitch 'modules/killswitch.bicep' = {
  scope: rg
  params: {
    location: location
    alertEmail: alertEmail
    tags: tags
  }
}

// The kill switch may delete resource groups anywhere in the subscription.
// It only targets groups tagged costguard=delete (enforced in the workflow).
var contributorRoleId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

resource killSwitchRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, 'killswitch', contributorRoleId)
  properties: {
    principalId: killSwitch.outputs.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', contributorRoleId)
    description: 'Cost guardrail kill switch: deletes resource groups tagged costguard=delete (ADR 0003).'
  }
}

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: 'budget-intplat-monthly'
  properties: {
    category: 'Cost'
    amount: budgetAmount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: budgetStartDate
    }
    notifications: {
      actual50: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: [alertEmail]
      }
      actual80: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: [alertEmail]
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: [alertEmail]
      }
      actual100KillSwitch: {
        enabled: true
        operator: 'GreaterThanOrEqualTo'
        threshold: 100
        thresholdType: 'Actual'
        contactEmails: [alertEmail]
        contactGroups: [killSwitch.outputs.actionGroupId]
      }
    }
  }
}

output killSwitchName string = killSwitch.outputs.logicAppName
output guardrailsResourceGroup string = rg.name
