function [X, y] = getXYfromTrackList(trackList, featureSpec)
% GETXYFROMTRACKLIST Features are stored in X, labels are stored in y. See
% GETXYFROMFILE.

    X = [];
    y = [];
    for trackNum = 1:length(trackList)
        track = trackList{trackNum};
        [dialogX, dialogY] = getXYfromFile(track.filename, featureSpec);
        
        % appending is ugly but isn't too slow here
        X = [X; dialogX];
        y = [y; dialogY];
    end
end