@echo off
setlocal EnableDelayedExpansion

rem ============================================================================
rem IMPORT-DEPENDENCE sweep: 4 regimes {coking-coal imports Lo/Hi x NG imports
rem Lo/Hi, from the calibrated scarce/abundant availability scenarios} x
rem 4 H2 start years (2030-2045) = 16 runs, cap fixed at 1.8. Prices fixed --
rem pure quantity-dependence. Import bill = coking coal (100%% imported) + NG
rem above the flat domestic supply (50%% of the 2025 cap). Model copy in THIS
rem folder. Outputs: per-run logs + impdep_summary.csv in results\, then
rem impdep_pivot.py builds the workbook and impdep_plot.py the figures.
rem ============================================================================

set "AMPL_EXE=C:\Users\Other User\AMPL\ampl.exe"
set "WORKDIR=C:\Users\Other User\Desktop\Claude\steel-mip\Plots\Import dependence"

cd /d "%WORKDIR%"

if not exist results mkdir results

echo regime,h2_start,solve_result,ccoal_bill,ng_import_bill,import_bill,ng_import_qty,cum_co2,lcop,share_bof,share_cdri,share_ngdri,share_h2,share_scrap,red_h2_2050,ccs_2050> "results\impdep_summary.csv"

set "TEMPFILE=temp_impdep_template.mod"

for %%R in ("HiCoal-HiNG ccoal_abundant.mod ng_policy.mod"
            "HiCoal-LoNG ccoal_abundant.mod ng_bau.mod"
            "LoCoal-HiNG ccoal_scarce.mod ng_policy.mod"
            "LoCoal-LoNG ccoal_scarce.mod ng_bau.mod") do (
    for /f "tokens=1-3" %%A in (%%R) do (
        for %%Y in (2030 2035 2040 2045) do (

            set "LABEL=%%A_h2%%Y"
            set "OUTFILE=results\!LABEL!.txt"

            echo.
            echo =====================================
            echo Running !LABEL!
            echo =====================================

            copy /Y impdep_template.mod "!TEMPFILE!" >nul

            powershell -NoProfile -Command "(Get-Content '!TEMPFILE!') | ForEach-Object { $_ -replace 'REGLABEL','%%A' -replace 'IMPCCOALFILE','scenarios/%%B' -replace 'IMPNGFILE','scenarios/%%C' -replace 'H2YRVAL','%%Y' } | Set-Content '!TEMPFILE!'"

            "%AMPL_EXE%" "!TEMPFILE!" > "!OUTFILE!" 2>&1

        )
    )
)

del "%TEMPFILE%" >nul 2>&1

echo.
echo Building Excel workbook and figures...
python impdep_pivot.py
python impdep_plot.py

echo.
echo ============================
echo ALL RUNS FINISHED
echo Summary CSV:  results\impdep_summary.csv
echo Workbook:     results\impdep_summary.xlsx
echo Figures:      fig_impdep_mix.png, fig_impdep_scatter.png
echo ============================
pause
