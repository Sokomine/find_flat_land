
-- locate a place for the "hut" and place it
find_flat_land.simple_hut_find_place_and_build = function( heightmap, minp, maxp, sizex, sizez, minheight, maxheight )

	local res = find_flat_land.find_flat_land_fast( heightmap, minp, maxp, sizex, sizez, minheight, maxheight );
--	print( "Places found of size "..tostring( sizex ).."x"..tostring(sizez)..": "..tostring( #res.places_x )..
--			       " and "..tostring( sizez ).."x"..tostring(sizex)..": "..tostring( #res.places_z )..
--		".");

	if( (#res.places_x + #res.places_z )< 1 ) then
--		print( "  Aborting. No place found.");
		return false;
	end

	-- select a random place - either sizex x sizez or sizez x sizex
	local c = math.random( 1, #res.places_x + #res.places_z );
	local i = 1;
	if( c > #res.places_x ) then
		i = res.places_z[ c-#res.places_x ];
		-- swap x and z due to rotation of 90 or 270 degree
		local tmp = sizex;
		sizex = sizez;
		sizez = tmp;
		tmp = nil;
	else
		i = res.places_x[ c ];
	end

	local chunksize = maxp.x - minp.x + 1;
	-- translate index back into coordinates
	local p = {x=minp.x+(i%chunksize)-1, y=heightmap[ i ], z=minp.z+math.floor(i/chunksize)};

	local wood_types = {"", "jungle", "acacia_", "aspen_", "pine_"};
	local wood  = wood_types[ math.random( #wood_types )];
	local wood1 = wood_types[ math.random( #wood_types )];
	local wood2 = wood_types[ math.random( #wood_types )];
	local wood3 = wood_types[ math.random( #wood_types )];
	local materials = {
		walls = "default:"..wood1.."tree", --"default:"..wood1.."wood",
		floor = "default:brick",
		gable = "default:"..wood2.."wood",
		ceiling = "default:"..wood3.."wood",
		roof = "stairs:stair_"..wood.."wood",
		roof_middle = "stairs:slab_"..wood.."wood",
		glass = "xpanes:pane_flat", --"default:glass",
		};
	find_flat_land.simple_hut_place_hut( p, sizex, sizez, materials );
end

-- actually build the "hut"
find_flat_land.simple_hut_place_hut = function( p, sizex, sizez, materials )

	sizex = sizex-1;
	sizez = sizez-1;
	-- house too small or too large
	if( sizex < 3 or sizez < 3 or sizex>64 or sizez>64) then
		return;
	end

	print( "  Placing house at "..minetest.pos_to_string( p ));
	-- where the plot starts
	minetest.set_node( p, {name="default:meselamp"});

	local window_at_height = {0,0,0,0,0};
	local r = math.random(1,6);
	if(     r==1 or r==2) then
		window_at_height = {0,1,1,1,0};
	elseif( r==3 or r==4 or r==5) then
		window_at_height = {0,0,1,1,0};
	else
		window_at_height = {0,0,1,0,0};
	end
	local window_at_odd_row = false;
	if( math.random(1,2)==1 ) then
		window_at_odd_row = true;
	end

	local dz = p.z;
	for dx = p.x-sizex+1, p.x-1 do
	local m1 = materials.walls;
	local m2 = materials.walls;
	if( dx>p.x-sizex+1 and dx<p.x-2 and (window_at_odd_row == (dx%2==1))) then
		if( math.random(1,2)==1) then
			m1 = materials.glass;
		end
		if( math.random(1,2)==1) then
			m2 = materials.glass;
		end
	end
	for dy = p.y, p.y+4 do
		-- build two walls in x direction
		if( window_at_height[ dy-p.y+1 ]==1 ) then
			minetest.set_node( {x=dx,y=dy,z=dz-1      }, {name=m1, param2=12});
			minetest.set_node( {x=dx,y=dy,z=dz-sizez+1}, {name=m2, param2=18});
		else
			minetest.set_node( {x=dx,y=dy,z=dz-1      }, {name=materials.walls, param2=12});
			minetest.set_node( {x=dx,y=dy,z=dz-sizez+1}, {name=materials.walls, param2=18});
		end
	end
	end
	local dx = p.x;
	for dz = p.z-sizez+1, p.z-1 do
	local m1 = materials.walls;
	local m2 = materials.walls;
	if( dz>p.z-sizez+1 and dz<p.z-2 and ( window_at_odd_row == (dz%2==1))) then
		if( math.random(1,2)==1) then
			m1 = materials.glass;
		end
		if( math.random(1,2)==1) then
			m2 = materials.glass;
		end
	end
	for dy = p.y, p.y+4 do
		-- build two walls in z direction
		if( window_at_height[ dy-p.y+1 ]==1 ) then
			minetest.set_node( {x=dx-1,      y=dy,z=dz}, {name=m1, param2=9});
			minetest.set_node( {x=dx-sizex+1,y=dy,z=dz}, {name=m2, param2=7});
		else
			minetest.set_node( {x=dx-1,      y=dy,z=dz}, {name=materials.walls, param2=9});
			minetest.set_node( {x=dx-sizex+1,y=dy,z=dz}, {name=materials.walls, param2=7});
		end
	end
	end

	local do_ceiling = ( math.min( sizex, sizez )>4 );
	-- floor and ceiling
	for dx = p.x-sizex+2, p.x-2 do
	for dz = p.z-sizez+2, p.z-2 do
		-- a brick roof
		minetest.set_node( {x=dx,y=p.y,  z=dz}, {name=materials.floor});
		if( do_ceiling ) then
			minetest.set_node( {x=dx,y=p.y+4,z=dz}, {name=materials.ceiling});
		end
	end
	end

	-- we need a door
	local door_pos = {x=p.x-1, y=p.y+1, z=p.z-1};
	local r = math.random(1,4);
	-- door is in x wall
	if( r==1 or r==2 ) then
		door_pos.x = math.random( p.x-sizex+2, p.x-2 );
		if( r==2 ) then
			door_pos.z = p.z-sizez+1;
		else
			door_pos.z = p.z-1;
		end
	-- dor is in z wall
	else
		door_pos.z = math.random( p.z-sizez+2, p.z-2 );
		if( r==2 ) then
			door_pos.x = p.x-sizex+1;
		else
			door_pos.x = p.x-1;
		end
	end
	minetest.set_node( door_pos, {name="doors:door_wood_a", param2 = 0 });
	minetest.set_node( {x=door_pos.x, y=door_pos.y+1, z=door_pos.z}, {name="doors:hidden"});
	-- light so that the door can be found
	minetest.set_node( {x=door_pos.x, y=door_pos.y+2, z=door_pos.z}, {name="default:meselamp"});

	-- roof
	if( sizex <= sizez ) then
		local xhalf = math.floor( sizex/2 );
		dy = p.y+5;
		for dx = 0,xhalf do
		for dz = p.z-sizez, p.z do
			minetest.set_node( {x=p.x-sizex+dx,y=dy,z=dz}, {name=materials.roof, param2=1});
			minetest.set_node( {x=p.x-      dx,y=dy,z=dz}, {name=materials.roof, param2=3});
		end
		dy = dy+1;
		end

		-- if sizex is not even, then we need to use slabs at the heighest point
		if( sizex%2==0 ) then
		for dz = p.z-sizez, p.z do
			minetest.set_node( {x=p.x-xhalf,y=p.y+6+xhalf-1,z=dz}, {name=materials.roof_middle});
		end
		end
	
		-- Dachgiebel (=gable)
		for dx = 0,xhalf do
		for dy = p.y+5, p.y+4+dx do
			minetest.set_node( {x=p.x-sizex+dx,y=dy,z=p.z-sizez+1}, {name=materials.gable});
			minetest.set_node( {x=p.x-      dx,y=dy,z=p.z-sizez+1}, {name=materials.gable});
	
			minetest.set_node( {x=p.x-sizex+dx,y=dy,z=p.z      -1}, {name=materials.gable});
			minetest.set_node( {x=p.x-      dx,y=dy,z=p.z      -1}, {name=materials.gable});
		end
		end
	else
		local zhalf = math.floor( sizez/2 );
		dy = p.y+5;
		for dz = 0,zhalf do
		for dx = p.x-sizex, p.x do
			minetest.set_node( {x=dx,y=dy,z=p.z-sizez+dz}, {name=materials.roof, param2=0});
			minetest.set_node( {x=dx,y=dy,z=p.z-      dz}, {name=materials.roof, param2=2});
		end
		dy = dy+1;
		end

		-- if sizex is not even, then we need to use slabs at the heighest point
		if( sizez%2==0 ) then
		for dx = p.x-sizex, p.x do
			minetest.set_node( {x=dx,y=p.y+6+zhalf-1,z=p.z-zhalf}, {name=materials.roof_middle});
		end
		end
	
		-- Dachgiebel (=gable)
		for dz = 0,zhalf do
		for dy = p.y+5, p.y+4+dz do
			minetest.set_node( {x=p.x-sizex+1,y=dy,z=p.z-sizez+dz}, {name=materials.gable});
			minetest.set_node( {x=p.x-sizex+1,y=dy,z=p.z-      dz}, {name=materials.gable});
	
			minetest.set_node( {x=p.x      -1,y=dy,z=p.z-sizez+dz}, {name=materials.gable});
			minetest.set_node( {x=p.x      -1,y=dy,z=p.z-      dz}, {name=materials.gable});
		end
		end
	end
		
	return true;
end

find_flat_land.simple_hut_generate = function( heightmap, minp, maxp)
	-- halfway reasonable house sizes
	local maxsize = 14;
	if( math.random(1,5)==1) then
		maxsize = 18;
	end
	local sizex = math.random(7,maxsize);
	local sizez = math.max( 7, math.min( maxsize, math.random( math.floor(sizex/4), sizex*2 )));
	-- chooses random materials and a random place without destroying the landscape
	-- minheight 2: one above water level; avoid below water level and places on ice
	find_flat_land.simple_hut_find_place_and_build( heightmap, minp, maxp, sizex, sizez, 2, 1000 );
end


