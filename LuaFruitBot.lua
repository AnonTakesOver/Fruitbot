--[[ Coding Style:
		Use semicolons when doing more then one function on the same line
		4 space tab indents

]]--

local badFruits = {}
local rareFruit = { tracking = false, item = 0, exists = false, x = 0, y = 0 }
local target = { acquired = false, x = 0, y = 0, item = 0, plyDistance = 99, oppDistance = 99 }

-- I like to create this in any code I do, it's just useful, even though I won't probably use it in this program, it's good to have it when I feel lazy.
function HasValue( tbl, v )
	for key,value in pairs(tbl) do
		if value == v then return true end
	end
	return false
end

function Distance( x1, x2, y1, y2 )
	return math.abs(x1 - x2) + math.abs(y1 - y2)
end

function AmountsToWin()
	local amount = get_number_of_item_types()
	if amount % 2 == 0 then
		local evenHalf = (amount / 2) + 1
		return evenHalf
	else
		local oddHalf = math.ceil(amount / 2)
		return oddHalf 
	end
end

function GetScore( isPly )
	local amountToWin = AmountsToWin()
	local totalItems = get_number_of_item_types()
	local score = 0
	for fruit = 1, totalItems do
		if AmountNeededToWin( fruit, isPly and get_my_item_count(fruit) or get_opponent_item_count(fruit) ) <= 0 then
			score = score + 1
		end
	end
	return score
end

function AmountNeededToWin( item, amount )
	local itemAmount = get_total_item_count(item)
	if itemAmount % 2 == 0 then			
		local evenHalf = (itemAmount / 2) + 1
		return evenHalf - amount
	else
		local oddHalf = math.ceil(itemAmount / 2)
		return oddHalf - amount
	end
end

function RankFruitTable( fruits )
	local fruitTable = fruits
	local plyX = get_my_x()
	local plyY = get_my_y()
	local plyScore = GetScore( true )
	local oppX = get_opponent_x()
	local oppY = get_opponent_x()
	local oppScore = GetScore( false )
	local amountToWin = AmountsToWin()
	for k,v in pairs(fruitTable) do
		v.rank = 0
		plyDistance = Distance(plyX, v.x, plyY, v.y )
		oppDistance = Distance(oppX, v.x, oppY, v.y )
		plyNeeded = AmountNeededToWin( v.item, get_my_item_count(v.item) )
		oppNeeded = AmountNeededToWin( v.item, get_opponent_item_count(v.item) )
		if plyDistance < oppDistance then v.rank = v.rank + 10 end
		if plyNeeded < oppNeeded then v.rank = v.rank + 10 end
		if plyNeeded == 1 then v.rank = v.rank + 10 end
		for dis = 1, 10 do
			if plyDistance <= dis then v.rank = v.rank + 3 end
		end
		if rareFruit.exists then if v.item == rareFruit.item then v.rank = v.rank + 20 end end 
		if plyNeeded == 1 and plyScore + 1 >= amountToWin then v.rank = v.rank + 50 end
		if oppNeeded == 1 and oppScore + 1 >= amountToWin then v.rank = v.rank + 50 end
	end
	return fruitTable
end

function AllFruits()
	-- All is used loosely, we mean the good fruits.
	local fruits = {}
	local board = get_board()
	for x = 0, WIDTH - 1 do
		for y = 0, HEIGHT - 1 do
			local field = board[x][y]
			if has_item(field) > 0 then
				local item = has_item(field)
				if not badFruits[item] then
					table.insert(fruits, { item = item, x = x, y = y } )
				end
			end
		end
	end
	return fruits
end

function ClosestFruit()
	local plyX = get_my_x()
	local plyY = get_my_y()
	local oppX = get_opponent_x()
	local oppY = get_opponent_x()
	local board = get_board()
	
	local closest = { oppDistance = 99, plyDistance = 99, x = 0, y = 0, item = 0 }
	for x = 0, WIDTH - 1 do
		for y = 0, HEIGHT - 1 do
			local field = board[x][y]
			if has_item(field) > 0 then
				local item = has_item(field)
				if not badFruits[item] then
					local itemAmount = get_total_item_count(item)
					local plyAmount =  get_my_item_count(item)
					local oppAmount =  get_opponent_item_count(item)
					local plyDistance = Distance(plyX, x, plyY, y)
					local oppDistance = Distance(oppX, x, oppY, y)
					if plyDistance < closest.plyDistance then
						closest.oppDistance = oppDistance
						closest.plyDistance = plyDistance
						closest.x = x
						closest.y = y
						closest.item = item
					end
				end
			end
		end
	end
	return closest
end

