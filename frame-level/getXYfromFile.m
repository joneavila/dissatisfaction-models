function [X, y] = getXYfromFile(filename, featureSpec, useAllAnnotators)
% GETXYFROMFILE Features are stored in X, labels are stored in y. Only
% neutral and disappointed labels are used ("n", "nn", "d", "dd").

    % get the annotation filename from the dialog filename, assuming
    % they have the same name
    [~, name, ~] = fileparts(filename);
    annFilename = append(name, ".txt");

    % get the monster
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);
    
    % If useAllAnnotors is true, X and y are for frames only annotated by
    % everyone (y is the mean annotations), else X and y are for frames
    % annotated by 'ja'.
    
    if useAllAnnotators
        
        tableJA = readElanAnnotation(...
            append('annotations\ja-annotations\', annFilename), true);
        tableNW = readElanAnnotation(...
            append('annotations\nw-annotations\', annFilename), true);
        
        % find which frames are annotated by everyone
        completelyAnnotated = false([size(monster, 1) 1]);
        for frameNum = 1:size(monster, 1)
            if isFrameInTable(frameNum, tableJA) && ...
                    isFrameInTable(frameNum, tableNW)
                completelyAnnotated(frameNum) = true;
            end
        end

        yJA = getYfromTable(tableJA, monster, completelyAnnotated);
        yNW = getYfromTable(tableNW, monster, completelyAnnotated);

        X = monster(completelyAnnotated, :);
        y = mean([yJA yNW], 2);
        
    else
        
        tableJA = readElanAnnotation(...
            append('annotations\ja-annotations\', annFilename), true);
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