import std.stdio;
import std.c.stdio;

/******************************************/

struct S
{
    int opStar() { return 7; }
}

void test1()
{
    S s;

    printf("%d\n", *s);
    assert(*s == 7);
}

/******************************************/

void test2()
{
  double[1][2] bar;
  bar[0][0] = 1.0;
  bar[1][0] = 2.0;
  foo2(bar);
}

void foo2(T...)(T args)
{
    foreach (arg; args[0 .. $])
    {
	//writeln(arg);
	bar2!(typeof(arg))(&arg);
    }
}


void bar2(D)(const(void)* arg)
{
    D obj = *cast(D*) arg;
}

/***************************************************/

void test3()
{
    version (unittest)
    {
	printf("unittest!\n");
    }
    else
    {
	printf("no unittest!\n");
    }
}


/***************************************************/

void test4()
{
  invariant int maxi = 8;
  int[][maxi] neighbors = [ cast(int[])[ ], [ 0 ], [ 0, 1], [ 0, 2], [1, 2], [1, 2, 3, 4],
[ 2, 3, 5], [ 4, 5, 6 ] ];
  int[maxi] grid;

  // neighbors[0].length = 0;

  void place(int k, uint mask)
  { if(k<maxi) {
      for(uint m = 1, d = 1; d <= maxi; d++, m<<=1)
        if(!(mask & m)) {
          bool ok = true;
          int dif;
          foreach(nb; neighbors[k]) 
            if((dif=grid[nb]-d)==1 || dif==-1) {
              ok = false; break;
            }
          if(ok) {
            grid[k] = d;
            place(k+1, mask | m);
          }
        }
    } else {
      printf("  %d\n%d %d %d\n%d %d %d\n  %d\n\n",
             grid[0], grid[1], grid[2], grid[3], grid[4], grid[5], grid[6], grid[7]);
    }
  }
  place(0, 0);
}


/***************************************************/

struct S5
{
  enum S5 some_constant = {2};

  int member;
}

void test5()
{
}

/***************************************************/

struct S6
{
    int a, b, c;
}

struct T6
{
    S6 s;
    int b = 7;

    S6* opDot()
    {
	return &s;
    }
}

void test6()
{
    T6 t;
    t.a = 4;
    t.b = 5;
    t.c = 6;
    assert(t.a == 4);
    assert(t.b == 5);
    assert(t.c == 6);
    assert(t.s.b == 0);
    assert(t.sizeof == 4*4);
    assert(t.init.sizeof == 4*4);
}

/***************************************************/

struct S7
{
    int a, b, c;
}

class C7
{
    S7 s;
    int b = 7;

    S7* opDot()
    {
	return &s;
    }
}

void test7()
{
    C7 t = new C7();
    t.a = 4;
    t.b = 5;
    t.c = 6;
    assert(t.a == 4);
    assert(t.b == 5);
    assert(t.c == 6);
    assert(t.s.b == 0);
    assert(t.sizeof == (void*).sizeof);
    assert(t.init is null);
}

/***************************************************/

void foo8(int n1 = __LINE__ + 0, int n2 = __LINE__, string s = __FILE__)
{
    assert(n1 < n2);
    printf("n1 = %d, n2 = %d, s = %.*s\n", n1, n2, s.length, s.ptr);
}

void test8()
{
    foo8();
}

/***************************************************/

void foo9(int n1 = __LINE__ + 0, int n2 = __LINE__, string s = __FILE__)()
{
    assert(n1 < n2);
    printf("n1 = %d, n2 = %d, s = %.*s\n", n1, n2, s.length, s.ptr);
}

void test9()
{
    foo9();
}

/***************************************************/

int foo10(char c) pure nothrow
{
    return 1;
}

void test10()
{
    int function(char c) fp;
    int function(char c) pure nothrow fq;

    fp = &foo10;
    fq = &foo10;
}

/***************************************************/

class Base11 {}
class Derived11 : Base11 {}
class MoreDerived11 : Derived11 {}

int fun11(Base11) { return 1; }
int fun11(Derived11) { return 2; }

void test11()
{
    MoreDerived11 m;

    auto i = fun11(m);
    assert(i == 2);
}

/***************************************************/

interface ABC {};
interface AB: ABC {};
interface BC: ABC {};
interface AC: ABC {};
interface A: AB, AC {};
interface B: AB, BC {};
interface C: AC, BC {};

int f12(AB ab) { return 1; }
int f12(ABC abc) { return 2; }

void test12()
{
	A a;
	auto i = f12(a);
	assert(i == 1);
}

/***************************************************/

template Foo13(alias x)
{
    enum bar = x + 1;
}

static assert(Foo13!(2+1).bar == 4);

template Bar13(alias x)
{
    enum bar = x;
}

static assert(Bar13!("abc").bar == "abc");

void test13()
{
}

/***************************************************/

template Foo14(alias a)
{
    alias Bar14!(a) Foo14;
}

int Bar14(alias a)()
{
    return a.sizeof;
}

void test14()
{
    auto i = Foo14!("hello")();
    printf("i = %d\n", i);
    assert(i == "hello".sizeof);
    i = Foo14!(1)();
    printf("i = %d\n", i);
    assert(i == 4);
}

/***************************************************/

auto foo15()(int x)
{
    return 3 + x;
}

void test15()
{

    auto bar()(int x)
    {
	return 5 + x;
    }

    printf("%d\n", foo15(4));
    printf("%d\n", bar(4));
}

/***************************************************/

int foo16(int x) { return 1; }
int foo16(ref int x) { return 2; }

void test16()
{
    int y;
    auto i = foo16(y);
    printf("i == %d\n", i);
    assert(i == 2);
    i = foo16(3);
    assert(i == 1);
}

/***************************************************/

class A17 { }
class B17 : A17 { }
class C17 : B17 { }

int foo17(A17, ref int x) { return 1; }
int foo17(B17, ref int x) { return 2; }

void test17()
{
    C17 c;
    int y;
    auto i = foo17(c, y);
    printf("i == %d\n", i);
    assert(i == 2);
}

/***************************************************/

class C18
{
    void foo(int x) { foo("abc"); }
    void foo(string s) { }  // this is hidden, but that's ok 'cuz no overlap
    void bar()
    {
	foo("abc");
    }
}

class D18 : C18
{
    override void foo(int x) { }
}

void test18()
{
    D18 d = new D18();
    d.bar();
}

/***************************************************/

int foo19(alias int a)() { return a; }

void test19()
{
    int y = 7;
    auto i = foo19!(y)();
    printf("i == %d\n", i);
    assert(i == 7);

    i = foo19!(4)();
    printf("i == %d\n", i);
    assert(i == 4);
}

/***************************************************/

template Foo20(int x) if (x & 1)
{
    const int Foo20 = 6;
}

template Foo20(int x) if ((x & 1) == 0)
{
    const int Foo20 = 7;
}

void test20()
{
    int i = Foo20!(3);
    printf("%d\n", i);
    assert(i == 6);
    i = Foo20!(4);
    printf("%d\n", i);
    assert(i == 7);
}

/***************************************************/

template isArray21(T : U[], U)
{
  static const isArray21 = 1;
}

template isArray21(T)
{
  static const isArray21 = 0;
}

int foo21(T)(T x) if (isArray21!(T))
{
    return 1;
}

int foo21(T)(T x) if (!isArray21!(T))
{
    return 2;
}

void test21()
{
    auto i = foo21(5);
    assert(i == 2);
    int[] a;
    i = foo21(a);
    assert(i == 1);
}

/***************************************************/

void test22()
{
    invariant uint x, y;
    foreach (i; x .. y) {}
}

/***************************************************/

const bool foo23 = is(typeof(function void() { }));
const bar23      = is(typeof(function void() { }));

void test23()
{
    assert(foo23 == true);
    assert(bar23 == true);
}

/***************************************************/

ref int foo24(int i)
{
    static int x;
    x = i;
    return x;
}

void test24()
{
    int x = foo24(3);
    assert(x == 3);
}

/***************************************************/

ref int foo25(int i)
{
    static int x;
    x = i;
    return x;
}

int bar25(ref int x)
{
    return x + 1;
}

