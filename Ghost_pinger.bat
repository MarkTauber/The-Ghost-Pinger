@echo off
setlocal enabledelayedexpansion
title [Ghost Pinger]

:start
rem Clear screen and show header
cls
echo.                                                       
echo   _____ _           _      _____ _                 
echo  ^|   __^| ^|_ ___ ___^| ^|_   ^|  _  ^|_^|___ ___ ___ ___ 
echo  ^|  ^|  ^|   ^| . ^|_ -^|  _^|  ^|   __^| ^|   ^| . ^| -_^|  _^|
echo  ^|_____^|_^|_^|___^|___^|_^|    ^|__^|  ^|_^|_^|_^|_  ^|___^|_^|  
echo                                       ^|___^|        
echo.

:GET_INPUT
rem Get IP range input method
echo Select input method:
echo 1. Enter IP range manually
echo 2. Enter IP range with count (e.g., 192.168.1.1-100)
echo 3. Scan common local networks
echo 4. Scan by CIDR notation (e.g., 192.168.1.0/24)
echo.
set /p "choice=Enter choice (1-4): " || set "choice=3"

if "%choice%"=="1" goto MANUAL_INPUT
if "%choice%"=="2" goto RANGE_INPUT
if "%choice%"=="3" goto COMMON_NETWORKS
if "%choice%"=="4" goto CIDR_INPUT

echo Invalid choice. Please try again.
echo.
goto GET_INPUT

:CIDR_INPUT
echo.
echo === CIDR NOTATION SCAN ===
echo Examples: 192.168.1.0/24, 10.0.0.0/16, 172.16.0.0/12
echo.

rem Get current IP as default
for /f "tokens=2 delims=[]" %%a in ('ping -4 -n 1 %ComputerName% ^| findstr "["') do set "_MYIP=%%a"
if "!_MYIP!"=="" (
    for /f "tokens=13 delims= " %%z in ('ipconfig ^|findstr "IPv4"') do set "_MYIP=%%z"
)

set /p "_IPNET=Enter Network to scan (!_MYIP!): " || set "_IPNET=!_MYIP!"
if "!_IPNET!"=="" set "_IPNET=!_MYIP!"

set /p "_NETMASK=Netmask CIDR format (0 - 32): " || set "_NETMASK=24"
if "!_NETMASK!"=="" set "_NETMASK=24"

rem Validate CIDR
if !_NETMASK! GTR 32 (
    echo Error: Wrong Netmask. Please enter 0 - 32
    pause
    goto CIDR_INPUT
)
if !_NETMASK! LSS 0 set "_NETMASK=0"

rem Parse IP address
for /f "tokens=1-4 delims=." %%a in ("%_IPNET%") do (
    set "I=%%a"
    set "II=%%b"
    set "III=%%c"
    set "IV=%%d"
)

rem Calculate network range based on CIDR
call :CalculateCIDRRange !_IPNET! !_NETMASK!

rem Display CIDR information
echo.
echo CIDR Information:
echo Network: %_IPNET%/%_NETMASK%
echo Network range: %network_start% to %network_end%
echo Hosts to scan: %hosts_count% IP addresses
echo.
goto GET_SETTINGS

:CalculateCIDRRange
set "ip_addr=%1"
set "cidr=%2"

rem Parse IP octets
for /f "tokens=1-4 delims=." %%a in ("%ip_addr%") do (
    set "oct1=%%a"
    set "oct2=%%b"
    set "oct3=%%c"
    set "oct4=%%d"
)

rem Calculate number of host bits
set /a "host_bits=32-%cidr%"

rem Calculate total hosts (2^host_bits - 2)
set "hosts_count=1"
for /l %%i in (1,1,%host_bits%) do set /a "hosts_count*=2"
set /a "hosts_count-=2"
if %hosts_count% LSS 1 set "hosts_count=1"

rem Calculate subnet mask
set /a "mask_full=0"
for /l %%i in (1,1,%cidr%) do (
    set /a "mask_full=(mask_full<<1)+1"
)
set /a "mask_full=mask_full<<(32-%cidr%)"

rem Convert mask to octets
set /a "mask1=(mask_full>>24)&255"
set /a "mask2=(mask_full>>16)&255"
set /a "mask3=(mask_full>>8)&255"
set /a "mask4=mask_full&255"

rem Calculate network address
set /a "net1=oct1&mask1"
set /a "net2=oct2&mask2"
set /a "net3=oct3&mask3"
set /a "net4=oct4&mask4"

