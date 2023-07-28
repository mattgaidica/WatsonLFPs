function states = findVoleState(SleepScoringSeconds,tryRange)


stateLabels = {"wake","nwake","nrem","rem"};
fields = fieldnames(SleepScoringSeconds);
for iField = 1:numel(fields)
    fieldName = fields{iField};
    fieldValue = SleepScoringSeconds.(fieldName);
    states = "transition"; % init/default
    for ii = 1:size(fieldValue,1)
        if tryRange(1) >= fieldValue(ii,1) &&...
                tryRange(end) < fieldValue(ii,2)
            states = stateLabels{iField};
            return ; % found it
        end
    end
end


