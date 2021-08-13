function [X, y, frameTrackNums, frameUtterances, frameTimes] = ...
    getXYfromTrackList(trackList, featureSpec)
% GETXYFROMTRACKLIST Features are stored in X, labels are stored in y. 
% For frame i, frameTrackNums is the frame's track number relative to 
% trackList. See GETXYFROMFILE for more information on frameUtterances and
% frameTimes. frameTrackNums is used in failure analysis only.

    X = [];
    y = [];
    frameTrackNums = [];
    frameUtterances = [];
    frameTimes = [];
    
    nTracks = size(trackList, 2);
    for trackNum = 1:nTracks
        
        track = trackList{trackNum};
        
        fprintf('[%d/%d] Getting X and y for %s\n', trackNum, nTracks, ...
            track.filename);
    
        [dialogX, dialogY, dialogFrameUtterances, dialogFrameTimes] = ...
            getXYfromFile(track.filename, featureSpec);
        
        % skip this track if there are no useable annotations for it
        if ~size(dialogX, 1)
            continue
        end
        
        X = [X; dialogX]; % TODO appending is slow
        y = [y; dialogY];
        nFramesInDialog = size(dialogX, 1);
        trackNumsToAppend = ones(nFramesInDialog, 1) * trackNum;
        frameTrackNums = [frameTrackNums; trackNumsToAppend];
        frameUtterances = [frameUtterances; dialogFrameUtterances];
        frameTimes = [frameTimes; dialogFrameTimes];
        
    end

end