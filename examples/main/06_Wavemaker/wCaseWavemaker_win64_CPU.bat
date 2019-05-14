@echo off

rem "name" and "dirout" are named according to the testcase

set name=CaseWavemaker
set dirout=%name%_out
set diroutdata=%dirout%\data

rem "executables" are renamed and called from their directory

set dirbin=../../../bin/windows
set gencase="%dirbin%/GenCase4_win64.exe"
set dualsphysicscpu="%dirbin%/DualSPHysics4.2CPU_win64.exe"
set dualsphysicsgpu="%dirbin%/DualSPHysics4.2_win64.exe"
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

rem CODES are executed according the selected parameters of execution in this testcase

%gencase% %name%_Def %dirout%/%name% -save:all
if not "%ERRORLEVEL%" == "0" goto fail

set dirout2=%dirout%\boundary
mkdir %dirout2%
%boundaryvtk% -loadvtk %dirout%/%name%__Actual.vtk -filexml %dirout%/%name%.xml -savevtkdata %dirout2%/MotionPREPiston -onlymk:21  
if not "%ERRORLEVEL%" == "0" goto fail

%dualsphysicscpu% -cpu %dirout%/%name% %dirout% -dirdataout data -svres
if not "%ERRORLEVEL%" == "0" goto fail

%boundaryvtk% -loadvtk %dirout%/%name%__Actual.vtk -filexml %dirout%/%name%.xml -motiondatatime %diroutdata% -savevtkdata %dirout2%/MotionPiston -onlymk:21 -savevtkdata %dirout2%/Box.vtk -onlymk:11
if not "%ERRORLEVEL%" == "0" goto fail

set dirout2=%dirout%\particles
mkdir %dirout2%
%partvtk% -dirin %diroutdata% -savevtk %dirout2%/PartFLuid -onlytype:-all,+fluid
if not "%ERRORLEVEL%" == "0" goto fail

%partvtk% -dirin %diroutdata% -savevtk %dirout2%/PartPiston -onlytype:-all,+moving
if not "%ERRORLEVEL%" == "0" goto fail

%partvtkout% -dirin %diroutdata% -savevtk %dirout2%/PartFluidOut -SaveResume %dirout2%/_ResumeFluidOut
if not "%ERRORLEVEL%" == "0" goto fail

set dirout2=%dirout%\measuretool
mkdir %dirout2%
%measuretool% -dirin %diroutdata% -points CaseWavemaker_PointsHeights.txt -onlytype:-all,+fluid -height -savevtk %dirout2%/PointsHeights -savecsv %dirout2%/_PointsHeight 
if not "%ERRORLEVEL%" == "0" goto fail

%measuretool% -dirin %diroutdata% -points CaseWavemaker_wg0_3D.txt -onlytype:-all,+fluid -height -savecsv %dirout2%/_WG0 
if not "%ERRORLEVEL%" == "0" goto fail

set dirout2=%dirout%\surface
mkdir %dirout2%
%isosurface% -dirin %diroutdata% -saveiso %dirout2%/Surface 
if not "%ERRORLEVEL%" == "0" goto fail


:success
echo All done
goto end

:fail
echo Execution aborted.

:end
pause

