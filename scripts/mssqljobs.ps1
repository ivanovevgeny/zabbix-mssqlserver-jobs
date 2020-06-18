#Задаем переменные для подключение к MSSQL. $uid и $pwd нужны для проверки подлинности windows / We define the variables for connecting to MS SQL. $uid и $pwd need to authenticate windows
$SQLServer = "(local)"#$(hostname.exe)
$uid = "zabbix"
$pass = "zabbix"

#Создаем подключение к MSSQL / Create a connection to MSSQL

#Если проверка подлинности windows / If windows authentication
$connectionString = "Server = $SQLServer; User ID = $uid; Password = $pass;"

#Если Интегрированная проверка подлинности / If integrated authentication
#$connectionString = "Server=$SQLServer; Integrated Security = True;"
#Write-Output $connectionString

$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

#Создаем запрос непосредственно к MSSQL / Create a request directly to MSSQL
$SqlCmd = New-Object System.Data.SqlClient.SqlCommand  

$SqlCmd.CommandText = "
    SELECT 
	    [sSVR].[name] + '.' +[sJOB].[name] AS [JobName]
    FROM
	    [msdb].[dbo].[sysjobs] AS [sJOB] WITH (NOLOCK)
	    INNER JOIN [msdb].[sys].[servers] AS [sSVR] WITH (NOLOCK) ON [sJOB].[originating_server_id] = [sSVR].[server_id]
	    INNER JOIN [msdb].[dbo].[syscategories] AS [sCAT] WITH (NOLOCK) ON [sJOB].[category_id] = [sCAT].[category_id] --AND [sCAT].[name] = N'Database Maintenance'
	    LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP] WITH (NOLOCK) ON [sJOB].[job_id] = [sJSTP].[job_id] AND [sJOB].[start_step_id] = [sJSTP].[step_id]
	    LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH] WITH (NOLOCK) ON [sJOB].[job_id] = [sJOBSCH].[job_id]
	    LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH] WITH (NOLOCK) ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]
	    LEFT JOIN (
		    SELECT job_id, instance_id = MAX(instance_id), MAX(run_duration) AS run_duration
                FROM [msdb].[dbo].sysjobhistory WITH (NOLOCK)
                GROUP BY job_id
		    ) AS l ON sJOB.job_id = l.job_id
	    LEFT JOIN [msdb].[dbo].sysjobhistory AS h WITH (NOLOCK) ON h.job_id = l.job_id AND h.instance_id = l.instance_id
	WHERE [sJOB].[name] <> 'syspolicy_purge_history'
    ORDER BY [JobName]

	SELECT 
		[sSVR].[name] + '.' +[sJOB].[name] AS 'JOB_NAME'
		,[sSVR].[name] AS 'SERVERNAME'
		,CONVERT(VARCHAR, [sJOB].[date_created], 121) AS 'CREATED' 
		,ISNULL(CONVERT(VARCHAR, [sJOB].[date_modified], 121), '') AS 'MODIFIED'
		,[sJOB].[enabled] AS 'IS_ENABLED'
		,(CASE WHEN [sSCH].[schedule_uid] IS NULL THEN 0 ELSE 1 END) AS 'IS_SCHEDULED' 
		,ISNULL(freq_type, 0) AS 'SCHEDULE_TYPE'
		,ISNULL([freq_interval], 0) AS 'SCHEDULE_INTERVAL'
		--,ISNULL(LTRIM(RTRIM(STR([freq_relative_interval]))), '') AS 'SCHEDULE_RELATIVE_INTERVAL'
		,ISNULL([freq_subday_type], 0) AS 'SCHEDULE_SUBDAY_TYPE'
		,ISNULL([freq_subday_interval], 0) AS 'SCHEDULE_SUBDAY_INTERVAL'
		,ISNULL([freq_recurrence_factor], 0) AS 'SCHEDULE_RECURRENCE_FACTOR'
		,ISNULL(CONVERT(VARCHAR, CONVERT(DATETIME, RTRIM(run_date) + ' ' + STUFF(STUFF(REPLACE(STR(RTRIM(h.run_time),6,0),' ','0'),3,0,':'),6,0,':')), 121),'') AS 'LAST_RUN' 
		,ISNULL(CONVERT(VARCHAR, DATEDIFF(SECOND, {d '1970-01-01'}, CONVERT(DATETIME, RTRIM(run_date) + ' ' + STUFF(STUFF(REPLACE(STR(RTRIM(h.run_time),6,0),' ','0'),3,0,':'),6,0,':')))), '0') AS 'LAST_RUN_TIMESTAMP' 
		,ISNULL(LTRIM(RTRIM(STR([sJSTP].Last_run_outcome))), '') AS 'LAST_RUN_STATUS' 
		,ISNULL(STUFF(STUFF(REPLACE(STR([sJSTP].last_run_duration,7,0),' ','0'),4,0,':'),7,0,':'), '') AS 'LAST_RUN_DURATION' 
		,ISNULL(CONVERT(VARCHAR,  CONVERT(DATETIME, RTRIM(NULLIF([sJOBSCH].next_run_date, 0)) +' '+ STUFF(STUFF(REPLACE(STR(RTRIM([sJOBSCH].next_run_time),6,0),' ','0'),3,0,':'),6,0,':')), 121), '') AS 'NEXT_RUN' 
		,ISNULL(h.Message, '') AS 'MESSAGE' 
	FROM
		[msdb].[dbo].[sysjobs] AS [sJOB] WITH (NOLOCK)
		INNER JOIN [msdb].[sys].[servers] AS [sSVR] WITH (NOLOCK) ON [sJOB].[originating_server_id] = [sSVR].[server_id]
		INNER JOIN [msdb].[dbo].[syscategories] AS [sCAT] WITH (NOLOCK) ON [sJOB].[category_id] = [sCAT].[category_id] --AND [sCAT].[name] = N'Database Maintenance'
		LEFT JOIN [msdb].[dbo].[sysjobsteps] AS [sJSTP] WITH (NOLOCK) ON [sJOB].[job_id] = [sJSTP].[job_id] AND [sJOB].[start_step_id] = [sJSTP].[step_id]
		LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH] WITH (NOLOCK) ON [sJOB].[job_id] = [sJOBSCH].[job_id]
		LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH] WITH (NOLOCK) ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]
		LEFT JOIN (
			SELECT job_id, instance_id = MAX(instance_id), MAX(run_duration) AS run_duration
				FROM [msdb].[dbo].sysjobhistory WITH (NOLOCK)
				GROUP BY job_id
			) AS l ON sJOB.job_id = l.job_id
		LEFT JOIN [msdb].[dbo].sysjobhistory AS h WITH (NOLOCK) ON h.job_id = l.job_id AND h.instance_id = l.instance_id
	WHERE [sJOB].[name] <> 'syspolicy_purge_history'
