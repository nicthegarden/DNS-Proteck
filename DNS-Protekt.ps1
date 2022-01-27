#DNS Protekt Scritp
#This script load up a list hosted on a website and then apply it to your host file.
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
Get-Content C:\dnscapture\newhost.txt >> C:\Windows\System32\drivers\etc\hosts