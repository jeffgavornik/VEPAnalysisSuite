

#include "mex.h"
#include <math.h>
#include <fstream>
#include "Plexon_LP64.h"

#define INT8  1 // 1 byte, equivalent to char
#define INT16 2 // 2 bytes, equivalent to short int
#define INT32 4 // 4 bytes, equivalent to long int
#define MAXWORDS 1024 // buffer size for a/d data

#define MAXSAMPLES 10000000
#define MAXEVENTS 100000

#define EVCH 257

using namespace std;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    int * intPtr;
    
    mexPrintf("sizeof(int)=%i, sizeof(double)=%i, sizeof(char)=%i\n",
            sizeof(int),sizeof(double),sizeof(char));
    mexPrintf("sizeof(short)=%i, sizeof(long)=%i\n",
            sizeof(short),sizeof(long));
    mexPrintf("sizeof(*int)=%i\n",sizeof(intPtr));
    
    mexPrintf("sizeof(DigFileHeader)=%i\n",sizeof(DigFileHeader));
    mexPrintf("sizeof(PL_ServerArea)=%i\n",sizeof(PL_ServerArea));
    mexPrintf("sizeof(PL_Event)=%i\n",sizeof(PL_Event));
    mexPrintf("sizeof(PL_Wave)=%i\n",sizeof(PL_Wave));
    mexPrintf("sizeof(PL_WaveLong)=%i\n",sizeof(PL_WaveLong));
    mexPrintf("sizeof(PL_FileHeader)=%i\n",sizeof(PL_FileHeader));
    mexPrintf("sizeof(PL_ChanHeader)=%i\n",sizeof(PL_ChanHeader));
    mexPrintf("sizeof(PL_EventHeader)=%i\n",sizeof(PL_EventHeader));
    mexPrintf("sizeof(PL_SlowChannelHeader)=%i\n",sizeof(PL_SlowChannelHeader));
    mexPrintf("sizeof(PL_DataBlockHeader)=%i\n",sizeof(PL_DataBlockHeader));
    mexPrintf("sizeof(ShortHeader)=%i\n",sizeof(ShortHeader));
    mexPrintf("sizeof(PL_ServerPars)=%i\n",sizeof(PL_ServerPars));
    mexPrintf("sizeof(PL_ServerPars1)=%i\n",sizeof(PL_ServerPars1));
}

