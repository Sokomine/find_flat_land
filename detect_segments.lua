
-- merges the neighbours-list of the two segments a and b from segment_list
-- segment_list[ b ].neighbours will be moved to segment_list[ a ].neighbours
-- and all of b's neighbours be updated
find_flat_land.merge_segments = function( segment_list, a, b )
	-- make sure a is the smaller index
	if( b>a ) then
		local temp = a;
		a = b;
		b = temp;
	end

	-- all neighbours of b are moved to a
	for neighbour_id, _ in pairs( segment_list[ b ].neighbours ) do
		-- add neighbour from b to a
		segment_list[ a ].neighbours[ neighbour_id ] = true;

		-- the neighbour's neighbour changes as well; from now
		-- on it will be a instead of b
		segment_list[ neighbour_id ].neighbours[ b ] = nil;
		segment_list[ neighbour_id ].neighbours[ a ] = true;
	end
	-- no point in beeing neighbour of itself
	segment_list[ a ].neighbours[ a ] = nil;
	-- a is no longer neighbour of b (b has no further relevance here)
	segment_list[ a ].neighbours[ b ] = nil;
	-- b no longer has any neighbours
	segment_list[ b ].neighbours = {};

	-- store which segment b has been merged into
	segment_list[ b ].merged = a;
	
	-- there may have been segments that have been merged into b already
	if( not( segment_list[ a ].merged_segments )) then
		segment_list[ a ].merged_segments = {b};
	else
		table.insert(segment_list[ a ].merged_segments, b);
	end
	if( segment_list[ b ].merged_segments ) then
		for i,s in ipairs( segment_list[ b ].merged_segments ) do
			table.insert( segment_list[ a ].merged_segments, s );
			-- segment s has been merged first into b and now into a
			segment_list[ s ].merged = a;
		end
	end
	segment_list[ b ].merged_segments = {};

	segment_list[ b ].is_obsolete = true;
end


-- assigns a segment value to each point in the heightmap;
-- creates a segment_list that lists all segments and their neighbours
find_flat_land.detect_segments = function( heightmap, minp, maxp, segment, segment_list )
	-- we want to seperate the heightmap into connected segments
	--segment = {};
	--segment_list = {};

	-- a height value that cannot occour
	local lastheight = -1;
	local lastrowheight = -1;

	local chunksize = maxp.x-minp.x+1;
	-- iterate over the entire heightmap
	-- mark areas with the same height (based on 4-connected)
        local i = 0;
	for az=minp.z,maxp.z do
	for ax=minp.x,maxp.x do
		i = i+1;
		local height = heightmap[i];
		-- no point in detecting sea level
		if( height<1 ) then
			height = 0;
		end
		if( i>chunksize ) then
			lastrowheight = heightmap[ i-chunksize ];
		end

		local last_col_segment = segment[ i-1 ];
		local last_row_segment = segment[ i-chunksize ];
		-- does an existing segment continue here?
		if(     height == lastheight and (ax>minp.x)) then
			segment[ i ] = last_col_segment;
		elseif( height == lastrowheight and (az>minp.z)) then
			segment[ i ] = last_row_segment;
		else 
			-- increment the segment counter
			local nr = #segment_list + 1;
			-- the first height value will start the first segment
			segment_list[ nr ] = {};
			-- starts at index i in the heightmap
			segment_list[ nr ].starts_at = i;
			-- the segment does not have any neighbours yet
			segment_list[ nr ].neighbours = {};

			-- this height value belongs to the new segment
			segment[ i ] = nr;
		end

		-- check if we have a new neighbour
		if( (ax>minp.x) and last_col_segment and segment[ i ] ~= last_col_segment) then
			segment_list[ segment[ i ]     ].neighbours[ last_col_segment ] = true;
			segment_list[ last_col_segment ].neighbours[ segment[ i ]     ] = true;
		end
		if( (az>minp.z) and last_row_segment and segment[ i ] ~= last_row_segment) then
			segment_list[ segment[ i ]     ].neighbours[ last_row_segment ] = true;
			segment_list[ last_row_segment ].neighbours[ segment[ i ]     ] = true;
		end
		lastheight = height;
		if( ax==maxp.x ) then
			lastheight = -1;
		end
	end
	end
	--print("anz_segments (initally): "..tostring( #segment_list ));
end

-- the first pass over the data is unable to identify some kind of segments as one;
-- those which are connected and really the same need to be merged here
find_flat_land.merge_segments_with_same_height = function( heightmap, minp, maxp, segment, segment_list )
	local anz_segments = 0;
	local anz_merged = 0;
	-- check which segments have the same height and merge their neighbour lists
	for segment_id,segment_data in ipairs( segment_list ) do
		-- cache the IDs of those segments we want to merge
		local to_merge = {};
		for neighbour_id,_ in pairs( segment_data.neighbours ) do
			-- detect segments with the same height
			if(   (neighbour_id > segment_id )
			  and (heightmap[ segment_list[ segment_id   ].starts_at ]
			    == heightmap[ segment_list[ neighbour_id ].starts_at ])) then
				-- remember to merge this one
				table.insert( to_merge, neighbour_id );
			end
		end
		-- actually do the merge (which changes segment_data.neighbours)
		for i, neighbour_id in ipairs( to_merge ) do
			find_flat_land.merge_segments( segment_list, segment_id, neighbour_id );
		end
		-- only for statistical purposes
		if( not( segment_list[ segment_id ].merge )) then
			anz_segments = anz_segments + 1;
		else
			anz_merged = anz_merged + 1;
		end
	end
	--print("anz_segments after same-height-merge: "..tostring( anz_segments ).." merged: "..tostring(anz_merged));
	return segment_list;
end


-- sets segment_list[ segment_id ].is_local_lowest and segment_list[ segment_id ].is_local_highest to true
-- for those segments that are the topmost at a mountain or the bottommost in a hole
find_flat_land.identify_local_highest_and_lowest_segment = function( heightmap, minp, maxp, segment, segment_list )
	-- identify local minima and maxima
	for segment_id,segment_data in ipairs( segment_list ) do
		segment_list[ segment_id ].is_local_highest = true;
		segment_list[ segment_id ].is_local_lowest = true;
		-- store at which height the segments above/below are located
		segment_list[ segment_id ].next_lower_at  =  1000;
		segment_list[ segment_id ].next_higher_at = -1000;
		local height = heightmap[ segment_data.starts_at ];
		for neighbour_id,_ in pairs( segment_data.neighbours ) do
			local height2 = heightmap[ segment_list[ neighbour_id ].starts_at ];
			-- detect segments with the same height
			if(     height < height2 ) then
				segment_list[ segment_id ].is_local_highest = false;
			elseif( height > height2 ) then
				segment_list[ segment_id ].is_local_lowest = false;
			end
			if(     height2 > height and height2 < segment_list[ segment_id ].next_higher_at) then
				segment_list[ segment_id ].next_higher_at = height2;
			elseif( height2 < height and height2 > segment_list[ segment_id ].next_lower_at) then
				segment_list[ segment_id ].next_lower_at = height2;
			end
		end
	end
	return segment_list;
end
