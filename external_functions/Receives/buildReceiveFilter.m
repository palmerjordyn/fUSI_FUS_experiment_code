function InputFilterCust=buildReceiveFilter(UserParam)
%% This function will create Receive filter for different probes based on given parameters
% Created by Baptiste Heiles on 2025/01/15

switch UserParam.ProbeName
    case 'L22-14vX' % Bandpass filter for L22-14vX
        if UserParam.TransmitFrequency==15.625.*1E6
            switch UserParam.ReceiveFilter
                case 'best'
                    InputFilterCust = [ -0.00162 +0.00000 +0.00568 +0.00000 -0.01065 +0.00000 +0.01349 ...
                        +0.00000 -0.00858 +0.00000 -0.00955 +0.00000 +0.04312 +0.00000 ...
                        -0.08841 +0.00000 +0.13550 +0.00000 -0.17130 +0.00000 +0.18463 ];
            end
        end
end