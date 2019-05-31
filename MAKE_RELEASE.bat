@echo off

call globals.bat

::--------------- 32-bit -------------------
if exist %AppExe% del %AppExe%
copy %AppExe32% %AppExe%
%CreatePortableZip32%

::--------------- 64-bit -------------------
if exist %AppExe% del %AppExe%
copy %AppExe64% %AppExe%
%CreatePortableZip64%



::---------------------------------
if exist %AppExe% del %AppExe%
copy %AppExe32% %AppExe%