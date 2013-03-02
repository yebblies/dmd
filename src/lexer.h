
// Compiler implementation of the D programming language
// Copyright (c) 1999-2012 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

#ifndef DMD_LEXER_H
#define DMD_LEXER_H

#ifdef __DMC__
#pragma once
#endif /* __DMC__ */

#include "root.h"
#include "mars.h"

struct StringTable;
struct Identifier;
struct Module;

/* Tokens:
        (       )
        [       ]
        {       }
        <       >       <=      >=      ==      !=      ===     !==
        <<      >>      <<=     >>=     >>>     >>>=
        +       -       +=      -=
        *       /       %       *=      /=      %=
        &       |       ^       &=      |=      ^=
        =       !       ~       @
        ^^      ^^=
        ++      --
        .       ->      :       ,       =>
        ?       &&      ||
 */

enum TOK
{
        TOKreserved,

        // Other
        TOKlparen,      TOKrparen,
        TOKlbracket,    TOKrbracket,
        TOKlcurly,      TOKrcurly,
        TOKcolon,       TOKneg,
        TOKsemicolon,   TOKdotdotdot,
        TOKeof,         TOKcast,
        TOKnull,        TOKassert,
        TOKtrue,        TOKfalse,
        TOKarray,       TOKcall,
        TOKaddress,
        TOKtype,        TOKthrow,
        TOKnew,         TOKdelete,
        TOKstar,        TOKsymoff,
        TOKvar,         TOKdotvar,
        TOKdotti,       TOKdotexp,
        TOKdottype,     TOKslice,
        TOKarraylength, TOKversion,
        TOKmodule,      TOKdollar,
        TOKtemplate,    TOKdottd,
        TOKdeclaration, TOKtypeof,
        TOKpragma,      TOKdsymbol,
        TOKtypeid,      TOKuadd,
        TOKremove,
        TOKnewanonclass, TOKcomment,
        TOKarrayliteral, TOKassocarrayliteral,
        TOKstructliteral,

        // Operators
        TOKlt,          TOKgt,
        TOKle,          TOKge,
        TOKequal,       TOKnotequal,
        TOKidentity,    TOKnotidentity,
        TOKindex,       TOKis,
        TOKtobool,

// 60
        // NCEG floating point compares
        // !<>=     <>    <>=    !>     !>=   !<     !<=   !<>
        TOKunord,TOKlg,TOKleg,TOKule,TOKul,TOKuge,TOKug,TOKue,

        TOKshl,         TOKshr,
        TOKshlass,      TOKshrass,
        TOKushr,        TOKushrass,
        TOKcat,         TOKcatass,      // ~ ~=
        TOKadd,         TOKmin,         TOKaddass,      TOKminass,
        TOKmul,         TOKdiv,         TOKmod,
        TOKmulass,      TOKdivass,      TOKmodass,
        TOKand,         TOKor,          TOKxor,
        TOKandass,      TOKorass,       TOKxorass,
        TOKassign,      TOKnot,         TOKtilde,
        TOKplusplus,    TOKminusminus,  TOKconstruct,   TOKblit,
        TOKdot,         TOKarrow,       TOKcomma,
        TOKquestion,    TOKandand,      TOKoror,
        TOKpreplusplus, TOKpreminusminus,

// 106
        // Numeric literals
        TOKint32v, TOKuns32v,
        TOKint64v, TOKuns64v,
        TOKfloat32v, TOKfloat64v, TOKfloat80v,
        TOKimaginary32v, TOKimaginary64v, TOKimaginary80v,

        // Char constants
        TOKcharv, TOKwcharv, TOKdcharv,

        // Leaf operators
        TOKidentifier,  TOKstring,
        TOKthis,        TOKsuper,
        TOKhalt,        TOKtuple,
        TOKerror,

        // Basic types
        TOKvoid,
        TOKint8, TOKuns8,
        TOKint16, TOKuns16,
        TOKint32, TOKuns32,
        TOKint64, TOKuns64,
        TOKint128, TOKuns128,
        TOKfloat32, TOKfloat64, TOKfloat80,
        TOKimaginary32, TOKimaginary64, TOKimaginary80,
        TOKcomplex32, TOKcomplex64, TOKcomplex80,
        TOKchar, TOKwchar, TOKdchar, TOKbit, TOKbool,

// 152
        // Aggregates
        TOKstruct, TOKclass, TOKinterface, TOKunion, TOKenum, TOKimport,
        TOKtypedef, TOKalias, TOKoverride, TOKdelegate, TOKfunction,
        TOKmixin,

