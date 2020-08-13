
/*
[unitData,eventValues,eventTimeStamps,wfTimePoints,chInfo] = extractPLXunits(filename);
*/

#include "mex.h"
#include "Plexon_LP64.h"
#include <math.h>
#include <fstream>
#include <sstream>
#include <string>
#include <map>
#include <vector>


#define INT16 2 // 2 bytes, equivalent to sizeof(short int)
#define MAXWORDS 512 // buffer size to hold data samples, don't know if
#define NHEADERUNITS 5 // number of units accounted for in the file header - notes: 1. index zero is actually unsorted waveforms, not a unit. 2. non-zero values in indici 2-4 indicate sorted units, but counting these non-zero values does not necessarily tell the total number of units for each channel.  The only way to find out the total number of units seems to be to go through the entire data file and count each manually


using namespace std;

#define MAXCH 130 // based on Plexon.h

struct spikeChannelInfo { // see Plexon.h
    int Channel, WFRate, SIG, Ref, Gain, Filter, Threshold, Method, NUnits;
    string Name, SIGName;
    // ~spikeChannelInfo() {
    //     mexPrintf("~spikeChannelInfo %s\n",Name.c_str());
    // }
};

// Structure to hold information about a single unit
struct unitData {
    // string channelName;
    bool isSorted; // set to 0 for unit 0, 1 otherwise
    int channel; // channel number, one indexed to match Plexon notation
    int unit; // unit number, zero indexed
    int nSamples; // number of points in a single waveform
    int evCount; // actual number of spike events, increments each time a waveform is added
    int expectedWaveformCount; // number of waveforms that are expected to be added to the structure; this value is used to pre-allocate memory pointed to by waveforms
    
    vector<double> timeStamps; // spike event timestamps
    
    double *cumulativeWaveform; // running sum of all added waveforms
    // optionally used to store each individual waveform, must be pre-allocated
    double *waveforms = NULL; // non-null

    unitData(int channel, int unit, int nSamples, int expectedWaveformCount) {
        this->channel = channel;
        this->unit = unit;
        this->nSamples = nSamples;
        this->expectedWaveformCount = expectedWaveformCount;
        isSorted = (unit != 0);
        evCount = 0;
        cumulativeWaveform = new (std::nothrow) double[nSamples];
        if (cumulativeWaveform == NULL){
            mexWarnMsgIdAndTxt("extractPlxUnit:unitData","unitData: Insufficient Memory");
        }
        memset(cumulativeWaveform, 0, nSamples*sizeof(double));
        //mexPrintf("unitData(%i %i %i %i)\n",channel,unit,nSamples,expectedWaveformCount);
    }

    ~unitData() {
        // mexPrintf("~unitData(%i %i %i %i)\n",channel,unit,nSamples,expectedWaveformCount);
        delete[] cumulativeWaveform;
        delete[] waveforms;
    }

    bool allocateWaveformMemory(int expectedWaveformCount){
        // Use the expectedWaveformCount and nSamples per waveform to pre-allocate a chunk of memory large enough to hold all of the waveforms.  Returns false if memory allocation fails
        bool success = true;
        this->expectedWaveformCount = expectedWaveformCount;
        waveforms = new (std::nothrow) double[nSamples*expectedWaveformCount];
        if (waveforms == NULL){
            mexWarnMsgIdAndTxt("extractPlxUnit:unitData","allocateWaveformMemory: Insufficient Memory");
            success = false;
        }
        memset(waveforms, 0, nSamples*expectedWaveformCount*sizeof(double));
        return(success);
    }

    void addWaveform(double timeStamp,double *samples){
        int offset = evCount * nSamples; // for indexing into 2D waveform array
        for (int ii=0;ii<nSamples;ii++) {
            cumulativeWaveform[ii] += samples[ii];
            if (waveforms != NULL){
                waveforms[offset+ii]=samples[ii];
            }
        }
        timeStamps.push_back(timeStamp);
        evCount += 1;
    }

