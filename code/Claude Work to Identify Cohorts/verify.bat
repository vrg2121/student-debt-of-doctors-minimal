@echo off
cd /d "%~dp0"

echo === Cohort verification run === > _verify_log.txt
echo Date: %date% %time% >> _verify_log.txt
echo. >> _verify_log.txt

echo Running verification...
python verify_cohorts.py >> _verify_log.txt 2>&1

echo. >> _verify_log.txt
echo === Verification finished === >> _verify_log.txt

echo.
echo Done. Output below:
echo ----------------------------------------------------------------
type _verify_log.txt
echo ----------------------------------------------------------------
echo.
echo (A copy of this output is also saved in _verify_log.txt)
echo.
echo Press any key to close this window...
pause >nul
