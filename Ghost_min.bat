@echo off
setlocal 

:start
cls
title [.]
echo Enter first 3 blocks of range (192.168.1, 10.10.10, 127.0.0 etc)
set /p "ip=IP: "
cls
echo Scanning %ip%.0 - %ip%.255
echo.

for /L %%i in (1,1,255) do (
	ping %ip%.%%i -w 10 -n 1 | findstr /i "(0% потерь)" >nul
	if errorlevel 1 (
		title [- %ip%.%%i]
	) else (
		title [+ %ip%.%%i]
		echo [+] %ip%.%%i
		echo %ip%.%%i >> ip_%ip%.X.txt
	)
)

echo.
echo DONE, press any button to restart
pause >nul
goto start
endlocal 
