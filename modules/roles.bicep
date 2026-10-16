// The roles the platform hands out, in one place. Exported for the other templates.

@export()
var contributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

@export()
var reader = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

@export()
var rbacAdministrator = 'f58310d9-a9f6-439a-9e8d-f62e7b41a168' // Role Based Access Control Administrator

// Lets a deploy identity attach its block's runtime identity to a Function or Logic App, granted
// on that one identity only.
@export()
var managedIdentityOperator = 'f1a07417-d97a-45cb-824c-7a7467783830'

// Data-plane roles: send to a topic, read a queue, write the tap. A building block may grant
// these within its own resource groups, and nothing else.
@export()
var dataRoles = [
  'd5a91429-5739-47e2-a06b-3470a27159e7' // EventGrid Data Sender
  '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39' // Azure Service Bus Data Sender
  '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0' // Azure Service Bus Data Receiver
  'c6a89b2d-59bc-44d0-9896-0f6e12d7b80a' // Storage Queue Data Message Sender
  '8a0f0c08-91a1-4084-bc3d-661d67233fed' // Storage Queue Data Message Processor
  '19e7f393-937e-4f77-808e-94535e297925' // Storage Queue Data Reader
  'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor
  'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner (a Function's own host storage)
  '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // Storage Blob Data Reader
]

// ABAC condition: the role administrator may create and delete assignments of these roles only.
@export()
func onlyRoles(roleIds string[]) string =>
  '((!(ActionMatches{\'Microsoft.Authorization/roleAssignments/write\'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(roleIds, ', ')}})) AND ((!(ActionMatches{\'Microsoft.Authorization/roleAssignments/delete\'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {${join(roleIds, ', ')}}))'
