function dispBlockTime()
%% A function to display block time
% Created by Baptiste Heiles on 2025/01/16
% Last modified by Baptiste Heiles on 2025/01/16
%
% dispBlockTime();

persistent timeBlock;

% Check output arguments in base workspace
if ~ evalin('base','exist("UserParam");')
    error(sprintf('     Error @dispBlockTime : UserParam is undefined in base workspace'));
else
    UserParam=evalin('base','UserParam');
end

% Define directory and file names
dirSave=UserParam.dataPathSave;

if isempty(timeBlock)
    timeBlock = tic;
end
T = toc(timeBlock) % absolute time (ms)
D = datestr(now, 'HH-MM-SS.FFF'); % fUS image interval (s)
fidresult = fopen([dirSave '\timeLog.txt'], 'a');
fprintf(fidresult,'%s  %g\r\n', D, T);
fclose(fidresult);
end