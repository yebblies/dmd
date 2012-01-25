
import std.stdio;

import root.aav;
import root._dchar;
import root.lstring;
import root.rmem;
import root.port;
import root.stringtable;
import root.root;
import root.speller;
import root.async;
import root.thread;

////////////////////////////////////////////////////////

void testaav()
{
    AA* x;
    auto a = new int;
    auto b = new int;
    *a = 3;
    *b = 7;
    *_aaGet(&x, a) = b;
    assert(*_aaGet(&x, a) is b);
    assert(_aaGetRvalue(x, a) is b);
    assert(root.aav._aaLen(x) == 1);
}

////////////////////////////////////////////////////////

void testdchar()
{
    _dchar[6] x = "Hello!";
    _dchar* p = x.ptr;
    
    assert(Dchar.get(p) == 'H');
    p = Dchar.inc(p);
    assert(Dchar.get(p) == 'e');
    p = Dchar.dec(x.ptr, p);
    assert(Dchar.get(p) == 'H');
    assert(Dchar.calcHash(p, 6) == 0x76A91ABD);
}

////////////////////////////////////////////////////////

void testlstring()
{
    auto x = Lstring(6, "Hello!".dup.ptr);
    assert(x.len() == 6);
}

////////////////////////////////////////////////////////

void testObject()
{
    auto o = new _Object();
    assert(o.toChars()[0..6] == "Object");
}

////////////////////////////////////////////////////////

void testThread()
{
    //writeln(Thread.getId()); where is getId defined?
}

////////////////////////////////////////////////////////

void main()
{
    testaav();
    testdchar();
    testlstring();
    testObject();
    testThread();
    writeln("All passed!");
}
