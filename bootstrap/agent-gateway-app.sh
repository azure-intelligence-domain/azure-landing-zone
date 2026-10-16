#!/usr/bin/env bash
# Bootstrap (manual, once, by a tenant administrator): the Entra ID application of the agent
# gateway (ADR 0012). Agents call apim-intplat-agents with a token for this application and must
# hold its app role "Agent.Act". Idempotent: safe to run again.
#
# Usage: bootstrap/agent-gateway-app.sh [principal-object-id-of-an-agent ...]
# Without arguments it grants the role to the platform pipeline identity (the smoke-test agent).
set -euo pipefail

APP_NAME="intplat-agent-gateway"
ROLE_VALUE="Agent.Act"
GRAPH="https://graph.microsoft.com/v1.0"

app_id=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [ -z "$app_id" ]; then
  role_id=$(uuidgen | tr 'A-Z' 'a-z')
  app_id=$(az ad app create --display-name "$APP_NAME" --sign-in-audience AzureADMyOrg \
    --app-roles "[{\"id\":\"$role_id\",\"value\":\"$ROLE_VALUE\",\"displayName\":\"Act through the agent gateway\",\"description\":\"Allows an AI agent to call the integration platform through the agent gateway. Every call is audited in the tap.\",\"allowedMemberTypes\":[\"Application\"],\"isEnabled\":true}]" \
    --query appId -o tsv)
  az ad app update --id "$app_id" --identifier-uris "api://$app_id"
  echo "Created application $APP_NAME ($app_id)"
fi

sp_id=$(az ad sp list --filter "appId eq '$app_id'" --query "[0].id" -o tsv)
if [ -z "$sp_id" ]; then
  sp_id=$(az ad sp create --id "$app_id" --query id -o tsv)
  # Only principals that were granted the app role may get a token for this application.
  az ad sp update --id "$sp_id" --set appRoleAssignmentRequired=true
fi
role_id=$(az ad app show --id "$app_id" --query "appRoles[?value=='$ROLE_VALUE'].id | [0]" -o tsv)

agents=("$@")
if [ ${#agents[@]} -eq 0 ]; then
  agents=("$(az identity show -g rg-intplat-identities -n id-intplat-platform --query principalId -o tsv)")
fi

for agent in "${agents[@]}"; do
  granted=$(az rest --method get --url "$GRAPH/servicePrincipals/$sp_id/appRoleAssignedTo" \
    --query "value[?principalId=='$agent' && appRoleId=='$role_id'] | length(@)" -o tsv)
  if [ "$granted" = "0" ]; then
    az rest --method post --url "$GRAPH/servicePrincipals/$sp_id/appRoleAssignedTo" \
      --body "{\"principalId\":\"$agent\",\"resourceId\":\"$sp_id\",\"appRoleId\":\"$role_id\"}" -o none
    echo "Granted $ROLE_VALUE to $agent"
  fi
done

echo "Audience for agent tokens: api://$app_id"
echo "Application (client) id:   $app_id"
