# get OS and MODEL
include osmodel.mak

ifeq (,$(TARGET_CPU))
    $(info no cpu specified, assuming X86)
    TARGET_CPU=X86
endif

ifeq (X86,$(TARGET_CPU))
    TARGET_CH = $C/code_x86.h
    TARGET_OBJS = cg87.o cgxmm.o cgsched.o cod1.o cod2.o cod3.o cod4.o ptrntab.o
else
    ifeq (stub,$(TARGET_CPU))
        TARGET_CH = $C/code_stub.h
        TARGET_OBJS = platform_stub.o
    else
        $(error unknown TARGET_CPU: '$(TARGET_CPU)')
    endif
endif

INSTALL_DIR=../../install
# can be set to override the default /etc/
SYSCONFDIR=/etc/

C=backend
TK=tk
ROOT=root

ifeq (osx,$(OS))
    export MACOSX_DEPLOYMENT_TARGET=10.3
endif
LDFLAGS=-lm -lstdc++ -lpthread

#ifeq (osx,$(OS))
#	HOST_CC=clang++
#else
	HOST_CC=g++
#endif
CC=$(HOST_CC) $(MODEL_FLAG)
GIT=git

#COV=-fprofile-arcs -ftest-coverage
#PROFILE=-pg

WARNINGS=-Wno-deprecated -Wstrict-aliasing
MMD=-MMD -MF $(basename $@).deps

ifneq (,$(DEBUG))
	GFLAGS=$(WARNINGS) -D__pascal= -fno-exceptions -g -g3 -DDEBUG=1 -DUNITTEST $(COV) $(PROFILE) $(MMD) -fno-rtti
else
	GFLAGS=$(WARNINGS) -D__pascal= -fno-exceptions -O2 $(PROFILE) $(MMD) -fno-rtti
endif

OS_UPCASE:=$(shell echo $(OS) | tr '[a-z]' '[A-Z]')
CFLAGS = $(GFLAGS) -I$(ROOT) -DMARS=1 -DTARGET_$(OS_UPCASE)=1 -DDM_TARGET_CPU_$(TARGET_CPU)=1
MFLAGS = $(GFLAGS) -I$C -I$(TK) -I$(ROOT) -DMARS=1 -DTARGET_$(OS_UPCASE)=1 -DDM_TARGET_CPU_$(TARGET_CPU)=1 -DDMDV2=1

DMD_OBJS = \
	access.o attrib.o \
	cast.o \
	class.o \
	constfold.o cond.o \
	declaration.o dsymbol.o \
	enum.o expression.o func.o nogc.o \
	id.o \
	identifier.o impcnvtab.o import.o inifile.o init.o inline.o \
	lexer.o link.o mangle.o mars.o module.o mtype.o \
	cppmangle.o opover.o optimize.o \
	parse.o scope.o statement.o \
	struct.o template.o \
	version.o strtold.o utf.o staticassert.o \
	entity.o doc.o macro.o \
	hdrgen.o delegatize.o interpret.o traits.o \
	builtin.o ctfeexpr.o clone.o aliasthis.o \
	arrayop.o async.o json.o unittests.o \
	imphint.o argtypes.o apply.o sapply.o sideeffect.o \
	intrange.o canthrow.o target.o

ROOT_OBJS = \
	rmem.o port.o man.o stringtable.o response.o \
	aav.o speller.o outbuffer.o object.o \
	filename.o file.o

GLUE_OBJS = \
	glue.o msc.o s2ir.o todt.o e2ir.o tocsym.o \
	toobj.o toctype.o toelfdebug.o toir.o \
	irstate.o typinf.o iasm.o

ifeq (osx,$(OS))
    GLUE_OBJS += libmach.o scanmach.o
else
    GLUE_OBJS += libelf.o scanelf.o
endif

#GLUE_OBJS=gluestub.o

BACK_OBJS = go.o gdag.o gother.o gflow.o gloop.o var.o el.o \
	glocal.o os.o nteh.o evalu8.o cgcs.o \
	rtlsym.o cgelem.o cgen.o cgreg.o out.o \
	blockopt.o cg.o type.o dt.o \
	debug.o code.o ee.o csymbol.o \
	cgcod.o cod5.o outbuf.o \
	bcomplex.o aa.o ti_achar.o \
	ti_pvoid.o pdata.o cv8.o backconfig.o \
	divcoeff.o dwarf.o \
	ph2.o util2.o eh.o tk.o \
	$(TARGET_OBJS)

