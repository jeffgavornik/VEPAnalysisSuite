/*
 *
 *
 *
 */

#include "mex.h"
#include <math.h>
#include <fstream>
#include "Plexon_LP64.h"
#include <time.h>

#define INT16 2 // 2 bytes, equivalent to short int

#define MAXWORDS 512 // buffer size to hold data samples, don't know if
// there is actually a fixed or max value, but this seems to work

// [n,npw,ts,wfs,wfTs,afTs,ev,evTs] = extractPLXunit(filename,ch,unit)
// n is the number of waveforms
// npw is the number of samples in each waveform
// ts is a 1xn array of timestamps for each waveform
// wfs is an n x npw array of waveforms
// afTs is a 1xnpw array of timestamps into a waveform based on AD starting at 0
// ev is an array of event values
// evTs is an array of event timestamps


using namespace std;

struct FileInfoStruct {
    int ch;
    int unit;
    int wfCount;
    int tsCount;
    int nSamples;
    int evCount;
    double vCF; // voltage conversion factor
    double tCF; // time conversion factor
    int stopPos; // point at which to stop reading the plexon file
    int fileLength;
    
    double *nWf;
    double *nS;
    double *ts;
    double *wfs;
    double *wTs;
};

void getInfoForChannelAndUnit(ifstream *plxFile, FileInfoStruct *fis);
void extractWaveformsForChannelAndUnit(ifstream *plxFile, FileInfoStruct *fis);

void analyzeHeaders(ifstream *plxFile);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // Check usage
    if (nrhs<3) mexErrMsgTxt("extractPLXad: 3 inputs required (plxFileName,channel,unit)");
    
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
    #ifdef DEBUG
    mexPrintf("Extract unit data from '%s'\n",filename.c_str());
    mexEvalString("drawnow");  // flush queue
    #endif
    
    // Create a data structure that will be used to pass information
    // between functions
    FileInfoStruct fis;
    
    // Read the channel number
    if (mxGetN(prhs[1])*mxGetM(prhs[1])!=1) {
        mexErrMsgTxt("extractPLXunit: single channel only");
    }
    fis.ch = (int)*mxGetPr(prhs[1]);
    
    // Read the channel number
    if (mxGetN(prhs[2])*mxGetM(prhs[2])!=1) {
        mexErrMsgTxt("extractPLXunit: single unit only");
    }
    fis.unit = (int)*mxGetPr(prhs[2]);
    
    // Read the headers and make a first pass through the data blocks to
    // get conversion factors and determine how much memory is needed to
    // hold the spike waveforms
    getInfoForChannelAndUnit(&plxFile,&fis);
    if (fis.wfCount == 0)
        mexErrMsgTxt("extractPLXunit: single channel only");
    if (fis.nSamples > MAXWORDS)
        mexErrMsgTxt("extractPLXunit: nSamples > MAXWORDS");
    mexPrintf("nWf = %i\n",fis.wfCount);
    mexPrintf("nTs = %i\n",fis.tsCount);
    mexPrintf("nSamples = %i\n",fis.nSamples);
    mexPrintf("vCF = %f\n",fis.vCF);
    mexPrintf("Total memory needed = %i bytes\n",fis.wfCount*fis.nSamples*INT16);
    
    // Create output variables
    // nWf = number of waveforms
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    fis.nWf = mxGetPr(plhs[0]);
    *(fis.nWf) = fis.wfCount;
    // nS = number of samples per waveform
    plhs[1] = mxCreateDoubleMatrix(1, 1, mxREAL);
    fis.nS = mxGetPr(plhs[1]);
    *(fis.nS) = fis.nSamples;
    // ts = timestamps for each waveform
    plhs[2] = mxCreateDoubleMatrix(1, fis.wfCount, mxREAL);
    fis.ts = mxGetPr(plhs[2]);
    // wfs = waveforms
    plhs[3] = mxCreateDoubleMatrix(fis.wfCount,fis.nSamples, mxREAL);
    fis.wfs = mxGetPr(plhs[3]);
    // wTs = time vector into a single waveform
    plhs[4] = mxCreateDoubleMatrix(1,fis.nSamples, mxREAL);
    fis.wTs = mxGetPr(plhs[4]);
    
    // Extract the waveforms
    extractWaveformsForChannelAndUnit(&plxFile,&fis);
    
    // Calculate a time vector into each waveform
    for (int ii = 0; ii<fis.nSamples; ii++)
        *(fis.wTs+ii) = ii * fis.tCF;
    
    plxFile.close();
    
}


