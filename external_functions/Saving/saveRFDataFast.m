function saveRFDataFast(RFData)
%% A function to save RF data as bin
% Created by Baptiste Heiles on 2025/02/06
% Last modified by Baptiste Heiles on 2025/02/06
% For a more advanced version with time tags, ask author
% last modified by Carter Lybbert 2025/12/15

% Grab UserParam and CParam
UserParam = evalin('base', 'UserParam');
CParam = evalin('base', 'CParam');

% Make sure CParam.startAcq is set to 1, otherwise dont save as you would
% be in live mode
if ~CParam.startAcq
    return
end


t1=tic;
persistent loopCountRF;

if isempty(loopCountRF)
    loopCountRF = 1;
end

savePrefix=[UserParam.savePrefix,'_RF_'];

%     loopTime = toc
% tic
% fast save RF
filenameRF = [savePrefix,sprintf('%.3d.bin', loopCountRF)];% with a save_prefix variable
filenameRF = fullfile(UserParam.dataPathSave, filenameRF);
fid = fopen(filenameRF, 'w');
fwrite(fid, RFData, 'int16');
fclose(fid);
if toc(t1)<CParam.TimeOfAllFrames
    disp(sprintf('saved in %03.3f s \n',toc(t1)));
else
    disp(sprintf('saved in %03.3f s (warning > CParam.TimeOfAllFrames!)\n',toc(t1)));
end


% update loop counter
loopCountRF = loopCountRF + 1;

end
