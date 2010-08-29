
-- jiujitsu: et pots tornar transparent per un moment,
-- pero no funciona si t'estas movent

function load()

	mytext=""

	math.randomseed(os.time())

	-- Init graphics mode
    screensize = { 800, 600 }
	if not love.graphics.setMode( screensize[1], screensize[2], true, true, 0 ) then
		love.system.exit()
	end

	-- Colors
	Colors = {
		love.graphics.newColor(0,100,200),
		love.graphics.newColor(0,200,100),
		love.graphics.newColor(100,200,0),
		love.graphics.newColor(200,100,0),
		love.graphics.newColor(100,0,200),
		love.graphics.newColor(200,0,100),
	}

	love.graphics.setBackgroundColor( 0, 50, 100 )

	playerOne = {
		pos = { 100, 100 },
		dir = {0,0},
		mov = {0,0},
		speed = 700,
		size = { 28, 48 },
		color = Colors[1],
		transparent = 0,
		transparent_pressed = false,
		transparent_charge = 0,
		dead = false
	}
	playerTwo = {
		pos = { 700, 500 },
		dir = {0,0},
		mov = {0,0},
		speed = 700,
		size = { 28, 48 },
		color = Colors[2],
		transparent = 0,
		transparent_pressed = false,
		transparent_charge = 0,
		dead = false
	}
	damp = -math.log(0.1)
	minmov = 1/playerOne.speed
	transparent_time = 0.5
	charge_time = 2.5

	entities = { playerOne, playerTwo }

	-- font
	font = love.graphics.newFont(love.default_font)
	love.graphics.setFont(font)

	-- light spots
	spots = {}

	-- sprites
	sprites = {
		vampireone_normal = love.graphics.newImage("images/vampireone_horz.png"),
		vampireone_trans = love.graphics.newImage("images/vampireone_horz_trans.png"),
		vampiretwo_normal = love.graphics.newImage("images/vampiretwo_horz.png"),
		vampiretwo_trans = love.graphics.newImage("images/vampiretwo_horz_trans.png"),
	}
	-- animations
	anims = {
		vampireone_normal = love.graphics.newAnimation(sprites.vampireone_normal,28,48,0.06,2),
		vampireone_trans = love.graphics.newAnimation(sprites.vampireone_trans,28,48,0.06,2),
		vampiretwo_normal = love.graphics.newAnimation(sprites.vampiretwo_normal,28,48,0.06,2),
		vampiretwo_trans = love.graphics.newAnimation(sprites.vampiretwo_trans,28,48,0.06,2),
	}

	menu = true

end

function myprint(st)
	mytext = mytext..st.."\n"
end

function update(dt)
	if menu then return end
	if playerOne.dead or playerTwo.dead then return end
	updatePlayer(dt, playerOne)
	updatePlayer(dt, playerTwo)
	updateSpot(dt)
--~ 	checkCrash( dt )

	local moduleone = playerOne.mov[1]*playerOne.mov[1]+playerOne.mov[2]*playerOne.mov[2]
	local moduletwo = playerTwo.mov[1]*playerTwo.mov[1]+playerOne.mov[2]*playerOne.mov[2]
	anims.vampireone_normal:update(dt *moduleone)
	anims.vampireone_trans:update(dt *moduleone)
	anims.vampiretwo_normal:update(dt*moduletwo)
	anims.vampiretwo_trans:update(dt *moduletwo)
end

