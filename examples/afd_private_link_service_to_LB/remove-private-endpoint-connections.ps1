$ErrorActionPreference = 'Stop'

$privateLinkServiceId = $env:PRIVATE_LINK_SERVICE_ID
if ([string]::IsNullOrWhiteSpace($privateLinkServiceId)) {
    throw 'PRIVATE_LINK_SERVICE_ID must be set.'
}

if (-not [string]::IsNullOrWhiteSpace($env:ACTIONS_ID_TOKEN_REQUEST_URL)) {
    if ([string]::IsNullOrWhiteSpace($env:ACTIONS_ID_TOKEN_REQUEST_TOKEN) -or
        [string]::IsNullOrWhiteSpace($env:ARM_CLIENT_ID) -or
        [string]::IsNullOrWhiteSpace($env:ARM_TENANT_ID)) {
        throw 'GitHub OIDC cleanup requires ACTIONS_ID_TOKEN_REQUEST_TOKEN, ARM_CLIENT_ID, and ARM_TENANT_ID.'
    }

    $separator = if ($env:ACTIONS_ID_TOKEN_REQUEST_URL.Contains('?')) { '&' } else { '?' }
    $oidcUrl = "${env:ACTIONS_ID_TOKEN_REQUEST_URL}${separator}audience=api%3A%2F%2FAzureADTokenExchange"
    $oidcToken = Invoke-RestMethod -Uri $oidcUrl -Headers @{
        Authorization = "Bearer $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN"
    }

    az login `
        --service-principal `
        --username $env:ARM_CLIENT_ID `
        --tenant $env:ARM_TENANT_ID `
        --federated-token $oidcToken.value `
        --allow-no-subscriptions `
        --output none
    if ($LASTEXITCODE -ne 0) {
        throw 'Azure CLI OIDC login failed.'
    }
}
else {
    az account show --output none 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw 'Azure CLI authentication is required to remove the private endpoint connections.'
    }
}

$connectionsUrl = "https://management.azure.com$privateLinkServiceId/privateEndpointConnections?api-version=2024-05-01"
$deadline = [datetime]::UtcNow.AddMinutes(10)

do {
    $connections = az rest --method get --url $connectionsUrl --output json | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to list the private endpoint connections.'
    }

    foreach ($connection in @($connections.value)) {
        az rest `
            --method delete `
            --url "https://management.azure.com$($connection.id)?api-version=2024-05-01" `
            --output none
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to delete private endpoint connection '$($connection.name)'."
        }
    }

    if (@($connections.value).Count -eq 0) {
        exit 0
    }

    Start-Sleep -Seconds 15
} while ([datetime]::UtcNow -lt $deadline)

throw 'Timed out waiting for the private endpoint connections to be removed.'