rem Calculate broadcast address
set /a "bcast1=net1|(255-mask1)"
set /a "bcast2=net2|(255-mask2)"
set /a "bcast3=net3|(255-mask3)"
set /a "bcast4=net4|(255-mask4)"

rem Set scan parameters
set "network_start=%net1%.%net2%.%net3%.%net4%"
set "network_end=%bcast1%.%bcast2%.%bcast3%.%bcast4%"

rem Store network boundaries for scanning
set "scan_net1=%net1%"
set "scan_net2=%net2%"
set "scan_net3=%net3%"
set "scan_net4=%net4%"
set "scan_bcast1=%bcast1%"
set "scan_bcast2=%bcast2%"
set "scan_bcast3=%bcast3%"
set "scan_bcast4=%bcast4%"

rem Set scan mode
set "scan_mode=cidr"
goto :eof

:MANUAL_INPUT
echo.
echo === MANUAL IP RANGE INPUT ===
set /p "subnet=Enter subnet (e.g., 192.168.1): " || set "subnet=192.168.1"
set /p "start_ip=Enter start IP (1-254): " || set "start_ip=1"
set /p "end_ip=Enter end IP (1-254): " || set "end_ip=254"
set "scan_mode=manual"
goto GET_SETTINGS

:RANGE_INPUT
echo.
echo === IP RANGE WITH COUNT INPUT ===
echo Examples: 192.168.1.1-100, 10.0.0.50-50, 172.16.0.1-254
set /p "range_input=Enter start IP and count (e.g., 192.168.1.1-100): " || set "range_input=192.168.1.1-100"

rem Parse range input
for /f "tokens=1,2 delims=-" %%a in ("%range_input%") do (
    set "start_address=%%a"
    set "ip_count=%%b"
)

rem Extract subnet and base IP from start address
for /f "tokens=1,2,3,4 delims=." %%a in ("%start_address%") do (
    set "subnet=%%a.%%b.%%c"
    set "base_ip=%%d"
)

rem Calculate end IP
set /a "start_ip=%base_ip%"
set /a "end_ip=%base_ip%+%ip_count%-1"

rem Validate range
if %end_ip% GTR 254 set "end_ip=254"
if %start_ip% LSS 1 set "start_ip=1"
if %end_ip% LSS %start_ip% set "end_ip=%start_ip%"

set "scan_mode=range"
goto GET_SETTINGS

:COMMON_NETWORKS
echo.
echo === COMMON LOCAL NETWORKS ===
echo 1. 192.168.1.1-254 (Most common)
echo 2. 192.168.0.1-254 
echo 3. 10.0.0.1-254
echo 4. 172.16.0.1-254
echo.
set /p "common=Select network (1-4): " || set "common=1"

if "%common%"=="1" (
    set "subnet=192.168.1"
    set "start_ip=1"
    set "end_ip=254"
) else if "%common%"=="2" (
    set "subnet=192.168.0"
    set "start_ip=1"
    set "end_ip=254"
) else if "%common%"=="3" (
    set "subnet=10.0.0"
    set "start_ip=1"
    set "end_ip=254"
) else if "%common%"=="4" (
    set "subnet=172.16.0"
    set "start_ip=1"
    set "end_ip=254"
) else (
    set "subnet=192.168.1"
    set "start_ip=1"
    set "end_ip=254"
)
set "scan_mode=common"
goto GET_SETTINGS

:GET_SETTINGS
rem Get additional settings
echo.
echo === SCAN SETTINGS ===
set /p "timeout=Ping timeout in ms (default 1000): " || set "timeout=1000"
set /p "ping_count=Ping attempts (default 1): " || set "ping_count=1"

rem Validate and set defaults if needed
if "%start_ip%"=="" set "start_ip=1"
if "%end_ip%"=="" set "end_ip=254"
if "%timeout%"=="" set "timeout=1000"
if "%ping_count%"=="" set "ping_count=1"

rem Ensure valid ranges
if %start_ip% LSS 1 set "start_ip=1"
if %start_ip% GTR 254 set "start_ip=254"
if %end_ip% LSS 1 set "end_ip=1"
if %end_ip% GTR 254 set "end_ip=254"
if %start_ip% GTR %end_ip% (
    set "temp=%start_ip%"
    set "start_ip=%end_ip%"
    set "end_ip=!temp!"
)

