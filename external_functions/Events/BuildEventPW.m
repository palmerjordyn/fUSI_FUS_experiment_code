function Event=BuildEventPW(Event,EventIdx,iTX,iRcv,iAccum,iAngle,iSC,Trans,UserParam,CParam)
    % This function will build the Event structure for PW. The event will be PW,
    % and will be modified whether we are implementing accumulation or not.
    % Created by Baptiste Heiles on 2025/01/17
    % Last modified by Baptiste Heiles on 2025/01/17
    % Event: Event structure to be built
    % EventIdx: Event index number
    % i_TX: transmit event index
    % i_Rcv: Receive event index
    % i_Accum: 0 if you are in the first set of events for the accum, 1 otherwise
    % i_SC: sequence control index
    % Trans: Transducer structure according to Verasonics
    % UserParam: User parameters as a structure
        
            % Build event info
            if iAccum==0
                Event(EventIdx).info = ['PW: Transmit PW, angle ', num2str(iAngle,'%0.2i')];
            else
               Event(EventIdx).info = ['PW: Transmit accum PW, angle ', num2str(iAngle,'%0.2i')];
           end
            Event(EventIdx).tx=iTX;
            Event(EventIdx).rcv=iRcv;
            Event(EventIdx).recon=0;% Do not reconstruct
            Event(EventIdx).process=0;% Do not process
            Event(EventIdx).seqControl=iSC;% Time between acquisitions
    end