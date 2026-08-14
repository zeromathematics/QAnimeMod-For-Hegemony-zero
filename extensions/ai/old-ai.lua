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

sgs.ai_skill_playerchosen.suodi = function(self, targets)
    local target_list = sgs.QList2Table(targets)
    local friends = {}

    for _, player in ipairs(target_list) do
        if self:isFriend(player)
            and player:isAlive()
            and (
                (
                    player:getJudgingArea():length() > 0
                    and not noNeedToRemoveJudgeArea(player)
                )
                or not player:isNude()
            ) then

            table.insert(friends, player)
        end
    end

    if #friends == 0 then
        return nil
    end

    -- 优先处理有不利判定牌的友方。
    for _, friend in ipairs(friends) do
        if friend:getJudgingArea():length() > 0
            and not noNeedToRemoveJudgeArea(friend) then
            return friend
        end
    end

    self:sort(friends, "defense")
    return friends[1]
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
	    if self.player:inMyAttackRange(p) and targets:contains(p) then
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


local function frierenWillShow(self)
    return self:willShowForAttack()
        or self:willShowForDefence()
end

-- 芙莉莲【牵绊】
sgs.ai_skill_invoke.qianban = function(self, data)
    if not frierenWillShow(self) then
        return false
    end
    return true
end


-- 选择获得牌的角色。
sgs.ai_skill_playerchosen.qianban = function(self, targets)
    local candidates = sgs.QList2Table(targets)
    local friends = {}

    for _, p in ipairs(candidates) do
        if self:isFriend(p) then
            table.insert(friends, p)
        end
    end

    -- 正常情况下targets包含自己，因此至少有一名友方。
    if #friends == 0 then
        return self.player
    end

    -- 优先援助空城的友方。
    local kongcheng_friends = {}
    for _, p in ipairs(friends) do
        if p:isKongcheng()
            and not p:hasShownSkill("kongcheng") then
            table.insert(kongcheng_friends, p)
        end
    end

    if #kongcheng_friends > 0 then
        self:sort(kongcheng_friends, "defense")
        return kongcheng_friends[1]
    end

    -- 其次援助手牌少且防御较弱的友方。
    table.sort(friends, function(a, b)
        if a:getHandcardNum() ~= b:getHandcardNum() then
            return a:getHandcardNum() < b:getHandcardNum()
        end

        return sgs.getDefense(a) < sgs.getDefense(b)
    end)

    return friends[1]
end


-- 被选择的角色声明一种非黑桃花色。
sgs.ai_skill_choice.qianban = function(self, choices, data)
    local available = choices:split("+")

    local function canChoose(choice)
        return table.contains(available, choice)
    end

    -- 濒危或受伤时优先红桃：
    -- 红桃牌中通常包含【桃】及较多防御、恢复资源。
    if (self.player:getHp() <= 2 or self:isWeak(self.player))
        and canChoose("heart") then
        return "heart"
    end

    -- 缺少【闪】时也优先红桃。
    if self:getCardsNum("Jink") == 0
        and canChoose("heart") then
        return "heart"
    end

    -- 出牌阶段且需要进攻资源时选择方块。
    -- 方块通常具有较多进攻牌和装备牌。
    if self.player:getPhase() == sgs.Player_Play
        and self:getCardsNum("Slash") == 0
        and canChoose("diamond") then
        return "diamond"
    end

    -- 手牌较少时，梅花通常能提供较丰富的功能牌。
    if self.player:getHandcardNum() <= 2
        and canChoose("club") then
        return "club"
    end

    -- 常态优先级：红桃保命，梅花补充功能，方块偏进攻。
    if canChoose("heart") then
        return "heart"
    elseif canChoose("club") then
        return "club"
    elseif canChoose("diamond") then
        return "diamond"
    end

    return available[1]
end

-- 选择友方获得牌属于友善行为。
sgs.ai_playerchosen_intention.qianban = -20

-- 芙莉莲【集魔】

local jimo_skill = {}
jimo_skill.name = "jimo"
table.insert(sgs.ai_skills, jimo_skill)

jimo_skill.getTurnUseCard = function(self, inclusive)
    if not frierenWillShow(self) then
        return
    end

    if self.player:hasUsed("ViewAsSkill_jimoCard") then
        return
    end

    if self.player:isKongcheng() then
        return
    end

    -- 至少需要一张手牌中的普通锦囊牌。
    local has_trick = false

    for _, card in sgs.qlist(self.player:getHandcards()) do
        if card:isNDTrick() then
            has_trick = true
            break
        end
    end

    if not has_trick then
        return
    end

    return sgs.Card_Parse("#jimoCard:.:&jimo")
