


--for shifeng
sgs.ai_skill_use["BasicCard+^Jink,TrickCard+^Nullification,EquipCard|.|.|hand"] = function(self, prompt, method)
	local cards =  sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					if card:isKindOf("IronChain") then
						return "."
					end
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not card:isKindOf("Jink") then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useBasicCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		end
	end
	return "."
end

--shifeng
sgs.ai_skill_invoke.shifeng = function(self, data)
	if not self:willShowForDefence() and not self:willShowForAttack() then
		return false
	end
	return true
end

sgs.ai_skill_use["@@shifeng"] = function(self, prompt)
	local targets = {}
	local n = 0
	for _,p in ipairs(self.friends) do
	  if self.player:inMyAttackRange(p) then
	     n = n+1
	  end
	end
	
	if n > 1 then
	 for _,p in ipairs(self.friends) do
	   if #targets <n and self.player:inMyAttackRange(p) then table.insert(targets, p:objectName()) end
	 end
	end
	
	if (n == 1) then
	   local m = 0
	   local target
	   for _,p in ipairs(self.friends) do
	     if p:getHandcardNum()>m and p:isWounded() then 
		   target = p
		   m = p:getHandcardNum()
		 end
	   end
	   if #targets <1 and target then table.insert(targets, target:objectName()) end
	end
	
	if type(targets) == "table" and #targets > 0 then
		return ("@ShifengCard=.&shifeng->" .. table.concat(targets, "+"))
	end
	return "."
end

sgs.ai_skill_choice.shifeng = function(self, choices, data)
   if self.player:containsTrick("indulgence") then
     return "shifeng_otherdraw"
   else
     local n = math.random(1,4)
	 if n==4 then
	   return "shifeng_otherdraw"
	 end
   end
   return "shifeng_selfdraw"
end

zhiyan_skill={}
zhiyan_skill.name="zhiyan"
table.insert(sgs.ai_skills,zhiyan_skill)
zhiyan_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if self.player:isKongcheng() then return end
	if self.player:hasFlag("zhiyan_used") then return end
	local can_man = false
	for _,enemy in ipairs(self.enemies) do
		if not self.player:hasFlag(enemy:objectName().."zhiyan") and enemy:getHandcardNum() > 0 then
			can_man = true
		end
	end
	for _,friend in ipairs(self.friends_noself) do
		for _,c in sgs.qlist(friend:getJudgingArea()) do
		   if (not c:isKindOf("Key") or friend:isWounded()) and not self.player:hasFlag(friend:objectName().."zhiyan") and friend:getHandcardNum()>0 then
			 can_man = true
		   end
		end
	end
	if not can_man then return end
	local cards=sgs.QList2Table(self.player:getHandcards())
	local OK = false
	for _,card in ipairs(cards) do
		if card:getNumber() > 6 then
			OK =true
		end
	end
	if OK then
		return sgs.Card_Parse("@ZhiyanCard=.&zhiyan")
	end
end

