sgs.ai_igiari = {}

function SmartAI:useCardMusic(card, use)
    local p
    for _,v in ipairs(self.friends) do
		local has
	    for _,w in ipairs(self.enemies) do
		   if v:inMyAttackRange(w) then
			  has = true
		   end
	    end
		if getCardsNum("Slash", v, self.player) >0 and has then p = v end
	end
    if not p then
        for _,v in ipairs(self.friends) do
            if v:getHandcardNum()> v:getMaxCards() and (v:objectName()~=self.player:objectName() or v:getHandcardNum()> v:getMaxCards()+1 or not self.player:getHandcards():contains(card)) then p = v end
        end
    end
    if p then
        if not card:isAvailable(self.player) then return end
	    if sgs.Sanguosha:isProhibited(self.player, p, card)then return end
        use.card = card
        if use.to then use.to:append(p) end
    end
	return
end
sgs.ai_use_priority.Music = 0
sgs.ai_use_value.Music = 6.5
sgs.ai_keep_value.Music= 2
sgs.ai_card_intention.Music= -60

sgs.ai_skill_choice.music = function(self, choices, data)
	local has
	for _,v in ipairs(self.enemies) do
		if self.player:inMyAttackRange(v) then
			for _,c in sgs.qlist(self.player:getHandcards()) do
               if c:isKindOf("Slash") and self:slashIsEffective(c, v, self.player) then has = true end
			end
		end
	end
	if self:getCardsNum("Slash") > 0 and has then return "music_moreslash" end 
	if self.player:getMaxCards()+1 < self.player:getHandcardNum() then return "music_maxh" end
	local na
	for _,v in ipairs(self.enemies) do
		if not self.player:inMyAttackRange(v) then
			local x = self.player:distanceTo(v) - self.player:getAttackRange()
			for _,c in sgs.qlist(self.player:getHandcards()) do
               if self.room:getCurrent():getMark("music_times")+1 >= x and c:isKindOf("Slash") and self:slashIsEffective(c, v, self.player) and c:isAvailable(self.player) then na = true end
			end
		end
	end
	if na then return "music_range" end
	if self.player:getPhase() == sgs.Player_NotActive then return "music_distance" end
end

