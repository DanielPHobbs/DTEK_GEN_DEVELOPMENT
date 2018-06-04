##
## set external time source
## set server type to NTP
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name Type -Value ‘NTP’
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name AnnounceFlags -Value 5
## Enable NTP server
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer -Name Enabled -Value 1
## Specify Time source
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters -Name NtpServer -Value ‘time.windows.com,0x1’
## Set poll interval in seconds – every 30 minutes
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient -Name SpecialPollInterval -Value 1800
## set max +/- time corrections in seconds – 24 hours
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name MaxPosPhaseCorrection -Value 86400
Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config -Name MaxnegPhaseCorrection -Value 86400
Stop-Service -Name W32Time
Start-Service -Name W32Time