--[[
    复兴之章 AI（源码/翻译复核版）
    核对依据：RevolutionPackage C++/H 与复兴之章中文翻译。
    实际触发条件、data 类型、选项字段和结算流程以当前 C++ 源码为准。
]]--

function SmartAI:useCardGuangyuCard(card, use)
    local room=self.room
	for _,v in ipairs(self.friends) do
		if not v:faceUp() then
			use.card = card
			if use.to then use.to:append(v) end
			return
		end
	end
	for _,v in ipairs(self.friends) do
	    local keys=0
	    for _,c in sgs.qlist(v:getJudgingArea()) do
		  if c:isKindOf("Key") then
		    keys=keys+1
		  end
		end
		if v:containsTrick("keyCard") and v:isWounded() then
			if not card:isAvailable(self.player) then return end
	        if sgs.Sanguosha:isProhibited(self.player, v, card)then return end
			use.card = card
			if use.to then use.to:append(v) end
			return
		end
	end
	for _,v in ipairs(self.friends) do
		if v:isChained() then
			if not card:isAvailable(self.player) then return end
			if sgs.Sanguosha:isProhibited(self.player, v, card)then return end
			use.card = card
			if use.to then use.to:append(v) end
			return
		end
	end
	for _,v in ipairs(self.friends) do
		if v:hasFlag("Global_Dying") then
			if not card:isAvailable(self.player) then return end
	        if sgs.Sanguosha:isProhibited(self.player, v, card)then return end
			use.card = card
			if use.to then use.to:append(v) end
			return
		end
	end
end
sgs.ai_use_priority.GuangyuCard = 1.2
sgs.ai_use_value.GuangyuCard = 6
sgs.ai_keep_value.GuangyuCard = 6
sgs.ai_card_intention.GuangyuCard = -60

function SmartAI:useCardEireishoukan(card, use)
    if not card:isAvailable(self.player) then return end
	if not self:hasTrickEffective(card, self.player, self.player) then return end
	use.card = card
end
sgs.ai_use_priority.Eireishoukan = 3
sgs.ai_use_value.Eireishoukan = 6.5
sgs.ai_keep_value.Eireishoukan = 3
sgs.ai_card_intention.Eireishoukan= -60

sgs.ai_nullification.Eireishoukan = function(self, card, from, to, positive, keep)
	if positive then
		if self:isEnemy(to) then
			return true, true
		end
	else
		if self:isFriend(to) then return true, true end
	end
	return
end

function SmartAI:useCardIsekai(card, use)
    if not card:isAvailable(self.player) then return end
	if not self:hasTrickEffective(card, self.player, self.player) then return end
	use.card = card
end
sgs.ai_use_priority.Isekai = 0
sgs.ai_use_value.Isekai = 6.5
sgs.ai_keep_value.Isekai= 3
sgs.ai_card_intention.Isekai= -60

sgs.ai_nullification.Iseikai = function(self, card, from, to, positive, keep)
	if positive then
		if self:isEnemy(to) then
			return true, true
		end
	else
		if self:isFriend(to) then return true, true end
	end
	return
end

sgs.ai_skill_choice.isekai = function(self, choices, data)
   local n = data:toInt()
   local m = self.player:getMaxHp()
   if n<=m then
      return "draw_maxhpcards_recover"
   end
   if m<n then
      return "draw_throwcards"
   end
end

function SmartAI:useCardRulerCard(card, use)
    if not card:isAvailable(self.player) then return end
	if not self:hasTrickEffective(card, self.player, self.player) then return end
	use.card = card
end
sgs.ai_use_priority.RulerCard = 0
sgs.ai_use_value.RulerCard = 6.5
sgs.ai_keep_value.RulerCard= 3

sgs.ai_skill_playerchosen.ruler_card = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then return p end
	end
end

sgs.ai_skill_invoke.IceSlash = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
		if self:getDamagedEffects(target, self.players, true) or self:needToLoseHp(target, self.player, true) then return false
		elseif target:isChained() and self:isGoodChainTarget(target, self.player, nil, nil, damage.card) then return false
		elseif self:isWeak(target) or damage.damage > 1 then return true
		elseif target:getLostHp() < 1 then return false end
		return true
	else
		if target:hasArmorEffect("PeaceSpell") and damage.nature ~= sgs.DamageStruct_Normal then return true end
		if self:isWeak(target) then return false end
		if damage.damage > 1 or self:hasHeavySlashDamage(self.player, damage.card, target) then return false end
		if target:hasShownSkill("lirang") and #self:getFriendsNoself(target) > 0 then return false end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and not (target:hasArmorEffect("SilverLion") and target:isWounded()) then return true end
		local num = target:getHandcardNum()
		if self.player:hasSkill("tieqi") or self:canLiegong(target, self.player) then return false end
		if target:hasShownSkill("tuntian") and target:getPhase() == sgs.Player_NotActive then return false end
		if target:hasShownSkills(sgs.need_kongcheng) then return false end
		if target:getCards("he"):length()<4 and target:getCards("he"):length()>1 then return true end
		return false
	end
end

--for shifeng
sgs.ai_skill_use["@shifeng_use"] = function(self, prompt, method)
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
	if self.player:containsTrick("indulgence") and string.find(choices, "shifeng_otherdraw", 1, true) then
		return "shifeng_otherdraw"
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
		if card:getNumber() > 10 then
			OK =true
		end
	end
	if OK or self.player:getHandcardNum()>4 then
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

-- 忍耐、绽放的完整决策在文件末尾“规则文本复核层”统一定义。

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
	if not self:isEnemy(data:toPlayer()) then return true end
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
		if self.player:getHandcardNum() < self.player:getHp() * 2 then return "nishen_draw" end
		return "nishen_recover"
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

sgs.ai_skill_invoke.zahyo = true

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

sgs.ai_skill_invoke.shizu = function(self, data)
  local damage = data:toDamage()
  if damage.from and damage.from:getKingdom()==self.player:getKingdom() then return false end
  return true
end

sgs.ai_skill_choice.docommand_shizu = function(self, choices, data)
   local n = data:toInt()
   if n==1 or n==2 then
     return "yes"
   else
     return "no"
   end	 
end

--朝潮
fanqian_skill={}
fanqian_skill.name="fanqian"
table.insert(sgs.ai_skills,fanqian_skill)
fanqian_skill.getTurnUseCard=function(self,inclusive)
	if self:getCardsNum("Peach") +  self:getCardsNum("Jink") + self:getCardsNum("Analeptic") +  self:getCardsNum("Nullification") >= self.player:getHandcardNum() then return end
	if self.player:usedTimes("FanqianCard") > self.player:getAliveSiblings():length() then return end
	return sgs.Card_Parse("@FanqianCard=.&fanqian")
end

