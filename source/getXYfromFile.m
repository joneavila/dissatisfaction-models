function [X, y, frameUtterances] = getXYfromFile(filename, featureSpec)
% GETXYFROMFILE Features are stored in X and labels are stored in y. 
% For frame i, frameTimes(i) is the time in milliseconds and
% frameUtterances(i) is the frame's utterance number (utterances in 
% X are labeled 1..n)
    
    % get the annotation filename from the dialog filename, assumin they 
    % have the same name, then get the annotation table
    [~, name, ~] = fileparts(filename);
    annFilename = append(name, ".txt");
    annotationPath = append('annotations/', annFilename);
    useFilter = true;
    annotationTable = readElanAnnotation(annotationPath, useFilter);
    
    % get the monster
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, filename, './calls/');
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);
    
    nFrames = size(monster, 1);
    
    isFrameAnnotated = false([nFrames 1]); % assume frame is not annotated (false)
    y = ones([nFrames 1]) * -1; % assume frame label does not exist (-1)
    frameUtterances = ones([nFrames 1]) * -1; % assume frame does not belong to labeled utterance (-1)
        
    nRows = size(annotationTable, 1);
    for rowNum = 1:nRows
        row = annotationTable(rowNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        isFrameAnnotated(frameStart:frameEnd) = true;
        y(frameStart:frameEnd) = labelToFloat(row.label);
        frameUtterances(frameStart:frameEnd) = rowNum;
    end

    % TODO remove isFrameAnnotated and use y directly
    matchingFrameNums = find(isFrameAnnotated);

    X = monster(isFrameAnnotated, :);
    y = y(isFrameAnnotated);
    frameTimes = arrayfun(@(frameNum) frameNumToTime(frameNum), ...
        matchingFrameNums);
    frameUtterances = frameUtterances(isFrameAnnotated);
    
    % NEW - frameTimes is now a feature included in X
    X = [X seconds(frameTimes)];

end
