/*
 * Return count info for all channels with spikes
 *
 *  Form of returned data = [channel number; unsorted count; unit 1 count; ... unit n count];
 *  Only returns info for channels with spikes (i.e. if all counts are zero data is not returned for that channel)
 *
 */

#include "mex.h"
#include <math.h>
#include <fstream>
#include <string.h>
#include <map>
#include "Plexon_LP64.h"

#define INT16 2 // 2 bytes, equivalent to sizeof(short)

// Define max units based on wf counts in the header - if there are more 
// units on any channel, will need to do something fancier to get the counts
#define MAXUNITS 5
#define MAXCHANNELS 130

using namespace std;

struct SpikeInfoStruct {
    int nChannelsWithSpikes;
    int maxNumberOfUnits = MAXUNITS+1; // +1 for channel #
    double spikeCountsPerChannel[MAXCHANNELS][MAXUNITS+1] = {0};
};


void report_contents(string filename,SpikeInfoStruct *sis);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // Check usage
    if (nrhs<1) mexErrMsgTxt("plxProfiler: 1 input required.");
    
    // Read in the filename and convert it into a string object
    if (!mxIsChar(prhs[0])) mexErrMsgTxt("plxProfiler: Input must be a string");
    int nChar = mxGetNumberOfElements(prhs[0]) + 1;
    char *buf = (char *)mxCalloc(nChar, sizeof(char));
    if (mxGetString(prhs[0], buf, nChar) != 0)
        mexErrMsgTxt("plxProfiler: Could not read filename");
    string filename = buf;
    mxFree((void *)buf);
        
    // Create a structure to pass info
    SpikeInfoStruct sis;
    
    // Call function to do all the work
    report_contents(filename,&sis);
    
    // Copy info over to output matrix
    plhs[0] = mxCreateDoubleMatrix(sis.nChannelsWithSpikes, sis.maxNumberOfUnits, mxREAL);
    double *returnData = mxGetPr(plhs[0]);
    int count = 0;
    for (int iUnit=0; iUnit < sis.maxNumberOfUnits; iUnit++) 
        for (int iCh=0; iCh < sis.nChannelsWithSpikes; iCh++)
            returnData[count++] = sis.spikeCountsPerChannel[iCh][iUnit];
}

void report_contents(string filename,SpikeInfoStruct *sis){
    mexPrintf("getPlxSpikeCounts: '%s'\n",filename.c_str());
    // Open the file for reading and calculate its length -----------------
    ifstream plxFile;
    plxFile.open(filename.c_str(), ifstream::in | ifstream::binary);
    if (plxFile.fail()){
        char errMsg[1024];
        sprintf(errMsg,"plxProfiler: Error Opening File '%s'\n",filename.c_str());
        mexErrMsgTxt((const char *)errMsg);
    }
    plxFile.seekg(0, ios::end);
    int fileLength = plxFile.tellg();
    plxFile.seekg(0, ios::beg);
    //mexPrintf("fileLength = %i bytes\n",fileLength);
    
    // Get information from the file headers ------------------------------
    PL_FileHeader fh;
    plxFile.read((char *)&fh, sizeof(fh));
    
    int wf0,wf1,wf2,wf3,wf4;
    int zeroFlag = 1;
    int chCount = 0;
    for (int ii=0; ii<130; ii++){
        wf0 = fh.WFCounts[ii][0]; wf1 = fh.WFCounts[ii][1];
        wf2 = fh.WFCounts[ii][2]; wf3 = fh.WFCounts[ii][3];
        wf4 = fh.WFCounts[ii][4];
        if (wf0+wf1+wf2+wf3+wf4 > 0) {
            sis->spikeCountsPerChannel[chCount][0] = ii;
            sis->spikeCountsPerChannel[chCount][1] = wf0;
            sis->spikeCountsPerChannel[chCount][2] = wf1;
            sis->spikeCountsPerChannel[chCount][3] = wf2;
            sis->spikeCountsPerChannel[chCount][4] = wf3;
            sis->spikeCountsPerChannel[chCount][5] = wf4;
            chCount += 1;
        } 
    }
    sis->nChannelsWithSpikes = chCount;
    //sis->maxNumberOfUnits = MAXUNITS+1; // +1 for channel #
    plxFile.close();
}