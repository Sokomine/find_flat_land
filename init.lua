
find_flat_land = {};

dofile(minetest.get_modpath( minetest.get_current_modname() ).."/detect_flat_land.lua");
dofile(minetest.get_modpath( minetest.get_current_modname() ).."/detect_local_extrema.lua");

--- just a node that can be colored and thus visualize the created segments
minetest.register_node("find_flat_land:segment", {
	description = "Segment Indicator",
	tiles = {"default_clay.png"},
	is_ground_content = false,
	groups = {oddly_breakable_by_hand=3,cracky=3,snappy=3,sappy=3},
	paramtype2 = "color",
	palette = "unifieddyes_palette_extended.png",
	});

minetest.register_on_generated(function(minp, maxp, seed)
	-- the flat_area-detection works below sealevel as well
	if( minp.y < -64 or minp.y > 500) then
		return;
	end
 

	local heightmap = minetest.get_mapgen_object('heightmap');
	if( not( heightmap )) then
		return;
	end

	local t_last = minetest.get_us_time();
	local chunksize = maxp.x-minp.x+1;
	local res = find_flat_land.detect_local_extrema( heightmap, minp, maxp );
	-- turn bottom of valleys into yellow wool; turn mountain tops into orange wool
	local heightmap2 = find_flat_land.visualize_extrema( heightmap, minp, maxp, heightmap, res, nil, nil); --"wool:yellow","wool:orange");

	res = find_flat_land.detect_local_extrema( heightmap2, minp, maxp );
	-- turn layer one top of valley bottoms into mangeta wool; turn mountain layers one below top into cyan wool
	heightmap2 = find_flat_land.visualize_extrema( heightmap2, minp, maxp, heightmap, res, nil, nil); --"wool:magenta", "wool:cyan" );

	res = find_flat_land.detect_local_extrema( heightmap2, minp, maxp );
	-- turn layer two from valley bottoms into pink wool; turn mountain layers two below top into blue wool
	heightmap2 = find_flat_land.visualize_extrema( heightmap2, minp, maxp, heightmap, res, nil, nil); --"wool:pink", "wool:blue" );
--[[
	-- analyze how many subsequent blocks have the same height in each row and column
	local same_height_count = find_flat_land.do_same_height_count( heightmap2, minp, maxp );

	-- use the information gained from do_same_height_count(..) to identify places of intrest 	
	-- search for flat land of 8 in x and 7 in z direction
	local buildplace_list = find_flat_land.search_for_flat_land( same_height_count, 8, 7, heightmap2, minp, maxp );
	-- place a meselamp to indicate where such places are located
	for nr, i in pairs( buildplace_list ) do
		minetest.set_node( {x=minp.x+(i%chunksize)-1, y=heightmap2[ i ], z=minp.z+math.floor(i/chunksize)}, {name="default:meselamp"});
	end
--]]
	print( 'TIME ELAPSED: '..tostring( minetest.get_us_time() - t_last ) );
end);