local clowcard_skill = {}
clowcard_skill.name = "clowcard"
table.insert(sgs.ai_skills, clowcard_skill)
clowcard_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local Clowcard
	self:sortByUseValue(cards, true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Clowcard") then
			Clowcard = card
			break
		end
	end
	if not Clowcard then return nil end
	local suit = Clowcard:getSuitString()
	local number = Clowcard:getNumberString()
	local card_id = Clowcard:getEffectiveId()
	local card_str = ("slash:clowcard[%s:%s]=%d&"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash

end

sgs.ai_view_as.clowcard = function(card, player, card_place, class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getHandPile():contains(card_id) then
		if card:isKindOf("Clowcard") then
			if class_name == "Slash" then
				return ("slash:clowcard[%s:%s]=%d&"):format(suit, number, card_id)
			elseif class_name == "Jink" then
				return ("jink:clowcard[%s:%s]=%d&"):format(suit, number, card_id)
			end
		end
	end
end

sgs.ai_keep_value.Clowcard = 6

function SmartAI:useCardIdolRoad(card, use)
    if not card:isAvailable(self.player) then return end
	if not self:hasTrickEffective(card, self.player, self.player) then return end
	use.card = card
end
sgs.ai_use_priority.IdolRoad = 3
sgs.ai_use_value.IdolRoad = 6
sgs.ai_keep_value.IdolRoad = 2
sgs.ai_card_intention.IdolRoad= -60

sgs.ai_skill_choice["idol_road"] = function(self, choices, data)
	 local n = self.player:property("ir_times"):toInt()
	 if n <= 1 and table.contains(choices:split("+"), "show_head") then return "show_head" end
	 if n <= 1 and table.contains(choices:split("+"), "show_deputy") then return "show_deputy" end
	return "ir_draw"
end

sgs.ai_nullification.IdolRoad = function(self, card, from, to, positive, keep)
	if positive then
		if self:isEnemy(to) then
			return true, true
		end
	else
		if self:isFriend(to) then return true, true end
	end
	return
end

function SmartAI:useCardMemberRecruitment(card, use)
    if not card:isAvailable(self.player) then return end
	if not self:hasTrickEffective(card, self.player, self.player) then return end
	use.card = card
end
sgs.ai_use_priority.MemberRecruitment = 3
sgs.ai_use_value.MemberRecruitment = 6
sgs.ai_keep_value.MemberRecruitment = 2
sgs.ai_card_intention.MemberRecruitment= -60

sgs.ai_nullification.MemberRecruitment = function(self, card, from, to, positive, keep)
	if positive then
		if self:isEnemy(to) then
			return true, true
		end
	else
		if self:isFriend(to) then return true, true end
	end
	return
end

sgs.ai_skill_use["@@Idolyousei!"] = function(self, prompt, method)
	local card = sgs.cloneCard("music")
	local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
	self:useCardMusic(card, dummyuse)
	local tos = {}
	if dummyuse.card and not dummyuse.to:isEmpty() then
		for _, to in sgs.qlist(dummyuse.to) do
			table.insert(tos, to:objectName())
		end
		return "music:Idolyousei[no_suit:0]=.&->" .. table.concat(tos, "+")
	end
end

sgs.ai_skill_use["@@Negi"] = function(self, prompt, method)
	local card = sgs.cloneCard("music")
	local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
	self:useCardMusic(card, dummyuse)
	local tos = {}
	local c
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _,ac in ipairs(cards) do
	   if self:getUseValue(ac) <= self:getUseValue(card) then
		  c = ac
		  break
	   end
    end
	if c and dummyuse.card and not dummyuse.to:isEmpty() then
		for _, to in sgs.qlist(dummyuse.to) do
			table.insert(tos, to:objectName())
		end
		return ("music:Negi[%s:%s]="):format(c:getSuitString(), c:getNumberString())..c:getEffectiveId().."&->" .. table.concat(tos, "+")
	end
end

sgs.ai_skill_invoke.Idolclothes = function(self, data)
    local use = data:toCardUse()
	local n = getTrickIntention(use.card:getClassName(), self.player)
	local enemies = 0 
	local friends = 0
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) and p:objectName()~=self.player:objectName() then friends = friends+1 end
		if self:isEnemy(p) then enemies= enemies+1 end
	end
	if n > 0 then return true end
	if n < 0 and enemies > friends then return true end
end

sgs.ai_skill_choice["Idolclothes"] = function(self, choices, data)
    local use = data:toCardUse()
	local n = getTrickIntention(use.card:getClassName(), self.player)
	local enemies = 0 
	local friends = 0
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) and p:objectName()~=self.player:objectName() then friends = friends+1 end
		if self:isEnemy(p) then enemies= enemies+1 end
	end
	if n > 0 then
		if enemies > friends or friends == 0 then return "ic_self" end
		return "ic_others"
	end
	if n < 0 and enemies > friends then return "ic_others" end
end

sgs.ai_skill_invoke.Josou = true
sgs.weapon_range.Shinai = 2
sgs.weapon_range.Negi = 2

local Josou_skill = {}
Josou_skill.name = "Josou"
table.insert(sgs.ai_skills, Josou_skill)
Josou_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("ViewAsSkill_JosouCard") or not self.player:getArmor() or self.player:getArmor():objectName() ~= "Josou" then return end
	return sgs.Sanguosha:getCard(self.player:getArmor():getEffectiveId())
end

local Shinai_skill = {}
Shinai_skill.name = "Shinai"
table.insert(sgs.ai_skills, Shinai_skill)
Shinai_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("ViewAsSkill_ShinaiCard") or not self.player:getWeapon() or self.player:getWeapon():objectName() ~= "Shinai" then return end
	return sgs.Sanguosha:getCard(self.player:getWeapon():getEffectiveId())
end

sgs.ai_skill_choice["shining_concert"] = function(self, choices, data)
	local player = data:toPlayer()
	if self:isEnemy(player) then
	    if self.player:isNude() and self.player:isWounded() then return "sc_recover" end
		sgs.updateIntention(self.player, player, 50)
		return "cancel"
	end
	if table.contains(choices:split("+"), "sc_drboth") then
		sgs.updateIntention(self.player, player, -5)
		return "sc_drboth" 
	end
	if not self.player:isWounded() then
		sgs.updateIntention(self.player, player, -30) 
		return "sc_draw" 
	end
	if self.player:getHandcardNum() <= self.player:getHp() and math.random(1, 2+self.player:getHp()-self.player:getHandcardNum()) ~= 1  then
		sgs.updateIntention(self.player, player, -30)
		return "sc_draw" 
	end
	sgs.updateIntention(self.player, player, -20)
    return "sc_recover"
end

function SmartAI:useCardShiningConcert(card, use)
	local e = 0
	for _,v in ipairs(self.enemies) do
		if self:isWeak(v) and self:hasTrickEffective(card, self.player, v) then e = e+1 end
	end    
	local f = 0
	for _,v in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(v) or not v:hasShownOneGeneral() and self:hasTrickEffective(card, self.player, v) then f = f+1 end
	end    
    if f < e then return end
    if not card:isAvailable(self.player) then return end
	use.card = card
	return
end

sgs.ai_nullification.ShiningConcert = function(self, card, from, to, positive, keep)
	if positive then
		if self:isEnemy(to) and self:isFriend(from, to) then
			return true, true
		end
	else
		if self:isFriend(to) and self:isFriend(from, to) then return true, true end
	end
	return
end

function SmartAI:askForIgiari(basic, from, to, positive)
	if self.player:isDead() then return nil end
	local igicards = self:getCards("Igiari", "he")
	local igi_num = self:getCardsNum("Igiari")
	local igi_card = self:getCardId("Igiari")
	if igi_num > 1 then
		for _, card in ipairs(igicards) do
			igi_card = card:toString()
			break
		end
	end
	if igi_card then igi_card = sgs.Card_Parse(igi_card) else return nil end
	assert(igi_card)
	if self.player:isLocked(igi_card) then return nil end
	if (to and to:isDead()) then return nil end

    local callback = sgs.ai_igiari[basic:getClassName()]
	if type(callback) == "function" then
		local shouldUse = callback(self, basic, from, to, positive, keep)
		return shouldUse and igi_card
	end

    if positive then
		if basic:isKindOf("Slash") and self:isFriend(to) and self:slashIsEffective(basic, to, from) then return igi_card end
		if basic:isKindOf("Analeptic") and to:hasFlag("Global_Dying") and self:isEnemy(to) then return igi_card end
		if basic:isKindOf("Peach") and to:isWounded() and self:isEnemy(to) then return igi_card end
	else
        if basic:isKindOf("Slash") and self:isEnemy(to) and self:slashIsEffective(basic, to, from) then return igi_card end
		if basic:isKindOf("Analeptic") and to:hasFlag("Global_Dying") and self:isFriend(to) then return igi_card end
		if basic:isKindOf("Peach") and to:isWounded() and self:isFriend(to) then return igi_card end
	end
    
    return
end