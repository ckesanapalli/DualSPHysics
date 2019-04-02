@echo off

rem "name" and "dirout" are named according to the testcase

set name=CaseWavemaker2D
set dirout=%name%_CPU_original_out
set diroutdata=%dirout%\data

rem "executables" are renamed and called from their directory

set dirbin=../../../bin/windows
set gencase="%dirbin%/GenCase4_win64.exe"
set dualsphysicscpu="%dirbin%/DualSPHysics4.2CPU_original_win64.exe"
set dualsphysicsgpu="%dirbin%/DualSPHysics4.2_original_win64.exe"
set boundaryvtk="%dirbin%/BoundaryVTK4_win64.exe"
set partvtk="%dirbin%/PartVTK4_win64.exe"
set partvtkout="%dirbin%/PartVTKOut4_win64.exe"
set measuretool="%dirbin%/MeasureTool4_win64.exe"
set computeforces="%dirbin%/ComputeForces4_win64.exe"
set isosurface="%dirbin%/IsoSurface4_win64.exe"
set flowtool="%dirbin%/FlowTool4_win64.exe"
set floatinginfo="%dirbin%/FloatingInfo4_win64.exe"

rem "dirout" is created to store results or it is removed if it already exists

if exist %dirout% rd /s /q %dirout%
mkdir %dirout%
if not "%ERRORLEVEL%" == "0" goto fail
mkdir %diroutdata%

rem a copy of CaseWavemaker2D_Piston_Movement.dat must exist in dirout

copy CaseWavemaker2D_Piston_Movement.dat %dirout%

rem CODES are executed according the selected parameters of execution in this testcase

%gencase% %name%_Def %dirout%/%name% -save:all
if not "%ERRORLEVEL%" == "0" goto fail

%dualsphysicscpu% -cpu %dirout%/%name% %dirout% -dirdataout data -svres
if not "%ERRORLEVEL%" == "0" goto fail

set dirout2=%dirout%\particles
mkdir %dirout2%
%partvtk% -dirin %diroutdata% -savevtk %dirout2%/PartFluid -onlytype:-all,+fluid
if not "%ERRORLEVEL%" == "0" goto fail

%partvtk% -dirin %diroutdata% -savevtk %dirout2%/PartMoving -onlytype:-all,+moving
if not "%ERRORLEVEL%" == "0" goto fail

%partvtk% -dirin %diroutdata% -savevtk %dirout2%/PartBox -onlytype:-all,+fixed
if not "%ERRORLEVEL%" == "0" goto fail

%partvtkout% -dirin %diroutdata% -savevtk %dirout2%/PartFluidOut -SaveResume %dirout2%/_ResumeFluidOut
if not "%ERRORLEVEL%" == "0" goto fail

REM set dirout2=%dirout%\measuretool
REM mkdir %dirout2%
REM %measuretool% -dirin %diroutdata% -points CaseWavemaker2D_wg1_2D.txt -onlytype:-all,+fluid -height -savecsv %dirout2%/_wg1 -savevtk %dirout2%/wg1
REM if not "%ERRORLEVEL%" == "0" goto fail

REM %measuretool% -dirin %diroutdata% -points CaseWavemaker2D_wg2_2D.txt -onlytype:-all,+fluid -height -savecsv %dirout2%/_wg2 -savevtk %dirout2%/wg2
REM if not "%ERRORLEVEL%" == "0" goto fail

REM %measuretool% -dirin %diroutdata% -points CaseWavemaker2D_wg3_2D.txt -onlytype:-all,+fluid -height -savecsv %dirout2%/_wg3 -savevtk %dirout2%/wg3
REM if not "%ERRORLEVEL%" == "0" goto fail
 
REM set dirout2=%dirout%\forces
REM mkdir %dirout2%
REM %computeforces% -dirin %diroutdata% -onlyid:1616-1669 -savecsv %dirout2%/_WallForce -savevtk %dirout2%/WallForce
REM if not "%ERRORLEVEL%" == "0" goto fail
rem Note that initial hydrostatic force is 20.72 N (initial column water 0.065 high) 


:success
echo All done
goto end

:fail
echo Execution aborted.

:end
pause
