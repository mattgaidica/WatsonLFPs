basePath = '/Users/mattgaidica/Documents/MATLAB/WatsonLFPs/CRCNS/fcx-1/data';
% WakeSleepTimePairFormat Paired periods of WAKE (7+min) followed immediately by SLEEP (20+ min)
periEventSec = 7*60;

transStrings = {'sleepToWake', 'wakeToSleep'};
% table variables
trans_string = string;
subject = string;
trans_type = [];
motion_data = {};
filt_data = {};
sleep_wake_ratio = [];
mid_sample = [];
iEntry = 0;

% this is messy code but it just needs to produce and write the table
files = dir(basePath);
for ii = 1:length(files)
    if files(ii).isdir && strcmp(files(ii).name,'.') == 0 && strcmp(files(ii).name,'..') == 0
        fprintf("%s\n",files(ii).name);
        load(fullfile(basePath,files(ii).name,[files(ii).name,'_Motion.mat']));
        warning('off', 'all');
        load(fullfile(basePath,files(ii).name,[files(ii).name,'_WSRestrictedIntervals.mat']));
        warning('on', 'all');

        for jj = 1:length(WakeSleepTimePairFormat)
            swArr = WakeSleepTimePairFormat{jj};
            % test for enough time sleepToWake
            if swArr(1,1) > periEventSec
                thisTrans = 1; % 1 or 2
                iEntry = iEntry + 1;
                trans_type(iEntry,1) = thisTrans;
                trans_string(iEntry,1) = string(transStrings{thisTrans});
                unfiltData = double(motiondata.motion(swArr(1,1)-periEventSec+1:swArr(1,1)+periEventSec));
                motion_data(iEntry,1) = {unfiltData};
                filtData = sqrt((unfiltData - movmean(unfiltData,60)).^2);
                midPoint = round(numel(filtData)/2);
                filt_data(iEntry,1) = {filtData};
                mid_sample(iEntry,1) = swArr(1,1);
                subject(iEntry,1) = files(ii).name;
                if thisTrans == 1
                    sleepMean = mean(filtData(1:midPoint));
                    wakeMean = mean(filtData(midPoint:end));
                else
                    wakeMean = mean(filtData(1:midPoint));
                    sleepMean = mean(filtData(midPoint:end));
                end
                sleep_wake_ratio(iEntry,1) = sleepMean/wakeMean;
            end
            % capture the known wakeToSleep
            thisTrans = 2;
            iEntry = iEntry + 1;
            trans_type(iEntry,1) = thisTrans;
            trans_string(iEntry,1) = string(transStrings{thisTrans});
            unfiltData = double(motiondata.motion(swArr(1,2)-periEventSec+1:swArr(1,2)+periEventSec));
            motion_data(iEntry,1) = {unfiltData};
            filtData = sqrt((unfiltData - movmean(unfiltData,60)).^2);
            midPoint = round(numel(filtData)/2);
            filt_data(iEntry,1) = {filtData};
            mid_sample(iEntry,1) = swArr(1,2);
            subject(iEntry,1) = files(ii).name;
            if thisTrans == 1
                sleepMean = mean(filtData(1:midPoint));
                wakeMean = mean(filtData(midPoint:end));
            else
                wakeMean = mean(filtData(1:midPoint));
                sleepMean = mean(filtData(midPoint:end));
            end
            sleep_wake_ratio(iEntry,1) = sleepMean/wakeMean;
        end
    end
end
TTransition = table(subject,motion_data,filt_data,sleep_wake_ratio,trans_type,trans_string,mid_sample);
% writetable(TT,'transitionTable');
save('TTransition','TTransition');

%%
ratioThresh = 0.5;
close all;
ff(900,600);
titleString = {"Sleep to Wake","Wake to Sleep"};

for ii = 1:2
    subplot(2,1,ii);
    useIds = find(TT.trans_type == ii & TT.sleep_wake_ratio < ratioThresh);
    combinedData = cell2mat(TT.filt_data(useIds));
    t = (1:length(combinedData)) - round(length(combinedData)/2);
    errorbar(t,mean(combinedData),std(combinedData));
    xlim([min(t),max(t)]);
    yline(0,'k-');
    xline(0,'r-');
    title(sprintf("%s (n=%i) - thresh = %1.2f",titleString{ii},numel(useIds),ratioThresh));
    set(gca,'fontsize',14);
end
saveas(gcf,sprintf("goodTrialsOverview_t%1.2f.jpg",ratioThresh));

%%
savePath = '/Users/mattgaidica/Documents/MATLAB/WatsonLFPs/export';
for ii = 1:size(TT,1)
    theseData = TT.motion_data{ii};
    filtData = sqrt((theseData - movmean(theseData,60)).^2);
    ff(1200,400);
    plot(filtData,'k-');
    xlim(size(theseData));
    midPoint = round(numel(theseData)/2);
    xline(midPoint,'r-');
    grid on;
    if TT.trans_type(ii) == 1
        sleepMean = mean(filtData(1:midPoint));
        wakeMean = mean(filtData(midPoint:end));
    else
        wakeMean = mean(filtData(1:midPoint));
        sleepMean = mean(filtData(midPoint:end));
    end
    title(sprintf("%s - sleep/wake = %2.1f",TT.subject(ii),sleepMean/wakeMean),'Interpreter','none');
    saveas(gcf,fullfile(savePath,TT.subject(ii)+".jpg"));
    close(gcf);
end