function [X, y] = getXYfromFile(filename, featureSpec, useAllAnnotators)
% GETXYFROMFILE Features are stored in X, labels are stored in y. If 
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
    
    tableJA = readElanAnnotation(...
            append('annotations\ja-annotations\', annFilename), useFilter);
    
    if useAllAnnotators
        
        tableNW = readElanAnnotation(...
            append('annotations\nw-annotations\', annFilename), useFilter);
        
        % find which frames are annotated by everyone
        annotated = false([size(monster, 1) 1]);
        for frameNum = 1:size(monster, 1)
            if isFrameInTable(frameNum, tableJA) && ...
                    isFrameInTable(frameNum, tableNW)
                annotated(frameNum) = true;
            end
        end

        yJA = getYfromTable(tableJA, monster, annotated);
        yNW = getYfromTable(tableNW, monster, annotated);

        X = monster(annotated, :);
        y = mean([yJA yNW], 2);
        
    else
        
        annotated = false([size(monster, 1) 1]);
        for frameNum = 1:size(monster, 1)
            if isFrameInTable(frameNum, tableJA)
                annotated(frameNum) = true;
            end
        end
        X = monster(annotated, :);
        y = getYfromTable(tableJA, monster, annotated);
    end

end

% Returns annotation if in table, else returns -1
function [inTable, annotation] = isFrameInTable(frameNum, table)
    inTable = false;
    annotation = -1;
    for rowNum = 1:size(table, 1)
        row = table(rowNum, :);
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