// Kill switch: an action group that calls a Logic App (Consumption), which
// deletes every resource group tagged costguard=delete.

param location string
param alertEmail string
param tags object

var armAudience = environment().resourceManager // e.g. https://management.azure.com/
var armBase = take(armAudience, length(armAudience) - 1) // without the trailing slash

resource killSwitch 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'logic-intplat-killswitch'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      triggers: {
        budget_alert: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {}
          }
        }
      }
      actions: {
        list_tagged_resource_groups: {
          type: 'Http'
          runAfter: {}
          inputs: {
            method: 'GET'
            uri: '${armBase}/subscriptions/${subscription().subscriptionId}/resourcegroups'
            queries: {
              'api-version': '2021-04-01'
              '$filter': 'tagName eq \'costguard\' and tagValue eq \'delete\''
            }
            authentication: {
              type: 'ManagedServiceIdentity'
              audience: armAudience
            }
          }
        }
        delete_each_resource_group: {
          type: 'Foreach'
          runAfter: {
            list_tagged_resource_groups: ['Succeeded']
          }
          foreach: '@body(\'list_tagged_resource_groups\')?[\'value\']'
          actions: {
            delete_resource_group: {
              type: 'Http'
              inputs: {
                method: 'DELETE'
                uri: '${armBase}@{items(\'delete_each_resource_group\')?[\'id\']}'
                queries: {
                  'api-version': '2021-04-01'
                }
                authentication: {
                  type: 'ManagedServiceIdentity'
                  audience: armAudience
                }
              }
            }
          }
        }
      }
      outputs: {}
    }
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-intplat-killswitch'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'killswitch'
    enabled: true
    emailReceivers: [
      {
        name: 'owner'
        emailAddress: alertEmail
        useCommonAlertSchema: true
      }
    ]
    logicAppReceivers: [
      {
        name: 'killswitch'
        resourceId: killSwitch.id
        callbackUrl: listCallbackUrl('${killSwitch.id}/triggers/budget_alert', '2019-05-01').value
        useCommonAlertSchema: true
      }
    ]
  }
}

output principalId string = killSwitch.identity.principalId
output actionGroupId string = actionGroup.id
output logicAppName string = killSwitch.name
