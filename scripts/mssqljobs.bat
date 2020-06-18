@echo off
: path for bin
set scriptPath="c:\zabbix\scripts\"
: path to zabbix agent conf file
set zabbixConf="c:\zabbix\zabbix_agentd.win.conf"
: hostname from zabbix_agentd.win.conf (don't know why not setted from agent conf)
set hostname="your hostname"
: ------------------------------------------------------------

set dataFileName="data.txt"
set psFileName="mssqljobs.ps1"
set outputfile="%scriptPath:"=%%dataFileName:"=%"
set psFile="%scriptPath:"=%%psFileName:"=%"

: del previos data file
del %outputfile%

: generate file for zabbix-sender with powershell
powershell -NoProfile -ExecutionPolicy Bypass -File %psFile% %outputfile%

@echo on

: send data to zabbix server
c:\zabbix\zabbix_sender --config %zabbixConf% --host %hostname% --input-file %outputfile% --verbose