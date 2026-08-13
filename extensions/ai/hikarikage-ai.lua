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

--闪光

local function shanguangCanShow(self)
    return self:willShowForAttack()
        or self:willShowForDefence()
end

local function getShanguangPattern(self)
    local name =
        self.player:property(
            "ShanguangName"
        ):toString()

    local suit =
        self.player:property(
            "ShanguangSuit"
        ):toString()

    return name, suit
end

local function isShanguangCandidate(
    self, card, base_name, base_suit
)
    if not card then
        return false
    end

    if card:isKindOf("EquipCard") then
        return false
    end

    --无懈类牌不能在出牌流程中主动使用
    if card:isKindOf("Nullification") then
        return false
    end

    if card:objectName() ~= base_name
        and card:getSuitString()
            ~= base_suit then
        return false
    end

    return card:isAvailable(
        self.player
    )
end

local function simulateShanguangSlash(
    self, card
)
    local dummy_use = {
        isDummy = true,
        to = sgs.SPlayerList(),
    }

    --参考jilan，无视【杀】的距离限制
    self.player:setFlags(
        "slashNoDistanceLimit"
    )

    self:useBasicCard(
        card,
        dummy_use
    )

    self.player:setFlags(
        "-slashNoDistanceLimit"
    )

    if dummy_use.card
        and dummy_use.to
        and not dummy_use.to:isEmpty() then
        return dummy_use
    end

    --若普通模拟受到使用次数等因素影响，
    --手动寻找一名无距离限制下可以攻击的敌人
    local enemies = {}

    for _, enemy in ipairs(
        self.enemies
    ) do
        if enemy:isAlive()
            and self.player:canSlash(
                enemy,
                card,
                false
            )
            and self:slashIsEffective(
                card,
                enemy,
                self.player
            ) then

            table.insert(
                enemies,
                enemy
            )
        end
    end

    if #enemies == 0 then
        return nil
    end

    self:sort(
        enemies,
        "defense"
    )

    dummy_use.card = card
    dummy_use.to:append(
        enemies[1]
    )

    return dummy_use
end

local function simulateShanguangCard(
    self, card
)
    if card:isKindOf("Slash") then
        return simulateShanguangSlash(
            self,
            card
        )
    end

    local dummy_use = {
        isDummy = true,
        to = sgs.SPlayerList(),
    }

    if card:isKindOf("BasicCard") then
        self:useBasicCard(
            card,
            dummy_use
        )

    elseif card:isKindOf("TrickCard") then
        self:useTrickCard(
            card,
            dummy_use
        )

    else
        return nil
    end

    if not dummy_use.card then
        return nil
    end

    if not card:targetFixed()
        and (
            not dummy_use.to
            or dummy_use.to:isEmpty()
        ) then
        return nil
    end

    return dummy_use
end

local function getShanguangScore(
    self, card, dummy_use
)
    local score =
        self:getUseValue(card)

    score =
        score
        - self:getKeepValue(card)
            * 0.15

    if card:isKindOf("Peach") then
        if self.player:isWounded() then
            score = score + 6
        else
            return -1000
        end
    end

    if card:isKindOf("Analeptic") then
        if self.player:isWounded() then
            score = score + 2
        end
    end

    if card:isKindOf("Slash") then
        score = score + 2
    end

    if dummy_use.to then
        for _, target in sgs.qlist(
            dummy_use.to
        ) do
            if self:isEnemy(target) then
                score = score + 3

                if target:getHp() <= 1 then
                    score = score + 4
                elseif self:isWeak(target) then
                    score = score + 2
                end

            elseif self:isFriend(target) then
                --通常的用牌函数不会主动伤害友方，
                --这里仍作额外保护
                if card:isKindOf("Peach") then
                    score = score + 4
                else
                    score = score - 5
                end
            end
        end
    end

    --连锁阶段适当提高低保留价值牌的收益
    if self:getKeepValue(card) <= 3 then
        score = score + 1
    end

    return score
end

local function findBestShanguangCard(
    self, base_name, base_suit
)
    if base_name == ""
        and base_suit == "" then
        return nil, nil, -1000
    end

    local cards =
        sgs.QList2Table(
            self.player:getHandcards()
        )

    local best_card = nil
    local best_use = nil
    local best_score = -1000

    for _, card in ipairs(cards) do
        if isShanguangCandidate(
                self,
                card,
                base_name,
                base_suit
            ) then

            local dummy_use =
                simulateShanguangCard(
                    self,
                    card
                )

            if dummy_use then
                local score =
                    getShanguangScore(
                        self,
                        card,
                        dummy_use
                    )

                if score > best_score then
                    best_card = card
                    best_use = dummy_use
                    best_score = score
                end
            end
        end
    end

    return best_card,
        best_use,
        best_score
end

--首次是否发动闪光
sgs.ai_skill_invoke.shanguang =
function(self, data)
    if not shanguangCanShow(self) then
        return false
    end

    local use = data:toCardUse()

    if not use.card then
        return false
    end

    local card, dummy_use, score =
        findBestShanguangCard(
            self,
            use.card:objectName(),
            use.card:getSuitString()
        )

    if not card
        or not dummy_use then
        return false
    end

    return score > 0
