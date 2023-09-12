# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

param($Context)

# We remove individual resources because some resources within a given resource group may have different expiration dates,
# resources with data may be kept around longer for later anaylasis, for example.
# The query skips resources with a malformed or missing expiration tag which is expected and will be fixed separately
if (($resources = Invoke-DurableActivity -FunctionName 'SearchAzGraph-DurableActivity' `
    -Input "Resources
        | where todatetime(tags.expireOn) < now()
        | project id, ExpireOn=tags.expireOn").Count -eq 0) {
    return "No Expired Resources"
}

$parallelTasks = foreach ($resource in $resources) {
    Invoke-DurableActivity -FunctionName 'RemoveAzResource-DurableActivity' -Input ($resource.id) -NoWait
}
$results = Wait-ActivityFunction -Task $parallelTasks

@($resources, $results)
