<#
Script: Deletes/clean all boot diagnostics storage containers from the specified storage account
Author: Leo Sorokin
Date: June 13, 2017
Version: 1.0
References:
	This scripts does the following:
	1. Deletes all storage containers that start with 'bootdiagnostics-' from the storage account specified

THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
PARTICULAR PURPOSE.

IN NO EVENT SHALL MICROSOFT AND/OR ITS RESPECTIVE SUPPLIERS BE
LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
OF THIS CODE OR INFORMATION.
#>

workflow delete-bootdiagnosticsstoragecontainers
{
	Param
	(
		[Parameter(mandatory=$false)]
		[String] $ConnectionName = 'AzureRunAsConnection',
		[Parameter(mandatory=$true)]
		[String] $ResourceGroupName,
		[Parameter(mandatory=$true)]
		[String] $StorageAccountName
	)

	try
	{
		$servicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName

		Add-AzureRMAccount `
			-ServicePrincipal `
			-Tenant $servicePrincipalConnection.TenantID `
			-ApplicationId $servicePrincipalConnection.ApplicationID `
			-CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
	}
	catch {
		if (!$servicePrincipalConnection)
		{
			$ErrorMessage = "Connection $ConnectionName not found."
			throw $ErrorMessage
		} else {
			Write-Error -Message $_.Exception
			throw $_.Exception
		}
	}

	Select-AzureRmSubscription -SubscriptionId $servicePrincipalConnection.SubscriptionId

	$StorageAccountKey = Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName

	$StorageContainers = Get-AzureStorageContainer `
		-Context (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey[0].Value)

	$DiagnosticsStorageContainerPattern = "^bootdiagnostics-"

	# Loop over and delete all diagnostic storage containers
	ForEach -Parallel ($StorageContainer in $StorageContainers)
	{
		if ($StorageContainer.Name -match $DiagnosticsStorageContainerPattern)
		{
			Write-Output "Deleting: $($StorageContainer.Name)"
			Remove-AzureStorageContainer `
				-Name $StorageContainer.Name `
				-Context (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey[0].Value) `
				-Force `
				-Verbose
		}
	}
}