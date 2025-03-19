$resourceGroupName ='NewRG' 
$azureRegion = 'East US'
$vmName = 'MYVM'

# Fix: Correct variable name
New-AzResourceGroup -Name $resourceGroupName -Location $azureRegion

$newSubnetParams = @{
    'Name'          = 'MySubnet'
    'AddressPrefix' = '10.0.1.0/24' 
}
$subnet = New-AzVirtualNetworkSubnetConfig @newSubnetParams

$newVNetParams = @{
    'Name'              = 'MyNetwork'
    'ResourceGroupName' = $resourceGroupName
    'Location'          = $azureRegion
    'AddressPrefix'     = '10.0.0.0/16'
}
$vNet = New-AzVirtualNetwork @newVNetParams -Subnet $subnet

$newStorageAcctParams = @{
    'Name'              = 'azurencplnewRGSA'
    'ResourceGroupName' = $resourceGroupName
    'SkuName'           = 'Standard_LRS'
    'Location'          = $azureRegion
}
$storageAccount = New-AzStorageAccount @newStorageAcctParams

$newPublicIpParams = @{
    'Name'              = 'MyPublicIP'
    'ResourceGroupName' = $resourceGroupName
    'AllocationMethod'  = 'Dynamic'
    'DomainNameLabel'   = 'test-domain'
    'Location'          = $azureRegion
}
$publicIp = New-AzPublicIpAddress @newPublicIpParams

$newVNicParams = @{
    'Name'              = 'MyNic'
    'ResourceGroupName' = $resourceGroupName
    'Location'          = $azureRegion
}
$vNic = New-AzNetworkInterface @newVNicParams -SubnetId $vNet.Subnets[0].Id -PublicIpAddressId $publicIp.Id

$newConfigParams = @{
    'VMName' = $vmName
    'VMSize' = 'Standard_B1s' # More cost-efficient than Standard_A3
} 
$vmConfig = New-AzVMConfig @newConfigParams

$newVmOsParams = @{
    'Windows'          = $true
    'ComputerName'     = $vmName
    'Credential'       = (Get-Credential -Message 'Enter Admin Username and Password')
    'ProvisionVMAgent' = $true
    'EnableAutoUpdate' = $true
}
$vm = Set-AzVMOperatingSystem @newVmOsParams -VM $vmConfig

$newSourceImageParams = @{
    'PublisherName' = 'MicrosoftWindowsServer'
    'Version'       = 'latest'
    'Skus'          = '2019-Datacenter'
}
$vm = Set-AzVMSourceImage @newSourceImageParams -VM $vm -Offer 'WindowsServer'

$vm = Add-AzVMNetworkInterface -VM $vm -Id $vNic.Id

$osDiskName = 'myDisk'
$osDiskUri = "$($storageAccount.PrimaryEndpoints.Blob)vhds/$vmName-$osDiskName.vhd"

$newOsDiskParams = @{
    'Name'         = 'OSDisk'
    'CreateOption' = 'fromImage'
}
$vm = Set-AzVMOSDisk @newOsDiskParams -VM $vm -VhdUri $osDiskUri

# Fix: Correct variable name
New-AzVM -VM $vm -ResourceGroupName $resourceGroupName -Location $azureRegion
