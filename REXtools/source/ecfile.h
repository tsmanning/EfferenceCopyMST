#ifndef ECODEFILEHEADER
#define ECODEFILEHEADER

#define ECFILE_SKIP_ACODES 0x1
#define ECFILE_SKIP_BCODES 0x2
#define ECFILE_IGNORE_SEQUENCE 0x4

struct event_struct
{
	unsigned short seqno;
	short ecode;
	int time;
};

typedef struct event_struct Event;
typedef struct event_struct *PEvent;

struct ecfs_struct
{
	int time;
	int counter;
	short int code;
	int chan;
	short int type;
	unsigned int U;
	int I;
	float F;
	double V;
	int id;
};

typedef struct ecfs_struct ECFS;
typedef struct ecfs_struct *PECFS;

struct ecode_info {
   short ecode;
   int  time;
};

typedef struct ecfile_itf ECFile;
typedef struct ecfile_itf* PECFile;

struct ecfile_itf {
	int ncodes;
	struct ecfile_priv *priv;
	int (*next)(ECFile *, PEvent, PECFS);
	PEvent (*make_event)(ECFile *, PEvent, unsigned short, short, int);
	char* (*get_header)(ECFile *this, char *h);
	void (*rewind)(ECFile *);
};

void ecfile_verbose(int i);
void ecfile_destroy(ECFile *);
ECFile *ecfile_new(const char *, int flag);
ECFile *ecsock_new(void);

#endif
