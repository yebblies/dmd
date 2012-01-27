
// Compiler implementation of the D programming language
// Copyright (c) 1999-2008 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module _module;

import root.root;

import mars;
import dsymbol;
import identifier;
import _scope;
import arraytypes;
import declaration;
import aggregate;
import _macro;
import doc;
import hdrgen;
import fakebackend;

extern(C++)
class Package : ScopeDsymbol
{
    this(Identifier ident);
    const(char)* kind();

    static DsymbolTable resolve(Identifiers packages, Dsymbol *pparent, Package *ppkg);

    Package isPackage();

    void semantic(Scope *sc);
};

extern(C++)
final class Module : Package
{
    static extern Module rootModule;
    static extern DsymbolTable modules;       // symbol table of all modules
    static extern Modules amodules;            // array of all modules
    static extern Dsymbols deferred;   // deferred Dsymbol's needing semantic() run on them
    static extern uint dprogress;  // progress resolving the deferred list
    static void init();

    static extern ClassDeclaration moduleinfo;


    const(char)* arg;    // original argument name
    ModuleDeclaration md; // if !NULL, the contents of the ModuleDeclaration declaration
    File srcfile;      // input source file
    File objfile;      // output .obj file
    File hdrfile;      // 'header' file
    File symfile;      // output symbol file
    File docfile;      // output documentation file
    uint errors;    // if any errors in file
    uint numlines;  // number of lines in source file
    int isHtml;         // if it is an HTML file
    int isDocFile;      // if it is a documentation input file, not D source
    int needmoduleinfo;
version (IN_GCC) {
    int strictlyneedmoduleinfo;
}

    int selfimports;            // 0: don't know, 1: does not, 2: does
    int selfImports();          // returns !=0 if module imports itself

    int insearch;
    Identifier searchCacheIdent;
    Dsymbol searchCacheSymbol; // cached value of search
    int searchCacheFlags;       // cached flags

    int semanticstarted;        // has semantic() been started?
    int semanticRun;            // has semantic() been done?
    int root;                   // != 0 if this is a 'root' module,
                                // i.e. a module that will be taken all the
                                // way to an object file
    Module importedFrom;       // module from command line we're imported from,
                                // i.e. a module that will be taken all the
                                // way to an object file

    Dsymbols decldefs;         // top level declarations for this Module

    Modules aimports;             // all imported modules

    ModuleInfoDeclaration vmoduleinfo;

    uint debuglevel;        // debug level
    Strings debugids;      // debug identifiers
    Strings debugidsNot;       // forward referenced debug identifiers

    uint versionlevel;      // version level
    Strings versionids;    // version identifiers
    Strings versionidsNot;     // forward referenced version identifiers

    Macro *macrotable;          // document comment macros
    Escape *escapetable;        // document comment escapes
    bool _safe;                  // TRUE if module is marked as 'safe'

    size_t nameoffset;          // offset of module name from start of ModuleInfo
    size_t namelen;             // length of module name in characters

    this(char *arg, Identifier ident, int doDocComment, int doHdrGen);
    ~this();

    static Module load(Loc loc, Identifiers packages, Identifier ident);

    void toCBuffer(OutBuffer buf, HdrGenState *hgs);
    void toJsonBuffer(OutBuffer buf);
    const(char)* kind();
    void setDocfile();  // set docfile member
    void read(Loc loc); // read file
version (IN_GCC) {
    void parse(bool dump_source = false);       // syntactic parse
} else {
    void parse();       // syntactic parse
}
    void importAll(Scope *sc);
    void semantic();    // semantic analysis
    void semantic2();   // pass 2 semantic analysis
    void semantic3();   // pass 3 semantic analysis
    void inlineScan();  // scan for functions to inline
    void setHdrfile();  // set hdrfile member
    void genhdrfile();  // generate D import file
    void genobjfile(int multiobj);
    void gensymfile();
    void gendocfile();
    int needModuleInfo();
    Dsymbol search(Loc loc, Identifier ident, int flags);
    Dsymbol symtabInsert(Dsymbol s);
    void deleteObjFile();
    void addDeferredSemantic(Dsymbol s);
    static void runDeferredSemantic();
    static void clearCache();
    int imports(Module m);

    // Back end

    int doppelganger;           // sub-module
    Symbol *cov;                // private uint[] __coverage;
    uint *covb;             // bit array of valid code line numbers

    Symbol *sictor;             // module order independent constructor
    Symbol *sctor;              // module constructor
    Symbol *sdtor;              // module destructor
    Symbol *ssharedctor;        // module shared constructor
    Symbol *sshareddtor;        // module shared destructor
    Symbol *stest;              // module unit test

    Symbol *sfilename;          // symbol for filename

    Symbol *massert;            // module assert function
    Symbol *toModuleAssert();   // get module assert function

    Symbol *munittest;          // module unittest failure function
    Symbol *toModuleUnittest(); // get module unittest failure function

    Symbol *marray;             // module array bounds function
    Symbol *toModuleArray();    // get module array bounds function


    static Symbol *gencritsec();
    elem *toEfilename();

    Symbol *toSymbol();
    void genmoduleinfo();

    Module isModule();
};


extern(C++)
final class ModuleDeclaration
{
    Identifier id;
    Identifiers packages;            // array of Identifier's representing packages
    bool _safe;

    this(Identifiers packages, Identifier id, bool _safe);

    char *toChars();
};