function BestFruit()
	local plyX = get_my_x()
	local plyY = get_my_y()
	local oppX = get_opponent_x()
	local oppY = get_opponent_x()
	if rareFruit.exists then -- If the rare fruit is in play, do this
		local plyDistance = Distance(plyX, rareFruit.x, plyY, rareFruit.y)
		local oppDistance = Distance(oppX, rareFruit.x, oppY, rareFruit.y)
		-- If I have a chance at getting the fruit, go for it, otherwise, fuck it.
		if plyDistance <= oppDistance then
			rareFruit.tracking = true
			if rareFruit.x < plyX then trace("Rare fruit is to the left, moving left"); return WEST end
			if rareFruit.y < plyY then trace("Rare fruit is above, moving up") return NORTH end
			if rareFruit.x > plyX then trace("Rare fruit is to the right, moving right"); return EAST end
			if rareFruit.y > plyY then trace("Rare fruit is below, moving down"); return SOUTH end
		end
		rareFruit.tracking = false
	end
	-- Get a table of info from the closest fruit and a table of all the fruit.
	local closest = ClosestFruit()
	local fruits = AllFruits()
	
	--[[ 
		Now we will rank each fruit, this will require an algorithm which will use the factors of distance from me, distance from opponent, 
		the amount needed to win for me and the amount needed to win for the opponent.
	]]--
	local rankedFruits = RankFruitTable( fruits )
	local highestRank = { rank = 0, item = 0, x = 0, y = 0 }
	for k,v in pairs( rankedFruits ) do
		trace(v.item.." at " .. v.x .. ":".. v.y .." has a rank of ".. v.rank)
		if v.rank > highestRank.rank then
			highestRank.rank = v.rank
			highestRank.item = v.item
			highestRank.x = v.x
			highestRank.y = v.y
		end
	end
	trace("Best fruit is "..highestRank.item.." with a ranking of "..highestRank.rank)
	if highestRank.x < plyX then trace("Best fruit is to the left, moving left"); return WEST end
	if highestRank.y < plyY then trace("Best fruit is above, moving up") return NORTH end
	if highestRank.x > plyX then trace("Best fruit is to the right, moving right"); return EAST end
	if highestRank.y > plyY then trace("Best fruit is below, moving down"); return SOUTH end
	trace("No movment..")
end

function WorthGetting( item )
	local plyX = get_my_x()
	local plyY = get_my_y()
	local oppX = get_opponent_x()
	local oppY = get_opponent_x()
	
	if badFruits[item] then return false end -- If it's a bad fruit, don't bother doing any checks.
	if item == rareFruit.item then rareFruit.exists = false; rareFruit.tracking = false; return TAKE end 
	trace("Tracking rare fruit: "..tostring(rareFruit.tracking))
	if rareFruit.tracking then
		-- If we are tracking the rare fruit, we better have a good excuse for picking up an item.
		local plyDistance = Distance(plyX, rareFruit.x, plyY, rareFruit.y)
		local oppDistance = Distance(oppX, rareFruit.x, oppY, rareFruit.y)
		-- Firstly, if we are closer to it then our opponent by 2 squares (1 turn to pick up fruit, so we stay ahead) then pick it up.
		if plyDistance < oppDistance - 1 then
			trace("Enough distance to take MINE: "..plyDistance .. " His: ".. oppDistance)
			return TAKE 
		end
		trace("Checking for good reason to take fruit")
		-- Okay, so they are chasing the fruit too, we need a fucking good reason to eat the fruit now.
		local plyAmount = get_my_item_count(item)
		local oppAmount = get_opponent_item_count(item)
		local itemAmount = get_total_item_count(item)
		-- If we need one more of that fruit to win, take it.
		if itemAmount % 2 == 0 then			
			local evenHalf = itemAmount / 2
			if plyAmount == evenHalf then return TAKE end
		else
			local oddHalf = math.floor(itemAmount / 2)
			if plyAmount == oddHalf then return TAKE end
		end
		
		-- If they have more of the item, and if they take it, they will win the category, we take it... unless they still win with 0.5 of the item
		local plyNeeded = AmountNeededToWin( item, plyAmount )
		local oppNeeded = AmountNeededToWin( item, oppAmount )
		if plyNeeded > oppNeeded and oppNeeded == 1 then return TAKE end
		return false
	end
	trace("All checks failed, taking.")
	return TAKE
end

function GetRareFruit()
	local board = get_board()
	rareFruit.tracking = false
	rareFruit.item = 0
	rareFruit.exists = false
	rareFruit.x = 0
	rareFruit.y = 0
	for x = 0, WIDTH - 1 do
		for y = 0, HEIGHT - 1 do
			local field = board[x][y]
			if has_item(field) > 0 then
				local item = has_item(field)
				local itemAmount = get_total_item_count(item)
				if itemAmount == 1 then 
					rareFruit.tracking = false
					rareFruit.item = item
					rareFruit.exists = true
					rareFruit.x = x
					rareFruit.y = y
				end
			end
		end
	end
end

function CheckForEvil()
	local board = get_board();
	local foundFruitID = false
	for x = 0, WIDTH - 1 do
		for y = 0, HEIGHT - 1 do
			local field = board[x][y]
			if has_item(field) > 0 then
				local item = has_item(field)
				if item == rareFruit.item then foundFruitID = true end 
				local itemAmount = get_total_item_count(item)
				local plyAmount =  get_my_item_count(item)
				local oppAmount =  get_opponent_item_count(item)
				if itemAmount % 2 == 0 then
					local evenHalf = (itemAmount / 2) + 1
					if plyAmount >= evenHalf or oppAmount >= evenHalf then badFruits[item] = true end
				else
					local oddHalf = math.ceil(itemAmount / 2)
					if plyAmount >= oddHalf or oppAmount >= oddHalf then badFruits[item] = true end
				end
			end
		end
	end
	if not foundFruitID then
		rareFruit.exists = false
	end
	for k,v in pairs(badFruits) do
		trace(k.." is a bad fruit!")
	end
end

function UpdateFields()

end

function make_move()
	-- Declare some variables
	local board = get_board()
	local plyX = get_my_x()
	local plyY = get_my_y()
	
	-- Non return functions
	 
	CheckForEvil() -- Bad fruit busters. (Don't track or eat fruit that will waste our time)
	
	-- Check if we have a fruit under us, if yes, then check if its worth picking up
	local field = board[plyX][plyY]
	if has_item(field) > 0 then
		local tempFunc = WorthGetting(has_item(field))
		if tempFunc then return tempFunc end
	end
	
	-- Check to see if the opponent is going for the targeted fruit of ours
	
	-- Go to best fruit
	local tempFunc = BestFruit()
	if tempFunc then return tempFunc end
	
end

function new_game()
	GetRareFruit() -- Checks if rare fruit exists, if yes then add it to table
end
