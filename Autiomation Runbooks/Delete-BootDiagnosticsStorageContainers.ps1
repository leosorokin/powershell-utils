<#
Script: Deletes/clean all boot diagnostics storage containers from the specified storage account
Author: Leonid Sorokin - Microsoft
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
		[Parameter(mandatory=$true)]
        [String] $ResourceGroupName,
		[Parameter(mandatory=$true)]
		[String] $StorageAccountName
    )

    $Conn = Get-AutomationConnection -Name AzureRunAsConnection
    Add-AzureRMAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

    $SubscriptionId = "***Enter Subscription GUID Here***" # Note: UPDATE/CHANGE subscription ID!

    Select-AzureRmSubscription -SubscriptionId $SubscriptionId

	$StorageAccountKey = Get-AzureRmStorageAccountKey -Name $StorageAccountName -ResourceGroupName $ResourceGroupName

	$StorageContainers = Get-AzureStorageContainer -Context (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey[0].Value)

	$DiagnosticsStorageContainerPattern = "^bootdiagnostics-"

	# Loop over and delete all diagnostic storage containers
    ForEach -Parallel ($StorageContainer in $StorageContainers)
    {
		if ($StorageContainer.Name -match $DiagnosticsStorageContainerPattern)
		{
			Write-Output "Deleting: $($StorageContainer.Name)"
			Remove-AzureStorageContainer -Name $StorageContainer.Name -Context (New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey[0].Value) -Force -Verbose
		}
    }
}