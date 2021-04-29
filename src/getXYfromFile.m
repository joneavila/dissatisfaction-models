function [X, y, frameTimes, frameUtterances] = getXYfromFile(filename, ...
    featureSpec, useAllAnnotators)
% GETXYFROMFILE Features are stored in X, labels are stored in y. 
% matchingFrameNums is an array of matching frame indices. If
% useAllAnnotators is false, then only 'ja' annotations are used.

    % get the annotation filename from the dialog filename, assuming
    % they have the same name
    [~, name, ~] = fileparts(filename);
    annFilename = append(name, ".txt");
    
    useFilter = true;

    % get the monster
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);
    nFrames = size(monster, 1);
    
    tableJA = readElanAnnotation(...
            append('annotations\ja-annotations\', annFilename), useFilter);
    
    annotated = false([nFrames 1]);
    
    if useAllAnnotators
        
        tableNW = readElanAnnotation(...
            append('annotations\nw-annotations\', annFilename), useFilter);
        
        % find which frames are annotated by everyone
        for frameNum = 1:size(monster, 1)
            if isFrameInTable(frameNum, tableJA) && ...
                    isFrameInTable(frameNum, tableNW)
                annotated(frameNum) = true;
            end
        end

        yJA = getYfromTable(tableJA, monster, annotated);
        yNW = getYfromTable(tableNW, monster, annotated);
        y = mean([yJA yNW], 2);
        
    else
        
        for frameNum = 1:size(monster, 1)
            if isFrameInTable(frameNum, tableJA)
                annotated(frameNum) = true;
            end
        end

        y = getYfromTable(tableJA, monster, annotated);
    end
    
    matchingFrameNums = find(annotated);
    
    frameTimes = arrayfun(@(frameNum) frameNumToTime(frameNum), matchingFrameNums);
    
    % TODO this is using just 'ja' annotations!
    frameUtterances = arrayfun(@(frameNum) frameToUtterance(frameNum, tableJA), matchingFrameNums);
    
    X = monster(annotated, :);

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

function y = getYfromTable(annTable, monster, completelyAnnotated)
    y = ones([size(monster, 1) 1]) * -1;
    for annotationNum = 1:height(annTable)
        row = annTable(annotationNum, :);
        frameStart = round(milliseconds(row.startTime) / 10);
        frameEnd = round(milliseconds(row.endTime) / 10);
        y(frameStart:frameEnd, :) = labelToFloat(row.label);
    end
    y = y(completelyAnnotated);
end