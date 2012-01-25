@echo off

rem **** Clear and build generated source ****

del *.obj
del dmd.exe

del impcnvtab.c
dmc -Iroot -cpp impcnvgen
impcnvgen
dmc -c -Iroot -cpp impcnvtab

del elxxx.c cdxxx.c optab.c debtab.c fltables.c tytab.c
dmc -cpp -ooptabgen.exe backend\optabgen -DMARS -Itk
optabgen
copy optab.c backend
copy elxxx.c backend
copy fltables.c backend
copy debtab.c backend
copy cdxxx.c backend
copy tytab.c backend

rem root;backend;tk;.;\dm\include

rem **** Build frontend ****
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp mars -Ae
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp enum
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp struct
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp dsymbol
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp import
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp id
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp staticassert
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp identifier
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp mtype
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp expression
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp optimize
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp template
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp lexer
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp declaration
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp cast
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp init
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp func
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp utf
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp unialpha
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp parse
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp statement
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp constfold
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp version
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp inifile
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp -Ibackend module.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp scope
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp dump
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp cond
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp inline
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp opover
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp entity
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp class
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp mangle
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp attrib
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp link
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp access
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp doc
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp macro
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp hdrgen
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp delegatize
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp interpret
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp traits
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp aliasthis
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp intrange
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp builtin
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp clone
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp libomf
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp arrayop
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp json
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp unittests
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp imphint
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp argtypes
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp apply
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp canthrow
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp sideeffect

rem **** Glue layer ****
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx typinf
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx irstate
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx glue
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx tocsym
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx toobj
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx toctype
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx tocvdebug
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx s2ir
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx todt
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx e2ir
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx msc
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx ph
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx tk.c
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx util
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx eh
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx toir

rem *** iasm is weird ***
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx iasm

rem ******* Build backend ********
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\go
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\gdag
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\gother
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\gflow
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\gloop
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\var
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\el
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\newman
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\glocal
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\os
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\nteh
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\evalu8
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgcs
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\rtlsym
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\html
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgelem
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgen
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgreg
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\out
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\blockopt
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgobj
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cg
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgcv
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\type
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\dt
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\debug
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\code
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cg87
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgxmm
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgsched
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\ee
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\symbol -ocsymbol.obj
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cgcod
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cod1
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cod2
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cod3
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cod4
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\cod5
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\outbuf
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\bcomplex
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\ptrntab
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\aa
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\ti_achar
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\md5
dmc -c -Iroot;backend;tk -DMARS -cpp -D -g -DUNITTEST -e -wx backend\ti_pvoid

rem ******* Build root ********
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\lstring.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\array.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\gnuc.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\man.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\root.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\port.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\stringtable.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\dchar.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\response.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\async.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\speller.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\aav.c
dmc -c -Iroot;\dm\include -D -g -DUNITTEST -cpp root\rmem.c

dmc -odmd.exe mars.obj enum.obj struct.obj dsymbol.obj import.obj id.obj staticassert.obj identifier.obj mtype.obj expression.obj optimize.obj template.obj lexer.obj declaration.obj cast.obj init.obj func.obj utf.obj unialpha.obj parse.obj statement.obj constfold.obj version.obj inifile.obj typinf.obj module.obj scope.obj dump.obj cond.obj inline.obj opover.obj entity.obj class.obj mangle.obj attrib.obj impcnvtab.obj link.obj access.obj doc.obj macro.obj hdrgen.obj delegatize.obj interpret.obj traits.obj aliasthis.obj intrange.obj builtin.obj clone.obj libomf.obj arrayop.obj irstate.obj glue.obj msc.obj ph.obj tk.obj s2ir.obj todt.obj e2ir.obj tocsym.obj util.obj eh.obj toobj.obj toctype.obj tocvdebug.obj toir.obj json.obj unittests.obj imphint.obj argtypes.obj apply.obj canthrow.obj sideeffect.obj go.obj gdag.obj gother.obj gflow.obj gloop.obj var.obj el.obj newman.obj glocal.obj os.obj nteh.obj evalu8.obj cgcs.obj rtlsym.obj html.obj cgelem.obj cgen.obj cgreg.obj out.obj blockopt.obj cgobj.obj cg.obj cgcv.obj type.obj dt.obj debug.obj code.obj cg87.obj cgxmm.obj cgsched.obj ee.obj csymbol.obj cgcod.obj cod1.obj cod2.obj cod3.obj cod4.obj cod5.obj outbuf.obj bcomplex.obj iasm.obj ptrntab.obj aa.obj ti_achar.obj md5.obj ti_pvoid.obj lstring.obj array.obj gnuc.obj man.obj root.obj port.obj stringtable.obj dchar.obj response.obj async.obj speller.obj aav.obj rmem.obj -cpp -mn -Ar -L/ma/co
rem link mars+enum+struct+dsymbol+import+id+staticassert+identifier+mtype+expression+optimize+template+lexer+declaration+cast+init+func+utf+unialpha+parse+statement+constfold+version+inifile+typinf+module+scope+dump+cond+inline+opoverentity+class+mangle+attrib+impcnvtab+link+access+doc+macro+hdrgen+delegatize+interpret+traits+aliasthis+intrange+builtin+clone+libomf+arrayop+irstate+glue+msc+ph+tk+s2ir+todt+e2ir+tocsym+util+eh+toobj+toctype+tocvdebug+toir+json+unittests+imphint+argtypes+apply+canthrow+sideeffect+go+gdag+gother+gflow+gloop+var+el+newman+glocal+os+nteh+evalu8+cgcs+rtlsym+html+cgelem+cgen+cgreg+out+blockopt+cgobj+cg+cgcv+type+dt+debug+code+cg87+cgxmm+cgsched+ee+csymbol+cgcod+cod1+cod2+cod3+cod4+cod5+outbuf+bcomplex+iasm+ptrntab+aa+ti_achar+md5+ti_pvoid+lstring+array+gnuc+man+root+port+stringtable+dchar+response+async+speller+aav+rmem,dmd.exe,,user32+kernel32/noi/ma/co;