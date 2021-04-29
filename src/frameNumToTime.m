% frameNumToTime.m
% Takes a frame number (index) belonging to a monster (returned from 
% makeTrackMonster function) and returns the time in milliseconds.

function time = frameNumToTime(frameNum)
    time = milliseconds(10) * frameNum;
end