void test25()
{
    int x = bar25(foo25(3));
    assert(x == 4);
}

/***************************************************/

static int x26;

ref int foo26(int i)
{
    x26 = i;
    return x26;
}

void test26()
{
    int* p = &foo26(3);
    assert(*p == 3);
}

/***************************************************/

static int x27 = 3;

ref int foo27(int i)
{
    return x27;
}

void test27()
{
    foo27(3) = 4;
    assert(x27 == 4);
}

/***************************************************/

ref int foo28(ref int x) { return x; }

void test28()
{
    int a;
    foo28(a);
}

/***************************************************/

void wyda(int[] a) { printf("aaa\n"); }
void wyda(int[int] a) { printf("bbb\n"); }

struct S29
{
    int[] a;

    void wyda()
    {
	a.wyda;
	a.wyda();
    }
}

void test29()
{
    int[] a;
    a.wyda;
    int[5] b;
    b.wyda;
    int[int] c;
    c.wyda;

    S29 s;
    s.wyda();
}

/***************************************************/

void foo30(D)(D arg) if (isIntegral!D)
{
}

struct S30(T) { }
struct U30(int T) { }

alias int myint30;

void test30()
{

    S30!myint30 u;
    S30!int s;
    S30!(int) t = s;

//    U30!3 v = s;
}

/***************************************************/

class A31
{
    void foo(int* p) { }
}

class B31 : A31
{
    void foo(scope int* p) { }
}

void test31()
{
}

/***************************************************/

void bar32() { }

nothrow void foo32(int* p)
{
    //try { bar32(); } catch (Object o) { }
    try { bar32(); } catch (Throwable o) { }
    try { bar32(); } catch (Exception o) { }
}

void test32()
{   int i;

    foo32(&i);
}

/***************************************************/

struct Integer
{
    this(int i)
    {
        this.i = i;
    }

    this(long ii)
    {
      i = 3;
    }

    const int i;
}

void test33()
{
}

/***************************************************/

void test34()
{
  alias uint Uint;
  foreach(Uint u;1..10) {}
  for(Uint u=1;u<10;u++) {}
}

/***************************************************/

ref int foo35(bool condition, ref int lhs, ref int rhs)
{
        if ( condition ) return lhs;
        return rhs;
}

ref int bar35()(bool condition, ref int lhs, ref int rhs)
{
        if ( condition ) return lhs;
        return rhs;
}

void test35()
{
        int a = 10, b = 11;

        foo35(a<b, a, b) = 42;
        printf("a = %d and b = %d\n", a, b); // a = 42 and b = 11
	assert(a == 42 && b == 11);

        bar35(a<b, a, b) = 52;
        printf("a = %d and b = %d\n", a, b);
	assert(a == 42 && b == 52);
}

/***************************************************/

int foo36(T...)(T ts)
if (T.length > 1)
{
    return T.length;
}

int foo36(T...)(T ts)
if (T.length <= 1)
{
    return T.length * 7;
}

void test36()
{
    auto i = foo36!(int,int)(1, 2);
    assert(i == 2);
    i = foo36(1, 2, 3);
    assert(i == 3);
    i = foo36(1);
    assert(i == 7);
    i = foo36();
    assert(i == 0);
}


/***************************************************/

struct A37(alias T)
{
}

void foo37(X)(X x) if (is(X Y == A37!(U), alias U))
{
}

void bar37() {}

void test37()
{
    A37!(bar37) a2;
    foo37(a2);
    foo37!(A37!bar37)(a2);
}

/***************************************************/

struct A38
{
    this(this)
    {
        printf("B's copy\n");
    }
    bool empty() {return false;}
    void popFront() {}
    int front() { return 1; }
//    ref A38 opSlice() { return this; }
}

void test38()
{
    A38 a;
    int i;
    foreach (e; a) { if (++i == 100) break; }
}

/***************************************************/

alias int function() Fun39;
alias ref int function() Gun39;
static assert(!is(Fun39 == Gun39));

void test39()
{
}

/***************************************************/

int x40;

struct Proxy
{
    ref int at(int i)() { return x40; }
}

void test40()
{
    Proxy p;
    auto x = p.at!(1);
}

/***************************************************/

template Foo41(TList...)
{
    alias TList Foo41;
}

alias Foo41!(immutable(ubyte)[], ubyte[]) X41;

void test41()
{
}


/***************************************************/

bool endsWith(A1, A2)(A1 longer, A2 shorter)
{
    static if (is(typeof(longer[0 .. 0] == shorter)))
    {
    }
    else
    {
    }
    return false;
}

void test42()
{
    char[] a;
    byte[] b;
    endsWith(a, b);
}

/***************************************************/

void f43(S...)(S s) if (S.length > 3)
{
}

void test43()
{
    f43(1, 2, 3, 4);
}


/***************************************************/

struct S44(int x = 1){}

void fun()(S44!(1) b) { }

void test44()
{
    S44!() s;
    fun(s);
}

/***************************************************/

class A45
{
  int x;
  int f()
  {
    printf("A\n");
    return 1;
  }
}

class B45 : A45
{
  override const int f()
  {
    printf("B\n");
    return 2;
  }
}

void test45()
{
    A45 y = new B45;
    int i = y.f;
    assert(i == 2);
}

/***************************************************/

struct Test46
{
 int foo;
}

void test46()
{
    enum Test46 test = {};
    enum q = test.foo;
}

/***************************************************/

pure int double_sqr(int x) {
    int y = x;
    void do_sqr() { y *= y; }
    do_sqr();
    return y;
}

void test47()
{
   assert(double_sqr(10) == 100);
}

/***************************************************/

void sort(alias less)(string[] r)
{
            bool pred()
            {
                return less("a", "a");
            }
	    .sort!(less)(r);
}

void foo48()
{
    int[string] freqs;
    string[] words;

sort!((a, b) { return freqs[a] > freqs[b]; })(words);
sort!((string a, string b) { return freqs[a] > freqs[b]; })(words);
//sort!(bool (a, b) { return freqs[a] > freqs[b]; })(words);
//sort!(function (a, b) { return freqs[a] > freqs[b]; })(words);
//sort!(function bool(a, b) { return freqs[a] > freqs[b]; })(words);
sort!(delegate bool(string a, string b) { return freqs[a] > freqs[b]; })(words);

}

void test48()
{
}

/***************************************************/

struct S49
{
    static void* p;

    this( string name )
    {
	printf( "(ctor) &%.*s.x = %p\n", name.length, name.ptr, &x );
	p = cast(void*)&x;
    }

    invariant() {}

    int x;
}

void test49()
{
    auto s = new S49("s2");

    printf( "&s2.x = %p\n", &s.x );
    assert(cast(void*)&s.x == S49.p);
}

/***************************************************/

auto max50(Ts...)(Ts args)
  if (Ts.length >= 2
        && is(typeof(Ts[0].init > Ts[1].init ? Ts[1].init : Ts[0].init)))
{
    static if (Ts.length == 2)
        return args[1] > args[0] ? args[1] : args[0];
    else
        return max50(max50(args[0], args[1]), args[2 .. $]);
}

void test50()
{
   assert(max50(4, 5) == 5);
   assert(max50(2.2, 4.5) == 4.5);
   assert(max50("Little", "Big") == "Little");

   assert(max50(4, 5.5) == 5.5);
   assert(max50(5.5, 4) == 5.5);
}

/***************************************************/

void test51()
{
    static immutable int[2] array = [ 42 ];
    enum e = array[1];
    static immutable int[1] array2 = [ 0: 42 ];
    enum e2 = array2[0];
    assert(e == 0);
    assert(e2 == 42);
}

/***************************************************/

enum ubyte[4] a52 = [5,6,7,8];

void test52()
{
  int x=3;
  assert(a52[x]==8);
}

/***************************************************/

void test53()
{
    size_t func2(immutable(void)[] t)
    {
        return 0;
    }
}

/***************************************************/

void foo54(void delegate(void[]) dg) { }

void test54()
{
    void func(void[] t) pure { }
    foo54(&func);

//    void func2(const(void)[] t) { }
//    foo54(&func2);
}

/***************************************************/

