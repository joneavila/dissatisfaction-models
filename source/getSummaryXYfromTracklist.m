function [Xsummary, yActual] = getSummaryXYfromTracklist(tracklist, ...
    normalizeCenteringValues, normalizeScalingValues, firstRegressor, ...
    useTimeFeature)

    featureSpec = getfeaturespec('.\source\mono.fss');
    nTracks = size(tracklist, 2);

    numSummaryFeatures = 5;
    Xsummary = zeros([nTracks numSummaryFeatures]);
    yActual = zeros(size(tracklist));
    
    if useTimeFeature
        dataDir = append(pwd, '\data\monsters-with-time\');
    else
        dataDir = append(pwd, '\data\monsters-without-time\');
    end
    if ~exist(dataDir, 'dir')
        mkdir(dataDir)
    end

    for trackNum = 1:nTracks
        
        track = tracklist{trackNum};
        filename = track.filename;
        fprintf('\t[%d/%d] %s... ', trackNum, nTracks, track.filename);
        
        % get the annotation path, assuming they share the same name
        [~, name, ~] = fileparts(filename);
        annFilename = append(name, ".txt");
        annotationPath = append('annotations\', annFilename);
        
        % skip this dialog if the annotation file does not exist
        if ~exist(annotationPath, 'file')
            fprintf('annotation file not found\n');
            continue
        end

        % get the X for that dialog
        % try to load the precomputed data, else compute it and save it for 
        % future runs
        customerSide = 'l';
        
        trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
        [~, name, ~] = fileparts(filename);
        saveFilename = append(dataDir, name, '.mat');
        try
            monster = load(saveFilename);
            monster = monster.monster;
        catch 
            % [~, monster] = makeTrackMonster(trackSpec, featureSpec);
            % save(saveFilename, 'monster');
            error('monster not found: %s\n', filename);
        end
        
        % temporary bug fix
        % rerun prepareData script to rebuild data/monsters-with-time
        if size(monster,2) == 120
            monster = monster(:,1:119);
        elseif size(monster,2) == 118
            monster(:,119) = monster(:,118);
        end
        

        % normalize X (monster) using the same centering values and scaling 
        % values used to normalize the data used for training
        monster = normalize(monster, 'center', ...
            normalizeCenteringValues, 'scale', normalizeScalingValues);
        
        % trim out-of-character frames from start and end of dialog
        useFilter = false;
        annotationTable = readElanAnnotation(annotationPath, useFilter);
        numRows = size(annotationTable, 1);
        for rowNum = 1:numRows % find the first non-out-of-character
            row = annotationTable(rowNum, :);
            if row.label ~= "o"
                frameNumStart = round(milliseconds(row.startTime) / 10);
                break
            end
        end
        for rowNum = numRows:-1:1 % find the last non-out-of-character
            row = annotationTable(rowNum, :);
            if row.label ~= "o"
                frameNumEnd = round(milliseconds(row.startTime) / 10);
                break
            end
        end
        monster = monster(frameNumStart:frameNumEnd, :);

        % get the known Y for that dialog
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
        
        % feature 2 - min of dialogPred
        Xsummary(trackNum, 2) = min(dialogPred);
        
        % feature 3 - max of dialogPred
        Xsummary(trackNum, 3) = max(dialogPred);
        
        % feature 4 - average of dialogPred
        Xsummary(trackNum, 4) = mean(dialogPred);
        
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
        
        % feature 5 - range of dialogPred 
        Xsummary(trackNum, 5) = dialogPredRange;
        
        % feature 6 - standard deviation of dialogPred
        Xsummary(trackNum, 6) = std(dialogPred);
        
        plotDirectory = append(pwd, "\time-pred-plots\");
        if ~exist(plotDirectory, 'dir')
            mkdir(plotDirectory)
        end
        
        figWidth = 1920;
        figHeight = 1080;
        fig = figure('visible', 'off', 'position', ...
            [0, 0, figWidth, figHeight]);
        x = (1:length(dialogPred)) * milliseconds(10);
        y = dialogPred;
        plot(x, y);
        % hold on
        % plot(x, dialogActual);
        % legend('dialogPred','dialogActual')
        title(sprintf('%s\n', filename));
        xlabel('time (seconds)');
        ylabel('dissatisfaction');
        ylim([-0.25 1.25]) % fix the y-axis range
        exportgraphics(gca, sprintf('%s/%s.jpg', plotDirectory, name));
        
        fprintf('done\n');
        
    end

end