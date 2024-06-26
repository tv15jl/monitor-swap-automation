﻿param($async)
$path = (Split-Path $MyInvocation.MyCommand.Path -Parent)
Set-Location $path
$settings = Get-Content -Path .\MonitorSwapper_Settings.json | ConvertFrom-Json

# Since pre-commands in sunshine are synchronous, we'll launch this script again in another powershell process
if ($null -eq $async) {
    Start-Process powershell.exe  -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`" $($MyInvocation.MyCommand.UnboundArguments) -async $true" -WindowStyle Hidden
    Start-Sleep -Seconds $settings.startDelay
    exit
}


. .\MonitorSwapper_Functions.ps1

if (Test-Path "\\.\pipe\MonitorSwapper") {
    Send-PipeMessage MonitorSwapper Terminate
    Start-Sleep -Seconds 20
}

if (Test-Path "\\.\pipe\MonitorSwapper-OnStreamEnd") {
    Send-PipeMessage MonitorSwapper-OnStreamEnd Terminate
    Start-Sleep -Seconds 4
}

# Attempt to start the transcript multiple times in case previous process is still running.
for ($i = 0; $i -lt 5; $i++) {
    
    try {
        Start-Transcript .\log.txt -ErrorAction Stop
        break;
    }
    catch {
        Start-Sleep -Seconds 2
    }
}

try {
    
    # Asynchronously start the MonitorSwapper, so we can use a named pipe to terminate it.
    Start-Job -Name MonitorSwapperJob -ScriptBlock {
        param($path, $gracePeriod)
        . $path\MonitorSwapper_Functions.ps1
        $lastStreamed = Get-Date


        Register-EngineEvent -SourceIdentifier MonitorSwapper -Forward
        New-Event -SourceIdentifier MonitorSwapper -MessageData "Start"
        while ($true) {
            try {
                if ((IsCurrentlyStreaming)) {
                    $lastStreamed = Get-Date
                }
                else {
                    if (((Get-Date) - $lastStreamed).TotalSeconds -gt $gracePeriod) {
                        New-Event -SourceIdentifier MonitorSwapper -MessageData "GracePeriodExpired"
                        break;
                    }
        
                }
            }
            finally {
                Start-Sleep -Seconds 2
            }
        }
    
    } -ArgumentList $path, $settings.gracePeriod


    # To allow other powershell scripts to communicate to this one.
    Start-Job -Name "MonitorSwapper-Pipe" -ScriptBlock {
        Register-EngineEvent -SourceIdentifier MonitorSwapper -Forward
        $pipeName = "MonitorSwapper"
        for ($i = 0; $i -lt 5; $i++) {
            # We could be pending a previous termination, so lets wait up to 10 seconds.
            if (-not (Test-Path "\\.\pipe\$pipeName")) {
                break
            }
            
            Start-Sleep -Seconds 2
        }


        Remove-Item "\\.\pipe\$pipeName" -ErrorAction Ignore
        $pipe = New-Object System.IO.Pipes.NamedPipeServerStream($pipeName, [System.IO.Pipes.PipeDirection]::In, 1, [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::Asynchronous)

        $streamReader = New-Object System.IO.StreamReader($pipe)
        Write-Output "Waiting for named pipe to recieve kill command"
        $pipe.WaitForConnection()

        $message = $streamReader.ReadLine()
        if ($message -eq "Terminate") {
            Write-Output "Terminating pipe..."
            $pipe.Dispose()
            $streamReader.Dispose()
        }

        New-Event -SourceIdentifier MonitorSwapper -MessageData "Pipe-Terminated"
    }



    Write-Host "Waiting for the next event to be called... (for starting/ending stream)"
    while ($true) {
        Start-Sleep -Seconds 2
        $eventFired = Get-Event -SourceIdentifier MonitorSwapper -ErrorAction SilentlyContinue
        if ($null -ne $eventFired) {
            $eventName = $eventFired.MessageData
            Write-Host "Processing event: $eventName"
            if ($eventName -eq "Start") {
                OnStreamStart
            }
            else {
                $job = OnStreamEndAsJob
                while ($job.State -ne "Completed") {
                    $job | Receive-Job
                    Start-Sleep -Seconds 2
                }
                $job | Wait-Job | Receive-Job
                break;
            }
            Remove-Event -EventIdentifier $eventFired.EventIdentifier
        }
    }
}
finally {
    Stop-Transcript
}
