# Load the System.Windows.Forms assembly into PowerShell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'SilentlyContinue'
[string]$n = "`r`n"

function New-Button {
  param ( $x, $action, $text)

  $button = New-Object System.Windows.Forms.Button
  $button.Size = New-Object System.Drawing.Size(120, 80)
  $button.Location = New-Object System.Drawing.Size($x, 50)
  $button.Text = $text
  $button.Add_Click( $action)
  return $button
}

# Create a new Form object and assign to the variable $Form
$Form = New-Object System.Windows.Forms.Form
$Form.MinimizeBox = $false
$Form.MaximizeBox = $false
$Form.SizeGripStyle = "Hide"
# $Form.ShowInTaskbar = $true
# $Form.StartPosition = "CenterParent"     
$Form.BackColor = "#FFEEEEEE"
$Form.Size = New-Object System.Drawing.Size(500, 500)
# AutoSize ensures the Form size can contain the text
$Form.StartPosition = "CenterParent"   
$Form.AutoSize = $true
$Form.AutoSizeMode = "GrowAndShrink"
$Form.Text = "Lighthouse Labs VM  Installer"

$FontFace = New-Object System.Drawing.Font(
  "Comic Sans MS", 14, [System.Drawing.FontStyle]::Regular
)
$Form.Font = $FontFace

$Label = New-Object System.Windows.Forms.Label
$Label.Text = "Deploy LightHouse WSL2 Image"
$Label.AutoSize = $true
$Form.Controls.Add($Label)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Size(10, 150)
$outputBox.Size = New-Object System.Drawing.Size(565, 200)
$outputBox.MultiLine = $True
$outputBox.Scrollbars = "Vertical"
$FontFace = New-Object System.Drawing.Font(
  "Lucida Console", 12, [System.Drawing.FontStyle]::Regular
)
$outputBox.Font = $FontFace
$outputBox.TabStop = $false
$outputBox.ReadOnly = $true
$Form.Controls.Add($OutputBox)

$EnableButton = New-Button  20 { EnableWSL } "Step 1: `r`nEnable WSL2"
$Form.Controls.Add($EnableButton)
$UpdateButton = New-Button  160 { Update-Kernel } "Step 2: `r`nUpdate Kernel"
$Form.Controls.Add($UpdateButton)
$DeployButton = New-Button  300 { Import-Image } "Step 3: `r`nImport VM Image"
$Form.Controls.Add($DeployButton)

$CloseButton1 = New-Button  20 { $Form.Close() } "Exit"
$CloseButton2 = New-Button  160 { $Form.Close() } "Exit"
$CloseButton3 = New-Button  300 { $Form.Close() } "Exit"

$tarFile = "$env:temp\Lighthouse_wsl-v1.2.tar"

function Write-Textbox {
  param  ( [string]$text, [int] $nl = 0)

  [string]$txt = "$text$n"
  for ($i = 0; $i -lt $nl; $i++) {
    $txt += $n
  }
  $outputBox.text += "$txt"
}

function  EnableWSL {
  $error.Clear()
  $EnableButton.Enabled = $false
  $EnableButton.Text = "Running"

  $isAdmin = Confirm-Admin
  if (!$isAdmin) {
    Show-Admin-Needed-Warning
    $Form.Controls.Remove($EnableButton)
    $Form.Controls.Add($CloseButton1)
    return
  }

  Write-Host "$n Enabling WSL feature..."
  Write-Textbox 'Enabling WSL feature...'
  $out1 = Invoke-Command 'c:\windows\system32\dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart'
  foreach ($item in $out1) {
    if ($item -notmatch '=\s') {
      Write-Host $item
    }
  }
  if ($error -or $out1[-1] -notmatch "success") {
    $EnableButton.Text = "Error!"
    Write-Textbox $error
    Write-Textbox "Error.  Not Completed!"
    return
  }
  Write-Textbox  $out1[-1] 1
  Write-Host "completed successfully."

  Write-Host "$n Enabling Virtual Machine Platform feature..."
  Write-Textbox 'Enabling Virtual Machine Platform feature...'
  $out1 = Invoke-Command 'c:\windows\system32\dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart'
  foreach ($item in $out1) {
    if ($item -notmatch '=\s') {
      Write-Host $item
    }
  }
  if ($error -or $out1[-1] -notmatch "success") {
    $EnableButton.Text = "Error!"
    Write-Textbox $error
    Write-Textbox "Error.  Not Completed!"
    return
  }
  Write-Textbox  $out1[-1] 1
  Write-Host "completed successfully."

  $EnableButton.text = "Step 1:`r`nDone"
  Write-Textbox "Done.  Please REBOOT Your computer now!"
}

