## Example - How to deploy first test node "s1"

## Introduction
<#
Here, we connect to the existing virtual machine we recently deployed named "s1".
We then manage the node using the CA certificate we created.
However, we are not yet using the pull server to manage this, we will do that later with "s2"
#>

## Deploy VMs
## If needed follow the docs to deploy basic vm.
psedit "C:\DSC_LABS\docs\Demo 3 - How to deploy DSC_LABS with New-LabVM.ps1"

## Configuration for "s1"
## Open the configuration script
psedit "C:\DSC_LABS\NewTestNode.ps1"

## Summary
<#
In this demo, we configured the "s1" node using a CA-signed certificate from lab.local.
We did this from our jump server, and securely managed the node from deployment to configuration.
We did have to copy modules manually with this technique.
#>

#Note: When using a pull server, module copy to remote nodes are handled automatically.

## Next, we manage our second test node named "s2" using the pull server.
psedit "C:\DSC_LABS\docs\Demo 18 - How to deploy second test node (s2).ps1"