sgs.ai_skill_use_func.FanqianCard = function(card,use,self)
	local card

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUsePriority(cards)

	--check equips first
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Armor") or card:isKindOf("Weapon") then
			if not self:getSameEquip(card) then
			elseif card:isKindOf("GudingBlade") and self:getCardsNum("Slash") > 0 then
				local HeavyDamage
				local slash = self:getCard("Slash")
				for _, enemy in ipairs(self.enemies) do
					if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy) and
						self:slashIsEffective(slash, enemy) and not self.player:hasSkill("jueqing") and enemy:isKongcheng() then
							HeavyDamage = true
							break
					end
				end
				if not HeavyDamage then table.insert(equips, card) end
			else
				table.insert(equips, card)
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end

	if #equips > 0 then

		local select_equip, target
		for _, friend in ipairs(self.friends) do
			for _, equip in ipairs(equips) do
				if not self:getSameEquip(equip, friend) and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
			for _, equip in ipairs(equips) do
				if not self:getSameEquip(equip, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
		end

		if target then
			use.card = sgs.Card_Parse("@FanqianCard="..select_equip:getEffectiveId().."&fanqian")
			if use.to then use.to:append(target) end
			--self.room:setTag("fanqian_target",sgs.QVariant(target:getSeat()))
			return
		end
	end

	for _, c in ipairs(cards) do
		if not c:isKindOf("Jink") and not c:isKindOf("Nullification") and not c:isKindOf("HegNullification") then
			if c:isKindOf("Slash") or c:isKindOf("SingleTargetTrick") or c:isKindOf("Lightning") or c:isKindOf("AOE") then
				card = c
				break
			end
		end
	end

	if card then
		local target
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getMark("@Buyu") > 0 then target = p end
		end
		if not target then target = self.enemies[1] end
		if target then
			use.card = sgs.Card_Parse("@FanqianCard="..card:getEffectiveId().."&fanqian")
			if use.to then use.to:append(target) end
			--self.room:setTag("fanqian_target",sgs.QVariant(target:getSeat()))
			return
		end
	else
		--peach
		for _, c in ipairs(cards) do
			if c:isKindOf("Peach") or c:isKindOf("GodSalvation") then
				card = c
				break
			end
		end
		if card then
			local target
			local minHp = 100
			for _,friend in ipairs(self.friends) do
				local hp = friend:getHp()
				if friend:getHp()==friend:getMaxHp() then
					hp = 1000
				end
				if self:hasSkills(sgs.masochism_skill, friend) then
					hp = hp - 1
				end
				if friend:isLord() then
					hp = hp - 1
				end
				if hp < minHp then
					minHp = hp
					target = friend
				end
			end
			for _,friend in ipairs(self.friends) do
				if friend:objectName() == "SE_Kirito" and friend:getHp() == 1 then
					target = friend
				end
			end
			if target then
				use.card = sgs.Card_Parse("@FanqianCard="..card:getEffectiveId().."&fanqian")
				if use.to then use.to:append(target) end
			--self.room:setTag("fanqian_target",sgs.QVariant(target:getSeat()))
				return
			end
		else
			for _, c in ipairs(cards) do
				if c:isKindOf("ExNihilo") or c:isKindOf("AmazingGrace") then
					card = c
					break
				end
			end
			if card then
				target = self:findPlayerToDraw(true, 2)
				if target then
					use.card = sgs.Card_Parse("@FanqianCard="..card:getEffectiveId().."&fanqian")
					if use.to then use.to:append(target) end
			--self.room:setTag("fanqian_target",sgs.QVariant(target:getSeat()))
					return
				end
			end
		end
	end
end
sgs.ai_skill_choice["fanqian"] = function(self, choices, data)
	return self.room:getTag("fanqian_target"):toString()
end

sgs.ai_use_value["FanqianCard"] = 8
sgs.ai_use_priority["FanqianCard"]  = 10
sgs.ai_card_intention["FanqianCard"] = 0

sgs.ai_skill_invoke.buyu = function(self, data)
	if #self.enemies == 0 then return false end
	local num = 0
	local other = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if (c:isKindOf("Slash") or c:isKindOf("SingleTargetTrick") or c:isKindOf("Lightning") or c:isKindOf("AOE")) and not c:isKindOf("Collateral") then
			num = num + 1
		elseif not c:isKindOf("Analeptic") and not c:isKindOf("Jink") then
			other = other + 1
		end
	end
	if num >= other then return true end
	return false
end

sgs.ai_skill_playerchosen.buyu = function(self, targets)
	return self:getPriorTarget()
end

--蓝羽浅葱
sgs.ai_skill_invoke.guanli = function(self, data)
    if not self:willShowForAttack() and not self:willShowForDefence() then return false end
	local PlayerNow = data:toPlayer()
	if self:isEnemy(PlayerNow) then
		sgs.guanli_reason = "enemy_discard"
		if PlayerNow:getHandcardNum() - PlayerNow:getMaxCards() > 1 then
			if self.player:getHandcardNum() > 3 then return true end
		elseif PlayerNow:getHandcardNum() - PlayerNow:getMaxCards() > 2 then
			if self.player:getHandcardNum() > 2 then return true end
		elseif PlayerNow:getHandcardNum() - PlayerNow:getMaxCards() > 4 then
			if self.player:getHandcardNum() > 0 then return true end
			if self.player:getEquips():length() > 0 then return true end
		end
	elseif self:isFriend(PlayerNow) then
		if self.player:getHandcardNum() > 0 then
			if self:hasSkills("qixin|shunshan|kanhu|shengjian|jianyu|huanyuan|zhanjing|gonglue|boxue|",PlayerNow) then
				sgs.guanli_reason = "friend_play"
				return true
			end
			if self:hasSkills("guanli|weigong|zhufu|luowang",PlayerNow) then
				sgs.guanli_reason = "friend_draw"
				return true
			end
		end
		if self.player:getHandcardNum() > 3 then
			sgs.guanli_reason = "friend_draw"
			return true
		end
	end
	return false
end

sgs.ai_skill_choice.guanli = function(self, choices, data)
	if sgs.guanli_reason == "friend_draw" then return "Gl_draw"
	elseif sgs.guanli_reason == "friend_play" then return "Gl_play"
	elseif sgs.guanli_reason == "enemy_discard" then return "Gl_discard"
	end
end

poyi_skill={}
poyi_skill.name="poyi"
table.insert(sgs.ai_skills,poyi_skill)
poyi_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("PoyiCard")  then return end
	if #self.enemies < 1 or self.room:getAlivePlayers():length()<=2 then return end
	return sgs.Card_Parse("@PoyiCard=.&poyi")
end

sgs.ai_skill_use_func.PoyiCard = function(card,use,self)
	local target
	local slashtarget
	local source = self.player
	for _,enemy in ipairs(self.enemies) do
		if source:getHp()<=enemy:getHp() then
			target = enemy
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if source:getHp()<=enemy:getHp() and enemy:getHp() == 2 then
			target = enemy
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and source:getHp()<=enemy:getHp() then
			target = enemy
		end
	end
	for _,friend in ipairs(self.friends_noself) do
		if source:getHp()<= friend:getHp() and  not self.player:isFriendWith(friend) then
			target = friend
		end
	end
	if target then
	    for _,enemy in ipairs(self.enemies) do
			if target:inMyAttackRange(enemy) and target:objectName()~=enemy:objectName() then
				slashtarget = enemy
			end
		end
	end
	if target and slashtarget then
		use.card = sgs.Card_Parse("@PoyiCard=.&poyi")
		if use.to then use.to:append(target) end
		if use.to then use.to:append(slashtarget) end
		return
	end
end

sgs.ai_use_value.PoyiCard = 5
sgs.ai_use_priority.PoyiCard = 2
sgs.ai_card_intention.PoyiCard = 0

chicheng_skill={}
chicheng_skill.name="chicheng"
table.insert(sgs.ai_skills,chicheng_skill)
chicheng_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if not (source:getHandcardNum() >= 2 or source:getHandcardNum() > source:getHp()) then return end
	if not self:willShowForAttack() and not self:willShowForDefence() then return end
	if source:hasUsed("ChichengCard") then return end
	return sgs.Card_Parse("@ChichengCard=.&chicheng")
end

sgs.ai_skill_use_func.ChichengCard = function(card,use,self)
	local cards=sgs.QList2Table(self.player:getHandcards())
	local cards2=sgs.QList2Table(self.player:getEquips())
	local needed = {}
	local num = 2
	if not self.player:isWounded() and self.player:getSiblings():length()<=1 then num = 1 end
	if self.player:getHandcardNum() - self.player:getHp() > 2 then num = self.player:getHandcardNum() - self.player:getHp() end
	for _,acard in ipairs(cards) do
		if #needed < num then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	for _,acard in ipairs(cards2) do
		if #needed < num then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	if needed then
		use.card = sgs.Card_Parse("@ChichengCard="..table.concat(needed,"+").."&chicheng")
		return
	end
end

sgs.ai_use_value.ChichengCard = 2
sgs.ai_use_priority.ChichengCard  = 1.2

sgs.ai_skill_invoke.zhikong = function(self, data)
	local pname = data:toPlayer():objectName()
	local p
	for _,r in sgs.qlist(self.room:getAlivePlayers()) do
		if r:objectName() == pname then p = r end
	end
	if not p then return false end
	if self:isFriend(p) and self.player:getPile("akagi_lv"):length() > 1 and not p:hasShownSkills("pasheng|wushi") then return true end
	if self:isFriend(p) and p:isFriendWith(self.player) then return true end
	if p:objectName() == self.player:objectName() then return true end
	return false
end

sgs.ai_skill_invoke.lianchui = function(self, data)
  return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.lianchui= function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) then return target end
	end
	return nil
end

sgs.ai_skill_invoke.xianshu = function(self, data)
  return self:willShowForDefence()
end

sgs.ai_skill_playerchosen.xianshu= function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) then return target end
	end
	return nil
end

sgs.ai_skill_invoke.huanbing = function(self, data)
  if not self:willShowForAttack() and not self:willShowForDefence() then return false end
  local damage = data:toDamage()
  if damage and damage.to then return self:isEnemy(damage.to) end
  return #self.enemies>0
end

sgs.ai_skill_playerchosen.huanbing= function(self, targets)
	return self:getPriorTarget()
end

sgs.ai_skill_invoke.trial = function(self, data)
   if not self:willShowForAttack() and not self:willShowForDefence() then return false end
   local use = data:toCardUse()
   if self:isEnemy(use.from) and self:isFriend(use.to:at(0)) then return true end
   if self:isEnemy(use.from) and use.from:isFriendWith(use.to:at(0)) then return true end
end

local yaozhan_skill = {}
yaozhan_skill.name = "yaozhan"
table.insert(sgs.ai_skills, yaozhan_skill)
yaozhan_skill.getTurnUseCard = function(self)
	if not self:willShowForAttack() then
		return
	end
	if self.player:hasUsed("YaozhanCard") then return end
	return sgs.Card_Parse("@YaozhanCard=.&yaozhan")
end

sgs.ai_skill_use_func.YaozhanCard = function(YZCard, use, self)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		table.insert(targets, enemy)
	end
	if #targets == 0 then return end
	sgs.ai_use_priority.YaozhanCard = 8
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _, card in sgs.qlist(self.player:getCards("h")) do
			if card:isKindOf("Armor") and self:evaluateArmor(card) > 3 then
				sgs.ai_use_priority.YaozhanCard = 5.9
				break
			end
		end
	end
	if use.to then
		self:sort(targets, "defenseSlash")
		use.to:append(targets[1])
	end
	use.card = YZCard
end


local function getSlashNum(player)
	local num = 0
	for _,card in sgs.qlist(player:getHandcards()) do
		if card:isKindOf("Slash") then
			num = num + 1
		end
	end
	return num
end

local poshi_skill={}
poshi_skill.name="poshi"
table.insert(sgs.ai_skills,poshi_skill)
poshi_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("PoshiCard") then return end
	if #self.enemies < 1 then return end
	if getSlashNum(self.player) < 2 then return end
	if self.player:getHp() < 2 then return end
	if getSlashNum(self.player) < 3 and self.player:getHp() < 3 then return end
	return sgs.Card_Parse("@PoshiCard=.&poshi")
end

sgs.ai_skill_use_func.PoshiCard = function(card,use,self)
	use.card = sgs.Card_Parse("@PoshiCard=.&poshi")
	return
end

sgs.ai_use_value.PoshiCard = 7
sgs.ai_use_priority.PoshiCard = 9

sgs.ai_skill_invoke.liansuo = true

sgs.ai_skill_playerchosen.liansuo = function(self, targets)
     local target
     for _, enemy in ipairs(self.enemies) do
		if not enemy:isChained() then
			target = enemy
		end
	 end
	 if target then return target end
end

sgs.ai_skill_invoke.yinguo = function(self, data)
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasShownOneGeneral() and self:isFriend(p) then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.yinguo = function(self, targets)
	local min_card_num = 100
	local target
	for _,p in sgs.qlist(targets) do
		if p:hasShownOneGeneral() and self:isFriend(p) then
			if p:getHandcardNum() < min_card_num then
				target = p
				min_card_num = p:getHandcardNum()
			end
		end
	end
	if target then return target end
end

local jiuzhu_skill={}
jiuzhu_skill.name="jiuzhu"
table.insert(sgs.ai_skills,jiuzhu_skill)
jiuzhu_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("JiuzhuCard") then return end
	if #self.friends_noself < 1 then return end
	return sgs.Card_Parse("@JiuzhuCard=.&jiuzhu")
end

sgs.ai_skill_use_func.JiuzhuCard = function(card,use,self)
    local target1
	local target2
	for _,p in ipairs(self.friends_noself) do
	   if p:getHandcardNum() < p:getMaxHp() or p:isWounded() then
	     target1 = p
	   end
	end
	for _,p in ipairs(self.friends_noself) do
		if (p:getHandcardNum() < p:getMaxHp() or p:isWounded()) and p:objectName()~=target1:objectName() then
	     target2 = p
	   end
	end
	if (self.player:getHp()==1 and (not self.player:hasSkill("shexin") or self.player:getMark("@shexin")==0) and self.player:getHandcardNum()>3) then
	   return
	end
	if target1 then 
	   use.card = sgs.Card_Parse("@JiuzhuCard=.&jiuzhu")
	   if use.to then use.to:append(target1) end
	end
	if use.to and target2 then 
	   use.to:append(target2)
	end
	return
end

sgs.ai_skill_invoke.shexin = true

sgs.ai_skill_use["@@shexin"] = function(self, prompt)
	local targets = {}
	local dest
	local card
	for _,p in ipairs(self.friends) do
	  dest = p
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local equips=sgs.QList2Table(self.player:getEquips())
	self:sortByUseValue(cards,true)
	self:sortByUseValue(equips,true)
	for _,acard in ipairs(cards) do
		if  acard:isRed() then
			card =acard
		end
	end
	for _,acard in ipairs(equips) do
		if acard:isRed()  then
			card =acard
		end
	end
	if dest and card then
	  return ("@ShexinCard="..card:getEffectiveId().."&->" .. dest:objectName())
	else
	  return "."
	end
