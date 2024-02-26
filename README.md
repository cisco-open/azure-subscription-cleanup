# azure-subscription-cleanup

## Summary

A solution deployable per Azure Subscription, consisting of [Azure Durable Functions](https://learn.microsoft.com/en-us/azure/azure-functions/durable/) (using PowerShell) and [Azure Policies](https://learn.microsoft.com/en-us/azure/governance/policy/) for maintaining a clean state of the subscription by removing resources according to their expirations

## Overview

 - Azure Tags are used to keep expiration date and resource owner for Azure Resources:
	- tags for Azure Resource Group:
		- **expireIfEmptyOn**: expiration date (in format 'yyyy-MM-dd') that indicates when the group can be removed if it's empty
		- **creator**: a json string that contains information about a user who created the resource group
	- tags for other Azure Resources that support tagging:
		- **expireOn**: expiration date (in format 'yyyy-MM-dd') that indicates when the resource can be removed
		- **creator**: a json string that contains information about a user who created the resource
 - Every new Azure Resource gets initial expiration tag automatically set by the Azure Policies
 - An Azure Function triggers on every update of a resource to check and fix if needed the expiration and the owner tag
 - Additional Azure Functions trigger once per day to correct any missing or malformed expiration tags and remove all expired resources and all expired empty resource groups
 - Default expiration is set to 3 days after resource was created or resource tag was corrupted

## Deploy

To deploy the solution to an Azure Subscription please use the one click deployment button below.  
You will need to login to your subscription and proceed with a pre-populated Azure Deployment Script

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcisco-open%2Fazure-subscription-cleanup%2Fmain%2Fdeploy.json)

> **_NOTE:_** To uninstall deployed resources please remove them manually.  
> The complete list of deployed resources can be found below

### What Gets Deployed

The following resources will be added to Azure Subscription after deployment

**"AzureSubscriptionCleanup"** in the names below is a configurable parameter and can be changed before deploying which will affect all the names below

 - Azure Policies (all policies are assigned with the same Category for ease of searching):
	- Azure Policy Definition to set 'expireOn' tag on resource
		- Display Name: **Add expireOn tag (AzureSubscriptionCleanup)**
		- Name: **AzureSubscriptionCleanup-ExpireOnTagPolicy**
		- Category: **AzureSubscriptionCleanup**
	- Azure Policy Definition to set 'expireIfEmptyOn' tag on resource group
		- Display Name: **Add expireIfEmptyOn tag (AzureSubscriptionCleanup)**
		- Name: **AzureSubscriptionCleanup-ExpireIfEmptyOnTagPolicy**
		- Category: **AzureSubscriptionCleanup**
	- Azure Policy Initiative to combine both definitions above for the ease of assignment
		- Display Name: **Add expiration tags (AzureSubscriptionCleanup)**
		- Name: **AzureSubscriptionCleanup-ExpirationTagsInitiative**
		- Category: **AzureSubscriptionCleanup**
	- Azure Policy Assignement to combine both definitions above for the assignment purposes
		- Display Name: **Add expiration tags (AzureSubscriptionCleanup)**
		- Name: **AzureSubscriptionCleanup-ExpirationTagsPolicyAssignment**
 - Azure Resource Group **azuresubscriptioncleanup-resourcegroup** with the following resources:
	- Azure Storage Account
		- Name: **azuresubscriptioncleanupstg**
		- Standard Locally-redundant Storage (Standard_LRS)
	- Azure Service Plan
		- Name: **AzureSubscriptionCleanup-AppServicePlan**
		- Consumption Pricing Tier (Y1)
	- Azure Function App
		- Name: **azuresubscriptioncleanup-functionapp**
		- Identity is assigned with the **Contributor** role
		- Set of Azure Durable Functions from this repository:
			- **CheckResourceExpireOn-DurableOrchestrator** - durable orchestrator that searches Azure Graph for resources with bad expiration tags and triggers a function to correct them
			- **CheckResourceGroupExpireIfEmptyOn-DurableOrchestrator**- durable orchestrator that searches Azure Graph for resource groups with bad expiration tags and triggers a function to correct them
			- **CleanupExpiredResourceGroups-DurableOrchestrator** - durable orchestrator that searches Azure Graph for expired resource groups and triggers a function to remove them
			- **CleanupExpiredResources-DurableOrchestrator** - durable orchestrator that searches Azure Graph for expired resources and triggers a function to remove them
			- **GetCreator-DurableActivity** - durable function that collects the information about a resource owner (name, email, principal id etc.) and wraps that into a json string
			- **RemoveAzResource-DurableActivity** - durable function that removes a resource by its id
			- **RemoveAzResourceGroup-DurableActivity** - durable function that removes a resource group by its id
			- **ResourceWrite-DurableOrchestrator** - durable orchestrator that checks whether an updated resource has a valid expiration and creator tag and if neccesary triggers a function to correct them: if the expiration tag is missing or bad, the expiration will be set to default value, if the creator tag is missing, the current user will be set as a creator
			- **ResourceWrite-DurableStarter-EventGridTrigger** - durable trigger which is subscribed to a resource update event and triggers the orchestator to check the tags on the resource
			- **Sanitize-DurableStarter-TimeTrigger** - durable trigger which is scheduled to run once per day and triggers the orchestartor to remove expired resources and to correct bad expiration tags
			- **SearchAzGraph-DurableActivity** - durable function that searches Azure Graph based on the given query
			- **UpdateAzTag-DurableActivity** - durable function that sets the given tags on a given resource
	- Azure Event Grid System Topic that sends an event when a resource is created or updated in the Azure Subscription
		- Name: **AzureSubscriptionCleanup-EventGridSystemTopic**
		- Azure Function subscribed to events: **ResourceWrite-DurableStarter-EventGridTrigger**
		- This is a global component that can only exist once per Azure Subscription
		- Currently the automated deployment is not supported if an Azure Subscription already has one Event Grid System Topic

## Development Setup

Visual Studio Code with PowerShell Azure SDK is required to work with the project.

Useful resources on how to get started:
 - [Quickstart: Create a PowerShell function in Azure using Visual Studio Code](https://learn.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-powershell)
 - [Azure Functions PowerShell developer guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell)
 - [Azure Durable Functions documentation](https://learn.microsoft.com/en-us/azure/azure-functions/durable/)

## Special Thanks

Special thanks to the following open source projects for inspiration and the starting point:
 - [[GitHub]: Az Subscription Cleaner](https://github.com/FBoucher/AzSubscriptionCleaner)
 - [[Microsoft Tech Community]: Tagging Azure Resources with a Creator](https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/tagging-azure-resources-with-a-creator/ba-p/1479819)