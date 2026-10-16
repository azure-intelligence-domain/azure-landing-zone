#!/usr/bin/env bash
# Bootstrap (manual, once, by a tenant administrator): the Entra ID application that is the
# audience of internal calls between building blocks through the gateway (ADR 0014).
# Runtime identities request a token for api://<application id>; API Management accepts only the
# client ids on the platform's allow-list (integration-platform/routing/internal-callers.yaml).
# Idempotent: safe to run again.
set -euo pipefail

APP_NAME="intplat-platform-apis"

app_id=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)
if [ -z "$app_id" ]; then
  app_id=$(az ad app create --display-name "$APP_NAME" --sign-in-audience AzureADMyOrg --query appId -o tsv)
  az ad app update --id "$app_id" --identifier-uris "api://$app_id"
  echo "Created application $APP_NAME ($app_id)"
fi
if [ -z "$(az ad sp list --filter "appId eq '$app_id'" --query "[0].id" -o tsv)" ]; then
  az ad sp create --id "$app_id" -o none
fi

echo "Audience for internal calls: api://$app_id"
echo "Application (client) id:     $app_id"