void getInfoForChannelAndUnit(ifstream *plxFile, FileInfoStruct *fis){
    
    #ifdef DEBUG
    mexPrintf("Pre-examining file for channel %i, unit %i\n",fis->ch,fis->unit);
    mexEvalString("drawnow");  // flush queue    
    clock_t tStart,tStop;
    tStart = clock();
    #endif
    
    // Read the file length
    plxFile->seekg(0, ios::end);
    int fileLength = plxFile->tellg();
    plxFile->seekg(0, ios::beg);
    
    // Read the file header and calculate the timestamp conversion factor
    PL_FileHeader fh;
    plxFile->read((char *)&fh, sizeof(fh));
    fis->tCF = 1/(double)fh.ADFrequency;
    
    // Read the spike channel header and calculate the voltage conversion
    // factor
    PL_ChanHeader ch;
    int WFRate, Gain;
    for (int ii=0; ii<fh.NumDSPChannels; ii++){
        plxFile->read((char *)&ch, sizeof(ch));
        if (ch.Channel == fis->ch){
            WFRate = ch.WFRate;
            Gain = ch.Gain;
        }
    }
    fis->vCF = fh.SpikeMaxMagnitudeMV /
            (0.5*pow((double)2,(int)fh.BitsPerSpikeSample)
            *Gain*fh.SpikePreAmpGain);
    
    // Get the strobed event count
    fis->evCount = fh.EVCounts[PL_StrobedExtChannel];
    
    // Skip over event and A/D channel headers and save the data block
    // start location
    plxFile->seekg(fh.NumEventChannels*sizeof(PL_EventHeader)+
            fh.NumSlowChannels*sizeof(PL_SlowChannelHeader),ios::cur);
    streampos dataStartPos = plxFile->tellg();
    
    // Scan through the data blocks counting the number of waveforms and
    // timestamps for the desired channel and unit
    int wfCount = 0;
    int tsCount = 0;
    int nSamples = 0;
    PL_DataBlockHeader dh;
    int nBytes = sizeof(PL_DataBlockHeader);
    int stopPos = fileLength-nBytes;
    //while (!plxFile->eof()){
    while (plxFile->tellg() <= stopPos){
        
        //if (plxFile->tellg() > stopPos) return;
        
        // Read header and extract needed info
        plxFile->read((char *)&dh, nBytes);
        if ((dh.Type == PL_SingleWFType) &&
                (dh.Channel == fis->ch) &&
                (dh.Unit == fis->unit) &&
                (dh.NumberOfWaveforms > 0)) {
            wfCount += dh.NumberOfWaveforms;
            tsCount += 1;
            //if (nSamples != dh.NumberOfWordsInWaveform)
            //    mexPrintf("old sample count = %i, new count = %i\n",
            //            nSamples,dh.NumberOfWordsInWaveform);
            nSamples = dh.NumberOfWordsInWaveform;
        }
        // Skip the data words
        plxFile->seekg(
                dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform*INT16,
                ios::cur);
    }
    fis->wfCount = wfCount;
    fis->tsCount = tsCount;
    fis->nSamples = nSamples;
    fis->stopPos = stopPos;
    fis->fileLength = fileLength;
    
    // Return to the data start location just before spike channel headers
    plxFile->seekg(dataStartPos);
    
    #ifdef DEBUG
    tStop = clock();
    double time_elapsed_in_seconds = (tStop - tStart)/(double)CLOCKS_PER_SEC;
    mexPrintf("Elapsed time for search = %f\n",time_elapsed_in_seconds);
    mexEvalString("drawnow");  // flush queue
    #endif
}

void extractWaveformsForChannelAndUnit(ifstream *plxFile,
        FileInfoStruct *fis){
    #ifdef DEBUG
    mexPrintf("Extracting %i waveforms\n",fis->wfCount);
    mexEvalString("drawnow");  // flush queue
    clock_t tStart,tStop;
    tStart = clock();
    #endif
    
    // Scan through the data blocks counting the number of waveforms and
    // timestamps for the desired channel and unit
    int wfCount = 0;
    PL_DataBlockHeader dh;
    int nBytes = sizeof(PL_DataBlockHeader);
    double *wfs = fis->wfs;
    double *ts = fis->ts;
    double vCF = fis->vCF;
    double tCF = fis->tCF;
    char *dataBuffer = new char[MAXWORDS*INT16]; // buffer for data words
    while (plxFile->tellg() <= fis->stopPos){
        // Read header and match channel and unit
        plxFile->read((char *)&dh, nBytes);
        if ((dh.Type == PL_SingleWFType) &&
                (dh.Channel == fis->ch) &&
                (dh.Unit == fis->unit) &&
                (dh.NumberOfWaveforms > 0)) {
            // Get the data, convert to uV
            plxFile->read(dataBuffer,
                    dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform*INT16);
            for (int iw=0;iw<dh.NumberOfWordsInWaveform;iw++){
                // Note: normal c uses row-wise indexing, matlab uses
                // col-wise so must use non-standard indexing into 2D array
                wfs[iw*fis->wfCount+wfCount] = *(short int *)(dataBuffer+INT16*iw)*vCF;
            }
            // Get the time stamp, convert to sec
            ts[wfCount] = dh.TimeStamp * tCF;
            wfCount += 1;
        } else plxFile->seekg(
                dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform*INT16,
                ios::cur);
    }
    delete[] dataBuffer;
    
    #ifdef DEBUG
    tStop = clock();
    double time_elapsed_in_seconds = (tStop - tStart)/(double)CLOCKS_PER_SEC;
    mexPrintf("Elapsed time for extract = %f\n",time_elapsed_in_seconds);
    mexEvalString("drawnow");  // flush queue
    #endif
    
    int pos = plxFile->tellg();
    mexPrintf("plxFile->tellg() = %i, stopPos = %i, fileLength = %i\n",
            pos,fis->stopPos,fis->fileLength);
    mexPrintf("target:wfCount = %i, actual:wfCount = %i\n",
            fis->wfCount,wfCount);
    mexEvalString("drawnow");  // flush queue
    
}

