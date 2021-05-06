% debug, find out why there's NaNs in predictions

trackListDev = gettracklist('dev-dialog.tl');
featureSpec = getfeaturespec('.\mono-extended.fss');

trackNum = 1;
track = trackListDev{trackNum};

customerSide = 'l';
filename = track.filename;
trackSpec = makeTrackspec(customerSide, filename, '.\calls\');
% [~, monster] = makeTrackMonster(trackSpec, featureSpec);

% print out info on features with NaNs
[row, col] = find(isnan(monster));
for i = 1:length(col)
    featureNum = col(i);
    feature = featureSpec(featureNum);
    featureAbbrev = feature.abbrev;
    fprintf('featureNum=%d, featureAbbrev="%s"\n', featureNum, featureAbbrev);
end
