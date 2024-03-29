﻿#DNS Protekt Scritp
#This script load up a list hosted on a website and then apply it to your host file.
#To apply this script simply run it.
$MyInvocation.MyCommand.ScriptContents | Out-File c:\dnscapture\DNS-Protekt.ps1
Remove-Item c:\dnscapture\newhost.txt
$path = "C:\dnscapture"
If(!(test-path $path))
{
      New-Item -ItemType Directory -Force -Path $path
      #New-Item -Path "c:\" -Name "dnscapture" -ItemType "directory" -force
}
$url = "https://someonewhocares.org/hosts/hosts"
$output = "c:\dnscapture\newhost.txt"
Invoke-WebRequest -Uri $url -OutFile $output
$fileToCheck = "C:\dnscapture\oghostfile.txt"
if (Test-Path $fileToCheck -PathType leaf)
{
    Remove-Item C:\Windows\System32\drivers\etc\hosts
    Get-Content C:\dnscapture\oghostfile.txt >> C:\Windows\System32\drivers\etc\hosts
    Get-Content c:\dnscapture\newhost.txt >> C:\Windows\System32\drivers\etc\hosts
    exit
}
Get-Content C:\Windows\System32\drivers\etc\hosts > C:\dnscapture\oghostfile.txt
Get-Content C:\dnscapture\newhost.txt >> C:\Windows\System32\drivers\etc\hosts^

$taskname = "DNSProtekt"
$taskdescription = "DNSProtekt"
$action = New-ScheduledTaskAction -Execute 'c:\dnscapture\DNS-Protekt.ps1'
$trigger =  New-ScheduledTaskTrigger -AtStartup -RandomDelay (New-TimeSpan -minutes 3)
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName $taskname -Description $taskdescription -Settings $settings -User "System"
Start-ScheduledTask -TaskName DNSProtekt