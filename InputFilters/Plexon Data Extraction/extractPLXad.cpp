/*
 * Function to extract raw A/D and event channel data from PLX files
 * Based on, and replacement for, plx_ad.m
 *
 * See extractPLXad.m for usage
 *
 * v1.0     J.Gavornik      22 June 2010
 *              Initial conversion from plx_ad.m
 * v1.1     J Gavornik      6 Oct 2010 
 *              Use header definitions in Plexon.h and return AD in mV with
 *              conversion based on parameters stored in the headers
 * v1.2     J Gavornik      21 Oct 2010
 *              Update dynamic memory allocation to work with visual C++,
 *              plugged a couple of leaks, and replaced calls to cout with
 *              mexPrintf() statements
 * v1.3     J Gavornik      8 Dec 2010
 *              Update to generate low res time stamps internally, also
 *              updated extractPLXad.m to include the change
 * v1.4     J Gavornik      5 May 2011
 *              Update to read all A/D channels from the plx file without
 *              requiring the user specify which channels to extract and 
 *              hardcoded in eventchannel 257
 * NOTE: 23 May 2011 - Noticed that the ad variable is not getting deleted
 *                     Should use mxDestroyArray to delete the mxArray 
 *                     that is allocated using the mxCreateDoubleMatrix()
 *                     call on line 273
 * v1.5     J Gavornik    22 Sept 2011
 *              Use Plexon_LP64.h to allow use on 64 bit systems
 * v1.6     J Gavornik     22 Aug 2012
 *              Omniplex writes events with zero words, change logic to 
 *              include this case
 * v1.7    J Gavornik     22 April 2014
 *              Updated extract function to return success indicator in 
 *              order to prevent segfault when file did not exist
 * v1.8    J Gavornik     24 August 2016
 *              Update to use a hashtable map between channel numbers and 
 *              data counts.  Necessary to handle indexing issues when
 *              reading trodal data
 */

#include "mex.h"
#include <math.h>
#include <fstream>
#include <map>
#include "string.h"
#include "Plexon_LP64.h"

#define INT8  1 // 1 byte, equivalent to char
#define INT16 2 // 2 bytes, equivalent to short int
#define INT32 4 // 4 bytes, equivalent to long int
#define MAXWORDS 1024 // buffer size for a/d data

#define MAXSAMPLES 50000000
#define MAXEVENTS 500000

#define EVCH 257

using namespace std;

