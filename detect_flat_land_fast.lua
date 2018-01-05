
-- works on the heightmap obtained in register.on_generated;
-- returns all places where a flat area with dimensions lookfor_x_dim and
--    lookfor_z_dim exists
-- Returns: { places_x = array, places_z }
--          with places_x: indices in heightmap where the previous
--                         lookfor_x_dim x lookfor_z_dim nodes are flat
--          and  places_z: indices in heightmap where the previous
--                         lookfor_z_dim x lookfor_x_dim nodes are flat
-- minheight and maxheight determine weather places will be acceptable
--   and returned; use it to i.e. get no places under water
find_flat_land.find_flat_land_fast = function( heightmap, minp, maxp, lookfor_x_dim, lookfor_z_dim, minheight, maxheight )

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
	local places_x = {}; -- lookfor_x_dim x lookfor_z_dim is flat
	local places_z = {}; -- lookfor_z_dim x lookfor_x_dim is flat

	-- the last zrun[ ax ] blocks in this column all had the same height
	local zrun = {};
	local chunksize = maxp.x-minp.x+1;
	-- the last count blocks in this row had the same height
	local count=1;
	-- how many zrun[ ax ] values (columns) had the right height value
	-- up until now?
	local check_before = 0;

	-- last height in x direction
	local lastheight = -1;
        local i = 0;
	local ax = 0;
 	local az = 0;

	-- identify and mark places that are flat areas of the required size
	for az=minp.z,maxp.z do
	for ax=minp.x,maxp.x do
		i = i+1;

		local height = heightmap[ i ];
		-- fallback if no height is provided
		if( not(height)) then
			height = 0;
		end

		if( height==lastheight and ax>minp.x) then
			count = count+1;
		else
			count = 1;
			-- new height - start new before-check
			check_before = 0;
		end
		lastheight = height;

		-- count in z direction as well
		local height2 = heightmap[ i-chunksize ];
		if( not(height2)) then
			height2 = 0;
		end
		-- it is enough to remember the last row in zrun
		if( height==height2 and az>minp.z) then
			zrun[ ax ] = zrun[ ax ]+1;
		else
			zrun[ ax ] = 1;
		end

		-- the candidates before this one have to have enough space
		-- as well
		if( zrun[ ax ]    >= lookfor_z_dim ) then
			check_before = check_before + 1;
		else
			check_before = 1;
		end
		if(     count     >= lookfor_x_dim
		 and check_before >= lookfor_x_dim
	         and zrun[ ax ]   >= lookfor_z_dim
		 and height >= minheight
		 and height <= maxheight
		 and height < maxp.y 
		 and height > minp.y) then
			table.insert( places_x, i );
		-- the place might fit if the building is rotated by 90 degree
		elseif( count     >= lookfor_z_dim
		 and check_before >= lookfor_z_dim
	         and zrun[ ax ]   >= lookfor_x_dim
		 and height >= minheight
		 and height <= maxheight
		 and height < maxp.y
		 and height > minp.y) then
			table.insert( places_z, i );
		end
	end
	end
	return {places_x=places_x, places_z=places_z};
end
