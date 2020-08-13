MEX = /Applications/MATLAB/MATLAB_R2013b.app/bin/maci64/mex
# MEX = /Applications/MATLAB_R2013b.app/bin/maci64/mex

MEX_OPTS = -O
INCLUDE_DIRS =
LIB_DIRS =
EXTRA_LIBS =
MEX_CMD = $(MEX) $(MEX_OPTS) $(INCLUDE_DIRS) $(LIB_DIRS) $(EXTRA_LIBS)
DEST_DIR = /usr/local/MATLAB/Shared/usb1208FSPlusInterface

all:	units data veps

units: Plexon_LP64.h
	$(MEX_CMD) -o extractPLXunits extractPLXunits.cpp

data: Plexon_LP64.h
	$(MEX_CMD) -o extractPLXdata extractPLXdata.cpp

veps: Plexon_LP64.h
	$(MEX_CMD) -o extractEventTriggeredTraces extractEventTriggeredTraces.cpp

open: mccDevice.o mccDevice.h datatypesandstatics.h usb1208FSPlusInterface.h
	$(MEX_CMD) -o usb1208FSPlusOpenInterface usb1208FSPlusOpenInterface.cpp mccDevice.o

close: mccDevice.o mccDevice.h datatypesandstatics.h usb1208FSPlusInterface.h
	$(MEX_CMD) -o usb1208FSPlusCloseInterface usb1208FSPlusCloseInterface.cpp mccDevice.o

start: mccDevice.o mccDevice.h datatypesandstatics.h usb1208FSPlusInterface.h
	$(MEX_CMD) -o usb1208FSPlusStartRecording usb1208FSPlusStartRecording.cpp mccDevice.o

stop: mccDevice.o mccDevice.h datatypesandstatics.h usb1208FSPlusInterface.h
	$(MEX_CMD) -o usb1208FSPlusStopRecording usb1208FSPlusStopRecording.cpp mccDevice.o

strobe: mccDevice.o mccDevice.h datatypesandstatics.h usb1208FSPlusInterface.h
	$(MEX_CMD) -o usb1208FSPlusStrobe usb1208FSPlusStrobe.cpp mccDevice.o
	$(MEX_CMD) -o usb1208FSPlusSetStrobe usb1208FSPlusSetStrobe.cpp mccDevice.o

set: mccDevice.o mccDevice.h datatypesandstatics.h usb1208FSPlusInterface.h
	$(MEX_CMD) -o usb1208FSPlusSetEvent usb1208FSPlusSetEvent.cpp mccDevice.o
	$(MEX_CMD) -o usb1208FSPlusSetAnalog usb1208FSPlusSetAnalog.cpp mccDevice.o
	$(MEX_CMD) -o usb1208FSPlusSendMessage usb1208FSPlusSendMessage.cpp mccDevice.o

threads: mccDevice.o mccDevice.h datatypesandstatics.h usb1208FSPlusInterface.h
	$(MEX_CMD) -lrt -o threadTest threadTest.cpp mccDevice.o
	$(MEX_CMD) -lrt -o cancelThread cancelThread.cpp mccDevice.o


test: mccDevice.o mccDevice.h datatypesandstatics.h usb1208FSPlusInterface.h
	$(MEX_CMD) -o testAsync testAsync.cpp mccDevice.o
	$(MEX_CMD) -o testUSBSpeed testUSBSpeed.cpp mccDevice.o
	g++  $(INCLUDE_DIRS) -o asynchTest_nonMex asynchTest_nonMex.cpp mccDevice.o

clean:
	rm *mexmaci64 *.o

install:
	@[ -d $(DEST_DIR) ] || mkdir -p $(DEST_DIR)
	cp *.m *.mexa64 *.sh $(DEST_DIR)
