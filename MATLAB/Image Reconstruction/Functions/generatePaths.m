function paths = generatePaths(num_paths, dim, path_type, points)
	% by default, generate random paths
    
	paths = zeros(num_paths,4);

    % we define min path length as the length of the path from a midpoint 
	% of one side to the midpoint of an adjacent side
	min_path_length = sqrt((dim(1)/2)^2 + (dim(2)/2)^2);
	%min_path_length = 0;
    
    if nargin == 2
		%disp('nothing')
        for i = 1:num_paths
			% choosing two edges of the image
			% 1 = left, 2 = top, 3 = right, 4 = bottom
			edges = randperm(4);
            edges = edges(1:2);
			point1 = get_random_point_on_edge(edges(1), dim);
			point2 = get_random_point_on_edge(edges(2), dim);							
			paths(i,:) = [point1 point2];
        end
        
    elseif strcmp(path_type, 'random')
        
        paths = dim(1)*rand(num_paths,4);
        
    % If the path type is bouncy, then bounce from wall to wall.
	elseif strcmp(path_type, 'bouncy')
        %disp('bouncy')
        edges = randperm(4);
        edges = edges(1:2);
		point1 = get_random_point_on_edge(edges(1), dim);
		point2 = get_random_point_on_edge(edges(2), dim);							
		paths(1,:) = [point1 point2];
		last_edge = edges(2);
        for i = 2:num_paths,
			rand_edge = randi(4);
			% make sure we don't bounce to the same edge
			while (rand_edge == last_edge)
				rand_edge = randi(4);
			end
			point1 = point2;
			point2 = get_random_point_on_edge(rand_edge, dim);

			path_length = pdist([point1; point2], 'euclidean');
			while (path_length < min_path_length)
				point2 = get_random_point_on_edge(rand_edge, dim);
				path_length = pdist([point1; point2], 'euclidean');
			end

			last_edge = rand_edge;
			paths(i,:) = [point1 point2];
        end
        
    elseif strcmp(path_type, 'radial')

        N = dim(1);
        M = dim(2);
        
        n = N/2;
        m = M/2;
        
        theta = (2*pi/(2*num_paths))*(0:2*num_paths-1)';
        thetaMod = mod(theta+pi/4, pi/2) - pi/4;
        r = abs((N-n)./cos(thetaMod));
        
        theta0   = theta(1:num_paths);
        thetaend = theta(num_paths+1:end);
        
        r0 = r(1:num_paths);
        rend = r(num_paths+1:end);
        
        x0   = r0.*cos(theta0) + n;
        y0   = r0.*sin(theta0) + m;
        xend = rend.*cos(thetaend) + n;
        yend = rend.*sin(thetaend) + m;
        
        paths(:,:) = [ x0 y0 xend yend ];
        
    elseif strcmp(path_type, 'centered')
        
        M = dim(1);
        N = dim(2);
        
        idx = randsample(size(points,1), 1, 1);
        center = points(idx, :);
        m = center(1); n = center(2);
        
        % Use disk point picking to choose the next point we go to.        
        for i = 1:num_paths
            
            % Connect our paths.
            paths(i, 1:2) = [n M-m];
            
            % Pick the point we want to be close to.
            %idx = randi(size(points, 2)/2)*2-1;
            relpts = bsxfun(@minus, points,center);
            dist = sqrt(sum(relpts.^2,2));
            maxdist = max(dist);
            
            weights = (maxdist-dist)./sum(dist);
            idx = randsample(size(points,1), 1, 1, weights);
            
            center = points(idx, :);
            
            % Choose an angle to go in.
            theta = 2*pi*rand(1);
            
            % Find the maximum distance we can go in that direction.
            rmax = find_max_dist( M, N, center, theta );
            
            % Pick a distance to go and go there.
            r = rmax*rand(1);
            
            m = abs(center(1) - r*sin(theta));
            n = abs(center(2) + r*cos(theta));
            
            paths(i, 3:4) = [n M-m];
            
        end

    elseif strcmp(path_type, 'randombounce')
        
        N = dim(1);
        M = dim(2);
    	point1 = [rand(1)*M rand(1)*N];
        for i = 1:num_paths
    		point2 = [rand(1)*M rand(1)*N];
			paths(i,:) = [point1 point2];
			point1 = point2;
        end    	
    
    elseif strcmp(path_type, 'points')
        N = dim(1);
        M = dim(2);
        for i = 1:num_paths,
            point1 = [randi(M-1) rand(1)*N];
            point2 = point1 + [1 0];
            paths(i,:) = [point1 point2];
        end
    end


end

function point = get_random_point_on_edge(edge_num, dim)
	switch edge_num
	case 1
		x1 = 0;
		y1 = rand(1)*dim(1);
	case 2
		x1 = rand(1)*dim(2);
		y1 = dim(1);
	case 3
		x1 = dim(2);
		y1 = rand(1)*dim(1);
	case 4
		x1 = rand(1)*dim(2);
		y1 = 0;
	end
	point = [x1 y1];
end

function rmax = find_max_dist( M, N, center, theta )

m0 = center(1); n0 = center(2);

if 0 < theta && theta < pi/2
    rmax = min( m0/sin(theta), (N-n0)/cos(theta) );
elseif pi/2 < theta && theta < pi
    rmax = min( m0/sin(theta), -n0/cos(theta) );
elseif pi < theta && theta < (3/2)*pi
    rmax = min( -(M-m0)/sin(theta), -n0/cos(theta) );
elseif (3/2)*pi < theta && theta < 2*pi
    rmax = min( -(M-m0)/sin(theta), (N-n0)/cos(theta) );
elseif theta == 0 || theta == 2*pi;
    rmax = N-n0;
elseif theta == pi/2
    rmax = m0;
elseif theta == pi
    rmax = n0;
elseif theta == (3/2)*pi
    rmax = M-m0;
else
    fprintf('pathing error')
    rmax = 0;
end

end