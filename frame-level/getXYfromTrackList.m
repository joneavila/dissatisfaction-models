function [X, y] = getXYfromTrackList(trackList, featureSpec, useAllAnnotators)
% GETXYFROMTRACKLIST Features are stored in X, labels are stored in y. See
% GETXYFROMFILE.

    X = [];
    y = [];
    nTracks = size(trackList, 2);
    for trackNum = 1:nTracks
        track = trackList{trackNum};
        
        fprintf('[%d/%d] Getting data for %s\n', trackNum, nTracks, track.filename);
        
        [dialogX, dialogY] = getXYfromFile(track.filename, featureSpec, useAllAnnotators);
        
        % appending is ugly but isn't too slow here
        X = [X; dialogX];
        y = [y; dialogY];
    end
end