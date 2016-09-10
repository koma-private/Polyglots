@@ echo off
@@ echo.
@@ echo Invoking a Powershell script...
@@ echo.
@@ setlocal
@@ set PS_WRAPPER_ARGS=%*
@@ set PS_WRAPPER_PATH=%~f0
@@ if defined PS_WRAPPER_ARGS set PS_WRAPPER_ARGS=%PS_WRAPPER_ARGS:"=\"%
@@ PowerShell -sta -Command Invoke-Expression $('$args=@(^&{$args} %PS_WRAPPER_ARGS%);'+[String]::Join([Environment]::NewLine,$((Get-Content '%PS_WRAPPER_PATH%') -notmatch '^^@@^|^^:^|^^cls'))) & endlocal & goto :EOF
{
######################################## POWERSHELL CODE BLOCK ########################################

<#
  A PC diagnostics utility for assisting remote support operation
  
  ** Gathers various system information and saves it into a compressed xml file.
  https://github.com/gamineshi
#>

#requires -version 2
Set-StrictMode -Version 2.0
$ErrorActionPreference = "stop"

Add-Type -AssemblyName System.Web
Add-Type -AssemblyName System.Windows.Forms

function logWql
{
    param
    (
        [string]
        $query,
        [string]
        $logFile
    )
    
    Write-Host "Executing WQL: $query"
    $s = "  <wmi query=`"{0}`">`n" -f $query
    $obj = Get-WmiObject -Query $query
    
    $obj | % {
        $s += "    <items>`n"
        $outer = $_
        $prop = $_ | get-member -MemberType property | select -ExpandProperty Name
        $prop | % {
            $s += "      <item name=`"{0}`">{1}</item>`n" -f [System.Web.HttpUtility]::HtmlEncode($_), [System.Web.HttpUtility]::HtmlEncode($outer.$_)
        }
        $s += "    </items>`n"
    }
    $s += "  </wmi>`n" -f $query

    Add-Content $logFile $s -Encoding UTF8
}

function main
{
    $script:selfPath = [environment]::GetEnvironmentVariable("PS_WRAPPER_PATH")
    $script:cmdPid = (gwmi win32_process -Filter "processid='$pid'").parentprocessid
#	hideWindow $script:cmdPid # Prevent user from closing command prompt
 
	$logFile = [Environment]::GetFolderPath('Desktop') + "\REPORT.XML"
	$compressedLogFile = [Environment]::GetFolderPath('Desktop') + "\REPORT.CAB"

	Set-Content $logFile "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n<report>" -Force

	logWql -query "SELECT * FROM Win32_baseboard" -logFile $logFile
	logWql -query "SELECT * FROM Win32_bios" -logFile $logFile
	logWql -query "SELECT * FROM Win32_Battery" -logFile $logFile
	logWql -query "SELECT * FROM win32_ComputerSystemProduct" -logFile $logFile
	logWql -query "SELECT * FROM win32_DiskDrive" -logFile $logFile
	logWql -query "SELECT * FROM win32_logicalDisk" -logFile $logFile
	logWql -query "SELECT * FROM win32_networkadapter" -logFile $logFile
	logWql -query "SELECT * FROM Win32_NetworkAdapterConfiguration" -logFile $logFile
	logWql -query "SELECT * FROM Win32_PhysicalMemory" -logFile $logFile
	logWql -query "SELECT * FROM Win32_Printer" -logFile $logFile
	logWql -query "SELECT * FROM Win32_processor" -logFile $logFile
	logWql -query "SELECT * FROM Win32_operatingSystem" -logFile $logFile
	logWql -query "SELECT * FROM Win32_Share" -logFile $logFile
	logWql -query "SELECT * FROM win32_startupCommand" -logFile $logFile
	logWql -query "SELECT * FROM win32_process" -logFile $logFile
	logWql -query "SELECT * FROM win32_Service" -logFile $logFile
	logWql -query "SELECT * FROM win32_Product" -logFile $logFile
	logWql -query "SELECT * FROM Win32_Environment" -logFile $logFile
	logWql -query "SELECT * FROM Win32_SystemDriver" -logFile $logFile
	logWql -query "SELECT * FROM Win32_ScheduledJob" -logFile $logFile
	#logWql -query "SELECT * FROM Win32_1394ControllerDevice" -logFile $logFile
	#logWql -query "SELECT * FROM Win32_DeviceBus" -logFile $logFile
	#logWql -query "SELECT * FROM Win32_USBControllerDevice" -logFile $logFile
	logWql -query "SELECT * FROM Win32_SystemUsers" -logFile $logFile
	logWql -query "SELECT * FROM Win32_NTLogEvent WHERE EventType = 1" -logFile $logFile

	Add-Content $logFile "</report>`n"
	makecab $logFile, $compressedLogFile
	Remove-Item $logFile -Force -ErrorAction Continue | Out-Null

	msgboxInfo -title $script:selfPath -message "Dumping is completed. Please send $compressedLogFile to administrator."
}

function hideWindow
{
  param (
    [Parameter(Mandatory=$true)]
    [UInt32]
    $process_id
  )
  $windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);' 
  $asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru 
  [void]$asyncwindow::ShowWindowAsync((Get-Process -PID $process_id).MainWindowHandle, 0) 
}


function msgboxInfo
{
  param (
    [Parameter(Mandatory=$true)]
    [string]
    $title,
    [Parameter(Mandatory=$true)]
    [string]
    $message
  )
  [void][System.Windows.Forms.Messagebox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
}

main

}.Invoke($args)
