
// Copyright (c) 1999-2009 by Digital Mars
// All Rights Reserved
// written by Walter Bright
// http://www.digitalmars.com

module root.port;

// Portable wrapper around compiler/system specific things.
// The idea is to minimize #ifdef's in the app code.

alias long longlong;
alias ulong ulonglong;

alias double d_time;
alias wchar wchar_t;

struct Port
{
    static double nan;
    static double infinity;
    static double dbl_max;
    static double dbl_min;
    static real ldbl_max;

    static int isNan(double);
    static int isNan(real);

    static int isSignallingNan(double);
    static int isSignallingNan(real);

    static int isFinite(double);
    static int isInfinity(double);
    static int Signbit(double);

    static double floor(double);
    static double pow(double x, double y);

    static real fmodl(real x, real y);

    static ulonglong strtoull(const char *p, char **pend, int base);

    static char *ull_to_string(char *buffer, ulonglong ull);
    static wchar_t *ull_to_string(wchar_t *buffer, ulonglong ull);

    // Convert ulonglong to double
    static double ull_to_double(ulonglong ull);

    // Get locale-dependent list separator
    static const(char)* list_separator();
    static const(wchar_t)* wlist_separator();

    static char *strupr(char *);
};

