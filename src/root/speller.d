
module root.speller;

extern(C++):

alias void function(void *, const(char) *) fp_speller_t;

extern const(char)* idchars;

void *speller(const(char)* seed, fp_speller_t fp, void* fparg, const(char)* charset);