class Foo55
{
	synchronized void noop1() { }
	void noop2() shared { }
}

void test55()
{
	auto foo = new shared(Foo55);
	foo.noop1();
	foo.noop2();
}

/***************************************************/

enum float one56 = 1 * 1;
template X56(float E) { int X56 = 2; }
alias X56!(one56 * one56) Y56;

void test56()
{
    assert(Y56 == 2);
}

/***************************************************/

void test57()
{
    alias shared(int) T;
    assert (is(T == shared));
}

/***************************************************/

struct A58
{
  int a,b;
}

void test58()
{
  A58[2] rg=[{1,2},{5,6}];
  assert(rg[0].a == 1);
  assert(rg[0].b == 2);
  assert(rg[1].a == 5);
  assert(rg[1].b == 6);
}

/***************************************************/

class A59 {
    const foo(int i)  { return i; }
}

/***************************************************/

void test60()
{
    enum real ONE = 1.0;
    real x;
    for (x=0.0; x<10.0; x+=ONE)
	printf("%Lg\n", x);
    printf("%Lg\n", x);
    assert(x == 10);
}

/***************************************************/

pure immutable(T)[] fooPT(T)(immutable(T)[] x, immutable(T)[] y){

  immutable(T)[] fooState;

  immutable(T)[] bar(immutable(T)[] x){
    fooState = "hello ";
    return x ~ y;
  }

  return fooState ~ bar(x);

}


void test61()
{
  writeln(fooPT("p", "c"));
}

/***************************************************/

int[3] foo62(int[3] a)
{
    a[1]++;
    return a;
}

void test62()
{
    int[3] b;
    b[0] = 1;
    b[1] = 2;
    b[2] = 3;
    auto c = foo62(b);
    assert(b[0] == 1);
    assert(b[1] == 2);
    assert(b[2] == 3);

    assert(c[0] == 1);
    assert(c[1] == 3);
    assert(c[2] == 3);
}

/***************************************************/

void test63()
{
    int[3] b;
    b[0] = 1;
    b[1] = 2;
    b[2] = 3;
    auto c = b;
    b[1]++;
    assert(b[0] == 1);
    assert(b[1] == 3);
    assert(b[2] == 3);

    assert(c[0] == 1);
    assert(c[1] == 2);
    assert(c[2] == 3);
}

/***************************************************/

void test64()
{
    int[3] b;
    b[0] = 1;
    b[1] = 2;
    b[2] = 3;
    int[3] c;
    c = b;
    b[1]++;
    assert(b[0] == 1);
    assert(b[1] == 3);
    assert(b[2] == 3);

    assert(c[0] == 1);
    assert(c[1] == 2);
    assert(c[2] == 3);
}

/***************************************************/

int[2] foo65(int[2] a)
{
    a[1]++;
    return a;
}

void test65()
{
    int[2] b;
    b[0] = 1;
    b[1] = 2;
    int[2] c = foo65(b);
    assert(b[0] == 1);
    assert(b[1] == 2);

    assert(c[0] == 1);
    assert(c[1] == 3);
}

/***************************************************/

int[1] foo66(int[1] a)
{
    a[0]++;
    return a;
}

void test66()
{
    int[1] b;
    b[0] = 1;
    int[1] c = foo66(b);
    assert(b[0] == 1);
    assert(c[0] == 2);
}

/***************************************************/

int[2] foo67(out int[2] a)
{
    a[0] = 5;
    a[1] = 6;
    return a;
}

void test67()
{
    int[2] b;
    b[0] = 1;
    b[1] = 2;
    int[2] c = foo67(b);
    assert(b[0] == 5);
    assert(b[1] == 6);

    assert(c[0] == 5);
    assert(c[1] == 6);
}

/***************************************************/

void test68()
{
    digestToString(cast(ubyte[16])x"c3fcd3d76192e4007dfb496cca67e13b");
}

void digestToString(const ubyte[16] digest)
{
    assert(digest[0] == 0xc3);
    assert(digest[15] == 0x3b);
}

/***************************************************/

void test69()
{
    digestToString69(cast(ubyte[16])x"c3fcd3d76192e4007dfb496cca67e13b");
}

void digestToString69(ref const ubyte[16] digest)
{
    assert(digest[0] == 0xc3);
    assert(digest[15] == 0x3b);
}

/***************************************************/

void test70()
{
    digestToString70("1234567890123456");
}

void digestToString70(ref const char[16] digest)
{
    assert(digest[0] == '1');
    assert(digest[15] == '6');
}

/***************************************************/

void foo71(out shared int o) {}

/***************************************************/

struct foo72
{
  int bar() shared { return 1; }
}

void test72()
{
  shared foo72 f;
  auto x = f.bar;
}

/***************************************************/

class Foo73
{
  static if (is(typeof(this) T : shared T))
	static assert(0);
  static if (is(typeof(this) U == shared U))
	static assert(0);
  static if (is(typeof(this) U == const U))
	static assert(0);
  static if (is(typeof(this) U == immutable U))
	static assert(0);
  static if (is(typeof(this) U == const shared U))
	static assert(0);

  static assert(!is(int == const));
  static assert(!is(int == immutable));
  static assert(!is(int == shared));

  static assert(is(int == int));
  static assert(is(const(int) == const));
  static assert(is(immutable(int) == immutable));
  static assert(is(shared(int) == shared));
  static assert(is(const(shared(int)) == shared));
  static assert(is(const(shared(int)) == const));

  static assert(!is(const(shared(int)) == immutable));
  static assert(!is(const(int) == immutable));
  static assert(!is(const(int) == shared));
  static assert(!is(shared(int) == const));
  static assert(!is(shared(int) == immutable));
  static assert(!is(immutable(int) == const));
  static assert(!is(immutable(int) == shared));
}

template Bar(T : T)
{
    alias T Bar;
}

template Barc(T : const(T))
{
    alias T Barc;
}

template Bari(T : immutable(T))
{
    alias T Bari;
}

template Bars(T : shared(T))
{
    alias T Bars;
}

template Barsc(T : shared(const(T)))
{
    alias T Barsc;
}


void test73()
{
    auto f = new Foo73;

    alias int T;

    // 5*5 == 25 combinations, plus 2 for swapping const and shared

    static assert(is(Bar!(T) == T));
    static assert(is(Bar!(const(T)) == const(T)));
    static assert(is(Bar!(immutable(T)) == immutable(T)));
    static assert(is(Bar!(shared(T)) == shared(T)));
    static assert(is(Bar!(shared(const(T))) == shared(const(T))));

    static assert(is(Barc!(const(T)) == T));
    static assert(is(Bari!(immutable(T)) == T));
    static assert(is(Bars!(shared(T)) == T));
    static assert(is(Barsc!(shared(const(T))) == T));

    static assert(is(Barc!(T) == T));
    static assert(is(Barc!(immutable(T)) == T));
    static assert(is(Barc!(const(shared(T))) == shared(T)));
    static assert(is(Barsc!(immutable(T)) == T));

    static assert(is(Bars!(const(shared(T))) == const(T)));
    static assert(is(Barsc!(shared(T)) == T));

    Bars!(shared(const(T))) b;
    pragma(msg, typeof(b));

    static assert(is(Bars!(shared(const(T))) == const(T)));
    static assert(is(Barc!(shared(const(T))) == shared(T)));

    static assert(!is(Bari!(T)));
    static assert(!is(Bari!(const(T))));
    static assert(!is(Bari!(shared(T))));
    static assert(!is(Bari!(const(shared(T)))));
    static assert(!is(Barc!(shared(T))));
    static assert(!is(Bars!(T)));
    static assert(!is(Bars!(const(T))));
    static assert(!is(Bars!(immutable(T))));
    static assert(!is(Barsc!(T)));
    static assert(!is(Barsc!(const(T))));
}

/***************************************************/

pure nothrow {
  alias void function(int) A74;
}

alias void function(int) pure nothrow B74;
alias pure nothrow void function(int) C74;

void test74()
{
    A74 a = null;
    B74 b = null;
    C74 c = null;
    a = b;
    a = c;
}

/***************************************************/

class A75
{
    pure static void raise(string s)
    {
        throw new Exception(s);
    }
}

