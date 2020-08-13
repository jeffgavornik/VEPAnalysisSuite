/*
 * Function to extract report on .plx file contents (i.e. number of 
 * channels, headers, etc.)
 *
 * 8/4/2016
 * Updated to use a channel agnostic mapping between channel numbers and 
 * waveform counts.  Necessary to read some trodal data channels
 */

#include "mex.h"
#include <math.h>
#include <fstream>
#include <string.h>
#include <map>
#include "Plexon_LP64.h"

#define INT16 2 // 2 bytes, equivalent to sizeof(short)

using namespace std;

void report_contents(string filename);

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
        
    // Call function to do all the work
    report_contents(filename);
}

void report_contents(string filename){
    mexPrintf("plxProfiler: '%s'\n",filename.c_str());
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
    mexPrintf("fileLength = %i bytes\n",fileLength);
    
    // Get information from the file headers ------------------------------
    PL_FileHeader fh;
    plxFile.read((char *)&fh, sizeof(fh));
    mexPrintf("File Header ----------------------\n");
    mexPrintf("Version = %i\n",fh.Version);
    mexPrintf("Comment = '%s'\n",fh.Comment);
    mexPrintf("ADFrequency = %i\n",fh.ADFrequency);
    mexPrintf("NumDSPChannels = %i\n",fh.NumDSPChannels);
    mexPrintf("NumEventChannels = %i\n",fh.NumEventChannels);
    mexPrintf("NumSlowChannels = %i\n",fh.NumSlowChannels);
    mexPrintf("NumPointsWave = %i\n",fh.NumPointsWave);
    mexPrintf("NumPointsPreThr = %i\n",fh.NumPointsPreThr);
    mexPrintf("Year/Month/Day = %i/%i/%i\n",fh.Year,fh.Month,fh.Day);
    mexPrintf("Hour/Minute/Second = %i/%i/%i\n",fh.Hour,fh.Minute,fh.Second);
    mexPrintf("FastRead = %i\n",fh.FastRead);
    mexPrintf("WaveformFreq = %i\n",fh.WaveformFreq);
    mexPrintf("LastTimestamp = %f\n",fh.LastTimestamp);
    if (fh.Version >= 103){
        mexPrintf("Trodalness = %u\n",fh.Trodalness);
        mexPrintf("DataTrodalness = %u\n",fh.DataTrodalness);
        mexPrintf("BitsPerSpikeSample = %u\n",fh.BitsPerSpikeSample);
        mexPrintf("BitsPerSlowSample = %u\n",fh.BitsPerSlowSample);
        mexPrintf("SpikeMaxMagnitudeMV = %u\n",fh.SpikeMaxMagnitudeMV);
        mexPrintf("SlowMaxMagnitudeMV = %u\n",fh.SlowMaxMagnitudeMV);
    }
    if (fh.Version >= 105){
        mexPrintf("SpikePreAmpGain = %u\n",fh.SpikePreAmpGain);
    }
    mexPrintf("Non-Zero Timestamp and Waveform Counts (1-based ch count)\n");
    int ts0,ts1,ts2,ts3,ts4,wf0,wf1,wf2,wf3,wf4;
    int wfCount0,wfCount1,wfCount2,wfCount3,wfCount4;
    int zeroFlag = 1;
    for (int ii=0; ii<130; ii++){
        ts0 = fh.TSCounts[ii][0]; ts1 = fh.TSCounts[ii][1];
        ts2 = fh.TSCounts[ii][2]; ts3 = fh.TSCounts[ii][3];
        ts4 = fh.TSCounts[ii][4];
        wf0 = fh.WFCounts[ii][0]; wf1 = fh.WFCounts[ii][1];
        wf2 = fh.WFCounts[ii][2]; wf3 = fh.WFCounts[ii][3];
        wf4 = fh.WFCounts[ii][4];
        if ((ts0+ts1+ts2+ts3+ts4 > 0) || (wf0+wf1+wf2+wf3+wf4 > 0)) {
            zeroFlag = 0;
            mexPrintf("  channel %i: TSCounts = %i %i %i %i %i, WFCounts = %i %i %i %i %i\n",
                    ii,ts0,ts1,ts2,ts3,ts4,wf0,wf1,wf2,wf3,wf4);
        } 
    }
    if (zeroFlag) mexPrintf("   (none)\n");
    mexPrintf("Non-Zero Event Counts\n");
    zeroFlag = 1;
    for (int ii=0; ii<512; ii++)
        if (fh.EVCounts[ii] > 0) {
            zeroFlag = 0;
            mexPrintf("  EVCount[%i] = %i\n",ii,fh.EVCounts[ii]);
        }
    if (zeroFlag) mexPrintf("   (none)\n");
    // Figure out which DSP and Continuous channels have data -------------
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
    std::map <int,int> ADChannelMap;
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
                case PL_ADDataType:
                    ADChannelMap[dh.Channel] += dh.NumberOfWordsInWaveform;
                    break;
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
    // Return to the data start location just before spike channel headers
    plxFile.seekg(dataStartPos);
    mexPrintf("Spike Channel Headers (with data) ----------------------\n");
    PL_ChanHeader ch;
    zeroFlag = 1;
    for (int ii=0; ii<fh.NumDSPChannels; ii++){
        plxFile.read((char *)&ch, sizeof(ch));
        //if (ch.NUnits > 0) {
        if (DSPChannelMap[ch.Channel]>0) {
            zeroFlag = 0;
            mexPrintf("Channel %i\n",ch.Channel);
            mexPrintf("  Name = '%s', SIGName = '%s'\n",ch.Name,ch.SIGName);
            mexPrintf("  WFRate = %i, SIG = %i, Ref = %i, Gain = %i\n",
                    ch.WFRate,ch.SIG,ch.Ref,ch.Gain);
            mexPrintf("  Filter = %i, Threshold = %i, Method = %i, NUnits = %i\n",
                    ch.Filter,ch.Threshold,ch.Method,ch.NUnits);
            mexPrintf("  Number of waveforms = %i\n",DSPChannelMap[ch.Channel]);
        }
    }
    if (zeroFlag) mexPrintf("   (none)\n");
    mexPrintf("Event Channel Headers ----------------------\n");
    PL_EventHeader eh;
    zeroFlag = 1;
    for (int ii=0; ii<fh.NumEventChannels; ii++){
        zeroFlag = 0;
        plxFile.read((char *)&eh, sizeof(eh));
        mexPrintf("  Name = '%s', Channel %i, FrameEvent = %i\n",
                eh.Name,eh.Channel,eh.IsFrameEvent  );
    }
    if (zeroFlag) mexPrintf("   (none)\n");
    mexPrintf("Continuous Channel Headers (with data) ----------------------\n");
    PL_SlowChannelHeader sch;
    zeroFlag = 1;
    for (int ii=0; ii<fh.NumSlowChannels; ii++){
        plxFile.read((char *)&sch, sizeof(sch));
        //if (ADChannelMap[sch.Channel]>0){
            zeroFlag = 0;
            mexPrintf("  Name = '%s', Channel %i, ADFreq = %i",
                    sch.Name,sch.Channel,sch.ADFreq);
            mexPrintf(", Gain = %i, Enabled = %i, PreAmpGain = %i, nSamples = %i\n",
                    sch.Gain,sch.Enabled,sch.PreAmpGain,ADChannelMap[sch.Channel]);
            if (sch.SpikeChannel != 0)
                mexPrintf("    SpikeChannel = %i\n",sch.SpikeChannel);
        //}
    }
    if (zeroFlag) mexPrintf("   (none)\n");
    plxFile.close();
}