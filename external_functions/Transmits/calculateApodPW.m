function ApodList = calculateApodPW(mode,NElements)
% This function will calculate the apodization for a number of elements
% for a sound-sheet. It creates the variable apodlist that only
% concerns the left transmit!
% Created by Baptiste Heiles on 2025/01/15
% Last modified by Baptiste Heiles on 2025/01/15

%% Calculate one part of the apodization based on the mode
switch mode
    case 'none'
        ApodList = ones(1, NElements);
    case 'tukey'
        ApodList = tukeywin(NElements, 0.5)';
    case 'tukey025'
        ApodList = tukeywin(NElements, 0.25)';
    case 'hamming'
        ApodList = hamming(NElements)';
    case 'kaiser'
        ApodList = kaiser(NElements)';
end

end