void test75()
{   int x = 0;
    try
    {
	A75.raise("a");
    } catch (Exception e)
    {
	x = 1;
    }
    assert(x == 1);
}

/***************************************************/

void test76()
{
    int x, y;
    bool which;
    (which ? x : y) += 5;
    assert(y == 5);
}

/***************************************************/

void test77()
{
    auto a = ["hello", "world"];
    pragma(msg, typeof(a));
    auto b = a;
    assert(a is b);
    assert(a == b);
    b = a.dup;
    assert(a == b);
    assert(a !is b);
}

/***************************************************/

void test78()
{
    auto array = [0, 2, 4, 6, 8, 10];
    array = array[0 .. $ - 2];         // Right-shrink by two elements
    assert(array == [0, 2, 4, 6]);
    array = array[1 .. $];             // Left-shrink by one element
    assert(array == [2, 4, 6]);
    array = array[1 .. $ - 1];         // Shrink from both sides
    assert(array == [4]);
}

/***************************************************/

void test79()
{
    auto a = [87, 40, 10];
    a ~= 42;
    assert(a == [87, 40, 10, 42]);
    a ~= [5, 17];
    assert(a == [87, 40, 10, 42, 5, 17]);
}

/***************************************************/

void test6317()
{
    int b = 12345;
    struct nested { int a; int fun() { return b; } }
    static assert(!__traits(compiles, { nested x = { 3, null }; }));
    nested g = { 7 };
    auto h = nested(7);
    assert(g.fun() == 12345);
    assert(h.fun() == 12345);
}

/***************************************************/

void test80()
{
    auto array = new int[10];
    array.length += 1000;
    assert(array.length == 1010);
    array.length /= 10;
    assert(array.length == 101);
    array.length -= 1;
    assert(array.length == 100);
    array.length |= 1;
    assert(array.length == 101);
    array.length ^= 3;
    assert(array.length == 102);
    array.length &= 2;
    assert(array.length == 2);
    array.length *= 2;
    assert(array.length == 4);
    array.length <<= 1;
    assert(array.length == 8);
    array.length >>= 1;
    assert(array.length == 4);
    array.length >>>= 1;
    assert(array.length == 2);
    array.length %= 2;
    assert(array.length == 0);

    int[]* foo()
    {
	static int x;
	x++;
	assert(x == 1);
	auto p = &array;
	return p;
    }

    (*foo()).length += 2;
    assert(array.length == 2);
}

/***************************************************/

void test81()
{
    int[3] a = [1, 2, 3];
    int[3] b = a;       
    a[1] = 42;
    assert(b[1] == 2); // b is an independent copy of a
    int[3] fun(int[3] x, int[3] y) {
       // x and y are copies of the arguments
       x[0] = y[0] = 100;
       return x;
    }
    auto c = fun(a, b);         // c has type int[3]
    assert(c == [100, 42, 3]);
    assert(b == [1, 2, 3]);     // b is unaffected by fun
}

/***************************************************/

void test82()
{
    auto a1 = [ "Jane":10.0, "Jack":20, "Bob":15 ];
    auto a2 = a1;                    // a1 and a2 refer to the same data
    a1["Bob"] = 100;                 // Changing a1
    assert(a2["Bob"] == 100);        //is same as changing a2
    a2["Sam"] = 3.5;                 //and vice
    assert(a2["Sam"] == 3.5);        //    versa
}

/***************************************************/

void bump(ref int x) { ++x; }

void test83()
{
   int x = 1;
   bump(x);
   assert(x == 2);
}

/***************************************************/

auto foo84 = [1, 2.4];

void test84()
{
    pragma(msg, typeof([1, 2.4]));
    static assert(is(typeof([1, 2.4]) == double[]));

    pragma(msg, typeof(foo84));
    static assert(is(typeof(foo84) == double[]));
}

/***************************************************/

void test85()
{
    dstring c = "V\u00E4rld";
    c = c ~ '!';
    assert(c == "V\u00E4rld!");
    c = '@' ~ c;
    assert(c == "@V\u00E4rld!");

    wstring w = "V\u00E4rld";
    w = w ~ '!';
    assert(w == "V\u00E4rld!");
    w = '@' ~ w;
    assert(w == "@V\u00E4rld!");

    string s = "V\u00E4rld";
    s = s ~ '!';
    assert(s == "V\u00E4rld!");
    s = '@' ~ s;
    assert(s == "@V\u00E4rld!");
}

/***************************************************/

void test86()
{
    int[][] a = [ [1], [2,3], [4] ];
    int[][] w = [ [1, 2], [3], [4, 5], [] ];
    int[][] x = [ [], [1, 2], [3], [4, 5], [] ];
}

/***************************************************/

// Bugzilla 3379

T1[] find(T1, T2)(T1[] longer, T2[] shorter)
   if (is(typeof(longer[0 .. 1] == shorter) : bool))
{
   while (longer.length >= shorter.length) {
      if (longer[0 .. shorter.length] == shorter) break;
      longer = longer[1 .. $];
   }
   return longer;
}

auto max(T...)(T a) 
      if (T.length == 2 
         && is(typeof(a[1] > a[0] ? a[1] : a[0]))
       || T.length > 2 
         && is(typeof(max(max(a[0], a[1]), a[2 .. $])))) {
   static if (T.length == 2) {
      return a[1] > a[0] ? a[1] : a[0];
   } else {
      return max(max(a[0], a[1]), a[2 .. $]);
   }
}

// Cases which would ICE or segfault
struct Bulldog(T){
    static void cat(Frog)(Frog f) if (true)
    {    }
}

void mouse(){
    Bulldog!(int).cat(0);
}

void test87()
{
    double[] d1 = [ 6.0, 1.5, 2.4, 3 ];
    double[] d2 = [ 1.5, 2.4 ];
    assert(find(d1, d2) == d1[1 .. $]);
    assert(find(d1, d2) == d1[1 .. $]); // Check for memory corruption
    assert(max(4, 5) == 5);
    assert(max(3, 4, 5) == 5);
}

/***************************************************/

struct S88
{
    void opDispatch(string s, T)(T i)
    {
	printf("S.opDispatch('%.*s', %d)\n", s.length, s.ptr, i);
    }
}

class C88
{
    void opDispatch(string s)(int i)
    {
	printf("C.opDispatch('%.*s', %d)\n", s.length, s.ptr, i);
    }
}

struct D88
{
    template opDispatch(string s)
    {
	enum int opDispatch = 8;
    }
}

void test88()
{
    S88 s;
    s.opDispatch!("hello")(7);
    s.foo(7);

    auto c = new C88();
    c.foo(8);

    D88 d;
    printf("d.foo = %d\n", d.foo);
    assert(d.foo == 8);
}

/***************************************************/

void test89() {
    static struct X {
        int x;
        int bar() { return x; }
    }
    X s;
    printf("%d\n", s.sizeof);
    assert(s.sizeof == 4);
}

/***************************************************/

struct S90
{
    void opDispatch( string name, T... )( T values )
    {
	assert(values[0] == 3.14);
    }
}

void test90( )
{   S90 s;
    s.opDispatch!("foo")( 3.14 );
    s.foo( 3.14 );
}

/***************************************************/

void foo91(uint line = __LINE__) { printf("%d\n", line); }

void test91()
{
    foo91();
    printf("%d\n", __LINE__);
}

/***************************************************/

auto ref foo92(ref int x) { return x; }
int bar92(ref int x) { return x; }

void test92()
{
    int x = 3;
    int i = bar92(foo92(x));
    assert(i == 3);
}

/***************************************************/

struct Foo93
{
    public int foo() const
    {
        return 2;
    }
}

void test93()
{
    const Foo93 bar = Foo93();
    enum bla = bar.foo();
    assert(bla == 2);
}

/***************************************************/

struct Foo94
{
    int x, y;
    real z;
}

pure nothrow Foo94 makeFoo(const int x, const int y)
{
    return Foo94(x, y, 3.0);
}

void test94()
{
    auto f = makeFoo(1, 2);
    assert(f.x==1);
    assert(f.y==2);
    assert(f.z==3);
}

/***************************************************/