end

sgs.ai_skill_invoke.xintiao = true

sgs.ai_skill_playerchosen.xintiao = function(self, targets, max_num, min_num)
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) then return target end
	end
	return nil
end

sgs.ai_skill_invoke.suipian = true

local lunhui_skill = {}
lunhui_skill.name = "lunhui"
table.insert(sgs.ai_skills, lunhui_skill)
lunhui_skill.getTurnUseCard = function(self,room,player,data)
	if self.player:hasUsed("ViewAsSkill_lunhuiCard") or self.player:getPile("Fragments"):length()==0 or self.player:getKingdom()~="magic" then return end
	local id
	local idn
	local ids = self.player:getPile("Fragments")
	for _,i in sgs.qlist(ids) do
	    id = tostring(i)
		idn = i
		break
    end
	if not id then return end
	local pattern = self.player:property("lunhui_card"):toString()
    if pattern == "" then
	  return
	end
	local card = sgs.Sanguosha:getCard(idn)
	local str = sgs.Card_Parse(pattern..":lunhui["..card:getSuitString()..":"..card:getNumberString().."]="..id.."&lunhui")
    local can
	if self:getUseValue(str) > 0.2 then
       can = true
     end
	if can and str and id then
		return str
	end
end

sgs.ai_skill_invoke.yandan = true

sgs.ai_skill_invoke.lunpo = function(self, data)
	local use = data:toCardUse()
	if use.from and self:isEnemy(use.from) then
		if use.card:isKindOf("SingleTargetTrick") and use.to:length() > 0 and self:isFriend(use.to:at(0)) then
			if use.card:isKindOf("Snatch") or use.card:isKindOf("Duel") then return true end
			--if use.card:isKindOf("Dismantlement") and use.to:at(0):getEquips():length() > 0 then return true end
			if use.card:isKindOf("DelayedTrick") and not use.card:isKindOf("KeyTrick") then return true end
		end
		if use.card:isKindOf("Slash") and self:isWeak(use.to:at(0)) and self:isFriend(use.to:at(0)) then return true end
		if use.card:isKindOf("Jink") or use.card:isKindOf("Peach") then return true end
		if use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect") then
			for _,p in ipairs(self.friends) do
				if self:isWeak(p) then
					return true
				end
			end
		end
	elseif not use.from then	
       if #self.enemies == 0 then return false end
	local min = 100
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() < min then min = p:getHp() end
	end
	local num = self.player:getPile("yandan"):length()
	if min <= 2 then
		local toFight = self:getPriorTarget()
		if toFight:getHp() <= 1 then return true end
		if toFight:hasSkills(sgs.masochism_skill) then return true end
	end
	return false
    end
	return false
end

sgs.ai_view_as.zizheng = function(card, player, card_place)
	if player:getMark("zizheng_used") > 0 then return end
    local list = player:getPile("yandan")
	if list:length()<2 then return end
	local card1
	local card2
	for _,i in sgs.qlist(list) do
	   for _,j in sgs.qlist(list) do
	      local c1 = sgs.Sanguosha:getCard(i)
	      local c2 = sgs.Sanguosha:getCard(j)
		  if i ~= j and (c1:getNumber()==c2:getNumber() or c1:getSuit()==c2:getSuit()) then
		      card1 = c1
			  card2 = c2
			  break
		  end
	   end
	end
	if not card1 or not card2 then
	   card1 = sgs.Sanguosha:getCard(list:at(0))
	   card2 = sgs.Sanguosha:getCard(list:at(1))
	end
	
	local id1 = card1:getEffectiveId()
	local id2 = card2:getEffectiveId()
	local str = ("heg_nullification:%s[%s:%s]=%d+%d&zizheng"):format("zizheng", "to_be_decided", "-", id1, id2)
	return str
end

sgs.ai_skill_choice.zizheng= function(self, choices, data)
	if self.player:getPile("yandan"):length()<=2 then
	  return "zizheng_transform"
	end
end

huanshi_skill={}
huanshi_skill.name="huanshi"
table.insert(sgs.ai_skills,huanshi_skill)
huanshi_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if self.player:isKongcheng() then return end
	if self.player:hasUsed("HuanshiCard") then return end
	if #self.enemies == 0 then return end
	return sgs.Card_Parse("@HuanshiCard=.&huanshi")
end

sgs.ai_skill_use_func.HuanshiCard = function(card,use,self)
	local target
	local source = self.player
	local m = 998
	
	for _,enemy in ipairs(self.enemies) do
	    if enemy:getHandcardNum()<m and enemy:getHandcardNum()>0  then
		  target = enemy
		  m = enemy:getHandcardNum()
		end
	end

	if target then
		use.card = sgs.Card_Parse("@HuanshiCard=.&huanshi")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_invoke.kuangzao= function(self, data)
   return self:isEnemy(data:toPlayer())
end

sgs.ai_skill_invoke.haoqi= function(self, data)
	local card = self.player:property("haoqi_card"):toCard()
	return self:isEnemy(data:toPlayer()) or card:isRed()
end

local function add_different_kingdoms2(self, target, targets)
   for _,p in ipairs(targets) do
	 if target:isFriendWith(p) then return false end
   end
   return true
end

shouji_skill={}
shouji_skill.name="shouji"
table.insert(sgs.ai_skills,shouji_skill)
shouji_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("ShoujiCard") then return end
	return sgs.Card_Parse("@ShoujiCard=.&shouji")
end

sgs.ai_skill_use_func.ShoujiCard = function(card,use,self)
	local needed = {}
	local hp = math.max(self.player:getHp(), 1)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local equips = sgs.QList2Table(self.player:getEquips())
	self:sortByKeepValue(cards)
	self:sortByKeepValue(equips)
	for _,acard in ipairs(cards) do
		table.insert(needed, acard:getEffectiveId())
			if #needed >= hp then
				break
			end
	end
	for _,acard in ipairs(equips) do
			if #needed < hp then
				table.insert(needed, acard:getEffectiveId())
			end
	end
	
	local targets = {}
	for _,p in ipairs(self.enemies) do
	  if #targets <hp and not p:isKongcheng() and add_different_kingdoms2(self, p, targets) then table.insert(targets, p) end
	end

   if #needed == hp and #targets >0  then
	  use.card = sgs.Card_Parse("@ShoujiCard="..table.concat(needed,"+").."&shouji")
	  if use.to then
        for _,target in ipairs(targets) do	  
	      use.to:append(target)
		end
	  end
	  return
   end
end

sgs.ai_use_value.ShoujiCard= 8
sgs.ai_use_priority.ShoujiCard  = 5

sgs.ai_skill_invoke.zhouli= function(self, data)
	local to = self.player:property("zhouli_to"):toPlayer()
	return (self:isEnemy(data:toPlayer()) and not to:hasShownAllGenerals()) or (self:isFriend(to) and self:isFriend(data:toPlayer()))
end

sgs.ai_skill_choice.zhouli = function(self, choices, data)
	if self:isFriend(data:toDamage().to) and table.contains(choices:split("+"), "zhouli_prevent") then
		return "zhouli_prevent"
	end
end

sgs.ai_skill_invoke.zhenyan= function(self, data)
   for _,p in ipairs(self.friends_noself) do
	  if #self.room:getTag(p:objectName().."zhenyan"):toStringList()>0 then
	    return true
	  end
   end
end

sgs.ai_skill_playerchosen.zhenyan = function(self, targets, max_num, min_num)
  for _,p in ipairs(self.friends_noself) do
	  if #self.room:getTag(p:objectName().."zhenyan"):toStringList()>0 then
	    return p
	  end
   end
end

sgs.ai_skill_invoke.yuyue= function(self, data)
   if self.player:hasShownSkill("yuyue") then return true end
   return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.xianhai= function(self, data)
	return not data:toPlayer():isFriendWith(self.player)
end

sgs.ai_skill_playerchosen.xianhai= function(self, targets)
	return self.player
end

sgs.ai_skill_invoke.wuren = function(self, data)
   return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.wuren = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self.player:isFriendWith(p) then return p end
	end
end

sgs.ai_skill_invoke.tongziqie= function(self, data)
   return self:isEnemy(data:toDamage().to)
end

sgs.ai_skill_invoke.paoqie= function(self, data)
   return self:isEnemy(data:toPlayer())
end

sgs.ai_skill_invoke.xiaowuwan= function(self, data)
   return self:isEnemy(data:toCardUse().to:at(0)) and getCardsNum("Jink", data:toCardUse().to:at(0), self.player)>0 and not self.player:isNude()
end

