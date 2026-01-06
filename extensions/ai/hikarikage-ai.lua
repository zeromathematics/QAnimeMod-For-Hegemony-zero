--五更琉璃
sgs.ai_skill_invoke.shengliA = function(self, data)
    if not self:willShowForAttack() and not self:willShowForDefence() then return false end
	local target = data:toPlayer()
	if self:isEnemy(target) then
		if self.player:getHandcardNum() >= target:getHandcardNum() then
			return true
		end
		local max_card = self:getMaxCard()
	    local max_point = max_card:getNumber()
	    if max_point - 10 >= self.player:getHandcardNum() - target:getHandcardNum() then
		    return true
		end
		if max_point - 7 >= self.player:getHandcardNum() - target:getHandcardNum() and self:isWeak(target) then
		    return true
		end
	end
	return false
end

sgs.ai_skill_invoke.shengliB = function(self, data)
    if not self:willShowForAttack() and not self:willShowForDefence() then return false end
	local target = data:toPlayer()
	return self:isFriend(target)
end

sgs.ai_skill_invoke.yishi = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.yishi = function(self, targets)
    local min = 998
	local best
    if self.player:getHp() < min then
	   min = self.player:getHp()
	   best = self.player
	end
    for _,p in sgs.qlist(targets) do
		if p:getHp() < min and p:isWounded() then
			min = p:getHp()
			best = p
		end
	end
    if best and best:getHandcardNum() < self.player:getHandcardNum() then return best end

	for _,p in sgs.qlist(targets) do
		if self.player:getHp() == min and self.player:isWounded() and self.player:getHp() < p:getHp() and self.player:getHandcardNum()~=p:getHandcardNum() then
			return p
	    end
		if p:getHp() == min and p:isWounded() and p:getHp() < self.player:getHp() and self.player:getHandcardNum()~=p:getHandcardNum() then
			return p
	    end
		if self.player:isWounded() and self.player:getHp() < p:getHp() and self.player:getHandcardNum()~=p:getHandcardNum() then
			return p
	    end
		if p:isWounded() and p:getHp() < self.player:getHp() and self.player:getHandcardNum()~=p:getHandcardNum() then
			return p
	    end
		if self.player:getHp() == min and self.player:isWounded() and self.player:getHp() < p:getHp() then
			return p
	    end
		if p:getHp() == min and p:isWounded() and p:getHp() < self.player:getHp() then
			return p
	    end
		if self.player:isWounded() and self.player:getHp() < p:getHp() then
			return p
	    end
		if p:isWounded() and p:getHp() < self.player:getHp() then
			return p
	    end
	end
	for _,p in sgs.qlist(targets) do
	    if p:getHandcardNum() ~= self.player:getHandcardNum() then return p end
	end
end

--Elaina
sgs.ai_skill_invoke.lvji = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

lvjigive_skill={}
lvjigive_skill.name="lvjigive"
table.insert(sgs.ai_skills,lvjigive_skill)
lvjigive_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if source:isKongcheng() then return end
	if source:hasUsed("#LvjigiveCard") then return end
	return sgs.Card_Parse("#LvjigiveCard:.:&lvjigive")
end

sgs.ai_skill_use_func["#LvjigiveCard"] = function(card,use,self)
	local target
	local source = self.player
	for _,friend in ipairs(self.friends_noself) do
		if friend:hasShownSkill("lvji") and friend:getPile("jixu_id"):length() < 5 then
			target = friend
		end
	end
    if not target then return end

	local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
	local needed = {}
    for _,acard in ipairs(cards) do
		if #needed < 1 and acard:isKindOf("TrickCard") then
            local has
            for _,i in sgs.qlist(target:getPile("jixu_id")) do
                local c = sgs.Sanguosha:getCard(i)
                if acard:objectName() == c:objectName() then
                    has = true
                end
            end
            if not has then table.insert(needed, acard:getEffectiveId()) end
		end
	end
    for _,acard in ipairs(cards) do
		if #needed < 1 and acard:isNDTrick() then
            table.insert(needed, acard:getEffectiveId())
		end
	end
	for _,acard in ipairs(cards) do
		if #needed < 1 and source:getHandcardNum() > source:getMaxCards() then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	if target and #needed == 1 then
		use.card = sgs.Card_Parse("#LvjigiveCard:"..table.concat(needed,"+")..":&lvjigive")
		if use.to then use.to:append(target) end
		return
	end
