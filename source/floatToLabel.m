function label = floatToLabel(float, threshold)
    if (float <= threshold)
        label = 'successful';
    else
        label = 'doomed';
    end
end