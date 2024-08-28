--Ruri
sgs.ai_skill_invoke.shengli = function(self, data)
    if not self:willShowForAttack() and not self:willShowForDefence() then return end
	local use = data:toCardUse()
	if self:isFriend(use.from) and not use.card:isBlack() then
		return true
	end
	if self:isEnemy(use.from) and use.card:isBlack() then
		if self.player:getHandcardNum() >= use.from:getHandcardNum() then
			return true
		end
		local max_card = self:getMaxCard()
	    local max_point = max_card:getNumber()
	    if max_point - 10 >= self.player:getHandcardNum() - use.from:getHandcardNum() then
		    return true
		end
		if max_point - 7 >= self.player:getHandcardNum() - use.from:getHandcardNum() and self:isWeak(use.from) then
		    return true
		end
	end
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
		if friend:hasShownSkill("lvji") then
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