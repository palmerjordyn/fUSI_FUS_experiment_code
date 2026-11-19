function saveIQDatafUS(IData,QData)
%% A function to save the beamformed IQ
% Created by Baptiste Heiles on 2025/01/16
% Last modified by Baptiste Heiles on 2025/03/28
%
% saveIQDatafUS(IData,QData);

    % Define persistent variables
    persistent loopCountIQ totalAcqTime dirSave;
    if isempty(loopCountIQ)
        loopCountIQ = 1;
        totalAcqTime = tic;
    end

    t1=tic;
    % Check output arguments in base workspace
    if ~ evalin('base','exist("UserParam");')
        error(sprintf('     Error @saveIQDatafUS : UserParam is undefined in base workspace'));
    else
        UserParam=evalin('base','UserParam');
    end

    % Grab UserParam and CParam
    if ~ evalin('base','exist("CParam");')
        error(sprintf('     Error @saveIQDatafUS : CParam is undefined in base workspace'));
    else
        CParam=evalin('base','CParam');
    end
    
    % Make sure CParam.startAcq is set to 1, otherwise dont save as you would
    % be in live mode
    if ~CParam.startAcq
        return
    end
    
%     if loopCountIQ == 1 && UserParam.Live == 0 
% 
%         UserParam.Live=0;CParam.startAcq=1;
%     end

    % Define directory and file names
    savePrefix=[UserParam.savePrefix,'_BF_'];
    dirSave=UserParam.dataPathSave;
    filenameBF = [savePrefix,sprintf('%.3d.bin', loopCountIQ)];% with a save_prefix variable
    filenameBF = fullfile(UserParam.dataPathSave, filenameBF);

    % Grab beamformed IQ
    if size(IData,4)==CParam.NAngles.*UserParam.NumFrames
        BFIQ=compoundPW(complex(IData,QData),CParam.NAngles);
    else
        BFIQ=complex(IData,QData);
    end

    % Save
    disp('saving IQ ...');
    fid = fopen(filenameBF,'w'); 
    fwritecomplex(fid,BFIQ, 'double');size(BFIQ);
    fclose(fid);
%     if toc(t1)<CParam.TimeOfAllFrames
%         disp(sprintf('saved in %03.3f s \n',toc(t1)));
%     else
%         disp(sprintf('saved in %03.3f s (warning >CParam.TimeOfAllFrames!)\n',toc(t1)));
%     end

    % Additional displays and save of timelog

% loopTime = toc
% tic

    disp(loopCountIQ)

    if loopCountIQ == (UserParam.NumLoops)
        T = toc(totalAcqTime); % absolute time (ms)
        D = datestr(now, 'HH-MM-SS.FFF'); % fUS image interval (s)
        fidresult = fopen([dirSave '\timeLog.txt'], 'a');
        fprintf(fidresult,'%s  %g\r\n', D, T);
        fclose(fidresult);
    end
  % assignin('base', 'UserParam', UserParam);

    loopCountIQ = loopCountIQ+1 ;
end