    double * getavgWaveform(){
        // Note: avgWaveform memory will NOT be freed by the structure destructor, must be freed externally, 
        double *avgWaveform = new (std::nothrow) double[nSamples];
        if (avgWaveform == NULL){
            mexWarnMsgIdAndTxt("extractPlxUnit:unitData","unitData.getavgWaveform: Insufficient Memory");
        }
        //memset(avgWaveform, 0, nSamples*sizeof(double));
        for (int ii=0;ii<nSamples;ii++) {
            avgWaveform[ii] = cumulativeWaveform[ii] / evCount;
        }
        return(avgWaveform);
    }
};

struct FileInfoStruct {
    // Hold information read from the plexon file header
    vector<spikeChannelInfo *> channelInfo; // vector of information for all active spike channels
    int evCount; // strobed event count (EVCounts[PL_StrobedExtChannel])
    int tsCount; // total number of timestamps
    int nSamples; // number of samples in a single waveform (NumPointsWave)
    map<int,double> vCF; // map spike channel numbers to conversion factors
    double tCF; // time conversion factor = 1/(double)fh.ADFrequency;
    int stopPos; // point at which to stop reading the plexon file
    int dataStartPos; // data block start location
    int fileLength; // total length of the file
    double *evTs; // strobed event times
    double *ev; // strobed event values
};

bool readHeaderInfo(ifstream *plxFileStream,
    FileInfoStruct *fis, 
    map<pair<int,int>,unitData *> * unitMap,
    bool averageWaveforms);

void checkMapContents(ifstream *plxFileStream, 
    FileInfoStruct *fis, 
    map<pair<int,int>,unitData *> * unitMap);

void extractUnitData(ifstream *plxFileStream, 
    FileInfoStruct *fis, 
    map<pair<int,int>,unitData *> * unitMap);

mxArray * convertUnitDataToMxArray(map<pair<int,int>,unitData *> * unitMap, 
    bool returnAverage);

mxArray * convertChannelDataToMxArray(FileInfoStruct *fis);

void cleanUp(ifstream *plxFileStream,
    FileInfoStruct *fis,map<pair<int,int>,
    unitData *> * unitMap);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

    // Check usage
    //if (nrhs<3) mexErrMsgTxt("extractPLXad: 3 inputs required.");

    // Read in the filename, open the file, return on failures
    if (!mxIsChar(prhs[0])) 
        mexErrMsgTxt("extractPLXad: First input must be a string");
    int nChar = mxGetNumberOfElements(prhs[0]) + 1;
    char *fileName = (char *)mxCalloc(nChar, sizeof(char));
    if (mxGetString(prhs[0], fileName, nChar) != 0) 
        mexErrMsgTxt("extractPLXunit: Could not read filename from input");
    mexPrintf("extractPLXUnits: %s\n",fileName);
    mexEvalString("drawnow");  // flush queue
    ifstream plxFileStream;
    plxFileStream.open(fileName, ifstream::in | ifstream::binary);
    mxFree((void *)fileName);
    if (plxFileStream.fail()){
        mexErrMsgTxt("extractPLXunits: Error Opening File");
    }
    
    // if (nrhs==2){
    //     // Allow the user to specify a subset of channel-unit pairs
    // }

    bool returnAverage = true; // temporay designation, should be passed variable.  When true, only return the average waveform.  When false, return all waveforms
    
    // Create a data structure that will hold file header information
    FileInfoStruct fis;
    
    // Create a container that will be used to map channel and unit numbers to unitData structures
    map<pair<int,int>,unitData *> unitMap;
    
    // Read and analyze file header information in preparation for actually extracting all of the unit data
    bool isReady = readHeaderInfo(&plxFileStream,&fis,&unitMap,returnAverage);
    if (!isReady){
        cleanUp(&plxFileStream,&fis,&unitMap);
        mexErrMsgTxt("extractPLXunits: readHeaderInfo returned failure, aborting");
    }

    // Call the routine to read all of the unit data
    extractUnitData(&plxFileStream,&fis,&unitMap);

    // Convert structures into mxArrays
    mxArray *unitDataStuctMatrix = convertUnitDataToMxArray(&unitMap,returnAverage);
    mxArray *spikeChDataStructMatrix = convertChannelDataToMxArray(&fis);

    // Create a time-vector for the waveforms, in ms
    mxArray *wfTimePoints = mxCreateDoubleMatrix(1,fis.nSamples,mxREAL);
    for (int ii = 0; ii<fis.nSamples; ii++){
        *(mxGetPr(wfTimePoints)+ii) = ii * fis.tCF * 1e3;
    }

    // Create mxArrays for strobed event values and timestamps
    mxArray *eventTimeStamps, *eventValues;
    eventTimeStamps = mxCreateDoubleMatrix(1,fis.evCount,mxREAL);
    eventValues = mxCreateDoubleMatrix(1,fis.evCount,mxREAL);
    memcpy(mxGetPr(eventTimeStamps),fis.evTs,fis.evCount*sizeof(double));
    memcpy(mxGetPr(eventValues),fis.ev,fis.evCount*sizeof(double));

    // Assign left hand size outputs
    plhs[0] = unitDataStuctMatrix;
    plhs[1] = eventValues;
    plhs[2] = eventTimeStamps;
    plhs[3] = wfTimePoints;
    plhs[4] = spikeChDataStructMatrix;
    
    // Clean up and release all dynamic memory
    cleanUp(&plxFileStream,&fis,&unitMap);

}