struct T95
{
    @disable this(this)
    {
    }
}

struct S95
{
    T95 t;
}

@disable void foo95() { }

struct T95A
{
    @disable this(this);
}

struct S95A
{
    T95A t;
}

@disable void foo95A() { }

void test95()
{
    S95 s;
    S95 t;
    static assert(!__traits(compiles, t = s));
    static assert(!__traits(compiles, foo95()));

    S95A u;
    S95A v;
    static assert(!__traits(compiles, v = u));
    static assert(!__traits(compiles, foo95A()));
}

/***************************************************/

struct S96(alias init)
{
    int[] content = init;
}

void test96()
{
    S96!([12, 3]) s1;
    S96!([1, 23]) s2;
    writeln(s1.content);
    writeln(s2.content);
    assert(!is(typeof(s1) == typeof(s2)));
}

/***************************************************/

struct A97
{
    const bool opEquals(ref const A97) { return true; }
    ref A97 opUnary(string op)() if (op == "++")
    {
        return this;
    }
}

void test97()
{
    A97 a, b;
    foreach (e; a .. b) {
    }
}

/***************************************************/

void test98()
{
    auto a = new int[2];
    // the name "length" should not pop up in an index expression
    static assert(!is(typeof(a[length - 1])));
}

/***************************************************/

string s99;

void bar99(string i)
{
}

void function(string) foo99(string i)
{
    return &bar99;
}

void test99()
{
    foo99 (s99 ~= "a") (s99 ~= "b");
    assert(s99 == "ab");
}

/***************************************************/

void test5081()
{
    static pure immutable(int[]) x()
    {
        return new int[](10);
    }

    static pure int[] y()
    {
        return new int[](10);
    }

    immutable a = x();
    immutable b = y();
}

/***************************************************/

void test100()
{
   string s;

   /* Testing order of evaluation */
   void delegate(string, string) fun(string) {
      s ~= "b";
      return delegate void(string, string) { s ~= "e"; };
   }
   fun(s ~= "a")(s ~= "c", s ~= "d");
   assert(s == "abcde", s);
}

/***************************************************/

void test101()
{
   int[] d1 = [ 6, 1, 2 ];
   byte[] d2 = [ 6, 1, 2 ];
   assert(d1 == d2);
   d2 ~= [ 6, 1, 2 ];
   assert(d1 != d2);
}

/***************************************************/

static assert([1,2,3] == [1.0,2,3]);

/***************************************************/

int transmogrify(uint) { return 1; }
int transmogrify(long) { return 2; }

void test103()
{
    assert(transmogrify(42) == 1);
}

/***************************************************/

int foo104(int x)
{
    int* p = &(x += 1);
    return *p;
}

int bar104(int *x)
{
    int* p = &(*x += 1);
    return *p;
}

void test104()
{
    auto i = foo104(1);
    assert(i == 2);
    i = bar104(&i);
    assert(i == 3);
}

/***************************************************/

ref int bump105(ref int x) { return ++x; }

void test105()
{
   int x = 1;
   bump105(bump105(x)); // two increments
   assert(x == 3);
}

/***************************************************/

pure int genFactorials(int n) {
    static pure int factorial(int n) {
      if (n==2) return 1;
      return factorial(2);
    }
    return factorial(n);
}

/***************************************************/

void test107()
{
    int[6] a;
    writeln(a);
    writeln(a.init);
    assert(a.init == [0,0,0,0,0,0]);
}

/***************************************************/

void bug4072(T)(T x)
   if (is(typeof(bug4072(x))))
{}

static assert(!is(typeof(bug4072(7))));

/***************************************************/

class A109 {}

void test109()
{
    immutable(A109) b;
    A109 c;
    auto z = true ? b : c;
    //writeln(typeof(z).stringof);
    static assert(is(typeof(z) == const(A109)));
}

/***************************************************/

template Boo(T) {}
struct Foo110(T, alias V = Boo!T)
{ pragma(msg, V.stringof);
  const s = V.stringof;
}
alias Foo110!double B110;
alias Foo110!int A110;

static assert(B110.s == "Boo!(double)");
static assert(A110.s == "Boo!(int)");

/***************************************************/

// 3716
void test111()
{
    auto k1 = true ? [1,2] : []; // OK
    auto k2 = true ? [[1,2]] : [[]];
    auto k3 = true ? [] : [[1,2]];
    auto k4 = true ? [[[]]] : [[[1,2]]];
    auto k5 = true ? [[[1,2]]] : [[[]]];
    auto k6 = true ? [] : [[[]]];
    static assert(!is(typeof(true ? [[[]]] : [[1,2]]))); // Must fail
}

/***************************************************/
// 4303

template foo112() if (__traits(compiles,undefined))
{
    enum foo112 = false;
}

template foo112() if (true)
{
    enum foo112 = true;
}

pragma(msg,__traits(compiles,foo112!()));
static assert(__traits(compiles,foo112!()));

const bool bar112 = foo112!();


/***************************************************/

struct File113
{
    this(int name) { }

    ~this() { }

    void opAssign(File113 rhs) { }

    struct ByLine
    {
        File113 file;

        this(int) { }

    }

    ByLine byLine()
    {
        return ByLine(1);
    }
}

auto filter113(File113.ByLine rs)
{
    struct Filter
    {
	this(File113.ByLine r) { }
    }

    return Filter(rs);
}

void test113()
{
    auto f = File113(1);
    auto rx = f.byLine();
    auto file = filter113(rx);
}

/***************************************************/

template foo114(fun...)
{
    auto foo114(int[] args)
    {
	return 1;
    }
}

pragma(msg, typeof(foo114!"a + b"([1,2,3])));

/***************************************************/
// Bugzilla 3935

struct Foo115 {
    void opBinary(string op)(Foo other) {
        pragma(msg, "op: " ~ op);
	assert(0);
    }
}

void test115()
{
    Foo115 f;
    f = f;
}

/***************************************************/
// Bugzilla 2477

void foo116(T,)(T t) { T x; }

void test116()
{
    int[] data = [1,2,3,];  // OK

    data = [ 1,2,3, ];  // fails
    auto i = data[1,];
    foo116!(int)(3);
    foo116!(int,)(3);
    foo116!(int,)(3,);
}

/***************************************************/
// Bugzilla 4291

void test117() pure
{
    mixin declareVariable;
    var = 42;
    mixin declareFunction;
    readVar();
}
template declareVariable() { int var; }
template declareFunction()
{
    int readVar() { return var; }
}

/***************************************************/
// Bugzilla 4177

pure real log118(real x) {
    if (__ctfe)
        return 0.0;
    else
        return 1.0;
}

enum x118 = log118(4.0);

void test118() {}

/***************************************************/

void bug4465()
{
    const a = 2 ^^ 2;
    int b = a;
}

/***************************************************/

pure void foo(int *p)
{
    *p = 3;
}

pure void test120()
{
    int i;
    foo(&i);
    assert(i == 3);
}

/***************************************************/
// 4866

immutable int[3] statik = [ 1, 2, 3 ];
enum immutable(int)[] dynamic = statik;

static assert(is(typeof(dynamic) == immutable(int)[]));
static if (! is(typeof(dynamic) == immutable(int)[]))
{
    static assert(0);   // (7)
}
pragma(msg, "!! ", typeof(dynamic));

/***************************************************/
// 2943

struct Foo2943
{
    int a;
    int b;
    alias b this;
}

void test122()
{
    Foo2943 foo, foo2;
    foo.a = 1;
    foo.b = 2;
    foo2.a = 3;
    foo2.b = 4;

    foo2 = foo;
    assert(foo2.a == foo.a);
}

/***************************************************/
// 4641

struct S123 {
    int i;
    alias i this;
}

void test123() {
    S123[int] ss;
    ss[0] = S123.init; // This line causes Range Violation.
}

/***************************************************/
// 2451

struct Foo124 {
    int z = 3;
    void opAssign(Foo124 x) { z= 2;}
}

struct Bar124 {
    int z = 3;
    this(this){ z = 17; }
}

