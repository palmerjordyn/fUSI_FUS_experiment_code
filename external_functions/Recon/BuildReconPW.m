function Recon = BuildReconPW(Recon, ReconIdx,iSuperFrame, Trans, UserParam,CParam)
    % This function will build the Recon structure for PW.
    % Created by Baptiste Heiles on 2025/01/15
    % Last modified by Baptiste Heiles on 2025/01/15
    

    Recon(ReconIdx).senscutoff=0.8;
    Recon(ReconIdx).pdatanum=1;
    Recon(ReconIdx).rcvBufFrame=iSuperFrame;
    Recon(ReconIdx).IntBufDest=[1,1];
%     Recon(ReconIdx).ImgBufDest=[1,-1];% need an imgbufdest for the output after sum IQ
    Recon(ReconIdx).newFrameTimeout=UserParam.TimeBtwLoops; % needed for the software to wait for a new frame in the first rcv slot
    Recon(ReconIdx).RINums=(iSuperFrame-1)*CParam.NAngles+[1:CParam.NAngles];

end
