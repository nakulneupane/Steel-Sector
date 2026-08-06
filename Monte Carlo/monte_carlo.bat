@echo off
setlocal

rem ============================================================================
rem PROBABILISTIC MONTE CARLO: 4 clouds x 25,000 uniform draws (100,000 solves)
rem on the mip-v3 model copy in THIS folder. Sampled per draw (all discrete
rem uniform): theta_tech and theta_grid+ccs {0, 0.1, ..., 1.0}, scrap growth
rem {2, 2.5, ..., 8 %%/yr}, NG price {5, 6, ..., 25}, coal {low,mid,high},
rem gas {bau,shock,policy}; avg_emi 1.8 + Medium ramp fixed; H2 start year
rem defines the cloud.
rem
rem STAGED: each run of this bat solves ONE cloud (~2 h, 10 workers) -- the
rem earliest incomplete one -- then rebuilds the workbook. RUN THIS BAT FOUR
rem TIMES to complete the study. Interruptions are safe (resumable).
rem   monte_carlo.bat 2040   -> force a specific cloud
rem   set MCP_ALL=1          -> all remaining clouds in one go (~8 h)
rem Outputs: results\mcp_results.csv (raw), results\mcp_summary.xlsx (workbook)
rem ============================================================================

set "WORKDIR=C:\Users\Other User\Desktop\Claude\steel-mip\Plots\MC"

cd /d "%WORKDIR%"

if not exist results mkdir results

if not "%~1"=="" set "MCP_CLOUD=%~1"

echo Running probabilistic Monte-Carlo (staged; resumable)...
python mc_run.py
if errorlevel 1 (
    echo mc_run.py reported errors -- inspect results\mcp_results.csv
)

echo.
echo Building Excel workbook...
python mc_pivot.py

echo.
echo ============================
echo DONE (rerun this bat until all four clouds report complete)
echo Raw runs:  results\mcp_results.csv
echo Workbook:  results\mcp_summary.xlsx
echo ============================
pause
