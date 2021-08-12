function annotationTable = readElanAnnotation(trackFilename, useFilter)
% READELANANNOTATION Read utterance annotations from default ELAN 
% tab-delimited export to MATLAB table. If useFilter is true, regions 
% labeled other as neutral and disappointed are ignored.

    [~, name, ~] = fileparts(trackFilename);
    annFilename = append(name, ".txt");
    annotationPathRelative = append('annotations/', annFilename);
    
    annotationPathFull = fullfile(pwd, annotationPathRelative);

    % throw error if the annotation file does not exist
    if ~isfile(annotationPathFull)
        ME = MException('readElanAnnotation:fileNotFound', ...
        'Annotation file %s not found', annotationPathRelative);
        throw(ME);
    end

    importOptions = delimitedTextImportOptions( ...
        'Delimiter', {'\t'}, ...
        'VariableNames', {'tier', 'startTime', 'startTimeShort', 'endTime', 'endTimeShort', 'duration', 'durationShort', 'label'}, ...
        'VariableTypes', {'string', 'duration', 'duration', 'duration', 'duration', 'duration', 'duration', 'string'}, ...
        'SelectedVariableNames', {'tier', 'startTime', 'endTime', 'duration', 'label'}, ...
        'ConsecutiveDelimitersRule', 'join' ...
        );
    
    annotationTable = readtable(annotationPathFull, importOptions);
    
    % if filter argument was passed, delete rows with labels other than "n"
    % "nn" "d" or "dd"
    if useFilter
        toDelete = ismember(annotationTable.label, ["n" "nn" "d" "dd"]);
        annotationTable(~toDelete, :) = [];
    end
    
end

