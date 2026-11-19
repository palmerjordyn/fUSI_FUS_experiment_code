function trigDisp
persistent firstTrig 
 if isempty(firstTrig)
disp('Waiting for first trigger')
    firstTrig = 1;

% pause(10)
%firstTrig = firstTrig+1;
elseif firstTrig == 1
pause(1)

disp('Waiting for main trigger')
end