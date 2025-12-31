file = '6obj200.txt';
dimension = 6;
% ------------- do not edit below this line -------------------------------
objectives = load(file);
if(dimension > 2)
    objectives = objectives + 0.00001; % to avoid numerical problems
end;
norm_weights = ones( size(objectives,1), size(objectives,2) );
for i = 1 : size(objectives,1)
    for j = 1 : dimension
        % Berechne Zähler (Produkt über alle Zielfunktionen ausser f_j)
        for k = 1 : dimension
            if (j ~= k)
                norm_weights(i,j) = norm_weights(i,j) * objectives(i,k);
            end;
        end;
        % Berechne Nenner (Summe über alle möglichen Produkte der 
        % Zielfunktionen mit (objectives - 1) Faktoren
        sum = 0;
        for k = 1 : dimension
            product = 1;
            for l = 1 : dimension
                if(k ~= l)
                    product = product .* objectives(i,l);
                end;
            end;
            sum = sum + product;           
        end;
        if(sum ~= 0)
            norm_weights(i,j) = norm_weights(i,j) ./ sum;
        elseif(objectives(i,j) == 0)
            norm_weights(i,j) = 1 ./ (dimension - 1);          
        end;           
    end;
end;
outfile = sprintf('space-filling-%udim.des', dimension);
dlmwrite(outfile, norm_weights, ' ');