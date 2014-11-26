<#
.SYNOPSIS
    Monitor remote computer using ICMP and Alert on changes to Online/Offline status

.DESCRIPTION
    This funciton uses the PowerShell command "Test-Connection" to periodically send ICMP requests to the specified system. When a change occurs in the response of the system, an email is generated and sent to the specified email address.

.PARAMETER Target
    Required Parameter.  The target system to monitor

.PARAMETER EmailAddress
    Required Parameter.  Email Address to which alerts will be sent.

.PARAMETER SMTPServer
    Required Parameter that can be set static if you wish.  SMTP Gateway to use for sending email. 

.PARAMETER CheckInterval
    Optional Parameter.  Interval of time (in seconds) to wait before sending another ICMP request to the target system.

.PARAMETER PacketCount
    Optional Parameter.  Number of ICMP Packets to send to the system each time it is checked.

.PARAMETER ExitWhenOnline
    Optional Parameter.  Stops the monitoring when the system begins to respond to ICMP requests.

.EXAMPLE
    Monitor-ICMPAndEmail -ComputerName SERVERNAME -EmailAddress myname@gmail.com -CheckInterval 300
    In this example we are monitoring SERVERNAME every 5 minutes (300 seconds) and emailing myname@gmail.com 
    when the response changes from $false to $true, or vice versa.

.NOTES
    Author: David Howell
    Date:   September 2, 2014

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1,HelpMessage='What system would you like to monitor?')]
        [String]$ComputerName=$null,
    [Parameter(Mandatory=$True,Position=2,HelpMessage='What email address should receive the alerts?')]
        [String]$EmailAddress=$null,
    [Parameter(Mandatory=$True,HelpMessage='What is your SMTP Gateway?')]
        [String]$SMTPServer=$null, #Set your SMTPServer here and change Mandatory to $false
    [Parameter(Mandatory=$False,HelpMessage='How often should we check the system? (in seconds)')]
        [Int]$CheckInterval=600,
    [Parameter(Mandatory=$False,HelpMessage='How many ICMP Packets should we send?')]
        [Int]$PacketCount=4,
    [Parameter(Mandatory=$False,HelpMessage='Would you like to stop monitoring when the system is online?')]
        [Switch]$ExitWhenOnline
) #end parameters

# Get baseline response before starting monitor loop (you need a start point to monitor for changes)
$Response = Test-Connection -ComputerName $ComputerName -Count $PacketCount -Quiet
$Exit=$false
while ($Exit -eq $false) {
    # Check if the response of the system has changed.  
    if ($Response -eq (Test-Connection -ComputerName $ComputerName -Count $PacketCount -Quiet)) { 
        # If it hasn't changed, pause for the specified interval.
        Start-Sleep $CheckInterval 
    } else { # If ICMP Response has changed
        $DateTime = get-date -format "MM/dd/yyyy hh:mm:ss tt (z)"
        # Update response variable to the most recent response
        $Response = Test-Connection -ComputerName $ComputerName -Count $PacketCount -Quiet
        if ($Response -eq $True) {$Status="Online"} else {$Status="Offline"}
       
        # Generate the Email Subject and Body to be sent
        $EmailSubject= "ICMP Monitor of $ComputerName - System is $Status"
        $EmailBody = "ICMP Response for $ComputerName has changed. The system is now $Status as of $DateTime"
        
        # Send the Email Alert
        Send-MailMessage -To $EmailAddress -From $EmailAddress -Subject $EmailSubject -Body $EmailBody -SmtpServer $SMTPServer
           
        # If the user selected the ExitWhenOnline Switch, and the system is now online exit the loop
        if ($ExitWhenOnline -and $Response -eq $true) { $Exit = $True } 
        else { Start-Sleep $CheckInterval }
    }
}