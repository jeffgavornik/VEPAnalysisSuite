/*
 *
 *
 *
 */

#include "mex.h"
#include <fstream>
#include "Plexon_LP64.h"

using namespace std;

#define INT16 2 // 2 bytes, equivalent to short int

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // Check usage
    if (nrhs<1) mexErrMsgTxt("extractPLXad: 1 input required.");
    
    // Read in the filename and convert it into a string object
    if (!mxIsChar(prhs[0])) mexErrMsgTxt("extractPLXad: First input must be a string");
    int nChar = mxGetNumberOfElements(prhs[0]) + 1;
    char *buf = (char *)mxCalloc(nChar, sizeof(char));
    if (mxGetString(prhs[0], buf, nChar) != 0)
        mexErrMsgTxt("extractPLXunit: Could not read filename");
    string filename = buf;
    mxFree((void *)buf);
    
    // Open the file
    ifstream plxFile;
    plxFile.open(filename.c_str(), ifstream::in | ifstream::binary);
    if (plxFile.fail()){
        mexPrintf("extractPLXunit: Error Opening File\n");
        return;
    }
    mexPrintf("Extracting events from '%s'\n",filename.c_str());
    mexEvalString("drawnow");  // flush queue
    clock_t tStart = clock();
    
    // Read the file length
    plxFile.seekg(0, ios::end);
    int fileLength = plxFile.tellg();
    plxFile.seekg(0, ios::beg);

    // Read the file header and calculate the timestamp conversion factor
    PL_FileHeader fh;
    plxFile.read((char *)&fh, sizeof(fh));
    double tCF = 1/(double)fh.ADFrequency;
    
    // Get the strobed event count
    int nEv = fh.EVCounts[PL_StrobedExtChannel];
    
    // Skip over the channel headers
    plxFile.seekg(fh.NumDSPChannels*sizeof(PL_ChanHeader)+
            fh.NumEventChannels*sizeof(PL_EventHeader)+
            fh.NumSlowChannels*sizeof(PL_SlowChannelHeader),ios::cur);
    
    // Create output variables and allocate memory
    // nEv = number of events
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    *(mxGetPr(plhs[0])) = nEv;
    // evs = event values
    plhs[1] = mxCreateDoubleMatrix(1, nEv, mxREAL);
    double *evs = mxGetPr(plhs[1]);
    // ts = timestamps for each waveform
    plhs[2] = mxCreateDoubleMatrix(1, nEv, mxREAL);
    double *ts = mxGetPr(plhs[2]);
    
    // Extract event values and timestamps from the data blocks
    int evCount = 0;
    PL_DataBlockHeader dh;
    int nBytes = sizeof(PL_DataBlockHeader);
    int stopPos = fileLength-nBytes;
    while (plxFile.tellg() <= stopPos){
        plxFile.read((char *)&dh, nBytes); // Read data header
        if (dh.Type == PL_ExtEventType) {
            if (dh.Channel == PL_StrobedExtChannel) {
                ts[evCount] = dh.TimeStamp * tCF;
                evs[evCount++] = dh.Unit;
            }
        }
        plxFile.seekg(
                dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform*INT16,
                ios::cur);
    }
    
    // Finish up
    mexPrintf("Returning  %i events in %f secs\n",evCount,
            (clock() - tStart)/(double)CLOCKS_PER_SEC);
    plxFile.close();
    
}

