function ReconInfo = BuildReconInfoPW(ReconInfo, ReconInfoIdx, iAngle,iSuperFrame,iPage, Trans, UserParam,CParam)
    % This function will build the ReconInfo structure for PW.
    % Created by Baptiste Heiles on 2025/01/15
    % Last modified by Baptiste Heiles on 2025/01/15
    

    ReconInfo(ReconInfoIdx).mode='replaceIQ';
    ReconInfo(ReconInfoIdx).txnum=iAngle;
    ReconInfo(ReconInfoIdx).rcvnum=(UserParam.NAccum+1)*CParam.NAngles*(iSuperFrame-1)+(UserParam.NAccum+1)*iAngle;
    ReconInfo(ReconInfoIdx).pagenum=iPage;
    ReconInfo(ReconInfoIdx).regionnum=1; % Assuming theres only one region
 
end