end

local fahui_skill = {}
fahui_skill.name = "fahui"
table.insert(sgs.ai_skills, fahui_skill)
fahui_skill.getTurnUseCard = function(self,room,player,data)
	if self.player:hasUsed("ViewAsSkill_fahuiCard") or self.player:isKongcheng() then return end
	local usevalue = 0
	local keepvalue = 0	
	local id
	local card1
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		id = tostring(card:getId())
		card1 = card
		usevalue=self:getUseValue(card)
		keepvalue=self:getKeepValue(card)
		break
	end
	if not id then return end
	local parsed_card = {}
	local list = self.player:getPile("jixu_id")
	for _,i in sgs.qlist(list) do
		local c = sgs.Sanguosha:getCard(i)
		if  (c:isKindOf("BasicCard") or c:isNDTrick()) and c:isAvailable(self.player) then
		  table.insert(parsed_card, sgs.Card_Parse(c:objectName()..":fahui[to_be_decided:"..card1:getNumberString().."]=" .. id .."&fahui"))
		end
	end
	
	local value = 0
	local tcard
	for _, c in ipairs(parsed_card) do
		assert(c)
		if self:getUseValue(c) > value and self:getUseValue(c) > keepvalue and self:getUseValue(c) > usevalue then
			value = self:getUseValue(c)
			tcard = c
		end
	end
	if tcard and id then
		return tcard
	end
end

sgs.ai_skill_askforag.lvji = function(self, card_ids)
	local list = {}
	for _,i in ipairs(card_ids) do
		if sgs.Sanguosha:getCard(i):isNDTrick() then
			table.insert(list, sgs.Sanguosha:getCard(i)) 
		end
	end
	if #list > 0 then
		self:sortByUseValue(list)
		return list[1]:getEffectiveId()
	end
	for _,i in ipairs(card_ids) do
		if sgs.Sanguosha:getCard(i):isKindOf("TrickCard") then
			return i
		end
	end
end

--Enju
sgs.ai_skill_invoke.qishi = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end



---绫小路清隆
ance_skill={}
ance_skill.name="ance"
table.insert(sgs.ai_skills,ance_skill)
ance_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("ViewAsSkill_anceCard") then return end
	if #self.enemies < 1 then return end
	local n = 0
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if not p:isAvailable(self.player)and not p:isKindOf("Peach")and not p:isKindOf("Analeptic")and not p:isKindOf("GuangyuCard") then
		    n=n+1
			break
		end				
	end
	if n == 0then
	return end
	return sgs.Card_Parse("#AnceCard:.:&ance")
end

sgs.ai_skill_use_func["#AnceCard"] = function(card,use,self)
	local targets = sgs.SPlayerList()
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,e in ipairs(enemies) do
		if targets:length() < 1 and self:isEnemy(e) then
			targets:append(e)
		end
	end
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    if #needed == 0 and (not c:isAvailable(self.player)and not c:isKindOf("Peach")and not c:isKindOf("Analeptic")and not c:isKindOf("GuangyuCard")) then
			table.insert(needed, c:getEffectiveId())
			break
		end
	end
	if targets:length()>0 and #needed == 1 then
		use.card = sgs.Card_Parse("#AnceCard:"..table.concat(needed, "+")..":&ance")
		if use.to then
			use.to = targets
		end
		return
	end
end


