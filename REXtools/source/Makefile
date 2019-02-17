#
# defines
#
# djs Use CC env variable - set in eclipse project settings if needed this for linux/bucky: CC		=	gcc-4.1
# djs use MATLAB_HOME env variable MATLAB	=	/opt/matlab
# djs override CC and CXX in ~/.matlab/mexopts.sh setting them here does not work? 

# DJS specify location of boost libs
BOOST_LIBS = /usr/lib

MEX		=	$(MATLAB_HOME)/bin/mex
MEXFLAGS=	-I$(MATLAB_HOME)/extern/include -DMATLAB_MEX_FILE -v
#added fir mac? says not needed above. Should test this...
#ENVOPTS = 'CC=gcc-4.4 CXX=g++-4.4'
ECFILE_SRCS =	ecfile.c
ECI_SRCS	=	ecid.c $(ECFILE_SRCS)
EFILE_SRCS	=	efile.c $(ECFILE_SRCS)
ECENCODE_SRCS	=	ecencode.c
ECMATCH_SRCS = ecmatch.c
ECULL_SRCS = ecull.c ecfile.c ecfile.h
ECULL_OBJS = ecull.o ecfile.o
EDUMP_SRCS = edump.c ecfile.c ecfile.h
EDUMP_OBJS = edump.o ecfile.o
MAKESERIES_SRCS = makeseries.c 
MAKEESERIES_SRCS = makeeseries.c
TMAT_SRCS = tmat.cpp
TMAT_OBJS = tmat.o
TMAT_FLAGS = -I../librender/src/util -L../librender/Release -lrender

# Don't include this in the sources - it is compiled in automatically. 
# $(MATLAB)/extern/src/mexversion.c

all : ecid efile makeseries ecencode tmat

clean:
# this needs to depend on platform and 32/64. below works on linux amd64
	rm -f ecm.mexa64 ecf.mexa64 ecfile.mexa64 makeseries.mexa64 ecull $(ECULL_OBJS) edump $(EDUMP_OBJS) ecmatch.mexa64 $(TMAT_OBJS) tmat.mexa64

ecid	: $(ECI_SRCS)
	$(MEX) $(MEXFLAGS) $(ECI_SRCS)
	
efile	: $(EFILE_SRCS)
	$(MEX) $(MEXFLAGS) $(EFILE_SRCS)

ecencode	: $(ECENCODE_SRCS)
	$(MEX) $(MEXFLAGS) $(ECENCODE_SRCS)

ecmatch		: $(ECMATCH_SRCS)
	$(MEX) $(MEXFLAGS) $(ECMATCH_SRCS)

makeseries	: $(MAKESERIES_SRCS)
	$(MEX) $(MEXFLAGS) $(MAKESERIES_SRCS) $(BOOST_LIBS)/libboost_regex.so

ecull.o : ecull.c ecfile.h
	$(CC) $(CFLAGS) -c ecull.c

edump.o : edump.c ecfile.h
	$(CC) $(CFLAGS) -c edump.c

ecfile.o : ecfile.c ecfile.h
	$(CC) $(CFLAGS) -c ecfile.c

ecull :	$(ECULL_OBJS)
	$(CC) -o ecull $(ECULL_OBJS)
	
edump :	$(EDUMP_OBJS)
	$(CC) $(CFLAGS) -o edump $(EDUMP_OBJS)

tmat : $(TMAT_SRCS)
	$(MEX) $(MEXFLAGS) $(TMAT_FLAGS) $(TMAT_SRCS)
	

	
ifdef INSTALL_DIR
INSTALLED_FILES = $(INSTALL_DIR)/efile.mexmaci $(INSTALL_DIR)/makeseries.mexmaci $(INSTALL_DIR)/ecencode.mexmaci
INSTALL_FILES = efile.mexmaci makeseries.mexmaci ecencode.mexmaci

$(INSTALL_DIR)/efile.mexmaci : efile

$(INSTALL_DIR)/makeseries.mexmaci : makeseries

$(INSTALL_DIR)/ecencode.mexmaci : ecencode

install : $(INSTALLED_FILES)
	install -v $(INSTALL_FILES) $(INSTALL_DIR)
	
else
install : 
	echo "INSTALL_DIR not defined!"
	
endif
