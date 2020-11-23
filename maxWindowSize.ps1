<#
Copyright © 2017 VMware, Inc. All Rights Reserved. 
SPDX-License-Identifier: MIT

# Max console size and buffer
# Currently this code works on windows machine only.
#Puneet Chawla
#@thisispuneet

NSX Power Operations

Copyright 2017 VMware, Inc.  All rights reserved				

The MIT license (the ìLicenseî) set forth below applies to all parts of the NSX Power Operations project.  You may not use this file except in compliance with the License.†

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#>


if ($Host.Name -match "console") 
{ 
    $MaxHeight = $host.UI.RawUI.MaxPhysicalWindowSize.Height 
    $MaxWidth = $host.UI.RawUI.MaxPhysicalWindowSize.Width 

    $MyBuffer = $Host.UI.RawUI.BufferSize 
    $MyWindow = $Host.UI.RawUI.WindowSize 

    $MyWindow.Height = ($MaxHeight) 
    $MyWindow.Width = ($Maxwidth-2) 

    $MyBuffer.Height = (9999) 
    $MyBuffer.Width = ($Maxwidth-2) 

    $host.UI.RawUI.set_bufferSize($MyBuffer)
    $host.UI.RawUI.set_windowSize($MyWindow)
} 
 
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent() 
$CurrentUserPrincipal = New-Object Security.Principal.WindowsPrincipal $CurrentUser 
$Adminrole = [Security.Principal.WindowsBuiltinRole]::Administrator 
If (($CurrentUserPrincipal).IsInRole($AdminRole)){$Elevated = "Administrator"}     

$Title = $Elevated + " $ENV:USERNAME".ToUpper() + ": $($Host.Name) " + $($Host.Version) + " - " + (Get-Date).toshortdatestring()  
$Host.UI.RawUI.set_WindowTitle($Title)
 