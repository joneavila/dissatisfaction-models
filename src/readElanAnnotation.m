function annotationTable = readElanAnnotation(pathRelative, useFilter)
% READELANANNOTATION Read utterance annotations from default ELAN 
% tab-delimited export to MATLAB table. If useFilter is true, regions 
% labeled other as neutral and disappointed are ignored.

    importOptions = delimitedTextImportOptions( ...
        'Delimiter', {'\t'}, ...
        'VariableNames', {'tier', 'startTime', 'startTimeShort', 'endTime', 'endTimeShort', 'duration', 'durationShort', 'label'}, ...
        'VariableTypes', {'string', 'duration', 'duration', 'duration', 'duration', 'duration', 'duration', 'string'}, ...
        'SelectedVariableNames', {'tier', 'startTime', 'endTime', 'duration', 'label'}, ...
        'ConsecutiveDelimitersRule', 'join' ...
        );
    
    pathFull = fullfile(pwd, pathRelative);
    annotationTable = readtable(pathFull, importOptions);
    
    % if filter argument was passed, delete rows with labels other than "n"
    % "nn" "d" or "dd"
    if useFilter
        toDelete = ismember(annotationTable.label, ["n" "nn" "d" "dd"]);
        annotationTable(~toDelete, :) = [];
    end
end

