
@echo off

rem **** Build c/c++ source files ****
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\aav.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\dchar.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\lstring.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\rmem.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\port.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\stringtable.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\root.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\array.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\gnuc.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\man.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\response.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\async.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\speller.c

dmd testroot ^
    root\aav root\_dchar root\lstring root\rmem root\root root\speller root\stringtable root\thread ^
    aav.obj dchar.obj lstring.obj rmem.obj port.obj stringtable.obj root.obj array.obj gnuc.obj man.obj ^
    response.obj async.obj speller.obj

testroot

