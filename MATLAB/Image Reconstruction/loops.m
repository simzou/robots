n = [10 50 100 200 500 1000 2500];
for j = 1:10
	errors = zeros(10,1);
	for i = 1:10
		[num_paths, err, time, uguess] = runReconstruction(n(j),'randompoints');
		errors(i) = err;
	end
	num_paths
	mean(errors)

end