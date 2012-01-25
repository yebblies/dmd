
@echo off

rem compile d source and link with compiler objs

dmd testroot ^
    root\aav root\_dchar root\lstring root\rmem root\root root\speller root\stringtable root\thread ^
    aav.obj dchar.obj lstring.obj rmem.obj port.obj stringtable.obj root.obj array.obj gnuc.obj man.obj ^
    response.obj async.obj speller.obj

testroot

