
-- assigns a segment value to each point in the heightmap;
-- detects regional extrema (mountain peaks, bottoms of valleys)
find_flat_land.detect_local_extrema = function( heightmap, minp, maxp )

	-- if a segment looses membership of segment_is_local_maximum or
	-- of segment_is_local_minium (passed on in the parameter min_or_max),
	-- all segments that have been merged with this segment so far will
	-- also loose the membership;
	-- the membership of segment_id inclusive all segments merged with
	-- egment_id in min_or_max will be revoked
	local update_incl_merged = function( segment_id, merged, min_or_max )
		local m;
		if( merged[ segment_id ]) then
			for m,_ in pairs( merged[ segment_id ] or {}) do
				min_or_max[ m ] = false;
			end
		end
		min_or_max[ segment_id ] = nil;
	end


	local segment = {};

	-- sometimes segments which are connected get diffrent segment_ids due to the
	-- way the algorithm works; those segments need to be merged.
	-- only merges of candidates for local maximum and minimum are stored
	-- (the rest of the segments is of not much intrest)
	local merged = {};

	-- into which other segment has this one been merged?
	-- merged_into_other[ a ] = b means: a has been merged into b
	local merged_into_other = {};

	-- each segment needs a uniq number
	local segment_nr = 0;

	-- this is what we are actually intrested in (mountain tops, bottoms of valleys)
	local segment_is_local_maximum = {};
	local segment_is_local_minimum = {};

	-- a height value that cannot occour
	local lastheight    = -1000;
	local lastrowheight = -1000;

	local chunksize = maxp.x-minp.x+1;
	-- iterate over the entire heightmap
	-- mark areas with the same height (based on 4-connected)
        local i = 0;
	for az=minp.z,maxp.z do
	for ax=minp.x,maxp.x do
		i = i+1;
		local height = heightmap[i];
		if( not(height) ) then
			height = -1000;
		end
		if( i>chunksize ) then
			lastrowheight = heightmap[ i-chunksize ];
		end

		local last_col_segment = segment[ i-1 ];
		local last_row_segment = segment[ i-chunksize ];
		-- does this node belong to the segment below (at x-1,z)?
		if(     height == lastheight and (ax>minp.x)) then
			segment[ i ] = last_col_segment;
		-- does this node belong to the segment to the right (at x,z-1)?
		elseif( height == lastrowheight and (az>minp.z)) then
			segment[ i ] = last_row_segment;
		-- or is it a new segment?
		else 
			-- increment the segment counter
			segment_nr = segment_nr + 1;
			-- this height value belongs to the new segment
			segment[ i ] = segment_nr;

			-- the new segment might be a regional minimum or maximum;
			-- but only if it is not at the border of our mapchunk
			-- (we have no idea how the segment will continue in other
			-- mapchunks)
			if( ax>minp.x and az>minp.z and ax<maxp.x and az<maxp.z ) then
				-- if this new segment is lower than those around it, it is
				-- a valid candidate for local minimum; weather it really is
				-- one or not can only be checked later on
				if(     height < lastheight and height < lastrowheight ) then
					segment_is_local_minimum[ segment[ i ] ] = true;
				-- if it is higher, then it is a candidate for local maximum
				elseif( height > lastheight and height > lastrowheight ) then
					segment_is_local_maximum[ segment[ i ] ] = true;
				-- else the segment definitely is neither maximum nor minimum
				end
			end
		end

		local this_segment = segment[ i ];

		-- if this node is LOWER than the one at (x-1,z), then...
		-- (or if it is at the border of the mapchunk)
		if( last_col_segment or ax==maxp.x) then
			if(     height < lastheight) then
				-- the segment containing the node at (x-1,z) cannot be a local minimum
				update_incl_merged( last_col_segment, merged, segment_is_local_minimum );
				-- this segment cannot be a local maximum
				update_incl_merged( this_segment,     merged, segment_is_local_maximum );
			-- if this node is HIGHER than the one at (x-1,z), then...
			elseif( height > lastheight ) then
				-- the segment containing the node at (x-1,z) cannot be a local maximum
				update_incl_merged( last_col_segment, merged, segment_is_local_maximum );
				-- this segment cannot be a local minimum
				update_incl_merged( this_segment,     merged, segment_is_local_minimum );
			end
		end

		-- do the same for the node at (x,z-1)
		if( last_row_segment or az==maxp.z) then
			if(     height < lastrowheight) then
				update_incl_merged( last_row_segment, merged, segment_is_local_minimum );
				update_incl_merged( this_segment,     merged, segment_is_local_maximum );
			elseif( height > lastrowheight) then
				update_incl_merged( last_row_segment, merged, segment_is_local_maximum );
				update_incl_merged( this_segment,     merged, segment_is_local_minimum );

			-- special case: if (x,z-1) has the same height but is part of
			-- a diffrent segment, then the segments need to be merged
			elseif( height == lastrowheight
			    and this_segment ~= last_row_segment
			    and ( not( merged[ this_segment ])
			       or not( merged[ this_segment ][ last_row_segment ]))) then

				-- remember the merge
				if( not( merged[ this_segment ])) then
					merged[ this_segment ] = {};
				end
				merged[ this_segment ][ last_row_segment ] = true;
				for m,_ in pairs( merged[ last_row_segment ] or {}) do
					merged[ this_segment ][ m ] = true;
					merged_into_other[ m ] = this_segment;
				end
				merged_into_other[ last_row_segment ] = this_segment;

				-- if the to-be-merged segment has already been determined *not* to
				-- be a local maximum or minimum, then this segment likewise cannot
				-- be such a minimum or maximum
				if(     not( segment_is_local_maximum[ last_row_segment ])) then
					update_incl_merged( this_segment, merged, segment_is_local_maximum );
				-- if the segment at (x,z-1) believed it was a maximum, but this segment
				-- here is to be merged with it and is *not* a maximum, then we need
				-- to propagate this update down to all segments the one at (x,z-1)
				-- had been merged with
				elseif( not( segment_is_local_maximum[ this_segment ])) then
					update_incl_merged( last_row_segment, merged, segment_is_local_maximum );
				end

				-- same for local minimum
				if( not( segment_is_local_minimum[ last_row_segment ])) then
					segment_is_local_minimum[ this_segment ] = nil;
				elseif( not( segment_is_local_minimum[ this_segment ])) then
					update_incl_merged( last_row_segment, merged, segment_is_local_minimum );
				end
			end
		end


		lastheight = height;
		if( ax==maxp.x ) then
			lastheight = -1000;
		end
	end
	end

	return { segment = segment, maxima = segment_is_local_maximum, minima = segment_is_local_minimum,
			merged = merged_into_other  };
