$TimeEnd = Get-Date -Hour 17 -Minute 00 -Second 00 
$WShell = New-Object -com "Wscript.Shell"
while ($(Get-Date) -lt $TimeEnd)
{
  Clear-Host
  Write-Host "$($TimeEnd.Subtract($(Get-Date)).ToString("hh' hours 'mm' minutes 'ss")) seconds until $TimeEnd."
  $WShell.sendkeys("{SCROLLLOCK}")
  Start-Sleep -Milliseconds 100
  $WShell.sendkeys("{SCROLLLOCK}")
  Start-Sleep -Seconds 60
}
Write-Host "$TimeEnd has passed. Exiting..."
