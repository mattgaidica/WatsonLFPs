close all;
ff(1200,400);
plot(motiondata.motion,'k-');
hold on;

for ii = 1:length(WakeSleepTimePairFormat)
    xline(WakeSleepTimePairFormat{ii}(1,1),'g-','LineWidth',4);
    xline(WakeSleepTimePairFormat{ii}(1,2),'g:','LineWidth',4);
    xline(WakeSleepTimePairFormat{ii}(2,1),'r-','LineWidth',4);
    xline(WakeSleepTimePairFormat{ii}(2,2),'r-','LineWidth',4);
end
% 
% for ii = 1:size(MATimePairFormat,1)
%     xline(mean(MATimePairFormat(ii,1)),'b-','LineWidth',2);
%     xline(mean(MATimePairFormat(ii,2)),'b:','LineWidth',2);
% end

% for ii = 1:size(REMTimePairFormat,1)
%     xline(mean(REMTimePairFormat(ii,1)),'m-','LineWidth',2);
%     xline(mean(REMTimePairFormat(ii,2)),'m:','LineWidth',2);
% end
% 
% for ii = 1:size(SWSEpisodeTimePairFormat,1)
%     xline(mean(SWSEpisodeTimePairFormat(ii,1)),'c-','LineWidth',2);
%     xline(mean(SWSEpisodeTimePairFormat(ii,2)),'c:','LineWidth',2);
% end