void test124() {
    Foo124[string] stuff;
    stuff["foo"] = Foo124.init;
    assert(stuff["foo"].z == 2);

    Bar124[string] stuff2;
    Bar124 q;
    stuff2["dog"] = q;
    assert(stuff2["dog"].z == 17);   
}

/***************************************************/

void doNothing() {}

void bug5071(short d, ref short c) {
   assert(c==0x76);

    void closure() {
        auto c2 = c;
        auto d2 = d;
        doNothing();
    }
    auto useless = &closure;    
}

void test125()
{
   short c = 0x76;
   bug5071(7, c);
}

/***************************************************/

struct Foo126
{
   static Foo126 opCall(in Foo126 _f) pure
   {
       return _f;
   }
}

/***************************************************/

struct Tuple127(S...)
{
    S expand;
    alias expand this;
}

alias Tuple127!(int, int) Foo127;

void test127()
{
    Foo127[] m_array;
    Foo127 f;
    m_array ~= f;
}

/***************************************************/

struct Bug4434 {}
alias const Bug4434* IceConst4434;
alias shared Bug4434* IceShared4434;
alias shared Bug4434[] IceSharedArray4434;
alias immutable Bug4434* IceImmutable4434;
alias shared const Bug4434* IceSharedConst4434;

alias int MyInt4434;
alias const MyInt4434[3] IceConstInt4434;

alias immutable string[] Bug4830;

/***************************************************/
// 4254

void bub(const inout int other) {}

void test128()
{
    bub(1);
}


/***************************************************/

pure nothrow @safe auto bug4915a() {  return 0; }
pure nothrow @safe int  bug4915b() { return bug4915a(); }

void bug4915c()
{
    pure nothrow @safe int d() { return 0; }
    int e() pure nothrow @safe { return d(); }    
}

/***************************************************/
// 5164

static if (is(int Q == int, Z...))  { }

/***************************************************/
// 5195

alias typeof(foo5195) food5195;
const int * foo5195 = null;
alias typeof(foo5195) good5195;
static assert( is (food5195 == good5195));

/***************************************************/
// 5191

struct Foo129
{
    void add(T)(T value) nothrow
    {
        this.value += value;
    }

    this(int value)
    {
        this.value = value;
    }

    int value;
}

void test129()
{
    auto foo = Foo129(5);
    assert(foo.value == 5);

    foo.add(2);
    writeln(foo.value);
    assert(foo.value == 7);

    foo.add(3);
    writeln(foo.value);
    assert(foo.value == 10);

    foo.add(3);
    writeln(foo.value);
    assert(foo.value == 13);

    void delegate (int) nothrow dg = &foo.add!(int);    
    dg(7);
    assert(foo.value == 20);
}

/***************************************************/

const shared class C5107
{
}

static assert(is(C5107 ==  const)); // okay
static assert(is(C5107 == shared)); // fails!

/***************************************************/

immutable struct S3598
{
    static void funkcja() { }
}

/***************************************************/
// 4211

@safe struct X130
{
    void func() {  }
}

@safe class Y130
{
    void func() {  }
}

@safe void test130()
{
    X130 x;
    x.func();
    auto y = new Y130;
    y.func();
}

/***************************************************/

template Return(alias fun)
{
    static if (is(typeof(fun) R == return)) alias R Return;
}

interface I4217
{
    int  square(int  n);
    real square(real n);
}
alias Return!( __traits(getOverloads, I4217, "square")[0] ) R4217;
alias Return!( __traits(getOverloads, I4217, "square")[1] ) S4217;

static assert(! is(R4217 == S4217));

/***************************************************/
// 5094

void test131()
{
    S131 s;
    int[] conv = s;
}

struct S131
{
    @property int[] get() { return [1,2,3]; }
    alias get this;
}

/***************************************************/
// 5020

void test132()
{
    S132 s;
    if (!s) {}
}

struct S132
{
    bool cond;
    alias cond this;
}

/***************************************************/
// 5343

struct Tuple5343(Specs...)
{    
    Specs[0] field;
}    

struct S5343(E)
{
    immutable E x;
}
enum A5343{a,b,c}
alias Tuple5343!(A5343) TA5343;
alias S5343!(A5343) SA5343;

/***************************************************/
// 5365

interface IFactory
{
    void foo();
}

class A133
{
    protected static class Factory : IFactory
    {
        void foo()
        {
        }
    }

    this()
    {
        _factory = createFactory();
    }

    protected IFactory createFactory()
    {
        return new Factory;
    }

    private IFactory _factory;
    @property final IFactory factory()
    {
        return _factory;
    }

    alias factory this;
}

void test133()
{

    IFactory f = new A133;
    f.foo(); // segfault
}

/***************************************************/
// 5365

class B134
{
}

class A134
{

    B134 _b;

    this()
    {
        _b = new B134;
    }

    B134 b()
    {
        return _b;        
    }   

    alias b this;
}

void test134()
{

    auto a = new A134;
    B134 b = a; // b is null
    assert(a._b is b); // fails 
}

/***************************************************/
// 5025

struct S135 {
  void delegate() d;
}

void test135()
{
  shared S135[] s;
  if (0)
	s[0] = S135();
}

/***************************************************/
// 5545

bool enforce136(bool value, lazy const(char)[] msg = null) {
    if(!value) {
        return false;
    }

    return value;
}

struct Perm {
    byte[3] perm;
    ubyte i;

    this(byte[] input) {
        foreach(elem; input) {
            enforce136(i < 3);
            perm[i++] = elem;
            std.stdio.stderr.writeln(i);  // Never gets incremented.  Stays at 0.
        }
    }
}

void test136() {
    byte[] stuff = [0, 1, 2];
    auto perm2 = Perm(stuff);
    writeln(perm2.perm);  // Prints [2, 0, 0]
    assert(perm2.perm[] == [0, 1, 2]);
}

/***************************************************/
// 4097

void foo4097() { }
alias typeof(&foo4097) T4097;
static assert(is(T4097 X : X*) && is(X == function));

static assert(!is(X));

/***************************************************/
// 5798

void assign9(ref int lhs) pure {
    lhs = 9;
}

void assign8(ref int rhs) pure {
    rhs = 8;
}

int test137(){
    int a=1,b=2;
    assign8(b),assign9(a);
    assert(a == 9);
    assert(b == 8);   // <-- fail

    assign9(b),assign8(a);
    assert(a == 8);
    assert(b == 9);   // <-- fail

    return 0;
}

/***************************************************/

struct Size138
{
    union
    {
        struct
        {
            int width;
            int height;
        }
       
        long size;
    }
}

enum Size138 foo138 = {2 ,5};
    
Size138 bar138 = foo138;

void test138()
{
    assert(bar138.width == 2);
    assert(bar138.height == 5);
}

/***************************************************/

// 5939, 5940

template map(fun...)
{
    auto map(double[] r)
    {
        struct Result
        {
            this(double[] input)
            {
            }
        }

        return Result(r);
    }
}


void test139()
{
    double[] x;
    alias typeof(map!"a"(x)) T;
    T a = void;
    auto b = map!"a"(x);
    auto c = [map!"a"(x)];
    T[3] d;
}


/***************************************************/
// 5966

string[] foo5966(string[] a)
{
    a[0] = a[0][0..$];
    return a;
}

enum var5966 = foo5966([""]);

/***************************************************/
// 5975

int foo5975(wstring replace)
{
  wstring value = "";
  value ~= replace;
  return 1;
}

enum X5975 = foo5975("X"w);

/***************************************************/
// 5965

template mapx(fun...) if (fun.length >= 1)
{
    int mapx(Range)(Range r)
    {
        return 1;
    }
}

void test140()
{
   int foo(int i) { return i; }

   int[] arr;
   auto x = mapx!( function(int a){return foo(a);} )(arr);
}

/***************************************************/

void bug5976()
{
    int[] barr;
    int * k;
    foreach (ref b; barr)
    {
        scope(failure)
            k = &b;
        k = &b;
    }
} 

/***************************************************/
// 5771

struct S141
{
    this(A)(auto ref A a){}
}

void test141()
{
    S141 s = S141(10);
}

/***************************************************/
// 3688

struct S142
{
    int v;
    this(int n) { v = n; }
    const bool opCast(T:bool)() { return true; }
}

