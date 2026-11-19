function saveParams(save_folder)
%% This function will save useful parameters of the sequence for beamforming after execution of the sequence
% Created by Baptiste Heiles on 27/10/2022
% saveParam(save_folder); will save UserParam, Cparam, VSXParam in a single
% matrix called 'SequenceParams.mat' in the directory defined by
% save_folder
disp(sprintf('Saving params...\n'));


UserParam=evalin('base','UserParam');
CParam=evalin('base','CParam');
Trans=evalin('base','Trans');
TW=evalin('base','TW');
if evalin('base','~exist(''VSXParam'')')
    VSXParam.decimSampleRate=evalin('base','Receive(1).decimSampleRate');
    VSXParam.endSample=evalin('base','Receive(1).endSample');
    VSXParam.demodFrequency=evalin('base','Receive(1).demodFrequency');
    for i_TW=1:size(TW,2)
        VSXParam.TWpeak(i_TW)=TW(i_TW).peak;
        VSXParam.TXFreq(i_TW)=TW(i_TW).Parameters(1).*1E6;
    end
else
    VSXParam=evalin('base','VSXParam');
end
assignin('base','VSXParam',VSXParam);

time = datestr(now, 'yyyy_mm_dd_hh_MM_ss');
save_filename = sprintf('SequenceParam_%s',time);
save([save_folder,'/',save_filename,'.mat'],'UserParam','CParam','VSXParam','Trans');