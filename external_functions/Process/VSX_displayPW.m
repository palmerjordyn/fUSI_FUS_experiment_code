function VSX_displayPW(IData,QData)
%% A function to display PW beamformed data
% Created by Baptiste Heiles on 2025/01/16
% Last modified by Baptiste Heiles on 2025/01/16
%
% VSX_displayPW();

% Check workspace for UserParam and CParam
if ~ evalin('base','exist("UserParam");')
    error(sprintf('     Error @VSX_displayPW : UserParam is undefined in base workspace'));
else
    UserParam=evalin('base','UserParam');
end

if ~evalin('base','exist("CParam");')
    error(sprintf('     Error @VSX_displayPW : CParam is undefined in base workspace'));
else
    CParam=evalin('base','CParam');
end

% Call compoundPW function and execute
if size(IData,4)==CParam.NAngles.*UserParam.NumFrames
    BFIQ=compoundPW(complex(IData,QData),CParam.NAngles);
else
    BFIQ=complex(IData,QData);
end

logBFIQ=20*log10(abs(BFIQ(:,:,1))./max(abs(BFIQ(:))));

%% axis scaling
PP.sizez=CParam.PData.Size(1);PP.sizex=CParam.PData.Size(2);
PP.zaxisMm = [1:PP.sizez].*CParam.PData.PDelta(3).*UserParam.CenterWavelength.*1e3;% axis in mm
PP.xaxisMm = [1:PP.sizex].*CParam.PData.PDelta(1).*UserParam.CenterWavelength.*1e3;% axis in mm
xaxisMm = [0 max(PP.xaxisMm)];
yaxisMm = [0 max(PP.zaxisMm)];
%%
if UserParam.displayMode==1
    % Display if you need
    f=figure(490217);
    %hold on

    if isempty(f.Children)
        f.Color='white';
        imagesc(xaxisMm,yaxisMm, logBFIQ);
        colormap bone;axis image;
        ax=gca;clim([-80 0]);
        xlabel('mm')
        ylabel('mm')
        title('B-Mode')
    else
        ax=gca;
        ax.Children.CData=logBFIQ;drawnow
    end

end
end
