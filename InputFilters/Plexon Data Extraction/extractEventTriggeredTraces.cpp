/*
 * Function to extract voltages traces for a fixed period of time following 
 * stobed events from continuously recorded data
 *
 * See extractEventTriggeredTraces.m for usage
 *
 * v1.0     J.Gavornik      20 June
 * v1.1     J.Gavornik      21 Oct 2010
 *              Added roundFnc() since round() is not included in c++
 *              standard libraries. Replaced cout with mexPrintf
 * v1.2     J.Gavornik      6 May 2011
 *              Repurposed extractPLXEventVEPs.cpp as 
 *              extractEventTriggeredTraces to work with VEPDataClass suite
 * v1.3     J.Gavornik      3 August 2011
 *              Modified to allow for an extraction window that precedes
 *              brackets the event
 * v1.4     J.Gavornik      11 Feb 2017
 *              Fixed index error that could, rarely, cause segfault
 *
 */

#include "mex.h"
#include <math.h>

//#define DEBUG

// round function
int roundFunc(double d){
    return floor(d+0.5);
}

static void extractEventVEPs(int nSamples, int nEvents, double *ts_ev,
        double *ad_data, double *t, int nMax, double *packs, 
        double pre_window);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    // Check usage
    bool posOnly; // set to false if extract window includes time points before the event
    if (nrhs< 4)
        mexErrMsgTxt("extractPLXEventVEPs: 4 inputs required.");
    else if (nrhs == 4)
        posOnly = true;
    else
        posOnly = false;
    if (mxGetN(prhs[1])!=mxGetN(prhs[2]) || mxGetM(prhs[1])!=mxGetM(prhs[2])){
        mexErrMsgTxt("extractPLXEventVEPs: ad_data and t should be the same size");
    }
    if (mxGetM(prhs[1])!=1)
        mexErrMsgTxt("extractPLXEventVEPs: ad_data should be a row vector");
    if (mxGetM(prhs[2])!=1)
        mexErrMsgTxt("extractPLXEventVEPs: t should be a row vector");
    if (!mxIsDouble(prhs[3]) || mxGetN(prhs[3])*mxGetM(prhs[3])!=1) {
        mexErrMsgTxt("extractPLXEventVEPs: pack_length should be scalar");
    }
    
    // Process Inputs
    double *ts_ev, *ad_data, *t, pack_length, pre_window, post_window;
    ts_ev = mxGetPr(prhs[0]); // high-res event times
    int nEvents = mxGetN(prhs[0]); // number of events
    ad_data = mxGetPr(prhs[1]); // voltages
    int nMax = mxGetN(prhs[1]); // total number of samples in a/d data
    t = mxGetPr(prhs[2]); // low-res time vector for a/d data
    if (posOnly){
        pre_window = 0;
        post_window = mxGetScalar(prhs[3]);
    } else {
        pre_window = mxGetScalar(prhs[3]);
        if (pre_window < 0) // make sure this is a positive value
                pre_window = pre_window * -1;
        post_window = mxGetScalar(prhs[4]);
    }
    pack_length = post_window + pre_window; // time to extract, in seconds
    double dt = t[1]-t[0]; // low-res time step
    int nSamples = roundFunc(pack_length/dt); // number of samples in pack_length seconds

    #ifdef DEBUG
    mexPrintf("dt = %f, nEvents = %i, nSamples = %i\n",dt,nEvents,nSamples);
    #endif
            
    // Allocate memory to hold output and assign to variables
    double *packs, *t_vec;
    plhs[0] = mxCreateDoubleMatrix(nSamples, nEvents, mxREAL);
    packs = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(1, nSamples, mxREAL);
    t_vec = mxGetPr(plhs[1]);

    // Create a time vector for each individual pack
    //for (int i=1; i<=nSamples-1; i++) t_vec[i] = i * dt - pre_window;
    for (int i=0; i<=nSamples; i++) t_vec[i] = i * dt - pre_window;
    
    // Call function to do the extraction work
    extractEventVEPs(nSamples,nEvents,ts_ev,ad_data,t,nMax,packs,
            pre_window);
}

/* Function to extract a fixed period of time following each event
 * timestamp.
 * Notes:
 *  1. this assumes that ts_ev are ordered lowest to highest
 *  2. fills with zeros for indici outside the dimensions of a/d data
 */
static void extractEventVEPs(int nSamples, int nEvents, double *ts_ev,
        double *ad_data, double *t, int nMax, double *packs, 
        double pre_window){
    int ti = 0; // index into t
    double te; // current event time stamp
    int evOffset; // index offset into 2-D data
    int iData; // index into AD data
    int iPack; // index into 2-D data
    for (int event=0;event<nEvents;event++){
        te = ts_ev[event]; // the event time
        // find the first time index >= te - pre_window
        while (t[ti]<te-pre_window) {
            ti = ti+1;
            if (ti > nMax) {
                    mexPrintf("extractEventTriggeredTraces - WARNING - ti>nMax, data missing");
                    return;
            }
        }
        iData = ti; // index into a/d data
        
        // Warn the user if the first data sample is also the first
        // element of the array - this might mean there was not enough
        // buffer before the event and data is being dropped
        if (iData == 1 && pre_window >0)
            mexPrintf("extractEventTriggeredTraces - WARNING - data might be dropped for event number %i\n", event);
        
        // Calculate the mean value of the first few samples - will be
        // used to make the initial part of the data zero-mean for
        // graphing purposes
        double mv = 0;
        for (int ii=0;ii<10;ii++) {
            if ((iData+ii)>nMax){
                mexPrintf("extractEventTriggeredTraces - WARNING - (iData+ii)>nMax, data missing");
                    return;
            }
            mv = mv + ad_data[iData+ii];
        }
        mv = mv/10;
        
        // Extract the data surround the event
        evOffset = event*nSamples; // index offset for 2-D array
        iPack = evOffset;
        int maxPackIndex = (int)(nSamples*nEvents);
        for (int sample=0; sample<nSamples; sample++){
            if (iData < nMax) packs[iPack++] = ad_data[iData++] - mv;
            else packs[iPack++] = 0;
            if (iPack>maxPackIndex) {
                mexPrintf("extractEventTriggeredTraces - WARNING - iPack>maxPackIndex\n");
                break;
            }
        } // sample loop
    } // event loop
    
    #ifdef DEBUG
            mexPrintf("te=%f,evOffset=%i,nSamples*nEvents=%i,iPack=%i,iData=%i\n",
            te, evOffset, nSamples*nEvents, iPack, iData);
    #endif
            
}


