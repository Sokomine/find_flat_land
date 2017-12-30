
-- TODO: combine both functions into one

-- count how many subsequent nodes have the same height in a row in x
-- direction (xrun) and in a column in z direction (zrun)
find_flat_land.do_same_height_count = function( heightmap, minp, maxp )
	-- what the function will return; an entry of n in one of these
	-- arrays means that the last n blocks in this row (xrun) or
	-- column (zrun) all had the same height
	local xrun = {};
	local zrun = {};
	local chunksize = maxp.x-minp.x+1;
	-- how many blocks had the same height in this row (xrun) or
	-- column (zrun) already?
	local count=1;
	-- last height in x direction
	local lastheight = -1;
        local i = 0;
	local ax = 0;
 	local az = 0;
	for az=minp.z,maxp.z do
	for ax=minp.x,maxp.x do
		i = i+1;
		local height = heightmap[ i ];
		-- no point in detecting sea level
		if( not(height)) then
			height = 0;
		end

		if( height==lastheight and ax>minp.x) then
			count = count+1;
		else
			count = 1;
		end
		xrun[ i ] = count;
		lastheight = height;

		-- count in z direction as well
		local height2 = heightmap[ i-chunksize ];
		if( not(height2)) then
			height2 = 0;
		end
		if( height==height2 and az>minp.z) then
			zrun[ i ] = zrun[ i-chunksize ]+1;
		else
			zrun[ i ] = 1;
		end
	end
	end
	return {xrun=xrun, zrun=zrun};
end


-- works on the data gained by the function do_same_height_count(..)
-- returns all places where a flat area with dimensions lookfor_x_dim and
--    lookfor_z_dim exists
-- Note: If you want to search for i.e. places with 5x7 nodes, you ought to
--       look for lookfor_x_dim=5 and lookfor_z_dim=7 AND also do a second
--       call to this function to look for lookfor_x_dim=7 and lookfor_z_dim=5
find_flat_land.search_for_flat_land = function( same_height_count,
		lookfor_x_dim, lookfor_z_dim,
		heightmap, minp, maxp )
	-- return empty result if search is invalid
	if(  lookfor_x_dim < 1
	  or lookfor_z_dim < 1
	  -- we can't handle more than one mapchunk at a time this way
	  or lookfor_x_dim > (maxp.x - minp.x - 2)
	  or lookfor_z_dim > (maxp.z - minp.z - 2)) then
		return {};
	end
	-- the return value; will contain the indices (of heightmap) where the
	-- searched for flat space exists
	local places = {};
	-- identify and mark places that are flat areas of the required size
	local i = 0;
	local ax = 0;
	local az = 0;
	local check_before = 0;
	for az=minp.z,maxp.z do
	for ax=minp.x,maxp.x do
		i = i+1;
		local height = heightmap[ i ];
		-- new height - start new before-check
		if( same_height_count.xrun[ i ]==1 ) then
			check_before = 0;
		end
		-- the candidates before this one have to have enough space
		-- as well
		if( same_height_count.zrun[ i ]>= lookfor_z_dim ) then
			check_before = check_before + 1;
		else
			check_before = 1;
		end
		if(  same_height_count.xrun[ i ]>= lookfor_x_dim
	         and same_height_count.zrun[ i ]>= lookfor_z_dim
		 and check_before >= lookfor_x_dim
		 and height < maxp.y 
		 and height > minp.y) then
			table.insert( places, i );
--			minetest.set_node( {x=ax, y=height, z=az}, {name="default:mese"});
		end
	end
	end
	return places;
end
