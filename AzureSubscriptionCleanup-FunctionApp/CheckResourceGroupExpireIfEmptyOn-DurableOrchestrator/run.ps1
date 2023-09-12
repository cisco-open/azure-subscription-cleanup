# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

param($Context)

if (($resources = Invoke-DurableActivity -FunctionName 'SearchAzGraph-DurableActivity' `
    -Input "ResourceContainers
        | where type =~ 'microsoft.resources/subscriptions/resourcegroups' and isnull(todatetime(tags.expireIfEmptyOn))
        | project id, ExpireIfEmptyOn = tags.expireIfEmptyOn").Count -eq 0) {
    return "All Resource Groups have valid 'expireIfEmptyOn' tag"
}

$expiration = $Context.CurrentUtcDateTime.AddDays(3).ToString('yyyy-MM-dd')
$parallelTasks = foreach ($resource in $resources) {
    Invoke-DurableActivity -FunctionName 'UpdateAzTag-DurableActivity' -Input @{ resourceId = $resource.id; tags = @{ expireIfEmptyOn = $expiration } } -NoWait
}
$results = Wait-ActivityFunction -Task $parallelTasks

@($resources, $results)
