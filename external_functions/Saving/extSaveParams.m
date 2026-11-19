%% An external function to save a few parameters after VSX is launched
% Created by Baptiste Heiles on 2025/02/28
% Last modified by Carter Lybbert on 2026/09/16 with guard against nested
% save folders
function extSaveParams()
    persistent acqFolderCreated;
    if isempty(acqFolderCreated)
        UserParam = evalin('base','UserParam');
        UserParam.dataPathSave = [UserParam.dataPathSave, 'Acq_', datestr(now,'yyyy_mm_dd_HH_MM_ss'), '\'];
        mkdir(UserParam.dataPathSave);
        assignin('base', 'UserParam', UserParam);
        acqFolderCreated = true;
    end

    save_folder = evalin('base', 'UserParam.dataPathSave');
    saveParams(save_folder);
end