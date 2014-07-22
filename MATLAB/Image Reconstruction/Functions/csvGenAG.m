function [ A g ] = csvGenAG( csv_path, dim )
%CSVSPLITBREGMANSOLVE generates A and g given a csv with paths & integrals.
%   csv should have 1 line per data point of this format:
%      xstart, ystart, xend, yend, int
%

csv = csvread(csv_path);

paths = csv(:,1:end-1);
g = csv(:, end);
u = zeros(dim);

[A, ~, ~] = generateAug( u, paths);

end

