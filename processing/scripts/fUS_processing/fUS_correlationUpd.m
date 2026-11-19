%% A script to look at functional correlation in fUS data
% Created by Baptiste Heiles on 2025/03/20
% Last modified by Baptiste Heiles on 2025/03/28: new version for custom
% scripts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Compute Doppler (if you saved BF data) %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%cd('C:\Users\Carter\Desktop\fUS-sequences')
addpath('C:\Users\Carter\Desktop\fUS-sequences\')
%addpath('E:\fUS2_scan\plane-1.9mm\')
addpath('C:\Users\Carter\Desktop\fUS-sequences\imaging_sequences\2D')
addpath('C:\Users\Carter\Desktop\fUS-sequences\processing\mat_exchange\freadcomplex')
addpath('D:\fUS Data\plane-1.9mm')
addpath(genpath('./external_functions'));
addpath(genpath('./ui_functions'));
addpath(genpath('./verasonics_utilities'));
addpath(genpath('../../processing/'));

%PP.pathToData='D:\fUS Data\Acq_2025_05_05_10_27_16';% Put the path to your data here
% PP.pathToData='D:\fUS Data\Acq_2025_05_05_11_27_07';
PP.pathToData='D:\fUS Data\Acq_2025_05_22_07_23_04';
%PP.pathToData='C:\Users\Carter\Desktop\fUS-sequences\fUS2_scan\plane-1.9mm';


%PP.pathToData='D:\fUS Data\plane-1.9mm';


%SeqParamPath=dir([PP.pathToData,filesep,'SequenceParam*']);
SeqParamPath=dir([PP.pathToData,filesep,'UF*']);

load([PP.pathToData,filesep,SeqParamPath(1).name]);
PP.fileName=UserParam.savePrefix;
PP.SVDval=[10,UserParam.NumFrames];
PP.sizez=CParam.PData.Size(1);PP.sizex=CParam.PData.Size(2);PP.sizey=CParam.PData.Size(3);
PP.sizefr=UserParam.NumFrames;% Size of the loaded array
Dop=zeros(PP.sizez,PP.sizex,PP.sizey,(UserParam.NumLoops+1));

for iAcq=1:(UserParam.NumLoops+1)
    Img=readBinFile([PP.pathToData, filesep,PP.fileName,'_BF_',num2str(iAcq,'%03.3d'),'.bin'],[PP.sizez,PP.sizex,PP.sizey],'complex');
    ImgFilt=SVDfilter(Img,PP.SVDval);% Remove tissue signal from data with SVD filter
    tmpDop=sqrt(mean(abs(ImgFilt).^2,4));% Compute Power Doppler
    Dop(:,:,:,iAcq)=(tmpDop-min(tmpDop(:)))./max(tmpDop(:));% Normalize
end
filenameDop=[PP.pathToData,'\Dop.bin'];
fid = fopen(filenameDop,'w');
fwrite(fid,Dop, 'double');
fclose(fid);
% To read, simply do Dop=readBinFile(filenameDop,size(Dop),'double');

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Analyze fUS  %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define parameters for post-processing
%PP.pathToData='D:\fUS Data\Acq_2025_05_05_10_27_16';% Put the path to your data here
% PP.pathToData='D:\fUS Data\Acq_2025_05_05_11_27_07';
PP.pathToData='D:\fUS Data\Acq_2025_05_22_07_23_04';

%PP.pathToData='D:\fUS Data\Acq_2025_05_22_07_23_04_1';

PP.zscore=2.58;% min z-score value for display
%PP.zscore=.1;% min z-score value for display
PP.isSmooth=0;% If you want to spatially smooth the data with a predefined filter
PP.isDisplay=1;% Activate display
PP.actPeriod=20+1;% number of Dop frames for activation (+1s to take into account for neurovascular coupling)
PP.restPeriod=20;% number of Dop frames for rest
PP.numAct=3;% Number of activations
PP.isCrop=0; % Cropping of the data

% Load parameters from data
SeqParamPath=dir([PP.pathToData,filesep,'SequenceParam*']);
load([PP.pathToData,filesep,SeqParamPath(1).name]);
PP.sizez=CParam.PData.Size(1);PP.sizex=CParam.PData.Size(2);PP.sizey=CParam.PData.Size(3);
PP.sizefr=UserParam.NumFrames;% Size of the loaded array
PP.zaxisMm=[1:PP.sizez].*CParam.PData.PDelta(3).*UserParam.CenterWavelength.*1e3;% axis in mm
PP.xaxisMm=[1:PP.sizex].*CParam.PData.PDelta(1).*UserParam.CenterWavelength.*1e3;% axis in mm
PP.yaxisMm=[1:PP.sizey].*CParam.PData.PDelta(2).*UserParam.CenterWavelength.*1e3;% axis in mm
PP.nDopFrames=(UserParam.NumLoops+1);
Dop=zeros(PP.sizez,PP.sizex,PP.sizey,PP.nDopFrames);

% Load Doppler matrix
Dop=readBinFile([PP.pathToData,'\Dop.bin'],size(Dop),'double');

% Do you only have 2D data? Then do this
Dop=squeeze(Dop);% Reduce singleton dimensionality

% In case you want to crop the data
if PP.isCrop
    f=figure;imagesc(power(Dop(:,:,1),0.5));
    colormap hot;axis image;f.Color='w';
    title(sprintf('Preview of the acquired Doppler data \n Please crop...'));
    rectDop=drawrectangle();
    PP.cropz=[floor(rectDop.Position(2)):(floor(rectDop.Position(2)+rectDop.Position(4)))];
    PP.cropx=[floor(rectDop.Position(1)):(floor(rectDop.Position(1)+rectDop.Position(3)))];
    DopCropped=Dop(PP.cropz,PP.cropx,:);
else
    PP.cropz=size(Dop,1);
    PP.cropx=size(Dop,2);
    DopCropped=Dop;
end
PP.zaxisMm=PP.cropz.*CParam.PData.PDelta(3).*UserParam.CenterWavelength.*1e3;% axis in mm
PP.xaxisMm=PP.cropx.*CParam.PData.PDelta(1).*UserParam.CenterWavelength.*1e3;% axis in mm

% Create stimulation pattern
PP.stimPattern=ones(1,PP.nDopFrames);
stimOn=[0:PP.numAct-1]'.*(PP.restPeriod+PP.actPeriod-1)+PP.restPeriod+[1:PP.actPeriod];
PP.stimPattern(stimOn(:))=-1;% PP.stimPattern on


% - Normalize of stimulation pattern
PP.stimPattern = PP.stimPattern-mean(PP.stimPattern);
PP.stimPattern = PP.stimPattern./sqrt(sum(PP.stimPattern.^2));
PP.stimPattern = reshape(PP.stimPattern,[1 1 length(PP.stimPattern)]);

% Optional spatial smoothing
if PP.isSmooth
     NSmooth = 2;
    % 
     for t = 1:size(DopCropped,3)
        DopFilt(:,:,t) = imfilter(DopCropped(:,:,t),ones(NSmooth,NSmooth)/NSmooth^2);
     end
else
    DopFilt=Dop;
end
 
% - Normalisation of Power Doppler signal
DopNorm = zeros(size(DopFilt));
tmp = DopFilt ;
tmp = mean(tmp,3);
tmp = bsxfun(@minus,DopFilt, tmp);
tmp = bsxfun(@rdivide,tmp, sqrt(sum(tmp.^2,3))); 
DopNorm = tmp;

% Compute activation map
CorrMatrix = bsxfun(@times,DopNorm,PP.stimPattern);
ActMap = sum(CorrMatrix,3);
ActMap(1,:) = 0;

if PP.isDisplay
    % First activation map and zscore significant
    f=figure(1)
    subplot(1,2,1)
    imagesc(PP.xaxisMm,PP.zaxisMm,ActMap);axis image
    caxis([0.1 0.5])
    colormap hot;f.Color='w';
    colorbar
    title('Activation map');
    region = roipoly;  
    figure(1)
    subplot(1,2,2)
    
    % Significant activation: value above which z-score > PP.zscore, OR the null hypothesis is rejected at 99% (p_value <0.01)
    
    threshedValues = PP.zscore*std(ActMap (:)) + mean(ActMap(:));
    clear interpDopNorm SuperimposedMap
    avgDop = squeeze(mean(DopCropped,3));

    % Interpolate data
    [X,Y] = meshgrid(1:size(DopCropped,2),1:size(DopCropped,1));
    stepX = size(DopCropped,2)/(size(ActMap,2)) ;
    stepY = size(DopCropped,1)/(size(ActMap,1)) ;
    [Xq,Yq] = meshgrid(stepX:stepX:size(DopCropped,2),stepY:stepY:size(DopCropped,1));
    interpDop = interp2(X,Y,avgDop,Xq,Yq);
    interpDopNorm = power(interpDop,1/2);

    % Add maps with transparency
    SuperimposedMap = ActMap;
    threshold = threshedValues;
    TransparencyMap = zeros(size(interpDopNorm));
    indices = SuperimposedMap > threshold; % Use threshold
    TransparencyMap(indices) = 1; % 1 for threshold
    
    % Display
    interpDopNorm = 1.5*interpDopNorm/max(interpDopNorm(:));
    imagesc(PP.xaxisMm,PP.zaxisMm,interpDopNorm(:,:,[1 1 1]) ); % make the first a grey-scale image with three channels so it will not be affected by the colormap later on
    hold on;
    ih = imagesc(PP.xaxisMm,PP.zaxisMm,SuperimposedMap);
    hold off
    set( ih, 'AlphaData', TransparencyMap);
    colormap hot;axis image;
    caxis([threshedValues 1])
    h_colBar = colorbar;
    h_colBar.Label.Rotation = 90;
    h_colBar.Label.String = 'correlation';
    title('Significant activation')

    % Plot temporal patterm
    f=figure(2);f.Color='w';
    region_time_course = bsxfun(@times,region,DopCropped);
    region_time_course_norm = squeeze(mean(mean(region_time_course,1),2)) ;
    mean_region = squeeze(mean(region_time_course_norm(1:30)));
    region_time_course_norm = region_time_course_norm - mean_region;
    region_time_course_final = region_time_course_norm./mean_region;

    plot(region_time_course_final,'Color',[0.6350 0.0780 0.1840])
    hold on
    plot(squeeze(PP.stimPattern)*2 + 0.1,'k');title('CBV ')
    % axis([0 length(PP.stimPattern) -0.05 0.6])
end

%% Additional function for SVD filter
function IQf = SVDfilter(IQ,cutoff)
%% function IQf = SVDfilter(IQ,cutoff)
% SVD of a n-dim matrix
% the temporal dimension has to be the last dimension

initsize = size(IQ);
if cutoff(end)>initsize(end)
    cutoff = cutoff(1):initsize(end);
end
if numel(cutoff)==1
    cutoff = cutoff(1):initsize(end);
elseif numel(cutoff)==2
    cutoff = cutoff(1):cutoff(2);
end
    
if or(isequal(cutoff,1:size(IQ,3)),cutoff(1)<2)
    IQf = IQ;
    return
end

X = reshape(IQ,prod(initsize(1:end-1)),initsize(end)); % Reshape into Casorati matric
[U,~] = svd(X'*X);% calculate svd of the autocorrelated Matrix
V = X*U;% Calculate the singular vectors.
Reconst = V(:,cutoff)*U(:,cutoff)'; % Singular value decomposition

IQf = reshape(Reconst,initsize); % Reconstruction of the final filtered matrix

end