sgs.ai_skill_use_func.ZhiyanCard = function(card,use,self)
	local target
	local source = self.player
	local m = 998
	
	for _,friend in ipairs(self.friends_noself) do
	   for _,c in sgs.qlist(friend:getJudgingArea()) do
		   if c:isKindOf("Key") and not friend:isKongcheng() and friend:isWounded() and not self.player:hasFlag(friend:objectName().."zhiyan") then
			 target = friend
		   end
		end
	end
	for _,enemy in ipairs(self.enemies) do
	    if enemy:getHandcardNum()<m and enemy:getHandcardNum()>0 and not self.player:hasFlag(enemy:objectName().."zhiyan") then
		  target = enemy
		  m = enemy:getHandcardNum()
		end
	end
	for _,friend in ipairs(self.friends_noself) do
	   for _,c in sgs.qlist(friend:getJudgingArea()) do
		   if not c:isKindOf("Key") and not friend:isKongcheng() and not self.player:hasFlag(friend:objectName().."zhiyan") then
			 target = friend
		   end
		end
	end
	if target then
		use.card = sgs.Card_Parse("@ZhiyanCard=.&zhiyan")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_invoke.rennai = function(self, data)
    local damage = data:toDamage()
	if damage and damage.damage>1 then
	  return true
	end
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_choice.rennai = function(self, choices, data)
	choices = choices:split("+")
	local tp = 1
	for _,choice in ipairs(choices) do
		if choice == "rennai_hp" then
			tp = 0
			break
		end
		if choice == "rennai_gain" then
			tp = 2
			break
		end
	end

	-- analysis
	local hp_table = {}
	local hand_table = {}
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if hp_table[p:getHp()] ~= nil then
			self.room:writeToConsole("old")
			if self:isFriend(p) then
				if p:getMark("@Frozen_Eu") > 0 then
				else
					hp_table[p:getHp()] = hp_table[p:getHp()] - 2
				end
			else
				if p:getMark("@Frozen_Eu") > 0 then
					hp_table[p:getHp()] = hp_table[p:getHp()] + 1
				else
					hp_table[p:getHp()] = hp_table[p:getHp()] + 3
				end
			end
		else
			self.room:writeToConsole("new")
			if self:isFriend(p) then
				if p:getMark("@Frozen_Eu") > 0 then
					hp_table[p:getHp()] = 0
				else
					hp_table[p:getHp()] = - 2
				end
			else
				if p:getMark("@Frozen_Eu") > 0 then
					hp_table[p:getHp()] = 1
				else
					hp_table[p:getHp()] = 3
				end
			end
		end
		if hand_table[p:getHandcardNum()] ~= nil then
			if self:isFriend(p) then
				if p:getMark("@Frozen_Eu") > 0 then
				else
					hand_table[p:getHandcardNum()] = hand_table[p:getHandcardNum()] - 2
				end
			else
				if p:getMark("@Frozen_Eu") > 0 then
					hand_table[p:getHandcardNum()] = hand_table[p:getHandcardNum()] + 1
				else
					hand_table[p:getHandcardNum()] = hand_table[p:getHandcardNum()] + 3
				end
			end
		else
			if self:isFriend(p) then
				if p:getMark("@Frozen_Eu") > 0 then
					hand_table[p:getHandcardNum()] = 0
				else
					hand_table[p:getHandcardNum()] = - 2
				end
			else
				if p:getMark("@Frozen_Eu") > 0 then
					hand_table[p:getHandcardNum()] = 1
				else
					hand_table[p:getHandcardNum()] = 3
				end
			end
		end
	end

	local maxValue = -100000
	local hp_or_hand
	local isHp = false
	for k,v in ipairs(hp_table) do
		self.room:writeToConsole(k)
		self.room:writeToConsole(v)
		if v > maxValue then
			maxValue = v
			hp_or_hand = k
			isHp = true
		end
	end

	for k,v in ipairs(hand_table) do
		if v > maxValue then
			maxValue = v
			hp_or_hand = k
			isHp = false
		end
	end

	self.room:writeToConsole(maxValue)
	self.room:writeToConsole(hp_or_hand)

	if tp == 0 then
		-- rennai_hp  rennai_lose
		if isHp then
			return "rennai_hp"
		else
			return "rennai_lose"
		end
	elseif tp == 1 then
		return hp_or_hand
	else
		return "rennai_gain"
	end
end

sgs.ai_skill_invoke.zhanfang = function(self, data)
	-- 绽放吧！
	local use = data:toCardUse()
	if use and use.card and self:isEnemy(use.to:first()) then return true end
	return false
end

sgs.ai_skill_choice.zhanfang = function(self, choices, data)
	if self.player:getMark("@Frozen_Eu") > 1 and math.random(1,2)==2 then
		return "cancel"
	else
		return "zhanfang_discard"
	end
end

sgs.ai_skill_invoke.zuozhan = function(self, data)
   return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_choice["zuozhan1"] = function(self, choices, data)
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		return "1_Zuozhan"
	else
		if p:getHandcardNum() <= p:getHp() then return "4_Zuozhan" else return "2_Zuozhan" end
	end
	return "1_Zuozhan"
end

sgs.ai_skill_choice["zuozhan2"] = function(self, choices, data)
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 then
			return "3_Zuozhan"
		else
			return "2_Zuozhan"
		end
	else
		if p:getHandcardNum() <= p:getHp() then return "2_Zuozhan" else return "3_Zuozhan" end
	end
	return "2_Zuozhan"
end

sgs.ai_skill_choice["zuozhan3"] = function(self, choices, data)
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 then
			return "2_Zuozhan"
		else
			return "4_Zuozhan"
		end
	else
		if p:getHandcardNum() <= p:getHp() then return "3_Zuozhan" else return "4_Zuozhan" end
	end
	return "3_Zuozhan"
end

sgs.ai_skill_choice["zuozhan4"] = function(self, choices, data)
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 then
			return "4_Zuozhan"
		else
			return "3_Zuozhan"
		end
	else
		return "1_Zuozhan"
	end
	return "4_Zuozhan"
end

sgs.ai_skill_invoke.nishen = function(self, data)
	local dying = data:toDying()
	if not self:isEnemy(dying.who) then return true end
	for _,p in ipairs(self.friends) do
		if self:isWeak(p) then return false end
	end
	return true
end

sgs.ai_skill_choice.nishen = function(self, choices, data)
	choices = choices:split("+")
	local on_join = false
	for _,choice in ipairs(choices) do
		if choice == "nishen_accept" then
			on_join = true
		end
	end
	if on_join then
		local yuri = self.room:findPlayerBySkillName("nishen")
		if not yuri then return "cancel" end
		if self.player:getRole() == "careerist" then return "cancel" end
		if not self:isEnemy(yuri) then return "nishen_accept" end
		return "cancel"
	else
		if self.player:getHandcardNum() < self.player:getHp() * 2 then return "draw" end
		return "recover"
	end
