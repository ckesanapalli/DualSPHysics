#!/bin/bash

# "name" and "dirout" are named according to the testcase

name=CaseWavemaker2D
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

# a copy of CaseWavemaker2D_Piston_Movement.dat must exist in dirout
cp CaseWavemaker2D_Piston_Movement.dat $dirout

# CODES are executed according the selected parameters of execution in this testcase
errcode=0

if [ $errcode -eq 0 ]; then
  $gencase ${name}_Def $dirout/$name -save:all
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $dualsphysicscpu $dirout/$name $dirout -dirdataout data -svres
  errcode=$?
fi

dirout2=${dirout}/particles; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $partvtk -dirin $diroutdata -savevtk $dirout2/PartFluid -onlytype:-all,+fluid
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $partvtk -dirin $diroutdata -savevtk $dirout2/PartMoving -onlytype:-all,+moving
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $partvtkout -dirin $diroutdata -savevtk $dirout2/PartFluidOut -SaveResume $dirout2/_ResumeFluidOut
  errcode=$?
fi

dirout2=${dirout}/measuretool; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $measuretool -dirin $diroutdata -points CaseWavemaker2D_wg1_2D.txt -onlytype:-all,+fluid -height -savecsv $dirout2/_wg1 -savevtk $dirout2/wg1 
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $measuretool -dirin $diroutdata -points CaseWavemaker2D_wg2_2D.txt -onlytype:-all,+fluid -height -savecsv $dirout2/_wg2 -savevtk $dirout2/wg2 
  errcode=$?
fi

if [ $errcode -eq 0 ]; then
  $measuretool -dirin $diroutdata -points CaseWavemaker2D_wg3_2D.txt -onlytype:-all,+fluid -height -savecsv $dirout2/_wg3 -savevtk $dirout2/wg3 
  errcode=$?
fi

dirout2=${dirout}/forces; mkdir $dirout2
if [ $errcode -eq 0 ]; then
  $computeforces -dirin $diroutdata -onlyid:1616-1669 -savecsv $dirout2/WallForce -savevtk $dirout2/_WallForce
  errcode=$?
fi
# Note that initial hydrostatic force is 20.72 N (initial column water 0.065 high) 

if [ $errcode -eq 0 ]; then
  echo All done
else
  echo Execution aborted
fi
read -n1 -r -p "Press any key to continue..." key
echo
