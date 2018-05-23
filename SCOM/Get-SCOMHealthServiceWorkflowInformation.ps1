      
function Get-SCOMHealthServiceWorkflowInformation           
{  
<# 
	.SYNOPSIS
	Gets detailed workflow information from a SCOM 2012 (R2) Healthservice.
	.DESCRIPTION
	This function uses the SCOM task Microsoft.SystemCenter.GetAllRunningWorkflows to retrieve all running workflows on a specific HealthService.
	This function collects the task result, exports the result as XML, processes the result to create customworkflow objects and optionally exports these
	objects to a CSV file
	.PARAMETER HealthServiceName
	FQDN of the HealthService to e analyzed
	.PARAMETER SCOMTask
	Name of the Task to be executed. Should be Microsoft.SystemCenter.GetAllRunningWorkflows
	.PARAMETER ExportTaskOutputXML
	Switch, if set, task result will be exported as XML for later analysis
	.PARAMETER SaveWorkflowObjectsAsCSV
	Switch, if set the custom workflow objects will be saved to a CSV file for later analysis
	.PARAMETER ExportDir
	Path of export directory. Default: C:\Temp
	
	.INPUTS
	N/A
	
	.OUTPUTS
	Custom workflow objects with these properties:
	WorkFlowID:		GUID for identifying the workflow
	WorkFlowType:	Rule,Monitor, Discovery, Unknown
	DisplayName: 	Displayname or name of the workflow
	Description:	Description of the workflow
	MPName:			internal MP name of workflow
	MPDisplayName:	Displayname of MP
	MPVersion:		MP version
	ObjectID:		GUID of object
	ObjectName:		target object name
	ObjectDisplayName: target object display name
	ObjectClassID:	GUID of class
	ObjectClassName: target object class name
	ObjectClassDisplayName: target object class display name
	
	.NOTES
    Author:     Brinkmann, Dirk (dirk.brinkmann@microsoft.com)
    Date        Version   Author    Category (NEW | CHANGE | DELETE | BUGFIX): Description
	03.02.2016	2.0.0	  DirkBri - NEW: Completely revamped script. Fixed bugs for several situations.Now supports workflows with duplicate names. Enhanced output file.
	09.03.2015  1.0.0     DirkBri - NEW: first release


	DISCLAIMER:
	This sample script is not supported under any Microsoft standard support program or service. This sample
	script is provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties
	including, without limitation, any implied warranties of merchantability or of fitness for a particular
	purpose. The entire risk arising out of the use or performance of this sample script and documentation
	remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation,
	production, or delivery of this script be liable for any damages whatsoever (including, without limitation,
	damages for loss of business profits, business interruption, loss of business information, or other
	pecuniary loss) arising out of the use of or inability to use this sample script or documentation, even
	if Microsoft has been advised of the possibility of such damages.
	
	.LINK
	http://blogs.technet.com/b/dirkbri

	.EXAMPLE
	<PS> Get-SCOMHealthServiceWorkflowInformation -HealthService my.server.local -ExportTaskOutputXML -SaveWorkflowObjectsAsCSV -verbose
	Analyze my.server.local and save the resulting XML as well as the enriched custom workflow objects. Verbose output.
	
#>
	[cmdletbinding()]
	param(	[Parameter(Mandatory=$true)]
			[string]$HealthServiceName,
			[string]$ScomTask="Microsoft.SystemCenter.GetAllRunningWorkflows",
			[Switch]$ExportTaskOutputXML,
		  	[Switch]$SaveWorkflowObjectsAsCSV,
			[Switch]$OutputWorkflowsToShell,
		  	[String]$ExportDir="C:\Temp"
	)
	
	#Helper functions
	function new-customobject
	{
		param(	$ID,
				$Type,
				$DisplayName,
				$Description,
				$MPName,
				$MPDisplayname,
				$MPVersion,
				$SCOMObjectName,
				$SCOMObjectID,
				$SCOMObjectDisplayname,
				$SCOMObjectClassName,
				$SCOMObjectClassID,				
				$SCOMObjectClassDIsplayName
		)
		$tempWorkFlowObject = New-Object PSCustomObject
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name WorkFlowID -Value $ID
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name WorkFlowType -Value $Type
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name DisplayName -Value $DisplayName
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name Description -Value $Description
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name MPName -Value $MPName
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name MPDisplayName -Value $MPDisplayname
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name MPVersion -Value $MPVersion
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name ObjectID -Value $SCOMObjectID
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name ObjectName -Value $SCOMObjectName
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name ObjectDisplayName -Value $SCOMObjectDisplayname
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name ObjectClassName -Value $SCOMObjectClassName
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name ObjectClassID -Value $SCOMObjectClassID
		$tempWorkFlowObject | Add-Member -MemberType NoteProperty -Name ObjectClassDisplayName -Value $SCOMObjectClassDisplayName
		$tempWorkFlowObject
	}
	
	function search-scomworkflow
	{
		param ($workflowName,
				$MaxWorkflowLength=125
				)
		
		$blnWorkflowFound = $false
		$blnWorkflowNameDoesNotExceedMaxLength = $true
		if ($workflowName.length -gt $MaxWorkflowLength)
		{
			$blnWorkflowNameDoesNotExceedMaxLength = $false
			$strMessage = "Workflowname [{1}] exceeds {0} chars and is probably not complete/unique!" -f $MaxWorkflowLength,$workflowName
			Write-Warning $strMessage
		}
		
		#Check for Monitor      
		if ($blnWorkflowNameDoesNotExceedMaxLength)
		{
			$colMonitors = @($monitors | where-object {$_.Name -eq $WorkFlowName} )
		}
		else
		{
			$colMonitors = @($monitors | where-object {$_.Name -match $WorkFlowName} )
		}
		if ($colMonitors.count -gt 0)   
		{
			$blnWorkflowFound = $true
			if ($colMonitors.count -gt 0)
			{	
				$strMessage = "Multiple monitors found with name: {0}" -f $workflowName
				Write-Verbose $strMessage
			}
			foreach ($Monitor in $colMonitors)
			{
			    $mp = $monitor.getmanagementpack() 
				$ID = $monitor.id.tostring()
		        $Type = "Monitor"
		        $DisplayName = get-displayname -object $monitor -workflow $workflowName 
				$Description = $monitor.Description     
				$script:colCustomWorkFlowObjects+=new-customobject -id $ID -Type $Type -DisplayName $DisplayName -Description $Description -MPName $mp.name -MPDisplayname $mp.Displayname -MPVersion $mp.version -SCOMObjectName $SCOMObjectName -SCOMObjectDisplayname $SCOMObjectDisplayname -SCOMObjectClassName $SCOMObjectClassDIsplayName -SCOMObjectClassDIsplayName  $SCOMObjectClassDIsplayName -SCOMObjectID $SCOMObject.ID.tostring() -SCOMObjectClassID $SCOMObjectClass.ID.tostring()
			}
		}
		
	   	#Check for Rule  
	  	if ($blnWorkflowNameDoesNotExceedMaxLength)
		{
			$colRules = @($rules | where-object {$_.Name -eq $WorkFlowName} )
		}
		else
		{
			$colRules = @($rules | where-object {$_.Name -match $WorkFlowName} )
		}
	  	if ($colRules.count -gt 0)            
	  	{   
			$blnWorkflowFound = $true
		   	if ($colRules.count -gt 0)
		    {	
				$strMessage = "Multiple rules found with name: {0}" -f $workflowName
				Write-Verbose $strMessage
			}
			foreach ($rule in $colRules)
			{
			    $mp = $rule.getmanagementpack()
				$ID = $rule.id.tostring()
				$Type = "Rule"
        		$DisplayName = get-displayname -object $rule -workflow $workflowName 
				$Description = $Rule.Description   
				$script:colCustomWorkFlowObjects+=new-customobject -id $ID -Type $Type -DisplayName $DisplayName -Description $Description -MPName $mp.name -MPDisplayname $mp.Displayname -MPVersion $mp.version -SCOMObjectName $SCOMObjectName -SCOMObjectDisplayname $SCOMObjectDisplayname -SCOMObjectClassName $SCOMObjectClassDIsplayName -SCOMObjectClassDIsplayName  $SCOMObjectClassDIsplayName -SCOMObjectID $SCOMObject.ID.tostring() -SCOMObjectClassID $SCOMObjectClass.ID.tostring()
			}
	   }
	 			          
		#Check for Discovery  
		if ($blnWorkflowNameDoesNotExceedMaxLength)
		{
			$colDiscoveries = @($discoveries | where-object {$_.Name -eq $WorkFlowName} )
		}
		else
		{
			$colDiscoveries = @($discoveries | where-object {$_.Name -match $WorkFlowName} )
		}
	    if ($colDiscoveries.count -gt 0)            
	    { 
			$blnWorkflowFound = $true
			if ($colDiscoveries.count -gt 0)
			{	
				$strMessage = "Multiple discoveries found with name: {0}" -f $workflowName
				Write-Verbose $strMessage
			}
			foreach ($Discovery in $colDiscoveries)
			{
			    #Get ManagementPack            
			    $mp = $discovery.getmanagementpack()  
				$ID = $discovery.id.tostring()
				$Type = "Discovery"
		        $DisplayName = get-displayname -object $discovery -workflow $workflowName 
				$Description = $discovery.Description 
				$script:colCustomWorkFlowObjects+=new-customobject -id $ID -Type $Type -DisplayName $DisplayName -Description $Description -MPName $mp.name -MPDisplayname $mp.Displayname -MPVersion $mp.version -SCOMObjectName $SCOMObjectName -SCOMObjectDisplayname $SCOMObjectDisplayname -SCOMObjectClassName $SCOMObjectClassDIsplayName -SCOMObjectClassDIsplayName  $SCOMObjectClassDIsplayName -SCOMObjectID $SCOMObject.ID.tostring() -SCOMObjectClassID $SCOMObjectClass.ID.tostring()
			}
		}
		
		#Process unkown workflows
		if ($blnWorkflowFound -eq $false)
		{
			$Type = "Unknown Workflow"
         	$DisplayName = $workflowName
		 	$Description = "Unknown Workflow"
			$ID = "N/A"
			$strMessage = "Unknown workflow: {0}" -f $workflowName
			Write-warning $strMessage
			$script:colCustomWorkFlowObjects+=new-customobject -id $ID -Type $Type -DisplayName $DisplayName -Description $Description -MPName $mp.name -MPDisplayname $mp.Displayname -MPVersion $mp.version -SCOMObjectName $SCOMObjectName -SCOMObjectDisplayname $SCOMObjectDisplayname -SCOMObjectClassName $SCOMObjectClassDIsplayName -SCOMObjectClassDIsplayName  $SCOMObjectClassDIsplayName -SCOMObjectID $SCOMObject.ID.tostring() -SCOMObjectClassID $SCOMObjectClass.ID.tostring()
		}
	}
	
	function get-displayname
	{
		param ($Object,
			   $workflowName)
		
		if ($Object.displayname -eq $null)
		{
			$workflowName
		}
		else
		{
			$Object.displayname	
		}
	}
	
	#Verify SCOM Shell
	if (@(Get-Module Operationsmanager).count -ne 1)
	{
		$strMessage = "This function requires a loaded OpsMgr Shell connected to a Management Group"
		Write-Error $strMessage
	}
	
	#
	$script:colCustomWorkFlowObjects = @()
	#DesiredTaskState
	$SuccessState = "Succeeded"
	 
	#Get objects
	$objTask = Get-scomTask -name $ScomTask            
	$classHealthService = Get-scomclass -name "Microsoft.SystemCenter.HealthService"            
	$objHealthService = Get-scomMonitoringObject -Class $classHealthService | Where-Object {$_.DisplayName -match $HealthServiceName}            
	 
	if ($objHealthService -ne $null)
	{
		$strMessage = "NOTICE: Depending on the amount of running workflows on {0} this function can run for several minutes" -f $HealthServiceName
		Write-Host $strMessage
		 #Start Task GetAllRunningWorkflows    
		 $strMessage = "Starting Task <{0}>..." -f $objTask.displayname
		 Write-Verbose $strMessage
		 $TaskResult = Start-scomTask -Task $objTask -Instance $objHealthService    
		 $BatchID = $TaskResult.batchid
		
		 #Wait,until Task is done
		 do
		 {
		 	Start-Sleep -Seconds 1
		 }
		 while ((Get-SCOMTaskResult -BatchID $BatchID) -match "(Scheduled|Started)")
		 $TaskResult = Get-SCOMTaskResult -BatchID $BatchID
		 if ($TaskResult.status -ne $SuccessState)
		 {
		 	$strMessage = "Task with BatchID {0} has state {1} which does not match {2}. No data can be retreived from HealthService {3}" -f $TaskResult.batchid.guid.tostring(),$TaskResult.state,$SuccessState,$objHealthService.name
		 	Write-warning $strMessage
		 }
		 else
		 {
			[xml]$taskXML = $TaskResult.OutPut   
			if ($ExportTaskOutputXML)
			{
				$TempFileName = "{0:yyyyMMdd}_{1}_WorkflowXML.xml" -f (Get-Date),$HealthServiceName.replace(".","_")
				$TempExportFileFQDN = Join-Path $ExportDir $TempFileName
				$taskXML.save($TempExportFileFQDN) 
				$strMessage = "Workflows written as XML to file {0}" -f $TempExportFileFQDN
				Write-Verbose $strMessage
			}
			
			#Retrieve Monitors, rules and discoveries    
			$strMessage = "Retrieving all monitors, rules and discoveries from the Management Group..."
			Write-Verbose $strMessage
			$monitors = get-scommonitor            
			$rules = get-scomrule 
		    $discoveries = get-scomdiscovery | select-object -Unique            
		    
			#Check for each workflow if it's a Rule or Monitor or Discovery.   
			$strMessage = "Processing each workflow..."
			Write-Verbose $strMessage

			$intObjectCount = $taskXML.DataItem.Details.Instance.Count
			$n=0
			foreach ($Object in $taskXML.DataItem.Details.Instance)
			{
				$n++
				$strActivity = "Proccessing discovered {0} objects for HealthService {1}" -f $intObjectCount,$HealthServiceName
				Write-Progress -Activity $strActivity -PercentComplete	(($n/$intObjectCount)*100) -Id 1
				$SCOMObject = Get-SCOMClassInstance -Id $Object.ID
				$SCOMObjectName = $SCOMObject.Name
				$SCOMObjectDisplayname = $SCOMObject.Displayname
				$SCOMObjectClass = Get-SCOMClass -Id $SCOMObject.LeastDerivedNonAbstractManagementPackClassId
				$SCOMObjectClassName = $SCOMObjectClass.Name
				$SCOMObjectClassDisplayName = $SCOMObjectClass.DisplayName
				
				$ObjectWorkFlows = $Object.Workflow
				$intWorkflowCount = $ObjectWorkFlows.count
				$i=0
				foreach ($workflow in $ObjectWorkFlows)            
				{ 
					$i++
					$workflowName = $WorkFlow
					$strActivity = "Proccessing {0} workflows for Object {1} of class {2}" -f $intWorkflowCount,$SCOMObjectDisplayname,$SCOMObjectClassDisplayName
					Write-Progress -Activity $strActivity -PercentComplete	(($i/$intWorkflowCount)*100) -ParentId 1
					search-scomworkflow -workflow $workflowName
				}  
			}
		}
	}
	else
	{
		$strMessage = "HealthService {0} cannot be found or contacted!" -f $HealthServiceName
		Write-Warning $strMessage
	}
	if ($SaveWorkflowObjectsAsCSV)
	{
		$TempFile = "{0:yyyyMMdd}_WorkflowExport_{1}.csv" -f (Get-Date),$HealthServiceName.replace(".","_")
		$TempFileFQDN = Join-Path $ExportDir $TempFile
		$script:colCustomWorkFlowObjects | Export-Csv $TempFileFQDN -NoTypeInformation -Force
		$strMessage = "Custom workflow objects exported to {0}" -f $TempFileFQDN
		Write-Verbose $strMessage
	}
	if ($OutputWorkflowsToShell) 
	{	$script:colCustomWorkFlowObjects}
}