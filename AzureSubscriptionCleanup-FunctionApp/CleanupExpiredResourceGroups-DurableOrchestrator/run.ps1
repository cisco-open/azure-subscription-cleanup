# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

param($Context)

# For time efficiency we should run this orchestrator in a few hours after the orchestrator that removes expired resources:
#  so first all expired resources are removed and then we cleanup all expired empty resource groups
#TODO Sub-ocrhestrator (not yet supported in powershell) would make this relationship more visible
$duration = New-TimeSpan -Hours 2
Start-DurableTimer -Duration $duration

# We remove expired resource groups only if they are empty.
# Some empty resource groups may be kept longer for a new deployment, for example.
# The query skips resource groups with a malformed or missing expiration tag which is expected and will be fixed separately
if (($resources = Invoke-DurableActivity -FunctionName 'SearchAzGraph-DurableActivity' `
    -Input "ResourceContainers
        | where type =~ 'microsoft.resources/subscriptions/resourcegroups'
        | where todatetime(tags.expireIfEmptyOn) < now()
        | join kind = leftouter (Resources | summarize ResourcesCount = count() by resourceGroup, subscriptionId) on resourceGroup, subscriptionId
        | where isnull(ResourcesCount)
        | project id, ExpireIfEmptyOn=tags.expireIfEmptyOn").Count -eq 0) {
    return "No Expired Empty Resource Groups"
}

$parallelTasks = foreach ($resource in $resources) {
    Invoke-DurableActivity -FunctionName 'RemoveAzResourceGroup-DurableActivity' -Input ($resource.id) -NoWait
}
$results = Wait-ActivityFunction -Task $parallelTasks

@($resources, $results)
