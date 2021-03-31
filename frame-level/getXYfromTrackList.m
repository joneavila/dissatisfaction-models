function [X, y, matchingTrackNums, matchingFrameTimes] = ...
    getXYfromTrackList(trackList, featureSpec, useAllAnnotators)
% GETXYFROMTRACKLIST Features are stored in X, labels are stored in y. 
% See also GETXYFROMFILE.

    X = [];
    y = [];
    matchingTrackNums = [];
    matchingFrameTimes = [];
    
    nTracks = size(trackList, 2);
    for trackNum = 1:nTracks
        
        track = trackList{trackNum};
        
        fprintf('[%d/%d] Getting X and y for %s\n', trackNum, nTracks, ...
            track.filename);
        tic;
        [dialogX, dialogY, dialogMatchingTimes] = ...
            getXYfromFile(track.filename, featureSpec, useAllAnnotators);
        toc;
        
        % TODO appending is slow
        X = [X; dialogX];
        y = [y; dialogY];
        toAppend = ones([size(dialogX, 1) 1]) * trackNum;
        matchingTrackNums = [matchingTrackNums; toAppend];
        matchingFrameTimes = [matchingFrameTimes; dialogMatchingTimes];
    end
end