@echo off
del c:\zabbix\scripts\data.txt
powershell -NoProfile -ExecutionPolicy Bypass -File "c:\zabbix\scripts\mssqljobs.ps1"
@echo on
c:\zabbix\zabbix_sender --config c:\zabbix\zabbix_agentd.win.conf --host PUT_YOUR_HOSTNAME --input-file c:\zabbix\scripts\data.txt --verbose