%% This code was created on 2025/01/14 by Baptiste Heiles
% This will drive plane waves with different angles to produce Doppler
% images at each loop. Its especially useful for fUS acquisition. This code
% synchronizes with a constraint on a timeout. If you see warning messages
% such as "'timeToNextAcq' duration too short" after running startAcq,
% increase time between loops or try to reduce computational burden
% This code is on my personal repo
% Modified by Carter Lybbert 2025/12/15
% Modified to use unique SeqControls for each sync/trigger event

clear all;
close all;
clear persistent;% Needed for checkTimeTags and various loop counts


%% Check C: drive free space
driveC = java.io.File('C:\');
freeSpaceGB = driveC.getUsableSpace() / (1024^3);
if freeSpaceGB < 40
    warning('Only %.1f GB free on C: drive (minimum recommended: 40 GB).', freeSpaceGB);
    userChoice = input('Continue anyway? (y/n): ', 's');
    if ~strcmpi(userChoice, 'y')
        fprintf('Session Terminated\n');
        return;
    end
end

%% Add relevant directories
addpath('C:\Users\Administrator\Desktop\CarterfUSI\')
addpath('C:\Users\Administrator\Documents\VantageNXT-2.1.0-p1')
cd('C:\Users\Administrator\Documents\VantageNXT-2.1.0-p1')
addpath(genpath('C:\Users\Administrator\Desktop\CarterfUSI\processing\'))
addpath(genpath('C:\Users\Administrator\Desktop\CarterfUSI\external_functions\'))
addpath(genpath('C:\Users\Administrator\Desktop\CarterfUSI\processing\scripts\'))
addpath(genpath('C:\Users\Administrator\Desktop\CarterfUSI\ui_functions'))
activate

%% User defined parameters (basic)
UserParam.dataPathSave = 'C:\Users\Administrator\Desktop\CarterfUSI\data\';
UserParam.savePrefix = 'P7-4_';
UserParam.mode = '2DPW_allSuperFrames';% Mode to put everything into the superframes
UserParam.BeamformMode='VSX';% Just a placeholder for now
UserParam.ProbeName = 'P7-4'; % Defined for the Trans function
UserParam.TransmitFrequency =5*1e6;% 7.8125/15.6250 in Hz (please check supported transmit frequencies from Vantage Manual or check with this : A = (6:197)'; TxFreq = 250 ./ (2.*A); [A, TxFreq])
UserParam.DutyCycle = 0.67;% Define Duty Cycle
UserParam.HalfCycle = 1;% Define Half Cycle
UserParam.Polarity = 1;% Define polarity of the pulse
UserParam.SpeedOfSound = 1540;% Speed of sound in m/s
UserParam.TransmitWavelength = UserParam.SpeedOfSound ./ UserParam.TransmitFrequency; % Define "Verasonics" wavelength in m
UserParam.ImagingWindow = [0; 50] .* 1E-3; % Imaging Window, start and end in m (user defined)
UserParam.SamplesPerWave = 2;% This is the sampling mode
UserParam.NumBuffers = 1; % This is the number of buffers you want to store in the Vantage local memory
UserParam.NumFrames = 200; % These are the number of frames you want to fit per buffer % 200 is 1 Hz 600 is .3 Hz.
UserParam.NumSuperFrames = UserParam.NumFrames;% No support for splitting frames
UserParam.NumFramesinSuperFrame = 1;% No support for multiple frames per SuperFrames for now
%UserParam.NumLoops =20; % Number of times you loop the sequence. Same convention as accum, if NumLoops=1, then you repeat once, so you have 2 acquisitions.
UserParam.NumLoops = 321; % Number of times you loop the sequence. Same convention as accum, if NumLoops=1, then you repeat once, so you have 2 acquisitions.
%UserParam.NumLoops =5; % Number of times you loop the sequence. Same convention as accum, if NumLoops=1, then you repeat once, so you have 2 acquisitions.

%UserParam.NumLoops =70; % Number of times you loop the sequence. Same convention as accum, if NumLoops=1, then you repeat once, so you have 2 acquisitions.
%UserParam.Voltage =1.6;% Set imaging voltage
UserParam.Voltage = 30;% Set imaging voltage

UserParam.Angles = [-2:4/7:2];
UserParam.NAccum = 0;% Number of accumulation of the RF data (done on the Vantage system). Convention is, if NAccum=1, then you accumulate once, so you have 2 transmits.
UserParam.OverheadTime = (7.*1E-6);% overhead time in btw transmit to prevent time to short
UserParam.TimeBtwAccum = 0.000100; % In seconds

UserParam.TimeBtwFrames = 2/500; % In seconds
UserParam.Apod = 'kaiser'; % Apodization on transmit elements, can be 'none', 'kaiser', 'tukey', 'hamming'
UserParam.TimeBtwSuperFrames=  0; % In seconds, if set to 0, it will proceed without a pause, thus time between last frame of SF i and first frame of SF i+1 is timebtwFrames
%UserParam.TimeBtwLoops=0.2;% In seconds time between loops (in between first frame of loop 0 and first frame of loop 1, this should be equal or less to the time it takes to save all frames!)
UserParam.TimeBtwLoops=0.182;% In seconds time between loops (in between first frame of loop 0 and first frame of loop 1, this should be equal or less to the time it takes to save all frames!)
UserParam.Live = 0;% If this is set to 1 it will acquire as fast as possible, and you will get a button to start acquiring on the VSX GUI
UserParam.checkTimeTags=0;% This will check time tags and display time drifts, useful for making sure acquisition runs normally
UserParam.displayMode=2;% 0 for no display, 1 for B-Mode, 2 for Doppler
UserParam.pixelSize=[0.5,1];% pixel size for beamforming in wavelengths
UserParam.ReceiveFilter='best';
UserParam.AntiAliasingFilter = 20;% Anti-aliasing filter

UserParam.WaitForTrig = 1; % wait for a trigger in from Trig port 1 before beginning loop
UserParam.InfiniteLoop = 0; % return to waiting for a trigger after the first loop
UserParam.isDebug=1;% To display debugging messages
UserParam.isNXT=1; % boolean to set Vantage NXT scanner (1) or older system (0)

%% Compute Trans
Trans.name = UserParam.ProbeName;
Trans.units = 'wavelengths';    % Explicit declaration avoids warning message when selected by default
Trans = computeTrans(Trans);  % Call computeTrans from Verasonics
    UserParam.CenterFrequency=Trans.frequency.*1e6; % Grab center frequency from the Trans structure
    UserParam.CenterWavelength = UserParam.SpeedOfSound ./ UserParam.CenterFrequency; % Define "Verasonics" wavelength in m
Trans.maxHighVoltage = 40;      % Set max voltage

% Parameters for processing/saving/displaying
UserParam.saveRF =0;% save RF data
UserParam.saveBF =1;% save BF data
UserParam.saveDop = 0;% save Doppler data
UserParam.SVD = ceil([0.15 1].*UserParam.NumFrames); % Svd thresholds

% Check for directory
if ~isdir(UserParam.dataPathSave)
    mkdir(UserParam.dataPathSave);
else
    warning(['You re using an existing folder \n'], 'interpreter', 'tex');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% A few checks and definition of parameters %%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
CParam = []; % Initialize a second param structure for convenience
data = []; % Initalize a struct to hold data
figNum = struct(); % Initialize a struct to hold figure numbers
figNum.BF=2;figNum.Dop=3;

%% Create CParam
CParam = createCParam(UserParam, CParam);

%% Check depths and samples and store in CParam structure
[CParam.maxAcqLength, CParam.VSXMaxAcq, CParam.TheoreticalMaxRange, CParam.MaxRangeSample] = checkDepthAndSamples(UserParam, CParam, Trans);

%% Estimate time and memory consumption
checkTimesAndMemory(UserParam, CParam, Trans); % calculate times and memory

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Global Objects %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Specify resource parameters attributes
%{
Resource.Parameters =
Connector, connector # (1(dflt), 2, or [n, m, ...]),
numTransmit, number of available transmitters,
numRcvChannels, number of available receive channels
speedOfSound, speed of sound in meters / sec (deflt 1540)
attenuation, media attenuation in -dB (deflt = 0dB)
speedCorrectionFactor, corrects speed of sound (default = 1.0)
startEvent, event no. to start after freeze (dflt = 1)
simulateMode, 0 = 'use VDAS'(default), 1 = 'simulate'
initializeOnly, 0 = false (default), 1 = 'true'
fakeScanhead, (dflt = 0) if 1, allow to run without probe
UpdateFunction, 'VsUpdate' [default] or user specified
GUI string, 'vsx_gui'[default] or ' < user specified > '
verbose, 0:3 specifying level of warnings / errors
%}

Resource.Parameters.numTransmit =ceil(Trans.numelements./128)*128; % Number of transmits used
Resource.Parameters.numRcvChannels =ceil(Trans.numelements./128)*128; % Number of receives
Resource.Parameters.connector = [1:ceil(Trans.numelements./128)]; % Using two connectors

Resource.Parameters.speedOfSound = UserParam.SpeedOfSound; % Speed of sound is in m/s. This will be used to calculate the wavelength in the rest of the script
Resource.Parameters.simulateMode = 0; % Enable simulation with 1
Resource.Parameters.verbose = 2; % Report all errors%
maxTimeOut=1e7* CParam.TimeOfSuperFrame;

Resource.VDAS.watchdogTimeout = 0;
Resource.VDAS.dmaTimeout = maxTimeOut; % Software timeout in ms! 
% When tranfertoHost is started, SW will wait until the DMAControl sets 
        % the flag transfer-But-Not-Processed. This will timeout based on
        % the parameter VDAS.dmaTimeout. This should thus be an estimate of
        % how fast the transfer from HW to PC goes.
Resource.Parameters.waitForProcessing = 0;% Do not set this to 1 if you want to control precisely the DMAs! When this attribute is set, sequence stop points are set in the hardware sequencer that
        % prevent the hardware sequencer from getting more than one frame ahead of the
        % software processing. When you use this, there is no need to use
        % wait for processing and marktransferprocessed since only
        % completed frames are reported to the lastFrame register. If you
        % want to use this, you should do your processing with the last
        % frame, srcframenum=-1. We do not do this
% Resource.Parameters.startEvent=2;% Set the start event to be the status display event

%% Define transducer (already done in the parameter section)

%% Define PData for reconstruction (optional)
%{
PData =
Coord string % ['rectangular'],'polar','spherical'
PDelta [1x3 double] % spacing between pixels in all dimensions
Size [1x3 double] % rows, cols and sections
Origin [1x3 double] % % x,y,z of top lft corner (for 2D) or top
lft far corner (3D view from z axis).
Region [numRegions Structs] % Region structures
%}
% PData.Origin=[Trans.spacingMm/2,Trans.spacingMm/2,0,0];% Origin is defined as the center of a virtual square transducer of size Trans.spacing
% PData.PDelta=[Trans.spacingMm,Trans.spacingMm, UserParam.TransWavelength./2];% Define voxel size
% PData.Size=[128,128,(UserParam.ImagingWindow(2)-UserParam.ImagingWindow(1))./PData.PDelta(1,3)];% ATTENTION this is switched for 3D in Verasonics : "For 3D volume scans, the axes arrangement is changed, with the
% row dimension corresponding to the Y axis and the sections dimension corresponding with the Z axis."
switch UserParam.BeamformMode
    case 'VSX' % In that case define the PData structure
        PData(1).PDelta = [UserParam.pixelSize(2), 0, UserParam.pixelSize(1)];
        PData(1).Size(1) = ceil(range(UserParam.ImagingWindow)./UserParam.CenterWavelength./PData(1).PDelta(3));
        PData(1).Size(2) = ceil((Trans.numelements*Trans.spacing)/PData(1).PDelta(1));
        PData(1).Size(3) = 1;      % single image page
        PData(1).Origin = [-Trans.spacing*(Trans.numelements-1)/2,0,floor(UserParam.ImagingWindow(1)./UserParam.CenterWavelength)]; % x,y,z of upper lft crnr.
        CParam.PData=PData;
end

%% Simulate media (optional)
if Resource.Parameters.simulateMode
    pt1;
    Media.function = 'movePoints';
end

%% Specify Resource object (if needed)
%{
The Resource Object contains information about the configuration of the system and
storage buffers
Please see Verasonics Manual for complete description. Keep in mind that,
RcvBuffer is the DMA target. The other buffers are for storing,
reconstructing or processing data (InterBuffer, ImageBuffer,
ImagePBuffer). A buffer is a cell organized in rows, colums, sections, pages.
Sections or pages are also called frames for Verasonics. The index of the
cell is called the buffer number. ALL FRAMES SHOULD BE IDENTICAL. In one
Verasonics frame, it is recommended you put everything needed to compose
the final frame (i.e. angles).
%}

for i_buffer = 1:UserParam.NumBuffers
    Resource.RcvBuffer(i_buffer).datatype = 'int16'; % so far only supports int16
    Resource.RcvBuffer(i_buffer).rowsPerFrame = CParam.rowsRcvBuffer;
    Resource.RcvBuffer(i_buffer).colsPerFrame = Resource.Parameters.numRcvChannels; % Will receive on all channels
    Resource.RcvBuffer(i_buffer).numFrames = UserParam.NumSuperFrames; % This is set to the number of transmits for the RCA

    % Interbuffer used to store IQ data
    Resource.InterBuffer(i_buffer).datatype = 'complex';
    Resource.InterBuffer(i_buffer).numFrames = 1;                      % one intermediate buffer needed.
    Resource.InterBuffer(i_buffer).pagesPerFrame = UserParam.NumSuperFrames;
    Resource.InterBuffer(i_buffer).rowsPerFrame = PData(1).Size(1);	% this size allows for maximum range
    Resource.InterBuffer(i_buffer).colsPerFrame = PData(1).Size(2);

    Resource.ImageBuffer(i_buffer).datatype = 'double';
    Resource.ImageBuffer(i_buffer).numFrames = 1;
    Resource.ImageBuffer(i_buffer).rowsPerFrame = PData(1).Size(1);
    Resource.ImageBuffer(i_buffer).colsPerFrame = PData(1).Size(2);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Sequence Objects %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%{
% Order to follow: TW,TX,TPC (optional), TGC, Receive and RcvProfile
(optional), Recon (optional), Process (optional), SeqControl, Event, UI
(optional), save
%}

%% Specify transmits
%{
Transmit waveform type TW. Please see Verasonics manual
%}
TW.type = 'parametric'; % Define the waveform type
TW.Parameters = [UserParam.TransmitFrequency .* 1E-6, UserParam.DutyCycle, UserParam.HalfCycle, UserParam.Polarity]; % [A,B,C,D], transmit a waveform at A-MHz, with an on time duration of B times the half cycle, with a pulse length of C-half cycle and a D-polarity
%{
TX =
waveform:double number of a transmit waveform structure.
Apod [1xM double] (see notes)
aperture double (see notes - only needed for muxed xducers)
Origin [1x3 double] effective origin of transmit beam at xducer
focus double Focal distance in wavelengths (0 = flat).
Steer [1x2 double] Beam steering angles in radians (Theta, Alpha) with theta the angle of the beam projection in the x, z plane from the positive z axis (azimuth), and alpha the angle of the beam with respect to the x, z plane (elevation).
FocalPt [1x3 double] optional method of defining focus(see text)
FocalPtMm [1x3 double] FocalPt in mm instead of wavelengths
Delay [1xM double] delay times for xmitters in wavelengths
TXPD [PData.Sizex3] transmit pixel data
peakCutOff double used to qualify pixel intensities dflt = 1.25
peakBLMax double used to qualify pixel burst lengths
VDASApod [1xN double] translated TX.Apod array for hardware
VDASDelay [1xN double] translated TX.Delay array for hardware
%}
% Design transmit structures for xAM in R and C
TX = [];
CParam.idx_TX= 1 + size(TX, 2);
for iAngle = 1:CParam.NAngles
    TransmitIdx = 1 + size(TX, 2); %   Verasonics increment
    [TX,CParam] = BuildTransmitPW(TX, TransmitIdx, iAngle, Trans, UserParam,CParam);
end
% Add a non-transmitting TX for time between events
TX(end + 1).Delay = TX(end).Delay; TX(end).waveform = TX(end - 1).waveform; TX(end).Apod = 0 .* TX(end - 1).Apod;

TPC(1).hv = UserParam.Voltage;

%% Define TGC Waveform profile
%{
Defines the time - gain - compensation curve for the receive portion of the
acquisition event.
TGC =
CntrlPts [1x8 double] Control points for specifying curve.
rangeMax double No. of wavelengths to max range.
Waveform [1x512 double] 512 gain values for TGC curve.
%}
TGC.CntrlPts =  560*ones(1,8);
TGC.rangeMax = round(UserParam.ImagingWindow(2)./UserParam.CenterWavelength);
TGC.Waveform = computeTGCWaveform(TGC);


%% Conduct BMode Imaging for Neuronavigation
%SetUpP7_4bmSave(UserParam)

%% Specify Receive objects
%{
Receive objects define all of the characteristics of the receive phase of an acquisition
event. In both the Vantage hardware and the simulation software, the TX and Receive
periods start at the same point in time, or time 0.
Receive =
mode double 0 = replace data, 1 = accumulate
Apod [1xnele double] Apodization value (see below) for rcv aper.
aperture double only used with HVMux probes to specify sub - aperture.
startDepth double starting depth of acquisition in wavelengths
endDepth double ending depth of acquisition in wavelengths.
TGC double number of TGC waveform object to use.
bufnum double number of rcv buffer to use (defined in Resource)
framenum double number of frame in rcv buffer to use. All frames
should be the same
acqNum double no. of acquisition in frame sequence.
sampleMode string 'NS200BW(I)', 'BS100BW', 'BS67BW', 'BS50BW', 'custom'
decimSampleRate double sample rate after decimation in MHz.
demodFrequency double frequency that will be translated to 0.
decimFactor double decimation factor after Low Pass Filter
ADCRate double A / D sample rate in MHz
quadDecim double decimation factor after input filter.
samplesPerWave double samples / wavelength of Trans.frequency
startSample double start row for this acqNum (added by VSX).
endSample double ending row for this acqNum (added by VSX).
LowPassCoef [1x12]double sym. coefs for 23 tap FIR following A / D
InputFilter [1x21]double sym. coefs of 41 tap input fltr (4 * Fc smpls)
callMediaFunc double 1 = call Media Function (Simulator only)
%}
Receive = [];
countReceive = 0; % counter to be able to put the other bisectors in the second frame
CParam.idx_Rcv=1+countReceive;
for iBuffer=1:UserParam.NumBuffers
    for iSuperFrames = 1:UserParam.NumSuperFrames
    
        for iFrames = 1:UserParam.NumFramesinSuperFrame
    
                for iAngle = 1:CParam.NAngles
    
                    for iAccum = 0:double(UserParam.NAccum > 0)
                        ReceiveIdx = 1 + countReceive; %   Verasonics increment
    
                        Receive = BuildReceivePW(Receive, ReceiveIdx, iAngle, iAccum, iSuperFrames,iBuffer, Trans, UserParam, CParam);
    
                        Receive(ReceiveIdx).acqNum = Receive(ReceiveIdx).acqNum + (iFrames - 1) .* CParam.OffsetPerAngles .* CParam.NAngles;
                        countReceive = CParam.NTXPerAngle + countReceive;
                    end
    
                end
                
                if Resource.Parameters.simulateMode
                    Receive(end).callMediaFunc = 1;
                end
    
        end

    end
end

%% Define Rcv profile
if UserParam.isNXT
     %RcvProfile.DCsubtract = 'on'; % Subtraction of a per-channel constant from the receive A/D data samples of each channel
    RcvProfile.AntiAliasCutoff = UserParam.AntiAliasingFilter;    % cutoff frequency in MHz for the lowpass lter ahead of the A/D converter
    RcvProfile.PgaGain = 27;	%  Gain in dB of the preamp output buffer prior to the A/D
    RcvProfile.LnaGain = 21;	% Set the overall gain in dB of the xed-gain low noise input amplier stage
    RcvProfile.LnaZin = 100;	% select the feedback resistors used to enable the  active termination  feature controlling the input impedance of the LNA input amplier, as presented to the transducer connector.

else

    RcvProfile.DCsubtract = 'on'; % Subtraction of a per-channel constant from the receive A/D data samples of each channel
    RcvProfile.AntiAliasCutoff = UserParam.AntiAliasingFilter;    % cutoff frequency in MHz for the lowpass lter ahead of the A/D converter
    RcvProfile.PgaGain = 30;	%  Gain in dB of the preamp output buffer prior to the A/D
    RcvProfile.LnaGain = 24;	% Set the overall gain in dB of the xed-gain low noise input amplier stage
    RcvProfile.LnaZinSel = 31;	% select the feedback resistors used to enable the  active termination  feature controlling the input impedance of the LNA input amplier, as presented to the transducer connector.

end
%% Define Recon structure
% The Recon structure provides the general attributes of the reconstruction,
% including the source and destination buffers to use.
%
% Recon = 
%     senscutoff  [double]     Cutoff value for excluding channels from sum.
%     pdatanum [double]     Number of PData structure to use.
%     rcvBufFrame [double]     If provided, overrides the frame no. in ReconInfo
%     newFrameTimeout [double] (dflt 1000 msec) Time to wait for new frm
%     IntBufDest  [1x2 double] [InterBuffer number, frame number]
%     ImgBufDest  [1x2 double] [ImageBuffer number, frame number]
%     RINums [n double]   Row vector of n ReconInfo structure nos.
%     rcvLUT      [uint16]     User provided receive Look Up Table (see text)

Recon=[];
for iSuperFrame = 1:UserParam.NumSuperFrames
    ReconIdx=1+size(Recon,2);% Verasonics increment
    Recon=BuildReconPW(Recon,ReconIdx,iSuperFrame,Trans,UserParam,CParam);
end

%% Define ReconInfo structure
% For each Recon object there is an associated set of ReconInfo objects. 
% Each of the numbers in the Recon.RINums list described above is the 
% number of a specific ReconInfo object.
%
% ReconInfo = 
%     mode [string]    Numeric or string representation
%     txnum [double]    Number of transmit object used for acquisition.
%     rcvnum [double]    Number of receive object used for acquisition.   
%     regionnum  [double]    Number of Region structure for pixel data.
%     pagenum    [double]    Indicates page no. for multi-page InterBuffer
%     normPower  [double]    Optional normalization power (see text).
%     normWeight [double]    Optional normalization weight (see text).
%     scaleFactor [double]   Optional scale factor for all modes.
%     Pre        [string]    'clearInterBuf','clearImageBuf','interleaveRF'
%     Post       [string]    'IQ2IntensityImageBuf','…Add','…Mul'
%     threadSync [double]    default=0, 1=>sync after recon w this RI
%     LUT        [int32]     user provided region Look Up Table (see text)
%     
ReconInfo=[];
for iSuperFrame=1:UserParam.NumSuperFrames
    iPage=iSuperFrame;
    for iAngle=1:CParam.NAngles
        ReconInfoIdx=1+size(ReconInfo,2);%   Verasonics increment
        ReconInfo=BuildReconInfoPWcmp(ReconInfo, ReconInfoIdx, iAngle,iSuperFrame,iPage, Trans, UserParam,CParam);
    end
end

%% Define Sequence Control objects
%{
Sequence Control objects are used to associate special function actions with a
sequence event.
SeqControl =
command [string] Command specifying seq. event action (see Verasonics manual).
condition [string] Condition for enabling command.
argument [double] Command argument
%}

% Define SC structure that holds every SeqControl number
SC.nsc=1;
if UserParam.WaitForTrig == 1
    % Unique trigger SeqControls - one for each trigger event
   % SC.trigIn1=SC.nsc;SC.nsc=SC.nsc+1;      % First spurious trigger
  %  SC.trigIn2=SC.nsc;SC.nsc=SC.nsc+1;      % Second spurious trigger
    SC.trigInMain=SC.nsc;SC.nsc=SC.nsc+1;   % Main trigger
%     SC.trigInMain2=SC.nsc;SC.nsc=SC.nsc+1;   % Main trigger 2

    
    % Unique sync SeqControls - one for each sync event
    SC.preSync1=SC.nsc;SC.nsc=SC.nsc+1;     % Sync after first spurious trigger
  %  SC.preSync2=SC.nsc;SC.nsc=SC.nsc+1;     % Sync after second spurious trigger
    SC.postTrigSync=SC.nsc;SC.nsc=SC.nsc+1; % Sync after main trigger
    
    SC.trigLoop=SC.nsc;SC.nsc=SC.nsc+1;
    SC.trigLoopTst=SC.nsc;SC.nsc=SC.nsc+1;
end
SC.sync=SC.nsc;SC.nsc=SC.nsc+1;
SC.jumpLive=SC.nsc;SC.nsc=SC.nsc+1;
SC.timeBtwAngles=SC.nsc;SC.nsc=SC.nsc+1;
SC.trigOut=SC.nsc;SC.nsc=SC.nsc+1;
SC.timeBtwFrames=SC.nsc;SC.nsc=SC.nsc+1;
SC.timeBtwSuperFrames=SC.nsc;SC.nsc=SC.nsc+1;
SC.timeBtwLoops=SC.nsc;SC.nsc=SC.nsc+1;
SC.loopCntLoop=SC.nsc;SC.nsc=SC.nsc+1;
SC.loopTstLoop = SC.nsc;SC.nsc=SC.nsc+1;
SC.returnToMatlab=SC.nsc;SC.nsc=SC.nsc+1;
if UserParam.InfiniteLoop == 1
    SC.bigJump = SC.nsc;SC.nsc=SC.nsc+1;
end

% Specify SeqControl structure arrays.
SeqControl(SC.jumpLive).command = 'jump'; % jump back to start used when live
SeqControl(SC.jumpLive).argument = 2;% Changed later
SeqControl(SC.timeBtwAngles).command = 'timeToNextAcq';  % time between synthetic aperture acquisitions
SeqControl(SC.timeBtwAngles).argument = CParam.SCtimeBtwTX.*1e6;  % 200 usecs
SeqControl(SC.trigOut).command = 'triggerOut';
SeqControl(SC.trigOut).argument = 2;
SeqControl(SC.trigOut).condition = {'SignalLevel', 3.3, ...
                                    'Polarity', 'ActiveHigh', ...
                                    'Duration', 1000, ...
                                    'Delay', 0};
SeqControl(SC.returnToMatlab).command = 'returnToMatlab';
SeqControl(SC.timeBtwFrames).command = 'timeToNextAcq';  % time between frames
SeqControl(SC.timeBtwFrames).argument = CParam.SCtimeBtwFrames.*1e6 ; % time input by the user minus estimated time btw frames
SeqControl(SC.timeBtwSuperFrames).command = 'timeToNextAcq';  % time between frames
SeqControl(SC.timeBtwSuperFrames).argument = CParam.SCtimeBtwSuperFrames.*1e6 ; % time input by the user minus estimated time btw frames
SeqControl(SC.timeBtwLoops).command = 'timeToNextAcq';  % time between blocks
SeqControl(SC.timeBtwLoops).argument = CParam.SCtimeBtwLoops.*1e6;  % This is equivalent to a pause!
SeqControl(SC.sync).command = 'sync';  % synchronisation soft hard, (no ping pong)
SeqControl(SC.sync).argument = UserParam.TimeBtwLoops.*1e6; % needed for the software to wait for the hardware to end the last TTNA of the loop
SeqControl(SC.loopCntLoop).command = 'loopCnt'; % - Set loop count. for looping on blocs
SeqControl(SC.loopCntLoop).argument = UserParam.NumLoops - 1; % Counter of N-1 gives N total acquisitions;

SeqControl(SC.loopTstLoop).command = 'loopTst';  % loop test
SeqControl(SC.loopTstLoop).argument = [6];    % set apres
SeqControl(SC.loopTstLoop).condition = 'counter1';

if UserParam.WaitForTrig == 1
    % Configure unique trigger SeqControls
%     SeqControl(SC.trigIn1).command = 'triggerIn';
%     SeqControl(SC.trigIn1).argument = 1;
%     SeqControl(SC.trigIn1).condition = {'Activation', 'RisingEdge', 'Timeout', 0};
%     
%     SeqControl(SC.trigIn2).command = 'triggerIn';
%     SeqControl(SC.trigIn2).argument = 1;
%     SeqControl(SC.trigIn2).condition = {'Activation', 'RisingEdge', 'Timeout', 0};
 
    SeqControl(SC.trigInMain).command = 'triggerIn';
    SeqControl(SC.trigInMain).argument = 1;
    SeqControl(SC.trigInMain).condition = {'Activation', 'RisingEdge', 'Timeout', 0};
    
%     SeqControl(SC.trigInMain2).command = 'triggerIn';
%     SeqControl(SC.trigInMain2).argument = 1;
%     SeqControl(SC.trigInMain2).condition = {'Activation', 'RisingEdge', 'Timeout', 0};

    % Configure unique sync SeqControls
    SeqControl(SC.preSync1).command = 'sync';
    SeqControl(SC.preSync1).argument = 20.*1e7; % timeout in microseconds
    
%     SeqControl(SC.preSync2).command = 'sync';
%     SeqControl(SC.preSync2).argument = 20.*1e7;
    
    SeqControl(SC.postTrigSync).command = 'sync';
    SeqControl(SC.postTrigSync).argument = 20.*1e7;
    
    SeqControl(SC.trigLoop).command = 'loopCnt'; % - Set loop count. for looping on blocs
    SeqControl(SC.trigLoop).argument = 1; % Set counter
    SeqControl(SC.trigLoop).condition = 'counter2';
    SeqControl(SC.trigLoopTst).command = 'loopTst';  % loop test
    SeqControl(SC.trigLoopTst).argument = 4;    % set apres
    SeqControl(SC.trigLoopTst).condition = 'counter2';
end

if UserParam.InfiniteLoop == 1
    SeqControl(SC.bigJump).command =  'jump';
    SeqControl(SC.bigJump).argument = 2;% Will be updated later to point to main trigger event
end

%% Define Process objects (Image, Doppler, etc)
%{
Describe the type of processing to apply to acquired or
reconstructed data.
%}
Np=1;
PN.extSaveParams = Np;
Process(Np).classname = 'External';
Process(Np).method = 'extSaveParams';
Process(Np).Parameters = {};
Np = Np + 1;

if UserParam.checkTimeTags
    PN.checkTT(1)=1;
    % Check time tags
    for iTT = 1:UserParam.NumSuperFrames
        PN.checkTT(iTT)=Np+(iTT-1);
        Process(PN.checkTT(iTT)).classname = 'External';
        Process(PN.checkTT(iTT)).method = 'checkTimeTags';
        Process(PN.checkTT(iTT)).Parameters = {'srcbuffer','receive',... % name of buffer to process.
            'srcbufnum',1,...
            'srcframenum',iTT};          % process the most recent frame

    end
    Np=Np+UserParam.NumSuperFrames;
end

PN.saveRF(1)=1;
% Save RF
for isaveSFRF = 1:UserParam.NumSuperFrames
    PN.saveRF(isaveSFRF)=Np+(isaveSFRF-1);
    Process(PN.saveRF(isaveSFRF)).classname = 'External';     % process structure for 1st Doppler ensemble
    Process(PN.saveRF(isaveSFRF)).method = 'saveRFDataFast';
    Process(PN.saveRF(isaveSFRF)).Parameters = {'srcbuffer','receive',... % name of buffer to process.
        'srcbufnum',1,...
        'srcframenum',isaveSFRF};          % process the most recent frame
        
end
Np=Np+UserParam.NumSuperFrames;

% Delay
PN.delayTrig=Np;
Process(PN.delayTrig).classname = 'External';     % process structure for 1st Doppler ensemble
Process(PN.delayTrig).method = 'delayTrig';
Process(PN.delayTrig).Parameters = {};
Np=Np+1;

% Display BFIQ
PN.display=Np;
data.BFIQ=[];% This will hold the compounded values of BFIQ
Process(PN.display).classname = 'External';     % process structure for 1st Doppler ensemble
Process(PN.display).method = 'VSX_displayPW';
Process(PN.display).Parameters = {'srcbuffer','inter',... % name of buffer to process.
    'srcbufnum',1,...
    'srcframenum',1,...            % process the most recent frame.
    'dstbuffer','none'};
Np=Np+1;

% Save IQ data
PN.saveBFIQ=Np;
Process(PN.saveBFIQ).classname = 'External';     % process structure for 1st Doppler ensemble
Process(PN.saveBFIQ).method = 'saveIQDatafUS';
Process(PN.saveBFIQ).Parameters = {'srcbuffer','inter',... % name of buffer to process.
    'srcbufnum',1,...
    'srcframenum',1,...            % process the most recent frame.
    'dstbuffer','none'};
Np=Np+1;

% SVD filtering and compute Doppler
PN.Dop=Np;
Process(PN.Dop).classname = 'External';     % process structure for 1st Doppler ensemble
Process(PN.Dop).method = 'VSX_computeDop';
Process(PN.Dop).Parameters = {'srcbuffer','inter',... % name of buffer to process.
    'srcbufnum',1,...
    'srcframenum',1,...            % process the most recent frame.
    'dstbuffer','image',...
    'dstbufnum', 1,...
    'dstframenum',1};
Np=Np+1;

% Save Dop data
PN.saveDop=Np;
Process(PN.saveDop).classname = 'External';     % process structure for 1st Doppler ensemble
Process(PN.saveDop).method = 'saveDop';
Process(PN.saveDop).Parameters = {'srcbuffer','image',...
    'srcbufnum', 1,...
    'srcframenum',1};
Np=Np+1;

% Display block time
PN.dispBlock=Np;
Process(PN.dispBlock).classname = 'External';     % process structure for 1st Doppler ensemble
Process(PN.dispBlock).method = 'dispBlockTime';
Process(PN.dispBlock).Parameters = {};
Np=Np+1;

%Display when waiting for a trigger
% PN.spurTrigDisp=Np;
% Process(PN.spurTrigDisp).classname = 'External';     % process structure for 1st Doppler ensemble
% Process(PN.spurTrigDisp).method = 'trigDispSpur';
% Process(PN.spurTrigDisp).Parameters = {};
% Np=Np+1;

% Display when waiting for a trigger
PN.trigDisp=Np;
Process(PN.trigDisp).classname = 'External';     % process structure for 1st Doppler ensemble
Process(PN.trigDisp).method = 'trigDisp';
Process(PN.trigDisp).Parameters = {};
Np=Np+1;

% Cnt Acq
PN.uiCntAcq=Np;
Process(PN.uiCntAcq).classname = 'External';     % process structure for 1st Doppler ensemble
Process(PN.uiCntAcq).method = 'uiCntAcq';
Process(PN.uiCntAcq).Parameters = {};

% Specify Event structure arrays.
EventIdx=1;

% Save parameters
Event(EventIdx).info = 'Save Params';
Event(EventIdx).tx = 0;
Event(EventIdx).rcv = 0;
Event(EventIdx).recon = 0;
Event(EventIdx).process = PN.extSaveParams;
Event(EventIdx).seqControl = SC.returnToMatlab; %
EventIdx = 1 + size(Event, 2); % Verasonics increment

if UserParam.WaitForTrig == 1

    % Store the event index for bigJump to return to (not used, but kept for reference)
    triggerStartEventIdx = EventIdx;

    % First spurious trigger wait
%     Event(EventIdx).info = 'Trigger in 1 (spurious)';
%     Event(EventIdx).tx = 0;
%     Event(EventIdx).rcv = 0;
%     Event(EventIdx).recon = 0;
%     Event(EventIdx).process = PN.spurTrigDisp;
%     Event(EventIdx).seqControl = SC.trigIn1;
%     EventIdx = 1 + size(Event, 2);
% 
    Event(EventIdx).info = 'Pre Sync 1';
    Event(EventIdx).tx = 0;
    Event(EventIdx).rcv = 0;
    Event(EventIdx).recon = 0;
    Event(EventIdx).process = 0;
    Event(EventIdx).seqControl = SC.preSync1;
    EventIdx = 1 + size(Event, 2);

%     Event(EventIdx).info = 'Trigger in 2 (spurious)';
%     Event(EventIdx).tx = 0;
%     Event(EventIdx).rcv = 0;
%     Event(EventIdx).recon = 0;
%     Event(EventIdx).process = PN.spurTrigDisp;
%     Event(EventIdx).seqControl = SC.trigIn2;
%     EventIdx = 1 + size(Event, 2);

%     % Delay event
%     Event(EventIdx).info = 'Delay';
%     Event(EventIdx).tx = 0;
%     Event(EventIdx).rcv = 0;
%     Event(EventIdx).recon = 0;
%     Event(EventIdx).process = PN.delayTrig;
%     Event(EventIdx).seqControl = SC.returnToMatlab;
%     EventIdx = 1 + size(Event, 2);

    mainTriggerEventIdx = EventIdx;     % Main trigger - save this index for bigJump

    % Sync after first spurious trigger
%     Event(EventIdx).info = 'Pre Sync 2';
%     Event(EventIdx).tx = 0;
%     Event(EventIdx).rcv = 0;
%     Event(EventIdx).recon = 0;
%     Event(EventIdx).process = 0;
%     Event(EventIdx).seqControl = SC.preSync2;
%     EventIdx = 1 + size(Event, 2);
        
    Event(EventIdx).info = 'Main Trigger';
    Event(EventIdx).tx = 0;
    Event(EventIdx).rcv = 0;
    Event(EventIdx).recon = 0;
    Event(EventIdx).process = PN.trigDisp;
    Event(EventIdx).seqControl = SC.trigInMain;
    EventIdx = 1 + size(Event, 2);

%         Event(EventIdx).info = 'Main Trigger 2';
%     Event(EventIdx).tx = 0;
%     Event(EventIdx).rcv = 0;
%     Event(EventIdx).recon = 0;
%     Event(EventIdx).process = PN.trigDisp;
%     Event(EventIdx).seqControl = SC.trigInMain2;
%     EventIdx = 1 + size(Event, 2);

    % Sync after main trigger - ensures HW/SW alignment before acquisition
    Event(EventIdx).info = 'Post Trigger Sync';
    Event(EventIdx).tx = 0;
    Event(EventIdx).rcv = 0;
    Event(EventIdx).recon = 0;
    Event(EventIdx).process = 0;
    Event(EventIdx).seqControl = SC.postTrigSync;
    EventIdx = 1 + size(Event, 2);

    % Update bigJump to return to main trigger (skip spurious trigger on subsequent loops)
    if UserParam.InfiniteLoop == 1
        SeqControl(SC.bigJump).argument = mainTriggerEventIdx;
    end
end

% Save parameters
Event(EventIdx).info = 'Start acq';
Event(EventIdx).tx = 0;
Event(EventIdx).rcv = 0;
Event(EventIdx).recon = 0;
Event(EventIdx).process = 0;
Event(EventIdx).seqControl = [SC.returnToMatlab]; %
EventIdx = 1 + size(Event, 2); % Verasonics increment
SeqControl(SC.jumpLive).argument = EventIdx; % Set event idx to do live imaging or loop

% set loop count
Event(EventIdx).info = 'start counter and run cntAcq';
Event(EventIdx).tx = 0;   % use next TX structure.
Event(EventIdx).rcv = 0;        
Event(EventIdx).recon = 0;      % no reconstruction.
Event(EventIdx).process = 0;    % no processing
Event(EventIdx).seqControl =  SC.loopCntLoop;
EventIdx = 1 + size(Event, 2); %   Verasonics increment

SeqControl(SC.loopTstLoop).argument = EventIdx;
SeqControl(SC.loopTstLoop).condition = SeqControl(SC.loopCntLoop).condition ;

% Create the master event
[Event,SC,SeqControl]=BuildMasterEvent_PW(Event,UserParam,CParam,Trans,TX,SC,SeqControl,PN);

% set sync hardware and software for the first TX
Event(EventIdx).seqControl =[Event(EventIdx).seqControl,SC.sync];
EventIdx = 1 + size(Event, 2); %   Verasonics increment

Event(EventIdx).info = 'Trigger out every loop';
Event(EventIdx).tx = 0;         % no transmit
Event(EventIdx).rcv = 0;        % no rcv
Event(EventIdx).recon = 0;      % no reconstruction
Event(EventIdx).process = 0;    % no process
Event(EventIdx).seqControl = SC.trigOut;
EventIdx = 1 + size(Event, 2); %   Verasonics increment

Event(EventIdx).info = 'Display beamformed IQ';
Event(EventIdx).tx = 0;         % no transmit
Event(EventIdx).rcv = 0;        % no rcv
Event(EventIdx).recon = 0;      % no reconstruction
Event(EventIdx).process = PN.display;    % process
Event(EventIdx).seqControl =  SC.returnToMatlab;% Necessary to be able to interact/freeze
EventIdx = 1 + size(Event, 2);

if UserParam.saveBF
    Event(EventIdx).info = 'save IQ Data Process';
    Event(EventIdx).tx = 0;         % no transmit
    Event(EventIdx).rcv = 0;        % no rcv
    Event(EventIdx).recon = 0;      % no reconstruction
    Event(EventIdx).process = PN.saveBFIQ;    % process
    Event(EventIdx).seqControl = SC.returnToMatlab;
    EventIdx = 1 + size(Event, 2);
end

Event(EventIdx).info = 'Filter SVD, compute Doppler and display';
Event(EventIdx).tx = 0;         % no transmit
Event(EventIdx).rcv = 0;        % no rcv
Event(EventIdx).recon = 0;      % no reconstruction
Event(EventIdx).process = PN.Dop;    % process
Event(EventIdx).seqControl = 0;
EventIdx = 1 + size(Event, 2);

if UserParam.saveDop
    Event(EventIdx).info = 'save Doppler';
    Event(EventIdx).tx = 0;         % no transmit
    Event(EventIdx).rcv = 0;        % no rcv
    Event(EventIdx).recon = 0;      % no reconstruction
    Event(EventIdx).process = PN.saveDop;    % process
    Event(EventIdx).seqControl = SC.returnToMatlab;
    EventIdx = 1 + size(Event, 2);
end

Event(EventIdx).info = 'Loop cnt Acq';
Event(EventIdx).tx = 0; % no transmit
Event(EventIdx).rcv = 0; % no rcv
Event(EventIdx).recon = 0; % no reconstruction
Event(EventIdx).process = PN.uiCntAcq; % process
Event(EventIdx).seqControl = 0;
EventIdx = EventIdx + 1;

if UserParam.NumLoops > 0
    
    if (UserParam.TimeBtwLoops~=0) && (UserParam.TimeBtwLoops<4.19)
        Event(EventIdx).info = 'Dummy transmit to set loop period';
        Event(EventIdx).tx = size(TX, 2); % This transmit is apod=0 was added at the end of the transmit structure
        Event(EventIdx).rcv = 0;
        Event(EventIdx).recon = 0;
        Event(EventIdx).process = 0;
        Event(EventIdx).seqControl = SC.timeBtwLoops;
        EventIdx = 1 + size(Event, 2); % Horrible Verasonics increment
    else
        if  (UserParam.TimeBtwLoops>=4.19)
            error('Your time between loops is too high you cant have this in hardware!');
        end
    end
    
    Event(EventIdx).info = 'loop everything';
    Event(EventIdx).tx = 0; % no transmit
    Event(EventIdx).rcv = 0; % no rcv
    Event(EventIdx).recon = 0; % no reconstruction
    Event(EventIdx).process = 0; % process
    Event(EventIdx).seqControl = SC.loopTstLoop;
    EventIdx = EventIdx + 1;
end

if UserParam.Live
    Event(EventIdx).info = 'Jump back to first event';
    Event(EventIdx).tx = 0;
    Event(EventIdx).rcv = 0;
    Event(EventIdx).recon = 0;
    Event(EventIdx).process = 0;
    Event(EventIdx).seqControl = SC.jumpLive;
    EventIdx = 1 + size(Event, 2); % Verasonics increment
end

if UserParam.InfiniteLoop == 1
    Event(EventIdx).info = 'Jump back to waiting for trigger';
    Event(EventIdx).tx = 0;
    Event(EventIdx).rcv = 0;
    Event(EventIdx).recon = 0;
    Event(EventIdx).process = 0;
    Event(EventIdx).seqControl = SC.bigJump;
    EventIdx = 1 + size(Event, 2); % Verasonics increment
end

%% Define UI objects
numFramesSvd = UserParam.NumFrames;
SVDINFO.start = UserParam.SVD(1);
SVDINFO.end = UserParam.SVD(end);
UIinfo.startsvd = 'UserC4';
UIinfo.endsvd = 'UserC3';
n_ui = 1;
UI(n_ui).Control = {UIinfo.startsvd, ...
                        'Style', 'VsSlider', ...
                        'Label', 'SVD start Cutoff', ...
                        'SliderMinMaxVal', [1, numFramesSvd, SVDINFO.start], ...
                        'SliderStep', [1 / numFramesSvd, 10 / numFramesSvd], ...
                        'ValueFormat', '%.0f', ...
                    };
UI(n_ui).Callback = {'svdCutoffSliderPW(hObject, eventdata)'};
n_ui = n_ui + 1;

UI(n_ui).Control = {UIinfo.endsvd, ...
                        'Style', 'VsSlider', ...
                        'Label', 'SVD end Cutoff', ...
                        'SliderMinMaxVal', [1, numFramesSvd, SVDINFO.end], ...
                        'SliderStep', [1 / numFramesSvd, 10 / numFramesSvd], ...
                        'ValueFormat', '%.0f', ...
                    };
UI(n_ui).Callback = {'svdCutoffSliderPW(hObject, eventdata)'};
n_ui = n_ui + 1;

UI(n_ui).Control = {'UserC1', ...
                        'Style', 'VsToggleButton', ...
                        'Label', 'Start Acq', ...
                    };
UI(n_ui).Callback = {'startAcq(hObject, eventdata)'};
n_ui = n_ui + 1;

% Save all the structures to a .mat file. & auto start
mkdir([UserParam.dataPathSave,filesep,'MatFiles']);
filename = [UserParam.dataPathSave ,'MatFiles\P7-4fUS'];
save(filename);

VSX
return