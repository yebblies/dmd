
@echo off

rem **** Build c/c++ source files ****
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\aav.c

dmd -c testroot

dmd testroot root\aav.obj

testroot

