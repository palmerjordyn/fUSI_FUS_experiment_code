function checkTimeTags(RFData)
% checkTimeTags will grab the first 2 elements of the RcvData, convert it
% into absolute time and add these values to 2 plots representing time
% drift and absolute time
%
% Function created by Baptiste Heiles on 2025/03/26

    % Grab UserParam from base space
    UserParam = evalin('base', 'UserParam');
    CParam=evalin('base','CParam');

    % Only calculate time tags if youre in start acq mode
    if ~CParam.startAcq
        return
    end

    % Convert time tags to seconds
    RFtt = RFData(1:2, 1);
    timeTags = double(reshape(RFtt, 2, [], 1));
    timeTagsSec = TimeTag2Sec(timeTags);

    % Create persistent values for ttCount and absolute time of start
    t1=tic;
    persistent loopCountTT;
    
    if isempty(loopCountTT)
        loopCountTT = 1;
    end
    persistent tStart; % Creates a Tstart value for 1st buffer
    
    % Initialize variables
    if loopCountTT == 1
        tStart = timeTagsSec;
    end
    
    if evalin('base', 'exist(''absTime'',''var'')')
        absTime = evalin('base', 'absTime');
    else
        absTime = 0;
    end
    
    if evalin('base', 'exist(''timeDrift'',''var'')')
        timeDrift = evalin('base', 'timeDrift');
    else
        timeDrift = 0;
    end
    
    % Add to variables
    absTime = [absTime timeTagsSec];
    ttDuration = diff(absTime(end - 1:end));% Duration between each call of checkTimeTags
    
    if loopCountTT == 1
        ttDuration = NaN;
    end
    
    assignin('base', 'absTime', absTime);
    assignin('base', 'timeDrift', timeDrift);

    % Uncomment this if you want to have time displayed but it can take a
    % long time for Matlab to display this
%     if (rem(loopCountTT,UserParam.NumSuperFrames) == 1)
%         % Then you're in the first superframe of the loop
%         timeDrift=[timeDrift ttDuration-CParam.SCtimeBtwLoops-UserParam.TimeBtwFrames];
%         if round(ttDuration.*1e6/25) > round(1e6/25*(CParam.SCtimeBtwLoops+UserParam.TimeBtwFrames))
%             fprintf('Loop: % 5i, time elapsed: % 7.3f s, measured time between loops: % 5.3f s\t\t  TOO SHORT LOOP by %5.3f \n     Increase time between loops', loopCountTT, timeTagsSec - tStart, ttDuration, ttDuration - CParam.SCtimeBtwLoops-UserParam.TimeBtwFrames);
%         else
%             fprintf('Loop: % 5i, time elapsed: % 7.3f s, measured time between loops: % 5.3f s\t\t  \n', loopCountTT, timeTagsSec - tStart, ttDuration);
%         end
%     
%     else
%         % Then you're in between superframes
%         timeDrift=[timeDrift ttDuration-UserParam.TimeBtwFrames];
%         if round(ttDuration.*1e6/25) > round(UserParam.TimeBtwFrames.*1e6/25)% rounding up to the 25 microsecond since its the precision of the Verasonics
%             fprintf('Superframe: % 5i, time elapsed: % 7.3f s, measured time between superframe: % 5.6f s\t\t  TOO SHORT Super Frame by %5.5f \n', loopCountTT, timeTagsSec - tStart, ttDuration, ttDuration - UserParam.TimeBtwFrames);
%         else
%             fprintf('Superframe: % 5i, time elapsed: % 7.3f s, measured time between superframe: % 5.6f s\t\t  \n', loopCountTT, timeTagsSec - tStart, ttDuration);
%         end
%     
%     end
%     
    
    f=figure(2130);f.Color='w';f.Name='Timetag check';f.Position(1)=100;
    subplot(2,1,1);hold on;plot(loopCountTT,timeTagsSec-tStart,'xk');ylabel('Time between superframes');
    subplot(2,1,2);hold on;plot(loopCountTT,timeDrift(end),'og');ylabel('Time drift')
    
    % update block counter
    loopCountTT = loopCountTT + 1;

end