end


-- puts node_name_for_minimum at the bottom of valleys,
-- puts node_name_for_maximum at the top of mountains,
--
-- returns a changed heightmap:
--   bottoms of valleys are raised by 1 m
--   mountain tops are lowered by 1 m
--
-- the parameter data is the return value from the function
--  find_flat_land.detect_local_extrema(..)
find_flat_land.visualize_extrema = function( heightmap, minp, maxp, orig_heightmap, data, node_name_for_minimum, node_name_for_maximum  )
	local heightmap2 = {};
	-- copy the old heightmap 
	for i,h in pairs( heightmap ) do
		heightmap2[ i ] = h;
	end

        local i = 0;
	for az=minp.z,maxp.z do
	for ax=minp.x,maxp.x do
		i = i+1;
		local segment_id = data.segment[ i ];
		local height = heightmap[i];
--[[
		-- color segments
		if( data.merged[ segment_id ]) then
			segment_id = data.merged[ segment_id ];
		end
		minetest.set_node( {x=ax, y=height, z=az}, {name="find_flat_land:segment", param2 = segment_id%256});
--]]

		if(     data.minima[ segment_id ]) then
			-- do not really fill the bottoms of valleys - just illustrate it
			if( orig_heightmap[ i ] >= height and node_name_for_minimum) then
				minetest.set_node( {x=ax, y=height, z=az}, {name=node_name_for_minimum, param2 = 0});
			end
			heightmap2[ i ] = height+1;

		elseif( data.maxima[ segment_id ]) then
			if( node_name_for_maximum ) then
				minetest.set_node( {x=ax, y=height, z=az}, {name=node_name_for_maximum, param2 = 0});
			end
			heightmap2[ i ] = height-1;
		end
	end
	end
	return heightmap2;
end
