/*
TEST_OUTPUT:
---
fail_compilation/ice10949.d(11): Deprecation: Using the result of a comma expression is deprecated
fail_compilation/ice10949.d(11): Error: array index 3 is out of bounds [5, 5][0 .. 2]
fail_compilation/ice10949.d(11): Error: array index 17 is out of bounds [2, 3][0 .. 2]
fail_compilation/ice10949.d(11): Error: array index 9 is out of bounds [3, 3, 3][0 .. 3]
---
*/
int global;
static assert((((((([5,5][3] + global - global)*global/global%global)>>global) &global|global)^global) == 9, [2,3][17]) || ([3,3,3][9] is 4) && ([[1,2,3]][4]).length);