rem Set total hosts
if defined hosts_count (
    set "total_hosts=%hosts_count%"
) else (
    set /a "total_hosts=(%end_ip%-%start_ip%)+1"
)

rem Create timestamp for output file
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "timestamp=%dt:~0,4%-%dt:~4,2%-%dt:~6,2%_%dt:~8,2%-%dt:~10,2%-%dt:~12,2%"
set "output_file=scan_results_%timestamp%.txt"

rem Create output file header
echo Network Scan Results > "%output_file%"
echo ==================== >> "%output_file%"
if "%scan_mode%"=="cidr" (
    echo Network: %network_start% to %network_end% >> "%output_file%"
    echo CIDR: %_IPNET%/%_NETMASK% >> "%output_file%"
) else (
    echo Network: %subnet%.%start_ip%-%end_ip% >> "%output_file%"
)
if defined range_input (
    echo Range: %range_input% >> "%output_file%"
)
echo Date: %date% %time% >> "%output_file%"
echo Ping timeout: %timeout%ms >> "%output_file%"
echo Ping attempts: %ping_count% >> "%output_file%"
echo Total hosts to scan: %total_hosts% >> "%output_file%"
echo ================================================ >> "%output_file%"
echo. >> "%output_file%"

rem Display scan info
echo.
echo ================================================
echo SCAN CONFIGURATION
echo ================================================
if "%scan_mode%"=="cidr" (
    echo Network: %network_start% to %network_end%
    echo CIDR: %_IPNET%/%_NETMASK%
) else (
    echo Network: %subnet%.%start_ip%-%end_ip%
)
if defined range_input (
    echo Range: %range_input%
)
echo Ping timeout: %timeout%ms
echo Ping attempts: %ping_count%
echo Total hosts to scan: %total_hosts%
echo Output file: %output_file%
echo ================================================
echo.

set /p "start_scan=Start scan? (Y/N): " || set "start_scan=Y"
if /i not "%start_scan%"=="Y" if /i not "%start_scan%"=="YES" (
    echo Scan cancelled.
    pause
    exit /b
)

echo.
echo Starting scan...
echo.

set "active_hosts=0"
set "scanned_count=0"

rem Main scanning logic
if "%scan_mode%"=="cidr" (
    call :ScanCIDRRange
) else (
    call :ScanSimpleRange
)

rem Final statistics
echo.
echo ================================================
echo SCAN COMPLETED!
echo ================================================
echo Active hosts found: %active_hosts% out of %scanned_count%
echo Results saved to: %output_file%
echo.

rem Save final statistics to file
echo. >> "%output_file%"
echo ================================================ >> "%output_file%"
echo SCAN STATISTICS >> "%output_file%"
echo ================================================ >> "%output_file%"
echo Active hosts: %active_hosts% >> "%output_file%"
echo Total hosts scanned: %scanned_count% >> "%output_file%"
if %scanned_count% GTR 0 (
    set /a "success_rate=(%active_hosts%*100)/%scanned_count%"
    echo Success rate: !success_rate!%% >> "%output_file%"
)
echo Scan completed: %date% %time% >> "%output_file%"

rem Ask user what to do next
echo.
echo What would you like to do?
echo 1. View results file
echo 2. Open results file in notepad
echo 3. Exit
echo 4. New scan (default)
echo.
set /p "action=Enter choice (1-4): " || set "action=4"

if "%action%"=="1" (
    type "%output_file%"
    echo.
    pause
) else if "%action%"=="2" (
    notepad "%output_file%"
) else if "%action%"=="3" (
    exit /b
) else if "%action%"=="4" (
    goto start
)
goto start

:ScanCIDRRange
rem Scan full CIDR range with nested loops
set "scanned_count=0"

rem Calculate total IPs to scan 
set /a "total_ip_count=(%scan_bcast1%-%scan_net1%)*16777216 + (%scan_bcast2%-%scan_net2%)*65536 + (%scan_bcast3%-%scan_net3%)*256 + (%scan_bcast4%-%scan_net4%)"

