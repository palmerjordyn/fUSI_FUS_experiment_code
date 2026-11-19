function Dop=VSX_computeDop(IData,QData)
%% A function to compute Doppler
% Created by Baptiste Heiles on 2025/01/16
% Last modified by Baptiste Heiles on 2025/03/28
%
% VSX_computeDop();

% Check workspace for UserParam and CParam
persistent firstRun timeInit timeToDisp timetoDispInit timetoDispAdj timetoDispInitAdj

if isempty(firstRun)
    firstRun = 0;
end
firstRun = firstRun+1;

if firstRun ~= 1
    timeToDisp = toc(timetoDispInit);
end
timetoDispInit = tic;

% if firstRun ~= 1
%     if timeToDisp < 1  
%         timeOffSet = 1-timeToDisp;
%         pause(timeOffSet)
%         disp('Delayed By:')
%         disp(timeOffSet)
%     end
% end
if firstRun ~= 1
    timetoDispAdj = toc(timetoDispInitAdj)
end
timetoDispInitAdj = tic;

% if firstRun ~= 1
%     timeToDisp = GetSecs-timeInit
% end
% timeInit = GetSecs;
% 
% if timeToDisp <1 
%  waitTime= (1-timeToDisp);
% WaitSecs(waitTime);
% end

if ~ evalin('base','exist("UserParam");')
    error(sprintf('     Error @VSX_computeDop : UserParam is undefined in base workspace'));
else
    UserParam=evalin('base','UserParam');
end

if ~evalin('base','exist("CParam");')
    error(sprintf('     Error @VSX_computeDop : CParam is undefined in base workspace'));
else
    CParam=evalin('base','CParam');
end

% Call SVDfilter function and execute
if size(IData,4)==CParam.NAngles.*UserParam.NumFrames
    BFIQ=compoundPW(complex(IData,QData),CParam.NAngles);
    BFIQSVD=SVDfilter(BFIQ,UserParam.SVD);
else
    BFIQSVD=SVDfilter(complex(IData,QData),UserParam.SVD);
end

Dop = mean(abs(BFIQSVD(:,:,:)).^2,3);
Dop = (Dop - min(Dop(:)))./range(Dop(:));

%% axis scaling
PP.sizez=CParam.PData.Size(1);PP.sizex=CParam.PData.Size(2);
    PP.zaxisMm = [1:PP.sizez].*CParam.PData.PDelta(3).*UserParam.CenterWavelength.*1e3;% axis in mm
    PP.xaxisMm = [1:PP.sizex].*CParam.PData.PDelta(1).*UserParam.CenterWavelength.*1e3;% axis in mm
    xaxisMm = [0 max(PP.xaxisMm)];
    yaxisMm = [0 max(PP.zaxisMm)];
    %%
    if UserParam.displayMode==2
        % Display if you need
        f=figure(490217);
        if isempty(f.Children)
            dopPlot = interp2(sqrt(Dop),2);
            disp(dopPlot(2,1))
            imagesc(xaxisMm, yaxisMm ,dopPlot);
            % imagesc(interp2(sqrt(Dop),2));
            %imagesc( xaxisMm, yaxisMm , interp2(sqrt(Dop),2));
            f.Color='white';title('Doppler');
            colormap hot(256);axis image;
            %caxis([0.05 0.95]);
            %clim([0.05 0.95]);

            ax=gca;
            title('Doppler')
            xlabel('mm')
            ylabel('mm')
            %         ax.Children.Interpolation='bilinear';

        else
            dopPlot = interp2(sqrt(Dop));
        ax=gca;
        ax.Children.CData=dopPlot;drawnow
        end
    end
end
