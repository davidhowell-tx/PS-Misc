<#
.SYNOPSIS
    Set-PSRemotingRemotely.ps1 is used to modify a remote computer's registry to enable PowerShell Remoting

.PARAMETER ComputerName
    Name of the Target Windows Computer

.EXAMPLE
    Set-PSRemotingRemotely.ps1 -ComputerName SERVER001

.NOTES
    Author: David Howell
    Last Modified: 03/18/2015
#>
[CmdletBinding()]Param(
    [Parameter(Mandatory=$True)][String]$ComputerName
)
Begin {
	# This is the value used to connect to HKLM on a remote system
	$HKLM = 2147483650
} Process {
	if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet) {
		Try {
		    Write-Verbose "Making sure WinRM Service is Started on $ComputerName"
		    # Check that WinRM Service is running on remote machine. If it isn't, start it.
		    if ((Get-Service -ComputerName $ComputerName -Name WinRM).Status -eq "Stopped") {
		        Get-Service -ComputerName $ComputerName -Name WinRM | Start-Service -ErrorAction Stop
		    }
		} Catch {
		    Write-Verbose "Error received: $Error"
		    $Error.Clear()
		    Break
		}

		Try {
		    Write-Verbose "Creating Remote Registry Handle on $ComputerName"
		    # Attempting to create remote registry handle
		    $Reg = New-Object -TypeName System.Management.ManagementClass -ArgumentList \\$ComputerName\Root\default:StdRegProv -ErrorAction Stop
		} Catch { 
		    Write-Verbose "Error received: $Error"
		    Write-Verbose "Unable to connect to $ComputerName's Registry, exiting function."
		    $Error.Clear()
			Break
		}

		Try {
		    Write-Verbose "Attempting to Verify and/or Set the appropriate registry keys on $ComputerName"
		    # Verify the Registry Directory Structure exists, and if not try to create it
		    if ($Reg.EnumValues($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM").ReturnValue -ne 0) {
		        $Reg.CreateKey($HKLM, "SOFTWARE\Policies\Microsoft\Windows\WinRM") | Out-Null
		    }
		    if ($Reg.EnumValues($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM\Service").ReturnValue -ne 0) {
		        $Reg.CreateKey($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM\Service") | Out-Null
		    }
		    # Verify the AllowAutoConfig registry value is 1, or set it to 1
		    $AutoConfigValue=$Reg.GetDWORDValue($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM\Service","AllowAutoConfig")
		    if ($AutoConfigValue.ReturnValue -ne 0 -and $CurrentValue.uValue -ne 1) {
		        $Reg.SetDWORDValue($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM\Service","AllowAutoConfig","0x1") | Out-Null
		    }
		    # Verify the IPv4Filter registry value is *, or set it to *
		    $IPV4Value=$Reg.GetStringValue($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM\Service","IPv4Filter")
		    if ($IPV4Value.ReturnValue -ne 0 -and $IPV4Value.sValue -ne "*") {
		        $Reg.SetStringValue($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM\Service","IPv4Filter","*") | Out-Null
		    }
		    # Verify the IPv6Filter registry value is *, or set it to *
		    $IPV6Value=$Reg.GetStringValue($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM\Service","IPv6Filter")
		    if ($IPV6Value.ReturnValue -ne 0 -and $IPV6Value.sValue -ne "*") {
		        $Reg.SetStringValue($HKLM,"SOFTWARE\Policies\Microsoft\Windows\WinRM\Service","IPv6Filter","*") | Out-Null
		    }
		    # After setting the values, restart the WinRM Service
		    Get-Service -ComputerName $ComputerName -Name WinRM | Restart-Service -Force

		    if ((Get-WmiObject -Class Win32_Service -ComputerName $ComputerName -Filter "Name='WinRM'").StartMode -ne "Auto") {
		        (Get-WmiObject -Class Win32_Service -ComputerName $ComputerName -Filter "Name='WinRM'").ChangeStartMode("Automatic")
		    }
		} Catch {
		    Write-Verbose "Error received: $Error"
		    Write-Verbose "Unable to fix PSRemoting on  $ComputerName."
		    $Error.Clear()
		}
	} else {
		Write-Verbose "$ComputerName is offline"
	}
} End {

}