for /l %%a in (%scan_net1%,1,%scan_bcast1%) do (
    set "current_net1=%%a"
    for /l %%b in (0,1,255) do (
        if %%a EQU %scan_net1% (
            if %%b GEQ %scan_net2% (
                if %%a EQU %scan_bcast1% (
                    if %%b LEQ %scan_bcast2% (
                        set "current_net2=%%b"
                        call :ScanThirdOctet !current_net1! !current_net2!
                    )
                ) else (
                    set "current_net2=%%b"
                    call :ScanThirdOctet !current_net1! !current_net2!
                )
            )
        ) else if %%a EQU %scan_bcast1% (
            if %%b LEQ %scan_bcast2% (
                set "current_net2=%%b"
                call :ScanThirdOctet !current_net1! !current_net2!
            )
        ) else (
            set "current_net2=%%b"
            call :ScanThirdOctet !current_net1! !current_net2!
        )
    )
)
goto :eof

:ScanThirdOctet
set "net1=%1"
set "net2=%2"

for /l %%c in (0,1,255) do (
    if %net1% EQU %scan_net1% (
        if %net2% EQU %scan_net2% (
            if %%c GEQ %scan_net3% (
                if %net1% EQU %scan_bcast1% (
                    if %net2% EQU %scan_bcast2% (
                        if %%c LEQ %scan_bcast3% (
                            set "current_net3=%%c"
                            call :ScanFourthOctet %net1% %net2% !current_net3!
                        )
                    ) else (
                        set "current_net3=%%c"
                        call :ScanFourthOctet %net1% %net2% !current_net3!
                    )
                ) else (
                    set "current_net3=%%c"
                    call :ScanFourthOctet %net1% %net2% !current_net3!
                )
            )
        )
    ) else if %net1% EQU %scan_bcast1% (
        if %net2% EQU %scan_bcast2% (
            if %%c LEQ %scan_bcast3% (
                set "current_net3=%%c"
                call :ScanFourthOctet %net1% %net2% !current_net3!
            )
        ) else (
            set "current_net3=%%c"
            call :ScanFourthOctet %net1% %net2% !current_net3!
        )
    ) else (
        set "current_net3=%%c"
        call :ScanFourthOctet %net1% %net2% !current_net3!
    )
)
goto :eof

:ScanFourthOctet
set "net1=%1"
set "net2=%2"
set "net3=%3"

rem Determine start and end for fourth octet
set "fourth_start=1"
set "fourth_end=254"

if %net1% EQU %scan_net1% (
    if %net2% EQU %scan_net2% (
        if %net3% EQU %scan_net3% (
            set "fourth_start=%scan_net4%"
            if !fourth_start! LSS 1 set "fourth_start=1"
        )
    )
)

if %net1% EQU %scan_bcast1% (
    if %net2% EQU %scan_bcast2% (
        if %net3% EQU %scan_bcast3% (
            set "fourth_end=%scan_bcast4%"
            if !fourth_end! GTR 254 set "fourth_end=254"
        )
    )
)

rem Scan the range
for /l %%d in (!fourth_start!,1,!fourth_end!) do (
    set /a "scanned_count+=1"
    
    set "current_ip=%net1%.%net2%.%net3%.%%d"
    
    <nul set /p "=Checking !current_ip! ... "
    
    rem Ping host
    ping -n %ping_count% -w %timeout% !current_ip! | find "TTL" >nul 2>&1
    if !errorlevel!==0 (
        echo ACTIVE
        echo !current_ip! - ACTIVE >> "%output_file%"
        
        rem Get MAC address
        for /f "tokens=1,*" %%a in ('arp -a !current_ip! ^| find "!current_ip!"') do (
            if not "%%b"=="" (
                echo   MAC: %%b
                echo   MAC: %%b >> "%output_file%"
            )
        )
        echo. >> "%output_file%"
        set /a active_hosts+=1
    ) else (
        echo INACTIVE
    )
)
goto :eof

:ScanSimpleRange
for /l %%i in (%start_ip%,1,%end_ip%) do (
    set /a "scanned_count+=1"
    
    set "current_ip=%subnet%.%%i"
    
    <nul set /p "=Checking !current_ip! ... "
    
    rem Ping host
    ping -n %ping_count% -w %timeout% !current_ip! | find "TTL" >nul 2>&1
    if !errorlevel!==0 (
        echo ACTIVE
        echo !current_ip! - ACTIVE >> "%output_file%"
        
        rem Get MAC address
        for /f "tokens=1,*" %%a in ('arp -a !current_ip! ^| find "!current_ip!"') do (
            if not "%%b"=="" (
                echo   MAC: %%b
                echo   MAC: %%b >> "%output_file%"
            )
        )
        echo. >> "%output_file%"
        set /a active_hosts+=1
    ) else (
        echo INACTIVE
    )
)
goto :eof