void cleanUp(ifstream *plxFileStream,FileInfoStruct *fis,map<pair<int,int>,unitData *> * unitMap){
// Close file and release dynamic memory allocations
    plxFileStream->close();
    delete[] fis->evTs;
    delete[] fis->ev;
    for (map<pair<int,int>,unitData *>::iterator it=unitMap->begin(); it!=unitMap->end(); ++it){
        delete it->second;
    }
    for (vector<spikeChannelInfo *>::iterator it=fis->channelInfo.begin(); it!=fis->channelInfo.end(); ++it){
        delete *it; // Call destructor on each element in the unitMap
    }
}


mxArray * convertUnitDataToMxArray(map<pair<int,int>,unitData *> * unitMap, bool returnAverage){
// Create a structure array to hold all of the unit data, assign field names, and copy data into mxArrays
    const char **fnames = (const char **)mxCalloc(7, sizeof(*fnames));
    fnames[0] = "isSorted";
    fnames[1] = "channel";
    fnames[2] = "unit";
    fnames[3] = "nSamples";
    fnames[4] = "evCount";
    fnames[5] = "timeStamps";
    fnames[6] = "waveforms";
    mxArray *unitDataStuctMatrix = mxCreateStructMatrix(unitMap->size(),1,7,fnames);
    mxFree(fnames);
    unitData *theUnit;
    mxArray *tsArray, *wfArray;
    double *dblptr, *wfPtr;
    int count = 0;
    for (map<pair<int,int>,unitData *>::iterator it=unitMap->begin(); it!=unitMap->end(); ++it){
        theUnit = (unitData *)it->second;
        tsArray = mxCreateDoubleMatrix(1,theUnit->evCount,mxREAL);
        dblptr = mxGetPr(tsArray); 
        for (int ii=0; ii<theUnit->evCount; ii++){
            dblptr[ii] = theUnit->timeStamps[ii];
        }
        if (returnAverage) {
            wfArray = mxCreateDoubleMatrix(1,theUnit->nSamples,mxREAL);
            dblptr = mxGetPr(wfArray);
            wfPtr = theUnit->getavgWaveform();
            for (int ii=0; ii<theUnit->nSamples; ii++){
                dblptr[ii] = wfPtr[ii];
            }
        } else {
            // get all of the waveforms
            // wfPtr = theUnit->waveforms();
        }
        delete[] wfPtr;
        // mexPrintf("%i: channel %i unit %i nSamples %i evCount %i timeStamps.size = %i isSorted = %i\n",count,theUnit->channel,theUnit->unit,theUnit->nSamples,theUnit->evCount,theUnit->timeStamps.size(),theUnit->isSorted);
        mxSetFieldByNumber(unitDataStuctMatrix,count,0, mxCreateDoubleScalar((double) theUnit->isSorted));
        mxSetFieldByNumber(unitDataStuctMatrix,count,1, mxCreateDoubleScalar((double) theUnit->channel));
        mxSetFieldByNumber(unitDataStuctMatrix,count,2, mxCreateDoubleScalar((double) theUnit->unit));
        mxSetFieldByNumber(unitDataStuctMatrix,count,3, mxCreateDoubleScalar((double) theUnit->nSamples));
        mxSetFieldByNumber(unitDataStuctMatrix,count,4, mxCreateDoubleScalar((double) theUnit->evCount));
        mxSetFieldByNumber(unitDataStuctMatrix,count,5, tsArray);
        mxSetFieldByNumber(unitDataStuctMatrix,count,6, wfArray);
        count += 1;
    }
    return(unitDataStuctMatrix);
}

