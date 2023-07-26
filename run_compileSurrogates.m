% compile ns segments
basePath = '/Users/mattgaidica/Documents/MATLAB/WatsonLFPs/CRCNS/fcx-1/data';
% table: full motion data, n=100 segments, labels for each segment
% 1)pick random time point 2)test for known state 3)include/exclude->save

nSurr = 100;
timeWindow = 120; % seconds
ratioThresh = 0.5;
% TT = readtable("transitionTable.txt");
load('TTransition');

files = dir(basePath);
motion_data = {};
filt_data = {};
segment_range = {};
segment_class = {};
sleep_class = {};
subject = string;
tableRow = 0;
for ii = 1:length(files)
    TTids = find(strcmp(TTransition.subject,files(ii).name));
    sleepWakeRatio = mean(TTransition.sleep_wake_ratio(TTids));
    if sleepWakeRatio < ratioThresh && files(ii).isdir && strcmp(files(ii).name,'.') == 0 && strcmp(files(ii).name,'..') == 0
        fprintf("%s\n",files(ii).name);
        load(fullfile(basePath,files(ii).name,[files(ii).name,'_Motion.mat']));
        warning('off', 'all');
        load(fullfile(basePath,files(ii).name,[files(ii).name,'_WSRestrictedIntervals.mat']));
        warning('on', 'all');

        % for WakeSleep periods only
        sleepRange = [];
        wakeRange = [];
        for jj = 1:length(WakeSleepTimePairFormat)
            sleepRange = [sleepRange,WakeSleepTimePairFormat{jj}(1,1):WakeSleepTimePairFormat{jj}(1,2)];
            wakeRange = [wakeRange,WakeSleepTimePairFormat{jj}(2,1):WakeSleepTimePairFormat{jj}(2,2)];
        end
        allWakeSleepRange = unique([sleepRange,wakeRange]);

        % for other types of sleep
        remRange = [];
        for jj = 1:height(REMTimePairFormat)
            remRange = [remRange,REMTimePairFormat(jj,1):REMTimePairFormat(jj,2)];
        end
        swsRange = [];
        for jj = 1:height(SWSPacketTimePairFormat)
            swsRange = [swsRange,SWSPacketTimePairFormat(jj,1):SWSPacketTimePairFormat(jj,2)];
        end
        wakeRange = [];
        for jj = 1:height(WakeTimePairFormat)
            wakeRange = [wakeRange,WakeTimePairFormat(jj,1):WakeTimePairFormat(jj,2)];
        end
        sleepRange = [];
        for jj = 1:height(SleepTimePairFormat)
            sleepRange = [sleepRange,SleepTimePairFormat(jj,1):SleepTimePairFormat(jj,2)];
        end
        maRange = [];
        for jj = 1:height(MATimePairFormat)
            maRange = [maRange,MATimePairFormat(jj,1):MATimePairFormat(jj,2)];
        end
        interruptRange = [];
        for jj = 1:height(WakeInterruptionTimePairFormat)
            interruptRange = [interruptRange,WakeInterruptionTimePairFormat(jj,1):WakeInterruptionTimePairFormat(jj,2)];
        end
        
        % rangeCell = {sleepRange,wakeRange,remRange,swsRange,maRange,interruptRange};
        % colors = lines(numel(rangeCell));
        % ff(1200,300);
        % plot(motiondata.motion,'k-');
        % yyaxis right;
        % for jj = 1:numel(rangeCell)
        %     for kk = 1:numel(rangeCell{jj})
        %         plot(rangeCell{jj}(kk),jj*.2,'.','color',colors(jj,:),'markerSize',50);
        %         hold on;
        %     end
        % end
        % ylim([0,numel(rangeCell)*.2+.2]);

        iSurr = 0;
        this_range = zeros(nSurr,timeWindow);
        this_class = string;
        this_sleep_class = string;
        while iSurr < nSurr
            tryTime = randi([min(allWakeSleepRange),max(allWakeSleepRange)-timeWindow]);
            tryRange = tryTime:tryTime+timeWindow-1;
            % is the whole range classified as sleep or wake?
            if all(ismember(tryRange,allWakeSleepRange))
                iSurr = iSurr + 1;
                this_range(iSurr,:) = tryRange;
                this_sleep_class(iSurr) = ""; % init
                if all(ismember(tryRange,sleepRange))
                    this_class(iSurr) = "sleep";
                    remCount = sum(ismember(tryRange,remRange));
                    swsCount = sum(ismember(tryRange,swsRange));
                    maCount = sum(ismember(tryRange,maRange));
                    intCount = sum(ismember(tryRange,interruptRange));
                    [v,k] = max([remCount,swsCount,maCount,intCount]);
                    if v == 0
                        this_sleep_class(iSurr) = "unclassified";
                    else
                        switch k
                            case 1
                                this_sleep_class(iSurr) = "rem";
                            case 2
                                this_sleep_class(iSurr) = "sws";
                            case 3
                                this_sleep_class(iSurr) = "arousal";
                            case 4
                                this_sleep_class(iSurr) = "interruption";
                            otherwise
                                this_sleep_class(iSurr) = "error";
                        end
                    end
                elseif all(ismember(tryRange,wakeRange))
                    this_class(iSurr) = "wake";
                else
                    this_class(iSurr) = "transition";
                end
            end
        end
        % everything is built by now
        tableRow = tableRow + 1;
        subject(tableRow,1) = string(files(ii).name);
        motion_data(tableRow,1) = {double(motiondata.motion)};
        % fixed at 60s
        filt_data(tableRow,1) = {double(sqrt((motiondata.motion - movmean(motiondata.motion,60)).^2))};
        segment_range{tableRow,1} = this_range;
        segment_class{tableRow,1} = this_class;
        sleep_class{tableRow,1} = this_sleep_class;
    end
end
TSurrogate = table(subject,motion_data,filt_data,segment_range,segment_class,sleep_class);
save('TSurrogate','TSurrogate');
% writetable(TSurrogate,'surrogateTable', 'Delimiter', ',');