ifeq (osx,$(OS))
	BACK_OBJS += machobj.o
else
	BACK_OBJS += elfobj.o
endif

SRC = win32.mak posix.mak osmodel.mak \
	mars.c enum.c struct.c dsymbol.c import.c idgen.c impcnvgen.c \
	identifier.c mtype.c expression.c optimize.c template.h \
	template.c lexer.c declaration.c cast.c cond.h cond.c link.c \
	aggregate.h parse.c statement.c constfold.c version.h version.c \
	inifile.c module.c scope.c init.h init.c attrib.h \
	attrib.c opover.c class.c mangle.c func.c nogc.c inline.c \
	access.c complex_t.h \
	identifier.h parse.h \
	scope.h enum.h import.h mars.h module.h mtype.h dsymbol.h \
	declaration.h lexer.h expression.h statement.h \
	utf.h utf.c staticassert.h staticassert.c \
	entity.c \
	doc.h doc.c macro.h macro.c hdrgen.h hdrgen.c arraytypes.h \
	delegatize.c interpret.c traits.c cppmangle.c \
	builtin.c clone.c lib.h arrayop.c \
	aliasthis.h aliasthis.c json.h json.c unittests.c imphint.c \
	argtypes.c apply.c sapply.c sideeffect.c \
	intrange.h intrange.c canthrow.c target.c target.h \
	scanmscoff.c scanomf.c ctfe.h ctfeexpr.c \
	ctfe.h ctfeexpr.c visitor.h

ROOT_SRC = $(ROOT)/root.h \
	$(ROOT)/array.h \
	$(ROOT)/rmem.h $(ROOT)/rmem.c $(ROOT)/port.h $(ROOT)/port.c \
	$(ROOT)/man.c \
	$(ROOT)/stringtable.h $(ROOT)/stringtable.c \
	$(ROOT)/response.c $(ROOT)/async.h $(ROOT)/async.c \
	$(ROOT)/aav.h $(ROOT)/aav.c \
	$(ROOT)/longdouble.h $(ROOT)/longdouble.c \
	$(ROOT)/speller.h $(ROOT)/speller.c \
	$(ROOT)/outbuffer.h $(ROOT)/outbuffer.c \
	$(ROOT)/object.h $(ROOT)/object.c \
	$(ROOT)/filename.h $(ROOT)/filename.c \
	$(ROOT)/file.h $(ROOT)/file.c

GLUE_SRC = glue.c msc.c s2ir.c todt.c e2ir.c tocsym.c \
	toobj.c toctype.c tocvdebug.c toir.h toir.c \
	libmscoff.c scanmscoff.c irstate.h irstate.c typinf.c iasm.c \
	toelfdebug.c libomf.c scanomf.c libelf.c scanelf.c libmach.c scanmach.c \
	tk.c eh.c gluestub.c

BACK_SRC = \
	$C/cdef.h $C/cc.h $C/oper.h $C/ty.h $C/optabgen.c \
	$C/global.h $C/code.h $C/type.h $C/dt.h $C/cgcv.h \
	$C/el.h $C/iasm.h $C/rtlsym.h \
	$C/bcomplex.c $C/blockopt.c $C/cg.c $C/cg87.c $C/cgxmm.c \
	$C/cgcod.c $C/cgcs.c $C/cgcv.c $C/cgelem.c $C/cgen.c $C/cgobj.c \
	$C/cgreg.c $C/var.c $C/strtold.c \
	$C/cgsched.c $C/cod1.c $C/cod2.c $C/cod3.c $C/cod4.c $C/cod5.c \
	$C/code.c $C/symbol.c $C/debug.c $C/dt.c $C/ee.c $C/el.c \
	$C/evalu8.c $C/go.c $C/gflow.c $C/gdag.c \
	$C/gother.c $C/glocal.c $C/gloop.c $C/newman.c \
	$C/nteh.c $C/os.c $C/out.c $C/outbuf.c $C/ptrntab.c $C/rtlsym.c \
	$C/type.c $C/melf.h $C/mach.h $C/mscoff.h $C/bcomplex.h \
	$C/cdeflnx.h $C/outbuf.h $C/token.h $C/tassert.h \
	$C/elfobj.c $C/cv4.h $C/dwarf2.h $C/exh.h $C/go.h \
	$C/dwarf.c $C/dwarf.h $C/aa.h $C/aa.c $C/tinfo.h $C/ti_achar.c \
	$C/ti_pvoid.c $C/platform_stub.c $C/code_x86.h $C/code_stub.h \
	$C/machobj.c $C/mscoffobj.c \
	$C/xmm.h $C/obj.h $C/pdata.c $C/cv8.c $C/backconfig.c $C/divcoeff.c \
	$C/md5.c $C/md5.h \
	$C/ph2.c $C/util2.c \
	$(TARGET_CH)