mxArray * convertChannelDataToMxArray(FileInfoStruct *fis){
// Create a structure matrix to hold channel information
    const char **fnames = (const char **)mxCalloc(11, sizeof(*fnames));
    fnames[0] = "Channel";
    fnames[1] = "WFRate";
    fnames[2] = "SIG";
    fnames[3] = "Ref";
    fnames[4] = "Gain";
    fnames[5] = "Filter";
    fnames[6] = "Threshold";
    fnames[7] = "Method";
    fnames[8] = "NUnits";
    fnames[9] = "Name";
    fnames[10] = "SIGName";
    mxArray *channelDataStructMatrix = mxCreateStructMatrix(fis->channelInfo.size(),1,11,fnames);
    mxFree(fnames);
    spikeChannelInfo *theChannel;
    mxArray *tsArray, *wfArray;
    double *dblptr, *wfPtr;
    int count = 0;
    for (vector<spikeChannelInfo *>::iterator it=fis->channelInfo.begin(); it!=fis->channelInfo.end(); ++it){
        theChannel = (spikeChannelInfo *)*it;
        mxSetFieldByNumber(channelDataStructMatrix,count,0, mxCreateDoubleScalar((double) theChannel->Channel));
        mxSetFieldByNumber(channelDataStructMatrix,count,1, mxCreateDoubleScalar((double) theChannel->WFRate));
        mxSetFieldByNumber(channelDataStructMatrix,count,2, mxCreateDoubleScalar((double) theChannel->SIG));
        mxSetFieldByNumber(channelDataStructMatrix,count,3, mxCreateDoubleScalar((double) theChannel->Ref));
        mxSetFieldByNumber(channelDataStructMatrix,count,4, mxCreateDoubleScalar((double) theChannel->Gain));
        mxSetFieldByNumber(channelDataStructMatrix,count,5, mxCreateDoubleScalar((double) theChannel->Filter));
        mxSetFieldByNumber(channelDataStructMatrix,count,6, mxCreateDoubleScalar((double) theChannel->Threshold));
        mxSetFieldByNumber(channelDataStructMatrix,count,7, mxCreateDoubleScalar((double) theChannel->Method));
        mxSetFieldByNumber(channelDataStructMatrix,count,8, mxCreateDoubleScalar((double) theChannel->NUnits));
        mxSetFieldByNumber(channelDataStructMatrix,count,9, mxCreateString(theChannel->Name.c_str()));
        mxSetFieldByNumber(channelDataStructMatrix,count,10, mxCreateString(theChannel->SIGName.c_str()));
        count += 1;
    }
    return(channelDataStructMatrix);
}


