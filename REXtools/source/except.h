#ifndef EXCEPTIONHEADER
#define EXCEPTIONHEADER

void trace(const char *, ...);
void poptrace(void);
void clrtrace(void);
void throw(const char *, ...);
void catch(void (*)(const char *));
void popcatch(void);

#endif
