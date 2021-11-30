# PowerShell Script - dynatrace_ingest
#
# Script to send following Windows Schedule Task metrics to Dynatrace
# - Task time since last execution
# - Task status
# - Task last result

# Switch to OneAgent folder
Set-Location "C:\Program Files\dynaTrace\oneagent\agent\tools"

# Enter Task Names to monitor
$taskNames = @(
    "RtkAudUService64_BG",
    "Adobe Acrobat Update Task"    
)

$currentTime=(Get-Date)

#Gather data for each scheduled task and send to Dynatrace
foreach ($taskName in $taskNames) {

    $lastExecution = (Get-ScheduledTaskInfo -TaskName "$taskName").LastRunTime
    $timeSinceLastExecution =  [math]::Round(($currentTime-$lastExecution).TotalMinutes,0)
    $taskStatus = (Get-ScheduledTask -TaskName $taskName).State
    $taskState=switch ($taskStatus) {
            Unknown {0}
            Disabled {1}
            Queued {2}
            Ready {3}
            Running {4}        
            Default {0}
        }
    $lastResult = (Get-ScheduledTaskInfo -TaskName "$taskName").LastTaskResult
    $lastResultState=switch ($lastResult.toString('x2')) {
        "00" { 0 }
        "41300" { 1 } #Task is ready to run at its next scheduled time
        "41301" { 2 } #Task is currently running
        "41302" { 3 } #Task has been disabled
        "41303" { 4 } #Task has not run yet
        "41304" { 5 } #There are no more runs scheduled for this task
        "41305" { 6 } #One or more of the properties that are needed to run this task have not been set
        "41306" { 7 } #The last run of the task was terminated by the user.
        Default { 8 } #Any other code
        
    }

    # Send metrics to Dynatrace
    Write-Output "dtingest_windows_scheduled_task_timeSinceLastExection,name=`"$taskName`",status=$taskStatus $timeSinceLastExecution" | .\dynatrace_ingest.exe -v
    Write-Output "dtingest_windows_scheduled_task_status,name=`"$taskName`",status=$taskStatus $taskState" |  .\dynatrace_ingest.exe -v
    Write-Output "dtingest_windows_scheduled_task_lastResult,name=`"$taskName`",status=$taskStatus $lastResultState" |  .\dynatrace_ingest.exe -v
}