bool readHeaderInfo(ifstream *plxFileStream,FileInfoStruct *fis,map<pair<int,int>,unitData *> * unitMap,bool averageWaveforms) {
// Read the header, use it to create unitData structures for each unit (sorted and unsorted) in the file.  Returns false if any of the memory allocation fail

    bool success = true;

    // Determine the file length
    plxFileStream->seekg(0, ios::end);
    fis->fileLength = plxFileStream->tellg();
    fis->stopPos = fis->fileLength-sizeof(PL_DataBlockHeader);
    plxFileStream->seekg(0, ios::beg);

    // Read the file header and save some info
    PL_FileHeader fh;
    plxFileStream->read((char *)&fh, sizeof(fh));
    fis->tCF = 1/(double)fh.ADFrequency; //timestamp conversion factor
    fis->nSamples = fh.NumPointsWave;
    fis->evCount = fh.EVCounts[PL_StrobedExtChannel];
    fis->evTs = new double[fis->evCount];
    fis->ev = new double[fis->evCount];

    // Create unitData structures for all units on all channels with non-zero waveform counts
    bool needDataAnalysis = false;
    int * activeChannels = new int[MAXCH];
    memset(activeChannels, 0, MAXCH*sizeof(int));
    for (int chNum=0; chNum<fh.NumDSPChannels; chNum++){
        for (int unNum=0; unNum<NHEADERUNITS; unNum++){
            if (fh.WFCounts[chNum][unNum] > 0) {
                // Non-zero waveform count, create a new unitData structure for the channel and waveform and add to the map
                activeChannels[chNum] = 1;
                unitData *newUnit = new unitData(chNum, unNum, fis->nSamples, fh.WFCounts[chNum][unNum]);
                (*unitMap)[make_pair(chNum,unNum)] = newUnit; 
                // mexPrintf("Adding unit to map (ch=%i,un=%i)\n",chNum,unNum);
            }
        }
        if (fh.WFCounts[chNum][NHEADERUNITS-1] > 0) {
            // Might be more sorted units but can't tell from the header
            needDataAnalysis = true;
        }
    }

    // Read spike channel headers and calculate voltage conversion factors
    PL_ChanHeader chHead;
    for (int ii=0; ii<fh.NumDSPChannels; ii++){
        plxFileStream->read((char *)&chHead, sizeof(chHead));
        if (activeChannels[ii+1] > 0){ // plus one for 1-based ch indexing
            // mexPrintf("%i: Channel %i Name = '%s', SIGName = '%s'\n",ii,chHead.Channel,chHead.Name,chHead.SIGName);
            fis->vCF[chHead.Channel] = fh.SpikeMaxMagnitudeMV / (0.5*pow((double)2,(int)fh.BitsPerSpikeSample)*chHead.Gain*fh.SpikePreAmpGain);
            spikeChannelInfo *chInfo = new spikeChannelInfo;
            chInfo->Channel = chHead.Channel;
            chInfo->WFRate = chHead.WFRate*10;
            chInfo->SIG = chHead.SIG;
            chInfo->Ref = chHead.Ref;
            chInfo->Gain = chHead.Gain;
            chInfo->Filter = chHead.Filter;
            chInfo->Threshold = chHead.Threshold;
            chInfo->Method = chHead.Method;
            chInfo->NUnits = chHead.NUnits;
            chInfo->Name = chHead.Name;
            chInfo->SIGName = chHead.SIGName;
            fis->channelInfo.push_back(chInfo);
        }
    }
    delete[] activeChannels;
    
    // Skip over event and A/D channel headers and save the data block
    // start location
    plxFileStream->seekg(fh.NumEventChannels*sizeof(PL_EventHeader)+
        fh.NumSlowChannels*sizeof(PL_SlowChannelHeader),ios::cur);
    fis->dataStartPos = plxFileStream->tellg();

    // If flag is set, call the routine to identify all units and count the total number of waveforms for each by analyzing the full data block 
    if (needDataAnalysis) {
        // Parse through data words to make sure all units have been identified
        mexWarnMsgIdAndTxt("extractPlxUnits:MissedUnit","extractPlxUnits: possible missed units");
        // checkMapContents(plxFileStream,fis,unitMap);
        // success = false;
    }

    if (!averageWaveforms){
        // Pre-allocate memory locations large enough to store all of the waveforms for each unit
        // iterate over map contents, telling each unit to allocate memory
        mexWarnMsgIdAndTxt("extractPlxUnits:NoPreAllocate","extractPlxUnits: no preallocation yet for non-average");
        success = false;
    }

    return(success);
}

