function Receive = BuildReceivePW(Receive, ReceiveIdx, iAngle, iAccum,iSuperFrame,iBuffer, Trans, UserParam,CParam)
    % This function will build the receive structure for PW. Accumulation will be implemented if needed
    % Created by Baptiste Heiles on 2025/01/15
    % Last modified by Baptiste Heiles on 2025/01/15
    
    % Build receive apod
    ApodRcv = ones(1, Trans.numelements);
    
    % Define a few constants
    if UserParam.isNXT == 1
         StartDepth = 2;
    else
    StartDepth = UserParam.ImagingWindow(1) ./ UserParam.CenterWavelength;
    end
    
    EndDepth = CParam.MaxRangeSample;
    Offsetacqnum = (iAngle - 1) ; % offset to increase acqnum based on the angles sequence

    % Receive structure for PW
    Receive(ReceiveIdx).mode = iAccum; % Create data if i_Accum==0, accumulate if i_Accum>1
    Receive(ReceiveIdx).Apod = ApodRcv; % Apodization
    Receive(ReceiveIdx).startDepth = StartDepth; % You have to change this
    Receive(ReceiveIdx).endDepth = EndDepth; % In wavelength!
    Receive(ReceiveIdx).TGC = 1; % This will get TGC profile number
    Receive(ReceiveIdx).bufnum = iBuffer; % This will transfer the data to buffer number bufNum in Resource.RcvBuffer
    Receive(ReceiveIdx).framenum = iSuperFrame; % This will transfer the data to frame number frameNum in Resource.RcvBuffer bufNum
    Receive(ReceiveIdx).acqNum = 1 + Offsetacqnum;

    switch UserParam.SamplesPerWave
        case 4
            Receive(ReceiveIdx).sampleMode = 'NS200BW'; % 200 %
        case 2
            Receive(ReceiveIdx).sampleMode = 'BS100BW'; % 100 
    end

    if ~isempty(UserParam.ReceiveFilter)
        try
            InputFilterCust=buildReceiveFilter(UserParam);
            Receive(ReceiveIdx).InputFilter = InputFilterCust;
        end
    end
end
