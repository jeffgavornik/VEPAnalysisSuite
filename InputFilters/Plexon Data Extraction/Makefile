UNAME := $(shell uname)

ifeq ($(UNAME),Darwin)
MEX = /Applications/MATLAB_R2014b.app/bin/mex
#MEX = /Applications/MATLAB_R2015a.app/bin/mex
INCLUDE_DIRS = -I/opt/local/include/libusb-1.0
LIB_DIRS = -L/opt/local/lib -lusb-1.0 -lpthread
DEST_DIR = /usr/local/MATLAB/Shared/usb1208FSPlusInterface
CPP_CMD = clang++
CLEAN_CMD = rm *mexmaci64
endif

ifeq ($(UNAME),Linux)
MEX = mex
INCLUDE_DIRS = -I/lib/x86_64-linux-gnu -I/usr/local/include/libusb-1.0/
LIB_DIRS =  -L/usr/local/lib -lusb-1.0 -lpthread
DEST_DIR = /usr/local/MATLAB/Shared/usb1208FSPlusInterface
CPP_CMD = g++ -std=c++11
CLEAN_CMD = rm *mexa64
endif

MEX_OPTS = -O
EXTRA_LIBS =
MEX_CMD = $(MEX) $(MEX_OPTS) $(INCLUDE_DIRS) $(LIB_DIRS) $(EXTRA_LIBS)

all:	common units veps

common: Plexon_LP64.h
	$(MEX_CMD) -output extractEventTriggeredTraces extractEventTriggeredTraces.cpp
	$(MEX_CMD) -output plxProfiler plxProfiler.cpp

units: Plexon_LP64.h
	$(MEX_CMD) -output extractPLXunit extractPLXunit.cpp
	$(MEX_CMD) -output getPlxSpikeChannelData getPlxSpikeChannelData.cpp

data: Plexon_LP64.h
	# $(MEX_CMD) -output extractPLXdata extractPLXdata.cpp

veps: Plexon_LP64.h
	$(MEX_CMD) -output extractPLXad extractPLXad.cpp 
	$(MEX_CMD) -output extractEventTriggeredTraces extractEventTriggeredTraces.cpp

clean:
	$(CLEAN_CMD)

print-%  : ; @echo $* = $($*)