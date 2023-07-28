basePath = '/Users/mattgaidica/Documents/MATLAB/WatsonLFPs/VoleData';
files = dir2(basePath,'*.mat');

% for squirrel-axy algorithm
senseParams = {};
senseParams.thresh = 0;
senseParams.w_kmeans = 0;
senseParams.w_temp = 0;
senseParams.w_tempGrad = 0;
senseParams.w_odba = 1;
senseParams.sm_tempGrad = 0;
senseParams.sm_odba = 1;
senseParams.fixTransitions = 0;
senseParams.offset_odba = 0;

nFilt = 60; % dynamic ODBA filter
windowSize = 5; % seconds
nEpisodes = 1000; % episodes per subject

actualStates = string;
predictedStates = string;
matchSum = 0; % running count of matched states
episodeCount = 0; % across all subjects
matchPerSubject = zeros(numel(files),1);

for iFile = 1:numel(files)
    fprintf("loading %s...\n",files(iFile).name);
    load(fullfile(basePath,files(iFile).name));
    % transform axy into 1Hz
    axy = double(downsample(Accel3D,SamplFreqHz));
    % apply ODBA filter
    odba = filtGetOdba(axy,nFilt);
    % set data we would have from squirrels to zeros
    temp = zeros(size(odba)); % rm
    nest = zeros(size(odba)); % rm
    % run squirrel algorithm
    [binNestSense,sense] = nestSenseAlg(temp,odba,nest,senseParams);

    % pluck random episodes from axy data, compare with squirrel algorithm
    oldMatchSum = matchSum;
    for iEpisode = 1:nEpisodes
        episodeCount = episodeCount + 1;
        startTime = randi([1,numel(odba)-windowSize]); % random
        tryRange = startTime:startTime+windowSize-1; % make into a range
        actualStates(episodeCount) = findVoleState(SleepScoringSeconds,tryRange); % classify
        % note: binNestSense is a sleep detector (1=sleep)
        if all(binNestSense(tryRange)==1)
            predictedStates(episodeCount) = "sleep";
        elseif all(binNestSense(tryRange)==0)
            predictedStates(episodeCount) = "wake";
        else % if binNestSense(tryRange) is a mixture of 1's and 0's
            predictedStates(episodeCount) = "transition";
        end
        % compare states based on sleep, wake, or transition to get
        % prediction accuracy (ie, matchSum is how often states match)
        if any(strcmp(actualStates(episodeCount),["nrem","rem"])) && strcmp(predictedStates(episodeCount),"sleep")
            matchSum = matchSum + 1;
        elseif any(strcmp(actualStates(episodeCount),["nwake","wake"])) && strcmp(predictedStates(episodeCount),"wake")
            matchSum = matchSum + 1;
        elseif strcmp(actualStates(episodeCount),"transition") && strcmp(predictedStates(episodeCount),"transition")
            matchSum = matchSum + 1;
        end % else do not increment
    end
    matchPerSubject(iFile,1) = (matchSum-oldMatchSum)/nEpisodes;
end

ff(600,300);
bar(matchPerSubject,'FaceColor','k');
ylabel('State Match Probability');
xlabel('Recording Session');
title('State Match Probability vs. Recording Session');
set(gca,'fontsize',14);
xticks(1:numel(files));
saveas(gcf,'stateMatchProbability_voles.jpg');

fprintf("state match: %i/%i = %1.2f%% (n=%i voles)\n",matchSum,episodeCount,100*matchSum/episodeCount,numel(files));
%%
close all;
ff(1200,700);
rows = 2;
cols = 3;

subplot(rows,cols,1:3);
plot(odba,'k-');
ylabel('3D-ODBA');

yyaxis right;
plot(-binNestSense,'r-','lineWidth',2);
% hold on;
% plot(-sense.nest,'color',[0,0,0,0.5],'LineStyle',':');
ylim([-1 2]);
xlabel('seconds');
legend({'3D-ODBA (vole)','Algorithm Prediction'});
set(gca,'ycolor','r');
yticks([-1 0]);
yticklabels({'sleep','wake'});
% ylabel('algorithm');
ylim([-4,2]);
xlim([1,numel(odba)]);
set(gca,'FontSize',14);
title("Example Episode (n=1 vole)");

subplot(rows,cols,4);
p = pie([matchSum/episodeCount,1-matchSum/episodeCount],'%.2f%%');
colors = magma;
p(1).FaceColor = colors(1,:,:);
p(3).FaceColor = colors(end,:,:);
title('Combined State Accuracy');
set(gca,'FontSize',14);
legend({'Correct','Incorrect'},'location','southoutside');

counts = [sum(strcmp(actualStates,"nrem")),sum(strcmp(actualStates,"rem")),sum(strcmp(actualStates,"wake")),...
    sum(strcmp(actualStates,"nwake")),sum(strcmp(actualStates,"transition"))] ./ episodeCount;
countLabels = {"NREM","REM","WAKE","NOISY WAKE","TRANSITION"};
subplot(rows,cols,5);
lc = lines(5);
colors = [lc(1,:);lc(1,:);lc(3,:);lc(3,:);lc(5,:)];
bar(counts,'FaceColor', 'flat', 'CData', colors);
xticks(1:numel(countLabels));
xticklabels(countLabels);
set(gca,'fontSize',14);
title(sprintf("Actual States\n%i episodes, %i subjects",episodeCount,numel(files)));
ylabel("Episode Probability");
% ylim([0,0.75]);
xtickangle(30);

counts = [sum(strcmp(predictedStates,"sleep")),sum(strcmp(predictedStates,"wake")),sum(strcmp(predictedStates,"transition"))] ./ nEpisodes;
countLabels = {"SLEEP","WAKE","TRANSITION"};
subplot(rows,cols,6);
colors = [lc(1,:);lc(3,:);lc(5,:)];
b = bar(counts,'FaceColor', 'flat', 'CData', colors);
xticks(1:numel(countLabels));
xticklabels(countLabels);
set(gca,'fontSize',14);
title(sprintf("Predicted States\n%i episodes, %i subjects",episodeCount,numel(files)));
ylabel("Episode Probability");
xtickangle(30);
% ylim([0,0.75]);
saveas(gcf,'voleAxyStates_allSessions.jpg');