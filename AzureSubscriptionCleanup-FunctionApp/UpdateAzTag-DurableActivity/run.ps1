# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

param($resourceData)

$ErrorActionPreference = "Stop"

$resourceId = $resourceData.resourceId
$tags = $resourceData.tags
$whatIf = Get-WhatIf

Write-Information "Resource Id: $resourceId"
Write-Information "Tags: $($tags | ConvertTo-StringData)"
Write-Information "What If: $whatIf"

$result = Update-AzTag -ResourceId $resourceId -Operation Merge -Tag $tags -WhatIf:$whatIf

$whatIf `
    ? "[whatif] Update-AzTag -ResourceId $resourceId -Tag @{ $($tags | ConvertTo-StringData) }" `
    : "Update-AzTag -ResourceId $resourceId -Tag @{ $($tags | ConvertTo-StringData) }: $($result.Id); Tags: $($result.Properties.TagsProperty | ConvertTo-StringData)"