int extract_ad_event_data(string filename, // plx file
        int *nChannels , double **adChannels, int evCh, // channel information
        double **ad, double *ts, double *adTs, // a/d and time memory locations
        double *nEv, double *evTs, double *ev, // event channel information
        double *adFreq, double *nSamples, // sample frequency and number of a/d samples
        int *maxSamples, int *nFragments
        );

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // Check usage
    if (nrhs<1) mexErrMsgTxt("extractPLXad: 1 input required.");
    
    // Read in the filename and convert it into a string object
    if (!mxIsChar(prhs[0])) mexErrMsgTxt("extractPLXad: First input must be a string");
    int nChar = mxGetNumberOfElements(prhs[0]) + 1;
    char *buf = (char *)mxCalloc(nChar, sizeof(char));
    if (mxGetString(prhs[0], buf, nChar) != 0){
        char errMsg[1024];
        sprintf(errMsg,"extractPLXad: Could not read filanme '%s'\n",buf);
        mexErrMsgTxt((const char *)errMsg);
    }
    string filename = buf;
    mxFree((void *)buf);
    
    // Read the event channel number
    int evCh = EVCH;
    
    // Create a pointer that will be directed towards the raw A/D data by
    // the extract function
    double *ad;
   
    // Create integers that will record the number of A/D channels read
    // by the extract function and the channel numbers - these will be 
    // setup as outputs after the extract function returns
    int nChannels;
    double *adChannels;
    
    // Preallocate some big chunks of memory and create function outputs
    int maxSamples = MAXSAMPLES;
    int maxFrags = maxSamples/100;
    int maxEvents = MAXEVENTS;
        
    // time stamps of a/d fragments
    plhs[1] = mxCreateDoubleMatrix(1, maxFrags, mxREAL);
    double *ts = mxGetPr(plhs[1]);
    // total number of samples
    plhs[2] = mxCreateDoubleMatrix(1, 1, mxREAL);
    double *nSamples = mxGetPr(plhs[2]);
    // strobed event values
    plhs[3] = mxCreateDoubleMatrix(1, maxEvents, mxREAL);
    double *ev = mxGetPr(plhs[3]);
    // strobed event timestamps
    plhs[4] = mxCreateDoubleMatrix(1, maxEvents, mxREAL);
    double *evTs = mxGetPr(plhs[4]);
    // number of events
    plhs[5] = mxCreateDoubleMatrix(1, 1, mxREAL);
    double *nEv = mxGetPr(plhs[5]);
    // a/d sample frequency
    plhs[6] = mxCreateDoubleMatrix(1, 1, mxREAL);
    double *adFreq = mxGetPr(plhs[6]);
    // ad time stamps
    plhs[7] = mxCreateDoubleMatrix(1, maxSamples, mxREAL);
    double *adTs =  mxGetPr(plhs[7]);
        
    // Call function to do all the work
    int nFragments = 0;
    if (extract_ad_event_data(filename, 
            &nChannels, &adChannels, evCh, 
            &ad, ts, adTs, 
            nEv, evTs, ev, 
            adFreq, nSamples,
            &maxSamples, &nFragments))
    {
        // Copy from  preallocation a/d buffer into a matrix correctly sized
        // based on the number of samples read from the plx file
        plhs[0] = mxCreateDoubleMatrix(nChannels,*nSamples, mxREAL);
        double *ad_resize = mxGetPr(plhs[0]);
        int offset;
        int index = 0;
        for (int ii=0; ii<nChannels; ii++){
            offset = ii * maxSamples;
            for (int jj=0; jj<(int)*nSamples; jj++)
                ad_resize[jj*nChannels+ii] = ad[offset++];
        }
        
        // Create an output for the channel info and copy the values
        plhs[8] = mxCreateDoubleMatrix(1, nChannels, mxREAL);
        memcpy(mxGetPr(plhs[8]),adChannels,nChannels*sizeof(double));
        delete[] adChannels;
        
        // Shrink existing sized buffers for other return variables - note,
        // these functions only work well for 1D vectors
        mxSetN(plhs[1], nFragments); // ts
        mxSetN(plhs[3], *nEv); // ev
        mxSetN(plhs[4], *nEv); // evTs
        mxSetN(plhs[7],*nSamples); // adTs
    }
}