function Update-Kernel {
  $error.Clear()
  $UpdateButton.Enabled = $false
  $UpdateButton.Text = "Running"

  $isAdmin = Confirm-Admin
  if (!$isAdmin) {
    Show-Admin-Needed-Warning
    $Form.Controls.Remove($UpdateButton)
    $Form.Controls.Add($CloseButton2)
    return
  }

  $error.Clear()
  Write-Host "$n Updating WSL ..."
  Write-Textbox 'Updating WSL ...'
  $out1 = Invoke-Command 'c:\windows\system32\wsl.exe --update'
  foreach ($item in $out1) {
    Write-Host $item
  }
  if ($error -or $out1[-1] -notmatch "version") {
    $EnableButton.Text = "Error!"
    Write-Textbox $error
    Write-Textbox "Error.  Not Completed!"
    return
  }
  Write-Textbox  $out1[-1] 1
  Write-Host "completed successfully."

  Write-Host "$n Applying WSL Update..."
  Write-Textbox 'Applying WSL Update ...'
  $out1 = Invoke-Command 'c:\windows\system32\wsl.exe --shutdown'
  $out1 = Invoke-Command 'c:\windows\system32\wsl.exe --status'
  foreach ($item in $out1) {
    Write-Host $item
  }

  if ($error) {
    Write-Textbox "`r`nUpdate Failed with errors"
  }

  Write-Textbox 'Complete!  Exit this program and re-run in a Non-Admin Powershell terminal'
  $UpdateButton.text = "Step 2:`r`nDone"
}

function  Import-Image {
  $outputBox.Text = "";
  $DeployButton.Enabled = $false
  $DeployButton.Text = "Running"
  Write-Host "started"

  $isAdmin = Confirm-Admin
  if ($isAdmin) {
    Show-No-Admin-Needed-Warning
    $Form.Controls.Remove($DeployButton)
    $Form.Controls.Add($CloseButton3)
    return
  }

  $TempFile = Download('https://bit.ly/3lhzXFa')
  $ZipFile = "$TempFile.zip"
  if (!$error) {
    Write-Host "Renaming: $ZipFile"
    Rename-Item -Path $TempFile -NewName $ZipFile
  }

  if (!$error) {
    UnPack($ZipFile);
  }

  if (!$error) {
    $imageDir = "$HOME/Lighthouse/wsl"
    Write-Host "Creating:  $imageDir"
    New-Item -ItemType Directory -Force -Path $imageDir
  }

  if (!$error) {
    $file = $tarFile
    $import = Import-WSL-Image( $imageDir, $file )
  }

  if ($error -or !$import) {
    Write-Textbox "$error"
    Write-Textbox "`r`nDeploy Failed with errors"
  }

  Cleanup($ZipFile)
  Write-Textbox 'Done!'
  $DeployButton.text = "Step 3:`r`nDone"
}

function  Download {
  param ($url)
  $TempFile = New-TemporaryFile
  Write-Host "Downloading: $url"
  Write-Host "Writing: $TempFile"
  
  try {
    Write-Textbox 'Downloading ...'
    Write-Textbox '(This can take a long time)'
    Invoke-WebRequest $url -OutFile  $TempFile
  }
  catch {
    Write-Textbox $error
  }

  return $TempFile 
}

function  UnPack {
  param ($Filename)
  Write-Textbox 'Extracting Archive ..'
  Write-Host "Unpacking: $Filename"
  
  try {
    Expand-Archive -Force  $Filename  -DestinationPath $env:temp
  }
  catch {
    Write-Textbox $error
  }
}

function Import-WSL-Image {
  param( $dest, $image)
  Write-Host "Import $tarFile ..."
  Write-Textbox 'Importing image ...'
  $cmd = "c:\windows\system32\wsl.exe --import Lighthouse $dest $image --version 2"
  Write-Host $cmd
  $out = Invoke-Command $cmd
  foreach ($item in $out) {
    Write-Host $item
  }

  if ($error) {
    Write-Textbox $error
    return false
  }

  $cmd = "c:\windows\system32\wsl.exe -l -v"
  Write-Host $cmd
  $out = Invoke-Command $cmd
  foreach ($item in $out) {
    Write-Host $item
    Write-Textbox $item
  }

  return $true
}


function  Cleanup {
  param ($ZipFile)
  Write-Textbox "`r`nCleaning up ..."
  Write-Host "Deleting: $ZipFile"
  Remove-Item $ZipFile
  # Remove-Item "$env:temp"

  Write-Host "Deleting: $tarFile"
  Remove-Item $tarFile
}

