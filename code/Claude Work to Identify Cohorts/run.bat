@echo off
cd /d "%~dp0"

echo === Cohort assignment run === > _run_log.txt
echo Date: %date% %time% >> _run_log.txt
echo. >> _run_log.txt

echo Step 1 of 3: Checking Python installation...
python --version >> _run_log.txt 2>&1

echo Step 2 of 3: Installing pandas (first run only)...
python -m pip install pandas --disable-pip-version-check >> _run_log.txt 2>&1

echo Step 3 of 3: Running cohort assignment...
echo. >> _run_log.txt
echo --- compute_cohorts.py output --- >> _run_log.txt
python compute_cohorts.py >> _run_log.txt 2>&1

echo. >> _run_log.txt
echo === Run finished === >> _run_log.txt

echo.
echo Done. Full output below:
echo ----------------------------------------------------------------
type _run_log.txt
echo ----------------------------------------------------------------
echo.
echo (A copy of this output is also saved in _run_log.txt)
echo.
echo Press any key to close this window...
pause >nul
