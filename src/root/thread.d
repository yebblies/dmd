
module root.thread;

alias int ThreadId;

extern(C++)
struct Thread
{
    static ThreadId getId();
};


