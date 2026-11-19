function userChoice = IQSaver(IData,QData)

% Ask user whether to save
userChoice = input('Would you like to save the acquired image? (1 = Yes, 0 = No): ');

if isempty(userChoice) || userChoice == 0
    disp('User chose not to save. Exiting function.');
    return;   % Skip the entire function
elseif userChoice ~= 1
    disp('Invalid input. Exiting function.');
    return;
end

persistent loopCountIQ totalAcqTime DateTime;
if isempty(loopCountIQ)
    loopCountIQ = 1;
    totalAcqTime = tic;
end
t1=tic;

% Define directory and file names
savePrefix=['BMIQ_'];
dirSave='C:\Users\Administrator\Desktop\CarterfUSI\data\BMSave\';
cd('C:\Users\Administrator\Desktop\CarterfUSI\data\BMSave\')
if loopCountIQ == 1
DateTime = datestr(now, 'hh-MM-mm-dd-yy')
mkdir(DateTime)
end
cd(sprintf( '%s%s', dirSave,DateTime))

filenameBF = [savePrefix,sprintf('%.3d.mat', loopCountIQ)];% with a save_prefix variable
%     filenameBF = fullfile(UserParam.dataPathSave, filenameBF);

BFIQ=complex(IData,QData); % Grab beamformed IQ

% Save
disp('saving IQ ...');
save(filenameBF, 'IData', 'QData')
% fid = fopen(filenameBF,'w');
% fwritecomplex(fid,BFIQ, 'double');
% fclose(fid);
% disp(sprintf('saved in %03.3f s \n',toc(t1)));

% Additional displays and save of timelog
display(loopCountIQ)
    T = toc(totalAcqTime); % absolute time (ms)
    D = datestr(now, 'HH-MM-SS.FFF'); % fUS image interval (s)
    fidresult = fopen([dirSave '\timeLog.txt'], 'a');
    fprintf(fidresult,'%s  %g\r\n', D, T);
    fclose(fidresult);
loopCountIQ = loopCountIQ+1 ;
pause(1)
end

