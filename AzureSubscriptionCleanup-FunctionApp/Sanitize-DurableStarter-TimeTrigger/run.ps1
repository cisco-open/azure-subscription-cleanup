# Copyright (c) 2023 Cisco Systems, Inc. and its affiliates.
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

param($Timer)

$InstanceId = Start-DurableOrchestration -FunctionName 'CheckResourceExpireOn-DurableOrchestrator'
Write-Output "Started CheckResourceExpireOn Orchestration with ID = '$InstanceId'"

$InstanceId = Start-DurableOrchestration -FunctionName 'CheckResourceGroupExpireIfEmptyOn-DurableOrchestrator'
Write-Output "Started CheckResourceGroupExpireIfEmptyOn Orchestration with ID = '$InstanceId'"

$InstanceId = Start-DurableOrchestration -FunctionName 'CleanupExpiredResources-DurableOrchestrator'
Write-Output "Started CleanupExpiredResources Orchestration with ID = '$InstanceId'"

$InstanceId = Start-DurableOrchestration -FunctionName 'CleanupExpiredResourceGroups-DurableOrchestrator'
Write-Output "Started CleanupExpiredResourceGroups Orchestration with ID = '$InstanceId'"
