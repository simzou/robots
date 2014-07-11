function [ paths g ] = paths_g_from_csv( file )
data = csvread(file,0,1);
paths = data(:,1:4);
g = data(:,5);
end

