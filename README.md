# zabbix-mssqlserver-jobs
Template for sql server jobs monitoring.
Uses a powershell script and zabbix_sender, called on zabbix-agent.
Tested on Windows Server 2016, MS SQL Server 2017, Zabbix 5.0.

Based on https://internet-lab.ru/zabbix_template_mssql_2014_jobs, but the solution from this article based on multiple powershell calls, that why CPU load is about 4-5% with long time.
This template has been changed to use zabbix trapper, so all keys (including discovery) are sent using a single call.

# Installation
1. Import zabbix template to zabbix and link it to the windows server host.
2. Copy scripts to zabbix agent folder c:\zabbix\scripts\.
3. Copy zabbix agent configuration to c:\zabbix\zabbix_agentd.conf.d\.
4. Also check settings in all copied file: connection string in mssqljobs.ps1 and other settings in mssqljobs.bat.
5. Include agent configuration in zabbix_agentd.win.conf
```Include=c:\zabbix\zabbix_agentd.conf.d\*.conf```
5. Restart zabbix agent.

**Metrics**
- Job Created
- Job Is Enabled
- Job Is Scheduled
- Job Last Run
- Job Last Run Duration
- Job Last Run Status
- Job Last Run Timestamp
- Job Message
- Job Modified
- Job Next Run
- Job Schedule Interval
- Job Schedule Recurrence Factor
- Job Schedule Subday Interval
- Job Schedule Subday Type
- Job Schedule Type
- Job ServerName

**Triggers**
- Job {#JOBNAME} Is NOT Enabled
- Job {#JOBNAME} Is NOT Scheduled
- Job {#JOBNAME} Last Run Status NOT Succeeded
- Job {#JOBNAME} Last Run was more than a 1 HOUR ago
- Job {#JOBNAME} Last Run was more than a 2 HOURS ago
- Job {#JOBNAME} Last Run was more than a MONTH ago
- Job {#JOBNAME} Last Run was more than a WEEK ago
- Job {#JOBNAME} Last Run was more than ONE DAY ago

Note: most triggers are created for personal use, you can write your own by analogy
