function CParam=createCParam(UserParam, CParam)
%% Function created on 2025/01/14 by Baptiste Heiles
% This function will calculate parameters based on UserParam and store
% them in CParam  structure
%
% createCParam(UserParam,CParam)
% List of variables:
%
% CParam.NTXPerAngle        : scalar, number of transmit per angle without taking
%   into account accumulation
%
% CParam.OffsetPerAngles    ; scalar, offset to precisely offset
%   transmits/receives based on the mode
%
% CParam.NAllTXPerAngle     : scalar, number of transmit per angle including
%   accumulation


    %% Calculate TX, angles related variables  
    % NTXPerAngle is the number of transmit to make an angle without
    % accumulation
    switch UserParam.mode
        case {'2DPW_allSuperFrames'}
            CParam.NTXPerAngle=1;
    end
    
    % OffsetPerAngles allow to precisely offset transmits/receives based on the modes
    switch UserParam.mode
        case {'2DPW_allSuperFrames'}
            CParam.OffsetPerAngles=1;
    end
    CParam.NAngles=numel(UserParam.Angles);
    CParam.NAllTXPerAngle=CParam.NTXPerAngle*(1+UserParam.NAccum);% all tx per angle is the number of transmit per angle including accumulation repeats
    
    %% Create startAcq parameter. This parameter will be changed when you press startAcq and thus will activate saving
    CParam.startAcq=0;
    if UserParam.Live==0;CParam.startAcq=1;end % Activate start if not live
end