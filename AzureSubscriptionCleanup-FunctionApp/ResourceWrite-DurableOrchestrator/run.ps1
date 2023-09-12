# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

param($Context)

$ErrorActionPreference = "Stop"

# ResourceId is passed as a string but orchestrator receives it as JValue which will fail on interpolation so convert it to string
# other types (checked int and Datetime) are working fine, as well as everything works fine when Input is passed to Activity function
[string]$resourceId = $Context.Input.ResourceId

# NOTE: resource id may have a different case in the azure resource graph so the id check must be case insensitive

# start with resources as they may be updated more often
# isnotnull(tags) is a check that a resource supports tagging (VS empty tags collection)
$expirationTag = 'expireOn'
$resources = Invoke-DurableActivity -FunctionName 'SearchAzGraph-DurableActivity' `
    -Input "Resources | where id =~ '$resourceId' and isnotnull(tags) | project id, Expiration = tags.expireOn, Creator = tags.creator"

# maybe it's a resource group then
if ($resources.Count -eq 0) {
    $expirationTag = 'expireIfEmptyOn'
    $resources = Invoke-DurableActivity -FunctionName 'SearchAzGraph-DurableActivity' `
        -Input "ResourceContainers | where id =~ '$resourceId' | project id, Expiration = tags.expireIfEmptyOn, Creator = tags.creator"
}

if ($resources.Count -eq 0) {
    return "Not a Resource Group nor a Resource that Supports Tagging; or Resource is already removed: $resourceId"
}

if ($resources.Length -ne 1 -Or ($resource = $resources[0]).id -ne $resourceId) {
    return "Something is Wrong with the Resource Query for '$resourceId': $resources"
}

$tags = @{}
$needUpdate = $false
$d = [DateTime]::MinValue
if (![DateTime]::TryParseExact($resource.Expiration, 'yyyy-MM-dd',
                                [System.Globalization.CultureInfo]::InvariantCulture,
                                [System.Globalization.DateTimeStyles]::None,
                                [ref]$d)) {
    $tags[$expirationTag] = $Context.CurrentUtcDateTime.AddDays(3).ToString('yyyy-MM-dd')
    $needUpdate = $true
}
if (!$resource.Creator) {
    $tags['creator'] = (Invoke-DurableActivity -FunctionName 'GetCreator-DurableActivity' -Input $Context.Input).Result
    $needUpdate = $true
}

if (!$needUpdate) {
    return "Valid Resource: $resourceId; Tags: $expirationTag = '$($resource.Expiration)', creator = '$($resource.Creator)'"
}

$result = Invoke-DurableActivity -FunctionName 'UpdateAzTag-DurableActivity' -Input @{ resourceId = $resourceId; tags = $tags }

 @($resource, $result)
