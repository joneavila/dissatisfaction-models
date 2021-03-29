function [X, y] = getXYfromFile(filename, featureSpec)
% GETXYFROMFILE Features are stored in X, labels are stored in y. Only
% neutral and disappointed labels are used ("n", "nn", "d", "dd").

    % get the annotation filename from the dialog filename, assuming
    % they have the same name
    [~, name, ~] = fileparts(filename);
    annotationFilename = append(name, ".txt");

    % get the monster
    customerSide = 'l';
    trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
    [~, monster] = makeTrackMonster(trackSpec, featureSpec);
    
    nFeatures = size(monster, 2);
    
    % get the annotation table set up (just using one annotator here)
    annotationPathRelative = append('ja-annotations\', annotationFilename);
    annotationTable = readElanAnnotation(annotationPathRelative, true);
    
    % iterate the table to pre-allocate size of X and y
    totalFrames = 0;
    for annotationNum = 1:height(annotationTable)
        row = annotationTable(annotationNum, :);
        
        startFrameMonster = round(milliseconds(row.startTime) / 10);
        endFrameMonster = round(milliseconds(row.endTime) / 10);
        framesInRegion = endFrameMonster - startFrameMonster + 1;
        totalFrames = totalFrames + framesInRegion;
    end
    
    X = zeros([totalFrames nFeatures]);
    y = zeros([totalFrames 1]);
    
    % for each entry in the table
    nFramesProcessed = 0;
    for annotationNum = 1:height(annotationTable)
        
        row = annotationTable(annotationNum, :);
        
        % skip if the label is not "n", "nn", "d", or "dd"
        % TODO check for bad labels
        if ~strcmp(row.label, "n") && ~strcmp(row.label, "nn") && ...
                ~strcmp(row.label, "d") && ~strcmp(row.label, "dd")
            continue;
        end

        startFrameMonster = round(milliseconds(row.startTime) / 10);
        endFrameMonster = round(milliseconds(row.endTime) / 10);
        
        regionX = monster(startFrameMonster:endFrameMonster, :);
     
        regionY = zeros(size(regionX, 1), 1); 
        regionY(:) = labelToFloat(row.label);
        
        framesInRegion = endFrameMonster - startFrameMonster + 1;
      
        idxStart = nFramesProcessed + 1;
        idxEnd = idxStart + framesInRegion - 1;
        
        % insert into X and y
        X(idxStart:idxEnd, :) = regionX;
        y(idxStart:idxEnd, :) = regionY;
        
        nFramesProcessed = nFramesProcessed + framesInRegion;
        
    end
    
end