        TOKalign, TOKextern, TOKprivate, TOKprotected, TOKpublic, TOKexport,
        TOKstatic, /*TOKvirtual,*/ TOKfinal, TOKconst, TOKabstract, TOKvolatile,
        TOKdebug, TOKdeprecated, TOKin, TOKout, TOKinout, TOKlazy,
        TOKauto, TOKpackage, TOKmanifest, TOKimmutable,

        // Statements
        TOKif, TOKelse, TOKwhile, TOKfor, TOKdo, TOKswitch,
        TOKcase, TOKdefault, TOKbreak, TOKcontinue, TOKwith,
        TOKsynchronized, TOKreturn, TOKgoto, TOKtry, TOKcatch, TOKfinally,
        TOKasm, TOKforeach, TOKforeach_reverse,
        TOKscope,
        TOKon_scope_exit, TOKon_scope_failure, TOKon_scope_success,

        // Contracts
        TOKbody, TOKinvariant,

        // Testing
        TOKunittest,

        // Added after 1.0
        TOKargTypes,
        TOKref,
        TOKmacro,
#if DMDV2
        TOKparameters,
        TOKtraits,
        TOKoverloadset,
        TOKpure,
        TOKnothrow,
        TOKgshared,
        TOKline,
        TOKfile,
        TOKshared,
        TOKat,
        TOKpow,
        TOKpowass,
        TOKgoesto,
        TOKvector,
        TOKpound,
#endif

        TOKMAX
};

#define TOKwild TOKinout

struct Token
{
    Token *next;
    const char *ptr;         // pointer to first character of this token within buffer
    enum TOK value;
    const char *blockComment; // doc comment string prior to this token
    const char *lineComment;  // doc comment for previous token
    union
    {
        // Integers
        d_int32 int32value;
        d_uns32 uns32value;
        d_int64 int64value;
        d_uns64 uns64value;

        // Floats
#ifdef IN_GCC
        // real_t float80value; // can't use this in a union!
#else
        d_float80 float80value;
#endif

        struct
        {   unsigned char *ustring;     // UTF8 string
            unsigned len;
            unsigned char postfix;      // 'c', 'w', 'd'
        };

        Identifier *ident;
    };
#ifdef IN_GCC
    real_t float80value; // can't use this in a union!
#endif

    static const char *tochars[TOKMAX];
    static void *operator new(size_t sz);

    Token() { next = NULL; }
    int isKeyword();
    void print();
    const char *toChars();
    static const char *toChars(enum TOK);
};

struct Lexer
{
    static StringTable stringtable;
    static OutBuffer stringbuffer;
    static Token *freelist;

    Loc loc;                    // for error messages

    const char *base;        // pointer to start of buffer
    const char *end;         // past end of buffer
    const char *p;           // current character
    Token token;
    Module *mod;
    int doDocComment;           // collect doc comment information
    int anyToken;               // !=0 means seen at least one token
    int commentToken;           // !=0 means comments are TOKcomment's

    Lexer(Module *mod,
        const char *base, size_t begoffset, size_t endoffset,
        int doDocComment, int commentToken);

    static void initKeywords();
    static Identifier *idPool(const char *s);
    static Identifier *uniqueId(const char *s);
    static Identifier *uniqueId(const char *s, int num);

    TOK nextToken();
    TOK peekNext();
    TOK peekNext2();
    void scan(Token *t);
    Token *peek(Token *t);
    Token *peekPastParen(Token *t);
    unsigned escapeSequence();
    TOK wysiwygStringConstant(Token *t, int tc);
    TOK hexStringConstant(Token *t);
#if DMDV2
    TOK delimitedStringConstant(Token *t);
    TOK tokenStringConstant(Token *t);
#endif
    TOK escapeStringConstant(Token *t, int wide);
    TOK charConstant(Token *t, int wide);
    void stringPostfix(Token *t);
    unsigned wchar(unsigned u);
    TOK number(Token *t);
    TOK inreal(Token *t);
    void error(const char *format, ...);
    void error(Loc loc, const char *format, ...);
    void deprecation(const char *format, ...);
    void poundLine();
    unsigned decodeUTF();
    void getDocComment(Token *t, unsigned lineComment);

    static int isValidIdentifier(char *p);
    static const char *combineComments(const char *c1, const char *c2);

    Loc tokenLoc();
};

#endif /* DMD_LEXER_H */
