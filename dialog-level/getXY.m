function [X, y, trackListExtended] = getXY(trackList, featureSpec)

    X = [];
    y = [];
    
    trackListExtended = trackList;
    
    % from call-log.xlsx, load the 'filename' and 'label' columns
    opts = spreadsheetImportOptions('NumVariables', 2, ...
        'DataRange', 'H2:I203', 'VariableNamesRange', 'H1:I1');
    callTable = readtable('call-log.xlsx', opts);

    for trackNum = 1:size(trackList, 2)
        
        track = trackList{1, trackNum};
        
        % get the monster
        customerSide = 'l';
        trackSpec = makeTrackspec(customerSide, track.filename, '.\calls\');
        [~, Xdialog] = makeTrackMonster(trackSpec, featureSpec);
        
        % keep only every nFramesSkip frame so that frames are further apart
        % if nFramesSkip=10, then frames are 100ms apart
        nFramesSkip = 10;
        Xdialog = Xdialog(1:nFramesSkip:end, :);
        
        % store the number of frames to reference later by adding new field 'nFrames'
        track.nFrames = size(Xdialog, 1);
    
        matchingIdx = strcmp(callTable.filename, track.filename);
        label = callTable(matchingIdx, :).label{1};
        
        if strcmp(label, 'successful')
            track.labelActual = 'successful';
            track.floatActual = 1;
        elseif strcmp(label, 'doomed_1') || strcmp(label, 'doomed_2')
            track.labelActual = 'doomed';
            track.floatActual = 0;
        else
            error('unknown label in call table')
        end
        
        yDialog = ones(size(Xdialog, 1), 1) * track.floatActual;
        
        X = [X; Xdialog];
        y = [y; yDialog];
        
        trackListExtended(trackNum) = {track};
       
    end

end