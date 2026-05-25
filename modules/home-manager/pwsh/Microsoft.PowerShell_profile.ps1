# Super basic profile to manage modules and setup a prompt
# TO DO:
# - Check if updates needed instead of just applying every 5 days

clear #clear the screen prior to PS load

# Prompt
function prompt {
    "$([char]27)[36m PS" + # Print PS in Cyan
    "$([char]27)[37m [$(Get-Date -Format 'HH:mm:ss')]" + # Print time in White
    "$([char]27)[32m $(Get-Location)" + # Print Location in Green
    '> '
} 

function updateModules {
    Write-host "Updating Modules" #Change to progress
    # Update AWS Modules
    Update-AWSToolsModule -CleanUp
    # Update other Modules
    Get-InstalledModule|Where-Object {$_.name -notlike "*aws*"}| Update-Module
    "$(get-date)"|Out-File $lastupdatefile -Force
}

# Probably shouldn't put this in profile
if($(Get-PSRepository PSGallery |Select-Object -ExpandProperty InstallationPolicy) -notlike "Trusted"){Set-PSRepository -Name PSGallery -InstallationPolicy Trusted}

function installModules {
    $modulestoinstall = Get-Content "$ProfileFolder/modules.txt"
    $awsmodulestoinstall = Get-Content "$ProfileFolder/modules_aws.txt"
    $mcount = 0
    $amcount = 0
    foreach($module in $modulestoinstall){
        Write-Progress -Activity "Updating Modules" -Status "Updating $module" -PercentComplete (($mcount / $modulestoinstall.count) * 100)
        Install-Module -Name $module -scope CurrentUser -Force
        $mcount += 1
    }

    foreach($module in $awsmodulestoinstall){
        Write-Progress -Activity "Updating AWS Modules" -Status "Updating $module" -PercentComplete (($amcount / $awsmodulestoinstall.count) * 100)
        Install-AWSToolsModule "AWS.Tools.$module" -Scope CurrentUser -CleanUp -Force
        $amcount += 1
    }
    "$(get-date)"|Out-File $lastupdatefile -Force
}

# Update modules if older than 14 days
$ProfileFolder = $($profile |Split-Path)
$lastupdatefile = "$ProfileFolder/last.txt"
if(Test-Path $lastupdatefile){
    $lastupdate = Get-ItemProperty $lastupdatefile|Select-Object -ExpandProperty LastWriteTime
    if($lastupdate -lt $(get-date).AddDays(-14)){ updateModules }
}
# Install modules if missing
else{ installModules }

# Set Aliases to use powershell commands when in pwsh
Set-Alias -name ls -Value Get-ChildItem
Set-Alias -name grep -Value Select-String

# Formatting Options
$PSStyle.FileInfo.Directory = "`e[35;1m" # Show Directories in Magenta
$PSStyle.FileInfo.SymbolicLink = "`e[36;1m" # Show Symlinks in Cyan
$PSStyle.FileInfo.Executable =  "`e[32;1m" # Show Executables in Green

# PSReadLine Options
Set-PSReadLineOption -PredictionSource History # Enable predictive auto completion based on History
Set-PSReadLineOption -Colors @{ InlinePrediction = "$([char]0x1b)[36;7;238m"} # Set format for predictions
Set-PSReadLineOption -PredictionViewStyle ListView # Set predicition mode to ListView (Default is InlineView)