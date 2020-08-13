// This is a modified version of Plexon.h with long data types replaced by 
// int. The reason for this is that 64 bit systems use the LP64 data model
// where sizeof(long) is 8 bytes; the data extraction code from the 
// VEPAnalysisSuite assumes that sizeof(long) is 4 bytes as it was under
// the 32 bit ILP32 data model. Compiling this code in a 64 bit  
// environment will cause memory problems and Matlab crashes.
//                                                  Gavornik 9/22/2011

// digitizer file header
struct DigFileHeader {
	int		Version;
	int		DataOffset;
	double	Freq;
	int		NChannels;
	int		Year; // when the file is created
	int		Month; // when the file is created
	int		Day; // when the file is created
	int		Hour; // when the file is created
	int		Minute; // when the file is created
	int		Second; // when the file is created
	int		Gain; 
	char	Comment[128];
	int		Padding[64]; 
};


// plexon.h: objects that are exposed to clients
//

struct PL_ServerArea{
	int	Version; // MMF version 100
	int ParAreaSize;  // 512
	int TSTick; // in microsec., multiple of 25
	int WFLength;  // 128
	int NumWF;   // number of waveforms in the MMF,
				// set in the server options
	int StartWFBuffer; // equals to the length of this structure
	int MMFLength;   //total length of the MMF
					// = StartWFBuffer + WFLength*NumWF
	// current nums for waveforms and timestamps
	int WFNum;		// absolute number of waveforms written to the MMF
	int TSNum;
	int NumDropped; // number of w/f dropped by the server
	int NumSpikeChannels; 
	int NumEventChannels;
	int NumContinuousChannels;
	};

#define	PL_SingleWFType			(1)
#define	PL_ExtEventType			(4)
#define	PL_ADDataType			(5)
#define	PL_StrobedExtChannel	(257)
#define	PL_StartExtChannel		(258)
#define	PL_StopExtChannel		(259)

// MMF has a circular buffer of PL_Wave structures.
// this structure is used in MMF as the first part of the
// PL_Wave structure -- see PL_Wave below.
//
// PL_Event is used in PL_GetTimestampStructures(...)

struct PL_Event{
	char	Type;  // so far, PL_SingleWFType or PL_ExtEventType
	char	NumberOfBlocksInRecord;
	char	BlockNumberInRecord;
	char	UpperTS; // fifth byte of the waveform
	int	TimeStamp;
	short	Channel;
	short	Unit;
	char	DataType; // tetrode stuff, ignore for now
	char	NumberOfBlocksPerWaveform; // tetrode stuff, ignore for now
	char	BlockNumberForWaveform; // tetrode stuff, ignore for now
	char	NumberOfDataWords; // number of shorts (2-byte integers) that follow this header 
	}; // 16 bytes

#define		MAX_WF_LENGTH	(56)
#define		MAX_WF_LENGTH_int	(120)

// the same as event above with extra waveform
// this is the structure used in the MMF
struct PL_Wave {
	char	Type;
	char	NumberOfBlocksInRecord;
	char	BlockNumberInRecord;
	char	UpperTS;
	int	TimeStamp;
	short	Channel;
	short	Unit;
	char	DataType; // tetrode stuff, ignore for now
	char	NumberOfBlocksPerWaveform; // tetrode stuff, ignore for now
	char	BlockNumberForWaveform; // tetrode stuff, ignore for now
	char	NumberOfDataWords; // number of shorts (2-byte integers) that follow this header 
	short	WaveForm[MAX_WF_LENGTH];
}; // size should be 128

struct PL_WaveLong {
	char	Type;
	char	NumberOfBlocksInRecord;
	char	BlockNumberInRecord;
	char	UpperTS;
	int	TimeStamp;
	short	Channel;
	short	Unit;
	char	DataType; // tetrode stuff, ignore for now
	char	NumberOfBlocksPerWaveform; // tetrode stuff, ignore for now
	char	BlockNumberForWaveform; // tetrode stuff, ignore for now
	char	NumberOfDataWords; // number of shorts (2-byte integers) that follow this header 
	short	WaveForm[MAX_WF_LENGTH_int];
}; // size should be 256


// .plx file structure
// file header (is followed by the channel descriptors)
struct	PL_FileHeader {
	unsigned int	MagicNumber; //	= 0x58454c50;
	int		Version;
	char    Comment[128];
	int		ADFrequency; // Timestamp frequency in hertz
	int		NumDSPChannels; // Number of DSP channel headers in the file
	int		NumEventChannels; // Number of Event channel headers in the file
	int		NumSlowChannels; // Number of A/D channel headers in the file
	int		NumPointsWave; // Number of data points in waveform
	int		NumPointsPreThr; // Number of data points before crossing the threshold
	int		Year; // when the file was created
	int		Month; // when the file was created
	int		Day; // when the file was created
	int		Hour; // when the file was created
	int		Minute; // when the file was created
	int		Second; // when the file was created
	int		FastRead; // not used
	int		WaveformFreq; // waveform sampling rate; ADFrequency above is timestamp freq 
	double	LastTimestamp; // duration of the experimental session, in ticks
	//char	Padding[56]; // so that this part of the header is 256 bytes
	