void test142()
{
    if (int a = 1)
        assert(a == 1);
    else assert(0);

    if (const int a = 2)
        assert(a == 2);
    else assert(0);

    if (immutable int a = 3)
        assert(a == 3);
    else assert(0);

    if (auto s = S142(10))
        assert(s.v == 10);
    else assert(0);

    if (auto s = const(S142)(20))
        assert(s.v == 20);
    else assert(0);

    if (auto s = immutable(S142)(30))
        assert(s.v == 30);
    else assert(0);
}

/***************************************************/
// 6072

static assert({
    if (int x = 5) {}
    return true;
}());

/***************************************************/
// 5959

int n;

void test143()
{
    ref int f(){ return n; }            // NG
    f() = 1;
    assert(n == 1);

    nothrow ref int f1(){ return n; }    // OK
    f1() = 2;
    assert(n == 2);

    auto ref int f2(){ return n; }       // OK
    f2() = 3;
    assert(n == 3);
}

/***************************************************/
// 6119

void startsWith(alias pred) ()   if (is(typeof(pred('c', 'd')) : bool))
{
}

void startsWith(alias pred) ()   if (is(typeof(pred('c', "abc")) : bool))
{
}

void test144()
{
    startsWith!((a, b) { return a == b; })();
} 

/***************************************************/

void test145()
{
    import std.c.stdio;
    printf("hello world 145\n");
}

void test146()
{
    test1();
    static import std.c.stdio;
    std.c.stdio.printf("hello world 146\n");
}

/***************************************************/
// 5856

struct X147
{
    void f()       { writeln("X.f mutable"); }
    void f() const { writeln("X.f const"); }

    void g()()       { writeln("X.g mutable"); }
    void g()() const { writeln("X.g const"); }

    void opOpAssign(string op)(int n)       { writeln("X+= mutable"); }
    void opOpAssign(string op)(int n) const { writeln("X+= const"); }
}

void test147()
{
    X147 xm;
    xm.f();     // prints "X.f mutable"
    xm.g();     // prints "X.g mutable"
    xm += 10;   // should print "X+= mutable" (1)

    const(X147) xc;
    xc.f();     // prints "X.f const"
    xc.g();     // prints "X.g const"
    xc += 10;   // should print "X+= const" (2)
}


/***************************************************/
// 5897

struct A148{ int n; }
struct B148{
    int n, m;
    this(A148 a){ n = a.n, m = a.n*2; }
}

struct C148{
    int n, m;
    static C148 opCall(A148 a)
    {
        C148 b;
        b.n = a.n, b.m = a.n*2;
        return b;
    }
}

void test148()
{
    auto a = A148(10);
    auto b = cast(B148)a;
    assert(b.n == 10 && b.m == 20);
    auto c = cast(C148)a;
    assert(c.n == 10 && c.m == 20);
}

/***************************************************/
// 4969

class MyException : Exception
{
    this()
    {
        super("An exception!");
    }
}

void throwAway()
{
    throw new MyException;
}

void cantthrow() nothrow
{
    try
        throwAway();
    catch(MyException me)
        assert(0);
    catch(Exception e)
        assert(0);
}

/***************************************************/

class A2540
{
    int a;
    int foo() { return 0; }
    alias int X;
}

class B2540 : A2540
{
    int b;
    super.X foo() { return 1; }

    alias this athis;
    alias this.b thisb;
    alias super.a supera;
    alias super.foo superfoo;
    alias this.foo thisfoo;
}

struct X2540
{
    alias this athis;
}

void test2540()
{
    auto x = X2540.athis.init;
    static assert(is(typeof(x) == X2540));

    B2540 b = new B2540();

    assert(&b.a == &b.supera);
    assert(&b.b == &b.thisb);
    assert(b.thisfoo() == 1);
}

/***************************************************/
// 5659 
 
void test149() 
{ 
    import std.traits; 
 
    char a; 
    immutable(char) b; 
 
    static assert(is(typeof(true ? a : b) == const(char))); 
    static assert(is(typeof([a, b][0]) == const(char))); 
 
    static assert(is(CommonType!(typeof(a), typeof(b)) == const(char))); 
} 
 

/***************************************************/
// 1373

void func1373a(){}

static assert(typeof(func1373a).stringof == "void()");
static assert(typeof(func1373a).mangleof == "FZv");
static assert(!__traits(compiles, typeof(func1373a).alignof));
static assert(!__traits(compiles, typeof(func1373a).init));
static assert(!__traits(compiles, typeof(func1373a).offsetof));

void func1373b(int n){}

static assert(typeof(func1373b).stringof == "void(int n)");
static assert(typeof(func1373b).mangleof == "FiZv");
static assert(!__traits(compiles, typeof(func1373b).alignof));
static assert(!__traits(compiles, typeof(func1373b).init));
static assert(!__traits(compiles, typeof(func1373b).offsetof));

/***************************************************/

void bar150(T)(T n) {  }

@safe void test150()
{
    bar150(1);
}

/***************************************************/

void test5785()
{
    static struct x { static int y; }
    assert(x.y !is 1);
    assert(x.y !in [1:0]);
}

/***************************************************/

void bar151(T)(T n) {  }

nothrow void test151()
{
    bar151(1);
}

/***************************************************/

@property int coo() { return 1; }
@property auto doo(int i) { return i; }

@property int eoo() { return 1; }
@property auto ref hoo(int i) { return i; }

// 3359

int goo(int i) pure { return i; }
auto ioo(int i) pure { return i; }
auto ref boo(int i) pure nothrow { return i; }

class A152 {
    auto hoo(int i) pure  { return i; }
    const boo(int i) const { return i; }
    auto coo(int i) const { return i; }
    auto doo(int i) immutable { return i; }
    auto eoo(int i) shared { return i; }
} 

// 4706

struct Foo152(T) {
    @property auto ref front() {
        return T.init;
    }

    @property void front(T num) {}
}

void test152() {
    Foo152!int foo;
    auto a = foo.front;
    foo.front = 2;
}


/***************************************************/
// 3799

void test153()
{
    void bar()
    {
    }

    static assert(!__traits(isStaticFunction, bar));
}

/***************************************************/
// 3632


void test154() {
    float f;
    assert(f is float.init);
    double d;
    assert(d is double.init);
    real r;
    assert(r is real.init);

    assert(float.nan is float.nan);
    assert(double.nan is double.nan);
    assert(real.nan is real.nan);
}

/***************************************************/
// 3147


void test155()
{
    byte b = 1;
    short s;
    int i;
    long l;

    s = b + b;
    b = s % b;
    s = s >> b;
    b = 1;
    b = i % b;
    b = b >> i;
}

/***************************************************/
// 2521

immutable int val = 23;
const int val2 = 23;

ref immutable(int) func2521_() {
    return val;
}
ref immutable(int) func2521_2() {
    return *&val;
}
ref immutable(int) func2521_3() {
    return func2521_;
}
ref const(int) func2521_4() {
    return val2;
}
ref const(int) func2521_5() {
    return val;
}
auto ref func2521_6() {
    return val;
}
ref func2521_7() {
    return val;
}

/***************************************************/
// 5962

struct S156
{
          auto g()(){ return 1; }
    const auto g()(){ return 2; }
}

void test156()
{
    auto ms = S156();
    assert(ms.g() == 1);
    auto cs = const(S156)();
    assert(cs.g() == 2);
}

/***************************************************/
// 4258

struct Vec4258 {
    Vec4258 opOpAssign(string Op)(auto ref Vec4258 other) if (Op == "+") {
        return this;
    }
    Vec4258 opBinary(string Op:"+")(Vec4258 other) {
        Vec4258 result;
        return result += other;
    }
}
void test4258() {
    Vec4258 v;
    v += Vec4258() + Vec4258(); // line 12
}

// regression fix test

struct Foo4258 {
    // binary ++/--
    int opPostInc()() if (false) { return 0; }

    // binary 1st
    int opAdd(R)(R rhs) if (false) { return 0; }
    int opAdd_r(R)(R rhs) if (false) { return 0; }

    // compare
    int opCmp(R)(R rhs) if (false) { return 0; }

