// Copyright (C) 2000-2011 by Digital Mars
// All Rights Reserved

module root.rmem;

alias void function(void* pObj, void* pClientData) FINALIZERPROC;

struct GC;                      // thread specific allocator

extern(C++)
struct Mem
{
    GC *gc = null;                     // pointer to our thread specific allocator

    void init();

    // Derive from Mem to get these storage allocators instead of global new/delete
    char *strdup(const char *s);
    void *malloc(size_t size);
    void *malloc_uncollectable(size_t size);
    void *calloc(size_t size, size_t n);
    void *realloc(void *p, size_t size);
    void free(void *p);
    void free_uncollectable(void *p);
    void *mallocdup(void *o, size_t size);
    void error();
    void check(void *p);        // validate pointer
    void fullcollect();         // do full garbage collection
    void fullcollectNoStack();  // do full garbage collection, no scan stack
    void mark(void *pointer);
    void addroots(char* pStart, char* pEnd);
    void removeroots(char* pStart);
    void setFinalizer(void* pObj, FINALIZERPROC pFn, void* pClientData);
    void setStackBottom(void *bottom);
    GC *getThreadGC();          // get apartment allocator for this thread
};

extern extern(C++) Mem mem;

