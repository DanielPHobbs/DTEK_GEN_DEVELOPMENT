#Define the event log and your custom event source
$evtlog = "AD FS/Admin"
$source = "AD FS"
#Load the event source to the log if not already loaded.  This will fail if the event source is already assigned to a different log.
if ([System.Diagnostics.EventLog]::SourceExists($source) -eq $false) {
    [System.Diagnostics.EventLog]::CreateEventSource($source, $evtlog)
}

#function to create the events with parameters
function CreateParamEvent ($evtID, $param1, $param2, $param3)
  {
    $id = New-Object System.Diagnostics.EventInstance($evtID,1); #INFORMATION EVENT
    #$id = New-Object System.Diagnostics.EventInstance($evtID,1,2); #WARNING EVENT
    #$id = New-Object System.Diagnostics.EventInstance($evtID,1,1); #ERROR EVENT
    $evtObject = New-Object System.Diagnostics.EventLog;
    $evtObject.Log = $evtlog;
    $evtObject.Source = $source;
    $evtObject.WriteEvent($id, @($param1,$param2,$param3))
  }

#These are just examples to pass as parameters to the event
$hostname = "dtekazdc001.dtekaz.local"
$timestamp = (get-date)

#Command line to call the function and pass whatever you like
CreateParamEvent 136 "The server $hostname was logged at $timestamp" $hostname $timestamp 