int extract_ad_event_data(string filename, // plx file
        int *nChannels , double **adChannels, int evCh, // channel information
        double **ad, double *ts, double *adTs, // a/d and time memory locations
        double *nEv, double *evTs, double *ev, // event channel information
        double *adFreq, double *nSamples, // sample frequency and number of a/d samples
        int *maxSamples, int *nFragments
        ){
    
    mexPrintf("\tExtracting A/D data from %s\n",filename.c_str());
    
    // Open the file for reading and calculate its length -----------------
    ifstream plxFile;
    plxFile.open(filename.c_str(), ifstream::in | ifstream::binary);
    if (!plxFile.good()){
        char errMsg[1024];
        sprintf(errMsg,"extractPLXad: Error Opening File %s\n",filename.c_str());
        mexErrMsgTxt((const char *)errMsg);
    }
    plxFile.seekg(0, ios::end);
    int fileLength = plxFile.tellg();
    plxFile.seekg(0, ios::beg);
    // mexPrintf("fileLength = %i bytes\n",fileLength);
    
    // Get information from the file headers ------------------------------
	// Extract the file header and get timestamp frequency and the number 
    // of events on the specified evCh
    PL_FileHeader fh;
    plxFile.read((char *)&fh, sizeof(fh));
    *adFreq =fh.ADFrequency;
    *nEv = fh.EVCounts[evCh];
    // Error if file version is less than 105
    if (fh.Version < 105) mexErrMsgTxt("extractPLXad: version less than 105");
	
    // Skip over the Spike and Event channel headers
    plxFile.seekg(fh.NumDSPChannels*sizeof(PL_ChanHeader)+
            fh.NumEventChannels*sizeof(PL_EventHeader),ios::cur);
    
    // Read AD headers,  calculate conversion factors.  
    // Use maps indexed by reported channel numbers
    int nHeaders = fh.NumSlowChannels;
	PL_SlowChannelHeader *slowheaders = new PL_SlowChannelHeader[nHeaders];
    int nBytes = nHeaders*sizeof(PL_SlowChannelHeader);
    plxFile.read((char *)slowheaders, nBytes);
    std::map <int,double> conversionFactors; // <ch number,uV conversion factor>
    std::map <int,double> slowADConv; // <ch number,time conversion factor>
    unsigned short adRefVal = fh.SpikeMaxMagnitudeMV;
    double bitValue = 0.5 * pow((double)2,(int)fh.BitsPerSlowSample);
    for (int ii=0;ii<nHeaders;ii++){
        conversionFactors[slowheaders[ii].Channel] = adRefVal / 
                (bitValue*slowheaders[ii].Gain*slowheaders[ii].PreAmpGain);
        slowADConv[slowheaders[ii].Channel] = 1/(double)slowheaders[ii].ADFreq;
    }

    // Create variables to use when reading AD data -----------------------
    short int type, channel, nWords, unit; // based on defs in Plexon.h
    long int timestamp; // based on defs in Plexon.h
    int stopPos; // used to stop reading from the file
    
    // Figure out which AD channels have data -----------------------------
    // Note: this is a hack made necessary by the fact that the
    // enabled field in all of the PL_SlowChannelHeaders is set to 1
    // irrespective of whether the channel was actually enabled at record
    // time
    
    // Save the current location within the file
    streampos dataStartPos = plxFile.tellg();
    
    // Loop over all data headers, count the total number of data words in
    // each slow channel
    std::map <int,int> channelMap; // <ch number,word count>
    PL_DataBlockHeader dh;
    nBytes = sizeof(PL_DataBlockHeader);
    stopPos = fileLength-nBytes;
    while (plxFile.tellg() <= stopPos){
        // Read header and extract needed info
        plxFile.read((char *)&dh, nBytes);
        channel = dh.Channel;
        nWords = dh.NumberOfWordsInWaveform;
        if (nWords>0){
            if (dh.Type == PL_ADDataType){ // A/D channels only
                channelMap[channel] += dh.NumberOfWordsInWaveform;
            }
            plxFile.seekg(nWords*INT16, ios::cur); // Skip the data words
        }
    }
    
    // Make sure that each AD channel with data has the same amount of data
    // If not, throw a warning so that the user will have a chance of 
    // troubleshooting when the program segfaults (since it will allocate
    // data assuming all channels have the same amount of data.  Also select
    // a channel that will be used later for creating the time array into
    // all AD channels
    int adWordCount = 0;
    int misMatch = 0;
    int timeRefChannel;
    for (std::map<int,int>::iterator it=channelMap.begin(); it!=channelMap.end(); ++it){
        if (adWordCount == 0) {
            adWordCount = it->second;
            timeRefChannel = it->first;
        } else if (adWordCount != it->second) misMatch = 1;
    }
    if (misMatch) mexWarnMsgTxt("extractPlxAD: AD channels word counts do not match, memory allocation might fail\n");
    if (adWordCount>MAXSAMPLES) {
        char errMsg[1024];
        sprintf(errMsg,"extractPLXad: adWordCount (%i) > MAXSAMPLES (%i)\n",adWordCount,MAXSAMPLES);
        mexErrMsgTxt((const char *)errMsg);
    }
            
    // Count the number of channels with data, save indexes into the final
    // data arrays for each channel with non-zero word count
    *nChannels = channelMap.size();
    //int *adCh = new int[*nChannels]; // local index variables
    std::map <int,int> adCh; // ch num, index
    *adChannels = new double[*nChannels]; // doubles for mex file return
    int index = 0;
    for (std::map<int,int>::iterator it=channelMap.begin(); it!=channelMap.end(); ++it){
        adCh[it->first]= index;
        (*adChannels)[index] = (double)(it->first);
        index++;
    }
    
    // Return to the data start location
    plxFile.seekg(dataStartPos);
    // mexPrintf("currentPos = %i\n",(unsigned long int)plxFile.tellg());
    
    // Extract a/d data from all active channels --------------------------
    
    // Allocate large chunk of memory to hold adData, based on the 
    // fileLength and number of AD channels - approximate only, will resize
    // to the true number of samples after data extraction is complete
    *maxSamples = (int)(fileLength / (*nChannels*2));
    mxArray *adMxArray = mxCreateDoubleMatrix(*maxSamples, 
            *nChannels, mxREAL);
    *ad =  mxGetPr(adMxArray);
    
    // Define counters and variables for use in the loop
    int ns = 0, nf = 0, ne = 0; // sample fragment and event counters
    int nts = 0; // ad sample time stamp counter
    int chIndex = 0; // index into channel array
    bool goodChannel = false;
    bool calcTimeStamps;
    double timeConv = 1/(*adFreq); // convert to seconds based on sampling rate
    int *adpos = new int[*nChannels]; // index into a/d data
    for (int ii=0; ii<*nChannels; ii++) adpos[ii] = 0;
    int chOffset; // offset for column-wise indexing into 2D matrix
    double cf; // data conversion factor
    char *dataBuffer = new char[MAXWORDS*INT16]; // buffer for data words
    nBytes = sizeof(PL_DataBlockHeader);
    while (!plxFile.eof()){
        // Read header and extract needed info
        plxFile.read((char *)&dh, nBytes);
        channel = dh.Channel;
        nWords = dh.NumberOfWordsInWaveform;
        type = dh.Type;
        timestamp = dh.TimeStamp;
        unit = dh.Unit;
        // Read data into buffer
        plxFile.read(dataBuffer, nWords*INT16);
        // Save data depending on type value
        switch (type) {
            case PL_ADDataType: // A/D channels
                // Verify that the channel was previously identified as
                // containing data, calculate voltage, save for return as 
                // in ad matrix
                if (channelMap.count(channel)>0) {
                    // calculate offset for indexing into 2D data array
                    chIndex = adCh[channel];
                    chOffset = *maxSamples * chIndex + adpos[chIndex];
                    // determine if we need to calculate slow time stamps
                    if (channel == timeRefChannel){
                        ns += nWords;
                        *(ts+nf++) = timestamp  * timeConv;
                        calcTimeStamps = true;
                    } else calcTimeStamps = false;
                    // convert each data word to voltage and save
                    for (int iW=0; iW<nWords; iW++) {
                        (*ad)[chOffset + iW] = *(short int *)(dataBuffer+INT16*iW)*conversionFactors[channel];
                        if (calcTimeStamps) { // calc and save time stamp
                            adTs[nts++] = timestamp*timeConv+iW*slowADConv[channel];
                        }
                    }
                    adpos[chIndex] += nWords;
                }
                break;
            case PL_ExtEventType: // Event Channels
                // mexPrintf("PL_ExtEventType %i, channel = %i, unit=%i, ts=%f, \n",type,channel,unit,timestamp*timeConv);
                if (channel == evCh) {
                    evTs[ne] = timestamp * timeConv;
                    ev[ne++] = unit;
                } else if (channel < evCh) {
                    // this should store event value as channel number while skipping start and stop
                    // there is a better way to do this
                    evTs[ne] = timestamp * timeConv;
                    ev[ne++] = channel;
                }
                break;
            default:;
        }
    } // while !eof
    
    // Free dynamically allocated memory
    delete[] dataBuffer;
    delete[] slowheaders;
    delete[] adpos;
    
    // Close the file
    plxFile.close();
    
    // Write counter values back to the calling function
    *nFragments = nf;
    *nSamples = ns;
    *nEv = ne;
        
    mexPrintf("\tReturning %i samples for %i A/D channels\n",ns,*nChannels);
    return(1);
} //extract_ad_event_data