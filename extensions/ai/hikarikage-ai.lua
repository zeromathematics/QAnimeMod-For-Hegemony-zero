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
		if friend:hasShownSkill("lvji") and friend:getPile("jixu_id"):length() <= 5 then
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