%% setup/init
load('TSurrogate');

senseParams = {};
senseParams.thresh = 0;
senseParams.w_kmeans = 0;
senseParams.w_temp = 0;
senseParams.w_tempGrad = 0;
senseParams.w_odba = 1;
senseParams.sm_tempGrad = 0;
senseParams.sm_odba = 1;
senseParams.fixTransitions = 0; %????
senseParams.offset_odba = 0;

%%
doPlot = false;
iSurr = 0;
allSurrResults = [];
for ii = 1:size(TSurrogate,1)
    odba = TSurrogate.filt_data{ii};
    temp = zeros(size(odba)); % rm
    nest = zeros(size(odba)); % rm
    [binNestSense,sense] = nestSenseAlg(temp,odba,nest,senseParams);

    segmentRange = TSurrogate.segment_range{ii};
    segmentClass = TSurrogate.segment_class{ii};
    
    for jj = 1:length(segmentClass)
        iSurr = iSurr + 1;
        thisRange = segmentRange(jj,:);
        % binNestSense is a SLEEP detector (1=sleep)
        if all(binNestSense(thisRange) == 1) && strcmp(segmentClass(jj),"sleep")
            allSurrResults(iSurr) = 1;
        elseif all(binNestSense(thisRange) == 0) && strcmp(segmentClass(jj),"wake")
            allSurrResults(iSurr) = 1;
        elseif strcmp(segmentClass(jj),"transition") % getting here implies binNestSense is 0's and 1's
            allSurrResults(iSurr) = 1;
        else
            allSurrResults(iSurr) = 0;
        end
        if doPlot
            close all;
            ff(1200,300);
            plot(odba,'k-');
            yyaxis right;
            plot(sense.nest,'b-');
            hold on;
            plot(binNestSense,'r-');
            ylim([-1,2]);
            yticks([0 1]);
            yticklabels({'wake','sleep'});
            xline(min(thisRange),'r--');
            xline(max(thisRange),'r--');
            title(allSurrResults(iSurr));
            hold on;
        end
    end
end
clc
fprintf("state match: %1.2f%% (n=%i surrogates across %i subjects)\n",100*sum(allSurrResults)/iSurr,iSurr,ii);

close all;
ff(400,450);
colors = magma;
p = pie([sum(allSurrResults)/iSurr,1-sum(allSurrResults)/iSurr],'%.2f%%');
p(1).FaceColor = colors(1,:,:);
p(3).FaceColor = colors(end,:,:);
title('Combined State Accuracy');
set(gca,'FontSize',14);
legend({'Correct','Incorrect'},'location','southoutside');
saveas(gcf,'combinedStateAccuracy.jpg');

%% detailed state analysis with sleep states
iSurr = 0;
predictedState = [];
actualState = [];
for ii = 1:size(TSurrogate,1)
    odba = TSurrogate.filt_data{ii};
    temp = zeros(size(odba)); % rm
    nest = zeros(size(odba)); % rm
    [binNestSense,sense] = nestSenseAlg(temp,odba,nest,senseParams);

    segmentRange = TSurrogate.segment_range{ii};
    segmentClass = TSurrogate.segment_class{ii};
    sleepClass = TSurrogate.sleep_class{ii};
    
    for jj = 1:length(segmentClass)
        iSurr = iSurr + 1;
        thisRange = segmentRange(jj,:);
        % binNestSense is a SLEEP detector (1=sleep)
        if all(binNestSense(thisRange) == 1)
            predictedState(iSurr) = 0; %sleep
        elseif all(binNestSense(thisRange) == 0)
            predictedState(iSurr) = 1; %wake
        else
            predictedState(iSurr) = 2; %transition
        end


        if strcmp(segmentClass(jj),"sleep")
            sleepId = find(ismember({'rem','sws','arousal','interruption'},sleepClass(jj)));
            if isempty(sleepId)
                error("empty sleep id!");
            else
                actualState(iSurr) = sleepId-1; % 0-3
            end
        elseif strcmp(segmentClass(jj),"wake")
            actualState(iSurr) = 4;
        else % strcmp(segmentClass(jj),"transition")
            actualState(iSurr) = 5;
        end
    end
