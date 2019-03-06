#!/bin/bash

# "name" and "dirout" are named according to the testcase

name=CaseWavemaker
dirout=${name}_out

# "executables" are renamed and called from their directory

dirbin=../../../bin/linux
gencase="${dirbin}/GenCase4_linux64"
dualsphysicscpu="${dirbin}/DualSPHysics4.2CPU_linux64"
dualsphysicsgpu="${dirbin}/DualSPHysics4.2_linux64"
boundaryvtk="${dirbin}/BoundaryVTK4_linux64"
partvtk="${dirbin}/PartVTK4_linux64"
partvtkout="${dirbin}/PartVTKOut4_linux64"
measuretool="${dirbin}/MeasureTool4_linux64"
computeforces="${dirbin}/ComputeForces4_linux64"
isosurface="${dirbin}/IsoSurface4_linux64"
flowtool="${dirbin}/FlowTool4_linux64"
floatinginfo="${dirbin}/FloatingInfo4_linux64"

# Library path must be indicated properly

current=$(pwd)
cd ${dirbin}
path_so=$(pwd)
cd $current
export LD_LIBRARY_PATH=$path_so

# "dirout" is created to store results or it is cleaned if it already exists

if [ -e $dirout ]; then
  rm -f -r $dirout
fi
mkdir $dirout
diroutdata=${dirout}/data; mkdir $diroutdata

# CODES are executed according the selected parameters of execution in this testcase
errcode=0

if [ $errcode -eq 0 ]; then
  $gencase ${name}_Def $dirout/$name -save:all
  errcode=$?
fi

dirout2=${dirout}/boundary; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $boundaryvtk -loadvtk $dirout/${name}__Actual.vtk -filexml $dirout/${name}.xml  -savevtkdata $dirout/MotionPREPiston -onlymk:21
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $dualsphysicsgpu $dirout/$name $dirout -dirdataout data -svres -gpu
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $boundaryvtk -loadvtk $dirout/${name}__Actual.vtk -filexml $dirout/${name}.xml -motiondatatime $diroutdata -savevtkdata $dirout2/MotionPiston -onlymk:21 -savevtkdata $dirout2/Box.vtk -onlymk:11
  errcode=$?
fi

dirout2=${dirout}/particles; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $partvtk -dirin $diroutdata -savevtk $dirout2/PartFluid -onlytype:-all,+fluid
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $partvtk -dirin $diroutdata -savevtk $dirout2/PartFluid -onlytype:-all,+moving
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $partvtkout -dirin $diroutdata -savevtk $dirout2/PartFluidOut -SaveResume $dirout2/_ResumeFluidOut
  errcode=$?
fi

dirout2=${dirout}/measuretool; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $measuretool -dirin $diroutdata -points CaseWavemaker_PointsHeights.txt -onlytype:-all,+fluid -height -savevtk $dirout2/PointsHeights -savecsv $dirout2/_PointsHeights
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $measuretool -dirin $diroutdata -points CaseWavemaker_wg0_3D.txt -onlytype:-all,+fluid -height -savecsv $dirout2/_WG0 
  errcode=$?
fi

dirout2=${dirout}/surface; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $isosurface -dirin $diroutdata -saveiso $dirout2/Surface 
  errcode=$?
fi


if [ $errcode -eq 0 ]; then
  echo All done
else
  echo Execution aborted
fi
read -n1 -r -p "Press any key to continue..." key
echo
