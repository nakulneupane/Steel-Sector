@echo off
setlocal

rem ============================================================================
rem H2-COMMITMENT study over SAMPLED WORLDS: the same four commitment
rem programs (plans/plan_c2030..2045), evaluated over the first 100 seeded
rem MC draws per H2-arrival cloud (400 worlds; identical seeds to Plots/MC).
rem Per world: PF + 4 norec + 4 recourse epochs A (2035) + 4 final (2045)
rem = ~5,200 solves, plus the panel-c frontier sweep (4 clouds x 5 targets
rem x 100 worlds = 2,000 flexible solves) -> ~7,200 total, ~25-40 min.
rem
rem RESUMABLE: rerun this bat after any interruption -- completed run_ids
rem are skipped (epoch-A rows re-solve if their window file is missing).
rem Requires the single-world study to have run once (commit.bat) so the
rem plan files and their signed LCOPs exist.
rem ============================================================================

set "WORKDIR=C:\Users\Other User\Desktop\Claude\steel-mip\Plots\NewRegret"
set "MC_WORKERS=10"
set "REG_WORLDS=100"

cd /d "%WORKDIR%"
if not exist results mkdir results

echo [1/2] Solving PF, no-recourse and recourse epochs over 400 worlds...
python commit_mc_run.py
if errorlevel 1 echo commit_mc_run.py reported errors -- inspect results\commit_mc_results.csv

echo.
echo [2/2] Rendering the 2x2 figure and workbooks...
python commit_mc_plot.py
if errorlevel 1 echo commit_mc_plot.py failed -- is results\commit_mc_plots.xlsx open in Excel?

echo.
echo ============================
echo DONE
echo Results:  results\commit_mc_results.csv / commit_mc_results.xlsx
echo Workbook: results\commit_mc_plots.xlsx (figure data + filters + ER)
echo Figure:   fig_commit_mc_2x2.png / .pdf
echo ============================
pause