end


sgs.ai_skill_use_func["#jimoCard"] = function(card, use, self)
    local usable_tricks = {}
    local other_tricks = {}

    for _, c in sgs.qlist(self.player:getHandcards()) do
        if c:isNDTrick() then
            -- 能在当前出牌阶段主动使用的锦囊，才有机会立即触发【魔导】。
            if c:isAvailable(self.player) then
                table.insert(usable_tricks, c)
            else
                table.insert(other_tricks, c)
            end
        end
    end

    local selected

    if #usable_tricks > 0 then
        -- 比较所有能够使用的普通锦囊，选择使用价值最高者，
        -- 使【魔导】强化落在本回合最值得使用的锦囊上。
        table.sort(usable_tricks, function(a, b)
            local value_a = self:getUseValue(a)
            local value_b = self:getUseValue(b)

            if value_a ~= value_b then
                return value_a > value_b
            end

            -- 使用价值相同时，优先选择保留价值较低者。
            return self:getKeepValue(a) < self:getKeepValue(b)
        end)

        selected = usable_tricks[1]
    elseif #other_tricks > 0 then
        -- 没有能立即使用的锦囊时，【集魔】本身仍能获得一张杀
        -- 并增加出杀次数，因此选择保留价值最低的普通锦囊展示。
        table.sort(other_tricks, function(a, b)
            local keep_a = self:getKeepValue(a)
            local keep_b = self:getKeepValue(b)

            if keep_a ~= keep_b then
                return keep_a < keep_b
            end

            return self:getUseValue(a) < self:getUseValue(b)
        end)

        selected = other_tricks[1]
    end

    if not selected then
        return
    end

    use.card = sgs.Card_Parse(
        "#jimoCard:" ..
        selected:getEffectiveId() ..
        ":&jimo"
    )
end

-- 应在使用普通锦囊和普通【杀】之前发动。
sgs.ai_use_priority.jimoCard = 9.8
sgs.ai_use_value.jimoCard = 8

-- 芙莉莲【魔导】

-- 计算某张锦囊对目标的收益。
-- 正数：希望该目标受到此牌影响；
-- 负数：希望取消该目标；
-- 0：暂时无法准确判断。
local function modaoTargetValue(self, card, target)
    if not card or not target then
        return 0
    end

    local intention = getTrickIntention(
        card:getClassName(),
        target
    )

    if intention > 0 then
        -- 伤害、控制、拆牌类锦囊
        if self:isEnemy(target) then
            return 10
        elseif self:isFriend(target) then
            return -10
        end
    elseif intention < 0 then
        -- 摸牌、恢复、辅助类锦囊
        if self:isFriend(target) then
            return 10
        elseif self:isEnemy(target) then
            return -10
        end
    end

    -- 对部分常见牌进行补充判断。
    if card:isKindOf("Duel")
        or card:isKindOf("FireAttack")
        or card:isKindOf("Drowning")
        or card:isKindOf("Snatch")
        or card:isKindOf("Dismantlement") then

        if self:isEnemy(target) then
            return 8
        elseif self:isFriend(target) then
            return -8
        end
    end

    if card:isKindOf("ExNihilo") then
        if self:isFriend(target) then
            return 10
        elseif self:isEnemy(target) then
            return -10
        end
    end

    return 0
end


local function modaoContainsChoice(choices, choice)
    return table.contains(choices:split("+"), choice)
end


local function modaoPlayerInUse(use, player, state)
    if not use or not player then
        return false
    end

    local name = player:objectName()

    -- 已经被守式取消的原目标不再视为当前目标。
    if state
        and state.removed
        and state.removed[name] then
        return false
    end

    if use.to and use.to:contains(player) then
        return true
    end

    -- 记录扩术后来增加的目标。
    if state
        and state.added
        and state.added[name] then
        return true
    end

    return false
end


local function modaoInitState(self, use)
    if not use or not use.card then
        return nil
    end

    local key = use.card:toString()

    if not self.modao_state
        or self.modao_state.key ~= key then

        self.modao_state = {
            key = key,
            choice = nil,
            added = {},
            removed = {}
        }
    end

    return self.modao_state
end


-- 寻找最值得扩术增加的合法目标。
local function modaoBestExtraTarget(self, use, state)
    if not use or not use.card then
        return nil, 0
    end

    local best_target
    local best_value = 0
    local empty_targets = sgs.PlayerList()

    for _, p in sgs.qlist(self.room:getAlivePlayers()) do
        if not modaoPlayerInUse(use, p, state)
            and use.card:targetFilter(
                empty_targets,
                p,
                self.player
            )
            and not self.player:isProhibited(p, use.card) then

            local value = modaoTargetValue(
                self,
                use.card,
                p
            )

            if value > best_value then
                best_value = value
                best_target = p
            end
        end
    end

    return best_target, best_value
