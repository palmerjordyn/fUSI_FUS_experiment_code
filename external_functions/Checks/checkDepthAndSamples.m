function [maxAcqLength,VSXMaxAcq,TheoreticalMaxRange,MaxRangeSample,varargout] = checkDepthAndSamples(UserParam,CParam,Trans)
%% Function created on 2025/01/15 by Baptiste Heiles
%
% This function will calculate variables maxAcqLength, MaxRangeSample and TheoreticalMaxRange
% Adapted to Doppler
% [maxAcqLength,VSXMaxAcq,TheoreticalMaxRange] =
% checkDepthAndSamples(UserParam,CParam,Trans);
%
% maxAcqLength : scalar, maximum size you need to do DAS beamforming of a
%   plane wave for a pixel situated at a distance from the piezos set by
%   range(UserParam.ImagingWindow)
%
% VSXMaxAcq: scalar, the closest high multiple of 128 of the number of
%   samples that Verasonics will record based on number of samples per wave
%   and the imaging depth you set in ImagingWindow. Corresponds to the
%   endSample-startSample set by Verasonics.
%
% TheoreticalMaxRange: scalar, based on VSXMaxAcq, this is the theoretical
%   ImagingWindow you could beamform. Up to you to max it or not.
%

%% Calculate maximum acquisition length needed to DAS beamform
% maxacqLength is the maximum size you need to do DAS beamforming of a
% plane wave for a pixel situated at a distance from the piezos set by
% range(UserParam.ImagingWindow) (so you have to
% calculate the maximum sample you will need to calculate the delay from
% the furthest element to that pixel)
ImagingLengthm = range(UserParam.ImagingWindow) ; % imaging length in m
maxAperture=Trans.spacingMm.*1E-3.*Trans.numelements;% Aperture max in m
maxDiagDAS= hypot(maxAperture, ImagingLengthm);% Maximum diagonal to beamform
maxDiagDASSeconds= maxDiagDAS.*2/UserParam.SpeedOfSound;% Maximum time to record
maxAcqLength =maxDiagDASSeconds.*(UserParam.SamplesPerWave.*UserParam.CenterFrequency); % maxAcqLength calculated the maximum length needed in multiples of SamplesPerWave.*wavelengths

%% Pre-calculate the receive samples Verasonics will decide (VSXMacAcq)
% Verasonics will only take a range of endDepth-startDepth that when converted to samples,
% is a multiple of 128. TheoreticalMaxRange will
% calculate the maximum range this multiple would allow you to beamform.
% That way, you know if you can increase your UserParam.ImagingWindow
% without Verasonics changing the endSample-startSample again!
VSXMaxAcq = ceil(maxAcqLength./128)*128; % in samples, this is what Verasonics considers as the end Sample
MaxRangeSample = (VSXMaxAcq./2)./(UserParam.SamplesPerWave); % in wavelength, the closest high multiple of 128 of the range in wavelength

%% Back-calculate the maximum range you could reach based on VSXMaxAcq
% If you assume the maximum delay you're going to have to fetch is the
% diagonal, tmax=2.*sqrt(z^2+x^2) and this should be smaller than
% VSXMaxAcq*c/decimSampleRate,
% c/decimSampleRate=c/(UserParam.SamplesPerWave.*UserParam.TransmitFrequency)
TheoreticalMaxRange = sqrt((VSXMaxAcq .* UserParam.SpeedOfSound / (2 .* UserParam.CenterFrequency .* UserParam.SamplesPerWave)) ^ 2 - (maxAperture .* 1E-3) .^ 2);
if ~isreal(TheoreticalMaxRange)% Verasonics maximum imaging depth would be smaller than your probe size
    % this is a weird case scenario but notify user
    %     fprintf('\n==============================================================================\n');
    %     fprintf('\n');
    %     fprintf(['The maximum imaging depth (%03.2f mm) from Verasonics will be smaller than probe size!'],(VSXMaxAcq .* UserParam.SpeedOfSound / (2 .* UserParam.TransmitFrequency .* UserParam.SamplesPerWave)).*1e3);
    %     fprintf('\n');
    %     fprintf('==============================================================================\n');
    TheoreticalMaxRange=NaN;
else
    
    switch sign(TheoreticalMaxRange - range(UserParam.ImagingWindow))
        case - 1
            msg=['Your imaging range is too high for DAS beamforming by : ', num2str(ceil((TheoreticalMaxRange - range(UserParam.ImagingWindow)) .* 1E3.*10)./10), ' mm'];
            msg=[msg,'\n      -> Decrease your imaging window \n'];
            printDebug(msg,UserParam.isDebug,'warning');
        case 1
            % You're good!
        case 0
            % Ahhh perfect imaging range!
    end
end

end

