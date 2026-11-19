function [TimeBtwTX, EstTimeBtwBis, EstTimeBtwVols, PRF] = checkTimesAndMemory(UserParam, CParam, Trans)
    %% Function created on 2025/01/15 by Baptiste Heiles
    % This function will calculate variables TimeBtwTX, EstTimeBtwBis, EstTimeBtwVols, MaxRangeSample and TheoreticalMaxRange
    %
    % [TimeBtwTX,EstTimeBtwBis,EstTimeBtwVols,PRF] = checkTimesAndMemory(UserParam,CParam,Trans)

    %% Calculate volume rates and  automatic time between transmits
    % Time it takes to record the whole startSample to endSample for VSX (overhead for added time)
    CParam.TimeBtwTX = UserParam.OverheadTime + CParam.VSXMaxAcq ./ UserParam.SamplesPerWave .* UserParam.CenterWavelength / UserParam.SpeedOfSound;
    
    switch UserParam.mode
        case {'2DPW_allSuperFrames'} % No super frames
            CParam.EstTimeBtwAccum= CParam.TimeBtwTX .* CParam.NAngles .* CParam.NTXPerAngle; % Time between the repeat of each frame for the accum
            CParam.EstTimeBtwFrames= CParam.EstTimeBtwAccum.*(UserParam.NAccum+1);% Time between each frame including all accum!
            CParam.PRF = 1 / (CParam.TimeBtwTX);
            CParam.TimeOfSuperFrame=UserParam.NumFramesinSuperFrame.*UserParam.TimeBtwFrames;% Time of a super frame
            CParam.TimeOfAllFrames=UserParam.NumFrames.*UserParam.TimeBtwFrames;% Time of a super frame
            
            % Compare user input to actual time
            if (CParam.EstTimeBtwFrames > UserParam.TimeBtwFrames) && (UserParam.NumFrames > 1) && UserParam.TimeBtwFrames ~= 0
                % Alert the user
                msg=sprintf('Increase time between frames to %03.4f ms\n', CParam.EstTimeBtwFrames .* 1E3);
                msg=[msg,'\n  Time between frames is too small. Increase or reduce number of accums '];
                printDebug(msg,UserParam.isDebug,'error');
            elseif UserParam.TimeBtwFrames == 0
                disp('You have no time between frames, you will go as fast as possible');
            end   

            % Precalculate a few times for the seqcontrols
            CParam.SCtimeBtwTX=CParam.TimeBtwTX;
            CParam.SCtimeBtwFrames=(UserParam.TimeBtwFrames-(CParam.EstTimeBtwFrames-CParam.SCtimeBtwTX));

            if CParam.SCtimeBtwFrames<0
                % Alert the user
                msg=sprintf('Increase time between frames to %03.4f ms\n', (CParam.EstTimeBtwFrames-CParam.SCtimeBtwTX) .* 1E3);
                msg=[msg,'\n  Time between frames is too small. Increase or reduce number of accums '];
                printDebug(msg,UserParam.isDebug,'error');
            end

            % For time between super frames, the input is assumed to be the time
            % between last frame of superframe i and first frame of loop i+1
            if UserParam.TimeBtwSuperFrames~=0
                CParam.SCtimeBtwSuperFrames=UserParam.TimeBtwSuperFrames;
            else
                CParam.SCtimeBtwSuperFrames=10.*1e-6;%10e-6 s but unused
            end

            % For time between loops, the input is assumed to be the time
            % between last frame of loop i and first frame of loop i+1
            if UserParam.TimeBtwLoops~=0
                CParam.SCtimeBtwLoops=UserParam.TimeBtwLoops;
            else
                CParam.SCtimeBtwLoops=10.*1e-6;%10e-6 s but unused
            end

    end

    %% Estimate time and memory consumption
    CParam.TimeBtwSave = CParam.TimeOfAllFrames+CParam.SCtimeBtwLoops;
    CParam.ncols = 128; % Receive on all channels, this is always the number of channels of the Verasonics
    CParam.NRcvBuffer = CParam.OffsetPerAngles .* CParam.NAngles ; % Number of receive buffers including the accum for NSSI/SSI
    CParam.rowsRcvBuffer = CParam.VSXMaxAcq * CParam.NRcvBuffer * UserParam.NumFramesinSuperFrame; % 1 is NRcvBuffer
    CParam.nMBPerSuperFrame = (CParam.rowsRcvBuffer * CParam.ncols * 2) / 2 ^ 20;
    CParam.nMBytesPerSec = CParam.nMBPerSuperFrame * 1 / (CParam.TimeBtwSave);
    
    if CParam.nMBytesPerSec > 6.E3
        fprintf('==============================================================================\n');
        fprintf('\n');
        fprintf('Warning! Estimated write speed is %03.4f GB/s \n \n', CParam.nMBytesPerSec ./ 1E3);
        fprintf('\n');
    end

    if CParam.nMBPerSuperFrame > 2 .* 1024

        fprintf('==============================================================================\n');
        fprintf('\n');
        fprintf('Estimated memory is %03.4f GB \n \n', CParam.nMBPerSuperFrame ./ 1024);
%         error(['Decrease size to less than 2GB']);
        fprintf('\n');
    end

    % All variables are useful so update CParam in base workspace
    assignin('base', 'CParam', CParam);

    if nargout > 1
        TimeBtwTx = CParam.TimeBtwTX;
        EstTimeBtwBis = CParam.EstTimeBtwBis;
        EstTimeBtwVols = CParam.EstTimeBtwVols;
        PRF = CParam.PRF;
    end

end
