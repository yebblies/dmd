
struct S
{
    immutable uint i;
    
    void fun()
    {
        enum uint j = i;
    }
}

void main()
{
    
}