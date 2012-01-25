
@echo off

rem compile d source and link with compiler objs

dmd aggregate.d arraytypes.d attrib.d cond.d cppmangle.d declaration.d doc.d dsymbol.d ^
    expression.d fakebackend.d hdrgen.d identifier.d init.d inline.d interpret.d ^
    intrange.d irstate.d lexer.d lib.d mars.d mtype.d parse.d statement.d staticassert.d ^
    -version=DMDV2 -c -ofdfiles1.obj
dmd _enum.d _import.d _macro.d _module.d _scope.d _template.d ^
    root\aav.d root\_dchar.d root\lstring.d root\rmem.d root\root.d root\speller.d ^
    root\stringtable.d root\thread.d ^
    -version=DMDV2 -c -ofdfiles2.obj

rem goto end

dmd aav.obj dchar.obj lstring.obj rmem.obj port.obj stringtable.obj root.obj array.obj gnuc.obj man.obj ^
    response.obj async.obj speller.obj ^
    expression.obj statement.obj parse.obj declaration.obj identifier.obj id.obj ^
    dsymbol.obj module.obj html.obj lexer.obj mars.obj cond.obj mtype.obj init.obj opover.obj ^
    attrib.obj template.obj interpret.obj intrange.obj inline.obj dump.obj cast.obj arrayop.obj ^
    optimize.obj doc.obj typinf.obj apply.obj argtypes.obj func.obj json.obj enum.obj import.obj ^
    constfold.obj class.obj struct.obj staticassert.obj clone.obj access.obj impcnvtab.obj ph.obj ^
    builtin.obj hdrgen.obj macro.obj scope.obj canthrow.obj delegatize.obj sideeffect.obj eh.obj ^
    util.obj msc.obj utf.obj inifile.obj link.obj unialpha.obj unittests.obj imphint.obj entity.obj ^
    traits.obj version.obj aliasthis.obj ^
    glue.obj s2ir.obj todt.obj e2ir.obj tocsym.obj tocvdebug.obj mangle.obj toctype.obj toobj.obj ^
    toir.obj libomf.obj irstate.obj ^
    tk.obj ^
    iasm.obj go.obj gdag.obj gother.obj gflow.obj gloop.obj var.obj el.obj newman.obj glocal.obj ^
    os.obj nteh.obj evalu8.obj cgcs.obj rtlsym.obj html.obj cgelem.obj cgen.obj cgreg.obj out.obj ^
    blockopt.obj cgobj.obj cg.obj cgcv.obj type.obj dt.obj debug.obj code.obj cg87.obj cgxmm.obj ^
    cgsched.obj ee.obj csymbol.obj cgcod.obj cod1.obj cod2.obj cod3.obj cod4.obj cod5.obj outbuf.obj ^
    bcomplex.obj ptrntab.obj aa.obj ti_achar.obj md5.obj ti_pvoid.obj ^
    druntime.lib dfiles1.obj dfiles2.obj -ofddmd.exe


:end

