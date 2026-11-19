%% A script to look at functional correlation in fUS data
% Created by Baptiste Heiles on 2025/03/20
% Last modified by Baptiste Heiles on 2025/03/28: new version for custom
% scripts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%mn 
%%%%%% Compute Doppler (if you saved BF data) %%%%%% for each individual frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
close all

addpath(genpath('C:\Users\Administrator\Desktop\CarterfUSI\'))
addpath(genpath('./external_functions'));
addpath(genpath('./ui_functions'));
addpath(genpath('./verasonics_utilities'));
addpath(genpath('../../processing/'));
addpath('C:\Users\Administrator\Desktop\CarterfUSI\data\Acq_2025_12_11_13_58_14\')
PP.pathToData='C:\Users\Administrator\Desktop\CarterfUSI\data\Acq_2025_12_11_13_58_14';

%establish size of your array for analysis
SeqParamPath=dir([PP.pathToData,filesep,'SequenceParam*']);
load([PP.pathToData,filesep,SeqParamPath(1).name]);
PP.fileName=UserParam.savePrefix;
PP.SVDval=[10,UserParam.NumFrames]; % why 10 for the SVD cutoff value? This is a cutoff to filter out tissue movement. May be experimentally determined.

PP.sizez=CParam.PData.Size(1);PP.sizex=CParam.PData.Size(2);% Size of the loaded array
PP.sizey=CParam.PData.Size(3);% Needed for Vantage NXT. Might become a backwards compatibility issue. Look for "Number of elements must not change" error in readBinFile
PP.sizefr=UserParam.NumFrames;% Size of the loaded array
Dop=zeros(PP.sizez,PP.sizex,PP.sizey,(UserParam.NumLoops+1));% Initialize size of Dop array

%calculate a fUS image for each loop of the doppler
for iAcq=1:(UserParam.NumLoops+1)
    Img=readBinFile(fullfile([PP.pathToData, filesep,PP.fileName,'_BF_',num2str(iAcq,'%03.3d'),'.bin']),[PP.sizez,PP.sizex,PP.sizey,PP.sizefr],'complex');
    ImgFilt=SVDfilter(Img,PP.SVDval);% Remove tissue signal from data with SVD filter. IMG is IQ data.
    tmpDop=sqrt(mean(abs(ImgFilt).^2,4)); % Compute Power Doppler
    % take absolute value of complex, which eliminates complex component by caculating the complex magnitude. Square each element, take mean of each element across the
    % 200 frames collected, then take the square root of each element. This
    % is the power doppler calculation
    Dop(:,:,iAcq)=(tmpDop-min(tmpDop(:)))./max(tmpDop(:));% Normalize by the minimum and maximum
end
% dop file saves the power doppler data of each frame
filenameDop=[PP.pathToData,'Dop.bin'];
fid = fopen(filenameDop,'w');
cd(PP.pathToData)
fwrite(fid,Dop, 'double');
fclose(fid);
% To read, simply do Dop=readBinFile(filenameDop,size(Dop),'double');

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Analyze fUS  %%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define parameters for post-processing
clear all
close all
PP.pathToData='C:\Users\Administrator\Desktop\CarterfUSI\data\Acq_2025_12_08_10_52_31';

    PP.zscore=2.58;% min z-score value for display
    %PP.zscore=1.65 ;% min z-score value for display 1.65 correstponds to a p
    PP.isSmooth=1;% If you want to spatially smooth the data with a predefined filter
    PP.isDisplay=1;% Activate display
    PP.actPeriod=20+1;% number of Dop frames for activation (+1s to take into account for neurovascular coupling)
    PP.restPeriod=20;% number of Dop frames for rest
    PP.numAct=3;% Number of activations
    PP.isCrop=0;% Cropping of the data
    stimFirst = 1;

    % Load parameters from data
    SeqParamPath=dir([PP.pathToData,filesep,'SequenceParam*']);
    load([PP.pathToData,filesep,SeqParamPath(1).name]);
    PP.sizez=CParam.PData.Size(1);PP.sizex=CParam.PData.Size(2);
    PP.sizey=UserParam.NumLoops+1;% Size of the loaded array
    PP.zaxisMm = [1:PP.sizez].*CParam.PData.PDelta(3).*UserParam.CenterWavelength.*1e3;% axis in mm
    PP.xaxisMm = [1:PP.sizex].*CParam.PData.PDelta(1).*UserParam.CenterWavelength.*1e3;% axis in mm
    xaxisMm = max(PP.xaxisMm);
    yaxisMm = max(PP.zaxisMm);
    PP.nDopFrames=PP.sizey;

    % Load Doppler matrix
    Dop=zeros(PP.sizez,PP.sizex,PP.sizey);
    Dop=readBinFile([PP.pathToData,'\Dop.bin'],size(Dop),'double');

    % In case you want to crop the data
    if PP.isCrop
        f=figure;
        imagesc(power(Dop(:,:,1),0.5));
        colormap hot;axis image;
        f.Color='w';
        title(sprintf('Preview of the acquired Doppler data \n Please crop...'));
        rectDop=drawrectangle();
        PP.cropz=[floor(rectDop.Position(2)):(floor(rectDop.Position(2)+rectDop.Position(4)))];
        PP.cropx=[floor(rectDop.Position(1)):(floor(rectDop.Position(1)+rectDop.Position(3)))];
        DopCropped=Dop(PP.cropz,PP.cropx,:);
    else % if you don't crop, the whole image is selected
        PP.cropz=size(Dop,1);
        PP.cropx=size(Dop,2);
        DopCropped=Dop;
    end
    PP.zaxisMm=PP.cropz.*CParam.PData.PDelta(3).*UserParam.CenterWavelength.*1e3;% axis in mm
    PP.zaxisMm = [0 PP.zaxisMm];
    PP.xaxisMm=PP.cropx.*CParam.PData.PDelta(1).*UserParam.CenterWavelength.*1e3;% axis in mm
    PP.xaxisMm = [0 PP.xaxisMm];

    % Create binary stimulation pattern (-1 or 1)
    PP.stimPattern=-ones(1,PP.nDopFrames);
    stimOn=[0:PP.numAct-1]'.*(PP.restPeriod+PP.actPeriod-1)+PP.restPeriod+[1:PP.actPeriod];
    PP.stimPattern(stimOn(:))=1;% PP.stimPattern on

    %- Normalize of stimulation pattern.
    PP.stimPattern = reshape(PP.stimPattern,[1 1 length(PP.stimPattern)])
    for i = 1:length(PP.stimPattern)
        tmp(i) = (PP.stimPattern(i) - mean(PP.stimPattern))./std(PP.stimPattern,1); % z score normalization
    end
    PP.stimPattern = tmp;

    if stimFirst == 1 % invert stimulation pattern if stimulation occured first vs baseline first
        PP.stimPattern = PP.stimPattern*-1;
    end

  %  %remove outliers
  %     frameMean = mean(mean(DopCropped,1),2);
  %   frameMean = squeeze(frameMean);
  % DopOutlierIdx = find(isoutlier(frameMean, 'quartiles')>0);
  % while (DopOutlierIdx)
  %   frameMean = mean(mean(DopCropped,1),2);
  %   frameMean = squeeze(frameMean);
  %   DopOutlierIdx = find(isoutlier(frameMean, 'quartiles')>0);
  % 
  %   DopMedian = median(DopCropped,3);
  %   for i  = 1:length(DopOutlierIdx)
  %       DopCropped(:,:,DopOutlierIdx(i)) = DopMedian;
  %       disp('Frame removed due to movement artifact')
  %   end
  %  DopOutlierIdx = find(isoutlier(frameMean, 'quartiles')>0);
  % end

    % frameMean2 = mean(mean(DopCropped,1),2);
    % frameMean2 = squeeze(frameMean2);
    % DopOutlierIdx2 = find(isoutlier(frameMean2, 'quartiles')>0);
    % 
    % DopMedian = median(DopCropped,3);
    % for i  = 1:length(DopOutlierIdx2)
    %     DopCropped(:,:,DopOutlierIdx2(i)) = DopMedian;
    %     disp('Frame removed due to movement artifact')
    % end

    % Optional spatial smoothing
    DopFilt = zeros(height(DopCropped(:,:,1)),width(DopCropped(:,:,1)));
    if PP.isSmooth
        NSmooth = 2;
        for t = 1:size(DopCropped,3)
            DopFilt(:,:,t) = imfilter(DopCropped(:,:,t),ones(NSmooth,NSmooth)/NSmooth^2);
        end
    else
        DopFilt=DopCropped;
    end

    % z score normalization
    tic
    dopMean = mean(DopFilt,3,'omitnan');
    dopSub = (DopFilt-dopMean).^2;
    dopSum = sum(dopSub,3);
    stdDop = (dopSum./(size(DopFilt,3))).^0.5;
    dopNorm = zeros(size(DopFilt));
    for iii = 1:size(dopNorm,3)
        dopNorm = (DopFilt - mean(DopFilt,3, 'omitnan'))./stdDop; %
    end
    toc

    % Compute activation map
    stimMat = zeros(size(dopNorm));
    ActMap = zeros(size(dopNorm,1),size(dopNorm,2));
    for i = 1:size(dopNorm,3)
        stimMat(:,:,i) = PP.stimPattern(i);
    end

    for i = 1:size(dopNorm,1)
        for ii = 1:size(dopNorm,2)
            tmp = corrcoef(dopNorm(i,ii,:),stimMat(i,ii,:));
            ActMap(i,ii) = tmp(1,2);
        end
    end

    if PP.isDisplay
        % First activation map and zscore significant
        f=figure(1);
        subplot(1,2,1)
        imagesc(PP.xaxisMm,PP.zaxisMm,ActMap);
        axis image
        xlabel('mm')
        ylabel('mm')
        clim([0 1]) % scaling of correlation coefficient
        colormap hot;f.Color='w';
        colorbar
        title('Activation Map');
        h_colBar = colorbar;
        h_colBar.Label.Rotation = 90;
        h_colBar.Label.String = 'Correlation (r)';
        region = roipoly;
        figure(1)
        subplot(1,2,2)

        % Significant activation: value above which z-score > PP.zscore, OR the null hypothesis is rejected at 99% (p_value <0.01)
        thresholdValues = PP.zscore*std(ActMap (:), 'omitnan') + mean(ActMap(:), 'omitnan'); % convert z score to raw score.
        clear interpDopNorm SuperimposedMap
        avgDop = squeeze(mean(DopCropped,3)); % average across all superframes

        % Interpolate data. This seems to have no impact on data. interpDop == avgDop
        [X,Y] = meshgrid(1:size(DopCropped,2),1:size(DopCropped,1));
        stepX = size(DopCropped,2)/(size(ActMap,2)) ;
        stepY = size(DopCropped,1)/(size(ActMap,1)) ;
        [Xq,Yq] = meshgrid(stepX:stepX:size(DopCropped,2),stepY:stepY:size(DopCropped,1));
        interpDop = interp2(X,Y,avgDop,Xq,Yq);
        interpDopNorm = interpDop.^.5; % square root
        interpDopNorm = avgDop.^.5; % square root

        % Add maps with transparency
        SuperimposedMap = ActMap;
        threshold = thresholdValues;
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
        colormap hot;
        axis image;
        clim([0 1]) % scaling of correlation coefficient
        h_colBar = colorbar;
        h_colBar.Label.Rotation = 90;
        h_colBar.Label.String = 'Correlation (r)';
        title('Significant Activation')
        xlabel('mm')
        ylabel('mm')

        % Plot temporal pattern
        f=figure(2);
        f.Color='w';

        % this is relative cerebral blood volume calculation. Other than taking the mean across the ROI, the rest basically is just scaling the data and changing units?
        region_time_course = region.*DopCropped; % region is your selected region of interest. Region is a binary matrix with 1s where you selected to ROI. DopCropped is the full matrix.multiplication zeros areas beyond selected ROI.
        region_time_course_norm = squeeze(mean(mean(region_time_course,1),2)); % create average of the doppler power in across the whole region of interest for each superframe
        mean_region = squeeze(mean(region_time_course_norm(1:30))); % take the mean across all superframes

        region_time_course_norm = region_time_course_norm - mean_region; % subtract the mean from each time course superframe
        region_time_course_final = region_time_course_norm./mean_region; % divide the normalized mean doppler by the mean doppler taken across all superframes
        region_time_course_final = movmean(region_time_course_final,3);
        stimPat = squeeze(PP.stimPattern);

        plot(region_time_course_final,'Color',[0.6350 0.0780 0.1840])

        hold on
        plot(stimPat,'k');
        title('Cerebral Blood Volume in Region of Interest ')
        xlabel('Time (s)')
        ylabel('Cerebral Blood Volume (A.U.)')
    end

    [R P] = corrcoef(region_time_course_final,stimPat);

    % Average over all sessions and plot
    totalAcq = PP.numAct .*(PP.restPeriod*2);
    expLeng = PP.restPeriod*2;
    dataCollectStim = zeros(PP.numAct,PP.restPeriod);
    dataCollectCont = zeros(PP.numAct,PP.restPeriod);

    ii=1;
    for i = 1:expLeng:(totalAcq)
        dataCollectStim(ii,:) = region_time_course_final(i:(i+PP.restPeriod-1));
        dataCollectCont(ii,:) = region_time_course_final((i+PP.restPeriod+1):(i+(PP.restPeriod*2)));
        ii = ii+1;
    end

    stimMean = mean(dataCollectStim,1);
    stimSEM = sem(dataCollectStim);
    contMean = mean(dataCollectCont,1);
    contSEM = sem(dataCollectCont);

    t = (0:1:expLeng/2-1);

    h = figure;
    hold on;
    shadedErrorBar(t, contMean,contSEM, 'lineprops','b')
    shadedErrorBar(t, stimMean,stimSEM,'lineprops','r' )
    legend('Lights Off','Lights On')
    xlabel('Time (s)')
    ylabel('Cerebral Blood Volume (A.U.)')
    makeFigureBig(h);

    stimMean = mean(dataCollectStim,2);
    contMean = mean(dataCollectCont,2);

    [H P ] = ttest( contMean,stimMean)


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

X = reshape(IQ,prod(initsize(1:end-1)),initsize(end)); % Reshape into Casorati matrix
[U,~] = svd(X'*X);% calculate svd of the autocorrelated Matrix
V = X*U;% Calculate the singular vectors.
Reconst = V(:,cutoff)*U(:,cutoff)'; % Singular value decomposition
IQf = reshape(Reconst,initsize); % Reconstruction of the final filtered matrix

end

