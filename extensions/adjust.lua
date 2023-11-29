
function file_exists(name) 
	local f = io.open(name, "r")
	if f ~= nil then io.close(f) return true else return false end
end
	
	local n = 0
	for i = 1, 998, 1 do
		if file_exists("image/backdrop/"..i..".jpg") then
			n = i
		else
			break
		end
	end
	local m = 0
	for i = 1, 998, 1 do
		if file_exists("audio/system/anime"..i..".ogg") then
			m = i
		else
			break
		end
	end
--sgs.SetConfig("BackgroundImage", "image/backdrop/"..math.random(1,n)..".jpg")
--sgs.SetConfig("TableBgImage", sgs.GetConfig("BackgroundImage", "")) 
sgs.SetConfig("BackgroundMusic", "audio/system/anime"..math.random(1,m)..".ogg")