end

corrMatrix = NaN(3,7); % rows(predict):sleep,wake,trans | cols(actual):sleep+[r,s,a,i],wake
predict_sleep = predictedState==0;
predict_wake = predictedState==1;
predict_trans = predictedState==2;
allPredictions = {predict_sleep,predict_wake,predict_trans};
allPredictions_labels = {'sleep','wake','transition'};

actual_sleep = ismember(actualState,0:3);
actual_rem = actualState==0;
actual_sws = actualState==1;
actual_arousal = actualState==2;
actual_interruption = actualState==3;
actual_wake = actualState==4;
actual_transition = actualState==5;
allActual = {actual_sleep,actual_rem,actual_sws,actual_arousal,actual_interruption,actual_wake,actual_transition};
allActual_labels = {'sleep','REM','SWS','arousal','interruption',...
    'wake','transition'};
fprintf("\n\n");
for ii = 1:numel(allPredictions)
    for jj = ii:numel(allActual)
        corrMatrix(ii,jj) = sum(allPredictions{ii} & allActual{jj}) ./ sum(allPredictions{ii});
        fprintf("predict %s x actual %s: %1.2f\n",allPredictions_labels{ii},allActual_labels{jj},corrMatrix(ii,jj));
    end
end

close all;
ff(1200,350);
rows = 1;
cols = 4;

subplot(rows,cols,1:2);
h = imagesc(corrMatrix);
alphaData = ones(size(corrMatrix));  % Initialize the AlphaData with 1 (fully opaque)
alphaData(isnan(corrMatrix)) = 0;
set(h, 'AlphaData', alphaData);
set(gca,'YDir','normal');
colormap(magma);
yticks(1:size(corrMatrix,1));
yticklabels({'sleep','wake','transition'});
xticks(1:size(corrMatrix,2));
xticklabels({'sleep','rem','sws','ar','int','wake','transition'});
xtickangle(60);
c = colorbar;
ylabel(c, 'Accuracy');
clim([0 1]);
title("Prediction vs. Actual");
p = get(gca,"Position");
set(gca,'Position',[p(1) p(2)+0.14 p(3)-.05 p(4)-0.28]);
set(gca,'FontSize',14);

subplot(rows,cols,3);
sumArray = zeros(1,3);
for ii = 1:numel(allPredictions)
    sumArray(ii) = sum(allPredictions{ii});
end
colors = [.2 .2 .2;0.4660 0.6740 0.1880;0.9290 0.6940 0.1250];
bar(1:numel(sumArray),sumArray./sum(sumArray),'FaceColor', 'flat', 'CData', colors);
xticklabels(allPredictions_labels);
ylabel('Fraction of Episodes');
title('Prediction');
xtickangle(60);
p = get(gca,"Position");
set(gca,'Position',[p(1) p(2)+0.14 p(3) p(4)-0.28]);
set(gca,'FontSize',14);
ylim([0 0.7]);


subplot(rows,cols,4);
sumArray = zeros(1,3);
for ii = 1:numel(allActual)
    sumArray(ii) = sum(allActual{ii});
end
colors = [.2 .2 .2;.5 .5 .5;.5 .5 .5;.5 .5 .5;.5 .5 .5;.4660 0.6740 0.1880;0.9290 0.6940 0.1250];
bar(1:numel(sumArray),sumArray./sum(sumArray),'FaceColor', 'flat', 'CData', colors);

xticklabels(allActual_labels);
ylabel('Fraction of Episodes');
title('Actual');
ylim([0 0.7]);
xtickangle(60);
p = get(gca,"Position");
set(gca,'Position',[p(1) p(2)+0.14 p(3) p(4)-0.28]);
set(gca,'FontSize',14);

saveas(gcf,'predictVsActualAccuracy.jpg');