function updatePlayer( dt, player )
	local  d = math.exp(-damp * dt)
	player.mov = {
		player.mov[1]*d + player.dir[1]*(1-d),
		player.mov[2]*d + player.dir[2]*(1-d) }
	if math.abs(player.mov[1])<minmov then player.mov[1]=0 end
	if math.abs(player.mov[2])<minmov then player.mov[2]=0 end
	oldpos = {player.pos[1],player.pos[2]}
	player.pos = {
		player.pos[1] + dt * player.speed * player.mov[1],
		player.pos[2] + dt * player.speed * player.mov[2]
	}

	if player.pos[1]<0 then player.pos[1] = player.pos[1]+screensize[1]-player.size[1] end
	if player.pos[1]+player.size[1]>screensize[1] then player.pos[1] = player.pos[1] - screensize[1] + player.size[1] end
	if player.pos[2]<0 then player.pos[2] = player.pos[2]+screensize[2]-player.size[2] end
	if player.pos[2]+player.size[2]>screensize[2] then player.pos[2] = player.pos[2] - screensize[2] + player.size[2] end

	if checkCrash(dt) then
		player.pos={oldpos[1],oldpos[2]}
	end

	if player.transparent > 0 then
		player.transparent = player.transparent - dt
	end

	if player.transparent_charge > 0 then
		player.transparent_charge = player.transparent_charge - dt
	end

	checkDeath(player)
end

function checkCrash( dt )

	if playerOne.transparent > 0 or playerTwo.transparent > 0 then return false end
	-- check if player one and two crash
	if playerOne.pos[1] < playerTwo.pos[1]+playerTwo.size[1] and
		playerOne.pos[1]+playerOne.size[1] > playerTwo.pos[1] and
		 playerOne.pos[2] < playerTwo.pos[2]+playerTwo.size[2] and
		playerOne.pos[2]+playerOne.size[2] > playerTwo.pos[2] then

		-- in that case, exchange velocities
		local tmp = {playerTwo.mov[1],playerTwo.mov[2]}
		playerTwo.mov = { playerOne.mov[1], playerOne.mov[2] }
		playerOne.mov = { tmp[1], tmp[2] }

		return true

	end

	return false

end

function draw()
	if menu then
		love.graphics.setColor(0,100,200)
		love.graphics.draw("Vampiric Hate - A two player game", 50,100)
		love.graphics.draw("   After centuries together, Vladimir and Mordrice hate each other and have decided to finish each other's undead life.\nThe old roof of their castle is starting to tear down.  Sunshine spots grow here and there.\nEach one of them is trying to push each other into the light. Only one can survive.\nVladimir's keys: cursors for movement, L for turning transparent.\nMordrice's keys:WASD for movement, 1 for turning transparent.\nPress ENTER to start. ESC to exit at any time",50,150)
		return
	end

	for i,spot in ipairs(spots) do
		local fraction = ((spot.radius/spot.final_radius)*0.8+0.2)*255
		if fraction>255 then fraction=255 end
		love.graphics.setColor( 200, 200, 0, fraction )
		love.graphics.circle(love.draw_fill, spot.pos[1], spot.pos[2], spot.radius, 32)
	end

	if not playerOne.dead then
		local px,py = math.floor(playerOne.pos[1]+playerOne.size[1]/2),math.floor(playerOne.pos[2]+playerOne.size[2]/2)
		if playerOne.transparent > 0 then
			if playerOne.mov[1]>=0 then
			love.graphics.draw( anims.vampireone_trans, px, py)
			else
			love.graphics.draw( anims.vampireone_trans, px, py,0,-1,1)
			end
		else
			if playerOne.mov[1]>=0 then
			love.graphics.draw( anims.vampireone_normal, px, py)
			else
			love.graphics.draw( anims.vampireone_normal, px, py,0,-1,1)
			end
		end
	end

	if not playerTwo.dead then
		local px,py = math.floor(playerTwo.pos[1]+playerTwo.size[1]/2),math.floor(playerTwo.pos[2]+playerTwo.size[2]/2)
		if playerTwo.transparent > 0 then
			if playerTwo.mov[1]>=0 then
			love.graphics.draw( anims.vampiretwo_trans, px, py)
			else
			love.graphics.draw( anims.vampiretwo_trans, px, py,0,-1,1)
			end
		else
			if playerTwo.mov[1]>=0 then
			love.graphics.draw( anims.vampiretwo_normal, px, py)
			else
			love.graphics.draw( anims.vampiretwo_normal, px, py,0,-1,1)
			end
		end
	end

	love.graphics.setColor( playerOne.color )
	love.graphics.draw(mytext,0,40)

	love.graphics.setColor(200,0,50)
	if playerOne.dead then
		love.graphics.draw("Vladimir died!  Mordrice wins!", 280,240)
		love.graphics.draw("Enter to restart", 280,260)
	end
	if playerTwo.dead then
		love.graphics.draw("Mordrice died!  Vladimir wins!", 280,240)
		love.graphics.draw("Enter to restart", 280,260)
	end

