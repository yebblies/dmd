
// Basic Types - return

void func_void_void();
void func_void_int_varargs(int a, ...);

#define BASIC_TYPES() \
    X(bool, bool) \
    X(char, char) \
    X(wchar, wchar_t) \
    X(byte, signed char) \
    X(ubyte, unsigned char) \
    X(short, signed short int) \
    X(ushort, unsigned short int) \
    X(int, signed int) \
    X(uint, unsigned int) \
    X(long, signed long long int) \
    X(ulong, unsigned long long int) \
    X(float, float) \
    X(double, double) \
    X(real, long double) \
    X(ifloat, _Imaginary float) \
    X(idouble, _Imaginary double) \
    X(ireal, _Imaginary long double) \
    X(cfloat, _Complex float) \
    X(cdouble, _Complex double) \
    X(creal, _Complex long double)

#define X(name, type) type func_##name##_void();
BASIC_TYPES()
#undef X

#define X(name, type) void func_void_##name(type a);
BASIC_TYPES()
#undef X

#define X(name, type) type func_##name##_##name(type a);
BASIC_TYPES()
#undef X

#define X(name, type) type func_##name##_##name##_##name##_##name(type a, type b, type c);
BASIC_TYPES()
#undef X

void basictypes()
{
#define X(name, type) func_void_##name(func_##name##_##name##_##name##_##name(func_##name##_##name(func_##name##_void()), func_##name##_void(), func_##name##_void()));
BASIC_TYPES()
#undef X
}



#define X(name, type) const type func_const##name##_void();
BASIC_TYPES()
#undef X

#define X(name, type) void func_void_const##name(const type a);
BASIC_TYPES()
#undef X

#define X(name, type) const type func_const##name##_const##name(const type a);
BASIC_TYPES()
#undef X

#define X(name, type) const type func_const##name##_const##name##_const##name##_const##name(const type a, const type b, const type c);
BASIC_TYPES()
#undef X

void constbasictypes()
{
#define X(name, type) func_void_const##name(func_const##name##_const##name##_const##name##_const##name(func_const##name##_const##name(func_const##name##_void()), func_const##name##_void(), func_const##name##_void()));
BASIC_TYPES()
#undef X
}


#define POINTER_TYPES() \
    X(voidptr, void *) \
    X(boolptr, bool *) \
    X(charptr, char *) \
    X(wcharptr, wchar_t *) \
    X(byteptr, signed char *) \
    X(ubyteptr, unsigned char *) \
    X(shortptr, signed short int *) \
    X(ushortptr, unsigned short int *) \
    X(intptr, signed int *) \
    X(uintptr, unsigned int *) \
    X(longptr, signed long long int *) \
    X(ulongptr, unsigned long long int *) \
    X(floatptr, float *) \
    X(doubleptr, double *) \
    X(realptr, long double *) \
    X(ifloatptr, _Imaginary float *) \
    X(idoubleptr, _Imaginary double *) \
    X(irealptr, _Imaginary long double *) \
    X(cfloatptr, _Complex float *) \
    X(cdoubleptr, _Complex double *) \
    X(crealptr, _Complex long double *)

#define X(name, type) type func_##name##_void();
POINTER_TYPES()
#undef X

#define X(name, type) void func_void_##name(type a);
POINTER_TYPES()
#undef X

#define X(name, type) type func_##name##_##name(type a);
POINTER_TYPES()
#undef X

#define X(name, type) type func_##name##_##name##_##name##_##name(type a, type b, type c);
POINTER_TYPES()
#undef X

void pointertypes()
{
#define X(name, type) func_void_##name(func_##name##_##name##_##name##_##name(func_##name##_##name(func_##name##_void()), func_##name##_void(), func_##name##_void()));
POINTER_TYPES()
#undef X
}


void main()
{
    func_void_void();
    func_void_int_varargs(3, 1, 2, 3);

    basictypes();
    constbasictypes();
    pointertypes();
}
