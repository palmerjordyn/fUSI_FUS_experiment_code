function [TX,CParam]=BuildTransmitPW(TX,TransmitIdx,iAngle,Trans,UserParam,CParam)
% This function will build the transmit structure for PW. Accumulation will be implemented if needed
    % Created by Baptiste Heiles on 2025/01/15
    % Last modified by Baptiste Heiles on 2025/01/15:

        % Transmit in OPW
        TX(TransmitIdx).waveform=1;
        TX(TransmitIdx).Origin=zeros(1,3);
        TX(TransmitIdx).Apod=calculateApodPW(UserParam.Apod,Trans.numelements);
        TX(TransmitIdx).focus=0.0;
        TX(TransmitIdx).Steer(1)=UserParam.Angles(iAngle).*pi/180;% azimuth angle
        TX(TransmitIdx).Steer(2)=0;% elevation angle
        TX(TransmitIdx).Delay=computeTXDelays(TX(TransmitIdx));
        
end