    // binary-op assign
    int opAddAssign(R)(R rhs) if (false) { return 0; }
}
struct Bar4258 {
    // binary commutive 1
    int opAdd_r(R)(R rhs) if (false) { return 0; }

    // binary-op assign
    int opOpAssign(string op, R)(R rhs) if (false) { return 0; }
}
struct Baz4258 {
    // binary commutive 2
    int opAdd(R)(R rhs) if (false) { return 0; }
}
static assert(!is(typeof(Foo4258.init++)));
static assert(!is(typeof(Foo4258.init + 1)));
static assert(!is(typeof(1 + Foo4258.init)));
static assert(!is(typeof(Foo4258.init < Foo4258.init)));
static assert(!is(typeof(Foo4258.init += 1)));
static assert(!is(typeof(Bar4258.init + 1)));
static assert(!is(typeof(Bar4258.init += 1)));
static assert(!is(typeof(1 + Baz4258.init)));

/***************************************************/
// 1471

void test1471()
{
	int n;
	string bar = "BOOM"[n..$-1];
	assert(bar == "BOO");
}

/***************************************************/

void test4963()
{
    struct Value {
        byte a;
    };
    Value single()
    {
        return Value();
    }

    Value[] list;
    auto x = single() ~ list;
}

/***************************************************/ 

pure int test4031() 
{ 
    static const int x = 8; 
    return x; 
} 
 
/***************************************************/
// 6228


void test6228()
{
    const(int)* ptr;
    const(int)  temp;
    auto x = (*ptr) ^^ temp;
}

/***************************************************/

struct S6230 {
    int p;
    int q() const pure {
        return p;
    }
    void r() pure {
        p = 231;
    }
}
class C6230 {
    int p;
    int q() const pure {
        return p;
    }
    void r() pure {
        p = 552;
    }
}
int q6230(ref const S6230 s) pure {    // <-- Currently OK
    return s.p;
}
int q6230(ref const C6230 c) pure {    // <-- Currently OK
    return c.p;
}
void r6230(ref S6230 s) pure {
    s.p = 244;
}
void r6230(ref C6230 c) pure {
    c.p = 156;
}
bool test6230pure() pure {
    auto s = S6230(4);
    assert(s.p == 4);
    assert(q6230(s) == 4);
    assert(s.q == 4);

    auto c = new C6230;
    c.p = 6;
    assert(q6230(c) == 6);
    assert(c.q == 6);

    r6230(s);
    assert(s.p == 244);
    s.r();
    assert(s.p == 231);

    r6230(c);
    assert(c.p == 156);
    c.r();
    assert(c.p == 552);

    return true;
}
void test6230() {
    assert(test6230pure());
}

/***************************************************/

void test6264()
{
    struct S { auto opSlice() { return this; } }
    int[] a;
    S s;
    static assert(!is(typeof(a[] = s[])));
    int*[] b;
    static assert(!is(typeof(b[] = [new immutable(int)])));
    char[] c = new char[](5);
    c[] = "hello";
}

/***************************************************/
// 5046 
 
void test5046() 
{ 
    auto va = S5046!("", int)(); 
    auto vb = makeS5046!("", int)(); 
} 
 
struct S5046(alias p, T) 
{ 
    T s; 
    T fun() { return s; }   // (10) 
} 
 
S5046!(p, T) makeS5046(alias p, T)() 
{ 
    return typeof(return)(); 
} 
 
/***************************************************/ 
// 6335

struct S6335
{
    const int value;
    this()(int n){ value = n; }
}
void test6335()
{
    S6335 s = S6335(10);
}

/***************************************************/ 

struct S6295(int N) {
    int[N] x;
    const nothrow pure @safe f() { return x.length; }
}

void test6295() {
    auto bar(T: S6295!(N), int N)(T x) {
        return x.f();
    }
    S6295!4 x;
    assert(bar(x) == 4);
}

/***************************************************/

struct S6284 {
    int a;
}
class C6284 {
    int a;
}
pure int bug6284a() {
    S6284 s = {4};
    auto b = s.a;   // ok
    with (s) {
        b += a;     // should be ok.
    }
    return b;
}
pure int bug6284b() {
    auto s = new S6284;
    s.a = 4;
    auto b = s.a;
    with (*s) {
        b += a;
    }
    return b;
}
pure int bug6284c() {
    auto s = new C6284;
    s.a = 4;
    auto b = s.a;
    with (s) {
        b += a;
    }
    return b;
}
void test6284() {
    assert(bug6284a() == 8);
    assert(bug6284b() == 8);
    assert(bug6284c() == 8);
}

/***************************************************/

class C6293 {
    C6293 token;
}
void f6293(in C6293[] a) pure {
    auto x0 = a[0].token;
    assert(x0 is a[0].token.token.token);
    assert(x0 is (&x0).token);
    auto p1 = &x0 + 1;
    assert(x0 is (p1 - 1).token);
    int c = 0;
    assert(x0 is a[c].token);
}
void test6293() {
    auto x = new C6293;
    x.token = x;
    f6293([x]);
}

/***************************************************/
// 2774

int foo2774(int n){ return 0; }
static assert(foo2774.mangleof == "_D7xtest467foo2774FiZi");

class C2774
{
    int foo2774(){ return 0; }
}
static assert(C2774.foo2774.mangleof == "_D7xtest465C27747foo2774MFZi");

template TFoo2774(T){}
static assert(TFoo2774!int.mangleof == "7xtest4615__T8TFoo2774TiZ");

void test2774()
{
    int foo2774(int n){ return 0; }
    static assert(foo2774.mangleof == "_D7xtest468test2774FZv7foo2774MFiZi");
}

/***************************************************/
// 6220

void test6220() {
    struct Foobar { real x; real y; real z;};
    switch("x") {
        foreach(i,member; __traits(allMembers, Foobar)) {
            case member : break;
        }
    default : break;
    }
}

/***************************************************/
// 5799

void test5799()
{
    int a;
    int *u = &(a ? a : (a ? a : a));
    assert(u == &a);
}

/***************************************************/

int main()
{
    test1();
    test2();
    test3();
    test4();
    test5();
    test6();
    test7();
    test8();
    test9();
    test10();
    test11();
    test12();
    test13();
    test14();
    test15();
    test16();
    test17();
    test18();
    test19();
    test20();
    test21();
    test22();
    test23();
    test24();
    test25();
    test26();
    test27();
    test28();
    test29();
    test30();
    test31();
    test32();
    test33();
    test34();
    test35();
    test36();
    test37();
    test38();
    test39();
    test40();
    test41();
    test42();
    test43();
    test44();
    test45();
    test46();
    test47();
    test48();
    test49();
    test50();
    test51();
    test52();
    test53();
    test54();
    test55();
    test56();
    test57();
    test58();

    test60();
    test61();
    test62();
    test63();
    test64();
    test65();
    test66();
    test67();
    test68();
    test69();
    test70();

    test5785();
    test72();
    test73();
    test74();
    test75();
    test76();
    test77();
    test78();
    test79();
    test80();
    test81();
    test82();
    test83();
    test84();
    test85();
    test86();
    test87();
    test88();
    test89();
    test90();
    test91();
    test92();
    test93();
    test94();
    test95();
    test96();
    test97();
    test98();
    test99();
    test100();
    test101();

    test103();
    test104();
    test105();

    test107();

    test109();

    test111();

    test113();

    test115();
    test116();
    test117();
    test118();
    test5081();

    test120();

    test122();
    test123();
    test124();
    test125();

    test127();
    test128();
    test129();
    test130();
    test131();
    test132();
    test133();
    test134();
    test135();
    test136();
    test137();
    test138();
    test139();
    test140();
    test141();
    test6317();
    test142();
    test143();
    test144();
    test145();
    test146();
    test147();
    test148();
    test149();
    test2540();
    test150();
    test151();
    test152();
    test153();
    test154();
    test155();
    test156();
    test4258();
    test4963();
    test4031();
    test6230();
    test6264();
    test6284();
    test6295();
    test6293();
    test5046();
    test1471();
    test6335();
    test6228();
    test2774();
    test6220();
    test5799();

    printf("Success\n");
    return 0;
}
