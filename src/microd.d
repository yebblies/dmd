
import core.stdc.stdio;

__gshared int global = 3;

struct S
{
    int a;
    void fun()
    {
        printf("member a: %d\n", a);
    }
}

int main()
{
    uint x;
    foreach(i; 0..20)
    {
        x += i;
    }

    printf("%d\n", x);

    S y = S(7);
    y.a += 5;
    y.fun();
    return 0;
}