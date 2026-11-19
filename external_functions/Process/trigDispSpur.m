function trigDispSpur()
persistent firstTrig 

 if isempty(firstTrig)
 disp('Waiting for spurious trigger')
    firstTrig = 1;
   % pause(1)

 elseif firstTrig == 1
 %disp('Waiting spurious trigger 2')
 %pause(1)
 end
end