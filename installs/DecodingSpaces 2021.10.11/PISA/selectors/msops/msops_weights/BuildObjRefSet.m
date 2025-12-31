function[RefSet] = BuildObjRefSet(targets, dimension)
% calculate stepsize to produce minimally the amount of needed refpoints
steps = ceil(realpow(targets, (1./dimension)));
stepsize = 1 ./ (steps-1);
% calculate RefPoints
RefSet = Build(steps, stepsize, dimension);
while size(RefSet, 1) < targets
    stepsize = 1 ./ steps;
    steps = steps + 1;
    RefSet = Build(steps, stepsize, dimension);
end;   
% remove RefPoints regarding a next neighbour technique
killed = 0;
while size(RefSet, 1) > targets
    distancematrix = zeros(size(RefSet, 1), size(RefSet, 1));
    for i = 1 : size(RefSet, 1)
        for j = (i+1) : size(RefSet, 1)
            value = distance(RefSet(i,:), RefSet(j,:), dimension);
            distancematrix(i,j) = value;
            distancematrix(j,i) = value;
        end;
    end;
    distancematrix = sort(distancematrix, 2);
    min = 1;
    for i = 2 : size(RefSet, 1)
        if( isMoreCrowded(i, min, distancematrix) == 1 )
            min = i;
        end;
    end;
    RefSet(min,:) = [];
end;

%distance between two n-dimensional points
function[value] = distance(Point1, Point2, n)
sum = 0;
for i = 1 : n
    sum = sum + (Point2(i) - Point1(i)).^2;
end;
value = sqrt(sum);

% distance relation
function[value] = isMoreCrowded(i, j, distancematrix)
for k = 1 : size(distancematrix, 1)
    if(distancematrix(i, k) < distancematrix(j, k))
        value = 1;
        break;
    elseif(distancematrix(i, k) > distancematrix(j, k))
        value = 0;
        break;
    end;
    value = 0;
end;

% create initial RefSet
function[RefSet] = Build(steps, stepsize, dimension)
for i = 1 : realpow(steps, dimension);
    for j = 1 : dimension;
        RefSet(i, j) = stepsize .* mod(floor((i-1) ./ (steps.^(dimension-j))), steps);
    end;
    length = distance(zeros(dimension), RefSet(i,:), dimension);
    if length > 0
        RefSet(i,:) = RefSet(i,:) ./ length;
    end;
end;
RefSet(1,:) = [];
% remove clones in 2 steps: 1. indicate clones, 2. delete them
RefSetIndicators = ones(size(RefSet,1));
for i = 1 : size(RefSet, 1);
    for j = (i+1) : size(RefSet, 1)
        if(distance(RefSet(i,:), RefSet(j,:),dimension) < 0.00001)
           RefSetIndicators(j) = 0;
        end;
    end;
end;
killed = 0;
for i = 1 : size(RefSetIndicators)
    if( RefSetIndicators(i) == 0 )
        RefSet(i-killed,:) = [];
        killed = killed + 1;
    end;
end;