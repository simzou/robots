function A = paths_to_A( paths, dims )
umat = zeros(dims(1),dims(2));
A = generate_Aug_from_image(umat,paths);
end