void checkMapContents(ifstream *plxFileStream, FileInfoStruct *fis, map<pair<int,int>,unitData *> * unitMap){
    // Go through the entire data block to make sure that the map contains complete information for each sorted unit
    return;
}

void extractUnitData(ifstream *plxFileStream, FileInfoStruct *fis, map<pair<int,int>,unitData *> * unitMap){
// Extracts waveforms from all units contained in the unitMap

    // Start at the beginning of the data words
    plxFileStream->seekg(fis->dataStartPos);

    // Create some variables to keep track of any units that are not in the map
    map<pair<int,int>,int> missingUnitsMap;
    ostringstream missingUnitsStrs[512];

    // Parse through the data section - read header information to the dh variable, switch on the header type.
    PL_DataBlockHeader dh; // data header
    int headerBits = sizeof(PL_DataBlockHeader);
    short int *dataBuffer = new short int[MAXWORDS]; // buffer for data words
    double *wfBuffer = new double[MAXWORDS]; // buffer for converted voltages
    unitData *theUnit;
    double vCF;
    int evCounter = 0;
    while (plxFileStream->tellg() <= fis->stopPos){
        // Read the data block header and select proper behavior
        plxFileStream->read((char *)&dh, headerBits);
        switch (dh.Type) {
            case PL_SingleWFType:
            if (dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform != fis->nSamples){
                mexPrintf("extractUnitData: nSamples does not match NumberOfWaveforms*dh.NumberOfWordsInWaveform\n");
            }
            // If the unit specified by channel and unit numbers is in the map, get it and add the waveform
            if (unitMap->find(make_pair(dh.Channel,dh.Unit)) != unitMap->end()){
                theUnit = (*unitMap)[make_pair(dh.Channel,dh.Unit)];
                plxFileStream->read((char *)dataBuffer,dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform*INT16);
                vCF = fis->vCF[dh.Channel];
                for (int iW=0;iW<dh.NumberOfWordsInWaveform;iW++){
                    wfBuffer[iW] = vCF*(double)dataBuffer[iW];
                }
                theUnit->addWaveform(dh.TimeStamp*fis->tCF,wfBuffer);
                break;
            } else if (missingUnitsMap.find(make_pair(dh.Channel,dh.Unit)) == missingUnitsMap.end()){
                // Save one description string for each unit in the data section that is missing from the map
                int index = missingUnitsMap.size();
                missingUnitsStrs[index] << "unit not in map: ch "<<dh.Channel<<", un "<<dh.Unit;
                missingUnitsMap[make_pair(dh.Channel,dh.Unit)] = index;
            }
            case PL_ExtEventType:
            if (dh.Channel == PL_StrobedExtChannel){
                fis->evTs[evCounter] = dh.TimeStamp*fis->tCF; // time stamp
                fis->ev[evCounter] = dh.Unit; // event value
                evCounter += 1;
            }
            default: // skip over the data words
            plxFileStream->seekg(dh.NumberOfWaveforms*dh.NumberOfWordsInWaveform*INT16,ios::cur);
        }
    }
    delete[] dataBuffer;
    delete[] wfBuffer;

    // Show the units that were in the file but not in the map
    for (map<pair<int,int>,int>::iterator it=missingUnitsMap.begin(); it!=missingUnitsMap.end(); ++it){
        mexPrintf("%s\n",missingUnitsStrs[it->second].str().c_str());
    }
}


