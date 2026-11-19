function [semContPlot]  = sem(contShortTrim)

for i =1:1:width(contShortTrim)
    semContPlot(i) =  std(contShortTrim(:,i), 'omitnan') / sqrt(height(contShortTrim));
end