end


-- 寻找最应该由守式取消的原目标。
local function modaoWorstOriginalTarget(self, use, state)
    if not use or not use.card or not use.to then
        return nil, 0
    end

    local worst_target
    local worst_value = 0

    for _, p in sgs.qlist(use.to) do
        local name = p:objectName()

        -- 扩术目标不能成为守式目标；
        -- 已经被取消的目标也不再计算。
        if not state.added[name]
            and not state.removed[name] then

            local value = modaoTargetValue(
                self,
                use.card,
                p
            )

            if value < worst_value then
                worst_value = value
                worst_target = p
            end
        end
    end

    return worst_target, worst_value
end


-- 判断破法是否有正收益。
local function modaoShouldPofa(self, use, state)
    if not use or not use.card or not use.to then
        return false
    end

    local total_value = 0
    local effective_targets = 0

    for _, p in sgs.qlist(use.to) do
        local name = p:objectName()

        if not state.removed[name] then
            total_value = total_value
                + modaoTargetValue(self, use.card, p)

            effective_targets = effective_targets + 1
        end
    end

    for name, added in pairs(state.added) do
        if added and not state.removed[name] then
            local p = findPlayerByObjectName(name)

            if p and p:isAlive()
                and not use.to:contains(p) then
                total_value = total_value
                    + modaoTargetValue(self, use.card, p)

                effective_targets = effective_targets + 1
            end
        end
    end

    -- 牌对我方整体有利时，才值得防止金色宣言响应。
    return effective_targets > 0 and total_value > 0
end


sgs.ai_skill_choice.modao = function(self, choices, data)
    local use = data:toCardUse()

    if not use or not use.card then
        return "cancel"
    end

    local state = modaoInitState(self, use)

    if not state then
        return "cancel"
    end

    state.choice = nil

    -- 第一优先：取消会伤害友方或帮助敌方的原目标。
    if modaoContainsChoice(choices, "modao_shoushi") then
        local target, value =
            modaoWorstOriginalTarget(self, use, state)

        if target and value < 0 then
            state.choice = "modao_shoushi"
            return state.choice
        end
    end

    -- 第二优先：增加一名明确具有正收益的目标。
    if modaoContainsChoice(choices, "modao_kuoshu") then
        local target, value =
            modaoBestExtraTarget(self, use, state)

        if target and value > 0 then
            state.choice = "modao_kuoshu"
            return state.choice
        end
    end

    -- 第三优先：当前牌对己方整体有利时选择破法。
    if modaoContainsChoice(choices, "modao_pofa")
        and modaoShouldPofa(self, use, state) then

        state.choice = "modao_pofa"
        return state.choice
    end

    state.choice = "cancel"
    return "cancel"
end


sgs.ai_skill_playerchosen.modao = function(self, targets)
    local candidates = sgs.QList2Table(targets)

    if #candidates == 0 then
        return nil
    end

    local state = self.modao_state

    if not state then
        return candidates[1]
    end

    if state.choice == "modao_kuoshu" then
        local best_target
        local best_value = -1000

        for _, p in ipairs(candidates) do
            local value = modaoTargetValue(
                self,
                self.player:getRoom():getCurrentCardUseCard(),
                p
            )

            if value > best_value then
                best_value = value
                best_target = p
            end
        end

        -- getCurrentCardUseCard()在部分旧版引擎中可能不存在，
        -- 此时改用choice阶段保存的术式牌。
        if not best_target and state.card then
            for _, p in ipairs(candidates) do
                local value =
                    modaoTargetValue(self, state.card, p)

                if value > best_value then
                    best_value = value
                    best_target = p
                end
            end
        end

        best_target = best_target or candidates[1]

        state.added[best_target:objectName()] = true
        return best_target
    end

    if state.choice == "modao_shoushi" then
        local worst_target
        local worst_value = 1000

        for _, p in ipairs(candidates) do
            local value

            if state.card then
                value = modaoTargetValue(
                    self,
                    state.card,
                    p
                )
            else
                -- 没有取得牌对象时，至少保证优先取消友方。
                value = self:isFriend(p) and -10 or 10
            end

            if value < worst_value then
                worst_value = value
                worst_target = p
            end
        end

        worst_target = worst_target or candidates[1]

        state.removed[worst_target:objectName()] = true
        return worst_target
    end

    return candidates[1]
end