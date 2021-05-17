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
numTracksDev = length(trackListDev);
for trackNum = 1:numTracksDev
    track = trackListDev{trackNum};
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
    
    numStdsAway = 5;
    maxDifferences = numStdsAway * stdFeatures;
    differences = abs(monster - meanFeatures');
    outlierFrames = differences > maxDifferences'; % rename 'badFrames'
    
    numFeatures = length(featureSpec);
    for featureNum = 1:numFeatures
        
        
        
        outlierFramesFeature = find(outlierFrames(:, featureNum));
        numOutlierFrames = length(outlierFramesFeature);
        
        % skip this feature if there are no outlier frames
        if numOutlierFrames == 0
            continue;
        end
        
        clipsDir = sprintf('%s\\dialog-level-clips\\%s\\feat%2d (%s)', ...
            pwd, name, featureNum, featureAbbrevs(featureNum));
        mkdir(clipsDir);
        
        feature = featureSpec(featureNum);
        fprintf('\tfeature %d (%s)\n', featureNum, featureAbbrevs(featureNum));
        
        lastFrameSeen = 1;
        segmentStart = -1;
        segmentEnd = -1;
        
        for i = 1:numOutlierFrames
            frameNum = outlierFramesFeature(i);

            if frameNum == lastFrameSeen+1 % continuining
                
                segmentEnd = frameNum;
            else % start of new segment OR end of old segment
                
                if segmentStart < 0
                    segmentStart = frameNum;
                    segmentEnd = frameNum;
                else
                    % fprintf('start=%d end=%d\n', segmentStart, segmentEnd);
                    
                    segmentEnd = frameNum;
                    
                    % create the clip
                    % save it in the folder for this dialog
                    [audioData, sampleRate] = audioread(trackFilename);
                    
                    secondsStart = seconds(segmentStart / 100);
                    secondsEnd = seconds(segmentEnd / 100);
                    
                    idxStart = round(seconds(secondsStart) * sampleRate);
                    idxEnd = round(seconds(secondsEnd) * sampleRate);
                    newFilename = sprintf('%s\\%.2f-%.2f.wav', ...
                        clipsDir, seconds(secondsStart), seconds(secondsEnd));
                    clipData = audioData(idxStart:idxEnd);
                    audiowrite(newFilename, clipData, sampleRate);
                    
                    segmentStart = frameNum;
                    
                end
            end

            lastFrameSeen = frameNum;
        end
        
        
        
    end
    
end