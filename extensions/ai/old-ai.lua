--菲特
sgs.ai_skill_invoke.leiguang = true

local tehua_skill={}
tehua_skill.name="tehua"
table.insert(sgs.ai_skills,tehua_skill)
tehua_skill.getTurnUseCard=function(self,inclusive)
    if not self:willShowForAttack() and not self:willShowForDefence() then return end
	---if self.player:hasUsed("#tehuaCard") then return end
	if self.player:getMark("##tehua_open") > 0 then return end
	if #self.enemies < 1 then return end
	if self.player:getHp() < 2 then return end
	--[[local cards = self.player:getHandcards() 
	local all_slash = 0
	for _, card in sgs.qlist(cards) do
		if card:inherits("Slash") then
			all_slash = slash + 1 
		end
	end
	if slash == 0 then return end]]
	local n = 0
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if p:isKindOf("Slash") then
		    n=n+1
			break
		end				
	end
	if n == 0then
	return end
	return sgs.Card_Parse("#tehuaCard:.:&tehua")
end

sgs.ai_skill_use_func["#tehuaCard"] = function(card,use,self)
	use.card = sgs.Card_Parse("#tehuaCard:.:&tehua")
	return
end
sgs.ai_skill_use_func.tehuaCard = function(card,use,self)
	use.card = sgs.Card_Parse("#tehuaCard:.:&tehua")
	return
end

sgs.ai_use_priority.tehuaCard = 5

sgs.ai_skill_use["@@tehuaglobal"] = function(self, prompt)
	if self.player:isNude() then return "." end
	local targets = {}
	local dest
	for _,e in ipairs(self.enemies) do
		dest = e
	end
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
		if #needed == 0 then
			table.insert(needed, c:getEffectiveId())
			break
		end                 
	end
	if dest and #needed==1 then
		return ("#tehuaglobalCard:"..table.concat(needed, "+")..":&->".. dest:objectName())
	end
	return "."
end



--四方茉莉
sgs.ai_skill_invoke.jiqiong = true

sgs.ai_skill_use["@@jiqiong"] = function(self, prompt)
   if self.player:isRemoved() then return end
   local id = self.player:property("jiqiong_number"):toInt()
   local card = sgs.Sanguosha:getCard(id)
   local use_card = card
	assert(use_card)
	if not card:isAvailable(self.player) then return end 
	local use = {isDummy = true,to = sgs.SPlayerList()}
	if use_card:isKindOf("BasicCard") then 
	self:useBasicCard(use_card, use)
	elseif use_card:isKindOf("EquipCard") then 
	self:useEquipCard(use_card, use)
	else 
	self:useTrickCard(use_card, use)
	end
    if not use.card then return "." end
	if use_card:isKindOf("EquipCard") or use_card:targetFixed() then return use_card:toString() end	
	local targets = {}
	for _,to in sgs.qlist(use.to) do
		table.insert(targets, to:objectName())
	end
	if #targets == 0 then 
		if use_card:canRecast() then return use_card:toString() end
	return "." end
	return use_card:toString() .. "->" .. table.concat(targets, "+")
end

sgs.ai_skill_askforag.jiqiong = function(self, card_ids)
   for _,id in ipairs(card_ids) do
       local card = sgs.Sanguosha:getCard(id)
	   if card:isAvailable(self.player) then
	      return id
	   end 
   end
   return -1
end

sgs.ai_skill_invoke.huaishi = true
sgs.ai_skill_invoke.yehuo = true


--阳子
sgs.ai_skill_invoke["suodi"] = function(self, data)
  if #self.friends<1 or (not self:willShowForDefence() and not self:willShowForAttack()) then return false end
  return true
end

