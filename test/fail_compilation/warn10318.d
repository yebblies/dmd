// REQUIRED_ARGS: -w
// PERMUTE_ARGS:

/*
TEST_OUTPUT:
---
fail_compilation/warn10318.d(25): Error: array property 'sort' is deprecated
fail_compilation/warn10318.d(26): Error: array property 'reverse' is deprecated
---
*/

void main()
{
    int[] x;
    x.sort;
    x.reverse;
}