--爱花＆美海
hailian_skill={}
hailian_skill.name="hailian"
table.insert(sgs.ai_skills,hailian_skill)
hailian_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("ViewAsSkill_hailianCard") then return end
	if self.player:isKongcheng() then return end
	local n = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getHandcardNum() > 0 then
		    n=n+1
			break
		end				
	end
	if n == 0then
	return end
	return sgs.Card_Parse("#HailianCard:.:&hailian")
end

sgs.ai_skill_use_func["#HailianCard"] = function(card,use,self)
	local targets = sgs.SPlayerList()
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if (self:isFriend(p) or self:isEnemy(p))and p:getHandcardNum() > 0 then
			targets:append(p)
            break
		end
	end
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    if #needed == 0 and (not c:isAvailable(self.player)and not c:isKindOf("Peach")and not c:isKindOf("Analeptic")and not c:isKindOf("GuangyuCard")) then
			table.insert(needed, c:getEffectiveId())
			break
		end
	end
	if targets:length()>0 and #needed == 1 then
		use.card = sgs.Card_Parse("#HailianCard:"..table.concat(needed, "+")..":&hailian")
		if use.to then
			use.to = targets
		end
		return
	end
end

sgs.ai_skill_invoke.langjing = function(self, data)
	if self.player:getMark("langjing_record") > 0 then
		return true
	end
end

sgs.ai_skill_playerchosen.langjing = function(self, targets)
   local result = {}
   local friends = self.friends
   self:sort(friends, "handcard")
   if #friends >1 and self.player:getMark("langjing_record") > 1 then
	  table.insert(result, friends[1])
	  table.insert(result, friends[2])
   else
	  table.insert(result, friends[1])
   end
   return result
end