sgs.ai_skill_discard["xiaowuwan"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
end


sgs.ai_skill_invoke.weituo= function(self, data)
   return self:isEnemy(data:toPlayer()) or self.player:willBeFriendWith(data:toPlayer())
end

sgs.ai_skill_invoke.wushi= function(self, data)
   return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.wushi= function(self, targets)
    local result = {}
	for _,name in sgs.qlist(targets) do
		if self:isEnemy(name) then table.insert(result, name) end
	end
	return result
end

sgs.ai_skill_invoke.zhuisha = function(self, data)
	return self:isEnemy(data:toPlayer()) and not data:toPlayer():isNude()
end

sgs.ai_skill_discard["zhuisha"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
end

sgs.ai_skill_invoke.songzang = function(self, data)
	return self:isEnemy(data:toPlayer())
end

sgs.ai_skill_invoke.shashou = function(self, data)
	return self:isEnemy(data:toPlayer())
end

sgs.ai_skill_invoke.aisha = true

sgs.ai_skill_invoke.aishadraw = true

sgs.ai_skill_invoke.xuexi = true

sgs.ai_skill_invoke.qinggan = true

sgs.ai_skill_cardask["@shengmu"] = function(self, data)
  local damage = data:toDamage()
  local can
  if damage and self:isFriend(damage.to) then
     if damage.to:isWounded() then
	    can = true
	 end
  end
  for _, c in sgs.qlist(self.player:getCards("he")) do
         if c:getSuitString() == "heart" and can then
		return "$" .. c:getEffectiveId()
	 end
  end
  for _, c in sgs.qlist(self.player:getCards("he")) do
	 if can then
		return "$" .. c:getEffectiveId()
	 end
  end
  return ""
end

sgs.ai_skill_invoke.fenjie = function(self, data)
	local player=data:toPlayer()
	local card = player:property("fenjie_card"):toCard()
	if self:isEnemy(player) and (self.player:getMark("drank") == 0 or not card:isKindOf("Slash")) then
	    return true
	end
end

sgs.ai_skill_invoke.jiaji = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_view_as.gaoling = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local ask = sgs.Sanguosha:getCurrentCardUsePattern()
	if (card_place == sgs.Player_PlaceEquip or card_place == sgs.Player_PlaceHand) and ask ~= "jink" and player:getHandcardNum()==math.ceil(player:getHandcardNum()/2) * 2 then
		return ("nullification:gaoling[%s:%s]=%d%s"):format(suit, number, card_id, "&gaoling")
	end
	if  (card_place == sgs.Player_PlaceEquip or card_place == sgs.Player_PlaceHand) and ask == "jink" and player:getHandcardNum()==math.ceil(player:getHandcardNum()/2) * 2 then
		return ("jink:gaoling[%s:%s]=%d%s"):format(suit, number, card_id, "&gaoling")
	end
end

sgs.ai_skill_choice.gaoling = "draw1card"

sgs.ai_skill_invoke.bingdu = true

sgs.ai_skill_invoke.juewang = function(self, data)
	return self:willShowForAttack()
end

sgs.ai_skill_invoke.kaihua = true

daokegive_skill={}
daokegive_skill.name="daokegive"
table.insert(sgs.ai_skills,daokegive_skill)
daokegive_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if source:isNude() then return end
	if source:hasUsed("DaokegiveCard") then return end
	return sgs.Card_Parse("@DaokegiveCard=.&daokegive")
end

sgs.ai_skill_use_func.DaokegiveCard = function(card,use,self)
	local target
	local source = self.player
	for _,friend in ipairs(self.friends) do
		if friend:hasShownSkill("daoke") then
			target = friend
		end
	end
	local cards=sgs.QList2Table(self.player:getHandcards())
	local equips=sgs.QList2Table(self.player:getEquips())
	local needed = {}
	for _,acard in ipairs(cards) do
		if #needed < 1 then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	for _,acard in ipairs(equips) do
		if #needed < 1 then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	if target and #needed>0 then
		use.card = sgs.Card_Parse("@DaokegiveCard="..table.concat(needed,"+").."&daokegive")
		if use.to then use.to:append(target) end
		return
	end
end

--[[
    复兴之章 AI 优化层
    保留原 AI 的完整接口，在此集中修正高风险判断并补齐缺失技能。
    所有循环仅使用 Lua table/ipairs 或 Qt QList/sgs.qlist 对应的合法组合。
]]--

local function fx_choices(choices)
	return choices:split("+")
end

local function fx_has_choice(choices, wanted)
	for _, choice in ipairs(fx_choices(choices)) do
		if choice == wanted then return true end
	end
	return false
end

local function fx_low_value_cards(self, place)
	local cards = sgs.QList2Table(self.player:getCards(place or "he"))
	self:sortByKeepValue(cards)
	return cards
end

local function fx_best_friend(self, targets, wounded_first)
	local result = {}
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) then table.insert(result, p) end
	end
	if #result == 0 then return nil end
	if wounded_first then self:sort(result, "hp") else self:sort(result, "handcard") end
	return result[1]
end

local function fx_best_enemy(self, targets)
	local result = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(result, p) end
	end
	if #result == 0 then return nil end
	self:sort(result, "defense")
	return result[1]
end

local function fx_override_turn_skill(name, func)
	for _, skill in ipairs(sgs.ai_skills) do
		if skill.name == name then
			skill.getTurnUseCard = func
			return
		end
	end
	table.insert(sgs.ai_skills, {name = name, getTurnUseCard = func})
end

-- 包牌：修正异世界牌名拼写，并避免无收益或敌友未明时主动使用。
sgs.ai_nullification.Isekai = function(self, card, from, to, positive, keep)
	if not to then return false end
	if positive then return self:isEnemy(to) end
	return self:isFriend(to)
end

sgs.ai_skill_playerchosen.ruler_card = function(self, targets)
	return fx_best_friend(self, targets, true) or fx_best_enemy(self, targets)
end

-- 雪风：只邀请明确友方或能产生明确收益的已明置角色，不盲探暗将。
sgs.ai_skill_invoke.shifeng = function(self, data)
	if not self:willShowForDefence() and not self:willShowForAttack() then return false end
	if self.player:isWounded() then return true end
	for _, p in ipairs(self.friends_noself) do
		if p:isAlive() and (p:isWounded() or self.player:inMyAttackRange(p)) then return true end
	end
	return false
end

sgs.ai_skill_use["@@shifeng"] = function(self, prompt)
	local targets = {}
	for _, p in ipairs(self.friends_noself) do
		if p:isAlive() and (p:isWounded() or self.player:inMyAttackRange(p)) then
			table.insert(targets, p)
		end
	end
	if #targets == 0 then return "." end
	self:sort(targets, "handcard")
	local names = {}
	for i = 1, math.min(#targets, math.max(1, self.player:getHp())) do
		table.insert(names, targets[i]:objectName())
	end
	return "@ShifengCard=.->" .. table.concat(names, "+")
end

sgs.ai_skill_choice.shifeng = function(self, choices, data)
	local list = fx_choices(choices)
	for _, c in ipairs(list) do
		if c == "shifeng_drawself" and self.player:getHandcardNum() <= self.player:getHp() then return c end
	end
	for _, c in ipairs(list) do
		if c ~= "cancel" then return c end
	end
	return list[1]
end

-- 直言：有明确敌人且自身有可接受拼点牌时才发动。
fx_override_turn_skill("zhiyan", function(self)
	if self.player:hasUsed("ZhiyanCard") or #self.enemies == 0 then return nil end
	if not self:willShowForAttack() then return nil end
	local max_card = self:getMaxCard(self.player)
	if not max_card or (max_card:getNumber() < 8 and self.player:getHandcardNum() <= self.player:getHp()) then return nil end
	return sgs.Card_Parse("@ZhiyanCard=.&zhiyan")
end)

sgs.ai_skill_use_func.ZhiyanCard = function(card, use, self)
	local enemies = {}
	for _, p in ipairs(self.enemies) do
		if not p:isKongcheng() and not p:isNude() then table.insert(enemies, p) end
	end
	if #enemies == 0 then return end
	self:sort(enemies, "handcard")
	use.card = card
	if use.to then
		for i = 1, math.min(#enemies, 2) do use.to:append(enemies[i]) end
	end
end

-- 仁爱：避免原实现对稀疏数值表使用 ipairs；按伤害关系及生存压力选择。
sgs.ai_skill_invoke.rennai = function(self, data)
	local damage = data:toDamage()
	if not damage or not damage.to then return false end
	if self:isFriend(damage.to) then return true end
	return self:isWeak(self.player) and damage.to:objectName() == self.player:objectName()
end

sgs.ai_skill_choice.rennai = function(self, choices, data)
	local preferred = {"rennai_reduce", "rennai_cancel", "rennai_damage", "cancel"}
	if self.player:getHp() > 2 and self.player:getHandcardNum() > self.player:getHp() then
		preferred = {"rennai_damage", "rennai_reduce", "rennai_cancel", "cancel"}
	end
	for _, wanted in ipairs(preferred) do
		if fx_has_choice(choices, wanted) then return wanted end
	end
	return fx_choices(choices)[1]
end

-- 绽放：扩展伤害只在目标整体偏敌方时发动；冻结清除按敌友决定。
sgs.ai_skill_invoke.zhanfang = function(self, data)
	local use = data:toCardUse()
	if use.card and use.to:length() > 0 then
		local score = 0
		for _, p in sgs.qlist(use.to) do
			if self:isEnemy(p) then score = score + 1 elseif self:isFriend(p) then score = score - 2 end
		end
		return score > 0
	end
	return false
end

sgs.ai_skill_choice.zhanfang = function(self, choices, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and fx_has_choice(choices, "zhanfang_discard") then return "zhanfang_discard" end
	if fx_has_choice(choices, "cancel") then return "cancel" end
	return fx_choices(choices)[1]
end

-- 救助：低血量时不为普通补牌冒险；优先救濒弱友方，彻底消除空目标访问。
fx_override_turn_skill("jiuzhu", function(self)
	if self.player:hasUsed("JiuzhuCard") or #self.friends_noself == 0 then return nil end
	if self.player:getHp() <= 1 and not (self.player:hasSkill("shexin") and self.player:getMark("@shexin") > 0) then return nil end
	for _, p in ipairs(self.friends_noself) do
		if p:isWounded() or p:getHandcardNum() < math.min(3, p:getMaxHp()) then
			return sgs.Card_Parse("@JiuzhuCard=.&jiuzhu")
		end
	end
end)

sgs.ai_skill_use_func.JiuzhuCard = function(card, use, self)
	local friends = {}
	for _, p in ipairs(self.friends_noself) do
		if p:isWounded() or p:getHandcardNum() < math.min(3, p:getMaxHp()) then table.insert(friends, p) end
	end
	if #friends == 0 then return end
	self:sort(friends, "hp")
	use.card = card
	if use.to then
		use.to:append(friends[1])
		if friends[2] and self.player:getHp() > 2 then use.to:append(friends[2]) end
	end
end

sgs.ai_skill_invoke.shexin = function(self, data)
	if self.player:getMark("@shexin") == 0 then return false end
	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then return false end
	return true
end

sgs.ai_skill_use["@@shexin"] = function(self, prompt)
	local cards = fx_low_value_cards(self, "he")
	local chosen
	for _, c in ipairs(cards) do if c:isRed() then chosen = c break end end
	if not chosen then return "." end
	local dest = self.player
	for _, p in ipairs(self.friends_noself) do
		if not p:containsTrick("key") then dest = p break end
	end
	return "@ShexinCard=" .. chosen:getEffectiveId() .. "&->" .. dest:objectName()
end

-- 连锤、咒力、真言：只针对已确认敌友关系，避免用技能强行试探暗将。
sgs.ai_skill_invoke.lianchui = function(self, data)
	for _, p in ipairs(self.enemies) do
		if p:hasShownOneGeneral() and self.player:inMyAttackRange(p) then return true end
	end
	return false
end
sgs.ai_skill_playerchosen.lianchui = function(self, targets) return fx_best_enemy(self, targets) end

sgs.ai_skill_invoke.zhouli = function(self, data)
    -- 源码的askForSkillInvoke传入的是造成伤害的角色，
    -- 不是DamageStruct。
    local source = data:toPlayer()
    local victim =
        self.player:property("zhouli_to"):toPlayer()

    if not source or not victim then
        return false
    end

    -- 敌人造成伤害，且受伤角色仍有暗置人物牌：
    -- 发动后可以令伤害来源额外失去体力。
    if self:isEnemy(source)
        and not victim:hasShownAllGenerals() then
        return true
    end

    -- 友方造成伤害，且来源已经全部明置：
    -- 可以让其暗置人物牌，并在受伤者也是友方时防止伤害。
    if self:isFriend(source)
        and self:isFriend(victim)
        and source:hasShownAllGenerals() then
        return true
    end

    return false
end

sgs.ai_skill_invoke.zhenyan = function(self, data)
	for _, p in ipairs(self.friends_noself) do
		if #self.room:getTag(p:objectName() .. "zhenyan"):toStringList() > 0 then return true end
	end
	return false
end
sgs.ai_skill_playerchosen.zhenyan = function(self, targets)
	return fx_best_friend(self, targets, true)
end

-- 追杀：低价值牌换取敌方牌；送葬只对敌人加伤。
sgs.ai_skill_invoke.zhuisha = function(self, data)
	local target = data:toPlayer()
	if not target or not self:isEnemy(target) or target:isNude() then return false end
	local cards = fx_low_value_cards(self, "he")
	return cards[1] ~= nil and (self.player:getHandcardNum() > self.player:getHp() or self:getKeepValue(cards[1]) < 5)
end
sgs.ai_skill_invoke.songzang = function(self, data)
	local target = data:toPlayer()
	return target ~= nil and self:isEnemy(target)
end

sgs.ai_skill_cardchosen.zhuisha = function(self, who, flags)
    if not who then
        return -1
    end

    -- 第一优先级：真正危险的装备，例如强力武器。
    local dangerous = self:getDangerousCard(who)
    if dangerous and dangerous >= 0 then
        return dangerous
    end

    -- 第二优先级：真正有价值的装备。
    local valuable = self:getValuableCard(who)
    if valuable and valuable >= 0 then
        return valuable
    end

    -- 第三优先级：防具。
    -- 追杀移走防具既削弱防御，也为送葬的后续伤害创造条件。
    local armor = who:getArmor()
    if armor then
        local armor_id = armor:getEffectiveId()

        -- 不移走对敌人有负收益的防具。
        if self:evaluateArmor(armor, who) > 0 then
            return armor_id
        end
    end

    -- 第四优先级：防御坐骑。
    local defensive_horse = who:getDefensiveHorse()
    if defensive_horse then
        return defensive_horse:getEffectiveId()
    end

    -- 第五优先级：宝物。
    local treasure = who:getTreasure()
    if treasure then
        return treasure:getEffectiveId()
    end

    -- 第六优先级：手牌。
    -- 手牌不能准确判断内容时，选择一张手牌仍能削弱其防御资源。
    if not who:isKongcheng() then
        local handcards =
            sgs.QList2Table(who:getHandcards())

        if #handcards > 0 then
            return handcards[math.random(1, #handcards)]
                :getEffectiveId()
        end
    end

    -- 第七优先级：进攻坐骑和普通武器。
    local offensive_horse = who:getOffensiveHorse()
    if offensive_horse then
        return offensive_horse:getEffectiveId()
    end

    local weapon = who:getWeapon()
    if weapon then
        return weapon:getEffectiveId()
    end

    -- 最后的安全兜底。
    local cards = sgs.QList2Table(who:getCards(flags or "he"))
    if #cards > 0 then
        return cards[1]:getEffectiveId()
    end

    return -1
end

-- 贤淑：只为友方男性使用，并根据缺血/缺牌选择。
sgs.ai_skill_invoke.xianshu = function(self, data)
	for _, p in ipairs(self.friends) do if p:isMale() and p:isWounded() then return true end end
	return false
end
sgs.ai_skill_playerchosen.xianshu = function(self, targets) return fx_best_friend(self, targets, true) end
sgs.ai_skill_choice.xianshu = function(self, choices, data)
	local target = self.player:getTag("xianshu_target"):toPlayer()
	if target and target:getLostHp() >= 2 and fx_has_choice(choices, "xianshudraw") then return "xianshudraw" end
	if fx_has_choice(choices, "xianshurecover") then return "xianshurecover" end
	return fx_choices(choices)[1]
end

sgs.ai_skill_invoke.huanbing = function(self, data)
	local damage = data:toDamage()
	if damage and damage.to then return self:isEnemy(damage.to) and not damage.to:isNude() end
	return #self.enemies > 0 and self:willShowForAttack()
end
sgs.ai_skill_playerchosen.huanbing = function(self, targets) return fx_best_enemy(self, targets) end

-- 管理：仅为明确友方改写阶段；牌紧张时优先摸牌，能爆发时选择出牌。
sgs.ai_skill_invoke.guanli = function(self, data)
	local target = data:toPlayer()
	if not target or not self:isFriend(target) then return false end
	local cards = fx_low_value_cards(self, "h")
	return cards[1] ~= nil and (self.player:getHandcardNum() > 2 or self:getKeepValue(cards[1]) < 4.5)
end
sgs.ai_skill_choice.guanli = function(self, choices, data)
	local target = data:toPlayer()
	if target and target:getHandcardNum() <= 2 and fx_has_choice(choices, "Gl_draw") then return "Gl_draw" end
	if target and target:getHandcardNum() > target:getHp() and fx_has_choice(choices, "Gl_play") then return "Gl_play" end
	if fx_has_choice(choices, "Gl_draw") then return "Gl_draw" end
	return fx_choices(choices)[1]
end

-- 魔弹：补齐主动使用。依据“宝石”实体牌种类决定目标，不浪费高价值牌。
fx_override_turn_skill("modan", function(self)
	if self.player:hasUsed("ModanCard") or self.player:getPile("gem"):isEmpty() then return nil end
	if #self.enemies == 0 and #self.friends == 0 then return nil end
	local best_id
	local best_value = 100
	for _, id in sgs.qlist(self.player:getPile("gem")) do
		local c = sgs.Sanguosha:getCard(id)
		local v = self:getKeepValue(c)
		if v < best_value then best_value, best_id = v, id end
	end
	if not best_id then return nil end
	return sgs.Card_Parse("@ModanCard=" .. best_id .. "&modan")
end)

sgs.ai_skill_use_func.ModanCard = function(card, use, self)
	local sub = card:getSubcards():isEmpty() and nil or sgs.Sanguosha:getCard(card:getSubcards():first())
	if not sub then return end
	local targets = {}
	if sub:isKindOf("Jink") or sub:isKindOf("Nullification") or sub:isKindOf("HegNullification") then
		for _, p in ipairs(self.friends) do if self.player:inMyAttackRange(p) then table.insert(targets, p) end end
	else
		for _, p in ipairs(self.enemies) do if self.player:inMyAttackRange(p) then table.insert(targets, p) end end
	end
	if #targets == 0 then return end
	self:sort(targets, "defense")
	use.card = card
	if use.to then use.to:append(targets[1]) end
end
sgs.ai_use_value.ModanCard = 6.5
sgs.ai_use_priority.ModanCard = 5.5

-- 赤城：只存入溢出牌或为回复而投入两张低价值牌。
sgs.ai_skill_use_func.ChichengCard = function(card, use, self)
	local cards = fx_low_value_cards(self, "he")
	local need = self.player:isWounded() and 2 or 1
	if #cards < need then return end
	if not self.player:isWounded() and self.player:getHandcardNum() <= self.player:getHp() then return end
	local ids = {}
	for i = 1, need do table.insert(ids, cards[i]:getEffectiveId()) end
	use.card = sgs.Card_Parse("@ChichengCard=" .. table.concat(ids, "+") .. "&chicheng")
end

-- 挑战：避免向友方或身份未明者发起无谓互杀。
sgs.ai_skill_use_func.YaozhanCard = function(card, use, self)
	local enemies = {}
	for _, p in ipairs(self.enemies) do if p:hasShownOneGeneral() then table.insert(enemies, p) end end
	if #enemies == 0 then return end
	self:sort(enemies, "defenseSlash")
	use.card = card
	if use.to then use.to:append(enemies[1]) end
end

sgs.ai_skill_invoke.lianji = function(self, data)
	return self.player:getHp() > 1 or self.player:getHandcardNum() > 1
end

-- 连锁：仅选择未横置敌人；没有合法敌人时拒绝发动。
sgs.ai_skill_invoke.liansuo = function(self, data)
	for _, p in ipairs(self.enemies) do if not p:isChained() then return true end end
	return false
end
sgs.ai_skill_playerchosen.liansuo = function(self, targets)
	local enemies = {}
	for _, p in sgs.qlist(targets) do if self:isEnemy(p) and not p:isChained() then table.insert(enemies, p) end end
	if #enemies == 0 then return nil end
	self:sort(enemies, "hp")
	return enemies[1]
end

-- 碎片：起始获取始终有收益；受伤分配只援助友方。
sgs.ai_skill_invoke.suipian = function(self, data)
	local target = data:toPlayer()
	if not target then return true end
	return self:isFriend(target)
end

-- 轮破：修正 sgs.list/QList 混用；只拦截高收益敌方牌或在优势窗口封锁全场。
sgs.ai_skill_invoke.lunpo = function(self, data)
	local use = data:toCardUse()
	if use and use.card and use.from then
		if not self:isEnemy(use.from) then return false end
		for _, to in sgs.qlist(use.to) do
			if self:isFriend(to) and (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")
				or use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")) then return true end
		end
		return use.card:isKindOf("Peach") or use.card:isKindOf("Analeptic")
	end
	local min_hp = 99
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do min_hp = math.min(min_hp, p:getHp()) end
	return self.player:getPile("yandan"):length() >= min_hp and #self.enemies > #self.friends_noself
end

sgs.ai_skill_invoke.yandan = function(self, data)
	return self.player:getPile("yandan"):length() < 4
end

-- 好奇、收集：不为未知阵营盲目消耗大量牌。
sgs.ai_skill_invoke.haoqi = function(self, data)
	local target = data:toPlayer()
	local card = self.player:property("haoqi_card"):toCard()
	if not target or not card then return false end
	return self:isEnemy(target) or (self:isFriend(target) and card:isRed())
end

sgs.ai_skill_use_func.ShoujiCard = function(card, use, self)
	local hp = math.max(1, self.player:getHp())
	local targets = {}
	for _, p in ipairs(self.enemies) do
		if p:hasShownOneGeneral() and not p:isKongcheng() then table.insert(targets, p) end
	end
	if #targets == 0 then return end
	local cards = fx_low_value_cards(self, "he")
	if #cards < hp or (self.player:getHandcardNum() <= self.player:getHp() and hp > 1) then return end
	local ids = {}
	for i = 1, hp do table.insert(ids, cards[i]:getEffectiveId()) end
	use.card = sgs.Card_Parse("@ShoujiCard=" .. table.concat(ids, "+") .. "&shouji")
	if use.to then
		for i = 1, math.min(#targets, hp) do use.to:append(targets[i]) end
	end
end

-- 无视：返回 QList 所要求的 Lua table，只取消对友方不利的目标。
sgs.ai_skill_invoke.wushi = function(self, data)
	local use = data:toCardUse()
	if not use.card then return false end
	for _, p in sgs.qlist(use.to) do if self:isFriend(p) then return true end end
	return false
end
sgs.ai_skill_playerchosen.wushi = function(self, targets, max_num, min_num)
	local result = {}
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHp() > 1 then table.insert(result, p) end
	end
	return result
end

-- 学习/情感：获取友方关键牌，但不抢救命桃、酒和无懈；情感只为明确友方发动。
sgs.ai_skill_invoke.xuexi = function(self, data)
	local use = data:toCardUse()
	if not use.card or not use.from or not self:isFriend(use.from) then return false end
	if use.card:isKindOf("Peach") or use.card:isKindOf("Analeptic") or use.card:isKindOf("Nullification") then return false end
	return self.player:getMark("xuexi_used") == 0
end
sgs.ai_skill_invoke.qinggan = function(self, data)
	local use = data:toCardUse()
	return use.from ~= nil and self:isFriend(use.from)
end

-- 圣母：低价值牌优先，红桃只在额外摸牌确有价值时使用。
sgs.ai_skill_cardask["@shengmu"] = function(self, data)
	local damage = data:toDamage()
	if not damage or not damage.to or not self:isFriend(damage.to) or not damage.to:isWounded() then return "." end
	local cards = fx_low_value_cards(self, "he")
	if #cards == 0 then return "." end
	for _, c in ipairs(cards) do if c:getSuit() == sgs.Card_Heart then return "$" .. c:getEffectiveId() end end
	return "$" .. cards[1]:getEffectiveId()
end

-- 重组：补齐主动技、AG 与受赠目标。只用两张低价值牌换取弃牌堆中较高价值牌。
fx_override_turn_skill("chongzu", function(self)
	if self.player:hasUsed("ChongzuCard") or self.player:getCards("he"):length() < 2 then return nil end
	local cards = fx_low_value_cards(self, "he")
	if #cards < 2 then return nil end
	return sgs.Card_Parse("@ChongzuCard=" .. cards[1]:getEffectiveId() .. "+" .. cards[2]:getEffectiveId() .. "&chongzu")
end)
sgs.ai_skill_use_func.ChongzuCard = function(card, use, self) use.card = card end
sgs.ai_skill_askforag.chongzu = function(self, card_ids)
	local best, value = -1, -100
	for _, id in ipairs(card_ids) do
		local c = sgs.Sanguosha:getCard(id)
		local v = self:getUseValue(c)
		if v > value then best, value = id, v end
	end
	return best
end
sgs.ai_skill_playerchosen.chongzu = function(self, targets)
	return fx_best_friend(self, targets, true) or self.player
end
sgs.ai_skill_choice.chongzu = function(self, choices, data)
	if fx_has_choice(choices, "use_card_chongzu") then return "use_card_chongzu" end
	return fx_choices(choices)[1]
end

-- 愉悦本身为纯摸牌收益；陷害只改写致命伤害来源，优先嫁祸敌人。
sgs.ai_skill_invoke.yuyue = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence() or self.player:hasShownSkill("yuyue")
end
sgs.ai_skill_invoke.xianhai = function(self, data)
	local victim = data:toPlayer()
	return victim ~= nil and self:isEnemy(victim) and #self.enemies > 0
end
sgs.ai_skill_playerchosen.xianhai = function(self, targets)
	return fx_best_enemy(self, targets) or self.player
end

-- 绝望：仅在能封锁至少一名明确敌人，或已明置时发动。
sgs.ai_skill_invoke.juewang = function(self, data)
	if self.player:hasShownSkill("juewang") then return true end
	for _, p in ipairs(self.enemies) do if p:getHp() < self.player:getHp() then return true end end
	return false
end

sgs.ai_skill_invoke.bingdu = function(self, data)
	local dead = data:toPlayer()
	return dead ~= nil and (self:isFriend(dead) or #self.enemies > 0)
end
sgs.ai_skill_choice.bingdu = function(self, choices, data)
	local dead = data:toPlayer()
	if dead and self:isFriend(dead) and fx_has_choice(choices, "bingdu_revive") then return "bingdu_revive" end
	if fx_has_choice(choices, "bingdu_use") then return "bingdu_use" end
	return fx_choices(choices)[1]
end

-- 逆神：只邀请友方或尚未形成敌对关系者；社团成员死亡后按实际状态选回复/摸牌。
sgs.ai_skill_invoke.nishen = function(self, data)
	local dying = data:toPlayer()
	if not dying then return true end -- Death 分支：社团奖惩替换必有非负收益
	return not self:isEnemy(dying)
end
sgs.ai_skill_choice.nishen = function(self, choices, data)
	if fx_has_choice(choices, "nishen_accept") then
		local yuri = self.room:findPlayerBySkillName("nishen")
		if yuri and self.player:getRole() ~= "careerist" and not self:isEnemy(yuri) then return "nishen_accept" end
		return fx_has_choice(choices, "cancel") and "cancel" or fx_choices(choices)[1]
	end
	if self.player:isWounded() and fx_has_choice(choices, "nishen_recover") then return "nishen_recover" end
	if fx_has_choice(choices, "nishen_draw") then return "nishen_draw" end
	return fx_choices(choices)[1]
end

sgs.ai_skill_invoke.zuozhan = function(self, data)
	local target = data:toPlayer()
	if not target then return false end
	if self:isFriend(target) then return true end
	return target:hasShownOneGeneral() and self:isEnemy(target)
end

-- 星爆：重铸最低保留价值的同色牌，避免无条件丢桃、闪或无懈。
sgs.ai_skill_invoke.xingbao = function(self, data)
	local damage = data:toDamage()
	if not damage or not damage.card then return false end
	local cards = fx_low_value_cards(self, "he")
	for _, c in ipairs(cards) do
		if c:isRed() == damage.card:isRed() and (self.player:getHandcardNum() > self.player:getHp() or self:getKeepValue(c) < 5) then
			return true
		end
	end
	return false
end
sgs.ai_skill_use["@@xingbao"] = function(self, prompt)
	local cards = fx_low_value_cards(self, "he")
	for _, c in ipairs(cards) do
		if (self.player:hasFlag("xingbao_red") and c:isRed())
			or (self.player:hasFlag("xingbao_black") and c:isBlack()) then
			return "@XingbaoCard=" .. c:getEffectiveId() .. "&->"
		end
	end
	return "."
end

-- 心跳：第一次选有【键】的来源，第二次选没有【键】的去处。
sgs.ai_skill_invoke.xintiao = function(self, data) return true end
sgs.ai_skill_playerchosen.xintiao = function(self, targets)
	local has_key = false
	for _, p in sgs.qlist(targets) do
		for _, c in sgs.qlist(p:getJudgingArea()) do if c:isKindOf("Key") then has_key = true break end end
		if has_key then break end
	end
	if has_key then
		for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
	else
		local enemy = fx_best_enemy(self, targets)
		if enemy then return enemy end
	end
	return targets:isEmpty() and nil or targets:first()
end

-- 制空：只为自己或明确友方消耗“铝”，并保证数据为空时不解引用。
sgs.ai_skill_invoke.zhikong = function(self, data)
	local target = data:toPlayer()
	if not target or self.player:getPile("akagi_lv"):isEmpty() or self.player:getHp() <= 1 then return false end
	if target:objectName() == self.player:objectName() then return true end
	return self:isFriend(target) and target:hasShownOneGeneral()
end
sgs.ai_skill_askforag.zhikong = function(self, card_ids)
	local best, value = card_ids[1] or -1, 999
	for _, id in ipairs(card_ids) do
		local v = self:getKeepValue(sgs.Sanguosha:getCard(id))
		if v < value then best, value = id, v end
	end
	return best
end

-- 不渝：只把标记放在计划反复指定的明确敌人身上。
sgs.ai_skill_invoke.buyu = function(self, data)
	for _, p in ipairs(self.enemies) do if p:hasShownOneGeneral() then return true end end
	return false
end
sgs.ai_skill_playerchosen.buyu = function(self, targets)
	return fx_best_enemy(self, targets)
end

-- 破译：X、Y均优先选明确敌人，避免驱使身份未明者盲杀。
sgs.ai_skill_use_func.PoyiCard = function(card, use, self)
	local first, second
	for _, x in ipairs(self.enemies) do
		if x:hasShownOneGeneral() and x:getHp() >= self.player:getHp() then
			for _, y in ipairs(self.enemies) do
				if y ~= x and y:hasShownOneGeneral() and x:inMyAttackRange(y) then first, second = x, y break end
			end
		end
		if first then break end
	end
	if not first or not second then return end
	use.card = card
	if use.to then use.to:append(first) use.to:append(second) end
end

-- 委托：友方伤害来源会给自己展示牌；明确敌方来源会成为流放者；身份未明时不主动定性。
sgs.ai_skill_invoke.weituo = function(self, data)
	local source = data:toPlayer()
	if not source then return false end
	if self:isFriend(source) then return true end
	return source:hasShownOneGeneral() and self:isEnemy(source)
end

-- 五刃附属技能：伤害换血必须保命，弃牌类效果只用于明确敌人。
sgs.ai_skill_invoke.tongziqie = function(self, data)
	local damage = data:toDamage()
	return damage and damage.to and self.player:getHp() > 1 and self:isEnemy(damage.to)
		and (damage.to:getHp() <= damage.damage + 1 or self.player:getHp() > 2)
end
sgs.ai_skill_invoke.paoqie = function(self, data)
	local target = data:toPlayer()
	return target ~= nil and target:hasShownOneGeneral() and self:isEnemy(target) and not target:isNude()
end
sgs.ai_skill_invoke.xiaowuwan = function(self, data)
	local use = data:toCardUse()
	if not use.card or self.player:isNude() then return false end
	for _, p in sgs.qlist(use.to) do
		if p:hasShownOneGeneral() and self:isEnemy(p) then return true end
	end
	return false
end

-- 分解：property 可能为空；仅在以1伤害并取消当前效果更有利时发动。
sgs.ai_skill_invoke.fenjie = function(self, data)
	local target = data:toPlayer()
	if not target or not target:hasShownOneGeneral() or not self:isEnemy(target) or target:getEquips():isEmpty() then return false end
	local card = target:property("fenjie_card"):toCard()
	if not card then return false end
	if card:isKindOf("Peach") or card:isKindOf("ExNihilo") then return true end
	if card:isKindOf("Slash") and self.player:getMark("drank") > 0 then return false end
	return true
end

-- 重组：弃牌堆没有可取牌，或收益不足以覆盖两张成本时不发动。
fx_override_turn_skill("chongzu", function(self)
	if self.player:hasUsed("ChongzuCard") or self.player:getCards("he"):length() < 2 then return nil end
	local best_gain = -999
	for _, id in sgs.qlist(self.room:getDiscardPile()) do
		local c = sgs.Sanguosha:getCard(id)
		if c:isKindOf("BasicCard") or c:isKindOf("EquipCard") then best_gain = math.max(best_gain, self:getUseValue(c)) end
	end
	local cards = fx_low_value_cards(self, "he")
	if #cards < 2 then return nil end
	local cost = self:getKeepValue(cards[1]) + self:getKeepValue(cards[2])
	if best_gain < 5 and cost > 7 then return nil end
	return sgs.Card_Parse("@ChongzuCard=" .. cards[1]:getEffectiveId() .. "+" .. cards[2]:getEffectiveId() .. "&chongzu")
end)

-- 学习的出牌阶段转换：从记录牌名中选收益最高者，并用同类别最低价值实体牌支付。
fx_override_turn_skill("xuexi", function(self)
    if self.player:hasUsed("ViewAsSkill_xuexiCard") then
        return nil
    end

    local patterns =
        self.player:property("xuexi_canusecard"):toStringList()

    if not patterns or #patterns == 0 then
        return nil
    end

    local physical =
        sgs.QList2Table(self.player:getCards("he"))

    self:sortByKeepValue(physical)

    local best, best_value

    for _, pattern in ipairs(patterns) do
        local prototype =
            sgs.Sanguosha:cloneCard(pattern)

        if prototype then
            for _, c in ipairs(physical) do
                if c:getTypeId() == prototype:getTypeId() then
                    local virtual = sgs.Card_Parse(
                        pattern
                        .. ":xuexi["
                        .. c:getSuitString()
                        .. ":"
                        .. c:getNumberString()
                        .. "]="
                        .. c:getEffectiveId()
                        .. "&xuexi"
                    )

                    if virtual
                        and virtual:isAvailable(self.player) then

                        local value =
                            self:getUseValue(virtual)
                            - self:getKeepValue(c) * 0.15

                        if not best_value
                            or value > best_value then
                            best = virtual
                            best_value = value
                        end
                    end
                end
            end
        end
    end

    return best
end)

-- 救助受益者的二选一：濒弱优先回复，否则在缺牌时摸两张。
sgs.ai_skill_choice.jiuzhu = function(self, choices, data)
	if self.player:isWounded() and (self:isWeak(self.player) or self.player:getLostHp() >= 2)
		and fx_has_choice(choices, "jiuzhu_recover") then return "jiuzhu_recover" end
	if fx_has_choice(choices, "jiuzhu_draw") then return "jiuzhu_draw" end
	if fx_has_choice(choices, "jiuzhu_recover") then return "jiuzhu_recover" end
	return fx_choices(choices)[1]
end

-- 邀战失败后的情报选择。
sgs.ai_skill_choice.yaozhan = function(self, choices, data)
	local target = data:toPlayer()
	if target and target:getHandcardNum() >= 3 and fx_has_choice(choices, "handcards") then return "handcards" end
	if fx_has_choice(choices, "hidden_general") then return "hidden_general" end
	if fx_has_choice(choices, "handcards") then return "handcards" end
	return fx_choices(choices)[1]
end

-- 咒力当前源码为伤害干预技。第一层选择暗置人物牌，第二层决定是否防止伤害。
sgs.ai_skill_choice.zhouli = function(self, choices, data)
	local damage = data:toDamage()
	local protect = damage and damage.to and self:isFriend(damage.to)
	if fx_has_choice(choices, "zhouli_prevent") then
		return protect and "zhouli_prevent" or (fx_has_choice(choices, "cancel") and "cancel" or "zhouli_prevent")
	end
	if protect then
		if fx_has_choice(choices, "zhouli_deputy") then return "zhouli_deputy" end
		if fx_has_choice(choices, "zhouli_head") then return "zhouli_head" end
	end
	return fx_has_choice(choices, "cancel") and "cancel" or fx_choices(choices)[1]
end

-- 真言当前源码只执行“摸一、交一”，故交出最低保留价值牌。
sgs.ai_skill_cardchosen.zhenyan = function(self, who, flags)
	local cards = fx_low_value_cards(self, flags or "he")
	return cards[1] and cards[1]:getEffectiveId() or -1
end

-- 因果：死亡后优先让所选友方变更副将；没有对应选项时返回取消。
sgs.ai_skill_choice.yinguo = function(self, choices, data)
	if fx_has_choice(choices, "yinguo1_transform") then return "yinguo1_transform" end
	if fx_has_choice(choices, "yinguo2_transform") then return "yinguo2_transform" end
	return fx_has_choice(choices, "cancel") and "cancel" or fx_choices(choices)[1]
end

-- 导刻：受赠者弃牌决定展示数量，友方赠牌时尽量弃置低价值高点数牌。
sgs.ai_skill_cardask["@daoke"] = function(self, data)
	local giver = data:toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return "." end
	local best, score
	for _, c in ipairs(cards) do
		local s = -self:getKeepValue(c)
		if giver and self:isFriend(giver) then s = s + c:getNumber() * 0.45 else s = s - c:getNumber() * 0.2 end
		if not score or s > score then best, score = c, s end
	end
	return best and "$" .. best:getEffectiveId() or "."
end
sgs.ai_skill_choice.daoke = function(self, choices, data)
	if fx_has_choice(choices, "daoke_drawpile") then return "daoke_drawpile" end
	return fx_choices(choices)[1]
end
sgs.ai_skill_askforag.daoke = function(self, card_ids)
	local best, best_value = card_ids[1] or -1, -999
	for _, id in ipairs(card_ids) do
		local value = self:getUseValue(sgs.Sanguosha:getCard(id))
		if value > best_value then best, best_value = id, value end
	end
	return best
end

-- 刀客赠牌：只给明确友方刀客，选择最低保留价值牌。
fx_override_turn_skill("daokegive", function(self)
	if self.player:hasUsed("DaokegiveCard") or self.player:isNude() then return nil end
	for _, p in ipairs(self.friends_noself) do
		if p:hasShownSkill("daoke") then return sgs.Card_Parse("@DaokegiveCard=.&daokegive") end
	end
end)
sgs.ai_skill_use_func.DaokegiveCard = function(card, use, self)
	local target
	for _, p in ipairs(self.friends_noself) do if p:hasShownSkill("daoke") then target = p break end end
	local cards = fx_low_value_cards(self, "he")
	if not target or not cards[1] then return end
	use.card = sgs.Card_Parse("@DaokegiveCard=" .. cards[1]:getEffectiveId() .. "&daokegive")
	if use.to then use.to:append(target) end
end

-- 通用保守边界：未知阵营不视作敌人；必须显式确认敌对后才执行攻击型选择。
sgs.ai_skill_invoke.shashou = function(self, data)
	local target = data:toPlayer()
	return target ~= nil and target:hasShownOneGeneral() and self:isEnemy(target)
end
sgs.ai_skill_invoke.aisha = function(self, data)
	local target = data:toPlayer()
	return target ~= nil and self:isFriend(target)
end
sgs.ai_skill_invoke.aishadraw = function(self, data) return true end
sgs.ai_skill_invoke.kaihua = function(self, data) return true end

-- 二刀、封弊：根据手中【杀】数量选择次数或额外目标；封弊的额外摸牌恒为正收益。
sgs.ai_skill_invoke.erdao = function(self, data)
	return self:willShowForAttack() or self.player:hasShownSkill("erdao")
end
sgs.ai_skill_choice.erdao = function(self, choices, data)
	local slash_num = self:getCardsNum("Slash")
	if slash_num >= 2 and fx_has_choice(choices, "erdao_extraslash") then return "erdao_extraslash" end
	if fx_has_choice(choices, "erdao_extratarget") then return "erdao_extratarget" end
	return fx_choices(choices)[1]
end
sgs.ai_skill_invoke.fengbi = function(self, data) return true end

-- 破晓：补齐双势力分支的主动 AI。消耗最低价值碎片，按敌方牌型选择限制。
fx_override_turn_skill("poxiao", function(self)
	if self.player:hasUsed("PoxiaoCard") or self.player:getKingdom() ~= "real"
		or self.player:getPile("Fragments"):isEmpty() or #self.enemies == 0 then return nil end
	local id = self.player:getPile("Fragments"):first()
	return sgs.Card_Parse("@PoxiaoCard=" .. id .. "&poxiao")
end)
sgs.ai_skill_use_func.PoxiaoCard = function(card, use, self)
	local enemies = {}
	for _, p in ipairs(self.enemies) do if p:hasShownOneGeneral() then table.insert(enemies, p) end end
	if #enemies == 0 then return end
	self:sort(enemies, "handcard")
	use.card = card
	if use.to then use.to:append(enemies[#enemies]) end
end
sgs.ai_skill_choice.poxiao = function(self, choices, data)
	local target = data:toPlayer()
	if target and target:getHandcardNum() >= 3 and fx_has_choice(choices, "Mipa_Basic") then return "Mipa_Basic" end
	if fx_has_choice(choices, "Mipa_NotBasic") then return "Mipa_NotBasic" end
	return fx_choices(choices)[1]
end
sgs.ai_use_value.PoxiaoCard = 7
sgs.ai_use_priority.PoxiaoCard = 7.5

-- 加积：只把低价值牌置为宝石，保留桃、无懈和关键防御牌。
sgs.ai_skill_invoke.jiaji = function(self, data)
	local cards = fx_low_value_cards(self, "he")
	return cards[1] ~= nil and (self.player:getHandcardNum() > self.player:getHp() or self:getKeepValue(cards[1]) < 4.5)
end
sgs.ai_skill_cardchosen.jiaji = function(self, who, flags)
	local cards = fx_low_value_cards(self, flags or "he")
	return cards[1] and cards[1]:getEffectiveId() or -1
end

-- 无刃：按当前手牌结构选择两项，不使用不存在的 findPlayerByObjectName。
sgs.ai_skill_invoke.wuren = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence() or self.player:hasShownSkill("wuren")
end
sgs.ai_skill_choice.wuren = function(self, choices, data)
	local order = {"leiqie", "huocheqie", "tongziqie", "paoqie", "xiaowuwan"}
	if self.player:getHandcardNum() <= 2 then
		order = {"paoqie", "leiqie", "tongziqie", "huocheqie", "xiaowuwan"}
	elseif self:getCardsNum("Slash") > 0 then
		order = {"tongziqie", "huocheqie", "leiqie", "xiaowuwan", "paoqie"}
	end
	for _, wanted in ipairs(order) do if fx_has_choice(choices, wanted) then return wanted end end
	return fx_choices(choices)[1]
end

-- 盖棺：偶数手牌时按响应类型生成牌；选择摸牌通常优于不稳定的其他分支。
sgs.ai_view_as.gaoling = function(card, player, card_place)
	if player:getHandcardNum() % 2 ~= 0 then return nil end
	if card_place ~= sgs.Player_PlaceEquip and card_place ~= sgs.Player_PlaceHand then return nil end
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	if pattern == "jink" then
		return ("jink:gaoling[%s:%s]=%d&gaoling"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
	end
	if pattern and pattern:find("nullification") then
		return ("nullification:gaoling[%s:%s]=%d&gaoling"):format(card:getSuitString(), card:getNumberString(), card:getEffectiveId())
	end
end
sgs.ai_skill_choice.gaoling = function(self, choices, data)
	if fx_has_choice(choices, "draw1card") then return "draw1card" end
	return fx_choices(choices)[1]
end

--[[
    规则文本复核层（以本包 C++ 的实际触发、参数和结算为准）
    翻译用于确认设计意图；翻译与当前源码不一致时，AI必须服从源码实际行为。
]]--

-- 侍奉：可以选择“一名受伤角色”或“任意名攻击范围内角色”，二者不可混选。
sgs.ai_skill_use["@@shifeng"] = function(self, prompt)
	local in_range = {}
	for _, p in ipairs(self.friends_noself) do
		if p:isAlive() and self.player:inMyAttackRange(p) then table.insert(in_range, p) end
	end
	if #in_range > 0 then
		self:sort(in_range, "handcard")
		local names = {}
		for _, p in ipairs(in_range) do table.insert(names, p:objectName()) end
		return "@ShifengCard=.->" .. table.concat(names, "+")
	end
	local wounded = {}
	for _, p in ipairs(self.friends_noself) do if p:isWounded() then table.insert(wounded, p) end end
	if #wounded == 0 and self.player:isWounded() then table.insert(wounded, self.player) end
	if #wounded == 0 then return "." end
	self:sort(wounded, "hp")
	return "@ShifengCard=.->" .. wounded[1]:objectName()
end

sgs.ai_skill_choice.shifeng = function(self, choices, data)
	if fx_has_choice(choices, "shifeng_selfdraw") then
		if self.player:getHandcardNum() <= self.player:getHp() then return "shifeng_selfdraw" end
		return fx_has_choice(choices, "shifeng_otherdraw") and "shifeng_otherdraw" or "shifeng_selfdraw"
	end
	return fx_choices(choices)[1]
end

-- 忍耐：三次 askForChoice 分别回答“维度—数值—增减冻结”。
local function fx_freeze_plan(self)
	local best = {dimension = "rennai_hp", value = self.player:getHp(), action = "rennai_gain", score = -999}
	for _, dimension in ipairs({"rennai_hp", "rennai_handcardnum"}) do
		local values = {}
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			local value = dimension == "rennai_hp" and p:getHp() or p:getHandcardNum()
			values[value] = true
		end
		for value, _ in pairs(values) do
			for _, action in ipairs({"rennai_gain", "rennai_lose"}) do
				local score = 0
				for _, p in sgs.qlist(self.room:getAlivePlayers()) do
					local pv = dimension == "rennai_hp" and p:getHp() or p:getHandcardNum()
					if pv == value then
						local frozen = p:getMark("@Frozen_Eu") > 0
						if action == "rennai_gain" and not frozen then
							if self:isEnemy(p) and p:hasShownOneGeneral() then score = score + 4
							elseif self:isFriend(p) then score = score - 4 else score = score - 1 end
						elseif action == "rennai_lose" and frozen then
							if self:isFriend(p) then score = score + 3
							elseif self:isEnemy(p) and p:hasShownOneGeneral() then score = score - 3 end
						end
					end
				end
				if score > best.score then
					best = {dimension = dimension, value = value, action = action, score = score}
				end
			end
		end
	end
	return best
end

sgs.ai_skill_invoke.rennai = function(self, data) return true end
sgs.ai_skill_choice.rennai = function(self, choices, data)
	local plan = fx_freeze_plan(self)
	if fx_has_choice(choices, "rennai_hp") or fx_has_choice(choices, "rennai_handcardnum") then
		self.rennai_plan = plan
		return fx_has_choice(choices, plan.dimension) and plan.dimension or fx_choices(choices)[1]
	end
	plan = self.rennai_plan or plan
	if fx_has_choice(choices, "rennai_gain") or fx_has_choice(choices, "rennai_lose") then
		local result = fx_has_choice(choices, plan.action) and plan.action or fx_choices(choices)[1]
		self.rennai_plan = nil
		return result
	end
	local wanted = tostring(plan.value)
	if fx_has_choice(choices, wanted) then return wanted end
	return fx_choices(choices)[1]
end

-- 绽放：评估所有冻结角色，而不是只检查原唯一目标。
sgs.ai_skill_invoke.zhanfang = function(self, data)
	local score = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("@Frozen_Eu") > 0 then
			if self:isEnemy(p) and p:hasShownOneGeneral() then score = score + 3
			elseif self:isFriend(p) then score = score - 4 else score = score - 1 end
		end
	end
	return score > 0
end

sgs.ai_skill_choice.zhanfang = function(self, choices, data)
	if not fx_has_choice(choices, "zhanfang_discard") then return fx_choices(choices)[1] end
	local equips = sgs.QList2Table(self.player:getEquips())
	self:sortByKeepValue(equips)
	if equips[1] and (self.player:getMark("@Frozen_Eu") > 1 or self:getKeepValue(equips[1]) < 4.5) then
		return "zhanfang_discard"
	end
	return fx_has_choice(choices, "cancel") and "cancel" or "zhanfang_discard"
end

-- 杀手的主动部分：源码当前实际只会暗置副将，因此只选择已明置副将的明确敌人。
fx_override_turn_skill("shashou", function(self)
	if self.player:hasUsed("ShashouCard") or self.player:isKongcheng() then return nil end
	for _, p in ipairs(self.enemies) do
		if p:hasShownGeneral2() then return sgs.Card_Parse("@ShashouCard=.&shashou") end
	end
end)

sgs.ai_skill_use_func.ShashouCard = function(card, use, self)
	local target
	for _, p in ipairs(self.enemies) do if p:hasShownGeneral2() then target = p break end end
	local cards = fx_low_value_cards(self, "h")
	if not target or not cards[1] then return end
	use.card = sgs.Card_Parse("@ShashouCard=" .. cards[1]:getEffectiveId() .. "&shashou")
	if use.to then use.to:append(target) end
end
sgs.ai_use_value.ShashouCard = 5.5
sgs.ai_use_priority.ShashouCard = 6

-- 魔弹：实体牌决定阵营方向，并尽量利用其“任意名目标”能力。
sgs.ai_skill_use_func.ModanCard = function(card, use, self)
	if card:getSubcards():isEmpty() then return end
	local sub = sgs.Sanguosha:getCard(card:getSubcards():first())
	if not sub then return end
	local beneficial = sub:isKindOf("Jink") or sub:isKindOf("Nullification")
		or sub:isKindOf("HegNullification") or sub:isKindOf("Peach")
		or sub:isKindOf("ExNihilo") or sub:isKindOf("AmazingGrace")
	local targets = {}
	local source = beneficial and self.friends or self.enemies
	for _, p in ipairs(source) do
		if self.player:inMyAttackRange(p) and (not beneficial or not sub:isKindOf("Peach") or p:isWounded()) then
			table.insert(targets, p)
		end
	end
	if #targets == 0 then return end
	use.card = card
	if use.to then for _, p in ipairs(targets) do use.to:append(p) end end
end

-- 无视：所选角色会先失去体力再被取消目标，只对明确敌人使用。
sgs.ai_skill_invoke.wushi = function(self, data)
	local use = data:toCardUse()
	if not use.card then return false end
	self.wushi_targets = {}
	for _, p in sgs.qlist(use.to) do
		if self:isEnemy(p) and p:hasShownOneGeneral() then table.insert(self.wushi_targets, p) end
	end
	return #self.wushi_targets > 0
end
sgs.ai_skill_playerchosen.wushi = function(self, targets, max_num, min_num)
	local result = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) and p:hasShownOneGeneral() then table.insert(result, p) end
	end
	self.wushi_targets = nil
	return result
end

-- 破晓的 choice 没有携带目标 data，目标必须在使用技能牌时缓存。
sgs.ai_skill_use_func.PoxiaoCard = function(card, use, self)
	local enemies = {}
	for _, p in ipairs(self.enemies) do if p:hasShownOneGeneral() then table.insert(enemies, p) end end
	if #enemies == 0 then return end
	self:sort(enemies, "handcard")
	local target = enemies[#enemies]
	self.poxiao_target = target
	use.card = card
	if use.to then use.to:append(target) end
end
sgs.ai_skill_choice.poxiao = function(self, choices, data)
	local target = self.poxiao_target
	self.poxiao_target = nil
	if target and (target:isWounded() or target:getHp() <= 2) and fx_has_choice(choices, "Mipa_Basic") then
		return "Mipa_Basic"
	end
	if fx_has_choice(choices, "Mipa_NotBasic") then return "Mipa_NotBasic" end
	return fx_choices(choices)[1]
end

-- 碎片、言弹、论破的 AG 均以 int id 返回，避免返回 Card 或 QList。
sgs.ai_skill_askforag.suipian = function(self, card_ids)
	local best, best_value = card_ids[1] or -1, -999
	for _, id in ipairs(card_ids) do
		local value = self:getUseValue(sgs.Sanguosha:getCard(id))
		if value > best_value then best, best_value = id, value end
	end
	return best
end

sgs.ai_skill_askforag.yandan = function(self, card_ids)
	local owned_suits = {}
	for _, id in sgs.qlist(self.player:getPile("yandan")) do
		owned_suits[sgs.Sanguosha:getCard(id):getSuit()] = true
	end
	for _, id in ipairs(card_ids) do
		if not owned_suits[sgs.Sanguosha:getCard(id):getSuit()] then return id end
	end
	return card_ids[1] or -1
end

sgs.ai_skill_askforag.lunpo = function(self, card_ids)
	local best, best_value = card_ids[1] or -1, 999
	for _, id in ipairs(card_ids) do
		local value = self:getUseValue(sgs.Sanguosha:getCard(id))
		if value < best_value then best, best_value = id, value end
	end
	return best
end

sgs.ai_skill_askforag.shouji = function(self, card_ids)
	local best, best_value = card_ids[1] or -1, -999
	for _, id in ipairs(card_ids) do
		local value = self:getUseValue(sgs.Sanguosha:getCard(id))
		if value > best_value then best, best_value = id, value end
	end
	return best
end

-- 陷害：记录濒死者。敌人将死时把击杀归于自己；友方将死时优先嫁祸敌人。
sgs.ai_skill_invoke.xianhai = function(self, data)
	local victim = data:toPlayer()
	if not victim then return false end
	self.xianhai_victim = victim
	if self:isEnemy(victim) then return true end
	return self:isFriend(victim) and #self.enemies > 0
end
sgs.ai_skill_playerchosen.xianhai = function(self, targets)
	local victim = self.xianhai_victim
	self.xianhai_victim = nil
	if victim and self:isEnemy(victim) then return self.player end
	return fx_best_enemy(self, targets) or self.player
end

-- 病毒：choice 同样不带死亡角色 data，必须在 invoke 时缓存。
sgs.ai_skill_invoke.bingdu = function(self, data)
	local dead = data:toPlayer()
	if not dead then return false end
	self.bingdu_dead = dead
	return self:isFriend(dead) or #self.enemies > 0
end
sgs.ai_skill_choice.bingdu = function(self, choices, data)
	local dead = self.bingdu_dead
	self.bingdu_dead = nil
	if dead and self:isFriend(dead) and fx_has_choice(choices, "bingdu_revive") then return "bingdu_revive" end
	if fx_has_choice(choices, "bingdu_use") then return "bingdu_use" end
	return fx_choices(choices)[1]
end
