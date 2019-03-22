## How to deploy second test node "s2"

<#

## Introduction
Here, we connect to the existing virtual machine we recently deployed named "s2".
We then manage the node using the pull server.

## Pull requirements
In the dsc "pull" model, it is our responsibility
to stage the required modules on the pull server.
The pull server can then provide the bits to the remote nodes.

## Prepare your mind
With so many new functions and things you have learned now with dsc,
it is very difficult to allow anything non-standard into your training flow.
Make way for just one function.

## Custom Function - "Publish-DscResourcePull"
The "Publish-DscResourcePull" function is a helper module from the community.
This is on github, as part of the Pluralsight supporting materials for
"Practical Desired State Configuration (DSC)" by JDuffney, and is
also included with DSC_LABS in the "Helper_Functions" folder.

#>

## Optional - Look at custom function
psedit "C:\DSC_LABS\Helper-Functions\Publish-DSCResourcePull.ps1"

## Configuration for "s2"
psedit "C:\DSC_LABS\NewTestNode.ps1"

## Summary
<#
In this demo, we configured the "s2" node using the pull server.
When using a pull server, modules are copied automatically
to the remote node (if the pull server has the bits).

We also learned that we may need to run an extra function or two
from the community (or homegrown) to make working with the pull
server easier.
#>

## Next, we review the certificate types we support, starting with the self-signed DscBastionCert:
psedit "C:\DSC_LABS\docs\Demo 19 - Review - How to handle nodes with self-signed DscBastionCert.ps1"

## Or, skip ahead to handling nodes with the PSDSCPullServerCert:
psedit "C:\DSC_LABS\docs\Demo 20 - Review - How to handle nodes with PSDSCPullServerCert from domain.ps1"
