function [setX, setY] = getXYfromTrackList(trackList, directory, featureSpec)

    % Appending is expensive but pre-allocating space, at least for this
    % few data is not worth it
    nFeatures = size(featureSpec, 2);
    setX = zeros([1 nFeatures]);
    setY = zeros([1 0]);
    
    % for each in the train set
    for trackNum = 1:length(trackList)
        track = trackList{trackNum};
        [dialogX, dialogY] = getXYforTrack(track.filename, directory, featureSpec); % TODO rename function
        
        setX = [setX; dialogX];
        setY = [setY; dialogY];
    end
    setX(1,:) = [];
end