---艾丝·华伦斯坦
sgs.ai_skill_discard["jizou"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
end
--[[sgs.ai_skill_invoke.jizou = function(self, data)
	if not self.player:isNude() then
		return true
	end
end]]
sgs.ai_skill_choice.jizou = "jizouDrawPile"

sgs.ai_skill_askforag.jizou = function(self, card_ids)
  --- local target = self.player:property("jizou_target"):toPlayer()
   for _,id in ipairs(card_ids) do
       local card = sgs.Sanguosha:getCard(id)
	   if card:isKindOf("Slash") then----card:isAvailable(self.player) and
	      return id
	   end 
   end
   return -1
end
sgs.ai_skill_playerchosen.jizou = function(self, targets)
    local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,p in ipairs(enemies)do
		---if self:slashIsEffective(slash,p) then 
		return p 		
		---end	
	end
end

---折纸
sgs.ai_skill_invoke.rilun = true
--[[sgs.ai_skill_invoke.rilun = function(self, data)
	if not self.player:isNude() then
		return true
	end
end]]

sgs.ai_skill_playerchosen.rilun = function(self, targets)
    local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,p in ipairs(enemies)do
		if p:hasShownOneGeneral() then return p end	
	end
	return
end

sgs.ai_skill_discard["rilun"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
end




guangjian_skill = {}
guangjian_skill.name = "guangjian"
table.insert(sgs.ai_skills, guangjian_skill)
guangjian_skill.getTurnUseCard = function(self, inclusive)
    if not self:willShowForAttack() and not self:willShowForDefence() then return end
	if self.player:hasUsed("ViewAsSkill_guangjianCard") then return end
	if #self.enemies < 1 then return end
	local n = 0
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if p:isKindOf("BasicCard") then
		    n=n+1
			break
		end				
	end
	if n == 0then
	return end
	return sgs.Card_Parse("#guangjianCard:.:&guangjian")
end

sgs.ai_skill_use_func["#guangjianCard"] = function(card, use, self)
    local targets = sgs.SPlayerList()
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,e in ipairs(enemies) do
		if targets:length() < 1 and self:isEnemy(e) and e:getPile("guangjian"):length()==0 then
			targets:append(e)
		end
	end
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    if #needed == 0 and c:isKindOf("BasicCard") then
			table.insert(needed, c:getEffectiveId())
			break
		end
	end
	if targets:length()>0 and #needed == 1 then
		use.card = sgs.Card_Parse("#guangjianCard:"..table.concat(needed, "+")..":&guangjian")
		if use.to then
			use.to = targets
		end
		return
	end
end

sgs.ai_skill_invoke.guangjian = true


----锦木千束
---sgs.ai_skill_invoke.qianggan = true

sgs.ai_skill_invoke.qianggan = function(self, data)
	if self.player:getHandcardNum() < 2 then
		return true
	end
end

sgs.ai_skill_choice.qianggan = function(self, choices, data)
    if self.player:getHandcardNum() < 2 then
	   return "choice-qianggan-obtain"
	end
	return "."
end

---楪祈
sgs.ai_skill_invoke.wangeA = true
sgs.ai_skill_invoke.wangeB = true
sgs.ai_skill_choice.wange = "draw"
sgs.ai_skill_invoke.wangeC = function(self, data)
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p) then
			return true
		end
	end
	return false
end
sgs.ai_skill_playerchosen.wange = function(self, targets)
	self:sort(self.friends, "defense")
	for _,q in ipairs(self.friends) do
		if self.player~=q then
		   return q
		end  
	end
end


sgs.ai_skill_invoke.xujian = function(self, data)
	local target = data:toPlayer()
	if target then
		return not self:isEnemy(target)
	end
end
sgs.ai_skill_invoke.xujiangive = function(self, data)
	return #self.friends_noself > 0 and self.player:getHandcardNum() >= 1---and self:getOverflow() > 0
end
sgs.ai_skill_playerchosen.xujian = function(self, targets)
	self:sort(self.friends, "defense")
	for _,q in ipairs(self.friends) do
	    if self.player~=q then
		   return q
		end  
	end
	return false
end

---爱丽丝·玛格特罗伊德

--[[sgs.ai_skill_invoke.suou = function(self, data)
	if self.player:getEquips():length() <= 5 then
		return true
	end
end]]

sgs.ai_skill_invoke.suou = true

sgs.ai_skill_choice.suou = function(self, choices, data)
    if self.player:getEquips():length() < 3 then
	   return "suou_draw"
	elseif self.player:getEquips():length() >= 3 and #self.friends_noself > 0 then
       return "suou_move"	
	end
	return "."
end

sgs.ai_skill_playerchosen.suou = function(self, targets)
	self:sort(self.friends_noself, "defense")
	return self.friends_noself[1]
end

sgs.ai_skill_invoke.weizhen = true


---青山七海
sgs.ai_skill_invoke["jinqu"] = function(self, data)
  if self.player:getLostHp()>0 and data:toDamage().damage>0 then
    return true
  end
  if not self.player:faceUp() then
    return true
  end
  return false
end

sgs.ai_skill_askforyiji.jinqu = function(self, card_ids)
  local num = 100
	local target
	for _,p in ipairs(self.friends) do
		if p:getHandcardNum() < num and p:objectName() ~= self.player:objectName() then
			target = p
			num = p:getHandcardNum()
		end
	end
	if target and #card_ids>2 then return target, card_ids[1] end
	return nil, -1
end



---鲁迪乌斯
sgs.ai_skill_invoke.wuyong = function(self, data)
    if self.player:isRemoved() then return end
    local target = 0
    for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) then
			target = target + 1
			break
		end
	end
	if target == 1then
	    return true
	end
	return false
end

sgs.ai_skill_choice["wuyong"] = function(self, choices, data)
	return "ice_slash"
end

