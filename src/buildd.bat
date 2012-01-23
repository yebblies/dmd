
@echo off

rem **** Build c/c++ source files ****
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\aav.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\dchar.c

dmd testroot root\aav aav.obj root\_dchar dchar.obj

testroot

