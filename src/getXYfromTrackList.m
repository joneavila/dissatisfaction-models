function [X, y, frameTrackNums, frameTimes, frameUtterances] = ...
    getXYfromTrackList(trackList, featureSpec, useAllAnnotators)
% GETXYFROMTRACKLIST Features are stored in X, labels are stored in y. 
% See also GETXYFROMFILE.

    X = [];
    y = [];
    frameTrackNums = [];
    frameTimes = [];
    frameUtterances = [];
    
    nTracks = size(trackList, 2);
    for trackNum = 1:nTracks
        
        track = trackList{trackNum};
        
        fprintf('[%d/%d] Getting X and y for %s\n', trackNum, nTracks, ...
            track.filename);
        tic;
        [dialogX, dialogY, dialogFrameTimes, dialogFrameUtterances] = ...
            getXYfromFile(track.filename, featureSpec, useAllAnnotators);
        toc;
        
        % TODO appending is slow
        X = [X; dialogX];
        y = [y; dialogY];
        toAppend = ones([size(dialogX, 1) 1]) * trackNum;
        frameTrackNums = [frameTrackNums; toAppend];
        frameTimes = [frameTimes; dialogFrameTimes];
        frameUtterances = [frameUtterances; dialogFrameUtterances];
    end
end