TK_SRC = \
	$(TK)/filespec.h $(TK)/mem.h $(TK)/list.h $(TK)/vec.h \
	$(TK)/filespec.c $(TK)/mem.c $(TK)/vec.c $(TK)/list.c

DMD_DEPS:=$(DMD_OBJS:.o=.deps)

all: dmd

frontend.a: $(DMD_OBJS)
	ar rcs frontend.a $(DMD_OBJS)

root.a: $(ROOT_OBJS)
	ar rcs root.a $(ROOT_OBJS)

glue.a: $(GLUE_OBJS)
	ar rcs glue.a $(GLUE_OBJS)

backend.a: $(BACK_OBJS)
	ar rcs backend.a $(BACK_OBJS)

dmd: frontend.a root.a glue.a backend.a
	$(HOST_CC) -o dmd $(MODEL_FLAG) $(COV) $(PROFILE) frontend.a root.a glue.a backend.a $(LDFLAGS)

clean:
	rm -f $(DMD_OBJS) $(ROOT_OBJS) $(GLUE_OBJS) $(BACK_OBJS) dmd optab.o id.o impcnvgen idgen id.c id.h \
	impcnvtab.c optabgen debtab.c optab.c cdxxx.c elxxx.c fltables.c \
	tytab.c verstr.h core \
	*.cov *.deps *.gcda *.gcno *.a \
	$(GENSRC)

######## optabgen generates some source

optabgen: $C/optabgen.c $C/cc.h $C/oper.h
	$(CC) $(MFLAGS) $< -o optabgen
	./optabgen

optabgen_output = debtab.c optab.c cdxxx.c elxxx.c fltables.c tytab.c
$(optabgen_output) : optabgen

######## idgen generates some source

idgen_output = id.h id.c
$(idgen_output) : idgen

idgen : idgen.c
	$(CC) idgen.c -o idgen
	./idgen

######### impcnvgen generates some source

impcnvtab_output = impcnvtab.c
$(impcnvtab_output) : impcnvgen

impcnvgen : mtype.h impcnvgen.c
	$(CC) $(CFLAGS) impcnvgen.c -o impcnvgen
	./impcnvgen

#########

# Create (or update) the verstr.h file.
# The file is only updated if the VERSION file changes, or, only when RELEASE=1
# is not used, when the full version string changes (i.e. when the git hash or
# the working tree dirty states changes).
# The full version string have the form VERSION-devel-HASH(-dirty).
# The "-dirty" part is only present when the repository had uncommitted changes
# at the moment it was compiled (only files already tracked by git are taken
# into account, untracked files don't affect the dirty state).
VERSION := $(shell cat ../VERSION)
ifneq (1,$(RELEASE))
VERSION_GIT := $(shell printf "`$(GIT) rev-parse --short HEAD`"; \
       test -n "`$(GIT) status --porcelain -uno`" && printf -- -dirty)
