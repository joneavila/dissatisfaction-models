% prepareData.m
%% load feature spec
featureSpec = getfeaturespec('./source/mono.fss');

% for adding the time feature as the last column later
% timeFeatureNum = length(featureSpec) + 1;

% %% load precomputed dialog-level train data if found, else compute it
% disp('loading dialog-level data');
% tracklistTrainDialog = gettracklist('tracklists-dialog\train.tl');
% tracklistDevDialog = gettracklist('tracklists-dialog\dev.tl');
% tracklistTestDialog = gettracklist('tracklists-dialog\test.tl');
% 
% if useTimeFeature
%     dataDir = append(pwd, '\data\dialog-with-time'); 
% else
%     dataDir = append(pwd, '\data\dialog-without-time');
% end
% if ~exist(dataDir, 'dir')
%     mkdir(dataDir)
% end
% 
% % load precomupted train data, else compute it and save it for future runs
% filenamesTrainDialog = ["timesTrainDialog" "trackNumsTrainDialog" ...
%     "utterNumsTrainDialog" "XtrainDialog" "yTrainDialog"];
% loadedAll = true;
% for i = 1:length(filenamesTrainDialog)
%     saveFilename = append(dataDir, '\', filenamesTrainDialog(i), '.mat');
%     try
%         load(saveFilename);
%     catch
%         loadedAll = false;
%         break
%     end
% end
% if ~loadedAll
%     [XtrainDialog, yTrainDialog, trackNumsTrainDialog, timesTrainDialog, ...
%         utterNumsTrainDialog] = getXYfromTrackList(tracklistTrainDialog, ...
%         featureSpec);
%     
%     if useTimeFeature
%         % include timesDevFrame as a feature
%         XtrainDialog(:, timeFeatureNum) = seconds(timesTrainDialog);
%     end
%     
%     for i = 1:length(filenamesTrainDialog)
%         saveFilename = append(dataDir, '\', filenamesTrainDialog(i), '.mat');
%         save(saveFilename, filenamesTrainDialog(i));
%     end
% end
% 
% % load precomupted dev data, else compute it and save it for future runs
% filenamesDevDialog = ["timesDevDialog" "trackNumsDevDialog" ...
%     "utterNumsDevDialog" "XdevDialog" "yDevDialog"];
% loadedAll = true;
% for i = 1:length(filenamesDevDialog)
%     saveFilename = append(dataDir, '\', filenamesDevDialog(i), '.mat');
%     try
%         load(saveFilename);
%     catch
%         loadedAll = false;
%         break
%     end
% end
% if ~loadedAll
%     [XdevDialog, yDevDialog, trackNumsDevDialog, timesDevDialog, ...
%         utterNumsDevDialog] = getXYfromTrackList(tracklistDevDialog, ...
%         featureSpec);
%     
%     if useTimeFeature
%         % include timesDevFrame as a feature
%         XdevDialog(:, timeFeatureNum) = seconds(timesDevDialog);
%     end
%     
%     for i = 1:length(filenamesDevDialog)
%         saveFilename = append(dataDir, '\', filenamesDevDialog(i), '.mat');
%         save(saveFilename, filenamesDevDialog(i));
%     end
% end
% 
% % load precomupted test data, else compute it and save it for future runs
% filenamesTestDialog = ["timesTestDialog" "trackNumsTestDialog" ...
%     "utterNumsTestDialog" "XtestDialog" "yTestDialog"];
% loadedAll = true;
% for i = 1:length(filenamesTestDialog)
%     saveFilename = append(dataDir, '\', filenamesTestDialog(i), '.mat');
%     try
%         load(saveFilename);
%     catch
%         loadedAll = false;
%         break
%     end
% end
% if ~loadedAll
%     [XtestDialog, yTestDialog, trackNumsTestDialog, timesTestDialog, ...
%         utterNumsTestDialog] = getXYfromTrackList(tracklistTestDialog, ...
%         featureSpec);
%     
%     if useTimeFeature
%         % include timesTestFrame as a feature
%         XtestDialog(:, timeFeatureNum) = seconds(timesTestDialog);
%     end
%     
%     for i = 1:length(filenamesTestDialog)
%         saveFilename = append(dataDir, '\', filenamesTestDialog(i), '.mat');
%         save(saveFilename, filenamesTestDialog(i));
%     end
% end
% 
% if useTimeFeature
%     dataDir = append(pwd, '\data\monsters-with-time'); 
% else
%     dataDir = append(pwd, '\data\monsters-without-time');
% end
% if ~exist(dataDir, 'dir')
%     mkdir(dataDir)
% end
% 
% %  load precomupted dialog-level train data, else compute it and save it for future runs
% numTracks = length(tracklistTrainDialog);
% for trackNum = 1:numTracks
%     track = tracklistTrainDialog{trackNum};
%     fprintf('\t[%d/%d] %s\n', trackNum, numTracks, track.filename);
%     customerSide = 'l';
%     trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
%     [~, name, ~] = fileparts(track.filename);
%     saveFilename = append(dataDir, '\', name, '.mat');
%     try
%         monster = load(saveFilename);
%         monster = monster.monster;
%     catch
%         [~, monster] = makeTrackMonster(trackSpec, featureSpec);
%         if useTimeFeature
%             matchingTimes = [1:1:size(monster,1)]';
%             matchingTimes = arrayfun(@(frameNum) ...
%                 frameNumToTime(frameNum), matchingTimes);
%             monster(:,timeFeatureNum) = seconds(matchingTimes);
%         end
%         save(saveFilename, 'monster');
%     end
% end    
% 
% %  load precomupted dialog-level dev data, else compute it and save it for future runs
% numTracks = length(tracklistDevDialog);
% for trackNum = 1:numTracks
%     track = tracklistDevDialog{trackNum};
%     fprintf('\t[%d/%d] %s\n', trackNum, numTracks, track.filename);
%     customerSide = 'l';
%     trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
%     [~, name, ~] = fileparts(track.filename);
%     saveFilename = append(dataDir, '\', name, '.mat');
%     try
%         monster = load(saveFilename);
%         monster = monster.monster;
%     catch
%         [~, monster] = makeTrackMonster(trackSpec, featureSpec);
%         if useTimeFeature
%             matchingTimes = [1:1:size(monster,1)]';
%             matchingTimes = arrayfun(@(frameNum) ...
%                 frameNumToTime(frameNum), matchingTimes);
%             monster(:,timeFeatureNum) = seconds(matchingTimes);
%         end
%         save(saveFilename, 'monster');
%     end
% end 
% 
% % load precomupted dialog-level test data, else compute it and save it for future runs
% tracklistTestDialog = gettracklist('tracklists-dialog\test.tl');
% numTracks = length(tracklistTestDialog);
% for trackNum = 1:numTracks
%     track = tracklistTestDialog{trackNum};
%     fprintf('\t[%d/%d] %s\n', trackNum, numTracks, track.filename);
%     customerSide = 'l';
%     trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
%     [~, name, ~] = fileparts(track.filename);
%     saveFilename = append(dataDir, '\', name, '.mat');
%     try
%         monster = load(saveFilename);
%         monster = monster.monster;
%     catch
%         [~, monster] = makeTrackMonster(trackSpec, featureSpec);
%         if useTimeFeature
%             matchingTimes = [1:1:size(monster,1)]';
%             matchingTimes = arrayfun(@(frameNum) ...
%                 frameNumToTime(frameNum), matchingTimes);
%             monster(:,timeFeatureNum) = seconds(matchingTimes);
%         end
%         save(saveFilename, 'monster');
%     end
% end    
% 
% %% normalize dialog-level data
% % just to get the centering values and scaling values
% 
% % normalize train data
% [XtrainDialog, centeringValuesDialog, scalingValuesDialog] = ...
%     normalize(XtrainDialog);

%% clear unnecessary variables
% clear dataDir
% clear filenamesDevFrame filenamesTrainDialog filenamesTrainFrame
% clear i idxDissatisfied idxNeutral idxToDrop
% clear loadedAll
% clear numDifference numDissatisfied numNeutral
% clear saveFilename