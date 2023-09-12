# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

param($resourceWriteData)

$ErrorActionPreference = "Stop"

$creator = [ordered]@{
    'name' = $resourceWriteData.UserName
    'email' = $resourceWriteData.UserEmail
    'principal' = [ordered]@{
        'type' = $resourceWriteData.PrincipalType
        'id' = $resourceWriteData.PrincipalId
    }
}

if ($resourceWriteData.PrincipalType -eq "ServicePrincipal") {
    # this can fail if not enough permission; we should not stop the execution
    $servicePrincipal = Get-AzADServicePrincipal -ObjectId $resourceWriteData.PrincipalId -ErrorAction SilentlyContinue
    if ($servicePrincipal) {
        $creator.principal.servicePrincipal = [ordered]@{
            'type' = $servicePrincipal.ServicePrincipalType;
            'displayName' = $servicePrincipal.DisplayName
        }
        # this is usually the case for ServicePrincipal but double check
        if (!$resourceWriteData.UserName -And !$resourceWriteData.UserEmail) {
            # AlternativeName array should contain resource id which is a path starting with '/subscriptions'
            $servicePrincipalResourceId = ($servicePrincipal.AlternativeName -like '/subscriptions/*')[0]
            if ($servicePrincipalResourceId) {
                $servicePrincipalResourceCreator = (Get-AzTag -ResourceId $servicePrincipalResourceId).Properties.TagsProperty['creator'] | ConvertFrom-Json
                if ($servicePrincipalResourceCreator) {
                    $creator.name = $servicePrincipalResourceCreator.name
                    $creator.email = $servicePrincipalResourceCreator.email
                }
            }
        }
    } else {
        Get-Error | Out-String | Write-Warning
    }
}

# to preserve the order of the properties for the visual uniformity of the creator tag we convert it into a json string and wrap it into a new object
# otherwise azure sdk will pass creator as an object and randomize the order of the properties defined here
@{ Result = $creator | ConvertTo-Json -Compress }
