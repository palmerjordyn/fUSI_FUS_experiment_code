function svdCutoffSliderPW(hObject, event)
%% A function to set SVD values and slider in VSX gui
% Created by Baptiste Heiles on 2025/02/28
% Last modified by Baptiste Heiles on 2025/02/28

    gui_h = findobj('tag', 'UI');
    UIi = evalin('base', 'UIinfo');
    svdC_start_h = findobj(gui_h, 'Tag', [UIi.startsvd, 'Slider']);
    svdC_end_h = findobj(gui_h, 'Tag', [UIi.endsvd, 'Slider']);

    svdC_start_h.Value = round(svdC_start_h.Value);
    svdC_end_h.Value = round(svdC_end_h.Value);
    start_val = svdC_start_h.Value;
    end_val = svdC_end_h.Value;

    if hObject == svdC_start_h
        svdC_start_h.Value = min(start_val, end_val - 1);
    elseif hObject == svdC_end_h
        svdC_end_h.Value = max(start_val + 1, end_val);
    end

    lab_start_h = findobj(gui_h, 'Tag', [UIi.startsvd, 'Edit']);
    lab_end_h = findobj(gui_h, 'Tag', [UIi.endsvd, 'Edit']);
    lab_start_h.String = sprintf('%.0f', svdC_start_h.Value);
    lab_end_h.String = sprintf('%.0f', svdC_end_h.Value);

    UserParam=evalin('base','UserParam');
    UserParam.SVD = [ceil(start_val),round(end_val)];
    assignin('base', 'UserParam', UserParam);
%     evalin('base','feval(Process(PN.SVD).method);');
end
