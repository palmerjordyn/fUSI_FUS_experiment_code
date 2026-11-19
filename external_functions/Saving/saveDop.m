function saveDop(Dop)
%% A function to save the fitltered Dop
% Created by Baptiste Heiles on 2025/03/28
% Last modified by Baptiste Heiles on 2025/03/28
%
% saveDop();
loopTime = toc
tic
    % Define persistent variables
    persistent loopCountDop totalAcqTime;
    if isempty(loopCountDop)
        loopCountDop = 1;
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
   

    % Define directory and file names
    savePrefix=[UserParam.savePrefix,'_Dop_'];
    dirSave=UserParam.dataPathSave;
    filenameDop = [savePrefix,sprintf('%.3d.bin', loopCountDop)];% with a save_prefix variable
    filenameDop = fullfile(UserParam.dataPathSave, filenameDop);

    % Save
    disp(sprintf('saving Doppler %03.0f...',loopCountDop));
    fid = fopen(filenameDop,'w'); 
    fwrite(fid,Dop, 'double');
    fclose(fid);
    if toc(t1)<CParam.TimeOfAllFrames
        disp(sprintf('saved in %03.3f s \n',toc(t1)));
    else
        disp(sprintf('saved in %03.3f s (warning >CParam.TimeOfAllFrames!)\n',toc(t1)));
    end

    % Additional displays and save of timelog
    display(loopCountDop)
    if loopCountDop == (1+UserParam.NumLoops)
        T = toc(totalAcqTime); % absolute time (ms)
        D = datestr(now, 'HH-MM-SS.FFF'); % fUS image interval (s)
        fidresult = fopen([dirSave '\timeLog.txt'], 'a');
        fprintf(fidresult,'%s  %g\r\n', D, T);
        fclose(fidresult);
    end
    loopCountDop = loopCountDop+1 ;
end