function Get-WSL-Status {
  Write-Host "Checking WSL Status..."
  Write-Textbox 'Checking WSL Status ...'
  $out = Invoke-Command 'c:\windows\system32\wsl.exe --status'
  if ($out[0] -notmatch "Copyright") {
    foreach ($item in $out) {
      Write-Host $item
    }
  }
  if ($error) {
    Write-Textbox $error
    Write-Textbox "Error.  Not Completed!"
    return "ERROR"
  }
  
  if ($out[-1] -match "usage information") {
    return "NOT_ENABLED"
  }

  if ($out[-1] -match "kernel file is not found.") {
    return "ENABLED"
  }

  if ($out[-1] -match "version: 5") {
    return "UPDATED"
  }

  return "NOT_ENABLED"
}

function removeNulls {
  # Removes null chars from string
  param ($in)
  $out = $in -replace "`0" 
  return $out;
}

function Remove-Array-Nulls {
  param ($array)
  $result = [System.Collections.ArrayList]@()

  foreach ($item in $array) {
    [String]$str = removeNulls $item;
    # Write-Host $str
    if ($str) {
      [void]$result.Add($str) # prevents Add from returning index
    } 
  }
  return $result;
}

function Invoke-Command {
  # Invokes expression and converts output to ArrayList of strings
  param ($expression)
  $result = Invoke-Expression $expression
  $resultList = Remove-Array-Nulls $result
  return $resultList;
}

function Confirm-Admin {
  $isAdmin = [Security.Principal.WindowsPrincipal]::new(
    [Security.Principal.WindowsIdentity]::GetCurrent()
  ).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

  Write-Textbox "Admin=$isAdmin" 1
  return $isAdmin 
}

function Show-Admin-Needed-Warning {
  $outputBox.Text = "";
  Write-Textbox 'This step requires PowerShell to be run as Administrator' 1
  Write-Textbox 'Please run PowerShell as Administrator and try again'
}
function Show-No-Admin-Needed-Warning {
  $outputBox.Text = "";
  Write-Textbox 'You are running PowerShell as Administrator!' 1
  Write-Textbox 'This is not needed for this step and will very likely deploy the VM to the wrong place on your system.' !
  Write-Textbox 'You need to run this step in a normal, non-admin PowerShell' 1
  Write-Textbox 'Please run PowerShell normally (without Admin) and try again'
}
function Confirm-Virtualization {
  Write-Host "Checking Hardware Virtualization.  One moment..."
  # $virtual = (gcim Win32_ComputerSystem).HypervisorPresent
  $virtual = Get-ComputerInfo -property "Hyper*"
  Write-Host "$virtual"

  if ($virtual -match "HyperVisorPresent=True" -or $virtual -match "HyperVRequirementVirtualizationFirmwareEnabled=True") {
    return $true
  }

  $outputBox.Text = "";
  Write-Textbox 'Your computer is not currently setup to support Hardware Virtualization.  Virtualization must be enabled for WSL to function.' 1
  Write-Textbox "You must enable Virtialization in your Computer's BIOS setup before continuing. This is usually quite easy but is different for every computer so please check your computer manual or search online for how to do this" 1 
  Write-Textbox 'Once enabled, continue with this Setup.'
  return $false
}

$wslStatus = Get-WSL-Status 
Write-Host  "WSL Status=$wslStatus"
if ($wslStatus -eq "UPDATED") {
  Write-Textbox 'Your system has WSL2 enabled with an updated Kernel.'
  Write-Textbox 'Continue to Step 3 to Deploy the LHL Linux VM. ' 1
  Write-Textbox 'Note: You should NOT be running PowerShell as Admin this time!'
  $DeployButton.Enabled = $true
  $EnableButton.Enabled = $false
  $UpdateButton.Enabled = $false
  $EnableButton.text = "Step 1:`r`nDone"
  $UpdateButton.text = "Step 2:`r`nDone"
}
if ($wslStatus -eq "NOT_ENABLED") {
  Write-Textbox 'Your system has does not have WSL2 enabled. Continue with Step 1 to enable WSL2'
  $EnableButton.Enabled = $true
  $UpdateButton.Enabled = $false
  $DeployButton.Enabled = $false
}
if ($wslStatus -eq "ENABLED") {
  Write-Textbox 'Your system has WSL2 enabled. Continue to Step 2 to Update the Kernel'
  $EnableButton.Enabled = $false
  $UpdateButton.Enabled = $true
  $DeployButton.Enabled = $false
  $EnableButton.text = "Step 1:`r`nDone"
}
if ($wslStatus -eq "ERROR") {
  Write-Textbox 'An error was encountered!'
  $EnableButton.Enabled = $false
  $DeployButton.Enabled = $false
  $UpdateButton.Enabled = $false
}

$virtualStatus = Confirm-Virtualization
if (!$virtualStatus) {
  $EnableButton.Enabled = $false
  $UpdateButton.Enabled = $false
  $DeployButton.Enabled = $false
}

[void] $Form.showDialog()