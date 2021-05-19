function [X, y, frameTimes, frameUtterances] = getXYfromFile(filename, ...
    featureSpec, annotator)
% GETXYFROMFILE Features are stored in X and labels are stored in y. 
% For frame i, frameTimes(i) is the time in milliseconds and
% frameUtterances(i) is the frame's utterance number (if the utterances in 
% X were labeled 1..n)
    
    % get the annotation filename from the dialog filename, assuming
    % they have the same name
    [~, name, ~] = fileparts(filename);
    annFilename = append(name, ".txt");
    
    % get the monster
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);

    % get the annotation table
    annotationPath = append('annotations\', annotator, '-annotations\', annFilename);
    useFilter = true;
    annotationTable = readElanAnnotation(annotationPath, useFilter);
    
    % TODO replace with arrayfun
    % mark all frames that are annotated
    nFrames = size(monster, 1);
    isFrameAnnotated = false([nFrames 1]);
    for frameNum = 1:size(monster, 1)
        if isFrameInTable(frameNum, annotationTable)
            isFrameAnnotated(frameNum) = true;
        end
    end

    y = getYfromTable(annotationTable, monster, isFrameAnnotated);

    matchingFrameNums = find(isFrameAnnotated);
    
    frameTimes = arrayfun(@(frameNum) frameNumToTime(frameNum), ...
        matchingFrameNums);
    
    frameUtterances = arrayfun(@(frameNum) ...
        frameToUtterance(frameNum, annotationTable), matchingFrameNums);
    
    X = monster(isFrameAnnotated, :);

end

function utteranceNum = frameToUtterance(frameNum, annTable)
    numRows = size(annTable, 1);
    utteranceNum = -1;
    for rowNum = 1:numRows
        row = annTable(rowNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        if frameNum >= frameStart && frameNum <= frameEnd
            utteranceNum = rowNum;
            return;
        end
    end
end

function [inTable, annotation] = isFrameInTable(frameNum, annTable)
% ISFRAMEINTABLE inTable is true if the frame is in the annotation, i.e.
% the frame belongs to a labeled utterance. If inTable is true, annotation
% is the the assigned label, else annotation is -1.

    inTable = false;
    annotation = -1;
    for rowNum = 1:size(annTable, 1)
        row = annTable(rowNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        if frameNum >= frameStart && frameNum <= frameEnd
            inTable = true;
            annotation = labelToFloat(row.label);
            return;
        end
    end
end

function y = getYfromTable(annTable, monster, isFrameAnnotated)
    y = ones([size(monster, 1) 1]) * -1;
    for annotationNum = 1:height(annTable)
        row = annTable(annotationNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        y(frameStart:frameEnd, :) = labelToFloat(row.label);
    end
    y = y(isFrameAnnotated);
end