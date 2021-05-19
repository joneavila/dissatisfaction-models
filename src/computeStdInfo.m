% standard deviation information for each feature

%% load all train data into one matrix Xtrain
fprintf('***loading training data to compute standard deviations\n');
Xtrain = [];
trackListTrain = gettracklist('train-dialog.tl');
numTracksTrain = length(trackListTrain);
featureSpec = getfeaturespec('.\mono-extended.fss');
for trackNum = 1:numTracksTrain
    track = trackListTrain{trackNum};
    trackFilename = track.filename;

    fprintf('[%2d/%d] %s\n', trackNum, numTracksTrain, trackFilename);
    
    % load the precomputed monster or compute it
    [~, name, ~] = fileparts(trackFilename);
    saveFilename = append(pwd, '\data\dialog-level-linear\', name, '.mat');
    try
        monster = load(saveFilename);
        monster = monster.monster;
    catch
        customerSide = 'l';
        trackSpec = makeTrackspec(customerSide, trackFilename, '.\calls\');
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        save(saveFilename, 'monster');
    end
    
    Xtrain = [Xtrain; monster];
end

clear monster name numTracks saveFilename track 
clear trackFilename trackListTrain trackNum

%% find the standard deviation of each feature
stdFeatures = std(Xtrain)';
meanFeatures = mean(Xtrain)';

% create a table by adding a column for feature names
featureAbbrevs = strings([length(featureSpec) 1]);
for featureNum = 1:length(featureAbbrevs)
    feature = featureSpec(featureNum);
    featureAbbrevs(featureNum) = feature.abbrev;
end
stdTable = table(stdFeatures, featureAbbrevs);

%% print out outlier frames in the dev data
fprintf('***loading dev data to print out outlier frames\n');
trackListDev = gettracklist('dev-dialog.tl');
for trackNum = 1:length(trackListDev)
    track = trackListDev{trackNum};
    fprintf('[%2d/%d] %s\n', trackNum, numTracksTrain, track.filename);
    
    % load the precomputed monster or compute it
    [~, name, ~] = fileparts(track.filename);
    saveFilename = append(pwd, '\data\dialog-level-linear\', name, '.mat');
    try
        monster = load(saveFilename);
        monster = monster.monster;
    catch
        customerSide = 'l';
        trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
        [~, monster] = makeTrackMonster(trackSpec, featureSpec);
        save(saveFilename, 'monster');
    end
    
    % for each feature, find all frames 'numStdsAway' standard deviations
    % away from the mean, stored as 'outlierFrames'
    numStdsAway = 6;
    maxDifferences = numStdsAway * stdFeatures;
    differences = abs(monster - meanFeatures');
    outlierFrames = differences > maxDifferences';
    
    for featureNum = 1:length(featureSpec)
        outlierFramesFeature = find(outlierFrames(:, featureNum));
        numOutlierFrames = length(outlierFramesFeature);
        
        % skip this feature if there are no outlier frames
        if numOutlierFrames == 0
            continue;
        end
        
        clipsDir = sprintf('%s\\dialog-level-clips\\%s', pwd, name);
        if ~exist(clipsDir, 'dir')
            % folder does not exist so create it
            mkdir(clipsDir);
        end

               
        lastFrameSeen = 1;
        segmentStart = -1;
        segmentEnd = -1;
        
        for i = 1:numOutlierFrames
            frameNum = outlierFramesFeature(i);

            if frameNum == lastFrameSeen+1 % continuining
                
                segmentEnd = frameNum;
            elseif segmentStart < 0  % start of new segment
                segmentStart = frameNum;
                segmentEnd = frameNum;
            else  % end of segment
                segmentEnd = frameNum;

                % create the clip
                % save it in the folder for this dialog
                [audioData, sampleRate] = audioread(track.filename);

                secondsStart = seconds(segmentStart / 100);
                secondsEnd = seconds(segmentEnd / 100);

                idxStart = round(seconds(secondsStart) * sampleRate);
                idxEnd = round(seconds(secondsEnd) * sampleRate);
                newFilename = sprintf('%s\\%.2fs-%.2fs-feat%02d-%s.wav', ...
                    clipsDir, seconds(secondsStart), ....
                    seconds(secondsEnd), featureNum, featureAbbrevs(featureNum));
                clipData = audioData(idxStart:idxEnd);
                audiowrite(newFilename, clipData, sampleRate);

                segmentStart = frameNum;
            end
            lastFrameSeen = frameNum;
        end
 
    end 
end  % line 140