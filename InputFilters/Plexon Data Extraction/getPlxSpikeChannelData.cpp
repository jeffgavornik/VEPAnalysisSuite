/*
 * Return an array specifying which channels have spike data
 */

#include "mex.h"
#include <math.h>
#include <fstream>
#include <string.h>
#include <map>
#include "Plexon_LP64.h"

#define INT16 2 // 2 bytes, equivalent to sizeof(short)

#define NUMBER_OF_CHANNELS 130

using namespace std;

void read_contents(string filename, mxArray *mxStrArray, int *chCount);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // Check usage
    if (nrhs<1) mexErrMsgTxt("getPlxSpikeChannelData: 1 input required.");
    
    // Read in the filename and convert it into a string object
    if (!mxIsChar(prhs[0])) mexErrMsgTxt("getPlxSpikeChannelData: Input must be a string");
    int nChar = mxGetNumberOfElements(prhs[0]) + 1;
    char *buf = (char *)mxCalloc(nChar, sizeof(char));
    if (mxGetString(prhs[0], buf, nChar) != 0)
        mexErrMsgTxt("getPlxSpikeChannelData: Could not read filename");
    string filename = buf;
    mxFree((void *)buf);
    
    // Call function to do all the work
    const char *field_names[] = {"Name","SIGName","Channel","WFRate",
    "SIG","Ref","Gain","Filter","Threshold","Method","NUnits",
    "Template","Fit","SortWidth","Boxes","Padding","NWaveforms"};
    int nFields = 17;
    mwSize dims[2] = {1, NUMBER_OF_CHANNELS };
    mxArray *mxStrArray;
    mxStrArray = mxCreateStructArray(2, dims, nFields, field_names);
    plhs[0] = mxStrArray;
    int chCount = 0;
    read_contents(filename,mxStrArray,&chCount);
    mxSetN(plhs[0],chCount);
    
}

void read_contents(string filename, mxArray *mxStrArray, int *chCount){
    // Open the file for reading and calculate its length -----------------
    ifstream plxFile;
    plxFile.open(filename.c_str(), ifstream::in | ifstream::binary);
    if (plxFile.fail()){
        char errMsg[1024];
        sprintf(errMsg,"getPlxSpikeChannelData: Error Opening File '%s'\n",filename.c_str());
        mexErrMsgTxt((const char *)errMsg);
    }
    plxFile.seekg(0, ios::end);
    int fileLength = plxFile.tellg();
    plxFile.seekg(0, ios::beg);
    
    // Get information from the file headers ------------------------------
    PL_FileHeader fh;
    plxFile.read((char *)&fh, sizeof(fh));
    
    // Figure out which DSP channels have data -------------
    // Note: this is sort of a hack made necessary by the fact that the
    // enabled field in all of the PL_SlowChannelHeaders is set to 1
    // irrespective of whether the channel was actually enabled at record
    // time and NUnits is only > 0 if the file has been sorted
    // Save the current location within the file and skip the headers
    streampos dataStartPos = plxFile.tellg();
    plxFile.seekg(
            fh.NumDSPChannels*sizeof(PL_ChanHeader)+
            fh.NumEventChannels*sizeof(PL_EventHeader)+
            fh.NumSlowChannels*sizeof(PL_SlowChannelHeader),ios::cur);
    // Loop over all data headers saving a record of which channels have
    // data associated with them.  Store waveform counts in a map indexed 
    // the channel number read from the data headers
    std::map <int,int> DSPChannelMap;
    PL_DataBlockHeader dh;
    int nBytes = sizeof(PL_DataBlockHeader);
    int stopPos = fileLength-nBytes;
    while (plxFile.tellg() <= stopPos){
        // Read header and extract needed info
        PL_DataBlockHeader dh;
        plxFile.read((char *)&dh, nBytes);
        if (dh.NumberOfWordsInWaveform>0){
            // note -1 ch count for 1-based numbering
            switch (dh.Type) {
                case PL_SingleWFType:
                    DSPChannelMap[dh.Channel] += dh.NumberOfWordsInWaveform;
                    break;
            }
            // Skip the data words
            int stopNextRead = (int)plxFile.tellg()+dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform*INT16;
            if (stopNextRead>fileLength){
                mexPrintf("----attempt to read beyond eof----\n");
                break;
            }       
            plxFile.seekg(
                    dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform*INT16,
                    ios::cur);
        }
    }
    
    // Count the number of channels with non-zero waveforms
    for (std::map<int,int>::iterator it=DSPChannelMap.begin(); it!=DSPChannelMap.end(); ++it)
        if (it->second > 0) *chCount = *chCount + 1;
    
    // Return to the data start location just before spike channel headers
    plxFile.seekg(dataStartPos);
    mexPrintf("Spike Channel Headers (with data) ----------------------\n");
    PL_ChanHeader ch;
    mxArray *field_value;
    int arrayIndex = 0;
    // field_value = mxCreateDoubleMatrix(1,1,mxREAL);
    for (int ii=0; ii<fh.NumDSPChannels; ii++){
        plxFile.read((char *)&ch, sizeof(ch));
        if (DSPChannelMap[ch.Channel]>0) {
            #ifdef DEBUG
            mexPrintf("Channel %i\n",ch.Channel);
            mexPrintf("  Name = '%s', SIGName = '%s'\n",ch.Name,ch.SIGName);
            mexPrintf("  WFRate = %i, SIG = %i, Ref = %i, Gain = %i\n",
                    ch.WFRate,ch.SIG,ch.Ref,ch.Gain);
            mexPrintf("  Filter = %i, Threshold = %i, Method = %i, NUnits = %i\n",
                    ch.Filter,ch.Threshold,ch.Method,ch.NUnits);
            mexPrintf("  Number of waveforms = %i\n",DSPChannelMap[ch.Channel]);
            #endif
            mxSetFieldByNumber(mxStrArray,arrayIndex,0,mxCreateString(ch.Name));
            mxSetFieldByNumber(mxStrArray,arrayIndex,1,mxCreateString(ch.SIGName));
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.Channel;
            mxSetFieldByNumber(mxStrArray,arrayIndex,2,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.WFRate;
            mxSetFieldByNumber(mxStrArray,arrayIndex,3,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.SIG;
            mxSetFieldByNumber(mxStrArray,arrayIndex,4,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.Ref;
            mxSetFieldByNumber(mxStrArray,arrayIndex,5,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.Gain;
            mxSetFieldByNumber(mxStrArray,arrayIndex,6,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.Filter;
            mxSetFieldByNumber(mxStrArray,arrayIndex,7,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.Threshold;
            mxSetFieldByNumber(mxStrArray,arrayIndex,8,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.Method;
            mxSetFieldByNumber(mxStrArray,arrayIndex,9,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.NUnits;
            mxSetFieldByNumber(mxStrArray,arrayIndex,10,field_value);
            // *mxGetPr(field_value) = ch.Template;
            //mxSetFieldByNumber(mxStrArray,arrayIndex,11,field_value);
            // *mxGetPr(field_value) = ch.Fit;
            //mxSetFieldByNumber(mxStrArray,arrayIndex,12,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = ch.SortWidth;
            mxSetFieldByNumber(mxStrArray,arrayIndex,13,field_value);
            field_value = mxCreateDoubleMatrix(1,1,mxREAL);
            *mxGetPr(field_value) = DSPChannelMap[ch.Channel];
            mxSetFieldByNumber(mxStrArray,arrayIndex,16,field_value);
            arrayIndex++;
        }
    }
    mexPrintf("chCount %i\n",chCount);
    plxFile.close();
}