VERSION := $(addsuffix -devel$(if $(VERSION_GIT),-$(VERSION_GIT)),$(VERSION))
endif
$(shell test \"$(VERSION)\" != "`cat verstr.h 2> /dev/null`" \
		&& printf \"$(VERSION)\" > verstr.h )

#########

$(DMD_OBJS) $(GLUE_OBJS) : $(idgen_output) $(impcnvgen_output)
$(BACK_OBJS) : $(optabgen_output)

aa.o: $C/aa.c
	$(CC) -c $(MFLAGS) -I. $<

aav.o: $(ROOT)/aav.c
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

access.o: access.c
	$(CC) -c $(CFLAGS) $<

aliasthis.o: aliasthis.c
	$(CC) -c $(CFLAGS) $<

apply.o: apply.c
	$(CC) -c $(CFLAGS) $<

argtypes.o: argtypes.c
	$(CC) -c $(CFLAGS) $<

arrayop.o: arrayop.c
	$(CC) -c $(CFLAGS) $<

async.o: $(ROOT)/async.c
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

attrib.o: attrib.c
	$(CC) -c $(CFLAGS) $<

backconfig.o: $C/backconfig.c
	$(CC) -c $(MFLAGS) $<

bcomplex.o: $C/bcomplex.c
	$(CC) -c $(MFLAGS) $<

blockopt.o: $C/blockopt.c
	$(CC) -c $(MFLAGS) $<

builtin.o: builtin.c
	$(CC) -c $(CFLAGS) $<

canthrow.o: canthrow.c
	$(CC) -c $(CFLAGS) $<

cast.o: cast.c
	$(CC) -c $(CFLAGS) $<

cg.o: $C/cg.c fltables.c
	$(CC) -c $(MFLAGS) -I. $<

cg87.o: $C/cg87.c
	$(CC) -c $(MFLAGS) $<

cgcod.o: $C/cgcod.c cdxxx.c
	$(CC) -c $(MFLAGS) -I. $<

cgcs.o: $C/cgcs.c
	$(CC) -c $(MFLAGS) $<

cgcv.o: $C/cgcv.c
	$(CC) -c $(MFLAGS) $<

cgelem.o: $C/cgelem.c elxxx.c
	$(CC) -c $(MFLAGS) -I. $<

cgen.o: $C/cgen.c
	$(CC) -c $(MFLAGS) $<

cgobj.o: $C/cgobj.c
	$(CC) -c $(MFLAGS) $<

cgreg.o: $C/cgreg.c
	$(CC) -c $(MFLAGS) $<

cgsched.o: $C/cgsched.c
	$(CC) -c $(MFLAGS) $<

cgxmm.o: $C/cgxmm.c
	$(CC) -c $(MFLAGS) $<

class.o: class.c
	$(CC) -c $(CFLAGS) $<

clone.o: clone.c
	$(CC) -c $(CFLAGS) $<

cod1.o: $C/cod1.c
	$(CC) -c $(MFLAGS) $<

cod2.o: $C/cod2.c
	$(CC) -c $(MFLAGS) $<

cod3.o: $C/cod3.c
	$(CC) -c $(MFLAGS) $<

cod4.o: $C/cod4.c
	$(CC) -c $(MFLAGS) $<

cod5.o: $C/cod5.c
	$(CC) -c $(MFLAGS) $<

code.o: $C/code.c
	$(CC) -c $(MFLAGS) $<

constfold.o: constfold.c
	$(CC) -c $(CFLAGS) $<

ctfeexpr.o: ctfeexpr.c
	$(CC) -c $(CFLAGS) $<

irstate.o: irstate.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

csymbol.o: $C/symbol.c
	$(CC) -c $(MFLAGS) $< -o $@

cond.o: cond.c
	$(CC) -c $(CFLAGS) $<

cppmangle.o: cppmangle.c
	$(CC) -c $(CFLAGS) $<

cv8.o: $C/cv8.c
	$(CC) -c $(MFLAGS) $<

debug.o: $C/debug.c debtab.c
	$(CC) -c $(MFLAGS) -I. $<

declaration.o: declaration.c
	$(CC) -c $(CFLAGS) $<

delegatize.o: delegatize.c
	$(CC) -c $(CFLAGS) $<

divcoeff.o: $C/divcoeff.c
	$(CC) -c $(MFLAGS) $<

doc.o: doc.c
	$(CC) -c $(CFLAGS) $<

dsymbol.o: dsymbol.c
	$(CC) -c $(CFLAGS) $<

dt.o: $C/dt.c
	$(CC) -c $(MFLAGS) $<

dwarf.o: $C/dwarf.c
	$(CC) -c $(MFLAGS) -I. $<

e2ir.o: e2ir.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

ee.o: $C/ee.c
	$(CC) -c $(MFLAGS) $<

eh.o: eh.c
	$(CC) -c $(MFLAGS) $<

el.o: $C/el.c
	$(CC) -c $(MFLAGS) $<

elfobj.o: $C/elfobj.c
	$(CC) -c $(MFLAGS) $<

entity.o: entity.c
	$(CC) -c $(CFLAGS) $<

enum.o: enum.c
	$(CC) -c $(CFLAGS) $<

evalu8.o: $C/evalu8.c
	$(CC) -c $(MFLAGS) $<

expression.o: expression.c
	$(CC) -c $(CFLAGS) $<

file.o : $(ROOT)/file.c
	$(CC) -c $(CFLAGS) -I$(ROOT) $<

filename.o : $(ROOT)/filename.c
	$(CC) -c $(CFLAGS) -I$(ROOT) $<

func.o: func.c
	$(CC) -c $(CFLAGS) $<

nogc.o: nogc.c
	$(CC) -c $(CFLAGS) $<

gdag.o: $C/gdag.c
	$(CC) -c $(MFLAGS) $<

gflow.o: $C/gflow.c
	$(CC) -c $(MFLAGS) $<

#globals.o: globals.c
#	$(CC) -c $(CFLAGS) $<

glocal.o: $C/glocal.c
	$(CC) -c $(MFLAGS) $<

gloop.o: $C/gloop.c
	$(CC) -c $(MFLAGS) $<

glue.o: glue.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

go.o: $C/go.c
	$(CC) -c $(MFLAGS) $<

gother.o: $C/gother.c
	$(CC) -c $(MFLAGS) $<

hdrgen.o: hdrgen.c
	$(CC) -c $(CFLAGS) $<

iasm.o: iasm.c
	$(CC) -c $(MFLAGS) -I$(ROOT) -fexceptions $<

id.o: id.c
	$(CC) -c $(CFLAGS) $<

identifier.o: identifier.c
	$(CC) -c $(CFLAGS) $<

impcnvtab.o: impcnvtab.c
	$(CC) -c $(CFLAGS) -I$(ROOT) $<

imphint.o: imphint.c
	$(CC) -c $(CFLAGS) $<

import.o: import.c
	$(CC) -c $(CFLAGS) $<

inifile.o: inifile.c
	$(CC) -c $(CFLAGS) -DSYSCONFDIR='"$(SYSCONFDIR)"' $<

init.o: init.c
	$(CC) -c $(CFLAGS) $<

inline.o: inline.c
	$(CC) -c $(CFLAGS) $<

interpret.o: interpret.c
	$(CC) -c $(CFLAGS) $<

intrange.o: intrange.c
	$(CC) -c $(CFLAGS) $<

json.o: json.c
	$(CC) -c $(CFLAGS) $<

lexer.o: lexer.c
	$(CC) -c $(CFLAGS) $<

libelf.o: libelf.c
	$(CC) -c $(CFLAGS) -I$C $<

libmach.o: libmach.c
	$(CC) -c $(CFLAGS) -I$C $<

libmscoff.o: libmscoff.c
	$(CC) -c $(CFLAGS) -I$C $<

link.o: link.c
	$(CC) -c $(CFLAGS) $<

machobj.o: $C/machobj.c
	$(CC) -c $(MFLAGS) -I. $<

macro.o: macro.c
	$(CC) -c $(CFLAGS) $<

man.o: $(ROOT)/man.c
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

mangle.o: mangle.c
	$(CC) -c $(CFLAGS) $<

mars.o: mars.c verstr.h
	$(CC) -c $(CFLAGS) $<

rmem.o: $(ROOT)/rmem.c
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

module.o: module.c
	$(CC) -c $(CFLAGS) -I$C $<

mscoffobj.o: $C/mscoffobj.c
	$(CC) -c $(MFLAGS) $<

msc.o: msc.c
	$(CC) -c $(MFLAGS) $<

mtype.o: mtype.c
	$(CC) -c $(CFLAGS) $<

nteh.o: $C/nteh.c
	$(CC) -c $(MFLAGS) $<

object.o : $(ROOT)/object.c
	$(CC) -c $(CFLAGS) -I$(ROOT) $<

opover.o: opover.c
	$(CC) -c $(CFLAGS) $<

optimize.o: optimize.c
	$(CC) -c $(CFLAGS) $<

os.o: $C/os.c
	$(CC) -c $(MFLAGS) $<

out.o: $C/out.c
	$(CC) -c $(MFLAGS) $<

outbuf.o: $C/outbuf.c
	$(CC) -c $(MFLAGS) $<

outbuffer.o : $(ROOT)/outbuffer.c
	$(CC) -c $(CFLAGS) -I$(ROOT) $<

parse.o: parse.c
	$(CC) -c $(CFLAGS) $<

pdata.o: $C/pdata.c
	$(CC) -c $(MFLAGS) $<

ph2.o: $C/ph2.c
	$(CC) -c $(MFLAGS) $<

platform_stub.o: $C/platform_stub.c
	$(CC) -c $(MFLAGS) $<

port.o: $(ROOT)/port.c
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

ptrntab.o: $C/ptrntab.c
	$(CC) -c $(MFLAGS) $<

response.o: $(ROOT)/response.c
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

rtlsym.o: $C/rtlsym.c
	$(CC) -c $(MFLAGS) $<

sapply.o: sapply.c
	$(CC) -c $(CFLAGS) $<

s2ir.o: s2ir.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

scanelf.o: scanelf.c
	$(CC) -c $(CFLAGS) -I$C $<

scanmach.o: scanmach.c
	$(CC) -c $(CFLAGS) -I$C $<

scope.o: scope.c
	$(CC) -c $(CFLAGS) $<

sideeffect.o: sideeffect.c
	$(CC) -c $(CFLAGS) $<

speller.o: $(ROOT)/speller.c
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

statement.o: statement.c
	$(CC) -c $(CFLAGS) $<

staticassert.o: staticassert.c
	$(CC) -c $(CFLAGS) $<

stringtable.o: $(ROOT)/stringtable.c
	$(CC) -c $(GFLAGS) -I$(ROOT) $<

strtold.o: $C/strtold.c
	$(CC) -c -I$(ROOT) $<

struct.o: struct.c
	$(CC) -c $(CFLAGS) $<

target.o: target.c
	$(CC) -c $(CFLAGS) $<

template.o: template.c
	$(CC) -c $(CFLAGS) $<

ti_achar.o: $C/ti_achar.c
	$(CC) -c $(MFLAGS) -I. $<

ti_pvoid.o: $C/ti_pvoid.c
	$(CC) -c $(MFLAGS) -I. $<

tk.o: tk.c
	$(CC) -c $(MFLAGS) $<

tocsym.o: tocsym.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

toctype.o: toctype.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

todt.o: todt.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

toelfdebug.o: toelfdebug.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

toir.o: toir.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

toobj.o: toobj.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

traits.o: traits.c
	$(CC) -c $(CFLAGS) $<

type.o: $C/type.c
	$(CC) -c $(MFLAGS) $<

typinf.o: typinf.c
	$(CC) -c $(MFLAGS) -I$(ROOT) $<

util2.o: $C/util2.c
	$(CC) -c $(MFLAGS) $<

utf.o: utf.c
	$(CC) -c $(CFLAGS) $<

unittests.o: unittests.c
	$(CC) -c $(CFLAGS) $<

var.o: $C/var.c optab.c tytab.c
	$(CC) -c $(MFLAGS) -I. $<

version.o: version.c
	$(CC) -c $(CFLAGS) $<

-include $(DMD_DEPS)

######################################################

install: all
	mkdir -p $(INSTALL_DIR)/bin
	cp dmd $(INSTALL_DIR)/bin/dmd
	$(eval bin_dir=$(if $(filter $(OS),osx), bin, bin$(MODEL)))
	cp ../ini/$(OS)/$(bin_dir)/dmd.conf $(INSTALL_DIR)/bin/dmd.conf
	cp backendlicense.txt $(INSTALL_DIR)/dmd-backendlicense.txt
	cp artistic.txt $(INSTALL_DIR)/dmd-artistic.txt

######################################################

gcov:
	gcov access.c
	gcov aliasthis.c
	gcov apply.c
	gcov arrayop.c
	gcov attrib.c
	gcov builtin.c
	gcov canthrow.c
	gcov cast.c
	gcov class.c
	gcov clone.c
	gcov cond.c
	gcov constfold.c
	gcov declaration.c
	gcov delegatize.c
	gcov doc.c
	gcov dsymbol.c
	gcov e2ir.c
	gcov eh.c
	gcov entity.c
	gcov enum.c
	gcov expression.c
	gcov func.c
	gcov nogc.c
	gcov glue.c
	gcov iasm.c
	gcov identifier.c
	gcov imphint.c
	gcov import.c
	gcov inifile.c
	gcov init.c
	gcov inline.c
	gcov interpret.c
	gcov ctfeexpr.c
	gcov irstate.c
	gcov json.c
	gcov lexer.c
ifeq (osx,$(OS))
	gcov libmach.c
else
	gcov libelf.c
endif
	gcov link.c
	gcov macro.c
	gcov mangle.c
	gcov mars.c
	gcov module.c
	gcov msc.c
	gcov mtype.c
	gcov opover.c
	gcov optimize.c
	gcov parse.c
	gcov scope.c
	gcov sideeffect.c
	gcov statement.c
	gcov staticassert.c
	gcov s2ir.c
	gcov struct.c
	gcov template.c
	gcov tk.c
	gcov tocsym.c
	gcov todt.c
	gcov toobj.c
	gcov toctype.c
	gcov toelfdebug.c
	gcov typinf.c
	gcov utf.c
	gcov version.c
	gcov intrange.c
	gcov target.c

#	gcov hdrgen.c
#	gcov tocvdebug.c

######################################################

zip:
	-rm -f dmdsrc.zip
	zip dmdsrc $(SRC) $(ROOT_SRC) $(GLUE_SRC) $(BACK_SRC) $(TK_SRC)


############################# DDMD stuff ############################

MAGICPORT = ../../magicport2/magicport2

GENSRC=access.d aggregate.d aliasthis.d apply.d \
	argtypes.d arrayop.d arraytypes.d \
	attrib.d builtin.d canthrow.d dcast.d \
	dclass.d clone.d cond.d constfold.d \
	cppmangle.d ctfeexpr.d declaration.d \
	delegatize.d doc.d dsymbol.d \
	denum.d expression.d func.d \
	hdrgen.d id.d identifier.d imphint.d \
	dimport.d dinifile.d inline.d init.d \
	dinterpret.d json.d lexer.d link.d \
	dmacro.d dmangle.d mars.d \
	dmodule.d mtype.d opover.d optimize.d \
	parse.d sapply.d dscope.d sideeffect.d \
	statement.d staticassert.d dstruct.d \
	target.d dtemplate.d traits.d dunittest.d \
	utf.d dversion.d visitor.d lib.d \
	nogc.d \
	$(ROOT)/file.d $(ROOT)/filename.d $(ROOT)/speller.d

MANUALSRC= \
	intrange.d complex.d longdouble.d \
	libomf.d scanomf.d \
	libmscoff.d scanmscoff.d \
	libelf.d scanelf.d \
	libmach.d scanmach.d \
	entity.d \
	$(ROOT)/aav.d $(ROOT)/array.d \
	$(ROOT)/man.d $(ROOT)/rootobject.d $(ROOT)/outbuffer.d $(ROOT)/port.d \
	$(ROOT)/response.d $(ROOT)/rmem.d  $(ROOT)/stringtable.d

$(GENSRC) : $(SRCS) $(ROOTSRC) settings.json
	$(MAGICPORT) . .

DSRC= $(GENSRC) $(MANUALSRC)

ddmd: dmd $(DSRC) glue.a backend.a outbuffer.o
	dmd $(DSRC) -ofddmd glue.a backend.a outbuffer.o -debug -vtls -J.. -d -version=DMDV2 -g