sgs.ai_skill_playerchosen["suodi"] = function(self, targets)
	local friends = {}
	for _,player in ipairs(self.friends) do
		if player:isAlive() and ((player:getJudgingArea():length() > 0 and not noNeedToRemoveJudgeArea(player)) or (not friend:isNude()))then
			table.insert(friends, player)
		end
	end
	if #friends > 0 then
		self:sort(friends)
		return friends[#friends]
	end
end


local sheyanyouko_skill = {}
sheyanyouko_skill.name = "sheyanyouko"
table.insert(sgs.ai_skills, sheyanyouko_skill)
sheyanyouko_skill.getTurnUseCard = function(self, inclusive)
    if not self:willShowForAttack() and not self:willShowForDefence() then return end
	if self.player:getHandcardNum() < 2 then return end
	if self.player:getMark("&sheyanyoukomove") > 0 and self.player:usedTimes("#sheyanyoukoCard")> 1 then return end
	if self.player:getMark("&sheyanyoukomove") == 0 and self.player:usedTimes("#sheyanyoukoCard")> 0 then return end
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("#sheyanyoukoCard:.:&sheyanyouko")
end

sgs.ai_skill_use_func["#sheyanyoukoCard"] = function(card, use, self)
    local targets = sgs.SPlayerList()
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,e in ipairs(enemies) do
		if targets:length() < 1 and self:isEnemy(e) and e:getHandcardNum() > 0 then
			targets:append(e)
		end
	end
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    if #needed == 0 then
			table.insert(needed, c:getEffectiveId())
			break
		end
	end
	if targets:length()>0 and #needed == 1 then
		use.card = sgs.Card_Parse("#sheyanyoukoCard:"..table.concat(needed, "+")..":&sheyanyouko")
		if use.to then
			use.to = targets
		end
		return
	end
end


sgs.ai_skill_discard.sheyanyouko = function(self, discard_num, min_num, optional, include_equip) 
	local slashone = self.room:getTag("sheyanyoukoTarget"):toPlayer()
	local to_discard = {}
	local cards = self.player:getCards("hej")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:isEnemy(slashone) then
	   return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
	end
end

--谏山黄泉
chuling_skill={}
chuling_skill.name="chuling"
table.insert(sgs.ai_skills,chuling_skill)
chuling_skill.getTurnUseCard=function(self,inclusive)
	--[[for _,f in ipairs(self.friends) do
	    for _,c in sgs.qlist(f:getCards("ej")) do
	      if (c:isKindOf("Key") and f:isWounded()) and c:getSuit()~=card:getSuit() then return "jilan_obtain" end
        end
	end]]
	if not self:willShowForAttack() and not self:willShowForDefence() then return end
	if self.player:usedTimes("#chulingCard")> 1 then return end
	if self.player:getHandcardNum() > 4 then return end
	if self.player:getHp() < 2 then return end
	return sgs.Card_Parse("#chulingCard:.:&chuling")
end

sgs.ai_skill_use_func["#chulingCard"] = function(card,use,self)
    local targets = sgs.SPlayerList()
	for _,p in ipairs(self.friends) do
	   if self.player:inMyAttackRange(p) and not p:getCards("ej"):isEmpty() and targets:length() < 1 then
	       targets:append(p) 
	   end
    end
	if targets:length() >0 then
        use.card = sgs.Card_Parse("#chulingCard:.:&chuling")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority.chulingCard = 6

sgs.ai_skill_invoke.luanhonglian = function(self, data)
    local target = 0
    for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and enemy:inMyAttackRange(self.player) then
			target = target + 1
			break
		end
	end
	if target == 1then
	    return true
	end
	return false
end

sgs.ai_skill_playerchosen.luanhonglian = function(self, targets)
	local enemies = self.enemies
	self:sort(enemies, "defense")
	local can_target = false
	for _,p in ipairs(enemies)do
	   if self.player:canSlash(p) and p:inMyAttackRange(self.player) then 
		  can_target = true
		  return p 
	   end	
	end
	return
end

sgs.ai_skill_invoke.eling = true

--时雨亚沙
local shourenasa_skill = {}
shourenasa_skill.name = "shourenasa"
table.insert(sgs.ai_skills, shourenasa_skill)
shourenasa_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("ViewAsSkill_shourenasaCard") then return end
	if self.player:isKongcheng() then return end
	return sgs.Card_Parse("#shourenasaCard:.:&shourenasa")
end

sgs.ai_skill_use_func["#shourenasaCard"] = function(card, use, self)
	local needed = {}
	---local suit_list = {"spade", "heart", "club", "diamond"}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    ---local suit = c:getSuitString()
	    if not c:isAvailable(self.player) and #needed < 3 then---and table.contains(suit_list, suit) 
			table.insert(needed, c:getEffectiveId())
			----table.removeOne(suit_list, suit)
		end
	end
	if #needed > 0 then
    	use.card = sgs.Card_Parse("#shourenasaCard:"..table.concat(needed, "+")..":&shourenasa")
		return
	end
	return "."
end

sgs.ai_skill_playerchosen.shourenasaCard = function(self, targets)
	if self.player:hasFlag("shourenasa_loseHp") then
		local enemies = self.enemies
		self:sort(enemies, "defense")
		for _,p in ipairs(enemies)do
			return p 		
		end
	elseif not self.player:hasFlag("shourenasa_loseHp") then
	    self:sort(self.friends, "defense")
	    for _,q in ipairs(self.friends) do
			return q
		end
	end	
end

--美墨渚＆雪城穗乃香

local moxin_skill = {}
moxin_skill.name = "moxin"
table.insert(sgs.ai_skills, moxin_skill)
moxin_skill.getTurnUseCard = function(self,room,player,data)
	if self.player:getPile("tongxinN"):isEmpty() then return end
	self:sort(self.enemies, "defense")
	local useAll = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 + getCardsNum("GuangyuCard", enemy, self.player) then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao") then disCrossbow = true end

	local can_use = false
	local cards = {}
	for i = 0, self.player:getPile("tongxinN"):length() - 1, 1 do
		local slash = sgs.Sanguosha:getCard(self.player:getPile("tongxinN"):at(i))
		local slash_str = ("slash:moxin[%s:%s]=%d&moxin"):format(slash:getSuitString(), slash:getNumberString(), self.player:getPile("tongxinN"):at(i))
		local moxinslash = sgs.Card_Parse(slash_str)
		assert(moxinslash)
        if self:slashIsAvailable(self.player, moxinslash) then
			table.insert(cards, moxinslash)
		end
	end
	if #cards == 0 then return end
	return cards[1]
end

sgs.ai_view_as.moxin = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local ask = sgs.Sanguosha:getCurrentCardUsePattern()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "tongxinN" and ask == "slash" then
		return ("slash:moxin[%s:%s]=%d%s"):format(suit, number, card_id, "&moxin")
	end
end

sgs.ai_skill_invoke.moxin = function(self, data)
    return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_invoke.xuerui = function(self, data)
    if not self:willShowForAttack() and not self:willShowForDefence() then return false end
	if (self.player:isKongcheng() or self.player:getHandcardNum() > 2 )and self.player:getPile("tongxinN"):length()< 2 then return false end
	local n = 0
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if p:isKindOf("Peach") or p:isKindOf("Analeptic") or p:isKindOf("GuangyuCard") then
		    n=n+1
			break
		end				
	end
	if n > 0then return end
	local enemies = self.enemies
	self:sort(enemies, "defense")
	local m = 0
	for _,q in ipairs(enemies)do
	   if self.player:inMyAttackRange(q) and q~= data:toPlayer() then 
		  m=m+1
		  break
	   end	
	end
	if m == 0then return end
	local target = data:toPlayer()
	if self:isEnemy(target) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.xuerui = function(self, targets)
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,p in ipairs(enemies)do
	    if self.player:inMyAttackRange(p) and p~= data:toPlayer() then
		  return p 		
		end  
	end
	return
end

--七海露西亚
local liangee_skill = {}
liangee_skill.name = "liangee"
table.insert(sgs.ai_skills, liangee_skill)
liangee_skill.getTurnUseCard = function(self,room,player,data)
    if self.player:hasUsed("ViewAsSkill_liangeeCard") then return end
	if self.player:isNude() or (not self:willShowForAttack() and not self:willShowForDefence()) then return end
	for _,e in ipairs(self.enemies) do
		if  e:isKongcheng() and e:isWounded() then
			return false
		end
	end
	local targets = sgs.SPlayerList()
	self:sort(self.friends, "defense")
	for _,p in ipairs(self.friends) do
	   if self.player~=p and p:getHp() < 2 and targets:length() < 1 then
	       targets:append(p) 
	   end
    end
	if targets:length() >0 then
	    local n = 0
		for _,pl in sgs.qlist(self.player:getHandcards()) do
			if pl:isKindOf("Peach") or pl:isKindOf("GuangyuCard") then
				n=n+1
				break
			end				
		end
		if n > 0then return end
		local hecards = self.player:getCards("he")
		for _, id in sgs.qlist(self.player:getHandPile()) do
			hecards:prepend(sgs.Sanguosha:getCard(id))
		end
		local cards = {}
		for _, card in sgs.qlist(hecards) do
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			local card_str = ("shining_concert:liangee[%s:%s]=%d&liangee"):format(suit, number, card_id)
			local slash = sgs.Card_Parse(card_str)
			assert(slash)
			if slash:isAvailable(self.player) then
				table.insert(cards, slash)
			end
		end
		if #cards == 0 then return end
		self:sortByUsePriority(cards)
		return cards[1]
	elseif targets:length() == 0 then
	    if self.player:hasSkill("zhenzhu") then return end
	    local hecards = self.player:getCards("he")
		for _, id in sgs.qlist(self.player:getHandPile()) do
			hecards:prepend(sgs.Sanguosha:getCard(id))
		end
		local cards = {}
		for _, card in sgs.qlist(hecards) do
			--if card:isBlack() and card:isKindOf("BasicCard") then
				local suit = card:getSuitString()
				local number = card:getNumberString()
				local card_id = card:getEffectiveId()
				local card_str = ("shining_concert:liangee[%s:%s]=%d&liangee"):format(suit, number, card_id)
				local slash = sgs.Card_Parse(card_str)
				assert(slash)
				if slash:isAvailable(self.player) then
					table.insert(cards, slash)
				end
			--end
		end
		if #cards == 0 then return end
		self:sortByUsePriority(cards)
		return cards[1]
	end
end


local zhuanqing_skill = {}
zhuanqing_skill.name = "zhuanqing"
table.insert(sgs.ai_skills, zhuanqing_skill)
zhuanqing_skill.getTurnUseCard = function(self, inclusive)
	if not self:willShowForAttack() and not self:willShowForDefence() then return end
	local f = 0 
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasSkill("zhenzhu") then
			f = f+1
			break
		end
	end
	if f > 0then return end
	return sgs.Card_Parse("#zhuanqingCard:.:&zhuanqing") 
end

sgs.ai_skill_use_func["#zhuanqingCard"] = function(card,use,self)
    local target
	local targets = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() < 2 and self:isFriend(p) then---p:isWounded()
			table.insert(targets, p)
		end
	end
	if #targets > 0 then
    	self:sort(targets, "defense")
    	target = targets[1]
		use.card = sgs.Card_Parse("#zhuanqingCard:.:&zhuanqing")
		if use.to then
			use.to:append(target)
		end
	end 
end

sgs.ai_skill_invoke.zhenzhu = true