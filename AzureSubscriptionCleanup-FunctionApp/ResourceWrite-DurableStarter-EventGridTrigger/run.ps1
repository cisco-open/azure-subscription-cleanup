# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

param($EventGridEvent, $TriggerMetadata)

$ErrorActionPreference = "Stop"

$EventGridEvent | ConvertTo-Json -Depth 10 | Write-Information

# it is always better to immediatly convert outside events into internal structures but here it is also important to aknowledge
# the azure sdk limitation of using only 2 deep level for json serialization when transfering objects between durable functions,
# so we keep our objects simple
#  - https://github.com/Azure/azure-functions-powershell-worker/issues/754
#  - https://github.com/Azure/azure-functions-durable-extension/issues/1922
$resourceWriteData = @{
    'ResourceId' = $EventGridEvent.data.resourceUri
    'UserName' = $EventGridEvent.data.claims.name ?? $EventGridEvent.data.claims."http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
    'UserEmail' = $EventGridEvent.data.claims."http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
    'PrincipalType' = $EventGridEvent.data.authorization.evidence.principalType
    'PrincipalId' = $EventGridEvent.data.authorization.evidence.principalId
}

$InstanceId = Start-DurableOrchestration -FunctionName 'ResourceWrite-DurableOrchestrator' -InputObject $resourceWriteData
Write-Output "Started ResourceWrite Orchestration with ID = '$InstanceId'"
