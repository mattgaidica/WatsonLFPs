keepFiles = {'WSRestrictedIntervals','EMGCorr','Motion','.tar.gz'};

basePath = '/Users/mattgaidica/Documents/MATLAB/WatsonLFPs/CRCNS/fcx-1/data';
files = dir2(basePath,'-r');
for ii = 1:length(files)
    if ~contains(files(ii).name, keepFiles) && ~files(ii).isdir
        fprintf("delete %s\n",files(ii).name);
        delete(fullfile(basePath,files(ii).name));
    end
end