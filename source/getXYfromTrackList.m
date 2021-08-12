function [X, y, frameTrackNums, frameUtterances] = ...
    getXYfromTrackList(trackList, featureSpec)
% GETXYFROMTRACKLIST Features are stored in X, labels are stored in y. 
% See also GETXYFROMFILE. If addTimeFeature is true, the last column of X
% is a time feature indicating the time of each frame relative its dialog.
% It is a temporary solution while we decide whether to keep this feature.

    X = [];
    y = [];
    frameTrackNums = [];
    frameUtterances = [];
    
    nTracks = size(trackList, 2);
    for trackNum = 1:nTracks
        
        track = trackList{trackNum};
        
        fprintf('[%d/%d] Getting X and y for %s\n', trackNum, nTracks, ...
            track.filename);
        
        % ignore if the annotation file does not exist
        [~, name, ~] = fileparts(track.filename);
        annFilename = append(name, ".txt");
        annotationFilename = append(pwd, '/annotations/', annFilename);
        if ~isfile(annotationFilename)
            fprintf('\tannotation file not found, skip\n');
            continue
        end
    
        [dialogX, dialogY, dialogFrameUtterances] = ...
            getXYfromFile(track.filename, featureSpec);
        
        % TODO appending is slow
        X = [X; dialogX];
        y = [y; dialogY];
        
        nFramesInDialog = size(dialogX, 1);
        trackNumsToAppend = ones(nFramesInDialog, 1) * trackNum;
        frameTrackNums = [frameTrackNums; trackNumsToAppend];
        frameUtterances = [frameUtterances; dialogFrameUtterances];
    end
end