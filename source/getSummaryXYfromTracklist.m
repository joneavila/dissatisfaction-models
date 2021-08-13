function [Xsummary, yActual] = getSummaryXYfromTracklist(tracklist, ...
    firstRegressor)

    nTracks = size(tracklist, 2);
    nSummaryFeatures = 3;
    Xsummary = zeros([nTracks nSummaryFeatures]);
    yActual = zeros(size(tracklist));
    
    % TODO check if the directory exists
    dataDir = append(pwd, '/data/dialog-level');
    
    for trackNum = 1:nTracks
        
        track = tracklist{trackNum};
        trackFilename = track.filename;
        
        annotationTable = readElanAnnotation(trackFilename, true);
        
        % get the X for that dialog
        % load precomputed data or throw error
        [~, name, ~] = fileparts(trackFilename);
        saveFilename = append(dataDir, '/', name, '.mat');
        try
            monster = load(saveFilename);
            monster = monster.monster;
        catch 
            error('monster not found: %s\n', trackFilename);
        end
        
        %% trim out-of-character frames from start and end of dialog
        numRows = size(annotationTable, 1);
        
        % skip this track if there are no useable annotations for it
        if ~numRows
            continue;
        end
        
        % find the first non-out-of-character
        for rowNum = 1:numRows
            row = annotationTable(rowNum, :);
            if row.label ~= "o"
                frameNumStart = round(milliseconds(row.startTime) / 10);
                break
            end
        end
        
        % find the last non-out-of-character
        for rowNum = numRows:-1:1 
            row = annotationTable(rowNum, :);
            if row.label ~= "o"
                frameNumEnd = round(milliseconds(row.startTime) / 10);
                break
            end
        end
        
        % clear out-of-character frames
        monster = monster(frameNumStart:frameNumEnd, :);

        %% get the known Y for that dialog
        % from call-log.xlsx, load the 'filename' and 'label' columns
        opts = spreadsheetImportOptions('NumVariables', 2, 'DataRange', ...
            'H2:I203', 'VariableNamesRange', 'H1:I1');
        callTable = readtable('call-log.xlsx', opts);
        matchingIdx = strcmp(callTable.filename, track.filename);
        actualLabel = callTable(matchingIdx, :).label{1};
        actualFloat = labelToFloat(actualLabel);

        yActual(trackNum) = actualFloat;

        % predict on X using the linear regressor
        % take the average of the predictions and make it the final one
        dialogPred = predict(firstRegressor, monster);

        % feature 1 - number of frames in dialogPred above the best 
        % threshold (the threshold with best F_0.25 score, found in 
        % linearRegressionFrame.m) divided by the number of total frames
        % DISS_THRESHOLD = 1.115; % found in linearRegressionFrame.m
        DISS_THRESHOLD = 0.953; % found in linearRegressionFrame.m
        Xsummary(trackNum, 1) = nnz(dialogPred > DISS_THRESHOLD) / ...
            length(dialogPred);
        
        % feature 2 - range of dialogPred 
        % get the range of predictions, ignoring the first and last x%
        % frames to try to ignore outliers
        toIgnore = 0.01;
        dialogPredSorted = sort(dialogPred);
        skipIntoIdx = round(length(dialogPredSorted) * toIgnore);
        if skipIntoIdx
            dialogPredRange = range(dialogPredSorted(skipIntoIdx:end-skipIntoIdx));
        else
            dialogPredRange = range(dialogPred);
        end
        Xsummary(trackNum, 2) = dialogPredRange;
        
        % feature 3 - standard deviation of dialogPred
        Xsummary(trackNum, 3) = std(dialogPred);
        
        %% plot predictions
%         plotDirectory = append(pwd, "\time-pred-plots\");
%         if ~exist(plotDirectory, 'dir')
%             mkdir(plotDirectory)
%         end
%         
%         figWidth = 1920;
%         figHeight = 1080;
%         fig = figure('visible', 'off', 'position', ...
%             [0, 0, figWidth, figHeight]);
%         x = (1:length(dialogPred)) * milliseconds(10);
%         y = dialogPred;
%         plot(x, y);
%         % hold on
%         % plot(x, dialogActual);
%         % legend('dialogPred','dialogActual')
%         title(sprintf('%s\n', trackFilename));
%         xlabel('time (seconds)');
%         ylabel('dissatisfaction');
%         ylim([-0.25 1.25]) % fix the y-axis range
%         exportgraphics(gca, sprintf('%s/%s.jpg', plotDirectory, name));
        
    end

end