"

$SqlCmd.Connection = $Connection
$SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$SqlAdapter.SelectCommand = $SqlCmd
$DataSet = New-Object System.Data.DataSet
$SqlAdapter.Fill($DataSet) > $null
$Connection.Close()

#Получили список джобов. Записываем в переменную. / We get a list of jobs. Write to the variable.
$jobs = $DataSet.Tables[0]
$values = $DataSet.Tables[1]

#Парсим и передаем список джобов в zabbix. В последней строке нужно вывести имя джоба без запятой в конце. / Parse and pass a list of jobs in zabbix. In the last line need to display the job name without a comma at the end.
$idx = 1

$discovery="- mssql.job.discovery {`"data`": [ "
foreach ($name in $jobs)
{
    $line= "{`"{#JOBNAME}`":`"" + $name.JobName + "`"}"
    if ($idx -lt $jobs.Rows.Count) {$line= $line + ", "}
    $line= $line 
    $discovery= $discovery + $line
    $idx++;
}
$discovery= $discovery + "]}"
#write-host $discovery

$line=""
foreach ($row in $values)
{
    #$line+= "- mssql.job.info[" + $row.JOB_NAME + ",job_name] '" + $row.JOB_NAME + "'`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",servername] '" + $row.SERVERNAME + "'`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",created] '" + $row.CREATED + "'`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",modified] '" + $row.MODIFIED + "'`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",is_enabled] " + $row.IS_ENABLED + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",is_scheduled] " + $row.IS_SCHEDULED + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",schedule_type] " + $row.SCHEDULE_TYPE + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",schedule_interval] " + $row.SCHEDULE_INTERVAL + "`n" 
    #$line+= "- mssql.job.info[" + $row.JOB_NAME + ",schedule_relative_interval] " + $row.SCHEDULE_RELATIVE_INTERVAL + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",schedule_subday_type] " + $row.SCHEDULE_SUBDAY_TYPE + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",schedule_subday_interval] " + $row.SCHEDULE_SUBDAY_INTERVAL + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",schedule_recurrence_factor] " + $row.SCHEDULE_RECURRENCE_FACTOR + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",last_run] '" + $row.LAST_RUN + "'`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",last_run_timestamp] " + $row.LAST_RUN_TIMESTAMP + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",last_run_status] " + $row.LAST_RUN_STATUS  + "`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",last_run_duration] '" + $row.LAST_RUN_DURATION + "'`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",next_run] '" + $row.NEXT_RUN + "'`n" 
    $line+= "- mssql.job.info[" + $row.JOB_NAME + ",message] '" + $row.MESSAGE + "'`n" 
}

$res = ($discovery + "`n" + $line).Trim()
#write-host $res
$Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $False
[System.IO.File]::WriteAllLines("c:\zabbix\scripts\data.txt", $res, $Utf8NoBomEncoding)