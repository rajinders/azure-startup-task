SET LogPath=%LogFileDirectory%%LogFileName%
 
ECHO Current Role: %RoleName% >> "%LogPath%" 2>&1
ECHO Current Role Instance: %InstanceId% >> "%LogPath%" 2>&1
ECHO Current Directory: %CD% >> "%LogPath%" 2>&1
 
ECHO We will first verify if startup has been executed before by checking %RoleRoot%\StartupComplete.txt. >> "%LogPath%" 2>&1
 
IF EXIST "%RoleRoot%\StartupComplete.txt" (
    ECHO Startup has already run, skipping. >> "%LogPath%" 2>&1
    EXIT /B 0
)

AzCopy\AzCopy.exe /Source:https://rajpublic.blob.core.windows.net/splunk/ /Dest:%TEMP% /Pattern:splunkforwarder-6.2.3-264376-x64-release.msi /Y >> "%LogPath%" 2>&1

IF ERRORLEVEL EQU 0 (

	Echo Installing Splunk Forwarder >> "%LogPath%" 2>&1

	msiexec.exe /i %TEMP%\splunkforwarder-6.2.3-264376-x64-release.msi AGREETOLICENSE=Yes RECEIVING_INDEXER="10.0.0.68:9997" LAUNCHSPLUNK=0 SERVICESTARTTYPE=auto WINEVENTLOG_APP_ENABLE=1 SET_ADMIN_USER=1 PERFMON=cpu,memory,network,diskspace  /quiet >> "%LogPath%" 2>&1
 
	IF ERRORLEVEL EQU 0 (

		
		Echo [monitor://D:\logs] >> "D:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf"
		Echo disabled = false >> "D:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf"
		Echo followTail = true >> "D:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf"
		Echo index = main >> "D:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf"
		Echo sourcetype = general >> "D:\Program Files\SplunkUniversalForwarder\etc\system\local\inputs.conf"

		"D:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" start >> "%LogPath%" 2>&1  

		IF ERRORLEVEL EQU 0 (
			ECHO Splunk installed. Startup completed. >> "%LogPath%" 2>&1
			ECHO Startup completed. >> "%RoleRoot%\StartupComplete.txt" 2>&1
			EXIT /B 0
		) ELSE
		(
			ECHO An error occurred while starting Splunk. The ERRORLEVEL = %ERRORLEVEL%.  >> "%LogPath%" 2>&1
			EXIT %ERRORLEVEL%
		)
	) ELSE (
		ECHO An error occurred. The ERRORLEVEL = %ERRORLEVEL%.  >> "%LogPath%" 2>&1
		EXIT %ERRORLEVEL%
	)
) ELSE (
   ECHO An error occurred while downloading Splunk forwarder The ERRORLEVEL = %ERRORLEVEL%.  >> "%LogPath%" 2>&1
   EXIT %ERRORLEVEL%
)