end

sgs.ai_skill_invoke.xingbao = function(self, data)
    local damage = data:toDamage()
	local card = damage.card
    local hecards = self.player:getCards("he")
	for _, c in sgs.qlist(hecards) do
	  if c:isRed() and card:isRed()  then
	    return true
	  end
	end
	for _, c in sgs.qlist(hecards) do
	  if c:isBlack() and card:isBlack() then
	    return true 
	  end
	end
   return false
end

sgs.ai_skill_use["@@xingbao"] = function(self, prompt)
	local card
    local hecards = self.player:getCards("he")
	for _, c in sgs.qlist(hecards) do
	  if c:isRed() and self.player:hasFlag("xingbao_red") and not c:isKindOf("Slash") then
	    card = c 
	  end
	end
	for _, c in sgs.qlist(hecards) do
	  if c:isBlack() and self.player:hasFlag("xingbao_black") and not c:isKindOf("Slash") then
	    card = c 
	  end
	end
	if not card then
	
	  for _, c in sgs.qlist(hecards) do
	  if c:isRed() and self.player:hasFlag("xingbao_red") then
	    card = c 
	  end
	end
	for _, c in sgs.qlist(hecards) do
	  if c:isBlack() and self.player:hasFlag("xingbao_black") then
	    card = c 
	  end
	end
	
    end 
	if card then
		return ("@XingbaoCard="..card:getEffectiveId().."&->")
	end
	return "."
end

shiso_skill={}
shiso_skill.name="shiso"
table.insert(sgs.ai_skills,shiso_skill)
shiso_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if source:hasUsed("ShisoCard") then return end
	return sgs.Card_Parse("@ShisoCard=.&shiso")
end
sgs.ai_skill_use_func.ShisoCard = function(card,use,self)
	local target
	local card
	local player = self.player
	for _,friend in ipairs(self.friends) do
		if friend:hasSkill("shizu") then
			target = friend
		end
	end
	local cards=sgs.QList2Table(player:getHandcards())
    self:sortByUseValue(cards, true)
    for _,c in ipairs(cards) do
	  if (c:getSuitString()=="heart" or c:getSuitString()=="spade") and c:getNumber()>10 then
	     card = c
	  end
	end
	if not card then
	    local cards = sgs.QList2Table(player:getEquips())
		self:sortByUseValue(cards, true)
		 for _,c in ipairs(cards) do
	  if (c:getSuitString()=="heart" or c:getSuitString()=="spade") and c:getNumber()>10 then
	     card = c
	  end
    end
	end
	
	if not card then
	
	for _,c in ipairs(cards) do
	  if (c:getSuitString()=="heart" or c:getSuitString()=="spade") then
	     card = c
	  end
	end
	if not card then
	    local cards = sgs.QList2Table(player:getEquips())
		self:sortByUseValue(cards, true)
		 for _,c in ipairs(cards) do
	  if c:getSuitString()=="heart" or c:getSuitString()=="spade" then
	     card = c
	  end
    end
	end
	
	end
	
	if target and card then
		use.card = sgs.Card_Parse("@ShisoCard="..card:getEffectiveId().."&shiso")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_invoke.zahyo = function(self, data)
  return true
end

sgs.ai_skill_invoke.quzhuaddtarget = function(self, data)
	local use = data:toCardUse()
	if use and use.card and self:isEnemy(use.to:first()) then return true end
	return false
end

sgs.ai_skill_invoke.quzhudamage= function(self, data)
	local player= data:toPlayer()
	if player and self:isEnemy(player) then return true end
	return false
end

sgs.ai_skill_invoke.jinji = function(self, data)
  local damage = data:toDamage()
  if damage.from and damage.from:getKingdom()==self.player:getKingdom() then return false end
  return true
end

sgs.ai_skill_playerchosen.jinji = function(self, targets, max_num, min_num)
  for _,p in sgs.qlist(self.room:getAlivePlayers()) do
     if self:isEnemy(p) and p:getMark("jinji_used")==0 and not self.player:inMyAttackRange(p) and p:getMark("@quzhu")==0 then
        return p
     end
	 if self:isEnemy(p) and p:getMark("jinji_used")==0 and p:getMark("@quzhu")==0 then
        return p
     end
	 if self:isEnemy(p) and p:getMark("jinji_used")==0 and  p:getMark("@quzhu")==1 then
        return p
     end
	 if self:isEnemy(p) and p:getMark("jinji_used")==0 and  p:getMark("@quzhu")==2 then
        return p
     end
  end
end

sgs.ai_skill_choice.docommand_shizu = function(self, choices, data)
   local n = data:toInt()
   if n==1 or n==2 then
     return "yes"
   else
     return "no"
   end	 
end