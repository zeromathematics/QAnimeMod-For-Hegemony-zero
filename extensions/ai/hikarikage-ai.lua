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