end


function keypressed(key)
	if key == love.key_escape then
		love.system.exit()
	end

	-- player one movement
	if key == love.key_up then
		playerOne.dir[2] = -1
	end
	if key == love.key_down then
		playerOne.dir[2] = 1
	end
	if key == love.key_left then
		playerOne.dir[1] = -1
	end
	if key == love.key_right then
		playerOne.dir[1] = 1
	end
	if key == love.key_l then
		setTransparent(playerOne)
	end

	-- player two movement
	if key == love.key_w then
		playerTwo.dir[2] = -1
	end
	if key == love.key_s then
		playerTwo.dir[2] = 1
	end
	if key == love.key_a then
		playerTwo.dir[1] = -1
	end
	if key == love.key_d then
		playerTwo.dir[1] = 1
	end
	if key == love.key_1 then
		setTransparent(playerTwo)
	end

	if key == love.key_return then
		if menu then menu = false else
		if playerOne.dead or playerTwo.dead then
			playerOne.pos = { 100, 100 }
			playerTwo.pos = { 700, 500 }
			playerOne.dead = false
			playerTwo.dead = false
			spots = {}
		end
		end
	end

end

function setTransparent( player )
	if player.transparent > 0 then return end
	if player.transparent_pressed then return end
	if player.transparent_charge > 0 then return end
	if math.abs(player.mov[1])>minmov*10 or math.abs(player.mov[2])>minmov*10 then return end
	player.transparent_pressed = true
	player.transparent = transparent_time
	player.transparent_charge = charge_time
end

function keyreleased(key)
	if key == love.key_up or key == love.key_down then
		playerOne.dir[2] = 0
	end
	if key == love.key_left or key == love.key_right then
		playerOne.dir[1] = 0
	end
	if key == love.key_w or key == love.key_s then
		playerTwo.dir[2] = 0
	end
	if key == love.key_a or key == love.key_d then
		playerTwo.dir[1] = 0
	end

	if key == love.key_l then
		playerOne.transparent_pressed = false
	end
	if key == love.key_1 then
		playerTwo.transparent_pressed = false
	end
end


function mousepressed(x, y, button)

end


function mousereleased(x, y, button)

end

---------------------------------------------------------------------------------------------------
-- sunshine
function chooseSpot()
	local newspot = {
		pos = {math.random(screensize[1]), math.random(screensize[2])},
		radius = 0,
		final_radius = math.random(350),
	}

	table.insert(spots,newspot)

end

function updateSpot(dt)
	local n = table.getn(spots)
	if n==0 then chooseSpot() else
		spots[n].radius = spots[n].radius + dt*10
		if spots[n].radius >= spots[n].final_radius then chooseSpot() end
	end
end

function checkDeath(player)
	local borders = 5
	for i,spot in ipairs(spots) do
		if checkspot(spot,{player.pos[1]+borders,player.pos[2]+borders}) or
		checkspot(spot,{player.pos[1]+player.size[1]-borders,player.pos[2]+borders}) or
		checkspot(spot,{player.pos[1]+borders,player.pos[2]+player.size[2]-borders}) or
		checkspot(spot,{player.pos[1]+player.size[1]-borders,player.pos[2]+player.size[2]-borders}) then
			player.dead = true
			return
		end
	end
end

function checkspot(spot, point)
	local dx = point[1]-spot.pos[1]
	local dy = point[2]-spot.pos[2]
	local distq = dx*dx+dy*dy
	if distq < spot.radius*spot.radius then return true else return false end
end
-- spot appears randomly
-- grows slowly until a maximum radius
-- opacity also changes gradually
-- if someone falls in, she dies
