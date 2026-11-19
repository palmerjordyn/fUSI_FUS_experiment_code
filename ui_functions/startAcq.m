function startAcq(hObject, event)
    % function to start the acquision. It will change the UserParam value
    % live to 0 and activate saving.
    % Created by B. 
    
    % Grab from workspace
    UserParam=evalin('base','UserParam');
    CParam=evalin('base','CParam');

    % Activate based on toggle button value
    if get(hObject,'Value')==1
        set(hObject,'String','Acquiring...');% Switch the text
        disp(sprintf('Starting acquisition...'));
        
        % Get UserParam and create dataPathSave -- moved to saveDop
        UserParam.dataPathSave=[UserParam.dataPathSave,'\Acq_',datestr(now,'YYYY_mm_DD_HH_MM_ss'),'\'];
        mkdir(UserParam.dataPathSave);
        UserParam.Live=0;CParam.startAcq=1;

        % Change jump loop event
        Control(1) = evalin('base','Control');
        Control(1).Command = 'update&Run';
        SeqControl=evalin('base','SeqControl');
        SeqControl(evalin('base','SC.jumpLive')).command='stop';
        SeqControl(evalin('base','SC.jumpLive')).argument=[];      
        Control(1).Parameters = {'SeqControl'};
        
    else
        set(hObject,'String','Start Acq');% Switch the text
        
        % Reinitialize dataPathSave value and put startAcq to 0 to cancel
        % saving
        idxStr=findstr(UserParam.dataPathSave,'\Acq_');
        UserParam.dataPathSave(idxStr+1:end)=[];
        UserParam.Live=1;CParam.startAcq=0;

        % Change jump loop event
        Control = evalin('base','Control');
        Control.Command = 'update&Run';
        SeqControl=evalin('base','SeqControl');
        SeqControl(evalin('base','SC.jumpLive')).command='jump';
        SeqControl(evalin('base','SC.jumpLive')).argument=evalin('base','Resource.Parameters.startEvent');      
        Control.Parameters = {'SeqControl'};%,'argument',[]};
       
    end
    assignin('base', 'UserParam', UserParam);
    assignin('base', 'CParam', CParam);
    assignin('base','SeqControl',SeqControl);% Needed to make sure Control executes correctly!
    assignin('base','Control', Control);
end