sgs.ai_skill_use["@@wuyong"] = function(self, prompt) 
	local target
	local card
	for _,p in ipairs(self.enemies) do
	  if self.player:canSlash(p) then target = p end
	end
	if target then	
		local card = sgs.Sanguosha:cloneCard(self.player:property("wuyongslashtype"):toString())
		assert(card)
		if not card:isAvailable(self.player) then return end 
		local use = {isDummy = true, to = sgs.SPlayerList()}
		if card:isKindOf("BasicCard") then
			self:useBasicCard(card, use)
		else
			self:useTrickCard(card, use)
		end
		if not use.card then return "." end
		if card:targetFixed() then return card:toString() end
		local targets = {}
		for _,to in sgs.qlist(use.to) do
			table.insert(targets, to:objectName())
		end
		if #targets == 0 then 
			if card:canRecast() then
				return card:toString()
			end
			return "."
		end
		return card:toString() .. "->" .. table.concat(targets, "+")
	end
	return "."
end


sgs.ai_skill_invoke.fushou = true
sgs.ai_skill_choice["fushou"] = function(self, choices, data)
    if self.player:getMark("fushou_effect1") == 0 then
	   return "fushou_effect1"
	elseif self.player:getMark("fushou_effect3") == 0 then
       return "fushou_effect3"
	elseif self.player:getMark("fushou_effect2") == 0 then
       return "fushou_effect2"	   
	end
	return "."
end

----我妻由乃
sgs.ai_skill_invoke.chuai = function(self, data)
  local use = data:toCardUse()
  if self:isEnemy(use.from) then 
     return use.card:isBlack()
  end
  return "."
end

----西行寺幽幽子
sgs.ai_skill_invoke.sidie = function(self, data)
    local target = 0
    for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self.player:getHandcardNum() > enemy:getHandcardNum() then
			target = target + 1
			break
		end
	end
	if target == 1then
	    return true
	end
	return false
end

sgs.ai_skill_playerchosen.sidie = function(self, targets)
	targets = sgs.QList2Table(targets)
	local drawTarget
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and self.player:canSlash(target) and self.player:getHandcardNum() > target:getHandcardNum()then drawTarget = target end 
	end
	if drawTarget then return drawTarget end
	---return targets[1]
end

----红美铃
sgs.ai_skill_invoke.taiji = function(self, data)
	if not self.player:isNude() then
		return true
	end
end
sgs.ai_skill_discard["taiji"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
end

sgs.ai_skill_invoke.hongquan = function(self, data)
    local target = 0
    for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) then
			target = target + 1
			break
		end
	end
	if target == 1then
	    return true
	end
	return false
end

sgs.ai_skill_playerchosen.hongquan = function(self, targets)
	targets = sgs.QList2Table(targets)
	local drawTarget
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and self.player:canSlash(target) then drawTarget = target end 
	end
	if drawTarget then return drawTarget end
end

----艾琳
mowu_skill={}
mowu_skill.name="mowu"
table.insert(sgs.ai_skills,mowu_skill)
mowu_skill.getTurnUseCard=function(self,inclusive)
	if self.player:isKongcheng() or self.player:hasUsed("ViewAsSkill_mowuCard") then return end
	return sgs.Card_Parse("#MowuCard:.:&mowu")
end

sgs.ai_skill_use_func["#MowuCard"] = function(card,use,self)
	local targets = sgs.SPlayerList()
	local enemies = self.enemies
	self:sort(enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash")
	for _,e in ipairs(enemies) do
		if targets:length() < 1 and (not e:hasShownSkill("huansha") or self.player:getMark("drank")>0) and self:slashIsEffective(slash, e, self.player) and self.player:distanceTo(e) <= 1 and self:slashIsAvailable(self.player, slash) and self.player:distanceTo(e)>-1 then
			targets:append(e)
		end
	end
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    if #needed == 0 then
			table.insert(needed, c:getEffectiveId())
			break
		end
	end
	if targets:length()>0 and #needed == 1 then
		use.card = sgs.Card_Parse("#MowuCard:"..table.concat(needed, "+")..":&mowu")
		if use.to then
			use.to = targets
		end
		return
	end
end

sgs.ai_skill_choice["mowu"] = function(self, choices, data)
	return "ice_slash"
end

sgs.ai_use_priority.MowuCard = 2