end

--实际响应闪光
sgs.ai_skill_use["@@shanguang"] =
function(self, prompt)
    if self.player:isRemoved() then
        return "."
    end

    local base_name, base_suit =
        getShanguangPattern(self)

    local card, dummy_use, score =
        findBestShanguangCard(
            self,
            base_name,
            base_suit
        )

    --没有足够收益时允许停止连续流程
    if not card
        or not dummy_use
        or score <= 0 then
        return "."
    end

    --只在最终确定使用后复制一次
    local shanguang_card =
        sgs.Sanguosha:cloneCard(
            card:objectName(),
            card:getSuit(),
            card:getNumber()
        )

    if not shanguang_card then
        return "."
    end

    shanguang_card:addSubcard(
        card:getEffectiveId()
    )

    shanguang_card:setSkillName(
        "shanguang"
    )

    shanguang_card:setShowSkill(
        "shanguang"
    )

    local card_string =
        shanguang_card:toString()

    if shanguang_card:targetFixed() then
        return card_string
    end

    local targets = {}

    if dummy_use.to then
        for _, target in sgs.qlist(
            dummy_use.to
        ) do
            table.insert(
                targets,
                target:objectName()
            )
        end
    end

    if #targets == 0 then
        return "."
    end

    return card_string
        .. "->"
        .. table.concat(
            targets,
            "+"
        )
end

--水妖

local shuiyao_skill = {}
shuiyao_skill.name = "shuiyao"
table.insert(sgs.ai_skills, shuiyao_skill)

local function getShuiyaoChoice(self)
    local suit_cards = {
        spade = {},
        club = {},
        heart = {},
        diamond = {},
    }

    --只从手牌中选择，暂时不处理装备区
    local cards =
        sgs.QList2Table(
            self.player:getHandcards()
        )

    self:sortByKeepValue(cards)

    for _, card in ipairs(cards) do
        local suit =
            card:getSuitString()

        if suit_cards[suit]
            and not card:isKindOf("Peach") then

            --体力较低时至少保留一张闪
            if not (
                card:isKindOf("Jink")
                and self.player:getHp() <= 2
                and self:getCardsNum("Jink") <= 1
            ) then
                table.insert(
                    suit_cards[suit],
                    card
                )
            end
        end
    end

    local wounded = false

    for _, friend in ipairs(self.friends) do
        if friend:isWounded() then
            wounded = true
            break
        end
    end

    local best_cards = {}
    local best_count = 0
    local best_value = 1000

    for _, same_suit in pairs(
        suit_cards
    ) do
        if #same_suit > 0 then
            local chosen = {}
            local total_value = 0

            for _, card in ipairs(
                same_suit
            ) do
                local value =
                    self:getKeepValue(card)

                --有人受伤时可投入保留价值稍高的牌
                local limit =
                    wounded and 5 or 3

                if value <= limit
                    and #chosen < 3 then

                    table.insert(
                        chosen,
                        card
                    )

                    total_value =
                        total_value + value
                end
            end

            if #chosen > 0 then
                if #chosen > best_count
                    or (
                        #chosen == best_count
                        and total_value
                            < best_value
                    ) then

                    best_cards = chosen
                    best_count = #chosen
                    best_value = total_value
                end
            end
        end
    end

    return best_cards
end

shuiyao_skill.getTurnUseCard =
function(self, inclusive)
    if not self:willShowForAttack()
        and not self:willShowForDefence() then
        return
    end

    if self.player:hasUsed(
        "ViewAsSkill_shuiyaoCard"
    ) then
        return
    end

    if self.player:isKongcheng() then
        return
    end

    local cards =
        getShuiyaoChoice(self)

    if #cards == 0 then
        return
    end

    local ids = {}

    for _, card in ipairs(cards) do
        table.insert(
            ids,
            card:getEffectiveId()
        )
    end

    --直接返回带有子牌的技能牌
    --不再先生成空技能牌后重新构造
    return sgs.Card_Parse(
        "#ShuiyaoCard:"
        .. table.concat(ids, "+")
        .. ":&shuiyao"
    )
end

sgs.ai_skill_use_func["#ShuiyaoCard"] =
function(card, use, self)
    --getTurnUseCard返回的card已经包含子牌
    if not card then
        return
    end

    if card:subcardsLength() <= 0 then
        return
    end

    use.card = card
end

sgs.ai_skill_playerchosen.shuiyao =
function(self, targets)
    local friends = {}

    for _, target in sgs.qlist(
        targets
    ) do
        if self:isFriend(target)
            and target:isWounded() then

            table.insert(
                friends,
                target
            )
        end
    end

    if #friends == 0 then
        return nil
    end

    self:sort(friends, "hp")

    return friends[1]
end

sgs.ai_use_priority.ShuiyaoCard = 6
sgs.ai_use_value.ShuiyaoCard = 6
