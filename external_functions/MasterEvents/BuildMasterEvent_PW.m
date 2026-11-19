function [Event,SC,SeqControl]=BuildMasterEvent_PW(Event,UserParam,CParam,Trans,TX,SC,SeqControl,PN)
%% A function to build the Master Event in the case of PW for Doppler
% Created by Baptiste Heiles on 2024/07/18
% Last modified by Baptiste Heiles on 2024/07/18
%
% Master Events define all Events pertaining to the sequence you're
% writing.
% BuildMasterEvent_PW will build the ME to transmit angled plane
% waves on a linear array, and receive. After the first acquisition, the events
% are repeated for each frame in one superframe. The RF data is transferred to
% the host, if needed RF are saved, beamformed, and data is mark as processed.
% If needed, the SVD filter is computed and data is displayed. At the end,
% a sync is implemented when in live mode.
%
% [Event,UserParam,CParam,SC,SeqControl]=BuildMasterEvent_PW(Event,UserParam,CParam,Trans,TX,SC,SeqControl,PN);

i_TX = CParam.idx_TX; % Initialize TX
i_Rcv=CParam.idx_Rcv-1;% set the first i_Rcv based CParam (-1 since you're incrementing later)
EventIdx = 1+size(Event, 2); % Verasonics increment
nsc=SC.nsc;% Grab number of Seq Control

prec_str_ifr=['%0.',num2str(numel(num2str(UserParam.NumFramesinSuperFrame))),'i'];% precision values for info text
prec_str_isfr=['%0.',num2str(numel(num2str(UserParam.NumSuperFrames))),'i'];% precision values for info text

% Start building events
for iSuperFrame = 1:UserParam.NumSuperFrames
    for iFramePerSuperFrame = 1:UserParam.NumFramesinSuperFrame
        i_TX = CParam.idx_TX; % Reinitialize the number of TX at every frame because they are always the same
        i_Rcv = i_Rcv + 1; % Intialize the number of Rcv to be previous number +1 so that each frame has different receive

        for iAngle = 1:CParam.NAngles
            for iAccum = 0:(UserParam.NAccum)

                iTX=iAngle;
                iRcv=(UserParam.NAccum+1)*CParam.NAngles*(iSuperFrame-1)+(UserParam.NAccum+1)*(iAngle-1)+(iAccum+1);
                Event=BuildEventPW(Event,EventIdx,iTX,iRcv,iAccum,iAngle,SC.timeBtwAngles,Trans,UserParam,CParam);
                Event(EventIdx).info = sprintf([Event(EventIdx).info, ' (frame : ',prec_str_ifr,',superframe: ',prec_str_isfr,')'], iFramePerSuperFrame,iSuperFrame);
                EventIdx = 1 + size(Event, 2); %   Verasonics increment

            end
        end

        Event(EventIdx).info = sprintf('PW: Dummy transmit to set frame period after Frame number %i',iFramePerSuperFrame);
        Event(EventIdx).tx = size(TX, 2); % This transmit is apod=0 was added at the end of the transmit structure
        Event(EventIdx).rcv = 0;
        Event(EventIdx).recon = 0;
        Event(EventIdx).process = 0;
       % Event(EventIdx).seqControl = [SC.timeBtwFrames,SC.trigOut];
        Event(EventIdx).seqControl = [SC.timeBtwFrames];

        EventIdx = 1 + size(Event, 2); % Verasonics increment
    end


    % Set last acquisitions SeqControl for transferToHost.
    SeqControl(nsc).command = 'transferToHost'; % Transfer the data
    SC.(['transferToHost_', num2str(nsc - SC.returnToMatlab)])=nsc;% remove the last SC.nsc of the list which is returnToMatlab
    Event(EventIdx-1).seqControl =[Event(EventIdx-1).seqControl, SC.(['transferToHost_', num2str(nsc - SC.returnToMatlab)])]; % Transfer to host
    nsc = 1 + nsc;

    Event(EventIdx).info = 'Reconstruct';
    Event(EventIdx).tx = 0;        % no transmit
    Event(EventIdx).rcv = 0;       % no rcv
    Event(EventIdx).recon = iSuperFrame;     % reconstruction
    Event(EventIdx).process = 0;	% process is done in the compounding function
    Event(EventIdx).seqControl = 0;
    
    EventIdx = 1 + size(Event, 2); %   Verasonics increment

    if UserParam.checkTimeTags
        Event(EventIdx).info = 'Check time tags';
        Event(EventIdx).tx = 0;        % no transmit
        Event(EventIdx).rcv = 0;       % no rcv
        Event(EventIdx).recon = 0;     % reconstruction
        Event(EventIdx).process = PN.checkTT(iSuperFrame).*UserParam.checkTimeTags;	%  Check time tags
        Event(EventIdx).seqControl = 0;
        EventIdx = 1 + size(Event, 2); %   Verasonics increment
    end

    if UserParam.saveRF==1
        Event(EventIdx).info = 'save RF';
        Event(EventIdx).tx = 0;        % no transmit
        Event(EventIdx).rcv = 0;       % no rcv
        Event(EventIdx).recon = 0;     % reconstruction
        Event(EventIdx).process = PN.saveRF(iSuperFrame).*UserParam.saveRF;	% process is done in the compounding function
        Event(EventIdx).seqControl = 0;
        EventIdx = 1 + size(Event, 2); %   Verasonics increment
    end

end

% Write back the advanced SeqControl counter so that repeated calls to this
% function (e.g. an unrolled acquisition loop) allocate fresh, unique
% transferToHost SeqControl indices instead of overwriting earlier ones.
SC.nsc = nsc;