	// Valid if Version >= 103
	char Trodalness;
	char DataTrodalness;
	char BitsPerSpikeSample;
	char BitsPerSlowSample;
	unsigned short SpikeMaxMagnitudeMV;
	unsigned short SlowMaxMagnitudeMV;
	
	// Valid id Version >= 105
	unsigned short SpikePreAmpGain;
	char Padding[46];
	
	// counters
	int		TSCounts[130][5]; // number of timestamps[channel][unit]
	int		WFCounts[130][5]; // number of waveforms[channel][unit]
	int		EVCounts[512];    // number of timestamps[event_number]
};


struct PL_ChanHeader {
	char	Name[32];
	char	SIGName[32];
	int		Channel;// DSP channel, 1-based
	int		WFRate;	// w/f per sec divided by 10
	int		SIG;    // 1 - based
	int		Ref;	// ref sig, 1- based
	int		Gain;	// 1-32, actual gain divided by 1000
	int		Filter;	// 0 or 1
	int		Threshold;	// +- 2048, a/d values
	int		Method; // 1 - boxes, 2 - templates
	int		NUnits; // number of sorted units
	short	Template[5][64]; // a/d values
	int		Fit[5];			// template fit 
	int		SortWidth;		// how many points to sort (template only)
	short	Boxes[5][2][4];
	int		Padding[44];
};

struct PL_EventHeader {
	char	Name[32];
	int		Channel;// input channel, 1-based
	int		IsFrameEvent; // frame start/stop signal
	int		Padding[64];
};

struct PL_SlowChannelHeader {
	char	Name[32];
	int		Channel;// input channel, 0-based
	int		ADFreq; 
	int		Gain;
	int		Enabled;
	int		PreAmpGain;
	int		SpikeChannel;
	char	Comment[128];
	int		Padding[28];
	//int		Padding[62];
};

// the record header used in the datafile (*.plx)
// it is followed by NumberOfWaveforms*NumberOfWordsInWaveform
// short integers that represent the waveform(s)
struct PL_DataBlockHeader{
	short	Type;
	short	UpperByteOf5ByteTimestamp;
	int	TimeStamp;
	short	Channel;
	short	Unit;
	short	NumberOfWaveforms;
	short	NumberOfWordsInWaveform; 
}; // 16 bytes


// extracted file header
struct ShortHeader {
	char	FileName[512];
	int		Version;
	int		Channel;
	int		NWaves;
	int		NPointsWave;
	int		TSFrequency;
	int		WaveFormFreq;
	int		ValidPCA;
	float	PCA[8][128];
	int		Padding[256];
};


// global parameter area (a separate MMF)
// we will use the plx file channel info:
struct PL_ServerPars {
	int			NumDSPChannels; 
	int			NumSIGChannels;
	int			NumOUTChannels;
	int			NumEventChannels;
	int			NumContinuousChannels;
	int			TSTick; // in microsec., multiple of 25
	int			NumPointsWave; 
	int			NumPointsPreThr; 
	int			GainMultiplier; 
	int			SortClientRunning;
	int			ElClientRunning;
	int			NIDAQEnabled;
	int			SlowFrequency;
	int			DSPProgramLoaded;
	int			PollTimeHigh;
	int			PollTimeLow;
	int			MaxWordsInWF;
	int			ActiveChannel;
	int			Out1Info;
	int			Out2Info;
	int			SWH;
	int			PollingInterval;
	int			Padding[56];
	// not all the info will be stored
	// for example, no names to start with
	PL_ChanHeader Channels[128]; 
	PL_EventHeader Events[512]; 
	PL_SlowChannelHeader SlowChannels[32];
};

// increased number of slow channels to 64
struct PL_ServerPars1 {
	int			NumDSPChannels; 
	int			NumSIGChannels;
	int			NumOUTChannels;
	int			NumEventChannels;
	int			NumContinuousChannels;
	int			TSTick; // in microsec., multiple of 25
	int			NumPointsWave; 
	int			NumPointsPreThr; 
	int			GainMultiplier; 
	int			SortClientRunning;
	int			ElClientRunning;
	int			NIDAQEnabled;
	int			SlowFrequency;
	int			DSPProgramLoaded;
	int			PollTimeHigh;
	int			PollTimeLow;
	int			MaxWordsInWF;
	int			ActiveChannel;
	int			Out1Info;
	int			Out2Info;
	int			SWH;
	int			PollingInterval;
	int			NIDAQ_NCh;
	int			Padding[55];
	// not all the info will be stored
	// for example, no names to start with
	PL_ChanHeader Channels[128]; 
	PL_EventHeader Events[512]; 
	PL_SlowChannelHeader SlowChannels[64];
};


#define COMMAND_LENGTH	(260)

#define WM_CONNECTION_CLOSED	(WM_USER + 401)


