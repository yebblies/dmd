
// Compiler implementation of the D programming language
// Copyright (c) 2006-2007 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com
// License for redistribution is by either the Artistic License
// in artistic.txt, or the GNU General Public License in gnu.txt.
// See the included readme.txt for details.

module arraytypes;

import root.root;

import _template;
import dsymbol;
import aggregate;
import identifier;
import _module;
import mtype;
import expression;
import declaration;
import init;
import statement;
import fakebackend;

alias ArrayBase!TemplateParameter TemplateParameters;

alias ArrayBase!Expression Expressions;

alias ArrayBase!Statement Statements;

alias ArrayBase!BaseClass BaseClasses;

alias ArrayBase!ClassDeclaration ClassDeclarations;

alias ArrayBase!Dsymbol Dsymbols;

alias ArrayBase!_Object Objects;

alias ArrayBase!FuncDeclaration FuncDeclarations;

alias ArrayBase!Parameter Parameters;

alias ArrayBase!Identifier Identifiers;

alias ArrayBase!Initializer Initializers;

alias ArrayBase!VarDeclaration VarDeclarations;

alias ArrayBase!Type Types;

alias ArrayBase!ScopeDsymbol ScopeDsymbols;

alias ArrayBase!Catch Catches;

alias ArrayBase!StaticDtorDeclaration StaticDtorDeclarations;

alias ArrayBase!SharedStaticDtorDeclaration SharedStaticDtorDeclarations;

alias ArrayBase!AliasDeclaration AliasDeclarations;

alias ArrayBase!Module Modules;

alias ArrayBase!File Files;

alias ArrayBase!CaseStatement CaseStatements;

alias ArrayBase!CompoundStatement CompoundStatements;

alias ArrayBase!GotoCaseStatement GotoCaseStatements;

alias ArrayBase!TemplateInstance TemplateInstances;

alias ArrayBasex!char Strings;

alias ArrayBasex!void Voids;

alias ArrayBasex!block Blocks;

alias ArrayBasex!Symbol Symbols;

