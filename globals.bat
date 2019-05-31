@echo off

rem --------------- common -----------------
set AppName=DpkGen
set AppVer=1.0
set AppFullName=DpkGen %AppVer%
set AppUrl=http://www.pazera-software.com/products/dpk-generator/
set AppName_=DpkGen

set AppExe=DpkGen.exe

rem ----------------- 32 bit ---------------------
set AppExe32=DpkGen32.exe
set PortableFileZip32=%AppName_%_PORTABLE_32bit.zip
set CreatePortableZip32=7z a -tzip -mx=9 %PortableFileZip32% %AppExe% README.md *.gif License.txt

rem ----------------- 64 bit ---------------------
set AppExe64=DpkGen64.exe
set PortableFileZip64=%AppName_%_PORTABLE_64bit.zip
set CreatePortableZip64=7z a -tzip -mx=9 %PortableFileZip64% %AppExe% README.md *.gif License.txt