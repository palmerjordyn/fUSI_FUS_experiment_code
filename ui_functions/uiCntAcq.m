function uiCntAcq()
persistent loopCntAcq


UserParam=evalin('base','UserParam');
CParam=evalin('base','CParam');
if UserParam.Live && CParam.startAcq==0
    loopCntAcq=UserParam.NumLoops;
elseif ~UserParam.Live && CParam.startAcq==1
    loopCntAcq=loopCntAcq-1;
    

    if loopCntAcq==-1
        
        % Reinitialize dataPathSave value and put startAcq to 0 to cancel
        % saving
        idxStr=findstr(UserParam.dataPathSave,'\Acq_');
        UserParam.dataPathSave(idxStr+1:end)=[];
        UserParam.Live=1;CParam.startAcq=0;
% If you want to go back to live after acquiring simply uncomment this
        % Change jump loop event
%         Control = evalin('base','Control');
%         Control.Command = 'update&Run';
%         SeqControl=evalin('base','SeqControl');
%         SeqControl(evalin('base','SC.jumpLive')).command='jump';
%         SeqControl(evalin('base','SC.jumpLive')).argument=evalin('base','Resource.Parameters.startEvent');      
%         Control.Parameters = {'SeqControl'};
%         assignin('base','Control', Control);
%         assignin('base','SeqControl',SeqControl);% Needed to make sure Control executes correctly!

%         Change value of toggle button
        evalin('base','userControlApp.UiControlViews{3,1}.ButtonHandle.Value=0;');
        evalin('base',"userControlApp.UiControlViews{3,1}.ButtonHandle.String='Start Acq';");% Switch the text
        disp(sprintf('Done with acq, switching back to live mode'));
        
   end
end
assignin('base','UserParam',UserParam);
assignin('base','CParam',CParam);

