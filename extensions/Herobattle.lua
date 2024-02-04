extension = sgs.Package("herobattle", sgs.Package_GeneralPack)

KMegumi = sgs.General(extension , "KMegumi", "real", 3, false)
Sakuta = sgs.General(extension , "Sakuta", "real", 4)
Zero = sgs.General(extension , "Zero", "magic", 3, false)
Chulainn = sgs.General(extension , "Chulainn", "magic", 4)
Hei = sgs.General(extension , "hei", "science", 3)
Shino = sgs.General(extension , "Shino", "science", 3, false)
Kuon = sgs.General(extension , "Kuon", "game", 3, false)
PYuuki = sgs.General(extension , "PYuuki", "game", 4)
KMisuzu = sgs.General(extension , "KMisuzu", "real", 3, false)
Fumika = sgs.General(extension , "Fumika", "magic", 3, false)
Sanya = sgs.General(extension , "Sanya", "science", 3, false)
Estelle = sgs.General(extension , "Estelle", "game", 4, false)
Houtarou = sgs.General(extension , "Houtarou", "real", 3)
Houtarou:addCompanion("Chitanda")
Kuuhaku = sgs.General(extension , "Kuuhaku", "magic", 3)
Kuuhaku:setGender(sgs.General_Sexless)
Tatsumi = sgs.General(extension , "Tatsumi", "science", 4)
Tatsumi:addCompanion("Mine")
Sakuya = sgs.General(extension , "Sakuya", "game", 3, false)
Sakuya:addCompanion("Remilia")
Nagi = sgs.General(extension , "Nagi", "real", 3, false)
TokidoSaya = sgs.General(extension , "TokidoSaya", "real", 4, false)
Kotori = sgs.General(extension , "Kotori", "magic", 3, false)
Emilia = sgs.General(extension , "Emilia", "magic", 3, false)
Kuroko = sgs.General(extension , "Kuroko", "science", 3, false)
Kuroko:addCompanion("Mikoto")
Chiyuri = sgs.General(extension , "Chiyuri", "science", 3, false)
--Kaneki = sgs.General(extension , "Kaneki", "science", 5)
Rean = sgs.General(extension , "Rean", "game")
Zuikaku = sgs.General(extension , "Zuikaku", "game", 4, false)
Natsume_Rin = sgs.General(extension , "Natsume_Rin", "real", 3, false)
Ryuuichi = sgs.General(extension , "Ryuuichi", "real", 4)
Chtholly = sgs.General(extension , "Chtholly", "magic", 4, false)
Yato = sgs.General(extension , "Yato", "magic", 4)
Neko = sgs.General(extension , "Neko", "science", 3, false)
Oumashu = sgs.General(extension , "Oumashu", "science", 4)
Joshua = sgs.General(extension , "Joshua", "game")
Joshua:addCompanion("Estelle")
Fegor = sgs.General(extension,"Fegor","game",4,false)
SKaguya = sgs.General(extension , "SKaguya", "real", 3, false)
Saki = sgs.General(extension , "Saki", "real", 3, false)
Megumin = sgs.General(extension , "Megumin", "magic", 3, false)
Megumin:addCompanion("Kazuma")
Lucy = sgs.General(extension , "Lucy", "magic", 3, false)
ShionNezumi = sgs.General(extension , "ShionNezumi", "science", 4)
ShokuhouMisaki = sgs.General(extension , "ShokuhouMisaki", "science", 3, false)
Renne = sgs.General(extension , "Renne", "game", 3, false)
ShameimaruAya = sgs.General(extension , "ShameimaruAya", "game", 3, false)
Tohka = sgs.General(extension , "Tohka", "magic", 4, false)
Violet = sgs.General(extension , "Violet", "magic", 4, false)
ZeroTwo = sgs.General(extension , "ZeroTwo", "science", 4, false)
Asuka = sgs.General(extension , "Asuka", "science", 3, false)
Sakunahime = sgs.General(extension , "Sakunahime", "game", 3, false)
MiyazonoKaori = sgs.General(extension , "MiyazonoKaori", "real", 3, false)
Nagisa = sgs.General(extension , "Nagisa", "real", 3, false)
Nagisa:addCompanion("Tomoya")
Ushio = sgs.General(extension , "Ushio", "real", 3, false, true)

function addGeneralCardToPile(room, player, general, skill)
	local list = player:getTag(skill.."s"):toList()
	if list:contains(sgs.QVariant(general)) then return end
	list:append(sgs.QVariant(general))
    player:setTag(skill.."s", sgs.QVariant(list))
	room:handleUsedGeneral(general)
	for _,p in sgs.qlist(room:getAllPlayers(true)) do
		local list = sgs.SPlayerList()
		list:append(p)
		room:doAnimate(7, player:objectName()..":"..skill, general, list)
	end	  
end

function removeGeneralCardToPile(room, player, general, skill)
	local list = player:getTag(skill.."s"):toList()
	if not list:contains(sgs.QVariant(general)) then return end
	list:removeOne(sgs.QVariant(general))
    player:setTag(skill.."s", sgs.QVariant(list))
	room:handleUsedGeneral("-"..general)
	for _,p in sgs.qlist(room:getAllPlayers(true)) do
		local list = sgs.SPlayerList()
		list:append(p)
		room:doAnimate(7, player:objectName()..":"..skill, "-"..general, list)
	end	  
end

function getGeneralCardToPile(player, skill)
    return player:getTag(skill.."s"):toStringList()
end

function getSkinId(general_name)
	local n = 0
	for i = 1, 998, 1 do
		if file_exists("hero-skin/"..general_name.."/"..i.."/full.png") then
			n = i
		else
			break
		end
	end
	return math.random(0,n)
end

UseDefaultSkin = sgs.CreateTriggerSkill{
	name = "UseDefaultSkin",
	global = true,
	events = {sgs.EventPhaseStart},
		priority = 0,
	on_record = function(self, event, room, player, data)  
		if player and player:isAlive() and player:getPhase() == sgs.Player_Play and player:getState() == "robot" then
			if player:hasShownGeneral1() and not string.find(player:getActualGeneral1Name(), "sujiang") and math.random(1,5) == 5 then	
			room:setPlayerProperty(player,"head_skin_id", sgs.QVariant(getSkinId(player:getActualGeneral1Name())))
			end
			if player:hasShownGeneral2() and not string.find(player:getActualGeneral2Name(), "sujiang") and math.random(1,5) == 5  then	
				room:setPlayerProperty(player, "deputy_skin_id", sgs.QVariant(getSkinId(player:getActualGeneral2Name())))
			end
		end 
		if player and player:isAlive() and string.find(player:getActualGeneral1Name(), "sujiang") then
			room:setPlayerProperty(player,"head_skin_id", sgs.QVariant(0))
		end
		if player and player:isAlive() and string.find(player:getActualGeneral2Name(), "sujiang") then
			room:setPlayerProperty(player,"deputy_skin_id", sgs.QVariant(0))
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return "" 
	end,
}


function getUsedGeneral(room)
   --[[local used = {}
   for _,p in sgs.qlist(room:getPlayers()) do
      table.insert(used,p:getActualGeneral1Name())
	  table.insert(used,p:getActualGeneral2Name())
   end ]] 
   return room:getUsedGeneral()
end

function getColorString(card)
	if card:isRed() then
		return "red"
    elseif card:isBlack() then
		return "black"
	else
		return "nosuit"
	end
	return ""
end

Dicun = sgs.CreateTriggerSkill{
	name = "dicun",
	events = {sgs.TargetConfirming},
	can_trigger = function(self, event, room, player, data)
	    local use = data:toCardUse()
		if use.card:isKindOf("EquipCard") or use.card:isKindOf("DelayedTrick") or use.card:isKindOf("SkillCard") then return "" end
		if player and player:isAlive() and player:hasSkill(self:objectName()) and use.to:length()>1 then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
		if use.to:contains(player) then
		  sgs.Room_cancelTarget(use, player)
		end
		data:setValue(use)
		player:drawCards(1)
		if not player:isRemoved() then
		  room:setPlayerCardLimitation(player, "use", ".", false)
          room:setPlayerProperty(player, "removed", sgs.QVariant(true))
		end
	end ,
}

Yuanyu = sgs.CreateTriggerSkill{
	name = "yuanyu",
	events = {sgs.CardsMoveOneTime, sgs.TurnStart, sgs.CardUsed},
	on_record = function(self, event, room, player, data)
		if event == sgs.TurnStart then 
			if player:getMark("yuanyu_used")>0 and not player:hasFlag("Point_ExtraTurn") then
				 room:setPlayerMark(player, "yuanyu_used", 0)
			end
		end
		if event == sgs.CardUsed then
		   local use = data:toCardUse()
		   if use.card:isKindOf("SkillCard") then return end
		   for _,p in sgs.qlist(room:getOtherPlayers(use.from)) do
		      local newlist = p:getTag("yuanyucard"):toList()
			  if newlist:contains(sgs.QVariant(use.card:getEffectiveId())) then
			     newlist:removeOne(sgs.QVariant(use.card:getEffectiveId()))
			     p:setTag("yuanyucard", sgs.QVariant(newlist))
				 p:drawCards(3)
				 room:broadcastSkillInvoke(self:objectName(), 3, player)
                                 --room:doLightbox("$yuanyu_image",1000)
				 local ids = p:handCards()
				 local has = true
				 local players = sgs.SPlayerList()
				 players:append(use.from)
                 while (has and room:askForYiji(p, ids, self:objectName(),false, false, true, -1, players, sgs.CardMoveReason(), "@yuanyu")) do
                     local newhas = false;
                     for _,id in sgs.qlist(p:handCards()) do
                        if (ids.contains(id))then
                           newhas = true;
                        end
                     end
                     has = newhas;
                 end
        
			  end
		   end
		end
	end,
	
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.CardsMoveOneTime then
		   local move = data:toMoveOneTime()
		   if (player:isDead() or not player:hasSkill(self:objectName())) then return "" end
		   if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
                and (not move.to or move.to:objectName() ~= player:objectName() or (move.to_place ~= sgs.Player_PlaceHand and move.to_place ~= sgs.Player_PlaceEquip)) and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) and player:getMark("yuanyu_used") == 0 then
				return self:objectName()
		   end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), math.random(1,2), player)
			room:setPlayerMark(player, "yuanyu_used", 1)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
        local move = data:toMoveOneTime()
		local list = move.card_ids
		if list:length()>0 then
		    room:fillAG(list, player)
			local id = room:askForAG(player, list, false, self:objectName())
			room:clearAG(player)
            local newlist = player:getTag("yuanyucard"):toList()
			newlist:append(sgs.QVariant(id))
			player:setTag("yuanyucard", sgs.QVariant(newlist))
			
			local cards = room:getNCards(5)
			cards:append(id)
			room:askForGuanxing(player, cards, sgs.Room_GuanxingUpOnly)
		end
	end ,
}

Shuaiyan = sgs.CreateTriggerSkill{
	name = "shuaiyan",
	events = {sgs.TargetConfirmed},
	can_trigger = function(self, event, room, player, data)
	    local use = data:toCardUse()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and use.to:length()==1 and player:getPhase() ~= sgs.Player_NotActive and not player:hasFlag("shuaiyan_used") and use.from == player and not use.to:contains(player) and use.card:getTypeId()~=sgs.Card_TypeSkill then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:askForSkillInvoke(self, data) then
		    room:setPlayerFlag(player, "shuaiyan_used")
		    room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
		local dest = use.to:at(0)
		if not dest:isNude() or dest:getJudgingArea():length()>0 then
		    room:obtainCard(player, room:askForCardChosen(player, dest, "hej", self:objectName()))
		end
		if (dest:isAlive() and dest:isFriendWith(player)) then
		   player:drawCards(1)
		end
		if (dest:isAlive() and dest:isFemale()) then
		   dest:drawCards(1)
		end
	end ,
}

Shangxian = sgs.CreateTriggerSkill{
    name = "shangxian",
	events = {sgs.Damaged, sgs.HpRecover},
	on_record = function(self, event, room, player, data)
	   if event == sgs.HpRecover then
		     local shangxianskills = player:getTag("shangxianskills"):toList()
			 local skills = {}
			 for _,s in sgs.qlist(shangxianskills) do
			    if player:hasSkill(s:toString()) then
			      table.insert(skills,s:toString())
				end
			 end
			 if #skills>0 and player:getPhase()~=sgs.Player_NotActive then
			   local skill = room:askForChoice(player, self:objectName(), table.concat(skills, "+"))
			   room:detachSkillFromPlayer(player, skill, false, true, true)
			   shangxianskills:removeOne(sgs.QVariant(skill))
			   player:setTag("shangxianskills", sgs.QVariant(shangxianskills))
			   local general
			   for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
				if sgs.Sanguosha:getGeneral(name):hasSkill(skill) then
					general = name
					break
				end
			   end
			   --[[room:handleUsedGeneral("-"..general)
		       for _,p in sgs.qlist(room:getAllPlayers()) do
			    local list = sgs.SPlayerList()
			    list:append(p)
			    room:doAnimate(7, player:objectName()..":shangxian", "-"..general, list)
		       end]]
			   removeGeneralCardToPile(room, player, general, self:objectName())
			 end
	   end
	end,
	can_trigger = function(self, event, room, player, data)
		if event ~= sgs.Damaged then return "" end
	    local damage = data:toDamage()
		local players = room:findPlayersBySkillName(self:objectName())
		local shangxianskills = damage.to:getTag("shangxianskills"):toList()
		for _,sp in sgs.qlist(players) do
		  if sp:willBeFriendWith(damage.to) and sp ~= damage.to and shangxianskills:length() < damage.to:getMaxHp() then
		     return self:objectName(), sp
		  end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()
		local da = sgs.DamageStruct()
		da.to = ask_who
		room:damage(da)
		local reals = {}
		for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do
		   if table.contains(sgs.Sanguosha:getGeneral(name):getKingdom():split("|"), "real") and not table.contains(getUsedGeneral(room), name) then
		       table.insert(reals,name)
		   end
		end
		if #reals>0 then
		  local name = reals[math.random(1, #reals)]
		  room:doLightbox("image=image/generals/card/"..name..".jpg",1500)
		  local general = sgs.Sanguosha:getGeneral(name)
		  local skills = {}
		  for _,s in sgs.qlist(general:getVisibleSkillList()) do
		     table.insert(skills,s:objectName())
		  end
		  local skill = room:askForChoice(damage.to, self:objectName(), table.concat(skills, "+"))
		  room:acquireSkill(damage.to, skill)
		  local shangxianskills = damage.to:getTag("shangxianskills"):toList()
		  shangxianskills:append(sgs.QVariant(skill))
		  damage.to:setTag("shangxianskills", sgs.QVariant(shangxianskills))

		  --[[room:handleUsedGeneral(name)
		  for _,p in sgs.qlist(room:getAllPlayers()) do
			local list = sgs.SPlayerList()
			list:append(p)
			room:doAnimate(7, damage.to:objectName()..":shangxian", name, list)
		  end]]
		  addGeneralCardToPile(room, damage.to, name, self:objectName())
		end
	end ,
}

Zhufavs = sgs.CreateViewAsSkill{
	name = "zhufa",
	n = 1,
	view_filter=function(self,selected,to_select)
		return #selected == 0 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local pattern = sgs.Self:getTag(self:objectName()):toString()
		if #cards ~=1 or pattern == "" then return end
		local new_card = sgs.Sanguosha:cloneCard(pattern)
		for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end      
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player)
		return not player:hasUsed("ViewAsSkill_zhufaCard")
	end,
}

Zhufa = sgs.CreateTriggerSkill{
	name = "zhufa",
	events = {sgs.CardUsed},
	guhuo_type = "z",
	can_preshow = true,
	view_as_skill = Zhufavs,
	can_trigger = function(self, event, room, player, data)
	    local use = data:toCardUse()
		local can
		local list = player:getTag("zhufa_record"):toString():split("+")
		if not table.contains(list, use.card:objectName()) then can = true end
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:hasShownOneGeneral() then can = true end
		end
		if player:hasSkill(self:objectName()) and player:isAlive() and use.card:isNDTrick() and not room:getCurrent():hasFlag(player:objectName().."zhufa") and can then
           return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:askForSkillInvoke(self, data) then
			room:setPlayerFlag(room:getCurrent(), player:objectName().."zhufa")
		    return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local use = data:toCardUse()
        local list = player:getTag("zhufa_record"):toString():split("+")
		table.insert(list, use.card:objectName())
		player:setTag("zhufa_record", sgs.QVariant(table.concat(list, "+")))
		room:setPlayerMark(player, use.card:objectName().."zhufa", 1)
		local players = room:getOtherPlayers(player)
		room:sortByActionOrder(players)
		for _,p in sgs.qlist(players) do
		   if not p:hasShownOneGeneral() and p:willBeFriendWith(player) then
			 local show=p:askForGeneralShow(true, true)
			 if show then
				room:obtainCard(p, use.card)
				break
			 end
			elseif not p:hasShownOneGeneral() then
				room:askForChoice(p,self:objectName(),"cannot_showgeneral+cancel",data)
			end
		end
	end ,
}

Fashufengyin = sgs.CreateTriggerSkill{
	name = "fashufengyin",
	events = {sgs.CardUsed},
	can_trigger = function(self, event, room, player, data)
	    local use = data:toCardUse()
		local players = room:findPlayersBySkillName(self:objectName())
		for _,p in sgs.qlist(players) do
		   if use.from and p ~= use.from and p:getMark(use.card:objectName().."zhufa")> 0 and not p:isNude() and use.to:length()>0 then
              return self:objectName(), p
		   end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, zero)
		if zero:askForSkillInvoke(self, data) and room:askForDiscard(zero,self:objectName(),1,1,true,true) then
		    return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, zero)
		local use = data:toCardUse()
        return true
	end ,
}

LiqiCard = sgs.CreateSkillCard{
	name = "LiqiCard",
	filter = function(self, targets, to_select) 
		if #targets <1 and sgs.Self:isFriendWith(to_select) and sgs.Self:objectName() ~= to_select:objectName() then
			return true
		end
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		if #targets > 0 then
            local target = targets[1]
			source:loseMark("@liqi")
			target:gainMark("@liqi_dest")
			source:setTag("liqi_dest", sgs.QVariant(target:objectName()))
		end
	end,
}

Liqivs = sgs.CreateZeroCardViewAsSkill{
	name = "liqi",
	view_as = function(self)
	    local vs = LiqiCard:clone()
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@liqi")>0
	end,
}

Liqi = sgs.CreateTriggerSkill{
	name = "liqi",
	events = {sgs.DamageForseen, sgs.EventPhaseStart},
	can_preshow = true,
    frequency = sgs.Skill_Limited,
	limit_mark = "@liqi",
	view_as_skill = Liqivs,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.DamageForseen then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.card:getSubcards():length()>0 then return "" end
		    for _,p in sgs.qlist(room:getOtherPlayers(damage.to)) do
		      if p:getTag("liqi_dest"):toString()==damage.to:objectName() then
                 return self:objectName(),p
		      end
		    end
		end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if (p:getTag("liqi_dest"):toString()==player:objectName() or player:getTag("liqi_dest"):toString()==p:objectName()) and not p:isNude() then
				   return self:objectName(),p
				end
			end
		end
        return ""
	end ,
	on_cost = function(self, event, room, player, data, sp)
		if event == sgs.EventPhaseStart and sp:askForSkillInvoke(self, data) then
		    return true
		end
		if event == sgs.DamageForseen then
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, sp)
        if event == sgs.DamageForseen then
			local damage = data:toDamage()
			damage.to = sp
			data:setValue(damage)
		end
		if event == sgs.EventPhaseStart then
			if sp:isNude() then return false end
            local id = room:askForCardChosen(sp, sp, "he", self:objectName())
			room:obtainCard(player, id, false)
		end
	end ,
}

Bishi = sgs.CreateTriggerSkill{
	name = "bishi",
	events = {sgs.DamageInflicted},
	can_trigger = function(self, event, room, player, data)
	    local damage = data:toDamage()
		if not damage.from or damage.from == player then return "" end
        if (not player:inHeadSkills(self) or not player:hasShownGeneral1()) and (player:inHeadSkills(self) or not player:hasShownGeneral2() or not player:hasShownSkill(self:objectName())) then return "" end
		if player:isAlive() and player:hasSkill(self:objectName()) and damage.from:distanceTo(player)>1 then --((not damage.from:getWeapon() and damage.from:distanceTo(player)>1) or (damage.from:getWeapon() and damage.from:getWeapon():getRealCard():toWeapon():getRange()<damage.from:distanceTo(player))) then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local damage = data:toDamage()
        player:hideGeneral(player:inHeadSkills(self))
		--[[if not damage.from:isNude() then
			local id = room:askForCardChosen(player, damage.from, "he", self:objectName())
            room:throwCard(id, damage.from, player)
		end]]
        return true
	end ,
}

CichuanCard = sgs.CreateSkillCard{
	name = "CichuanCard",
	will_throw = false,
	filter = function(self, targets, to_select) 
		if #targets <1 and sgs.Self:inMyAttackRange(to_select) and to_select:getPile("qiang"):length() == 0 then
			return true
		end
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		if #targets > 0 then
            local target = targets[1]
			room:showCard(source, self:getSubcards():at(0))
            local damage = sgs.DamageStruct()
            damage.from = source
            damage.to = target
            room:damage(damage)
            if target:isAlive() then          
               target:addToPile("qiang", self)
            end
		end
	end,
}

Cichuanvs=sgs.CreateViewAsSkill{
	name="cichuan",
	n=1,
	view_filter=function(self,selected,to_select)
		return #selected == 0 and to_select:getSuitString() == "diamond" and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards ~=1  then return end
		local new_card = CichuanCard:clone()
		for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end      
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player,pattern)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@cichuan"
	end,
}

Cichuan = sgs.CreateTriggerSkill{
	name = "cichuan",
	events = {sgs.EventPhaseEnd, sgs.PreHpRecover},
	view_as_skill = Cichuanvs,
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.EventPhaseEnd then
            if player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
			  return self:objectName()
		    end
        end
		if event == sgs.PreHpRecover then
            if player:getPile("qiang"):length()>0 then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if event == sgs.EventPhaseEnd and player:askForSkillInvoke(self, data) and room:askForUseCard(player, "@@cichuan", "@cichuan") then
		    return true
		end
		if event == sgs.PreHpRecover then
           return true
	    end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.PreHpRecover then
			local id = player:getPile("qiang"):at(0)
			room:throwCard(id, player)
			return true
		end
	end ,
}

Yingdi = sgs.CreateTriggerSkill{
	name = "yingdi",
	events = {sgs.TargetConfirming, sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_record = function(self, event, room, player, data)
       if event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start then
           local can = true
		   for _,p in sgs.qlist(room:getAlivePlayers()) do
			  if not p:hasShownOneGeneral() then can = false end
		   end
		   local n = 0
		   local list = sgs.SPlayerList()
		   for _,p in sgs.qlist(room:getAlivePlayers()) do
			  if p:hasShownOneGeneral() then
				list:append(p)
			  end
		    end
			local initial = list:at(0)
             while list:length()>0 do
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:isFriendWith(initial) and list:contains(p) then 
                         list:removeOne(p)
					end
				end
				n = n+1
				if list:length()>0 then initial = list:at(0) end
			 end
		   if can and n == 2 and player:hasShownSkill(self:objectName()) then
			 local head = player:inHeadSkills(self)
			 room:broadcastSkillInvoke(self:objectName(), 4 ,player)
             room:detachSkillFromPlayer(player, self:objectName(), false, false, head)
			 room:acquireSkill(player, "jiesha", true, head)
		   end
	   end
	end,
	can_trigger = function(self, event, room, player, data)
		if event ~= sgs.TargetConfirming then return "" end
	    local use = data:toCardUse()
		if not use.card:isKindOf("Slash") and not use.card:isKindOf("Duel") then return "" end
		local n = 998
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		   if p:getHandcardNum()< n then n = p:getHandcardNum() end
		end
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getHandcardNum()==n then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), math.random(1,3) ,player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
        local use = data:toCardUse()
		if use.to:contains(player) then
		  sgs.Room_cancelTarget(use, player)
		end
		data:setValue(use)
	end ,
}

Diansuo = sgs.CreateTriggerSkill{
    name = "diansuo",
	events = {sgs.DamageCaused},
	can_trigger = function(self, event, room, player, data)
	    local damage = data:toDamage()
		local players = room:findPlayersBySkillName(self:objectName())
		local chained = sgs.SPlayerList()
	    local dischained = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		   if p:isChained() then
		     chained:append(p)
		   else
             dischained:append(p)		   
		   end
		end
		for _,sp in sgs.qlist(players) do
		  if sp ~= damage.from and sp:isChained() and chained:length()>1 then
		     return self:objectName(), sp
		  elseif sp == damage.from and not sp:isChained() and dischained:length()>1 then
		     return self:objectName(), sp
		  end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:askForSkillInvoke(self, data) then
		    local damage = data:toDamage()
            local chained = sgs.SPlayerList()
			local dischained = sgs.SPlayerList()
		    for _,p in sgs.qlist(room:getOtherPlayers(ask_who)) do
		      if p:isChained() then
		        chained:append(p)
		      else
                dischained:append(p)		   
		      end
		    end
			local target
			if ask_who:isChained() then
			   target = room:askForPlayerChosen(ask_who, chained, self:objectName(), "@diansuo-prompt-remove", true)
			else
			   target = room:askForPlayerChosen(ask_who, dischained, self:objectName(), "@diansuo-prompt", true)
			end
			if target then
			  ask_who:setProperty("diansuo_target", sgs.QVariant(target:objectName()))
			  return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()
		local target = findPlayerByObjectName(ask_who:property("diansuo_target"):toString())
		if not target then return false end
        if player == ask_who then
		  room:broadcastSkillInvoke(self:objectName(), math.random(1,2))
          room:setPlayerProperty(ask_who, "chained", sgs.QVariant(true))
          room:setPlayerProperty(target, "chained", sgs.QVariant(true))
          damage.from = target
          data:setValue(damage)
		else
          room:setPlayerProperty(ask_who, "chained", sgs.QVariant(false))
          room:setPlayerProperty(target, "chained", sgs.QVariant(false))
          damage.to = target
		  room:broadcastSkillInvoke(self:objectName(), 3)
          data:setValue(damage)
		end
	end ,
}

Jiesha = sgs.CreateTriggerSkill{
	name = "jiesha",
	events = {sgs.SlashProceed},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
	    local effect = data:toSlashEffect()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getWeapon() and player:getWeapon():isKindOf("DoubleSword") and effect.to then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName() ,player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
        local effect = data:toSlashEffect()
        local log = sgs.LogMessage()
                log.type = "$jiesha_effect"
                log.from = effect.to
                log.arg = effect.slash:objectName()
                room:sendLog(log);
                room:slashResult(effect, nil)
                return true
	end ,
}

Sjuji = sgs.CreateTriggerSkill{
	name = "sjuji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed},
	can_trigger = function(self, event, room, player, data)
	    local use = data:toCardUse()
		local targets = {}
		if use.card:isKindOf("Slash") and use.from == player and player:isAlive() and player:hasSkill(self:objectName()) then
		   for _,target in sgs.qlist(use.to) do
			   if not target:inMyAttackRange(player) then
                  table.insert(targets, target:objectName())
			   end
		   end
		end
		if #targets>0 then return self:objectName().."->"..table.concat(targets, "+") end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
	    local value = sgs.QVariant()
		value:setValue(player)
		local use = data:toCardUse()
		if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self, value) then
		   if use.card:getNumber() ~= 0 then
			  room:broadcastSkillInvoke(self:objectName(), ask_who)
		   end
           return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
       local use = data:toCardUse()
	   local jink_list = ask_who:getTag("Jink_" .. use.card:toString()):toList()
	   local index = use.to:indexOf(player)
        local log = sgs.LogMessage()
        log.type = "#SE_Juji_XD"
        log.from = player
        room:sendLog(log)
        jink_list:replace(index,sgs.QVariant(0))
		room:setEmotion(player, "snipe")
		ask_who:setTag("Jink_" .. use.card:toString(), sgs.QVariant(jink_list))
	end ,
}

SjujiDis = sgs.CreateDistanceSkill{
	name = "#sjuji_dis",
	correct_func = function(self, from, to)
		if from:hasShownSkill("sjuji") then
			return -1
		end
		return 0
	end
}

Jianyu = sgs.CreateZeroCardViewAsSkill{
	name = "jianyu",
	view_as = function(self)
	    local vs = JianyuCard:clone()
		--vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_jianyuCard")
	end,
}

JianyuCard = sgs.CreateSkillCard{
	name = "JianyuCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select) --必须
		if #targets <math.max(sgs.Self:getLostHp(), 1) and sgs.Self:inMyAttackRange(to_select) then
			return true
		end
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		--room:broadcastSkillInvoke("se_jianyu")
		--room:setPlayerFlag(source,"se_jianyucard_used")
		room:doLightbox("se_jianyu$", 800)
		if #targets > 0 then
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			card:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
			use.from = source
			for _,target in ipairs(targets) do
				use.to:append(target)
			end
			use.card = card
			room:useCard(use, false)
		end
	end,
}

Yaoshi = sgs.CreateTriggerSkill{
    name = "yaoshi",
	events = {sgs.EventPhaseStart, sgs.CardUsed, sgs.Dying},
	on_record = function(self, event, room, player, data)
	   if event == sgs.CardUsed and player:getPhase() == sgs.Player_Play then
          local use = data:toCardUse()
		  if use.card:getTypeId() == sgs.Card_TypeSkill then return end
		  for _,p in sgs.qlist(room:getAlivePlayers()) do
             if player:hasFlag(p:objectName().."yaoshi_target") then
				local suit = player:property("yaoshi"..p:objectName()):toString()
                if suit ~= "" and use.card:getSuitString() ~= suit then
                    room:setPlayerProperty(player, "yaoshi"..p:objectName(), sgs.QVariant())
					local damage = sgs.DamageStruct()
					damage.from = p
					damage.to = player
					room:damage(damage)
				elseif suit ~= "" then
                    room:setPlayerProperty(player, "yaoshi"..p:objectName(), sgs.QVariant())
					p:drawCards(1)
				end
			 end
		  end
	   end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
			  if not sp:isKongcheng() and not player:hasFlag(sp:objectName().."yaoshi") then
				 return self:objectName(), sp
			  end
			end
		end
		if event == sgs.Dying then
			if player:hasSkill(self:objectName()) and player:isAlive() and not player:isNude() and not room:getCurrent():hasFlag(player:objectName().."yaoshi") then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if event == sgs.EventPhaseStart and ask_who:askForSkillInvoke(self, data) then
			local dat = sgs.QVariant()
			dat:setValue(player)
			local card = room:askForCard(ask_who, ".|.|.|hand", "@yaoshi", dat);
		    if card then
				room:setPlayerFlag(player, ask_who:objectName().."yaoshi")
				room:setPlayerFlag(player, ask_who:objectName().."yaoshi_target")
				room:setPlayerProperty(player, "yaoshi"..ask_who:objectName(), sgs.QVariant(card:getSuitString()))
				room:broadcastSkillInvoke(self:objectName(), ask_who)
				return true
			end
		end
		if event == sgs.Dying and ask_who:askForSkillInvoke(self, data) then
			local card = room:askForCard(ask_who, ".|heart|.|.", "@yaoshi2", data);
			if card then
				room:setPlayerFlag(room:getCurrent(), ask_who:objectName().."yaoshi")
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
		if event == sgs.Dying then
           local dying = data:toDying()
		   local recover = sgs.RecoverStruct()
		   recover.who = player
		   room:recover(dying.who, recover, true)
		end
        return false
	end ,
}

Shenxue = sgs.CreateTriggerSkill{
    name = "shenxue",
	events = {sgs.Dying, sgs.Death},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Dying then
			local dying = data:toDying()
			if player:isAlive() and player:hasSkill(self:objectName()) and player == dying.who then
                return self:objectName()
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if player:isAlive() and player:hasSkill(self:objectName()) and player ~= death.who and player:isFriendWith(death.who) then
                return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			--room:broadcastSkillInvoke("Fl_shenxue")
            room:doLightbox("Fl_shenxue$", 999)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
		player:drawCards(1)
		player:turnOver()
		if not player:faceUp() then
			--[[local choice = room:askForChoice(player, self:objectName(), "shenxue_recover+shenxue_attack")
			if choice == "shenxue_recover" then
				local recover = sgs.RecoverStruct()
				recover.who = player
				room:recover(player, recover, true)
			else
                local list = sgs.SPlayerList()
			    for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not p:isFriendWith(player) then list:append(p) end
				end
				local targets = sgs.SPlayerList()
				targets = room:askForPlayersChosen(player, list, self:objectName(), 0, 2, "@shenxue", true)
				for _,p in sgs.qlist(targets) do
					local discard = room:askForDiscard(p, "@shenxue-discard", 2, 2, true, false)
					if not discard then room:loseHp(p) end
				end
			end	]]
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not room:askForDiscard(p, self:objectName(), 2, 2, true, false, "@shenxue") then
                   room:loseHp(p)
				end
			end
		end
        return false
	end ,
}

Pquanneng = sgs.CreateTriggerSkill{
    name = "pquanneng",
	events = {sgs.DamageCaused},
	can_trigger = function(self, event, room, player, data)
	    local damage = data:toDamage()
		local f
		if damage.from:hasShownGeneral1() then
			local general = damage.from:getActualGeneral1()
			if general:isFemale() then f = true end
		end
		if damage.from:hasShownGeneral2() then
			local general = damage.from:getActualGeneral2()
			if general:isFemale() then f = true end
		end
		local players = room:findPlayersBySkillName(self:objectName())
		for _,sp in sgs.qlist(players) do
		  if f and not room:getCurrent():hasFlag(sp:objectName().."pquanneng") then
		     return self:objectName(), sp
		  end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:askForSkillInvoke(self, data) then
			room:setPlayerFlag(room:getCurrent(), ask_who:objectName().."pquanneng")
		    room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
        local damage = data:toDamage()
		ask_who:drawCards(1)
		local list = {}
		if not ask_who:isKongcheng() then table.insert(list, "pquanneng_seehandcards") end
		table.insert(list, "pquanneng_gainmark")
		if (damage.from:getMark("@xuli")>0) then table.insert(list, "pquanneng_losemark") end
		local dat = sgs.QVariant()
		dat:setValue(ask_who)
		local choice = room:askForChoice(damage.from, self:objectName(), table.concat(list, "+"), dat)
		if choice == "pquanneng_seehandcards" and not ask_who:isKongcheng() then
			room:obtainCard(damage.from, room:askForCardChosen(damage.from, ask_who, "h", self:objectName(), true), false)
		elseif choice == "pquanneng_gainmark" then
			damage.from:gainMark("@xuli")
		else
			damage.from:loseMark("@xuli")
			damage.from:drawCards(1)
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover, true)
		end
		if ask_who:hasShownSkill("plianjie") or (ask_who:hasSkill("plianjie") and ask_who:askForSkillInvoke("plianjie", data)) and ask_who:getMark("@haogandu")< 3 then 
			ask_who:showGeneral(ask_who:inHeadSkills("plianjie"))
			if ask_who:getMark("@haogandu")< 3 then
				ask_who:gainMark("@haogandu")
			end
		end
	end ,
}

Plianjie = sgs.CreateTriggerSkill{
    name = "plianjie",
	events = {sgs.EventPhaseStart, sgs.DamageCaused},
	relate_to_place = "head",
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Start then return "" end
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
			  if (player == sp and player:getMark("@haogandu") == 3) then --or (player~=sp and sp:getTag("lianjie_general"):toString()~="") then
				 return self:objectName(), sp
			  end
			end
		end
		if event == sgs.DamageCaused then
			if player:hasSkill(self:objectName()) and player:isAlive() and player:getMark("@haogandu")< 3 then
				return self:objectName(), player
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if event == sgs.EventPhaseStart and ask_who:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		if event == sgs.DamageCaused and (player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data)) then
            return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
        if event == sgs.EventPhaseStart then
			if ask_who == player then
				player:loseAllMarks("@haogandu")
				player:setTag("lianjie_general", sgs.QVariant(player:getActualGeneral2Name()))
				local list = {}
				for _,g in ipairs(sgs.Sanguosha:getLimitedGeneralNames(true)) do
					local general = sgs.Sanguosha:getGeneral(g)
					if general:getKingdom()~="careerist" and #general:getKingdom():split("|") == 1 then
						 table.insert(list, general:getKingdom())
					end
				end
				local kingdom = list[math.random(1,#list)]
				local generals = {}
				for _,g in ipairs(sgs.Sanguosha:getLimitedGeneralNames(true)) do
					if table.contains(sgs.Sanguosha:getGeneral(g):getKingdom():split("|"), kingdom) and sgs.Sanguosha:getGeneral(g):isFemale() and not table.contains(getUsedGeneral(room), g) then
						table.insert(generals, g)
					end
				end
				generals = table.Shuffle(generals)
				local ava = {}
				for i = 1, 3, 1 do
				   if #generals > 0 then
					  local a = generals[1]
					  table.removeOne(generals, a)
					  table.insert(ava, a)
				   end
				end
				if #ava > 0 then
					local to = room:askForGeneral(player, table.concat(ava, "+"), nil,true, self:objectName())
					player:showGeneral(false)
					room:transformDeputyGeneralTo(player, to)
				end
			end
			--[[else
				local sp = ask_who
				local g = sp:getTag("lianjie_general"):toString()
				if not table.contains(getUsedGeneral(room), g) then
					local general = sgs.Sanguosha:getGeneral(g)
					local marks = {}
					for _,s in sgs.qlist(general:getVisibleSkillList()) do
					   if s:getFrequency() == sgs.Skill_Limited and sp:getMark(s:getLimitMark()) == 0 then
						  table.insert(marks, s:getLimitMark())
					   end
					end
					sp:setTag("lianjie_general", sgs.QVariant())
					sp:showGeneral(false)
					room:transformDeputyGeneralTo(sp, g)
					for _,m in ipairs(marks) do
						room:setPlayerMark(sp, m, 0)
					end
				end
			end]]
		end
		if event == sgs.DamageCaused then
			if ask_who:getMark("@haogandu")< 3 then
				ask_who:gainMark("@haogandu")
			end
		end
	end ,
}

Pquannengmax = sgs.CreateMaxCardsSkill{
	name = "#pquannengmax",
	extra_func = function(self, player)
		local has
		if player:getMark("@xuli")>0 then has = true end
		for _,p in sgs.qlist(player:getAliveSiblings()) do
            if p:getMark("@xuli")>0 then has = true end
		end
		if player:hasShownSkill("pquanneng") and has then
           return 1
		end
		return 0
	end
}

Jiaozhi = sgs.CreateTriggerSkill{
    name = "jiaozhi",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
        if player:hasSkill(self:objectName()) and player:isAlive() and player:getPhase()==sgs.Player_Start then
           return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
	    local x = player:getTag("Permanent_PhaseSkip"):toList():length()
		if player:askForSkillInvoke(self, data) then
			local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 0, x+1, "@jiaozhi", true)
		    if targets:length()> 0 then
				local s = {}
				for _,p in sgs.qlist(targets) do
					table.insert(s, p:objectName())
                end
                player:setProperty("jiaozhi_targets", sgs.QVariant(table.concat(s, "+")))
				room:broadcastSkillInvoke(self:objectName(), player)
			    return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
        local targets = player:property("jiaozhi_targets"):toString():split("+")
		for _,q in ipairs(targets) do
			local p = findPlayerByObjectName(q)
			local has
			for _,c in sgs.qlist(p:getJudgingArea()) do
				if c:isKindOf("Key") then has = true end
			end
			if not p:isNude() and not has then
				local id = room:askForCardChosen(player, p, "he", self:objectName())
				--room:throwCard(id, p, player)
				local key = sgs.Sanguosha:cloneCard("keyCard")
				--key:addSubcard(id)
				--key:setSkillName(self:objectName())
				local wrapped = sgs.Sanguosha:getWrappedCard(id)
                wrapped:takeOver(key)
				--local use = sgs.CardUseStruct()
				--use.from = player
				--use.to:append(p)
				--use.card = key
				wrapped:setSkillName(self:objectName())
				--room:useCard(use)
				room:moveCardTo(wrapped, p, p, sgs.Player_PlaceDelayedTrick,
                       sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
                       player:objectName(), self:objectName(), ""))

			elseif has then
                p:drawCards(1)
			end
		end
	end ,
}

MjianshiCard = sgs.CreateSkillCard{
	name = "MjianshiCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local list = {"Judge", "Draw", "Play", "Discard"}
		local phases = source:getTag("Permanent_PhaseSkip"):toList()
		for _,p in sgs.qlist(phases) do
           if table.contains(list, p:toString()) then
              table.removeOne(list, p:toString())
		   end
		end
        if #list>0 then
			local choice = room:askForChoice(source, "mjianshi", table.concat(list, "+"))
			phases:append(sgs.QVariant(choice))
			source:setTag("Permanent_PhaseSkip", sgs.QVariant(phases))
			local phase
			if choice == "Judge" then
				phase = sgs.Player_Judge
			end
			if choice == "Draw" then
				phase = sgs.Player_Draw
			end
			if choice == "Play" then
				phase = sgs.Player_Play
			end
			if choice == "DisCard" then
				phase = sgs.Player_DisCard
			end
			local l = sgs.LogMessage()
			l.type = "$mjianshi"
			l.from = source
			l.arg = choice
			room:sendLog(l)
			local dest = room:askForPlayerChosen(source, room:getOtherPlayers(source), "mjianshi")
			local c =  room:askForChoice(source, "mjianshi", "mjianshi_gain+mjianshi_skip")
			if c == "mjianshi_gain" then
				room:setPlayerFlag(dest, "mjianshi_gain"..choice)
				local l = sgs.LogMessage()
			    l.type = "$mjianshi_gain"
			    l.from = dest
			    l.arg = choice
			    room:sendLog(l)
			else
				room:setPlayerFlag(dest, "mjianshi"..choice)
				l.type = "$mjianshi_skip"
			    l.from = dest
			    l.arg = choice
			    room:sendLog(l)
			end
			local ps = sgs.SPlayerList()
			ps:append(dest)
			ps:append(source)
			local target = room:askForPlayerChosen(source, ps, "@mjianshi")
			target:drawCards(source:getTag("Permanent_PhaseSkip"):toList():length())
		end
	end,
}

Mjianshi = sgs.CreateZeroCardViewAsSkill{
	name = "mjianshi",
	view_as = function(self)
	    local vs = MjianshiCard:clone()
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_mjianshiCard")
	end,
}

MjianshiGlobal = sgs.CreateTriggerSkill{
    name = "mjianshiglobal",
	global = true,
	events = {sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data) 
		local change = data:toPhaseChange()
		local phase = change.to

        if phase == sgs.Player_NotActive and player:hasShownSkill("mjianshi") and player:getMaxCards()< player:getHandcardNum()-1 then
			if player:getHandcardNum() < 2 or not room:askForDiscard(player, self:objectName(), 2, 2, true) then
                room:loseHp(player)
			end
		end


		local ph
		if phase == sgs.Player_Judge then
			ph = "Judge"
		elseif phase == sgs.Player_Draw then
			ph = "Draw"
		elseif phase == sgs.Player_Play then
			ph = "Play"
		elseif phase == sgs.Player_Discard then
			ph = "Discard"
		else
			return
		end
		local phases = player:getTag("Permanent_PhaseSkip"):toList()
		if ph and ((phases:contains(sgs.QVariant(ph)) and player:hasShownSkill("mjianshi")) or player:hasFlag("mjianshi"..ph)) and not player:isSkipped(phase) then
			if player:hasFlag("mjianshi"..ph) then
				room:setPlayerFlag(player, "-mjianshi"..ph)
			end
           player:skip(phase)
		end
	end,
	can_trigger = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		local phase = change.to
		
		if phase == sgs.Player_Start then
			local ph
			if player:hasFlag("mjianshi_gainJudge") then
			   ph = sgs.Player_Judge
			elseif player:hasFlag("mjianshi_gainDraw") then
			   ph = sgs.Player_Draw
			elseif player:hasFlag("mjianshi_gainPlay") then
			   ph = sgs.Player_Play
			elseif player:hasFlag("mjianshi_gainDiscard") then
			   ph = sgs.Player_Discard
			end
			if ph and not player:hasFlag("mjianshi_on") then
			   return self:objectName()
			end
		elseif phase == sgs.Player_Finish and player:hasFlag("mjianshi_on") then
		    player:setFlags("-mjianshi_on")
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		player:setFlags("mjianshi_on")
		return true 
	end,
	on_effect = function(self, event, room, player, data)
        local change = data:toPhaseChange()
		local phase = change.to
		
		if phase == sgs.Player_Start then
			local ph
			if player:hasFlag("mjianshi_gainJudge") then
			   ph = sgs.Player_Judge
			elseif player:hasFlag("mjianshi_gainDraw") then
			   ph = sgs.Player_Draw
			elseif player:hasFlag("mjianshi_gainPlay") then
			   ph = sgs.Player_Play
			elseif player:hasFlag("mjianshi_gainDiscard") then
			   ph = sgs.Player_Discard
			end
			if ph then
			   change.to = ph
			   data:setValue(change)
			   player:insertPhase(ph)
			end
		end
	end
}

Youji = sgs.CreateTriggerSkill{
	name = "youji",
    events = {sgs.Damaged, sgs.HpLost},
	can_trigger = function(self, event, room, player, data)
        local players = room:findPlayersBySkillName(self:objectName())
		for _,sp in sgs.qlist(players) do
		  if player:getMark("@youji")==0 and player:getHp()<player:getMaxHp()/2 and player:isAlive() then
		     return self:objectName(), sp
		  end
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
		if sp:askForSkillInvoke(self, data) then
		   room:broadcastSkillInvoke(self:objectName(), sp)
		   return true
	    end
	end,
	on_effect = function(self, event, room, player, data, sp)
		sp:drawCards(1)
        player:gainMark("@youji")
	end
}

Songxin = sgs.CreateTriggerSkill{
	name = "songxin",
    events = {sgs.Death},
	can_trigger = function(self, event, room, player, data)
		local death = data:toDeath()
        if player:isAlive() and player:hasSkill(self:objectName()) and death.who:getMark("@youji")>0 then
			return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
		if player:askForSkillInvoke(self, data) then
		   room:broadcastSkillInvoke(self:objectName(), player)
		   return true
	    end
	end,
	on_effect = function(self, event, room, player, data, sp)
        local choices = "songxin_choose"
		local death = data:toDeath()
		if death.damage and death.damage.from and death.damage.from:isAlive() then
			choices = "songxin_choose+songxin_source"
		elseif death.who:handCards():length()==0 then
			return false
		end 
		local choice = room:askForChoice(player, self:objectName(), choices, data)
		if choice == "songxin_choose" and death.who:handCards():length()>0 then
			local dest = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "@songxin", true, true)
			if dest then
				local dummy = sgs.DummyCard()
				for _,id in sgs.qlist(death.who:handCards()) do
					dummy:addSubcard(id)
				end
				room:obtainCard(dest, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName()), false)
				dummy:deleteLater()
			end
		end
		if choice == "songxin_source" then
		   local source = death.damage.from
		   local id = room:getNCards(1):at(0)
		   local typeid = sgs.Sanguosha:getCard(id):getTypeId()
           room:obtainCard(source, id)
           local dummy = sgs.DummyCard()
		   for _,c in sgs.qlist(source:getHandcards()) do
              if c:getTypeId()~=typeid then
                  dummy:addSubcard(c)
			  end
		   end
		   for _,c in sgs.qlist(source:getEquips()) do
			 if c:getTypeId()~=typeid then
				dummy:addSubcard(c)
			 end
		   end
		   room:throwCard(dummy, source, source)
		   dummy:deleteLater()
		end
		if player:getMark("@youji")>0 then
			player:loseMark("@youji")
			player:drawCards(1)
		end
	end
}

Youjimax = sgs.CreateMaxCardsSkill{
	name = "#youjimax" ,
	extra_func = function(self, player)
		local room = player:getRoom()
		local n = 0
		for _,p in sgs.qlist(room:getAlivePlayers()) do
           n = n+p:getMark("@youji")
		end
		if player:hasShownSkill("youji") then
			return n
		end
		return 0
	end
}

Tancha = sgs.CreateTriggerSkill{
	name = "tancha",
    events = {sgs.EventPhaseStart, sgs.ChoiceMade},
	on_record = function(self, event, room, player, data)
       if event == sgs.ChoiceMade then
          local datalist = data:toString():split(":")
		  if datalist[1]~=self:objectName() then return end
		  local choice = datalist[2]
		  local target = findPlayerByObjectName(datalist[3])
		  if not target then return end
		  local can = false
		  if choice == "handcards" then
             for _,c in sgs.qlist(target:getHandcards()) do
                if c:isKindOf("Slash") then
					can = true
					break
				end
			 end
		  end
		  if choice == "head_general" and player:getKingdom()~=target:getActualGeneral1():getKingdom() then
			 can = true
		  end
		  if choice == "deputy_general" and player:getKingdom()~=target:getActualGeneral2():getKingdom() then
			can = true
		  end
		  if can then
             local slash = sgs.Sanguosha:cloneCard("slash")
			 local use = sgs.CardUseStruct()
		     use.from = player
		     use.to:append(target)
		     use.card = slash
		     room:useCard(use, false)
		  else
             player:drawCards(1)
		  end
	   end
	end,
	can_trigger = function(self, event, room, player, data)
       if event==sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:isAlive() and player:getPhase()==sgs.Player_Play then
          return self:objectName()
	   end
 	end,
	on_cost = function(self, event, room, player, data, sp)
       local c = sgs.Sanguosha:cloneCard("known_both")
       local targets = sgs.SPlayerList()
	   for _,p in sgs.qlist(room:getOtherPlayers(player)) do
          if not player:isProhibited(p, c) then targets:append(p) end		  
	   end
	   local target = room:askForPlayerChosen(player, targets, self:objectName(), "@tancha", true, true)
	   if target then
		  player:setProperty("tancha_target", sgs.QVariant(target:objectName()))
		  --room:broadcastSkillInvoke(self:objectName(), player)
		  return true
	   end
	end,
	on_effect = function(self, event, room, player, data, sp)
		local target = findPlayerByObjectName(player:property("tancha_target"):toString())
		if not target then return false end
		local c = sgs.Sanguosha:cloneCard("known_both", sgs.Card_NoSuit, -1)
		c:setSkillName(self:objectName())
		local use = sgs.CardUseStruct()
		use.from = player
		use.to:append(target)
		use.card = c
		room:useCard(use, false)
	end
}

Boxi = sgs.CreateTriggerSkill{
	name = "boxi",
    events = {sgs.GeneralShown},
	priority = -4,
	can_trigger = function(self, event, room, player, data)
		local players = room:findPlayersBySkillName(self:objectName())
		for _,sp in sgs.qlist(players) do
		  if player ~= sp then
		     return self:objectName(), sp
		  end
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        local targets = sgs.SPlayerList()
	   for _,p in sgs.qlist(room:getAlivePlayers()) do
          if p:isFriendWith(sp) then targets:append(p) end		  
	   end
	   local target
	   if player:isFriendWith(sp) then
		  target = room:askForPlayerChosen(sp, targets, self:objectName(), "@boxi1", true, true)
	   else
		  target = room:askForPlayerChosen(sp, targets, self:objectName(), "@boxi2", true, true)
	   end
	   if target then
		 if player:isFriendWith(sp) then
			target:setFlags("boxi_draw")
		 else
			target:setFlags("boxi_slash")
		 end
		 sp:setProperty("boxi_target", sgs.QVariant(target:objectName()))
	  	 return true
	   end
	end,
	on_effect = function(self, event, room, player, data, sp)
        local target = findPlayerByObjectName(sp:property("boxi_target"):toString())
		if not target then return false end
		if target:hasFlag("boxi_slash") then
			target:setFlags("-boxi_slash")
			room:askForUseSlashTo(target, player, "#boxi", false)
		end
		if target:hasFlag("boxi_draw") then
			target:setFlags("-boxi_draw")
			target:drawCards(1)
			if not sp:isRemoved() and sp~=target then
				room:setPlayerCardLimitation(sp, "use", ".", false)
				room:setPlayerProperty(sp, "removed", sgs.QVariant(true))
			end
		end
	end
}

Fenglun = sgs.CreateViewAsSkill{
	name = "fenglun",
	n = 1,
	view_filter=function(self,selected,to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
        local vs = FenglunCard:clone()
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])                
        end  
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_fenglunCard")
	end,
}

FenglunCard = sgs.CreateSkillCard{
	name = "FenglunCard",
	filter = function(self, targets, to_select) --必须
		return #targets == 0
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		local id = self:getSubcards():at(0)
		if target and id > -1 then
           local card = sgs.Sanguosha:getCard(id)
		   local damage = sgs.DamageStruct()
		   damage.from = source
		   damage.to = target
		   if card:isKindOf("BasicCard") then
              local c = room:askForCard(target, "Slash", "@fenglun-basic", sgs.QVariant(), "fenglun")
			  if not c then
                 room:damage(damage)
			  end
		   elseif card:isKindOf("EquipCard") then
			local discard = room:askForDiscard(target, "@fenglun-equip", 2, 2, true, false)
			if not discard then room:damage(damage) end
		   elseif card:isKindOf("TrickCard") then
			  local choice = room:askForChoice(target, "fenglun", "@fenglun-trick+cancel")
              if choice == "@fenglun-trick" then
				source:drawCards(1)
				local use = sgs.CardUseStruct()
				use.from = source
				use.to:append(target)
				use.card = sgs.Sanguosha:cloneCard("duel")
				room:useCard(use)
			  else
                room:damage(damage)
			  end
		   end
		end
	end,
}

Linggantri = sgs.CreateTriggerSkill{
	name = "#linggantri",
    events = {sgs.TurnStart},
	on_record = function(self, event, room, player, data)
		if event == sgs.TurnStart then
			if (player:getMark("linggan1_used")>0 or player:getMark("linggan2_used")>0) and not player:hasFlag("Point_ExtraTurn") then
				 room:setPlayerMark(player, "linggan1_used", 0)
				 room:setPlayerMark(player, "linggan2_used",0)
			end
			if player:getMark("tuili_hused")>0 and not player:hasFlag("Point_ExtraTurn") then
                room:setPlayerMark(player, "tuili_hused", 0)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return ""
	end,
}

Linggan = sgs.CreateTriggerSkill{
	name = "linggan",
    events = {sgs.GeneralShown, sgs.TurnStart},
	priority = -4,
	--[[on_record = function(self, event, room, player, data)
		if event == sgs.TurnStart then 
			if player:getMark("linggan_used")>0 and not player:hasFlag("Point_ExtraTurn") then
				 room:setPlayerMark(player, "linggan_used", 0)
			end
		end
	end,]]
	can_trigger = function(self, event, room, player, data)
		if event ~= sgs.GeneralShown then return "" end
		local players = room:findPlayersBySkillName(self:objectName())
		for _,sp in sgs.qlist(players) do
			local has = false
			for _,c in sgs.qlist(sp:getJudgingArea()) do
			   if c:isKindOf("Indulgence") then has = true end
			end
		  if (player ~= sp and sp:getMark("linggan1_used")==0) or (sp:getMark("linggan2_used")==0 and sp == player and sp:inHeadSkills(self) == data:toBool() and not has) then
		     return self:objectName(), sp
		  end
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        if sp:askForSkillInvoke(self, data) then
		   if player ~= sp then
		     room:setPlayerMark(sp, "linggan1_used", 1)
		   else
			  room:setPlayerMark(sp, "linggan2_used", 1)
		   end
           room:broadcastSkillInvoke(self:objectName(), sp)
		   return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        if sp == player then
			sp:drawCards(2)
			local has = false
			for _,c in sgs.qlist(sp:getJudgingArea()) do
			   if c:isKindOf("Indulgence") then has = true end
			end
			if not has then
				local key = sgs.Sanguosha:cloneCard("Indulgence")
				local id = room:getNCards(1, true):at(0)
				local wrapped = sgs.Sanguosha:getWrappedCard(id)
                wrapped:takeOver(key)
				wrapped:setSkillName(self:objectName())
				room:moveCardTo(wrapped, sp, sp, sgs.Player_PlaceDelayedTrick,
                       sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
                       player:objectName(), self:objectName(), ""))
			end
		else
            local list = sgs.IntList()
			local drawlist = room:getDrawPile()
			if drawlist:isEmpty() then return false end
			for i = 1, 3, 1 do
                if drawlist:length()-4+i >= 0 then
                   list:append(drawlist:at(drawlist:length()-4+i))
				end
			end
			local id = -1
			room:fillAG(list, sp)
			id = room:askForAG(sp, list, true, self:objectName())
			room:clearAG(sp)
			if id > -1 then
				local ex = room:askForCard(sp, ".|.|.|hand", "@linggan", sgs.QVariant(), sgs.Card_MethodNone)
                local index
				for i = 1,3,1 do
                   if i <= list:length() and list:at(i-1) == id then index = i+drawlist:length()-list:length()-1 end
				end
                if ex then
                   room:putIdAtDrawpile(ex:getEffectiveId(), index)
				   room:obtainCard(sp, id, false)
				end
			end
		end
	end
}

Jieneng = sgs.CreateTriggerSkill{
	name = "jieneng",
    events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if player:hasSkill(self:objectName()) and (player:getPhase()==sgs.Player_Judge or player:getPhase()==sgs.Player_Discard) then
			local has = false
			for _,c in sgs.qlist(player:getJudgingArea()) do
			   if c:isKindOf("Indulgence") then has = true end
			end
			if has then return self:objectName() end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
           room:broadcastSkillInvoke(self:objectName(), player)
		   return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        if not player:hasFlag("jienengmax") then
           room:setPlayerFlag(player, "jienengmax")
		end
	end
}

Jienengmax = sgs.CreateMaxCardsSkill{
	name = "#jienengmax" ,
	extra_func = function(self, player)
		if player and player:hasFlag("jienengmax")  then
			return 3
		end
		return 0
	end
}

Tuili = sgs.CreateTriggerSkill{
	name = "tuili",
    events = {sgs.CardUsed},
	can_trigger = function(self, event, room, player, data)
		local players = room:findPlayersBySkillName(self:objectName())
		local use = data:toCardUse()
		local drawlist = room:getDrawPile()
		local has
		for i = 1, 3, 1 do
			if drawlist:length()-4+i >= 0 then
			   local c = sgs.Sanguosha:getCard(drawlist:at(drawlist:length()-4+i))
			   if c:objectName() == use.card:objectName() then has = true end 
			end
		end
		for _,sp in sgs.qlist(players) do
		  for _,c in sgs.qlist(sp:getHandcards()) do
			if c:objectName() == use.card:objectName() then has = true end 
		  end
		  if (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) and not room:getCurrent():hasFlag("tuili"..sp:objectName()) and has then
		     return self:objectName(), sp
		  end
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        if sp:askForSkillInvoke(self, data) then
           room:broadcastSkillInvoke(self:objectName(), sp)
		   return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
		local use = data:toCardUse()
		local list = sgs.IntList()
		local dis = sgs.IntList()
		local drawlist = room:getDrawPile()
		if drawlist:isEmpty() then return false end
		for i = 1, 3, 1 do
			if drawlist:length()-4+i >= 0 then
			   local c = sgs.Sanguosha:getCard(drawlist:at(drawlist:length()-4+i))
			   if c:objectName() ~= use.card:objectName() then dis:append(drawlist:at(drawlist:length()-4+i)) end 
			   list:append(drawlist:at(drawlist:length()-4+i))
			end
		end
		local id = -1
		local card
		room:fillAG(list, sp, dis)
		room:setPlayerProperty(sp, "tuili_pattern", data)
		id = room:askForAG(sp, list, true, self:objectName())
		room:clearAG(sp)
		if id < 0 then
			if use.card:objectName() == "slash" then
				card = room:askForCard(sp, "Slash+^FireSlash+^ThunderSlash+^IceSlash|.|.|.", "@tuili")
			else
			    card = room:askForCard(sp, use.card:getClassName(), "@tuili")
			end
		else
			room:throwCard(id, sp)
		end
		room:setPlayerProperty(sp, "tuili_pattern", sgs.QVariant())
		if id > -1 or card then
			room:setPlayerFlag(room:getCurrent(), "tuili"..sp:objectName())
			local targets = room:askForPlayersChosen(sp, room:getAlivePlayers(), self:objectName(), 1, 2, "@tuili_choose")
			for _,p in sgs.qlist(targets) do
				p:drawCards(1)
			end
			if card and sp:getMark("tuili_hused")==0 and room:askForChoice(sp, self:objectName(), "tuili_hide+cancel") == "tuili_hide" then
			    room:setPlayerMark(sp, "tuili_hused", 1)
               sp:hideGeneral(sp:inHeadSkills(self))
			end
		end
	end
}

Youzheng = sgs.CreateTriggerSkill{
	name = "youzheng",
    events = {sgs.EventPhaseStart, sgs.Pindian},
	on_record = function(self, event, room, player, data)
		if event == sgs.Pindian then
           local pd = data:toPindian()
		   if pd.reason ~= "youzheng" then return "" end
		   local winner
		   local loser
		   if pd.from_number == pd.to_number then return "" end
		   if pd.from_number > pd.to_number then
			 winner = pd.from
			 loser = pd.to
		   else
			winner = pd.to
			loser = pd.from
		   end
		   local index = winner:property("youzheng_index"):toInt()
			local dest = winner:property("youzheng_dest"):toPlayer()
			loser:doCommandForcely(self:objectName(), index, winner, dest)
			if winner:objectName() == player:objectName() and room:askForChoice(winner, self:objectName(), "exchange_two_general+cancel", data) == "exchange_two_general" then
				local head = winner:getActualGeneral1Name()
				local deputy = winner:getActualGeneral2Name()
                winner:showGeneral(true)
				winner:showGeneral(false)
				winner:removeGeneral(true)
				winner:removeGeneral(false)
				room:exchangeHeadGeneralTo(winner, deputy)
				room:exchangeDeputyGeneralTo(winner, head)
			end
        end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase()==sgs.Player_Start then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        local list = sgs.SPlayerList()
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		      if not p:isFriendWith(player) then
				list:append(p)		   
		      end
		    end
			local target 
			if player:askForSkillInvoke(self,data) then
			  target =  room:askForPlayerChosen(player, list, self:objectName(), "@youzheng", true)
			end
			if target then
			  local index = 0
			  if player:inHeadSkills(self) then
				index = 1
			  else
				index = 2
			  end
			  room:broadcastSkillInvoke(self:objectName(), index, player)
			  player:setProperty("youzheng_target", sgs.QVariant(target:objectName()))
			  return true
			end
	end,
	on_effect = function(self, event, room, player, data, sp)
        local target = findPlayerByObjectName(player:property("youzheng_target"):toString())
		if not target then return false end
        local n1 = player:startCommand(self:objectName())
		local dest1
		if n1 == 0 then
           dest1 = room:askForPlayerChosen(player, room:getAlivePlayers(), "command_youzheng", "@command-damage")
		   room:doAnimate(1, player:objectName(), dest1:objectName())
	    end
		local n2 = target:startCommand(self:objectName())
		local dest2
		if n2 == 0 then
			dest2 = room:askForPlayerChosen(target, room:getAlivePlayers(), "command_youzheng", "@command-damage")
			room:doAnimate(1, target:objectName(), dest2:objectName())
		end

		room:setPlayerProperty(player, "youzheng_index", sgs.QVariant(n1))
		data1 = sgs.QVariant()
		data1:setValue(dest1)
		room:setPlayerProperty(player, "youzheng_dest",data1)
		room:setPlayerProperty(target,"youzheng_index", sgs.QVariant(n2))
		data2 = sgs.QVariant()
		data2:setValue(dest2)
		room:setPlayerProperty(target,"youzheng_dest", data2)

		player:drawCards(1)
		target:drawCards(1)
		if player:isKongcheng() or target:isKongcheng() then return false end
		local pd = player:pindianSelect(target, "youzheng")
		player:pindian(pd)
	end
}

Sorazhi = sgs.CreateTriggerSkill{
	name = "sorazhi",
	relate_to_place = "head",
    events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime and player:hasSkill(self:objectName()) and player:isAlive() and room:getCurrent() and not room:getCurrent():hasFlag("sorazhi2"..player:objectName()) then
			local move = data:toMoveOneTime()
			if (not move.from or move.from:objectName()~=player:objectName() or not move.from_places:contains(sgs.Player_PlaceHand)) and (not move.to or move.to:objectName()~=player:objectName() or move.to_place~=sgs.Player_PlaceHand) then return "" end
			local list = sgs.SPlayerList()
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		      if p:getHandcardNum()==player:getHandcardNum() then
				list:append(p)		   
		      end
		    end
			if list:length()==0 then return "" end
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        local list = sgs.SPlayerList()
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		      if p:getHandcardNum()==player:getHandcardNum() then
				list:append(p)		   
		      end
		    end
			local target 
			if player:askForSkillInvoke(self,data) then
			  target =  room:askForPlayerChosen(player, list, self:objectName(), "@sorazhi", true)
			end
			if target then
			  room:broadcastSkillInvoke(self:objectName(), player)
			  player:setProperty("sorazhi_target", sgs.QVariant(target:objectName()))
			  local cur = room:getCurrent()
			  if not cur:hasFlag("sorazhi1"..player:objectName()) then
                  room:setPlayerFlag(cur, "sorazhi1"..player:objectName())
			  else
				  room:setPlayerFlag(cur, "sorazhi2"..player:objectName())
			  end
			  return true
			end
	end,
	on_effect = function(self, event, room, player, data, sp)
        local target = findPlayerByObjectName(player:property("sorazhi_target"):toString())
		if not target then return false end
        local choice = "sora_draw"
		if not target:isNude() then
            choice = room:askForChoice(player, self:objectName(), "sora_draw+sora_discard")
		end
		if choice == "sora_draw" then
			target:drawCards(1)
		elseif not target:isNude() then
			room:askForDiscard(target, self:objectName(), 1, 1, false, true)
		end
	end
}

Shiroshi = sgs.CreateTriggerSkill{
	name = "shiroshi",
	relate_to_place = "deputy",
    events = {sgs.HpChanged},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.HpChanged and player:hasSkill(self:objectName()) and player:isAlive() --[[and room:getCurrent() and not room:getCurrent():hasFlag("shiroshi"..player:objectName())]] then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
		local x = 0
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHp() == player:getHp() then
               x = x+1
		    end
		end
        x = math.max(1, x)
		local ids = room:getNCards(x, false)
		room:askForGuanxing(player, ids)
		local list = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getHp() == player:getHp() then
               list:append(p)
		    end
		end
		local target
        if list:length()>= 1  then
			target = room:askForPlayerChosen(player, list, self:objectName(), "@shiro", true)		    
		end
		if target then
			target:drawCards(1)
			local list = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if target:inMyAttackRange(p) then
				   list:append(p)
				end
			end
			local t
			if list:length()>= 1  then
				t = room:askForPlayerChosen(player, list, self:objectName(), "@shiroshi", true)		    
			end
			if t then
				local c = sgs.Sanguosha:cloneCard("known_both", sgs.Card_NoSuit, -1)
				c:setSkillName(self:objectName())
				local use = sgs.CardUseStruct()
				use.from = player
				use.to:append(t)
				use.card = c
				room:useCard(use, false)
			end
		end
	end
}

Lizhan = sgs.CreateTriggerSkill{
	name = "lizhan",
    events = {sgs.Damage, sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if player:hasSkill(self:objectName()) and player:isAlive() and player:getMark("#lizhan_mark")< player:getMaxHp() then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self,data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        player:gainMark("#lizhan_mark")
	end
}

Lizhanmax = sgs.CreateMaxCardsSkill{
	name = "#lizhanmax" ,
	extra_func = function(self, player)
		if player and player:getMark("#lizhan_mark")>0 and player:hasShownSkill("lizhan") then
			return 1
		end
		return 0
	end
}

Caokai = sgs.CreateTriggerSkill{
	name = "caokai",
    events = {sgs.EventPhaseStart, sgs.DamageCaused},
	on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			room:setPlayerMark(player, "#lizhan", 0)
		end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and player:getMark("#lizhan")>0 and not damage.chain and not damage.transfer then
				damage.damage = damage.damage+1
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase()==sgs.Player_Judge and player:getMark("#lizhan_mark")>0 then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self, data) then
           room:broadcastSkillInvoke(self:objectName(), player)
		   --room:broadcastSkillInvoke("Flcaokai")
           room:doLightbox("Flcaokai$", 999)
		   return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        player:loseMark("#lizhan_mark")
		if player:getMark("longhua_used")>0 and player:getJudgingArea():length()>0 then
			local id = room:askForCardChosen(player,player,"j",self:objectName())
			room:throwCard(id, player)
		end
		if player:getMark("longhua_used")>0 then 
		    room:setPlayerMark(player, "#lizhan", 2)
		else
			room:setPlayerMark(player, "#lizhan", 1)
		end
	end
}

Caokaitr = sgs.CreateTargetModSkill{
	name = "#caokaitr",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player:getMark("#lizhan")>1 then
			return 1
		end
		return 0
	end,
}

Longhua = sgs.CreateTriggerSkill{
	name = "longhua",
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	frequency = sgs.Skill_Limited,
	relate_to_place = "head",
    limit_mark = "@longhua",
	on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging and player:hasSkill(self:objectName()) then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("longhua_used")>0 and player:getMark("#lizhan_mark") < player:getMaxHp() then
                if (player:isAlive()) then
					player:removeGeneral(player:inHeadSkills(self));
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase()==sgs.Player_Start and player:getMark("#lizhan_mark")>=player:getMaxHp() and player:getHp()<=1 and player:getMark("@longhua")>0 then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self, data) then
		   player:loseMark("@longhua")
           room:broadcastSkillInvoke(self:objectName(), player)
		   return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+1))
		local recover = sgs.RecoverStruct()
		recover.who = player
		room:recover(player, recover, true)
		room:setPlayerMark(player, "longhua_used", 1)
	end
}

HuanshenCard= sgs.CreateSkillCard
{   name = "HuanshenCard",	
	skill_name = "huanshen",
	target_fixed = true,
	on_use=function(self,room,player,targets)
		player:drawCards(self:getSubcards():length())
	end,
}

Huanshenvs = sgs.CreateViewAsSkill{
	name = "huanshen",
	view_filter = function(self, selected, to_select)
		return #selected < sgs.Self:getHandcardNum()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs=HuanshenCard:clone()
            for _, card in ipairs(cards) do
				vs:addSubcard(card)
			end    
			vs:setShowSkill(self:objectName())			
		return vs
	end,
	enabled_at_play=function(self,player,pattern)
		return not player:isKongcheng() and not player:hasUsed("ViewAsSkill_huanshenCard")
	end,
	enabled_at_response=function(self,player,pattern) 
		return pattern=="@@huanshen" and not player:isKongcheng()
	end,
}

Huanshen = sgs.CreateTriggerSkill{
	name = "huanshen",
    events = {sgs.DamageInflicted},
    view_as_skill = Huanshenvs,
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if event == sgs.DamageInflicted and player:hasSkill(self:objectName()) and (not damage.card or not damage.card:isKindOf("Slash")) then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self, data) and room:askForUseCard(player, "@@huanshen", "@huanshen") then
           room:broadcastSkillInvoke(self:objectName(), player)
		   return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        return false
	end
}

Sshiji = sgs.CreateTriggerSkill{
	name = "sshiji",
    events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, event, room, player, data)
		local move = data:toMoveOneTime()
		if event == sgs.CardsMoveOneTime and move.from and move.from:objectName() == player:objectName() and player:hasSkill(self:objectName()) and move.reason.m_skillName == "huanshen" and move.to_place == sgs.Player_DiscardPile and not room:getCurrent():hasFlag("sshiji"..player:objectName()) then
           if sameColor(move.card_ids) or hasFlush2(move.card_ids) or threeType(move.card_ids) or threeSameName(move.card_ids) then
			 return self:objectName()
		   end
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
		   room:setPlayerFlag(room:getCurrent(), "sshiji"..player:objectName())
           room:broadcastSkillInvoke(self:objectName(), player)
		   --room:broadcastSkillInvoke("Fhsshiji")
           room:doLightbox("Fhsshiji$", 999)
		   return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
		local move = data:toMoveOneTime()
        if sameColor(move.card_ids) and player:isWounded() and (move.card_ids:length()>=3 or player:isKongcheng()) and player:askForSkillInvoke("sshiji_recover", data) then
            local recover = sgs.RecoverStruct()
		    recover.who = player
		    room:recover(player, recover, true)
		end
		if hasFlush2(move.card_ids) then
			local froms = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
               if p:getJudgingArea():length()>0 then froms:append(p) end
			end
			local from
			if froms:length() > 0 then from = room:askForPlayerChosen(player, froms, self:objectName(), "@sshiji_from", true)	 end
			if from then 
               local to
			   local tos = sgs.SPlayerList()
			   for _,p in sgs.qlist(room:getOtherPlayers(from)) do
				   local same
				   for _,c in sgs.qlist(p:getJudgingArea()) do
					for _,d in sgs.qlist(from:getJudgingArea()) do
						if c:objectName() == d:objectName() then same = true end
					end
				   end
				   if not same then tos:append(p) end
			   end
			   if tos:length() > 0 then to = room:askForPlayerChosen(player, tos, self:objectName(), "@sshiji_to") end
			   if to then 
				  for _,c in sgs.qlist(from:getJudgingArea()) do
					room:moveCardTo(c, from, to, sgs.Player_PlaceDelayedTrick,
					sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,
					player:objectName(), self:objectName(), ""))
				  end
			   end
			end
		end

		if threeType(move.card_ids) and player:askForSkillInvoke("sshiji_turnover", data) then
            room:getCurrent():turnOver()
		end
		if threeSameName(move.card_ids) and player:askForSkillInvoke("sshiji_obtain", data) then
			local list = room:getDiscardPile()
            for i = 1,3,1 do
			   if list:length()>0 then
                  local id = list:at(math.random(1,list:length()-1))
				  for _,i in sgs.qlist(list) do
                      if sgs.Sanguosha:getCard(i):objectName() == sgs.Sanguosha:getCard(id):objectName() then
                         list:removeOne(i)
					  end
				  end
				  room:obtainCard(player, id)
			   end
			end

			room:setPlayerFlag(player, "sshiji_extra")
		end
	end
}

Shijitr = sgs.CreateTargetModSkill{
	name = "#shijitr",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasFlag("sshiji_extra") then
			return 1
		end
		return 0
	end,
}

function hasFlush2(list)
	local heart = {} 
	local club = {} 
	local spade = {} 
	local diamond = {}
	for _,id in sgs.qlist(list) do
       local c = sgs.Sanguosha:getCard(id)
	   if c:getSuitString() == "heart" then table.insert(heart, c) end
	   if c:getSuitString() == "club" then table.insert(club, c) end
	   if c:getSuitString() == "spade" then table.insert(spade, c) end
	   if c:getSuitString() == "diamond" then table.insert(diamond, c) end
	end
	return #heart >=3 or #club >=3 or #spade >=3 or #diamond >=3
end

function sameColor(list)
	for _,id in sgs.qlist(list) do
       local c = sgs.Sanguosha:getCard(id)
	   local cc = sgs.Sanguosha:getCard(list:at(0))
	   if getColorString(c)~=getColorString(cc) then return false end      
	end
	return true
end

function threeType(list)
	if list:length() < 3 then return false end
	local c = sgs.Sanguosha:getCard(list:at(0))
	local cc
	for _,id in sgs.qlist(list) do
       local card = sgs.Sanguosha:getCard(id)
	   if card:getTypeId()~=c:getTypeId() then
	       cc = card
		   break
	   end      
	end
	if not cc then return false end
	for _,id in sgs.qlist(list) do
		local card = sgs.Sanguosha:getCard(id)
		if card:getTypeId()~=c:getTypeId() and card:getTypeId()~=cc:getTypeId() then
			return true
		end      
	 end
	return false
end

function threeSameName(list)
	if list:length() < 3 then return false end
	for _,id0 in sgs.qlist(list) do
		local c = sgs.Sanguosha:getCard(id0)
		local cc
		local idd
		for _,id in sgs.qlist(list) do
		   local card = sgs.Sanguosha:getCard(id)
		   if card:objectName()==c:objectName() and id ~= id0 then
			   cc = card
			   idd = id
			   break
		   end
		end
		if cc then
			for _,id in sgs.qlist(list) do
				local card = sgs.Sanguosha:getCard(id)
				if card:objectName()==c:objectName() and id ~= id0 and id ~= idd then
					return true
				end      
			end
		end
	end
	return false
end

Qiangdou = sgs.CreateTriggerSkill{
	name = "qiangdou", 
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.CardFinished,sgs.TargetConfirmed,sgs.ConfirmDamage}, 
	on_record = function(self, event, room, player, data)
		if event == sgs.TargetConfirmed then
           local use = data:toCardUse()
		   local has
		   local list = player:getJudgingArea()
               for _, i in sgs.qlist(list) do
                 if  i:isKindOf("Key") then		 
				    has = true
                 end				
			   end	
		   if use.card and use.card:isKindOf("Slash") and use.from ~= nil and player == use.from and player:hasShownSkill(self:objectName()) and has then
			for _,p in sgs.qlist(use.to) do
				room:setPlayerMark(p, "Armor_Nullified", p:getMark("Armor_Nullified")+1)
				room:setPlayerMark(p, "qiangdou_null", 1)
			end
		   end
		end
        if event == sgs.CardFinished then
			local use = data:toCardUse()
			for _,p in sgs.qlist(use.to) do
				if p:getMark("qiangdou_null")>0 then
				  room:setPlayerMark(p, "Armor_Nullified", p:getMark("Armor_Nullified")-1)
				  room:setPlayerMark(p, "qiangdou_null", 0)
				end
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
	    if event == sgs.ConfirmDamage then
			local has
			if not player then return "" end
			   local list = player:getJudgingArea()
				   for _, i in sgs.qlist(list) do
					 if  i:isKindOf("Key") then		 
						has = true
					 end				
				   end	
			if player:isAlive() and player:hasSkill(self:objectName()) and has then
				return self:objectName()
			end
		end
	end,
	on_cost = function(self, event, room, player, data, sp)
        if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
           room:broadcastSkillInvoke(self:objectName(), player)
		   return true
		end
	end,
	on_effect = function(self, event, room, player, data) 
		local list=player:getJudgingArea()
		local ids = sgs.IntList()
		local has
		for _, i in sgs.qlist(list) do
		  if  i:isKindOf("Key") then 
		     has = true
			 ids:append(i:getEffectiveId())
		  end				 
	    end	
		if has then
			player:drawCards(1)
			if ids:length()>0 then
				room:fillAG(ids, player)
			    local id = room:askForAG(player, ids, false, self:objectName())
			    room:clearAG(player)			  
		        room:throwCard(id,player,player)
			end
		end
	end,
}	

Qiangdoujuli = sgs.CreateTargetModSkill{
	name = "#qiangdoujuli",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player:hasShownSkill("qiangdou") then
			local list=player:getJudgingArea()
			 for _, i in sgs.qlist(list) do
				 if  i:isKindOf("Key") then         	   
				 return 9999
				 end
			 end	
		end
		return 0		
	end ,
}

QiangjiCard = sgs.CreateSkillCard{
   name = "QiangjiCard",
   filter = function(self, targets, to_select, Self)
	 return #targets == 0 and to_select ~= Self and not to_select:isKongcheng()
   end,
   extra_cost = function(self, room, use)
	local pd = sgs.PindianStruct()
	pd = use.from:pindianSelect(use.to:first(), "qiangji")
	local d = sgs.QVariant()
	d:setValue(pd)
	use.from:setTag("qiangjipindian", d)
   end,
   on_use=function(self,room,player,targets)	
	local pd = player:getTag("qiangjipindian"):toPindian()
	player:removeTag("qiangjipindian")
	if pd then
		local win = player:pindian(pd)
		local cards1 = sgs.Sanguosha:getCard(pd.from_card:getEffectiveId())
        local cards2 = sgs.Sanguosha:getCard(pd.to_card:getEffectiveId())
		local winner
		local key
		local ob
		if win then
           winner = player 
		   key = cards1
		   ob = cards2
		else
           winner = targets[1]
		   key = cards2
		   ob = cards1
		end
		local has
        local list = winner:getJudgingArea()
               for _, i in sgs.qlist(list) do
                 if  i:isKindOf("Key") then		 
				    has = true
                 end				
			   end	
		if not has then
			local newkey = sgs.Sanguosha:cloneCard("keyCard")
			local wrapped = sgs.Sanguosha:getWrappedCard(key:getEffectiveId())
			wrapped:takeOver(newkey)
			wrapped:setSkillName("qiangji")
			room:moveCardTo(wrapped, winner, winner, sgs.Player_PlaceDelayedTrick,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
			winner:objectName(), "qiangji", ""))
			room:obtainCard(winner, ob)
		end
	end
   end,
}

Qiangji=sgs.CreateZeroCardViewAsSkill{
	name="qiangji",
	relate_to_place = "head",
	view_as = function(self)
		local card = QiangjiCard:clone()
		card:setShowSkill(self:objectName())
		return card
	end,
	enabled_at_play=function(self,player)
		return not player:isKongcheng() and not player:hasUsed("ViewAsSkill_"..self:objectName().."Card")
	end,
}

Jiaoti = sgs.CreateViewAsSkill{
	n = 1,
	name="jiaoti",
	relate_to_place = "deputy",
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and #selected == 0
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = sgs.Sanguosha:cloneCard("keyCard")
		card:addSubcard(cards[1])
		card:setShowSkill(self:objectName())
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play=function(self,player)
		return not player:isKongcheng() and not player:hasUsed("ViewAsSkill_"..self:objectName().."Card")
	end,
}

Jt_tri = sgs.CreateTriggerSkill{
	name = "#jt_tri",
	events = {sgs.CardFinished},
	on_record = function(self, event, room, player, data)  
		local use = data:toCardUse()
		if	use.card:getSkillName() == "jiaoti" then
		   local dest = use.to:at(0)
           if dest:objectName() ~= player:objectName() and dest:isFriendWith(player) then
              if room:askForChoice(dest, "jiaoti", "jiaoti_ex+cancel", data) == "jiaoti_ex" then
                  dest:showGeneral(false)
				  player:showGeneral(false)
				  local g1 = dest:getActualGeneral2Name()
				  local g2 = player:getActualGeneral2Name()
				  room:exchangeDeputyGeneralTo(dest, g2)
				  room:exchangeDeputyGeneralTo(player, g1)
			  end
		   end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return "" 
	end,
}

TianziVS=sgs.CreateZeroCardViewAsSkill{
	name="tianzi",
	view_as = function(self)
		local card = TianziCard:clone()
		card:setShowSkill(self:objectName())
		return card
	end,
	enabled_at_play=function(self,player)
		return not player:hasUsed("ViewAsSkill_"..self:objectName().."Card")
	end,
}

Tianzi = sgs.CreateTriggerSkill{
	name = "tianzi",
	events = {sgs.DrawNCards, sgs.EventPhaseEnd, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
	view_as_skill = TianziVS,
	can_preshow = true,
	on_record = function(self, event, room, player, data)  
		if (event == sgs.EventPhaseChanging) then
            local change = data:toPhaseChange()
            if (player ~= nil and change.to == sgs.Player_NotActive) then
                if (player:getMark("@tianzi_draw") > 0) then
                    room:setPlayerMark(player, "@tianzi_draw", 0)
				end	
                if (player:getMark("tianzidiscards") > 0) then
                    room:setPlayerMark(player, "tianzidiscards", 0)
				end
			end
        elseif (event == sgs.CardsMoveOneTime) then
            local move = data:toMoveOneTime()
            if (move.from ~= nil and player:objectName() == move.from:objectName() and player:getMark("@tianzi_draw") > 0 and player:getPhase() == sgs.Player_Discard
                and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and move.to_place == sgs.Player_PlaceTable))
            then
                for _,id in sgs.qlist(move.card_ids) do
                    if (sgs.Sanguosha:getEngineCard(id):isKindOf("TrickCard")) then
                        room:setPlayerMark(player, "tianzidiscards", player:getMark("tianzidiscards") + 1)

					end
				end
			end 
		end         
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.DrawNCards and player:hasSkill(self:objectName()) then return self:objectName() end
        if event == sgs.EventPhaseEnd and player:hasSkill(self:objectName()) and player:getMark("tianzidiscards") > 0 and player:getPhase() == sgs.Player_Discard then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
       if event == sgs.DrawNCards and player:askForSkillInvoke(self, data) then
           room:broadcastSkillInvoke(self:objectName(), 1, player)
		   return true
	   end
	   if event == sgs.EventPhaseEnd then
	       room:broadcastSkillInvoke(self:objectName(), 2, player)
		   return true
	   end
	end,
	on_effect = function(self, event, room, player, data)
        if event == sgs.DrawNCards then
             data:setValue(data:toInt()+1)
		end
        if event == sgs.EventPhaseEnd then
            local length = player:getMark("tianzidiscards")
            if (length > 0) then
                room:drawCards(player, length, self:objectName())
                room:setPlayerMark(player, "tianzidiscards", 0)
			end
		end
	end
}

TianziCard = sgs.CreateSkillCard{
   target_fixed = true,
   name = "TianziCard",
   on_use=function(self,room,player,targets)
	 room:setPlayerMark(player, "@tianzi_draw", 1)  
   end,
}

TianziMaxCards = sgs.CreateMaxCardsSkill{
	name = "#tianzi-maxcard",
	extra_func = function(self, player)
		if player:hasShownSkill("tianzi") then
           return -player:getMark("@tianzi_draw")
		end
		return 0
	end,
}

Yuzhai = sgs.CreateTriggerSkill{
	name = "yuzhai",
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)  
		if (event == sgs.EventPhaseChanging) then
            local change = data:toPhaseChange()
            if (player ~= nil and change.to == sgs.Player_NotActive) then
				room:setPlayerMark(player, "yuzhai_cards", 0)
                room:setPlayerMark(player, "@yuzhai_cards", 0)
			end
        elseif (event == sgs.CardsMoveOneTime) then
            local move = data:toMoveOneTime()
            if (move.from ~= nil and player:objectName() == move.from:objectName() and player:getPhase() ~= sgs.Player_NotActive
                and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and move.to_place == sgs.Player_PlaceTable))
            then
                room:setPlayerMark(player, "yuzhai_cards", player:getMark("yuzhai_cards") + move.card_ids:length())
                if player:hasShownSkill(self) then
                    room:setPlayerMark(player, "@yuzhai_cards", player:getMark("yuzhai_cards"))
				end
			end 
		end         
	end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getMark("yuzhai_cards") > player:getHp() and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
		local x = player:getMark("yuzhai_cards") - player:getHp()
		x = math.min(x,3)
		room:setPlayerMark(player, "yuzhai_cards", 0)
        room:setPlayerMark(player, "@yuzhai_cards", 0)
		for i = 1, x, 1 do
            local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yuzhai-invoke", true, true)
			if target and player:canDiscard(target, "he") and not target:isNude() then
                local id = room:askForCardChosen(player, target ,"he", self:objectName())
				room:throwCard(id, target, player)
			end
		end
	end
}

ZhuoguiCard = sgs.CreateSkillCard{
	name = "ZhuoguiCard",
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
         return #targets < self:getSubcards():length() and sgs.Self:objectName() ~= to_select:objectName()
	end,
	feasible = function(self, targets)
		return #targets == self:getSubcards():length()
	end,
    on_use = function(self, room, player, targets)
        local card = sgs.Sanguosha:cloneCard("fire_slash")
       card:setSkillName("zhuogui")
	   for _,i in sgs.qlist(self:getSubcards()) do
         card:addSubcard(i)
	   end
	   local use = sgs.CardUseStruct()
	   use.card = card
	   use.from = player
	   for _,p in ipairs(targets) do
		use.to:append(p)
	   end
	   room:doLightbox("se_jiangui$", 1500)
       room:useCard(use, false)
	end,
}

Zhuoguivs = sgs.CreateViewAsSkill{
	name = "zhuogui",
	--mute = true,
	view_filter=function(self,selected,to_select)
		return not to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		local vs = ZhuoguiCard:clone()
		if #cards == 0 then return nil end
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])                
        end  
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_zhuoguiCard")
	end,
}

Zhuogui = sgs.CreateTriggerSkill{
	name = "zhuogui",
	view_as_skill = Zhuoguivs,
	events = {sgs.Damage},
	on_record = function(self, event, room, player, data)
		local damage = data:toDamage()
		if damage.card ~= nil and damage.card:getSkillName() == self:objectName() and player:isAlive() then
            local choices = "zhuogui_draw+cancel"
			if damage.to:isAlive() and not damage.to:isNude() then choices = "zhuogui_draw+zhuogui_discard+cancel" end
			local choice = room:askForChoice(player, self:objectName(), choices, data)
			if choice == "zhuogui_draw" then player:drawCards(1)
			else
			 local id = room:askForCardChosen(player, damage.to, "he", self:objectName())
			 room:throwCard(id, damage.to, player)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

Tongyu = sgs.CreateTriggerSkill{
	name = "tongyu",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) and room:askForCard(player, ".|.|.|hand", "@tongyu-discard", data, self:objectName()) then
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
		local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 1, 2, "@tongyu")
		room:broadcastSkillInvoke(self:objectName(), player)
		for _,p in sgs.qlist(targets) do
            if not room:askForUseSlashTo(p, room:getAlivePlayers(), "@tongyu-slash", true) then p:drawCards(1) end
		end
	end,
}

Bingshuvs = sgs.CreateViewAsSkill{
	name = "bingshu",
	view_filter=function(self,selected,to_select)
		return to_select:isKindOf("BasicCard") and to_select:isBlack() and #selected == 0
	end,
	view_as = function(self, cards)
		local vs = sgs.Sanguosha:cloneCard("ice_slash")
		if #cards == 0 then return nil end
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])                
        end  
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}

Bingshu = sgs.CreateTriggerSkill{
	name = "bingshu",
	view_as_skill = Bingshuvs,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_record = function(self, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() and not room:getCurrent():hasFlag(player:objectName().."bingshu") then
	            room:setPlayerFlag(room:getCurrent(), player:objectName().."bingshu")
				player:drawCards(1)
			end
		end
		if event == sgs.CardResponded then
			local card = data:toCardResponse().m_card
			if card:getSkillName() == self:objectName() and not room:getCurrent():hasFlag(player:objectName().."bingshu") then
	            room:setPlayerFlag(room:getCurrent(), player:objectName().."bingshu")
				player:drawCards(1)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

BingshuMod = sgs.CreateTargetModSkill{
	name = "#bs-mod",
	pattern = "Slash",
	extra_target_func = function(self, player, card)
		if card:getSkillName() == "bingshu" then
			return 1
		end
		return 0
	end,
	distance_limit_func = function(self, player, card)
		if card:getSkillName() == "bingshu" then
			return 999
		end
		return 0
	end,
}

Lingshi = sgs.CreateTriggerSkill{
	name = "lingshi",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Start then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,p in sgs.qlist(players) do
                if (p == player and p:isWounded()) or (p ~= player and player:isWounded() and not p:isKongcheng()) then
					return self:objectName(), p
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		if sp == player and sp:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), sp)
			return true
		end
		if sp ~= player and sp:askForSkillInvoke(self, data) then
			local card = room:askForCard(sp, "BasicCard|red|.|.", "@lingshi", data, sgs.Card_MethodNone)
			if card then
				room:setPlayerProperty(sp, "lingshi_card", sgs.QVariant(card:getEffectiveId()))
				room:broadcastSkillInvoke(self:objectName(), sp)
			    return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
        if sp == player then
			local list = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("BasicCard") then list:append(id) end
			end
			for _,id in sgs.qlist(room:getDiscardPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("BasicCard") then list:append(id) end
			end
			if not list:isEmpty() then room:obtainCard(sp, list:at(math.random(0, list:length()-1))) end
		end
		if sp ~= player then
            local id = sp:property("lingshi_card"):toInt()
			room:obtainCard(player, id)
            local recover = sgs.RecoverStruct()
		    recover.who = sp
		    room:recover(player, recover, true)
		end
	end,
}

Bingfeng = sgs.CreateTriggerSkill{
    name = "bingfeng",
	events = {sgs.Death},
	frequency = sgs.Skill_Limited,
	limit_mark = "@bingfeng",
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Death then
			local death = data:toDeath()
	        local killer = death.damage and death.damage.from or nil
			if player:isAlive() and player:hasSkill(self:objectName()) and player ~= death.who and player:isFriendWith(death.who) and player:getMark("@bingfeng")>0 and killer ~= nil and killer ~= player then
                return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:askForSkillInvoke(self, data) then
			player:loseMark("@bingfeng")
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
		local death = data:toDeath()
		local killer = death.damage.from
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if killer:distanceTo(p)<=1 then targets:append(p) end
		end
		room:sortByActionOrder(targets)
		for _,p in sgs.qlist(targets) do
			local damage = sgs.DamageStruct()
            damage.from = player
            damage.to = p
			damage.nature = sgs.DamageStruct_Ice
            room:damage(damage)
		end
		killer:turnOver()
		player:turnOver()
	end ,
}

ShunshanCard = sgs.CreateSkillCard{
	name = "ShunshanCard",
	filter = function(self, targets, to_select) --必须
		if #targets < 1 and sgs.Self:distanceTo(to_select) <= 1 then
			return not to_select:isNude() or to_select:getJudgingArea():length() > 0
		end
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		if target:isNude() and target:getJudgingArea():length() == 0 then return end
		local id = room:askForCardChosen(player, target, "hej", self:objectName())
        local card = sgs.Sanguosha:getCard(id)
		local place = room:getCardPlace(id)
		local equip_index = -1
		if place == sgs.Player_PlaceEquip then
			local equip = card:getRealCard():toEquipCard()
			equip_index = equip:location()
		end
		local tos = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(target)) do
			if equip_index ~= -1 then
				if not p:getEquip(equip_index) then
					tos:append(p)
				end
			elseif place == sgs.Player_PlaceHand then 
				tos:append(p)
			else
				if not player:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
					tos:append(p)
				end
			end
		end
		if tos:isEmpty() then return end
		local tag = sgs.QVariant()
		tag:setValue(from)
		room:setTag("shunshanTarget", tag)
		local to = room:askForPlayerChosen(player, tos, self:objectName(), "shunshan_to")
		if to then
			local reason = sgs.CardMoveReason(0x09, player:objectName(), self:objectName(), "")
			room:moveCardTo(card, from, to, place, reason)
			if to ~= player then
                room:askForUseSlashTo(to, room:getAlivePlayers(), "@shunshan-slash", true)
			end
		end
		room:removeTag("shunshanTarget")
	end,
}

Shunshan = sgs.CreateViewAsSkill{
	name = "shunshan",
	view_filter=function(self,selected,to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		local vs = ShunshanCard:clone()
		if #cards == 0 then return nil end
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])                
        end  
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_shunshanCard")
	end,
}

Dingshen = sgs.CreateTriggerSkill{
	name = "dingshen",
	events = {sgs.DamageCaused, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
               room:setPlayerMark(player, "@Stop", 0)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event ~= sgs.DamageCaused then return "" end
		local damage = data:toDamage()
		if player:hasSkill(self:objectName()) and damage.to ~= player and not damage.chain then return self:objectName() end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
        local damage = data:toDamage()
		damage.to:gainMark("@Stop")
	end,
}

DingshenKeep = sgs.CreateMaxCardsSkill{
	name = "#dingshen-keep",
	extra_func = function(self, target)
		if target:getMark("@Stop") > 0 then
			local stops = target:getMark("@Stop")
			if stops > target:getMaxHp() then
				return -target:getMaxHp()
			end
			return -stops
		end
	end
}

DingshenStopped = sgs.CreateDistanceSkill{
	name = "#dingshen-stopped",
	correct_func = function(self, from, to)
		if to:getMark("@Stop") > 0 and from:objectName()~=to:objectName() and from:hasShownSkill("dingshen") then
			return -999
		end
		if from:getMark("@Stop") > 0 and from:objectName()~=to:objectName() then
			return from:getMark("@Stop")
		end
	end
}

Shiyu = sgs.CreateTriggerSkill{
    name = "shiyu",
	events = {sgs.EventPhaseStart, sgs.Damage, sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_record = function(self, event, room, player, data)
		if event == sgs.Damage then
			local damage = data:toDamage()
			if player:getPhase() ~= sgs.Player_NotActive then
                 room:setPlayerMark(player, "shiyu_num", player:getMark("shiyu_num") + damage.damage)
			end
		end
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
                room:setPlayerMark(player, "shiyu_num", 0)
			end
		end
	end,    
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
                return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
        local x = player:getMark("shiyu_num")
		if x == 0 then
			room:loseHp(player)
		elseif x == 1 then
			player:drawCards(1)
		elseif x >= 2 then
			local choices = "shiyu_draw"
			if player:isWounded() then choices = "shiyu_draw+shiyu_recover" end
			local choice = room:askForChoice(player, self:objectName(), choices, data)
			if choice == "shiyu_draw" then player:drawCards(2) end
			if choice == "shiyu_recover" then
                local recover = sgs.RecoverStruct()
		        recover.who = player
		        room:recover(player, recover, true)
			end
        end
	end ,
}

Banhe = sgs.CreateTriggerSkill{
	name = "banhe",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Start then
			if player:hasSkill(self:objectName()) and player:isWounded() then
                return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		if sp:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), sp)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
		local list = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("EquipCard") then list:append(id) end
			end
			for _,id in sgs.qlist(room:getDiscardPile()) do
				local c = sgs.Sanguosha:getCard(id)
				if c:isKindOf("EquipCard") then list:append(id) end
			end
			if not list:isEmpty() then room:obtainCard(sp, list:at(math.random(0, list:length()-1))) end	
	end,
}

HuanyuanCard = sgs.CreateSkillCard{
	name="HuanyuanCard",
	will_throw = true,
	filter = function(self, selected, to_select)
		return #selected < 1
	end,
	on_use = function(self,room,source,targets)
		local choice = room:askForChoice(source, "huanyuan", "huanyuan_Draw+huanyuan_Hp")
		--room:broadcastSkillInvoke("se_huanyuan")
		room:doLightbox("se_huanyuan$", 1000)
		room:setEmotion(targets[1], "skills/huanyuan")
		if choice == "huanyuan_Draw" then
			local card_num = targets[1]:getTag("huanyuan_Pre_Handcards"..source:objectName()):toInt()
			if card_num - targets[1]:getHandcardNum() > 0 then
				targets[1]:drawCards(math.min(card_num - targets[1]:getHandcardNum(), 5))
			elseif card_num - targets[1]:getHandcardNum() < 0 then
				room:askForDiscard(targets[1], self:objectName(), targets[1]:getHandcardNum() - card_num, targets[1]:getHandcardNum() - card_num, false, false)
			end
		else
			if targets[1]:getMaxHp() ~= targets[1]:getTag("huanyuan_Pre_MaxHp"..source:objectName()):toInt() then room:setPlayerProperty(targets[1], "maxhp", targets[1]:getTag("huanyuan_Pre_MaxHp"..source:objectName())) end
			if targets[1]:getHp() ~= targets[1]:getTag("huanyuan_Pre_Hp"..source:objectName()):toInt() then room:setPlayerProperty(targets[1], "hp", targets[1]:getTag("huanyuan_Pre_Hp"..source:objectName())) end
		end
	end
}

Huanyuanvs = sgs.CreateViewAsSkill{
	name = "huanyuan",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected < 1 and to_select:isKindOf("BasicCard")
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local card = HuanyuanCard:clone()
			card:setSkillName(self:objectName())
			card:addSubcard(cards[1])
			card:setShowSkill(self:objectName())
			return card
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#HuanyuanCard") and not player:isKongcheng()
	end,
}

Huanyuan = sgs.CreateTriggerSkill{
	name = "huanyuan",
	view_as_skill = Huanyuanvs,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd, sgs.TurnStart},
	on_record = function(self, event, room, player, data)
		if (event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish) or event == sgs.TurnStart then
			for _,p in sgs.qlist(room:getAlivePlayers()) do				
				if event == sgs.TurnStart then
					for _,q in sgs.qlist(room:getAlivePlayers()) do
					    if p:getMark("huanyuan_record"..q:objectName()) == 0 then
							room:setPlayerMark(p, "huanyuan_record"..q:objectName(), 1)
							p:setTag("huanyuan_Pre_Hp"..q:objectName(), sgs.QVariant(p:getHp()))
							p:setTag("huanyuan_Pre_MaxHp"..q:objectName(), sgs.QVariant(p:getMaxHp()))
							p:setTag("huanyuan_Pre_Handcards"..q:objectName(), sgs.QVariant(4))
						end
					end
					if p:getMark("chengling_record") == 0 then
						room:setPlayerMark(p, "chengling_record", 1)
						p:setTag("chengling_head", sgs.QVariant(p:getActualGeneral1Name()))
						p:setTag("chengling_deputy", sgs.QVariant(p:getActualGeneral2Name()))
					end
				else
					p:setTag("huanyuan_Pre_Hp"..player:objectName(), sgs.QVariant(p:getHp()))
				    p:setTag("huanyuan_Pre_MaxHp"..player:objectName(), sgs.QVariant(p:getMaxHp()))
					p:setTag("huanyuan_Pre_Handcards"..player:objectName(), sgs.QVariant(p:getHandcardNum()))
				end
			end
		end
		return false
	end,    
	can_trigger = function(self, event, room, player, data)
		return ""
	end,
}

ChenglingCard = sgs.CreateSkillCard{
	name = "ChenglingCard",
	filter = function(self, targets, to_select)
		return #targets < 2 and to_select:objectName() ~= sgs.Self:objectName() and to_select:hasShownAllGenerals()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		source:loseMark("@LimeBell")
		room:doLightbox("se_chengling$", 3000)

        for _,p in ipairs(targets) do
            local g1 = p:getTag("chengling_head"):toString()
			local g2 = p:getTag("chengling_deputy"):toString()
            if sgs.Sanguosha:getGeneral(g1) and g1 ~= p:getActualGeneral1Name() and not table.contains(getUsedGeneral(room), g1) then
				p:showGeneral()
                room:transformHeadGeneralTo(p, g1)
			end
			if sgs.Sanguosha:getGeneral(g2) and g2 ~= p:getActualGeneral1Name() and not table.contains(getUsedGeneral(room), g2) then
				p:showGeneral(false)
                room:transformDeputyGeneralTo(p, g2)
			end
            for _,s in sgs.qlist(p:getActualGeneral1():getVisibleSkillList()) do
                if not p:hasSkill(s:objectName()) and not s:relateToPlace(false) then
					room:acquireSkill(p, s:objectName(), true)
				end
				if s:getFrequency() == sgs.Skill_Limited then
                    if p:getMark(s:getLimitMark()) == 0 then
						room:setPlayerMark(p, s:getLimitMark(), 1)
					end
				end
			end
			for _,s in sgs.qlist(p:getActualGeneral2():getVisibleSkillList()) do
				if not p:hasSkill(s:objectName()) and not s:relateToPlace(true) then
					room:acquireSkill(p, s:objectName(), false)
				end
				if s:getFrequency() == sgs.Skill_Limited then
                    if p:getMark(s:getLimitMark()) == 0 then
						room:setPlayerMark(p, s:getLimitMark(), 1)
					end
				end
			end
			local maxhp = -1
			local a = -1
			local b = -1
			if p:getActualGeneral1() and not string.find(p:getActualGeneral1Name(), "sujiang") then a = p:getActualGeneral1():getMaxHpHead() end
			if p:getActualGeneral2() and not string.find(p:getActualGeneral2Name(), "sujiang") then b = p:getActualGeneral2():getMaxHpDeputy() end

			if a>-1 and b>-1 then
				maxhp = math.floor((a+b)/2) 
			elseif a>-1 then
				maxhp = a
			elseif b>-1 then
				maxhp = b
			end
            
			if maxhp > -1 then
				if p:getMaxHp()~=maxhp then room:setPlayerProperty(p, "maxhp", sgs.QVariant(maxhp)) end
		        if p:getHp()~=maxhp then room:setPlayerProperty(p, "hp", sgs.QVariant(maxhp)) end
			end
		end

	end
}

Chengling=sgs.CreateZeroCardViewAsSkill{
	name="chengling",
	limit_mark = "@LimeBell",
	view_as = function(self)
		local vs = ChenglingCard:clone()
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@LimeBell") > 0
	end,
}

Huanqivs = sgs.CreateZeroCardViewAsSkill{
	name = "huanqi",
	view_as = function(self)
		local vs = sgs.Sanguosha:cloneCard("slash")
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and player:getMark("huanqi_used") == 0
	end,
	enabled_at_play = function(self, player)
        return player:getMark("huanqi_used") == 0
	end
}

Huanqi = sgs.CreateTriggerSkill{
	name = "huanqi",
	view_as_skill = Huanqivs,
	relate_to_place = "head",
	events = {sgs.PreCardUsed, sgs.CardResponded, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		--[[if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() then
				room:setPlayerMark(player, "huanqi_used", 1)
				player:showGeneral(false)
				room:transformDeputyGeneral(player)
			end
		end]]
		if event == sgs.CardResponded then
			local card = data:toCardResponse().m_card
			if card:getSkillName() == self:objectName() then
				room:setPlayerMark(player, "huanqi_used", 1)
				player:showGeneral(false)
				room:transformDeputyGeneral(player)
			end
		end
		if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
               for _,p in sgs.qlist(room:getAlivePlayers()) do
                  room:setPlayerMark(p, "huanqi_used", 0)
			   end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

RwurenCard = sgs.CreateSkillCard{
	name = "RwurenCard",
	filter = function(self, targets, to_select) --必须
		if #targets < 1 then
			return true
		end
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if source:isKongcheng() then return end
		local id = room:askForCardChosen(target, source, "h", "rwuren")
		room:showCard(source, id)
		local c = sgs.Sanguosha:getCard(id)
		if c:isKindOf("Slash") then
		   local slash = sgs.Sanguosha:cloneCard("slash")
		   slash:setSkillName("rwuren")
           local use = sgs.CardUseStruct()
		   use.from = source
		   use.to:append(target)
		   use.card = slash
		   room:useCard(use, false)
		end
	end,
}

Rwuren = sgs.CreateZeroCardViewAsSkill{
	name = "rwuren",
	relate_to_place = "deputy",
	view_as = function(self)
	    local vs = RwurenCard:clone()
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_rwurenCard")
	end,
}

Jueye = sgs.CreateTriggerSkill{
	name = "jueye",
	events = {sgs.CardUsed},
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
        if player:hasSkill(self:objectName()) and use.card:isKindOf("Slash") and use.card:getSubcards():length() == 0 and not player:isKongcheng() then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) and room:askForCard(player, "Slash|.|.|hand", "@jueye-discard", data, self:objectName()) then
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local list = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		   if not use.to:contains(p) then list:append(p) end
		end
		local targets = room:askForPlayersChosen(player, list, self:objectName(), 0, 2, "@jueye")
		if not targets:isEmpty() then
		   room:broadcastSkillInvoke(self:objectName(), player)
		   for _,p in sgs.qlist(targets) do
			 if not use.to:contains(p) then use.to:append(p) end
		   end
		   data:setValue(use)
		end
	end,
}

YoudizCard = sgs.CreateSkillCard{
	name = "YoudizCard",
	filter = function(self, targets, to_select) 
		if #targets <1 and sgs.Self:objectName() ~= to_select:objectName() then
			return true
		end
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		if #targets > 0 then
            local target = targets[1]
			room:askForUseSlashTo(target, source, "@youdiz-slash:"..source:objectName(), false)
			if source:getHp() >= target:getHp() then
                if not target:isRemoved() then
					room:setPlayerCardLimitation(target, "use", ".", false)
					room:setPlayerProperty(target, "removed", sgs.QVariant(true))
				end
				if not target:isFriendWith(source) then source:drawCards(1) end
			end
		end
	end,
}

Youdizvs = sgs.CreateZeroCardViewAsSkill{
	name = "youdiz",
	--[[view_filter=function(self,selected,to_select)
		return #selected == 0 and to_select:isKindOf("EquipCard")
	end,]]
	view_as = function(self)
		local new_card = YoudizCard:clone()
		--[[for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end]]      
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player,pattern)
		return not player:hasUsed("ViewAsSkill_youdizCard")
	end,
}

YoudizMod = sgs.CreateTargetModSkill{
	name = "#youdiz-mod",
	pattern = "LureTiger",
	extra_target_func = function(self, player, card)
		if player:hasShownSkill("youdiz") then
			return 1
		end
		return 0
	end,
}

Youdiz = sgs.CreateTriggerSkill{
	name = "youdiz",
	view_as_skill = Youdizvs,
	events = {sgs.CardUsed, sgs.CardResponded},
	on_record = function(self, event, room, player, data)
		--[[if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("LureTiger") and player:hasShownSkill(self:objectName()) then
				player:drawCards(1)
			end
		end]]
	end,
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

EryuSummon = sgs.CreateArraySummonCard{
	name = "eryu",
}

Eryuvs = sgs.CreateArraySummonSkill{
	name = "eryu",
	array_summon_card = EryuSummon,
}

Eryu = sgs.CreateTriggerSkill{
	name = "eryu",
	is_battle_array = true,
    view_as_skill = Eryuvs,
	battle_array_type = 0,
	can_preshow = true,
	events = {sgs.TargetConfirmed, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(player, "eryu_times"..p:objectName(), 0)
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
			if not use.card:isNDTrick() and not use.card:isKindOf("BasicCard") then return "" end
			if room:getAlivePlayers():length()>=4 and player:isAlive() and player:hasSkill(self:objectName()) and room:getCurrent():getMark("eryu_times"..player:objectName()) < 3 then
				local targets = {}
                for _,p in sgs.qlist(use.to) do
					if player:inSiegeRelation(use.from, p) then
						if player == use.from then
					       if player:getNextAlive():objectName() == p:objectName() then
							 if not table.contains(targets, p:getNextAlive():objectName()) then table.insert(targets, p:getNextAlive():objectName()) end
						   else
							if not table.contains(targets, p:getLastAlive():objectName()) then  table.insert(targets, p:getLastAlive():objectName()) end
						   end
					    else
							if not table.contains(targets, player:objectName()) then table.insert(targets, player:objectName()) end
						end
					end
				end
				if #targets > 0 then
					return self:objectName().."->"..table.concat(targets, "+")
				else
					return ""
				end
			end
		end
	end ,
    on_cost = function(self, event, room, target, data, player)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
			local use = data:toCardUse()
			local from = use.from
			local to = target
			local middle
			for _,p in sgs.qlist(use.to) do
				if from:inSiegeRelation(to, p) then
					middle = p
					break
				end
			end
			if from == player then
				if not player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
				  room:setPlayerMark(room:getCurrent(), "eryu_times"..player:objectName(),room:getCurrent():getMark("eryu_times"..player:objectName())+1)
				  room:doBattleArrayAnimate(from, middle)
				  room:broadcastSkillInvoke(self:objectName(), player)
				  return true
				end
			end
			if to == player then
                if from:askForSkillInvoke(self, data) then
					room:setPlayerMark(room:getCurrent(), "eryu_times"..player:objectName(),room:getCurrent():getMark("eryu_times"..player:objectName())+1)
					room:doBattleArrayAnimate(from, middle)
					room:broadcastSkillInvoke(self:objectName(), player)
				    return true
				end
			end
		end
	end,
	on_effect = function(self, event, room, target, data, player)
        local use = data:toCardUse()
		room:obtainCard(target, use.card)
	end,
}

HuanxiCard = sgs.CreateSkillCard{
	name = "HuanxiCard",
    target_fixed = true,
	on_use = function(self, room, source, targets)
		local choices = {"huanxi_basic","huanxi_equip","huanxi_hp"}
		local success = false
		local choice = room:askForChoice(source, "huanxi", table.concat(choices, "+"))
		if choice == "huanxi_hp" then room:loseHp(source) end
		if choice == "huanxi_basic" then
			local card = room:askForCard(source, "BasicCard", "@huanxi-basic")
			if not card then
				choice = "huanxi_hp"
				room:loseHp(source)
			end
		elseif choice == "huanxi_equip" then
			local card = room:askForCard(source, "EquipCard", "@huanxi-equip")
			if not card then
				choice = "huanxi_hp"
				room:loseHp(source)
			end
		end
		table.removeOne(choices, choice)
		local list = room:getOtherPlayers(source)
		local target = room:askForPlayerChosen(source, list, "huanxi", "", false, true)
		choice = room:askForChoice(target, "huanxi", table.concat(choices, "+"))
        if choice == "huanxi_hp" then room:loseHp(target) end
		if choice == "huanxi_basic" then
			local card = room:askForCard(target, "BasicCard", "@huanxitarget-basic")
			if not card then
				room:setPlayerFlag(source, "huanxi"..target:objectName())
				room:setPlayerMark(target, "huanxi_effect", 1)
				room:setPlayerCardLimitation(target, "use, response", ".|.|.|.", false)
				target:setTag("CannotRecover", sgs.QVariant(true))
			end
		elseif choice == "huanxi_equip" then
			local card = room:askForCard(target, "EquipCard", "@huanxitarget-equip")
			if not card then
				room:setPlayerFlag(source, "huanxi"..target:objectName())
				room:setPlayerMark(target, "huanxi_effect", 1)
				room:setPlayerCardLimitation(target, "use, response", ".|.|.|.", false)
				target:setTag("CannotRecover", sgs.QVariant(true))
			end
		end
		table.removeOne(choices, choice)
		list = room:getOtherPlayers(source)
        if list:contains(target) then list:removeOne(target) end
		if list:length()>0 and source:getHp()<= source:getMaxHp()/2 and source:hasShownSkill("jjueying") then
			target = room:askForPlayerChosen(source, list, "huanxi", "", true, true)
			if not target then return end
		    choice = room:askForChoice(target, "huanxi", table.concat(choices, "+"))
            if choice == "huanxi_hp" then room:loseHp(target) end
		    if choice == "huanxi_basic" then
			  local card = room:askForCard(target, "BasicCard", "@huanxitarget-basic")
			  if not card then
				room:setPlayerFlag(source, "huanxi"..target:objectName())
				room:setPlayerMark(target, "huanxi_effect", 1)
				room:setPlayerCardLimitation(target, "use, response", ".|.|.|.", false)
				target:setTag("CannotRecover", sgs.QVariant(true))
			  end
		    elseif choice == "huanxi_equip" then
			  local card = room:askForCard(target, "EquipCard", "@huanxitarget-equip")
			  if not card then
				room:setPlayerFlag(source, "huanxi"..target:objectName())
				room:setPlayerMark(target, "huanxi_effect", 1)
				room:setPlayerCardLimitation(target, "use, response", ".|.|.|.", false)
				target:setTag("CannotRecover", sgs.QVariant(true))
			  end
			end
		end
	end,
}

Huanxi = sgs.CreateZeroCardViewAsSkill{
	name = "huanxi",
	view_as = function(self)
		local new_card = HuanxiCard:clone()   
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player)
		return not player:hasUsed("ViewAsSkill_huanxiCard")
	end,
}


Huanxidis = sgs.CreateDistanceSkill{
	name = "#huanxidis",
	correct_func = function(self, from, to)
		if from:hasFlag("huanxi"..to:objectName())then
			return -999
		end
	end
}

Huanxieffect = sgs.CreateTriggerSkill{
	name = "huanxieffect",
	global = true,
	events = {sgs.EventPhaseStart},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_NotActive then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("huanxi_effect")>0 then
					room:setPlayerMark(p, "huanxi_effect", 0)
					room:removePlayerCardLimitation(p, "use, response", ".|.|.|.")
					p:setTag("CannotRecover", sgs.QVariant(false))
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
       return ""
	end,
}

Jjueying = sgs.CreateTargetModSkill{
  name = "jjueying",
  residue_func = function(self,player,card)
	if player:hasSkill(self:objectName()) and player:getHp()>player:getMaxHp()/2 and card:getSuit() == sgs.Card_Spade then return 1	end
  end 
}

Moshi = sgs.CreateTriggerSkill{
	name = "moshi",
	events = {sgs.EventPhaseEnd, sgs.TargetConfirmed},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "moshi_times"..player:objectName(), 0)
				end
				room:setPlayerMark(player, "#moshi_dis", 0)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetConfirmed then
		   local use = data:toCardUse()
		   if player:hasSkill(self:objectName()) and player:isAlive() and player == use.from and player:getMark("@neko_shi")>0 and use.card:getTypeId()~=sgs.Card_TypeSkill and use.card:getTypeId()~=sgs.Card_TypeEquip then
               if player:getMark("moshi_times"..room:getCurrent():objectName())>=3 or (use.to:length() == 1 and use.to:at(0) == player) then return "" end
			   return self:objectName()
		   end
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
	    if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:setPlayerMark(player, "moshi_times"..room:getCurrent():objectName(), player:getMark("moshi_times"..room:getCurrent():objectName())+1)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
        local use = data:toCardUse()
		local choices = "1"
		local list = sgs.SPlayerList()
		local list2 = sgs.SPlayerList()
		for _,p in sgs.qlist(use.to) do
           if p ~= player and p:getEquips():length()>0 then list:append(p) end
		   if p ~= player then list2:append(p) end
		end
		if list:length()>0 and player:getMark("@neko_shi")>1 then choices = choices.."+2" end
		if list2:length()>0 and player:getMark("@neko_shi")>2 then choices = choices.."+3" end
		local choice = room:askForChoice(player, self:objectName(), choices, data)
		if choice == "1" then
			player:loseMark("@neko_shi", 1)
			player:drawCards(1)
            room:setPlayerMark(player, "#moshi_dis", player:getMark("#moshi_dis")+1)
		elseif choice == "2" then
			player:loseMark("@neko_shi", 2)
			local target = room:askForPlayerChosen(player, list, self:objectName())
			local id = room:askForCardChosen(player, target, "e", self:objectName())
			room:throwCard(id, target, player)
		elseif choice == "3" then
            player:loseMark("@neko_shi", 3)
			local targets = room:askForPlayersChosen(player, list2, self:objectName(), 1, list2:length())
			for _,p in sgs.qlist(targets) do
               local da = sgs.DamageStruct()
			   da.from = player
			   da.to = p
			   room:damage(da)
			end
		end
	end,
}

Nekojiyi = sgs.CreateTriggerSkill{
	name = "nekojiyi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd, sgs.CardUsed},
    on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				room:setPlayerProperty(player, "nekojiyi_suit", sgs.QVariant())
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId() == sgs.Card_TypeSkill or player:getPhase() == sgs.Player_NotActive then return end
			if use.card:getSuitString() ~= "spade" and use.card:getSuitString() ~= "heart" and use.card:getSuitString() ~= "diamond" and use.card:getSuitString() ~= "club" then return  end
			room:setPlayerProperty(player, "nekojiyi_suit", sgs.QVariant(use.card:getSuitString().."+"..player:property("nekojiyi_suit"):toString()))
		 end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardUsed then
		   local use = data:toCardUse()
		   local list = player:property("nekojiyi_suit"):toString():split("+")
		   local list2 = player:property("nekojiyi_suit"):toString():split("+")
		   table.removeOne(list2, list2[1])
		   if use.card:getTypeId() == sgs.Card_TypeSkill or player:getPhase() == sgs.Player_NotActive then return "" end
		   if use.card:getSuitString() ~= "spade" and use.card:getSuitString() ~= "heart" and use.card:getSuitString() ~= "diamond" and use.card:getSuitString() ~= "club" then return "" end
		   if player:hasSkill(self:objectName()) and player:isAlive() and (#list<=1 or list[1]~=list[2]) and not table.contains(list2, list[1]) then			   
			   return self:objectName()
		   end
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
	    if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
        player:gainMark("@neko_shi")
	end
}

Moshimax = sgs.CreateDistanceSkill{
	name = "#moshimax",
	correct_func = function(self, from, to)
		if from:getMark("#moshi_dis")>0 then
			return -from:getMark("#moshi_dis")
		end
	end
}

VoidCard = sgs.CreateSkillCard{
	name = "VoidCard",
	mute = true,
	filter = function(self, targets, to_select)
	   return (#targets == 0 or (#targets <= 1 and sgs.Self:hasShownSkill("wangguo") and to_select:isFriendWith(sgs.Self)))  and not to_select:isNude() and to_select:objectName() ~= sgs.Self:objectName()
    end,
	about_to_use = function(self, room, use)
	   local shu = use.from

       local log = sgs.LogMessage()
       log.from = shu
       log.to = use.to
       log.type = "#UseCard"
       log.card_str = self:toString()
       room:sendLog(log)

       local data = sgs.QVariant()
	   data:setValue(use)
       local thread = room:getThread()

       thread:trigger(sgs.PreCardUsed, room, shu, data)
       room:broadcastSkillInvoke("void", shu)
       
	   local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_THROW, shu:objectName(), "", "void", "")
	   room:moveCardTo(self, shu, nil, sgs.Player_PlaceTable, reason, true)

       if (shu:ownSkill("void") and not shu:hasShownSkill("void")) then
           shu:showGeneral(shu:inHeadSkills("void"))
	   end
       thread:trigger(sgs.CardUsed, room, shu, data)
       thread:trigger(sgs.CardFinished, room, shu, data)
    end,
	on_use = function(self, room, source, targets)
	    for _,target in ipairs(targets) do
			if target:isNude() then continue end
			local id = room:askForCardChosen(source, target, "he", "void", true)
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("Slash") or card:isKindOf("Weapon") then
                room:setPlayerFlag(source, "void_targetmod")
			end
			room:obtainCard(source, id)
			--room:broadcastSkillInvoke("void", math.random(1, 2)) 
			local names = room:getTag(source:objectName().."voidtarget"):toString():split("+")
			table.insert(names, target:objectName())
			local list = room:getTag(source:objectName().."voidid"):toString():split("+")
			table.insert(list, string.format("%d",id))
			room:setTag(source:objectName().."voidtarget", sgs.QVariant(table.concat(names, "+")))
			room:setTag(source:objectName().."voidid", sgs.QVariant(table.concat(list, "+")))
			--room:setPlayerMark(source,"voidused",source:getMark("voidused")+1)
			room:setTag(source:objectName().."voidbeused"..target:objectName(), sgs.QVariant(true))
			--room:setPlayerMark(target,"@voidbeused",1)
		end
	end,
}

Voidvs = sgs.CreateViewAsSkill{
	name = "void",
	n = 1,
	view_filter=function(self,selected,to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs = VoidCard:clone()
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])                
        end  
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("ViewAsSkill_voidCard")
	end,
}

Void = sgs.CreateTriggerSkill{
    name = "void" ,
	events = {sgs.EventPhaseEnd, sgs.PreCardUsed},
	view_as_skill = Voidvs,
	on_record = function(self, event, room, player, data)  
	  if event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Finish then
	    --room:setPlayerMark(player,"voidused",0)
		--room:setPlayerMark(player,"voidcanuse",0)
		local idlist = room:getTag(player:objectName().."voidid"):toString():split("+")
		local names = room:getTag(player:objectName().."voidtarget"):toString():split("+")
		local names_copy = names

		for _,n in ipairs(names_copy) do
           if n == "" then table.removeOne(names, n)	end		   
 		end
		
		for i=1, #idlist, 1 do
		
		local target
		for _,p in sgs.qlist(room:getAlivePlayers()) do
          if p:objectName()==names[i] then target = p end
        end
		local list = sgs.IntList()
		for _,h in sgs.qlist(player:handCards()) do
		  list:append(h)
		end
		for _,e in sgs.qlist(player:getEquips()) do
		  list:append(e:getEffectiveId())
		end
		if target and (list:contains(tonumber(idlist[i])) or room:getDiscardPile():contains(tonumber(idlist[i]))) then
		  room:obtainCard(target, tonumber(idlist[i]))
		end
		
		end
		
		room:setTag(player:objectName().."voidtarget", sgs.QVariant())
	    room:setTag(player:objectName().."voidid", sgs.QVariant())
	  end
	  if event == sgs.PreCardUsed then
         local use = data:toCardUse()
		 if use.card:isKindOf("Slash") and player:hasFlag("void_targetmod") then
            room:setPlayerFlag(player, "-void_targetmod")
		 end
	  end
	end,
	can_trigger = function(self, event, room, player, data)
		return ""
	end,
}

VoidMod = sgs.CreateTargetModSkill{
	name = "#voidmod",
	distance_limit_func = function(self, target)
		if target:hasFlag("void_targetmod")  then 
			return 1000
		end
		return 0
	end,
	extra_target_func = function(self, target)
		if target:hasFlag("void_targetmod")  then 
			return 1
		end
		return 0
	end
}

Wangguo = sgs.CreateTriggerSkill{
    name = "wangguo" ,
	events = {sgs.TargetChosen},
	relate_to_place = "head",
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetChosen then
			local use = data:toCardUse()
			if use.card:getSkillName() == "void" and player == use.from and player:hasSkill(self:objectName()) and player:isAlive() then
                local targets = {}
				for _,p in sgs.qlist(use.to) do
					if p:isFriendWith(player) then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return self:objectName().."->"..table.concat(targets, "+")
				end
			end
		end
		return ""
	end,
    on_cost = function(self, event, room, target, data, player)
		local da = sgs.QVariant()
		da:setValue(target)
	    if player:askForSkillInvoke(self, da) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, target, data, player)
        if not target or target:isDead() then return false end
		room:loseHp(player)
		local choices = "void_draw"
		if target:isWounded() then choices = "void_draw+void_recover" end
		if target:getJudgingArea():length()>0 then choices = choices.."+void_discard" end
		local da = sgs.QVariant()
		da:setValue(target)
        local choice = room:askForChoice(player, self:objectName(), choices, da)
		if choice == "void_draw" then target:drawCards(2) end
		if choice == "void_recover" then
			local recover = sgs.RecoverStruct()
		    recover.who = player
		    room:recover(target, recover, true)
		end
		if choice == "void_discard" and target:getJudgingArea():length()>0 then
			local id = room:askForCardChosen(player, target, "j", self:objectName())
			room:throwCard(id, target, player)
		end
	end,
}

MaoqunCard = sgs.CreateSkillCard{
	name = "MaoqunCard", 
	mute = true,
	filter = function(self, targets, to_select)
		local suit = self:getSuitString()
		local mark = ""
		if suit == "spade" then mark = "@Neko_S" end
		if suit == "club" then mark = "@Neko_C" end
		if suit == "diamond" then mark = "@Neko_D" end
		if suit == "heart" then mark = "@Neko_H" end
		return (#targets == 0) and to_select:getMark(mark) == 0
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local dest = effect.to
		local room = source:getRoom()
		local suit = self:getSuitString()
		local mark = ""
		if suit == "spade" then mark = "@Neko_S" end
		if suit == "club" then mark = "@Neko_C" end
		if suit == "diamond" then mark = "@Neko_D" end
		if suit == "heart" then mark = "@Neko_H" end
		if mark == "" then return end
		room:broadcastSkillInvoke("maoqun", math.random(5,7), source)
        room:setPlayerMark(dest, mark, 1)
	end
}

Maoqunvs = sgs.CreateOneCardViewAsSkill{
	name = "maoqun",
	expand_pile = "RinNeko",
	filter_pattern = ".|.|.|RinNeko",
	view_as = function(self, card)
		--local new_card = sgs.Sanguosha:cloneCard("igiari")
		local new_card = MaoqunCard:clone()
		new_card:addSubcard(card)
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	--[[enabled_at_play=function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
	    return table.contains(pattern:split("+"), "igiari") and player:getPile("RinNeko"):length()>0
    end,
	enabled_at_igiari = function(self, player)
		return player:getPile("RinNeko"):length()>0
    end,]]
}

Maoqun = sgs.CreateTriggerSkill{
	name = "maoqun",
	events = {sgs.TurnStart, sgs.DamageInflicted, sgs.EventPhaseEnd, sgs.DrawNCards, sgs.PreHpRecover},
	view_as_skill = Maoqunvs,
	can_preshow = true,
    on_record = function(self, event, room, player, data)
		if event == sgs.TurnStart then 
			if player:getMark("maoqun_used")>0 and not player:hasFlag("Point_ExtraTurn") then
				 room:setPlayerMark(player, "maoqun_used", 0)
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then 
			room:setPlayerMark(player, "@Neko_S", 0)
			room:setPlayerMark(player, "@Neko_C", 0)
			room:setPlayerMark(player, "@Neko_D", 0)
			room:setPlayerMark(player, "@Neko_H", 0)
		end
		if event == sgs.DrawNCards and player:getMark("@Neko_S")>0 then
			local n = data:toInt()
			if n > 0 then
				n = n-1
				data:setValue(n)
			end
		end
		if event == sgs.DamageInflicted and player:getMark("@Neko_D")>0 then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal then
				damage.damage = damage.damage+1
			    data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.DamageInflicted then
		   local damage = data:toDamage()
		   local players = room:findPlayersBySkillName(self:objectName())
		   for _,sp in sgs.qlist(players) do
			if not sp:isFriendWith(player) --[[or sp:getMark("maoqun_used")>0]]or sp:getPile("RinNeko"):length()>=room:getAlivePlayers():length()*1.5 then return "" end
			return self:objectName(), sp
		   end		  
		end
		if event == sgs.PreHpRecover then
			if player:getMark("@Neko_H")>0 then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
	    if event == sgs.DamageInflicted and player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), math.random(1,4), player)
			room:setPlayerMark(player, "maoqun_used", 1)
			return true
		end
		if event == sgs.PreHpRecover then
			room:setPlayerMark(player, "@Neko_H", 0)
			return true
		end
	end,
	on_effect = function(self, event, room, target, data, player)
        if event == sgs.DamageInflicted then
			if (room:getDrawPile():length() == 0) then
				room:swapPile()
			end
			player:addToPile("RinNeko", room:getDrawPile():at(0))
		end
		if event == sgs.PreHpRecover then
			return true
		end
	end
}

MaoqunMaxCards = sgs.CreateMaxCardsSkill{
	name = "#maoqun-maxcard",
	extra_func = function(self, player)
		if player:getMark("@Neko_C")>0 then
           return -1
		end
		return 0
	end,
}

Pasheng = sgs.CreateTriggerSkill{
	name = "pasheng",
	events = {sgs.TargetConfirming},
	relate_to_place = "deputy",
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetConfirming then
		   local use = data:toCardUse()
		   if use.to:length()>1 or not use.from or player == use.from then return "" end
		   if player:getJudgingArea():length()==0 and use.from:getJudgingArea():length()==0 then return "" end
		   if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then return "" end
		   if player:hasSkill(self:objectName()) and player:isAlive() then return self:objectName() end  
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
	    if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, target, data, player)
        local list = sgs.SPlayerList()
		local use = data:toCardUse()
		if player:getJudgingArea():length()>0 then list:append(player) end
		if use.from:getJudgingArea():length()>0 then list:append(use.from) end
        if list:length()>0 then 
			local target = room:askForPlayerChosen(player, list, self:objectName())
			local id = room:askForCardChosen(player, target, "j", self:objectName())
			room:throwCard(id, target, player)
			sgs.Room_cancelTarget(use, player)
			data:setValue(use)
		end
	end
}

Rinjiuyuan = sgs.CreateTriggerSkill{
	name = "rinjiuyuan",
	events = {sgs.Dying, sgs.DamageInflicted},
	relate_to_place = "head",
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Dying then
		   local dying = data:toDying()
		   local has
		    for _,c in sgs.qlist(dying.who:getJudgingArea()) do
			  if c:isKindOf("Key") then has = true end
			end
		   if not has and player:hasSkill(self:objectName()) and player:isAlive() then return self:objectName() end  
		end
		if event == sgs.DamageInflicted then
            local damage = data:toDamage()
			local has
			for _,c in sgs.qlist(player:getJudgingArea()) do
				if c:isKindOf("Key") then has = true end
			end
		    local players = room:findPlayersBySkillName(self:objectName())
		    for _,sp in sgs.qlist(players) do
			 if has and damage.damage>= player:getHp() then
			   return self:objectName(), sp
			 end
		    end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
	    if sp:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), sp)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        if event == sgs.Dying then
			room:doLightbox("SE_Zhixing$", 800)
			local dying = data:toDying()
			if (room:getDrawPile():length() == 0) then
				room:swapPile()
			end
            local id =  room:getDrawPile():at(0)
			local key = sgs.Sanguosha:cloneCard("keyCard")
			local wrapped = sgs.Sanguosha:getWrappedCard(id)
            wrapped:takeOver(key)
			wrapped:setSkillName(self:objectName())
			room:moveCardTo(wrapped, dying.who, dying.who, sgs.Player_PlaceDelayedTrick,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
                player:objectName(), self:objectName(), ""))
		end
		if event == sgs.DamageInflicted then
            local list = sgs.IntList()
			for _,c in sgs.qlist(player:getJudgingArea()) do
				if c:isKindOf("Key") then list:append(c:getId()) end
			end
			if list:length()> 0 then
                room:fillAG(list, sp)
				local id = room:askForAG(sp, list, false, self:objectName())
				room:clearAG(sp)
				room:throwCard(id, player, sp)
			end
		end
	end
}

Quzheng = sgs.CreateTriggerSkill{
	name = "quzheng",
	events = {sgs.EventPhaseEnd, sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.Damaged, sgs.Death},
    on_record = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceTable and player:getPhase() ~= sgs.Player_NotActive and move.from and move.from:objectName() == player:objectName() then
                local list = room:getTag(player:objectName().."quzhengid"):toString():split("+")
				for _,id in sgs.qlist(move.card_ids) do
			        if not table.contains(list, string.format("%d",id)) then table.insert(list, string.format("%d",id)) end
				end
				room:setTag(player:objectName().."quzhengid", sgs.QVariant(table.concat(list, "+")))
			end
		end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
                room:setTag(player:objectName().."quzhengid", sgs.QVariant())
			end
		end
		if event == sgs.Damaged or event == sgs.Death then
			local current = room:getCurrent()
			if current then
				room:setPlayerFlag(current, "quzheng_trigger")
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
           local players = room:findPlayersBySkillName(self:objectName())
		   for _,sp in sgs.qlist(players) do
			   local list = room:getTag(player:objectName().."quzhengid"):toString():split("+")
			   local list_copy = room:getTag(player:objectName().."quzhengid"):toString():split("+")
			   for _,i in ipairs(list_copy) do
				   if i == "" then continue end
                   local card = sgs.Sanguosha:getCard(tonumber(i))
                   if not room:getDiscardPile():contains(tonumber(i)) then
					   table.removeOne(list, i)
				   end
			   end
               if player:getPhase() == sgs.Player_Finish and #list>0 and sp:getPile("evidence"):length()<3 and player ~= sp and not sp:isKongcheng() and player:hasFlag("quzheng_trigger") then
				   return self:objectName(), sp
			   end				   
		   end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		if event == sgs.EventPhaseEnd and sp:askForSkillInvoke(self, data) then
			local list = room:getTag(player:objectName().."quzhengid"):toString():split("+")
			local ids = sgs.IntList()
			local list_copy = room:getTag(player:objectName().."quzhengid"):toString():split("+")
			for _,i in ipairs(list_copy) do
				if i == "" then continue end
				if not room:getDiscardPile():contains(tonumber(i)) then
					table.removeOne(list, i)
				end
			end
			for _,i in ipairs(list) do
				if i == "" then continue end
				ids:append(tonumber(i))
			end
			room:fillAG(ids, sp)
			local id = room:askForAG(sp, ids, false, self:objectName())
			local card = sgs.Sanguosha:getCard(id)
			room:clearAG(sp)
            --if room:askForCard(sp, ".|"..card:getSuitString().."|.|hand", "@quzheng", sgs.QVariant(), sgs.Card_MethodDiscard) then
			if room:askForCard(sp, ".|.|.|hand", "@quzheng", sgs.QVariant(), sgs.Card_MethodDiscard) then
			  room:setPlayerProperty(sp, "quzhengid", sgs.QVariant(card:getEffectiveId()))
              room:broadcastSkillInvoke(self:objectName(), sp)
			  return true
			end
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        if event == sgs.EventPhaseEnd then
			local id = sp:property("quzhengid"):toInt()
			sp:addToPile("evidence", id)
		end
	end
}	

Nizhuanvs = sgs.CreateOneCardViewAsSkill{
	name = "nizhuan",
	expand_pile = "evidence",
	filter_pattern = ".|.|.|evidence",
	view_as = function(self, card)
		local new_card = sgs.Sanguosha:cloneCard("igiari")
		new_card:addSubcard(card)
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
    enabled_at_play=function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
	    return table.contains(pattern:split("+"), "igiari") and player:getPile("evidence"):length()>0 and not player:hasFlag("nizhuan_used")
    end,
	enabled_at_igiari = function(self, player)
		return player:getPile("evidence"):length()>0 and not player:hasFlag("nizhuan_used")
    end,
}

Nizhuan = sgs.CreateTriggerSkill{
	name = "nizhuan",
	relate_to_place = "head",
	view_as_skill = Nizhuanvs,
	events = {sgs.CardUsed, sgs.CardFinished, sgs.EventPhaseChanging},
    on_record = function(self, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() then
                room:setPlayerFlag(player, "nizhuan_used")
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasFlag("nizhuan_used") then
						room:setPlayerFlag(p, "-nizhuan_used")
					end
				end
			end
		end
		if event == sgs.CardFinished then
            local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() then
                local card = player:property("igiari_card"):toCard()
				local from = player:property("igiari_from"):toPlayer()
				local to = player:property("igiari_to"):toPlayer()
				if from and to and card and card:isKindOf("Slash") and card:getColor()==use.card:getColor() and from:isAlive() and to:isAlive() then
					local slash = sgs.Sanguosha:cloneCard(card:objectName())
					local u = sgs.CardUseStruct()
					u.from = to
					u.to:append(from)
					u.card = slash
					room:useCard(u, false)
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return ""
	end,
}

YanshenCard = sgs.CreateSkillCard{
	name = "YanshenCard",
	target_fixed = true;
	on_use = function(self, room, source, targets)
		local current = room:getCurrent()
		if current then
			local ids = self:getSubcards()
            if ids:length()>0 then
				room:fillAG(ids, current)
				local id = room:askForAG(current, ids, false, "yanshen")
				room:clearAG(current)
				ids:removeOne(id)
				room:obtainCard(current, id)
				if ids:length()>0 then room:obtainCard(source, ids:at(0)) end
				local choice = room:askForChoice(current, "yanshen", "yanshen_1+yanshen_2")
				if choice == "yanshen_1" then
					room:setPlayerFlag(current, "yanshen_Judge")
					room:setPlayerFlag(current, "yanshen_Draw")
				else
					room:setPlayerFlag(current, "yanshen_Play")
					room:setPlayerFlag(current, "yanshen_Discard")
				end
			end
		end
	end,
}

Yanshenvs = sgs.CreateViewAsSkill{
	name = "yanshen",
	expand_pile = "evidence",
	view_filter=function(self,selected,to_select)
		return #selected < 2 and not sgs.Self:getHandcards():contains(to_select) and not sgs.Self:getEquips():contains(to_select)
	end,
	view_as = function(self, cards)
		if #cards <2 then return nil end
		local new_card = YanshenCard:clone()
		for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end      
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player)
		return false
	end,
	enabled_at_response=function(self,player,pattern) 
		return pattern=="@@yanshen"
	end,
}

Yanshen = sgs.CreateTriggerSkill{
	name = "yanshen",
	relate_to_place = "deputy",
	view_as_skill = Yanshenvs,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local phase = change.to
			if phase == sgs.Player_Draw and player:hasFlag("yanshen_Draw") and not player:isSkipped(phase) then
			   room:setPlayerFlag(player, "-yanshen_Draw")
			   player:skip(phase)
			end
			if phase == sgs.Player_Judge and player:hasFlag("yanshen_Judge") and not player:isSkipped(phase) then
				room:setPlayerFlag(player, "-yanshen_Judge")
				player:skip(phase)
			 end
			 if phase == sgs.Player_Play and player:hasFlag("yanshen_Play") and not player:isSkipped(phase) then
				room:setPlayerFlag(player, "-yanshen_Play")
				player:skip(phase)
			 end
			 if phase == sgs.Player_Discard and player:hasFlag("yanshen_Discard") and not player:isSkipped(phase) then
				room:setPlayerFlag(player, "-yanshen_Discard")
				player:skip(phase)
			 end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if player:getPhase() == sgs.Player_Start and player:getHandcardNum()>=player:getHp() and sp:getPile("evidence"):length()>=2 then
					return self:objectName(), sp
				end				   
			end
		 end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		if event == sgs.EventPhaseStart and sp:askForSkillInvoke(self, data) then
            if room:askForUseCard(sp, "@@yanshen", "@yanshen") then return true end
		end
	end,
	on_effect = function(self, event, room, player, data, sp)

	end
}

Ranxin = sgs.CreateTriggerSkill{
	name = "ranxin",
	events = {sgs.EventPhaseEnd, sgs.CardUsed, sgs.DamageCaused, sgs.CardResponded},
    on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(player, "ranxin_times"..p:objectName(), 0)
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardUsed then
		   local use = data:toCardUse()
		   if not use.card:isRed() or use.card:getTypeId() == sgs.Card_TypeSkill or room:getCurrent():getMark("ranxin_times"..player:objectName())> 2 then return false end
		   if player:getPile("ranxin_magic"):length() < 3 and player:hasSkill(self:objectName()) and player:isAlive() then return self:objectName() end  
		end
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and player:getPile("ranxin_magic"):length() >0 and player:hasSkill(self:objectName()) and player:isAlive() then return self:objectName() end
		end
		if event == sgs.CardResponded then
			local res = data:toCardResponse()
			if not res.m_card:isRed() or res.m_card:getTypeId() == sgs.Card_TypeSkill or room:getCurrent():getMark("ranxin_times"..player:objectName())> 2 then return false end
			if res.m_isUse and player:getPile("ranxin_magic"):length() < 3 and player:hasSkill(self:objectName()) and player:isAlive() then return self:objectName() end  
		 end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
	    if (event == sgs.CardUsed or event == sgs.CardResponded) and player:askForSkillInvoke(self, data) then
			room:setPlayerMark(room:getCurrent(), "ranxin_times"..player:objectName(), room:getCurrent():getMark("ranxin_times"..player:objectName())+1)
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		if event == sgs.DamageCaused and (player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data)) then
            room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
        if event == sgs.CardUsed or event == sgs.CardResponded then
			local id = room:getDrawPile():at(0)
		    player:addToPile("ranxin_magic", id)
		else
			if player:getPile("ranxin_magic"):length()>0 then
				local list = player:getPile("ranxin_magic")
				room:fillAG(list, player)
				local id = room:askForAG(player, list, false, self:objectName())
				room:clearAG(player)
				room:throwCard(id, player, player)
				player:drawCards(1)
			end
		end
	end
}

Chiyi = sgs.CreateTriggerSkill{
	name = "chiyi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseEnd},
    on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(player, "ranxin_times"..p:objectName(), 0)
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
		   if player:getPhase() == sgs.Player_Finish and player:getPile("ranxin_magic"):length() >0 and player:hasSkill(self:objectName()) and player:isAlive() then return self:objectName() end  
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
	    if event == sgs.EventPhaseEnd and (player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data)) then
            room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
        local n = player:getPile("ranxin_magic"):length()
		local list = player:getPile("ranxin_magic")
		for _,i in sgs.qlist(list) do
			room:throwCard(i, player, player)
		end
		if n <= 2 and n > 0 then
			room:loseHp(player)
			player:drawCards(2)
		elseif n >2 then
			room:loseMaxHp(player)
			player:drawCards(3)
			if not player:isKongcheng() then
				room:askForDiscard(player, self:objectName(), 1, 1)
			end
		end
	end
}

Ranxintr = sgs.CreateTargetModSkill{
	name = "#ranxintr",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasShownSkill("ranxin") and player:getPile("ranxin_magic"):length()>0 then
			return 1
		end
		return 0
	end,
}

Shenqi = sgs.CreateTriggerSkill{
	name = "shenqi",
	events = {sgs.GeneralShown, sgs.CardUsed, sgs.Death},
	relate_to_place = "head",
	can_trigger = function(self, event, room, player, data)
		if event == sgs.GeneralShown then
		   if player:hasSkill(self:objectName()) and player:isAlive() and player:inHeadSkills(self) == data:toBool() then return self:objectName() end  
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local list = player:getTag(self:objectName().."s"):toList()
			if player:hasSkill(self:objectName()) and player:isAlive() and use.card:isKindOf("Slash") and list:length()>0 then return self:objectName() end  
		end
		if event == sgs.Death then
			local death = data:toDeath()
			local g1 = death.who:getActualGeneral1Name()
			local g2 = death.who:getActualGeneral2Name()
			if player:hasSkill(self:objectName()) and player:isAlive() and death.who:isFriendWith(player) and (not string.find(g1, "sujiang") or not string.find(g2, "sujiang")) then return self:objectName() end  
		end
		return ""
	end,
	on_cost = function(self, event, room, target, data, player)
	    if event == sgs.GeneralShown and (player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data)) then
            room:broadcastSkillInvoke(self:objectName(), 1, player)
			return true
		end
		if event == sgs.CardUsed and player:askForSkillInvoke(self, data) then
            room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		if event == sgs.Death and player:askForSkillInvoke(self, data) then
            room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
        if event == sgs.GeneralShown then
			local generals = {}
			for _,g in ipairs(sgs.Sanguosha:getLimitedGeneralNames(true)) do
				if table.contains(sgs.Sanguosha:getGeneral(g):getKingdom():split("|"), "magic") and not table.contains(getUsedGeneral(room), g) then
					table.insert(generals, g)
				end
			end
			generals = table.Shuffle(generals)
			if #generals>0 then
				addGeneralCardToPile(room, player, generals[1], self:objectName())
			end
		end
		if event == sgs.CardUsed then
		   local ava = {}
           local list = player:getTag(self:objectName().."s"):toList()
		   for _,n in sgs.qlist(list) do
			  table.insert(ava, n:toString())
		   end
		   if #ava == 0 then return false end
           local to = room:askForGeneral(player, table.concat(ava, "+"), nil,true, self:objectName())
		   player:showGeneral(false)
		   local general = player:getActualGeneral2Name()
		   removeGeneralCardToPile(room, player, to, self:objectName())
		   room:exchangeDeputyGeneralTo(player, to)
		   if string.find(general, "sujiang") then return false end
           addGeneralCardToPile(room, player, general, self:objectName())
	    end
		if event == sgs.Death then
			local death = data:toDeath()
			local g1 = death.who:getActualGeneral1Name()
			local g2 = death.who:getActualGeneral2Name()
			local ava = {}
			if not string.find(g1, "sujiang") then table.insert(ava, g1) end
			if not string.find(g2, "sujiang") then table.insert(ava, g2) end
 			if #ava == 0 then return false end
			local to = room:askForGeneral(player, table.concat(ava, "+"), nil,true, self:objectName())
			if to == g1 then
				death.who:removeGeneral(true)
			else
				death.who:removeGeneral(false)
			end
			addGeneralCardToPile(room, player, to, self:objectName())
		 end
	end
}

Huojin = sgs.CreateTriggerSkill{
	name = "huojin",
	relate_to_place = "deputy",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
			local list = sgs.SPlayerList()
			local has
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isNude() then has = true end
			end
			if player:hasSkill(self:objectName()) and player:isAlive() and has then return self:objectName() end  
		end
		return ""
	end,
    on_cost = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:askForSkillInvoke(self, data) then
			local list = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isNude() then list:append(p) end
			end
			local target
			if list:length()>0 then
                target = room:askForPlayerChosen(player, list, self:objectName(), "", true)
			end
            if target then
                player:setProperty("huojin_target", sgs.QVariant(target:objectName()))
				room:broadcastSkillInvoke(self:objectName(), player)
			    return true
			end
		end
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart then
            local target = findPlayerByObjectName(player:property("huojin_target"):toString())
		    if not target then return false end
			local card = room:askForCard(target, ".|.|.", "@huojin:"..target:objectName()..":"..player:objectName(), sgs.QVariant(), sgs.Card_MethodNone)
			if card then
				room:obtainCard(player, card, false)
				local list = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p ~= target then list:append(p) end
				end
				local tar
				if list:length()>0 then
					tar = room:askForPlayerChosen(target, list, self:objectName(), "", false, true)
				end
				if tar then
                    room:askForUseSlashTo(player, tar, "@huojin-slash", false, true, false)
				end
			end
	    end
	end,	
}

Zhanyuan = sgs.CreateTriggerSkill{
	name = "zhanyuan",
	events = {sgs.Damage},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Damage then
			local damage= data:toDamage()
			if player:hasSkill(self:objectName()) and player:isAlive() and damage.card and damage.card:isKindOf("Slash") and (not damage.to:isNude() or damage.to:getJudgingArea():length()>0) and not room:getCurrent():hasFlag(player:objectName().."zhanyuan_used") then return self:objectName() end  
		end
		return ""
	end,
    on_cost = function(self, event, room, target, data, player)
		if event == sgs.Damage and player:askForSkillInvoke(self, data) then
			room:setPlayerFlag(room:getCurrent(), player:objectName().."zhanyuan_used")
            room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.Damage then
            local damage= data:toDamage()
			if not damage.to:isNude() or damage.to:getJudgingArea():length()>0 then
				local id = room:askForCardChosen(player, damage.to, "hej", self:objectName())
				room:throwCard(id, damage.to, player)
				if not damage.to:isRemoved() then
					room:setPlayerCardLimitation(damage.to, "use", ".", false)
					room:setPlayerProperty(damage.to, "removed", sgs.QVariant(true))
				end
            end
	    end
	end,	
}

yizhigame = sgs.CreateTriggerSkill{
	name = "yizhigame",
	events = {sgs.Death, sgs.DrawNCards, sgs.GameOverJudge},
	--frequency = sgs.Skill_Compulsory,
	on_record = function(self, event, room, player, data)
	if event == sgs.DrawNCards then
		local room = player:getRoom()
		local count = data:toInt()
		local n = player:getMark("@yizhigame3")
		data:setValue(count + n )
	end		
	end,
	
	can_trigger = function(self, event, room, player, data)
	if event == sgs.Death then
		if player and player:hasSkill(self:objectName()) and player:isAlive() then
			return self:objectName()
		end
		return ""
	end 
	if event == sgs.GameOverJudge then
		if player:hasSkill(self:objectName())  then
			return self:objectName()
		end
		return ""	
	end 
	end ,
	
	on_cost = function(self, event, room, player, data)
	if event == sgs.Death then
		if player:askForSkillInvoke(self,data) then
			local da = sgs.QVariant()
			da:setValue(player)
			return true
		end
		return false
	end 
	if event == sgs.GameOverJudge then
		if player:askForSkillInvoke(self,data) then
			return true
		end
		return false
	end 
	end,
	on_effect = function(self, event, room, player, data, ask_who)
	if event == sgs.Death then
		local room = player:getRoom()
		local death = data:toDeath()
		local splayer = death.who
		local da = sgs.QVariant()
	    da:setValue(player)
		if not splayer:askForSkillInvoke(self,da) then return false end
		local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local cards = splayer:getCards("he")
			for _,card in sgs.qlist(cards) do
					dummy:addSubcard(card)
			end
				if cards:length() > 0 then
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECYCLE, player:objectName())
					room:obtainCard(player, dummy, reason, false)
				end
				dummy:deleteLater()
				
				local choice=room:askForChoice(splayer,self:objectName(),"a+b+c")
					local list = room:getAlivePlayers()
					if choice == "a" then
						
					player:gainMark("@yizhigame1", 1)	
					end
					if choice == "b" then
						
					player:gainMark("@yizhigame2", 1)	
					end
					
					if choice == "c" then
						
					player:gainMark("@yizhigame3", 1)	
					end	
			
	end
	if event == sgs.GameOverJudge then
		local room = player:getRoom()
		local to = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "LuaZhiyan-invoke", true, true)
		if to then
		local a = player:getMark("@yizhigame1")
		to:gainMark("@yizhigame1", a)
		local b = player:getMark("@yizhigame2")
		to:gainMark("@yizhigame2", b)
		local c = player:getMark("@yizhigame3")
		to:gainMark("@yizhigame3", c)
		room:acquireSkill(to, "yizhigame")
		end
	end
	end ,



}

yizhigameKeep = sgs.CreateMaxCardsSkill{
		name = "#yizhigameKeep",
		extra_func = function(self, target)
			if target:hasSkill(yizhigame) then
				return 2 * target:getMark("@yizhigame1")
			end
			return 0
		end
	}

yizhigamechusha = sgs.CreateTargetModSkill{
		name = "#yizhigamechusha",
		residue_func = function(self, target)
			if target:hasSkill(yizhigame)  then 
				return target:getMark("@yizhigame2")
			end
			return 0
		end
	}
	



sibieCard = sgs.CreateSkillCard{
		name = "sibieCard", 
		target_fixed = false,
		will_throw = false,
		filter = function(self, targets, to_select)
			local has
			for _,p in sgs.qlist(sgs.Self:getAliveSiblings()) do
				if sgs.Self:hasFlag("sibie"..p:objectName()) then
					has = p
				end
			end
			return (#targets == 0) and (to_select:getHp() > sgs.Self:getHp()) and (not has or to_select:objectName()==has:objectName())
		end,
		on_effect = function(self, effect)
			local source = effect.from
			local dest = effect.to
			local room = source:getRoom()
			room:setPlayerFlag(source, "sibie"..dest:objectName())
			local theDamage = sgs.DamageStruct()
			theDamage.from = source
			theDamage.to = dest
			theDamage.damage = 1
			theDamage.nature = sgs.DamageStruct_Normal
			room:damage(theDamage)			
			room:loseHp(source)
			if not source:isAlive() then
			dest:throwAllEquips()
			end
			
		end
	}
	sibie = sgs.CreateViewAsSkill{
		name = "sibie", 
		n = 0, 
		view_filter = function(self,selected, to_select)
		end,
		view_as = function(self, cards) 			
				local vs = sibieCard:clone()
				vs:setShowSkill(self:objectName())
				return vs			
		end
	}

	SlianjiCard = sgs.CreateSkillCard{
		name = "SlianjiCard",
		will_throw = false,
		filter = function(self, targets, to_select)
			return (#targets == 0) and to_select:objectName() ~= sgs.Self:objectName() 
		end,
		on_use = function(self, room, source, targets)
			for _,p in ipairs(targets) do
                room:obtainCard(p, self, false)
				local list = {"heart", "spade", "diamond", "club", "EquipCard", "BasicCard", "TrickCard"}
				local suits = {"heart", "spade", "diamond", "club"}
				local type = room:askForChoice(source, "slianji", table.concat(list, "+"), sgs.QVariant(self:getSubcards():at(0)))
				local log = sgs.LogMessage()
                log.from = source
				log.type = "#Slianji_choice"
				log.arg = type
				room:sendLog(log)
				local card
				if table.contains(suits, type) then
				    card = room:askForCard(p, ".|"..type.."|.|hand", "@slianji:"..source:objectName().."::"..type, sgs.QVariant(), sgs.Card_MethodNone)
			    else
					card = room:askForCard(p, type.."|.|.|hand", "@slianji:"..source:objectName().."::"..type, sgs.QVariant(), sgs.Card_MethodNone)
				end
				if card then
					room:obtainCard(source, card)
				else
					local list = sgs.IntList()
					if p:getHandcardNum()>2 then
                        list = room:askForExchange(p, "slianji", 2, 2, "", "", ".|.|.|hand")
						if list:isEmpty() and p:getHandcardNum()>=2 then
							list:append(p:handCards():at(0))
							list:append(p:handCards():at(1))
						end
					elseif p:getHandcardNum() <= 2 then
						list = p:handCards()
					end
                    if not list:isEmpty() then
						local dummy  = sgs.DummyCard()
						dummy:deleteLater()
						dummy:addSubcards(list)
						room:obtainCard(source, dummy, false)
					end
				end
			end
		end,
	}

	
Slianji = sgs.CreateOneCardViewAsSkill{
	name = "slianji",
	view_filter = function(self, to_select)
		return true
	end,
	view_as = function(self, card)
		local vs = SlianjiCard:clone()
		vs:addSubcard(card)
		vs:setShowSkill(self:objectName())	
		vs:setSkillName(self:objectName())		
		return vs		
	end,
	enabled_at_play=function(self,player)
		return not player:hasUsed("ViewAsSkill_"..self:objectName().."Card")
	end,
}

	Jinchi = sgs.CreateTriggerSkill{
		name = "jinchi",
		events = {sgs.DamageForseen},
		can_trigger = function(self, event, room, player, data)
			local damage = data:toDamage()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.from and damage.from:isAlive() and not room:getCurrent():hasFlag("jinchiUsed") and not player:isKongcheng() then
				return self:objectName()
			end
			return ""
		end,
		on_cost = function(self, event, room, player, data)
			local damage = data:toDamage()
			local who = sgs.QVariant()
			who:setValue(damage.from)
			if player:askForSkillInvoke(self, who) then    
				room:getCurrent():setFlags("jinchiUsed")
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
			return false
		end,
		on_effect = function(self, event, room, player, data)
			local damage = data:toDamage()
			if not player:isKongcheng() then
				room:showAllCards(player)
				local spade, club, heart, diamond = 0, 0, 0, 0
				for _,k in sgs.qlist(player:getHandcards()) do
					if k:getSuit() == sgs.Card_Spade then
						spade = spade + 1
					end					
					if k:getSuit() == sgs.Card_Club then
						club = club + 1
					end
					if k:getSuit() == sgs.Card_Heart then
						heart = heart + 1
					end
					if k:getSuit() == sgs.Card_Diamond then
						diamond = diamond + 1
					end
				end
				local max = math.max(spade, heart, club, diamond)
				local suit_list = {}
				if spade == max then
					table.insert(suit_list, "spade")
				end
				if club == max then
					table.insert(suit_list, "club")
				end
				if heart == max then
					table.insert(suit_list, "heart")
				end
				if diamond == max then
					table.insert(suit_list, "diamond")
				end
				local suit_pat = table.concat(suit_list, ",")
				local card = room:askForCard(damage.from, ".|"..suit_pat.."|.|hand", "&jinchi:" .. player:objectName(), data)
				if not card then
					local log = sgs.LogMessage()
					log.type = "#jinchi_effect"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
					return true
				end
			end
		end,
	}

	LingshangVS = sgs.CreateViewAsSkill{
		name = "lingshang",
		n = 2,
		view_filter = function(self, selected, to_select)
			if #selected < 1 then
				return true
			elseif #selected ==1 then
				return to_select:getTypeId() == selected[1]:getTypeId()
			end
			return false
		end,
		view_as = function(self, cards)
			if #cards == 2 then
				local vs = lingshangCard:clone()
				for _,card in pairs(cards) do
					vs:addSubcard(card)
				end			
				vs:setShowSkill(self:objectName())
				vs:setSkillName(self:objectName())
				return vs
			end
		end,
		enabled_at_play = function(self, player)
			return false
		end,
		enabled_at_response = function(self, player, pattern)
			return pattern == "@@lingshang"
		end,
	}
	
	lingshangCard = sgs.CreateSkillCard{
		name = "lingshangCard",
		target_fixed = true,
		on_use = function(self, room, source, targets)
			room:setPlayerMark(source, "lingshang-used", source:getMark("lingshang-used")+1)
			local pattern = source:property("lingshang_card"):toInt()
			local list = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(pattern):getTypeId() ~= sgs.Sanguosha:getCard(id):getTypeId() then continue end
				list:append(id)
			end
			if list:length() > 0 then
				local id = list:at(math.random(0, list:length()-1))
				local card = sgs.Sanguosha:getCard(id)
				room:doLightbox("SE_Lingshang$", 500)
				room:obtainCard(source, card)
				source:gainMark("#SakiMark")
			end
		end,
	}
	
	Lingshang = sgs.CreateTriggerSkill{
		name = "lingshang",
		can_preshow = true,
		view_as_skill = LingshangVS,
		events = {sgs.CardsMoveOneTime, sgs.EventPhaseChanging, sgs.DrawNCards},
		on_record = function(self, event, room, player, data)
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_NotActive then
					for _,Saki in sgs.qlist(room:getAlivePlayers()) do
						if Saki:getMark("lingshang-invoke") + Saki:getMark("lingshang-used") > 0 then
							room:setPlayerMark(Saki, "lingshang-invoke", 0)
							room:setPlayerMark(Saki, "lingshang-used", 0)
						end
					end
				end
			end
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if move.card_ids:length() == 1 and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= 0x03 and move.to_place == sgs.Player_DiscardPile and player:getMark("#SakiMark") < 4 then
					room:setPlayerMark(player, "lingshang-invoke", player:getMark("lingshang-invoke")+1)
				end
			end
		end,
		can_trigger = function(self, event, room, player, data)
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				if player and player:isAlive() and player:hasSkill(self:objectName()) and move.card_ids:length() == 1 and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= 0x03 and move.to_place == sgs.Player_DiscardPile and player:getMark("#SakiMark") < 4 then
					if player:getMark("lingshang-invoke") - player:getMark("lingshang-used") == 1 then
						return self:objectName()
					end
				end
			end
			if event == sgs.DrawNCards then
				if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("#SakiMark") > 0 then
					return self:objectName()
				end
			end
			return ""
		end,
		on_cost = function(self, event, room, player, data)
			if event == sgs.CardsMoveOneTime then
				local move = data:toMoveOneTime()
				room:setPlayerProperty(player, "lingshang_card", sgs.QVariant(move.card_ids:at(0)))
				if room:askForUseCard(player, "@@lingshang", "@lingshang") then               
					return true
				end
			end
			if event == sgs.DrawNCards then
				if player:askForSkillInvoke(self, data) then
					room:broadcastSkillInvoke(self:objectName(), player)
					return true
				end
			end
			return false
		end,
		on_effect = function(self, event, room, player, data)
			if event == sgs.CardsMoveOneTime then
				return
			end
			if event == sgs.DrawNCards then				
				local count = data:toInt()
				count = count + player:getMark("#SakiMark")
				data:setValue(count)
			end
		end,
	}
	
	LingshangMaxCards = sgs.CreateMaxCardsSkill{
		name = "#lingshangMaxCards" ,
		extra_func = function(self, player)
			if player:hasSkill("lingshang") then
				return player:getMark("#SakiMark")
			end
			return 0
		end
	}
	
	Guiling = sgs.CreateZeroCardViewAsSkill{
		name = "guiling",
		view_as = function(self)
			local vs = guilingCard:clone()
			vs:setShowSkill(self:objectName())
			return vs
		end,
		enabled_at_play = function(self, player)
			return not player:hasUsed("ViewAsSkill_guilingCard") and player:getMark("#SakiMark") > 0
		end,
	}
	
	guilingCard = sgs.CreateSkillCard{
		name = "guilingCard",
		target_fixed = false,
		will_throw = true,
		filter = function(self, targets, to_select)
			if #targets < sgs.Self:getMark("#SakiMark") and #targets < 3 then
				return to_select:objectName() ~= sgs.Self:objectName()
			end
			return false
		end,
		feasible = function(self, targets)
			return #targets > 0
		end,
		on_use = function(self, room, source, targets)
			if #targets > 0 then
				source:loseMark("#SakiMark", #targets)
				for _,A in ipairs(targets) do
					local show_ids = room:askForExchange(A, "guiling", 1, 0, "&guilingGive:" .. source:objectName(), "", "EquipCard")
					if not show_ids:isEmpty() then					
						local show = sgs.Sanguosha:getCard(show_ids:first())
						local reason = sgs.CardMoveReason(0x17, source:objectName())
						room:obtainCard(source, show, reason, false)
					else				
						local choice
						if not source:isWounded() then
							choice = "guilingDamage"
						else
							local da = sgs.QVariant()
							da:setValue(source)
							choice = room:askForChoice(A, "guiling", "guilingDamage+guilingRecover", da)
						end
						if choice == "guilingDamage" then
							local damage = sgs.DamageStruct()
							damage.from = source
							damage.to = A
							room:damage(damage)
						else
							local recover = sgs.RecoverStruct()
							recover.who = A
							recover.recover = 1
							room:recover(source, recover, true) 
						end
					end
				end
			end
		end,
	}
	
	Guilingglobal = sgs.CreateTriggerSkill{
		name = "guilingglobal",
		global = true,
		events = {sgs.EventPhaseChanging},
		on_record = function(self, event, room, player, data)
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("#SakiMark") > 0 then
				player:loseMark("#SakiMark", player:getMark("#SakiMark"))
			end
		end,
		can_trigger = function(self, event, room, player, data)
			return ""
		end,
	}

    BaolieCard = sgs.CreateSkillCard{
		name = "BaolieCard",
		filter = function(self, targets, to_select)
			local n = sgs.Self:getPile("yinchang"):length()
			if #targets < n then
				return 2
			else
				return false
			end 
		end,
		on_use = function(self, room, source, targets)
			local move = sgs.CardsMoveStruct()
				move.card_ids = source:getPile("yinchang")
				move.reason = sgs.CardMoveReason(0x01,"","yinchang","")
				move.to_place = sgs.Player_DiscardPile
				room:moveCardsAtomic(move, true)
			local real_targets = sgs.SPlayerList()
			for _,p in ipairs(targets) do
				if not real_targets:contains(p) then
					real_targets:append(p)
				else
					continue
				end
				local n = 0
				for _,q in ipairs(targets) do
					if q:objectName() == p:objectName() then n = n+1 end
				end
				local damage = sgs.DamageStruct()
				damage.from = source
				damage.to = p
				damage.damage = n
				damage.nature = sgs.DamageStruct_Fire
				room:damage(damage)
			end
		end,
	}

	
Baolievs = sgs.CreateZeroCardViewAsSkill{
	name = "baolie",
	view_as = function(self)
		local vs = BaolieCard:clone()
		vs:setShowSkill(self:objectName())	
		vs:setSkillName(self:objectName())		
		return vs 	
	end,
	enabled_at_play=function(self,player,pattern)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@baolie"
	end,
}

Baolie= sgs.CreateTriggerSkill{
	name = "baolie",
	view_as_skill = Baolievs,
	events = {sgs.EventPhaseChanging, sgs.DamageCaused},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging and player:isAlive() and player:hasSkill(self:objectName()) and data:toPhaseChange().to ==sgs.Player_Play and player:getPile("yinchang"):length()>=2 and not player:isSkipped(sgs.Player_Play) then
			return self:objectName()
		end
		if event == sgs.DamageCaused and player:isAlive() and player:hasSkill(self:objectName()) and player:getPile("yinchang"):length()>0 and data:toDamage().nature == sgs.DamageStruct_Fire then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging and player:askForSkillInvoke(self, data) and room:askForUseCard(player, "@@baolie", "@baolie") then
            return true
		end
		if event == sgs.DamageCaused and player:getPile("yinchang"):length()>0 and player:askForSkillInvoke(self, data) then
			local list = player:getPile("yinchang")
			room:fillAG(list, player)
			local id = room:askForAG(player, list, false, self:objectName())
			room:clearAG()
            if id > -1 then
				room:broadcastSkillInvoke(self:objectName(), player)
				room:throwCard(id, player, player)
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
            player:skip(sgs.Player_Play)
		end
		if event == sgs.DamageCaused then
            local damage = data:toDamage()
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
}

	Yinchang= sgs.CreateTriggerSkill{
		name = "yinchang",
		events = {sgs.EventPhaseStart, sgs.Damaged},
		can_trigger = function(self, event, room, player, data)
			if event == sgs.EventPhaseStart and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase()==sgs.Player_Start and not player:isNude() then
				return self:objectName()
			end
			if event == sgs.Damaged and player:isAlive() and player:hasSkill(self:objectName()) and player:getPile("yinchang"):length()>0 then
				return self:objectName()
			end
			return ""
		end,
		on_cost = function(self, event, room, player, data)
			if event == sgs.EventPhaseStart and player:askForSkillInvoke(self, data) then
				local list = sgs.IntList()
				for _,c in sgs.qlist(player:getCards("he")) do
					local has
					for _,i in sgs.qlist(player:getPile("yinchang")) do
						if sgs.Sanguosha:getCard(i):getTypeId() == c:getTypeId() then has = true end
					end
					if not has then list:append(c:getEffectiveId()) end
				end
				if not list:isEmpty() then
				   room:fillAG(list, player)
				   local id = room:askForAG(player, list, false, self:objectName())
				   room:clearAG(player)
				   room:setPlayerProperty(player, "yinchang_id", sgs.QVariant(id))
				   room:broadcastSkillInvoke(self:objectName(), player)
				   return true
				end
			end
			if event == sgs.Damaged and player:askForSkillInvoke(self, data) then
                local list = player:getPile("yinchang")
				if not list:isEmpty() then
				   room:fillAG(list, player)
				   local id = room:askForAG(player, list, false, self:objectName())
				   room:clearAG(player)
				   room:setPlayerProperty(player, "yinchangget_id", sgs.QVariant(id))
				   room:broadcastSkillInvoke(self:objectName(), player)
				   return true
				end
			end
			return false
		end,
		on_effect = function(self, event, room, player, data)
	        if event == sgs.EventPhaseStart then
			   local id = player:property("yinchang_id"):toInt()
			   player:addToPile("yinchang", id)
			end
			if event == sgs.Damaged then
				local id = player:property("yinchangget_id"):toInt()
				room:obtainCard(player, id)
			end
		end
	}

	xingling = sgs.CreateViewAsSkill{
		n = 1,
		name = "xingling",
		view_filter = function(self, selected, to_select)
		   return to_select:getSuit() == sgs.Card_Diamond and #selected == 0
		end,
		view_as = function(self, cards)
			if #cards == 0 then return nil end
			local card = sgs.Sanguosha:cloneCard("eirei_shoukan")
			card:addSubcard(cards[1])
			card:setShowSkill(self:objectName())
			card:setSkillName(self:objectName())
			return card
		end,
		enabled_at_play=function(self,player)
			return not player:hasUsed("ViewAsSkill_"..self:objectName().."Card")	
		end,
	}
	
	
	xinglingShown = sgs.CreateTriggerSkill{
		name = "#xinglingShown" ,
		events = {sgs.GeneralShown, sgs.CardUsed, sgs.EventPhaseChanging},
		on_record = function(self, event, room, player, data)
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_NotActive then
					local ava = {}
                    local list = player:getTag("xinglings"):toList()
		            for _,n in sgs.qlist(list) do
			           table.insert(ava, n:toString())
		            end
		            if #ava == 0 then return end
                    local to = room:askForGeneral(player, table.concat(ava, "+"), nil,true, "xingling")
					local choice = room:askForChoice(player, "xingling", "xingling_discard+xingling_change")
					if choice == "xingling_discard" then
						removeGeneralCardToPile(room, player, to, "xingling")
					else
                        player:showGeneral(false)
		                local general = player:getActualGeneral2Name()
		                removeGeneralCardToPile(room, player, to, "xingling")
		                room:exchangeDeputyGeneralTo(player, to)
					end
				end
			end			
		end,
		can_trigger = function(self, event, room, player, data)
			if event == sgs.GeneralShown and player and player:isAlive() and player:inHeadSkills(self) == data:toBool()and player:hasSkill("xingling") then---and player:getMark("&xingling_Shown") < 1
				return self:objectName()
			end
			if event == sgs.CardUsed and player:isAlive() and player:hasSkill("xingling") and data:toCardUse().card:isKindOf("Eireishoukan") then
				return self:objectName()
			end
			return ""
		end,
		on_cost=function(self,event,room,player,data)
			if event == sgs.GeneralShown and player:hasShownSkill("xingling") and player:askForSkillInvoke(self, data) then
				---room:setPlayerMark(player, "&xingling_Shown", 1)
				room:broadcastSkillInvoke("xingling", player)
				---room:doLightbox("xingling$", 999)
				return true
			end
			if event == sgs.CardUsed and player:askForSkillInvoke(self, data) then
				return true
			end
			return false
		end,
		on_effect=function(self, event, room, player, data)
			if event == sgs.GeneralShown then
				----room:setPlayerMark(player, "&xinglingShown_used", 1)
							local targetst = sgs.SPlayerList()
									for _,ps in sgs.qlist(room:getAlivePlayers()) do
										if (ps:getJudgingArea():length()+ps:getEquips():length())> 0 then
											targetst:append(ps)
										end 
									end
									for _,po in sgs.qlist(targetst) do
										 local dummy = sgs.DummyCard()
										 for _,c in sgs.qlist(po:getEquips()) do
											 if c:getSuit() == sgs.Card_Diamond then
												  dummy:addSubcard(c)
											 end
										 end
										 for _,c in sgs.qlist(po:getJudgingArea()) do
											  if c:getSuit() == sgs.Card_Diamond then
													dummy:addSubcard(c)
											  end
										 end
										 room:obtainCard(player, dummy, true)
										 dummy:deleteLater()
									end
						
			end
			if event == sgs.CardUsed then
				local g = player:getActualGeneral2Name()
				player:removeGeneral(false)
				addGeneralCardToPile(room, player, g, "xingling")
			end
		end	   
	}       
	
	lingqi = sgs.CreateTriggerSkill{
		name = "lingqi",
		events = {sgs.Death},
		can_trigger = function(self, event, room, player, data)
		   if event == sgs.Death then
				local death = data:toDeath()
				local players = room:findPlayersBySkillName(self:objectName())
					for _,sp in sgs.qlist(players) do
						if sp:isAlive() and sp:hasSkill(self:objectName()) and death.damage and death.damage.from:objectName() == sp:objectName() and sp == player then --death.who:objectName() ~= player:objectName()
							return self:objectName(), sp
						end
					end
			end		
			return ""
		end,
		on_cost = function(self, event, room, player, data, sp)
			if sp:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName())
				---room:doLightbox("lingqi$", 999)
				return true	
			end
		end,
		on_effect = function(self, event, room, player, data, sp)
			if event == sgs.Death then
				local death = data:toDeath()
						if sp:isAlive() then
							local list = sgs.IntList()
							for _,id in sgs.qlist(room:getDrawPile()) do
								local c = sgs.Sanguosha:getCard(id)
								if c:getSuitString()== "diamond" then list:append(id) end
							end
							for _,id in sgs.qlist(room:getDiscardPile()) do
								local c = sgs.Sanguosha:getCard(id)
								if c:getSuitString()== "diamond" then list:append(id) end
							end
							if not list:isEmpty() then room:obtainCard(sp, list:at(math.random(0, list:length()-1))) end	   
						end
	
			end			
		end				
	}

	KangshiCard = sgs.CreateSkillCard{
		name = "KangshiCard",
		target_fixed = true,
		on_use = function(self, room, source, targets)
			local damage = sgs.DamageStruct()
			damage.to = source
			room:damage(damage)
			if source:isDead() then return end
			local players = room:getAlivePlayers()
			room:sortByActionOrder(players)
			for _,p in sgs.qlist(players) do
                if sgs.isBigKingdom(p, "kangshi") then 
					if not p:isNude() then
                      local id = room:askForCardChosen(source, p, "he", "kangshi")
					  room:obtainCard(source, id, false)
					end
                    room:setPlayerMark(source, "kangshi"..p:objectName(), 1)
                    room:setFixedDistance(source,p,1)
				end
			end
		end,
	}

	Kangshivs = sgs.CreateZeroCardViewAsSkill{
		name = "kangshi",
		view_as = function(self)
			local vs = KangshiCard:clone()
			vs:setShowSkill(self:objectName())	
			vs:setSkillName(self:objectName())		
			return vs 	
		end,
		enabled_at_play=function(self,player)
			local list = player:getBigKingdoms(self:objectName(),sgs.Max)
			return not player:hasUsed("ViewAsSkill_"..self:objectName().."Card") and not sgs.isBigKingdom(player, self:objectName()) and #list == 1
		end,
	}

	Kangshi= sgs.CreateTriggerSkill{
		name = "kangshi",
		view_as_skill = Kangshivs,
		can_preshow = true,
		events = {sgs.DrawNCards, sgs.EventPhaseChanging},
		on_record = function(self, event, room, player, data)
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to == sgs.Player_NotActive then
					for _,p in sgs.qlist(room:getAllPlayers(true)) do
						if player:getMark("kangshi"..p:objectName())>0 then
							room:setPlayerMark(player, "kangshi"..p:objectName(), 0)
							room:setFixedDistance(player,p,-1)
						end
					end
				end
			end			
		end,
		can_trigger = function(self, event, room, player, data)
			local list = player:getBigKingdoms(skill_name,sgs.Max)
			if event == sgs.DrawNCards and player:isAlive() and player:hasSkill(self:objectName()) and not sgs.isBigKingdom(player, self:objectName()) and #list == 1 then
				return self:objectName()
			end
			return ""
		end,
		on_cost = function(self, event, room, player, data)
			if event == sgs.DrawNCards and player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName(). player)
				return true
			end
			return false
		end,
		on_effect = function(self, event, room, player, data)
			if event == sgs.DrawNCards then
				local n = data:toInt()
				n = n+1
				data:setValue(n)
			end
		end
	}

	Qingban = sgs.CreateTriggerSkill{
		name = "qingban",
		events = {sgs.Dying},
		can_trigger = function(self, event, room, player, data)
			if event == sgs.Dying then
				local dying = data:toDying()
				if player:isAlive() and player:hasSkill(self:objectName()) and player:getMaxHp()>1 and player:getMark("qingban"..dying.who:objectName()) == 0 then
					return self:objectName()
				end			
			end
			return ""
		end,
		on_cost = function(self, event, room, player, data, sp)
			if player:askForSkillInvoke(self, data) then
				local dying = data:toDying()
				room:setPlayerMark(player, "qingban"..dying.who:objectName(), 1)
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
			return false
		end,
		on_effect = function(self, event, room, player, data, sp)
			if event == sgs.Dying then
				local dying = data:toDying()
				room:loseMaxHp(player)
				local recover = sgs.RecoverStruct()
		        recover.who = player
		        room:recover(dying.who, recover, true)
			end
		end
	}

	xinkong = sgs.CreateTriggerSkill{
		name = "xinkong",
		events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
		on_record = function(self, event, room, player, data)
			if event == sgs.EventPhaseEnd then
				if player:getPhase() == sgs.Player_Finish then
						 room:setPlayerMark(player, "#xinkong_max", 0)
				end	
			end		
		
		end,
		can_trigger = function(self, event, room, player, data)
			if event == sgs.EventPhaseStart and player and player:isAlive() and player:hasSkill("xinkong") and player:getPhase()==sgs.Player_Play then
				return self:objectName()
			end
			return ""
		end,
		on_cost = function(self, event, room, player, data)
			if player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke("xinkong")
				room:doLightbox("xinkong$", 999)
				return true
			end
			return false
		end,
		on_effect = function(self, event, room, player, data)
				local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 1, 1, "@xinkonga")
				for _,p in sgs.qlist(targets) do
					if not p:isKongcheng() then 
						local choice = room:askForChoice(player, "xinkong", "@xinkong1+@xinkong2")
						if choice == "@xinkong1" then
							local show_ids = room:askForExchange(player, self:objectName(), 1, 1, "&xinkong", "", ".|.|.|.")
							local show_id = -1
							if show_ids:isEmpty() then
							   show_id = player:getCards("he"):first():getEffectiveId()
							else
							   show_id = show_ids:first()
							end
							local show = sgs.Sanguosha:getCard(show_id)
							if show then
								room:moveCardTo(show, nil, sgs.Player_DiscardPile, room:getCardPlace(show:getId()) ~= sgs.Player_PlaceHand)
								local log = sgs.LogMessage()
								log.type = "#Card_Recast"   
								log.from = player
								log.arg = self:objectName()
								room:sendLog(log)
								player:drawCards(1)
							end
							if not p:isKongcheng() then
								room:showAllCards(p)
							end	
						elseif choice == "@xinkong2" then
							local targetsm = room:askForPlayersChosen(player, room:getOtherPlayers(p), self:objectName(), 1, 1, "@xinkongb")
							for _,pm in sgs.qlist(targetsm) do
							   local list = {}
							   if not p:isKongcheng() then table.insert(list, "xinkong_seehandcards") end
							   local dat = sgs.QVariant()
							   dat:setValue(p)
							   local choice = room:askForChoice(player, self:objectName(), table.concat(list, "+"), dat)
								if choice == "xinkong_seehandcards" and not p:isKongcheng() then
								   local m = room:askForCardChosen(player, p, "h", self:objectName(), true)
								   room:obtainCard(player, m, false) 
									if not room:askForUseSlashTo(p, pm, "@xinkong-slash", true) then room:loseHp(p) end
									room:setPlayerMark(player, "#xinkong_max", 1)
									room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
	 
								end	
							end	
						end       
					elseif p:isKongcheng() then
							local show_ids = room:askForExchange(player, self:objectName(), 1, 1, "&xinkong", "", ".|.|.|.")
							local show_id = -1
							if show_ids:isEmpty() then
							   show_id = player:getCards("he"):first():getEffectiveId()
							else
							   show_id = show_ids:first()
							end
							local show = sgs.Sanguosha:getCard(show_id)
							if show then
								room:moveCardTo(show, nil, sgs.Player_DiscardPile, room:getCardPlace(show:getId()) ~= sgs.Player_PlaceHand)
								local log = sgs.LogMessage()
								log.type = "#Card_Recast" 
								log.from = player
								log.arg = self:objectName()
								room:sendLog(log)
								player:drawCards(1)
							end
							if not p:isKongcheng() then
								room:showAllCards(p)
							end
					end
							
				end
					
	
		end
	}
	
	
	xinkongmax = sgs.CreateMaxCardsSkill{
		name = "#xinkongmax" ,
		extra_func = function(self, player)
			if player:hasSkill("xinkong") and player:getMark("#xinkong_max") > 0 then
			   return 2
			end
		end,
	}
	
	
	paifa = sgs.CreateTriggerSkill{
		name = "paifa",
		frequency = sgs.Skill_Club,
		club_name = "nvking",
		events = {sgs.EventPhaseEnd},
		can_trigger = function(self, event, room, player, data)
			if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Start then
				for _,ShokuhouMisaki in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if player and player:isAlive() and not player:hasClub("nvking") and player:objectName() ~= ShokuhouMisaki:objectName() and ShokuhouMisaki:getMark("has_use_nvking-Clear"..player:objectName()) == 0 then----and player:getPhase() == sgs.Player_NotActive
						return self:objectName(), ShokuhouMisaki
					end
				end
			end
			return ""	
		end ,
		on_cost = function(self, event, room, player, data, ask_who)
			if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Start then
				local who = sgs.QVariant()
				who:setValue(player)
				if ask_who:askForSkillInvoke(self, who) then
					room:broadcastSkillInvoke(self:objectName(), ask_who)
					room:setPlayerMark(ask_who, "has_use_nvking-Clear"..player:objectName(), 1)
					return true
				end
			end
			return false
		end ,
		on_effect = function(self, event, room, player, data, ask_who)
			---room:doLightbox("paifa$", 999)
			if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Start then
				local who = sgs.QVariant()
				who:setValue(ask_who)
				local choice = room:askForChoice(player, self:objectName(), "paifa_accept+cancel", who)
				if choice == "paifa_accept" then
					player:addClub("nvking")
				end
			end
		
		end ,
	}
	
	paifatr = sgs.CreateTriggerSkill{
		name = "#paifatr",
		events = {sgs.TargetConfirming, sgs.EventPhaseEnd},
		on_record = function(self, event, room, player, data)
			if event == sgs.EventPhaseEnd then
				if player:getPhase() == sgs.Player_Finish then
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						 room:setPlayerMark(p, "&paifatr_used", 0)
					end 
				end	
			end		
		
		end,
		can_trigger = function(self, event, room, player, data)
			if event == sgs.TargetConfirming then
				local use = data:toCardUse()
				local players = room:findPlayersBySkillName(self:objectName())
					for _,sp in sgs.qlist(players) do
						if sp:isAlive() and sp:hasSkill(self:objectName()) and sp:hasSkill("paifa") and use.from and use.from:hasClub("nvking") and room:getCurrent():objectName() ~= use.from:objectName() and not use.card:isKindOf("SkillCard") and sp:getMark("&paifatr_used") < 1 then---and use.card:isKindOf("Slash") 
							return self:objectName(), sp
						end
					end
				
			end
			return ""
		end,
		on_cost = function(self, event, room, player, data, sp)
			local use = data:toCardUse()
			local dat = sgs.QVariant()
			dat:setValue(use.from)
			if sp:hasShownSkill("paifa") and sp:askForSkillInvoke(self, dat) then
				room:broadcastSkillInvoke("paifa", sp)
				room:setPlayerMark(sp, "&paifatr_used", 1)
				room:doLightbox("paifa$", 999)
				return true
			end
			return false
		end,
		on_effect = function(self, event, room, player, data, sp)
			if event == sgs.TargetConfirming then
			   local use = data:toCardUse()
			   local choice = room:askForChoice(sp, self:objectName(), "paifa_draw+paifa_recast")
				if choice == "paifa_draw" then
						if room:askForCard(sp, ".|.|.|.", "@paifa_discard", data, self:objectName())then
							  use.from:drawCards(1)
							  sp:drawCards(1)
						end	  
				elseif choice == "paifa_recast" then
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:hasClub("nvking") then
							local show_ids = room:askForExchange(p, self:objectName(), 1, 1, "&pf_recast", "", ".|.|.|.")
							local show_id = -1
							if show_ids:isEmpty() then
							   show_id = p:getCards("he"):first():getEffectiveId()
							else
							   show_id = show_ids:first()
							end
							local show = sgs.Sanguosha:getCard(show_id)
							if show then
								room:moveCardTo(show, nil, sgs.Player_DiscardPile, room:getCardPlace(show:getId()) ~= sgs.Player_PlaceHand)
								local log = sgs.LogMessage()
								log.type = "#Card_Recast" 
								log.from = p
								log.arg = self:objectName()
								room:sendLog(log)
								p:drawCards(1)
							end
						end
					end
				end
			end
		end
	}

ChahuiCard = sgs.CreateSkillCard{
   name = "ChahuiCard",
   filter = function(self, targets, to_select, Self)
	 return #targets == 0 and to_select ~= Self and not to_select:isKongcheng()
   end,
   extra_cost = function(self, room, use)
	local pd = sgs.PindianStruct()
	pd = use.from:pindianSelect(use.to:first(), "chahui")
	local d = sgs.QVariant()
	d:setValue(pd)
	use.from:setTag("chahuipindian", d)
   end,
   on_use=function(self,room,player,targets)	
	local pd = player:getTag("chahuipindian"):toPindian()
	player:removeTag("chahuipindian")
	if pd then
		local win = player:pindian(pd)
		local card1 = sgs.Sanguosha:getCard(pd.from_card:getEffectiveId())
        local card2 = sgs.Sanguosha:getCard(pd.to_card:getEffectiveId())
		if win then
           local x = card1:getNumber()-card2:getNumber()
		   while room:getDrawPile():length()<x do
			   room:swapPile()
		   end
		   local list = sgs.IntList()
		   for i=1 ,x ,1 do
               list:append(room:getDrawPile():at(i-1))
		   end
		   room:fillAG(list, player)
		   local id = -1
		   id = room:askForAG(player, list, true, "chahui")
		   room:clearAG(player)
		   if id > -1 then
			   local players = sgs.SPlayerList()
		       if player:isAlive() then players:append(player) end
			   if targets[1]:isAlive() then players:append(targets[1]) end
			   if players:length() == 0 then return end
			   local target = room:askForPlayerChosen(player, players, "chahui")
			   local card = sgs.Sanguosha:getCard(id)
			   local use = sgs.CardUseStruct()
			   use.from = player
			   use.card = card
			   use.to:append(target)
			   room:useCard(use, false)
		   end 
		else
			room:obtainCard(targets[1], card1)
		end
	end
   end,
}

Chahui=sgs.CreateZeroCardViewAsSkill{
	name="chahui",
	view_as = function(self)
		local card = 
		ChahuiCard:clone()
		card:setShowSkill(self:objectName())
		return card
	end,
	enabled_at_play=function(self,player)
		return not player:isKongcheng() and not player:hasUsed("ViewAsSkill_"..self:objectName().."Card")
	end,
}

function setLianwuLimitation(room, player, n)
    room:setPlayerMark(player, "#lianwumark", n)
	local max = 13
	for i = 1,999,1 do
        local c = sgs.Sanguosha:getCard(i)
		if c and c:getNumber()>max then max = c:getNumber() end 
	end
	local numbers = {}
	for i = n+1, max+1, 1 do
        table.insert(numbers, string.format("%d", i))
	end
	room:setPlayerCardLimitation(player, "use, response", ".|.|"..table.concat(numbers, ",").."|.", false)
end

function removeLianwuLimitation(room, player, n)
    room:setPlayerMark(player, "#lianwumark", 0)
	local max = 13
	for i = 1,999,1 do
        local c = sgs.Sanguosha:getCard(i)
		if c and c:getNumber()>max then max = c:getNumber() end 
	end
	local numbers = {}
	for i = n+1, max+1, 1 do
        table.insert(numbers, string.format("%d", i))
	end
	room:removePlayerCardLimitation(player, "use, response", ".|.|"..table.concat(numbers, ",").."|.")
end

Lianwu = sgs.CreateTriggerSkill{
	name = "lianwu",
	events = {sgs.DamageCaused, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
                for _,p in sgs.qlist(room:getAllPlayers(true)) do
					if p:getMark("#lianwumark") >0 then
                       removeLianwuLimitation(room, p, p:getMark("#lianwumark"))
					end
				end
			end
		end			
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if player:isAlive() and player:hasSkill(self:objectName()) and damage.card and damage.card:getNumber()>0 then
				return self:objectName()
			end			
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.DamageCaused then
	        local damage = data:toDamage()
			local x = damage.card:getNumber()
			if damage.to:getMark("#lianwumark") == 0 then
                setLianwuLimitation(room, damage.to, x)
			elseif x < damage.to:getMark("#lianwumark") then
                removeLianwuLimitation(room, damage.to, damage.to:getMark("#lianwumark"))
				setLianwuLimitation(room, damage.to, x)
			end
		end
	end
}

JilanCard = sgs.CreateSkillCard{
	mute = true,
	name = "JilanCard",
	filter = function(self, targets, to_select, Self)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("jilan")
		slash:deleteLater()
		local tos = sgs.PlayerList()
	    for _,p in ipairs(targets) do
		   tos:append(p)
	    end
        return slash:targetFilter(tos, to_select, Self)	
	end,
	on_use=function(self,room,player,targets)	
	   for _,p in ipairs(targets) do
           if not player:canSlash(p, nil, false) then
			   table.removeOne(targets, p)
		   end
	   end
	   local slash = sgs.Sanguosha:cloneCard("slash")
	   slash:setSkillName("jilan")
       local tos = sgs.SPlayerList()
	   for _,p in ipairs(targets) do
		   tos:append(p)
	   end
	   room:useCard(sgs.CardUseStruct(slash, player, tos))
	end
}

Jilanvs = sgs.CreateZeroCardViewAsSkill{
	name = "jilan",
	view_as = function(self)
		local vs = JilanCard:clone()
		vs:setShowSkill(self:objectName())	
		vs:setSkillName(self:objectName())		
		return vs 	
	end,
	enabled_at_play=function(self,player,pattern)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@jilan"
	end,
}

Jilan = sgs.CreateTriggerSkill{
	name = "jilan",
	events = {sgs.EventPhaseChanging},
	can_preshow = true,
	view_as_skill = Jilanvs,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if player:isAlive() and player:hasSkill(self:objectName()) and change.to == sgs.Player_Judge and not player:isSkipped(sgs.Player_Judge) and not player:isSkipped(sgs.Player_Draw) then
				return self:objectName()
			end			
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		local change = data:toPhaseChange()
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			player:skip(sgs.Player_Judge)
			player:skip(sgs.Player_Draw)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
		local judge = sgs.JudgeStruct()
		judge.good = false
		judge.who = player
		judge.reason = self:objectName()
		room:judge(judge)
		local da = sgs.QVariant()
		da:setValue(judge.card)
		local choice = room:askForChoice(player, self:objectName(), "jilan_obtain+jilan_slash", da)
		if choice == "jilan_obtain" then
			room:obtainCard(player, judge.card)
			local players = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				for _,c in sgs.qlist(p:getCards("ej")) do
					if c:getSuit() ~= judge.card:getSuit() then
						players:append(p)
						break
					end
				end
			end
			if not players:isEmpty() then
				room:setPlayerProperty(player, "jilan_card", da)
				local target = room:askForPlayerChosen(player, players, self:objectName(), "jilan-invoke", true, true)
				room:setPlayerProperty(player, "jilan_card", sgs.QVariant())
				if target then
                    local list = sgs.IntList()
					for _,c in sgs.qlist(target:getCards("ej")) do
						if c:getSuit() ~= judge.card:getSuit() then
							list:append(c:getEffectiveId())
						end
					end
					room:fillAG(list, player)
					local dat = sgs.QVariant()
					dat:setValue(target)
					room:setPlayerProperty(player, "jilan_target", dat)
					local id = room:askForAG(player, list, false, self:objectName())
					room:setPlayerProperty(player, "jilan_target", sgs.QVariant())	
					room:clearAG(player)
					room:obtainCard(player, id)
				end
			end
		else
            room:askForUseCard(player, "@@jilan", "@jilan")
		end
	end
}

ShenfengCard = sgs.CreateSkillCard{
	name = "ShenfengCard",
	filter = function(self, targets, to_select)
		return #targets == 0 and not to_select:isKongcheng()
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
			if p:isKongcheng() then continue end
			local list = p:handCards()
			--[[local blist = {}
            for _,i in sgs.qlist(list) do
				if not sgs.Sanguosha:getCard(i):isRed() then
					table.insert(blist, tostring(i))
				end
			end
			local dis = table.concat(blist, "+")]]
				local listA = sgs.IntList()
				if p:handCards():length() == 1 then
					--ids = room:askForCardsChosen(source, p, "h^true^none", "shenfeng")
					room:fillAG(list, source)
					local id = room:askForAG(source, list, true, "shenfeng")
					if id > -1 then listA:append(id) end
					room:clearAG(source)
				else
					local di = sgs.IntList()
					room:fillAG(list, source)
					local id1 = room:askForAG(source, list, true, "shenfeng")
					if id1 > -1 then
						listA:append(id1)
						di:append(id1)
					end
					room:clearAG(source)
					room:setPlayerProperty(source, "shenfeng_firstid", sgs.QVariant(id1+1))
                    room:fillAG(list, source, di)
					local id2 = room:askForAG(source, list, true, "shenfeng")
					if id2 > -1 then
						listA:append(id2)
					end
					room:clearAG(source)
					room:setPlayerProperty(source, "shenfeng_firstid", sgs.QVariant())
                    --ids = room:askForCardsChosen(source, p, "h^true^none|h^true^none", "shenfeng")
				end
				if listA:length() > 0 then
					local move = sgs.CardsMoveStruct()
					move.card_ids = listA
					move.to_place = sgs.Player_DiscardPile
					move.reason.m_reason = 0x33
					move.reason.m_playerId = source:objectName()
					move.reason.m_skillName = "shenfeng"
					room:moveCardsAtomic(move, true)
				end
				for _,i in sgs.qlist(listA) do
					local c = sgs.Sanguosha:getCard(i)
					if c:isKindOf("BasicCard") then
						p:drawCards(1)
					else
						source:drawCards(1)
					end
				end
		end
	end,
}

Shenfeng = sgs.CreateOneCardViewAsSkill{
name = "shenfeng",
view_filter = function(self, to_select)
	return not to_select:isEquipped()
end,
view_as = function(self, card)
	local vs = ShenfengCard:clone()
	vs:addSubcard(card)
	vs:setShowSkill(self:objectName())	
	vs:setSkillName(self:objectName())		
	return vs		
end,
enabled_at_play=function(self,player)
	return not player:hasUsed("ViewAsSkill_"..self:objectName().."Card")
end,
}

AoshaCard = sgs.CreateSkillCard{
    name = "AoshaCard",
    target_fixed = true,
    on_use = function(self, room, source, targets)
        local equipType = room:askForChoice(source, "aosha", "Weapon+Armor+Horse+OffensiveHorse+DefensiveHorse+Treasure")
        local pile = room:getDrawPile()
        local discard_pile = room:getDiscardPile()
        local equipCard
        for _, id in sgs.qlist(pile) do
            local card = sgs.Sanguosha:getCard(id)
            if card:isKindOf(equipType) then
                equipCard = card
                break
            end
        end
        
        if not equipCard then
            for _, id in sgs.qlist(discard_pile) do
                local card = sgs.Sanguosha:getCard(id)
                if card:isKindOf(equipType) then
                    equipCard = card
                    break
                end
            end
		end
        if equipCard then
            source:addToPile("throne", equipCard)
        end
    end,
}

Aoshavs = sgs.CreateViewAsSkill{
    name = "aosha",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isKindOf("BasicCard") and #selected == 0
    end,
    view_as = function(self, cards)
		if #cards == 0 then return nil end
		local throne = AoshaCard:clone()
		for var = 1, #cards, 1 do   
            throne:addSubcard(cards[var])                
        end   
        throne:setSkillName("aosha")
		throne:setShowSkill("aosha")
        return throne
    end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("ViewAsSkill_"..self:objectName().."Card") and player:getPile("throne"):isEmpty()
    end,
}

Aosha = sgs.CreateTriggerSkill{
	name = "aosha",
	view_as_skill = Aoshavs,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseChanging, sgs.CardUsed},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
			for _,p in sgs.qlist(room:getAlivePlayers()) do				
				if p:getMark("aosha_slash")>0 then
                    room:setPlayerMark(p, "aosha_slash", 0)
				end
			end
		end
		if event == sgs.CardUsed then
            local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:isBlack() then
				room:setPlayerMark(player, "aosha_slash", 1)
			end
		end
	end,    
	can_trigger = function(self, event, room, player, data)
		return ""
	end,
}

Aoshamod = sgs.CreateTargetModSkill{
	name = "#aoshamod",
	pattern = "Slash",
	residue_func = function(self,player,card)
	  if player:hasShownSkill("aosha") and player:getMark("aosha_slash")==0 and card:isBlack() then return 1 end
	  if player:hasShownSkill("aosha") and player:getMark("aosha_slash")>0 then return 1 end
	end,
    distance_limit_func  = function(self,player,card)
	  if player:hasShownSkill("aosha") and player:getMark("aosha_slash")==0 and card:isBlack() then return 1000 end
	end
}

Jiankaivs = sgs.CreateZeroCardViewAsSkill{
	name = "jiankai",
	view_as = function(self)
		local id = sgs.Self:property("jiankai_card"):toInt()-1
		if id < 0 then return nil end
		local vs = sgs.Sanguosha:getCard(id)
		if not vs then return nil end
		vs:setSkillName("jiankai")
		vs:setShowSkill("jiankai")
		return vs
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jiankai"
	end,
}

Jiankai = sgs.CreateTriggerSkill{
    name = "jiankai",
    events = {sgs.TargetConfirmed, sgs.EventPhaseChanging , sgs.EventPhaseStart},
	view_as_skill = Jiankaivs,
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.from == sgs.Player_Play then
				if player:hasFlag("jiankai_used") then
				  player:clearOnePrivatePile("throne")
				  room:setPlayerFlag(player, "-jiankai_used")
				end
			end
		end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            local card = use.card
            if player and player:isAlive() and player:hasSkill(self:objectName()) and card and card:isKindOf("Slash") and use.to:length() == 1 and use.from and use.from == player then
                local throne = player:getPile("throne")
                for _,id in sgs.qlist(throne) do
					local throneCard = sgs.Sanguosha:getCard(id)
					local target = use.to:at(0)
					if throneCard:isKindOf("Weapon") and not target:getCards("hej"):isEmpty() then
						return self:objectName() 
					elseif throneCard:isKindOf("Armor") or throneCard:isKindOf("Treasure") then
						return self:objectName()
					elseif throneCard:isKindOf("Horse") then
						if player:getHandcardNum() >= player:getHp() then
							return self:objectName()
						end
					end
				end
            end
        end
		if event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) then
            if player:isAlive() and player:hasSkill(self:objectName()) and not player:getPile("throne"):isEmpty() then
				return self:objectName()
			end
		end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp) --不能保证有“王座”时人物牌一定处于明置状态，所以按照严谨的触发技能逻辑写
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local target = use.to:at(0)
			local throne = player:getPile("throne")
			local discard,draw,hit
			for _,id in sgs.qlist(throne) do  --特殊情况如和其他技能联动“王座”可能有多张牌，所以按照描述按顺序分别询问。
				local throneCard = sgs.Sanguosha:getCard(id)
				local target = use.to:at(0)
				if throneCard:isKindOf("Weapon") and not target:getCards("hej"):isEmpty() then
					discard = true
				elseif throneCard:isKindOf("Armor") or throneCard:isKindOf("Treasure") then
					draw = true
				elseif throneCard:isKindOf("Horse") then
					if player:getHandcardNum() >= player:getHp() then
						hit = true
					end
				end
			end
			--按顺序询问，直到选择一个发动开始
			if discard and room:askForSkillInvoke(player, "jiankai_discard", data) then
				local id = room:askForCardChosen(player, target, "hej", self:objectName()) 
				room:setPlayerProperty(player, "jiankai_id", sgs.QVariant(id+1)) --不能保证亮将时有其他插入结算，所以要提前记录。注意int数据默认为0，所以这里id+1避免卡牌和trivial case重复
                room:setPlayerFlag(player, "jiankai_used")
				room:setPlayerFlag(player, "jiankai_discard")--不能保证亮将时有其他插入结算，所以要提前记录。
                room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
			if draw and room:askForSkillInvoke(player, "jiankai_draw", data) then
				room:setPlayerFlag(player, "jiankai_used")
				room:setPlayerFlag(player, "jiankai_draw")
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
			if hit and room:askForSkillInvoke(player, "jiankai_hit", data) then
				room:setPlayerFlag(player, "jiankai_used")
				room:setPlayerFlag(player, "jiankai_hit")
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end	
		end
		if event == sgs.EventPhaseStart then
            if player:askForSkillInvoke(self:objectName(), data) then
				local throne = player:getPile("throne")
				local dis = sgs.IntList()
				for _,id in sgs.qlist(throne) do
					local card = sgs.Sanguosha:getCard(id)
					if not card:isAvailable(player) then dis:append(id) end
				end
				room:fillAG(throne, player, dis)
				local id = room:askForAG(player, throne, true, self:objectName())
				room:clearAG(player)
				if id > -1 then
                    room:setPlayerProperty(player, "jiankai_card", sgs.QVariant(id+1))
					local card = room:askForUseCard(player, "@@jiankai", "@jiankai")
					room:setPlayerProperty(player, "jiankai_card", sgs.QVariant())
					if card then return true end
				end
			end
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local target = use.to:at(0)
			local throne = player:getPile("throne")
			local type = ""
			if player:hasFlag("jiankai_discard") then type = "discard" end
			if player:hasFlag("jiankai_draw") then type = "draw" end
			if player:hasFlag("jiankai_hit") then type = "hit" end
			if player:hasFlag("jiankai_discard") then room:setPlayerFlag(player, "-jiankai_discard") end --及时清空数据避免插入结算
			if player:hasFlag("jiankai_draw") then room:setPlayerFlag(player, "-jiankai_draw") end
			if player:hasFlag("jiankai_hit") then room:setPlayerFlag(player, "-jiankai_hit") end
			local discard,draw,hit --on_cost 里只发动一个效果所以这里要重新判断是否发动其他效果
			for _,id in sgs.qlist(throne) do
				local throneCard = sgs.Sanguosha:getCard(id)
				local target = use.to:at(0)
				if throneCard:isKindOf("Weapon") and not target:getCards("hej"):isEmpty() then
					discard = true
				elseif throneCard:isKindOf("Armor") or throneCard:isKindOf("Treasure") then
					draw = true
				elseif throneCard:isKindOf("Horse") then
					if player:getHandcardNum() >= player:getHp() then
						hit = true
					end
				end
			end
			if type == "discard" then --选择了武器类效果则直接发动
                local id = player:property("jiankai_id"):toInt() -1 --获取选择的卡牌
				if id > -1 then
					room:throwCard(id, target, player)
				end
				room:setPlayerProperty(player, "jiankai_id", sgs.QVariant()) --清空数据
			end
            if type == "draw" or (type == "discard" and draw and room:askForSkillInvoke(player, "jiankai_draw", data)) then --选择了防具、宝物类效果则直接发动，否则选择了武器效果的情况下满足条件则继续询问发动
                player:drawCards(1)
			end
			if type == "hit" or (hit and room:askForSkillInvoke(player, "jiankai_hit", data)) then --选择了坐骑类效果则直接发动，否则满足条件则继续询问发动
                local jink_list = player:getTag("Jink_" .. use.card:toString()):toList()
	            local index = use.to:indexOf(target)
                local log = sgs.LogMessage()
                log.type = "#jiankai_XD"
                log.from = target
                room:sendLog(log)
                jink_list:replace(index,sgs.QVariant(0))
		        player:setTag("Jink_" .. use.card:toString(), sgs.QVariant(jink_list))
			end
		end
	end
}

VshoujiCard = sgs.CreateSkillCard{
    name = "VshoujiCard",
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isNude()
    end,
    on_use = function(self, room, source, targets)
        for _,targetA in ipairs(targets) do
            local prompt = string.format("@vshouji:%s::%s:", source:objectName(), targetA:objectName())
            local cardA = room:askForCard(targetA, ".|.|.|.", prompt, sgs.QVariant(), sgs.Card_MethodNone, source, false, "vshouji")
            if cardA then
				room:obtainCard(source, cardA)
                local list = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(source)) do
					if p ~= targetA then list:append(p) end
				end
				local targetB = room:askForPlayerChosen(targetA, list, "vshouji", "@vshouji1", true, true)
				if targetB and not source:isKongcheng() then
					local cardId = room:askForCardChosen(source, source, "h", "vshouji")
					local cardB = sgs.Sanguosha:getCard(cardId)
					if cardB then
						room:obtainCard(targetB, cardB)
						if cardB:getSuit() == cardA:getSuit() or cardB:getNumber() == cardA:getNumber() then
							--can use cardB
						end
					end
				end
			end
		end
    end,
}

Vshouji = sgs.CreateZeroCardViewAsSkill{
	name = "vshouji",
	view_as = function(self)
		local vs = VshoujiCard:clone()
		vs:setShowSkill(self:objectName())	
		vs:setSkillName(self:objectName())		
		return vs 	
	end,
	enabled_at_play=function(self,player,pattern)
		return not player:hasUsed("ViewAsSkill_"..self:objectName().."Card")
	end,
}

Gongqing = sgs.CreateTriggerSkill{
	name = "gongqing",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local move = data:toMoveOneTime()
			if move.from and move.to and move.from:objectName() ~= move.to:objectName() and (move.to:objectName() == player:objectName() or move.from:objectName() == player:objectName()) and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.to_place == sgs.Player_PlaceHand and not room:getCurrent():hasFlag("gongqingUsed") and not player:isKongcheng() then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local move = data:toMoveOneTime()
		local who = sgs.QVariant()
		local target = (move.from:objectName() == player:objectName() and move.to) or move.from
		who:setValue(findPlayerByObjectName(target:objectName()))
		if player:askForSkillInvoke(self, who) and room:askForDiscard(player, self:objectName(), 1, 1) then
			room:getCurrent():setFlags("gongqingUsed")
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local move = data:toMoveOneTime()
		local target = (move.from:objectName() == player:objectName() and move.to) or move.from
		local dest = findPlayerByObjectName(target:objectName())
		local choice
		if not dest:isWounded() then
			choice = "gongqingDraw"
		else
			choice = room:askForChoice(player, self:objectName(), "gongqingDraw+gongqingRecover", data)
		end
		if choice == "gongqingDraw" then
			local a = dest:getMaxHp()-move.from:getHandcardNum()
			if a > 0 then
				dest:drawCards(math.min(a,5), self:objectName())
			end
		else
			local recover = sgs.RecoverStruct()
			recover.who = player
			recover.recover = 1
			room:recover(dest, recover, true) 
		end	
	end ,
}

XieyuCard = sgs.CreateSkillCard{
	mute = true,
	name = "XieyuCard",
	filter = function(self, targets, to_select, Self)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("xieyu")
		slash:deleteLater()
		local tos = sgs.PlayerList()
	    for _,p in ipairs(targets) do
		   tos:append(p)
	    end
        return slash:targetFilter(tos, to_select, Self)	
	end,
	on_use=function(self,room,player,targets)	
	   for _,p in ipairs(targets) do
           if not player:canSlash(p, nil, false) then
			   table.removeOne(targets, p)
		   end
	   end
	   local slash = sgs.Sanguosha:cloneCard("slash")
	   slash:setSkillName("xieyu")
       local tos = sgs.SPlayerList()
	   for _,p in ipairs(targets) do
		   tos:append(p)
	   end
	   room:useCard(sgs.CardUseStruct(slash, player, tos), false)
	end
}

Xieyuvs = sgs.CreateZeroCardViewAsSkill{
	name = "xieyu",
	view_as = function(self)
		local vs = JilanCard:clone()
		vs:setShowSkill(self:objectName())	
		vs:setSkillName(self:objectName())		
		return vs 	
	end,
	enabled_at_play=function(self,player,pattern)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@xieyu"
	end,
}

Xieyu = sgs.CreateTriggerSkill{
    name = "xieyu",
	view_as_skill = Xieyuvs,
    events = {sgs.CardUsed, sgs.CardFinished, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		if event ~= sgs.EventPhaseChanging then return end
	    local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive then
            for _,p in sgs.qlist(room:getAlivePlayers()) do
				room:removePlayerDisableShow(p, self:objectName())
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardUsed then
			local use = data:toCardUse()
			local male, has
			if player:hasShownGeneral1() and player:getActualGeneral1():isMale() then male = true end
			if player:hasShownGeneral2() and player:getActualGeneral2():isMale() then male = true end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getJudgingArea():length()>0 then has = true end
			end
            if player and player:isAlive() and player:hasSkill(self:objectName()) and use.card:isKindOf("Slash") and male and has then
				return self:objectName()
			end
        end
        if event == sgs.CardFinished then
			local use = data:toCardUse()
			local can
			if player:inHeadSkills(self) and player:hasShownGeneral2() then can = true end
			if not player:inHeadSkills(self) and player:hasShownGeneral1() then can = true end
            if player and player:isAlive() and player:hasSkill(self:objectName()) and use.card:isKindOf("Slash") and not room:getCurrent():hasFlag(player:objectName().."xieyu_used") and can then
				return self:objectName()
			end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
		if event == sgs.CardUsed then
			if player:askForSkillInvoke(self, data) then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getJudgingArea():length()>0 then targets:append(p) end
				end
				local target = room:askForPlayerChosen(player, targets, self:objectName(), "@xieyu1", true)
				if target then
					local id = room:askForCardChosen(player, target, "j", self:objectName())
					player:setProperty("xieyu_target", sgs.QVariant(target:objectName()))
					player:setProperty("xieyu_id", sgs.QVariant(id))
					room:broadcastSkillInvoke(self:objectName(), math.random(1,3), player)
					return true
				end
			end
		end
        if event == sgs.CardFinished then
			if player:askForSkillInvoke(self, data) then
				room:setPlayerFlag(room:getCurrent(), player:objectName().."xieyu_used")
				room:broadcastSkillInvoke(self:objectName(), 4, player)
				return true
			end
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
        if event == sgs.CardUsed then
			local use = data:toCardUse()
            local target = findPlayerByObjectName(player:property("xieyu_target"):toString())
			local id = player:property("xieyu_id"):toInt()
			if not target then return end
			player:setProperty("xieyu_target", sgs.QVariant())
			player:setProperty("xieyu_id", sgs.QVariant())
			room:doLightbox("xieyu$", 1000)
			if (target:getCards("j"):contains(sgs.Sanguosha:getWrappedCard(id))) then
				room:throwCard(id, target, player)
			end
			local targets = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if use.card:targetFilter(sgs.PlayerList(), p, player) and not use.to:contains(p) then targets:append(p) end
			end
			if not targets:isEmpty() then
				local extra = room:askForPlayerChosen(player, targets, self:objectName())
				use.to:append(extra)
				data:setValue(use)
			end
        end
        if event == sgs.CardFinished then
            room:loseHp(player)
            room:askForUseCard(player, "@@xieyu", "@xieyu")
			player:hideGeneral(not player:inHeadSkills(self:objectName()))
			room:setPlayerDisableShow(player, (player:inHeadSkills(self:objectName()) and "d") or "h", self:objectName())
        end
	end
}

Kuanghe = sgs.CreateTriggerSkill{
    name = "kuanghe",
    events = {sgs.EventPhaseChanging, sgs.Dying},
	on_record = function(self, event, room, player, data)
	    if event == sgs.Dying then
			local dying = data:toDying()
			if dying.damage and dying.damage.from and dying.damage.reason == self:objectName() and player == dying.damage.from then
                local choice = room:askForChoice(player, self:objectName(), "recover+draw")
                if choice == "recover" then
					local recover = sgs.RecoverStruct()
			        recover.who = player
			        room:recover(player, recover, true)
				elseif choice == "draw" then
					player:drawCards(1)
				end
			end
            return true
        end
	end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then
			local male
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_Play then return "" end
			if player:hasShownGeneral1() and player:getActualGeneral1():isMale() then male = true end
			if player:hasShownGeneral2() and player:getActualGeneral2():isMale() then male = true end
            if player and player:isAlive() and player:hasSkill(self:objectName()) and not male and player:getHandcardNum() >= room:alivePlayerCount() - 1 and (not player:isSkipped(sgs.Player_Play) or not player:isSkipped(sgs.Player_Discard))then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if event == sgs.EventPhaseChanging and player:askForSkillInvoke(self:objectName(), data) then
            room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("kuanghe$", 1500)
            return true
		end
    end,
    on_effect = function(self, event, room, player, data, sp)
        if event == sgs.EventPhaseChanging then
           player:throwAllHandCards()
		   if not player:isSkipped(sgs.Player_Play) then
			  player:skip(sgs.Player_Play)
		   end
		   if not player:isSkipped(sgs.Player_Discard) then
			  player:skip(sgs.Player_Discard)
		   end
		   local targets = room:getOtherPlayers(player)
		   room:sortByActionOrder(targets)
		   for _,p in sgs.qlist(targets) do
		      local da = sgs.DamageStruct()
			  da.from = player
			  da.to = p
			  da.reason = self:objectName()
			  room:damage(da)
		   end
        end
    end,
}

Aoshivs = sgs.CreateZeroCardViewAsSkill{
	name = "aoshi",
	view_as = function(self)
		local id = sgs.Self:property("aoshi_id"):toInt() -1
		if id < 0 then return nil end
		return sgs.Sanguosha:getCard(id)
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@aoshi"
	end,
}

Aoshi = sgs.CreateTriggerSkill{
	name = "aoshi",
	view_as_skill = Aoshivs,
    events = {sgs.EventPhaseStart, sgs.PindianVerifying},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase()==sgs.Player_Start and not player:isKongcheng() and player:getMark("#aoshi_null")==0 then
			local can
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if not p:isKongcheng() then
					can = true
				    break
				end
			end
		    if can then return self:objectName() end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
        local list = sgs.SPlayerList()
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		      if not p:isKongcheng() then
				list:append(p)		   
		      end
		    end
			local target 
			if player:askForSkillInvoke(self,data) then
			  target =  room:askForPlayerChosen(player, list, self:objectName(), "@aoshi1", true)
			end
			if target then
			  room:broadcastSkillInvoke(self:objectName(), player)
			  room:doLightbox("aoshi$", 1000)
			  local pd = player:pindianSelect(target, "aoshi")
			  local da = sgs.QVariant()
			  da:setValue(pd)
			  player:setProperty("aoshi_pd", da)
			  return true
			end
	end,
	on_effect = function(self, event, room, player, data, sp)
        local pd = player:property("aoshi_pd"):toPindian()
		player:setProperty("aoshi_pd", sgs.QVariant())
		if pd ~= nil then
			local target = pd.to
			local success = player:pindian(pd)
			local n1 = pd.from_number
			local n2 = pd.to_number
			local card1 = pd.from_card
            local card2 = pd.to_card
			pd = nil
			if success then
				local da = sgs.DamageStruct()
				da.from = player
				da.to = target
				room:damage(da)
				if (n1-n2)%2 == 0 then
                   local list = sgs.IntList()
				   local dis = sgs.IntList()
				   list:append(card1:getEffectiveId())
				   list:append(card2:getEffectiveId())
                   if not card1:isAvailable(player) then
					   dis:append(card1:getEffectiveId())
				   end
				   if not card2:isAvailable(player) then
					   dis:append(card2:getEffectiveId())
				   end
				   if list:length() > dis:length() then
					   room:fillAG(list, player, dis)
					   local id = room:askForAG(player, list, true, self:objectName())
                       room:clearAG(player)
					   if id > -1 then
						  room:setPlayerProperty(player, "aoshi_id", sgs.QVariant(id+1))
						  room:askForUseCard(player, "@@aoshi", "@aoshi:" .. tostring(sgs.Sanguosha:getCard(id):getName()))
						  room:setPlayerProperty(player, "aoshi_id", sgs.QVariant())
					   end
					end
				end
			else
				room:loseHp(player)
			end
		end
	end
}

Xinshang = sgs.CreateTriggerSkill{
	name = "xinshang",
    events = {sgs.HpLost},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.HpLost and player:isAlive() and player:hasSkill(self:objectName()) then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
        if event == sgs.HpLost and player:askForSkillInvoke(self,data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.HpLost then
           player:drawCards(1)
		end
	end
}	

gengzhong = sgs.CreateTriggerSkill{
	name = "gengzhong",
	events = {sgs.CardFinished, sgs.EventPhaseEnd, sgs.EventPhaseChanging, sgs.CardsMoveOneTime},
    on_record = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile and move.card_ids:length() > 0 and player:getPhase() == sgs.Player_Play then
                local players = room:findPlayersBySkillName(self:objectName())
                for _,p in sgs.qlist(players) do
                    if p == player then room:setPlayerMark(p, "gengzhong", p:getMark("gengzhong") + move.card_ids:length()) end
                end
            end
		end
        if event == sgs.EventPhaseChanging and player:getMark("gengzhong") > 0 then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "gengzhong", 0)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()			
			local players = room:findPlayersBySkillName(self:objectName())
			for _,p in sgs.qlist(players) do
				if (use.card:isKindOf("Peach") or use.card:isKindOf("Analeptic") or use.card:getSubtype() == "food_card") and use.card:getEffectiveId() > -1 and (p:objectName() == player:objectName() or (p:hasShownOneGeneral() and player:isFriendWith(p))) and p:getPile("paddy"):length() < 4 then
					return self:objectName(), p
				end
			end
		end
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Play and player:getPile("paddy"):length() > 0 and player:getMark("gengzhong") >= 3 then
                return self:objectName()
            end
        end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if room:askForSkillInvoke(ask_who, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
            ask_who:addToPile("paddy", use.card)
		end
        if event == sgs.EventPhaseEnd then
            local n = math.ceil(player:getMark("gengzhong")/3)
            if n <= 0 then return false end
            local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:isFriendWith(player) then
                    targets:append(p)
                end
            end
            for i = 1, n, 1 do
                if player:getPile("paddy"):length() <= 0 then return false end
                local to = room:askForPlayerChosen(player, targets, self:objectName(), "&gengzhong")
                local ids = sgs.IntList()
                for _, i in sgs.qlist(player:getPile("paddy")) do
                    ids:append(i)
                end
                room:fillAG(ids, to)
			    local id = room:askForAG(to, ids, false, self:objectName())
			    room:clearAG(to)
		        room:obtainCard(to, id)
            end
        end
	end,
}

zhilians = sgs.CreateTriggerSkill{
	name = "zhilians",
	events = {sgs.DamageInflicted},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if damage.to:isAlive() and damage.to:getMark("@lian")> 0 then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,MiyazonoKaori in sgs.qlist(players) do return self:objectName(), MiyazonoKaori end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		local damage = data:toDamage()
		local who = sgs.QVariant()
		who:setValue(damage.to)
		if ask_who:askForSkillInvoke(self, who) then room:broadcastSkillInvoke(self:objectName(), ask_who) return true end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local damage = data:toDamage()
		local x = damage.damage
		damage.to:drawCards(1)
		if ask_who then
		  local damage = sgs.DamageStruct()
		  damage.to = ask_who
		  room:damage(sgs.DamageStruct(self:objectName(), nil, ask_who, x))
		end  
	end,
}

zhiliansShown = sgs.CreateTriggerSkill{
	name = "#zhiliansShown" ,
	events = {sgs.GeneralShown},
	can_trigger = function(self, event, room, player, data)
	    if player and player:isAlive() and player:inHeadSkills(self) == data:toBool()and player:hasSkill("zhilians")and player:getMark("&zhilians_Shown") < 1then return self:objectName() end
		return ""
    end,
	on_cost=function(self,event,room,player,data)
        if player:hasShownSkill("zhilians") or player:askForSkillInvoke(self, data) then
		    room:setPlayerMark(player, "&zhilians_Shown", 1)
			room:broadcastSkillInvoke("zhilians",1)
			room:doLightbox("zhilians$", 1000)
            return true
		end
		return false
	end,
	on_effect=function(self, event, room, player, data)
	    if event == sgs.GeneralShown then
		    local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 1, 1, "@zhilians")
			for _,p in sgs.qlist(targets) do room:setPlayerMark(p, "@lian", 1) end
		end
		  
	end	   
} 

yixins = sgs.CreateTriggerSkill{
	name = "yixins",
	events = {sgs.Damaged, sgs.Dying, sgs.QuitDying, sgs.AskForPeachesDone, sgs.EventPhaseStart},
	on_record = function(self, event, room, player, data)
		if event == sgs.QuitDying then
			local dying = data:toDying()
			if player:hasSkill("yixins") and player == dying.who then
			    for _,p in sgs.qlist(room:getAlivePlayers()) do room:setPlayerMark(p, "##yixin_Current", 0) end  
			end
		end
		if event == sgs.AskForPeachesDone then
			local dying = data:toDying()
			if player:hasSkill("yixins") and player == dying.who and dying.who:getHp() < 1 then
				for _,sp in sgs.qlist(room:getAlivePlayers()) do
					if sp:getMark("##yixin_Current") > 0 and sp:getPile("yixin"):length()> 0 then
					    local choice = room:askForChoice(sp, "yixin", "@yixin_can+no")
			            if choice == "@yixin_can" then 
						    local dummy = sgs.DummyCard(sp:getPile("yixin"))
					        room:obtainCard(sp, dummy)
							room:broadcastSkillInvoke("yixins",4)
						end	
					end
				end
			end
        end
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Draw then
			for _,spl in sgs.qlist(room:getAlivePlayers()) do
				if spl:getPile("yixin"):length()> 0 and room:getCurrent():objectName() == spl:objectName() then
					local dummy = sgs.DummyCard(spl:getPile("yixin"))
					room:obtainCard(spl, dummy)
					room:setPlayerFlag(spl, "yixins_max")
					room:broadcastSkillInvoke("yixins",4)
				end	
			end
		end
	end ,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Damaged and player and player:isAlive() and player:hasSkill(self:objectName()) then return self:objectName() end
		if event == sgs.Dying then
			local dying = data:toDying()
			if player:hasSkill(self:objectName()) and player == dying.who then return self:objectName() end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("yixins") or player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:doLightbox("yixins$", 1000)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local x = player:getLostHp()
		player:drawCards(math.min(2,x), self:objectName())------player:drawCards(math.max(1,x), self:objectName())
		if not player:isNude() then
		    if player:getLostHp() ~= 0 then 
			    local cards = room:askForExchange(player, self:objectName(), x, 1, "&yixins", "", ".|.|.|.")
				if cards then
					local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 1, 1, "@yixins")
					for _,p in sgs.qlist(targets) do                  
						p:addToPile("yixin", cards, false)---p:addToPile("yixin", cards)
						if player:getHp() < 1 then room:setPlayerMark(p, "##yixin_Current", 1) end	
					end
			    end
			elseif player:getLostHp() == 0 then 
			    local cards = room:askForExchange(player, self:objectName(), 1, 1, "&yixins", "", ".|.|.|.")
                	if cards then
						local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 1, 1, "@yixins")
						for _,p in sgs.qlist(targets) do                  
							p:addToPile("yixin", cards, false)---p:addToPile("yixin", cards)
							if player:getHp() < 1 then room:setPlayerMark(p, "##yixin_Current", 1) end	
						end
					end			
			end   
           return false
		end
	end ,
}  

yixinsMaxCards = sgs.CreateMaxCardsSkill{
	name = "yixinsMaxCards" ,
	extra_func = function(self, player)
		if player:hasFlag("yixins_max") then return 1 end  return 0
	end
}

hezous = sgs.CreateTriggerSkill{
	name = "hezous",
	events = {sgs.EventPhaseStart, sgs.Death, sgs.CardUsed},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play then
			for _,sp in sgs.qlist(room:getAlivePlayers()) do
				if sp:getPile("huanzou"):length()> 0 and room:getCurrent():objectName() == sp:objectName() then
					local YP = sp:getPile("huanzou")
					local left = YP
					local Zlist = sp:getTag("huanzoucard"):toList()
					for _, card_id in sgs.qlist(YP) do Zlist:append(sgs.QVariant(card_id)) end
					if not Zlist:isEmpty() then
					   sp:setTag("huanzoucard", sgs.QVariant(Zlist))
					   local dummy = sgs.DummyCard(sp:getPile("huanzou"))
					   room:obtainCard(sp, dummy)
					   sp:setFlags("huanzou-Current")
					   room:doLightbox("hezous$", 1000)
					   room:broadcastSkillInvoke("hezous",2)
					end   
				end	
			end
		end
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
		    if use.card:isKindOf("SkillCard") then return end
			if use.from:hasFlag("huanzou-Current") then
				local Zlist = use.from:getTag("huanzoucard"):toList()
				if Zlist:contains(sgs.QVariant(use.card:getEffectiveId())) then
					 Zlist:removeOne(sgs.QVariant(use.card:getEffectiveId()))
					 use.from:setTag("huanzoucard", sgs.QVariant(Zlist))
					 room:addPlayerHistory(use.from, use.card:getClassName(),-1)
				end
			end	
		end
	end ,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Death then
		    local death = data:toDeath()
			if player:hasSkill(self:objectName())and player == death.who and not player:isNude() then
			    for _,spl in sgs.qlist(room:getAlivePlayers()) do
					if spl:getPile("yixin"):length()> 0 then return self:objectName() end	
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then 
		    room:broadcastSkillInvoke("hezous",1)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
	    local targetst = sgs.SPlayerList()
		for _,ps in sgs.qlist(room:getOtherPlayers(player)) do
			if ps:getPile("yixin"):length()> 0 then targetst:append(ps) end 
		end	
		local dy = room:askForPlayerChosen(player, targetst, self:objectName(), "@hezous", true, true)
		local dummy = sgs.DummyCard()
		for _,id in sgs.qlist(player:getCards("he")) do dummy:addSubcard(id) end
		dy:addToPile("huanzou", dummy)
		dummy:deleteLater()
	end,
}

Bingruo = sgs.CreateTriggerSkill{
    name = "bingruo",
    events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_RoundStart then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local key = sgs.Sanguosha:cloneCard("keyCard")
					if key:targetFilter(sgs.PlayerList(), p, player) then return self:objectName() end
				end
            end
        end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and change.to == sgs.Player_NotActive then
				local has
				local min = true
				for _,c in sgs.qlist(player:getJudgingArea()) do
					 if c:isKindOf("Key") then has = true end
				end
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				    if p:getHp()<player:getHp() then min = false end
				end
				if not has or not min then return "" end
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					local key = sgs.Sanguosha:cloneCard("keyCard")
					if key:targetFilter(sgs.PlayerList(), p, player) then return self:objectName() end
				end
            end
		end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if event == sgs.EventPhaseStart or event == sgs.EventPhaseChanging then
			local list = sgs.SPlayerList()
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				local key = sgs.Sanguosha:cloneCard("keyCard")
				if key:targetFilter(sgs.PlayerList(), p, player) then list:append(p) end
			end
			if player:askForSkillInvoke(self, data) then
				local dest = room:askForPlayerChosen(player, list, self:objectName(), "", true, true)
				if dest then
				   player:setProperty("bingruo_dest", sgs.QVariant(dest:objectName()))
				   local num = room:getTag("nagisa_voice"):toInt()
				   num = num + 1
				   room:setTag("nagisa_voice", sgs.QVariant(num))
				   room:broadcastSkillInvoke(self:objectName(), math.min(num, 40), player)
				   return true
				end
			end	
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.EventPhaseStart or event == sgs.EventPhaseChanging then
			local name = player:property("bingruo_dest"):toString()
			local dest = findPlayerByObjectName(name)
			if not dest or dest:isDead() then return end
			player:setProperty("bingruo_dest", sgs.QVariant())
			local card
			local cards = {}
			for _,i in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(i):getSuitString() == "heart" then
					table.insert(cards, sgs.Sanguosha:getCard(i))
				end
			end
			if #cards == 0 then return end
			card = cards[math.random(1,#cards)]
			local key = sgs.Sanguosha:cloneCard("keyCard")
			local id = card:getId()
			local wrapped = sgs.Sanguosha:getWrappedCard(id)
			wrapped:takeOver(key)
			wrapped:setSkillName(self:objectName())
			room:moveCardTo(wrapped, player, dest, sgs.Player_PlaceDelayedTrick,
				 sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
				 player:objectName(), self:objectName(), ""))

				 if event == sgs.EventPhaseChanging then return end
	
				 local has
				 for _,c in sgs.qlist(player:getJudgingArea()) do
					 if c:isKindOf("Key") then has = true end
				 end
				 if not has then
					room:loseHp(player)
					if player:isDead() then return end
					local card
					local cards = {}
					for _,i in sgs.qlist(room:getDrawPile()) do
						if sgs.Sanguosha:getCard(i):getSuitString() == "heart" then
							table.insert(cards, sgs.Sanguosha:getCard(i))
						end
					end
					if #cards == 0 then return end
					card = cards[math.random(1,#cards)]
					local key = sgs.Sanguosha:cloneCard("keyCard")
					local id = card:getId()
					local wrapped = sgs.Sanguosha:getWrappedCard(id)
					wrapped:takeOver(key)
					wrapped:setSkillName(self:objectName())
					room:moveCardTo(wrapped, player, player, sgs.Player_PlaceDelayedTrick,
						 sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
						 player:objectName(), self:objectName(), ""))
				 end
		end
	end
}

Yanju = sgs.CreateTriggerSkill{
    name = "yanju",
    events = {sgs.CardsMoveOneTime, sgs.AskForRetrial},
	frequency = sgs.Skill_Club,
	club_name = "yanjubu",
	on_record = function(self, event, room, player, data)
		if event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if player == judge.who and player:hasClub("yanjubu") and judge.card:isRed() and judge.reason == "keyCard" then
				judge.pattern = ".|red|."
				judge:updateResult()
				local msg = sgs.LogMessage()
				msg.from = player
				msg.type = "#YanjubuEffect"
				msg.arg = "yanjubu"
				room:sendLog(msg)
			end
		end
    end,
    can_trigger = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local can
			for _,i in sgs.qlist(move.card_ids) do
				local wrapped = sgs.Sanguosha:getWrappedCard(i)
				if wrapped:isKindOf("Key") then can = true end
			end
			if player and player:isAlive() and player:hasSkill(self:objectName()) and can and move.to and move.to:objectName() ~= player:objectName() and not move.to:hasClub("yanjubu") and move.to_place == sgs.Player_PlaceDelayedTrick then
				return self:objectName()
			end
	    end
        return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local who = sgs.QVariant()
			who:setValue(findPlayerByObjectName(move.to:objectName()))
			if player:askForSkillInvoke(self, who) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local who = sgs.QVariant()
			who:setValue(player)
			local choice = room:askForChoice(findPlayerByObjectName(move.to:objectName()), self:objectName(), "yanju_accept+cancel", who)
			if choice == "yanju_accept" then
				findPlayerByObjectName(move.to:objectName()):addClub("yanjubu")
			end
		end
	end
}

Xiyuan = sgs.CreateTriggerSkill{
    name = "xiyuan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@xiyuan",
    events = {sgs.EventAcquireSkill, sgs.AskForPeachesDone},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventAcquireSkill then
			if data:toString():split(":")[1] == self:objectName() then
				room:broadcastSkillInvoke(self:objectName(), 4, player)
                room:doLightbox("DaoluA$", 3000)
			end
		end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.AskForPeachesDone then
            if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getHp()<1 and player:getMark("@xiyuan")> 0 then
				return self:objectName()
			end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
		if event == sgs.AskForPeachesDone then
			if player:askForSkillInvoke(self, data) then
				player:loseMark("@xiyuan")
				room:broadcastSkillInvoke(self:objectName(), math.random(1,3), player)
				return true
			end
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.AskForPeachesDone then
			local head, deputy
			if player:getActualGeneral1Name() == "Nagisa" then head = true end
			if player:getActualGeneral2Name() == "Nagisa" then deputy = true end
			if head or deputy then
				room:doLightbox("xiyuan$", 3000)
			end
			if head then
				player:showGeneral(true)
				room:transformHeadGeneralTo(player, "Ushio")
			end
			if deputy then
				player:showGeneral(false)
				room:transformDeputyGeneralTo(player, "Ushio")
			end
			if (head or deputy) and not table.contains(room:getUsedGeneral(), "Nagisa") then
				room:handleUsedGeneral("Nagisa")
			end
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover, true)
		end
	end
}

Dingxin = sgs.CreateTriggerSkill{
    name = "dingxin",
	frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseStart, sgs.Dying},
    can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then
				return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if event == sgs.EventPhaseStart then
			if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
				if player:getHp()>1 then
					local num = room:getTag("nagisa_voice"):toInt()
					num = num + 1
					room:setTag("nagisa_voice", sgs.QVariant(num))
					if num > 16 then
						room:broadcastSkillInvoke(self:objectName(), math.random(0, 4)+12, player)
					else
						room:broadcastSkillInvoke(self:objectName(), num, player)
					end
				end
				return true
			end	
		end
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.EventPhaseStart then
			room:loseHp(player)
			if player:isDead() then return end
			local card
			local cards = {}
			for _,i in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(i):getSuitString() == "heart" then
					table.insert(cards, sgs.Sanguosha:getCard(i))
				end
			end
			if #cards == 0 then return end
			card = cards[math.random(1,#cards)]
			local key = sgs.Sanguosha:cloneCard("keyCard")
			local id = card:getId()
			local wrapped = sgs.Sanguosha:getWrappedCard(id)
			wrapped:takeOver(key)
			wrapped:setSkillName(self:objectName())
			room:moveCardTo(wrapped, player, player, sgs.Player_PlaceDelayedTrick,
				 sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,
				 player:objectName(), self:objectName(), ""))
		end
	end
}

KMegumi:addSkill(Dicun)
KMegumi:addSkill(Yuanyu)
Sakuta:addSkill(Shuaiyan)
Sakuta:addSkill(Shangxian)
Zero:addSkill(Zhufa)
Zero:addSkill(Fashufengyin)
Zero:addSkill(Liqi)
Chulainn:addSkill(Bishi)
Chulainn:addSkill(Cichuan)
Hei:addSkill(Yingdi)
Hei:addSkill(Diansuo)
Hei:addRelateSkill("jiesha")
Shino:addSkill(Sjuji)
Shino:addSkill(Jianyu)
sgs.insertRelatedSkills(extension, "sjuji", "#sjuji_dis")
Shino:addCompanion("Kirito")
Kuon:addSkill(Yaoshi)
Kuon:addSkill(Shenxue)
PYuuki:addSkill(Pquanneng)
PYuuki:addSkill(Plianjie)
PYuuki:setHeadMaxHpAdjustedValue()
KMisuzu:addSkill(Jiaozhi)
KMisuzu:addSkill(Mjianshi)
Fumika:addSkill(Youji)
Fumika:addSkill(Songxin)
Sanya:addSkill(Tancha)
Sanya:addSkill(Boxi)
Estelle:addSkill(Fenglun)
Houtarou:addSkill(Linggan)
Houtarou:addSkill(Jieneng)
Houtarou:addSkill(Tuili)
Kuuhaku:addSkill(Youzheng)
Kuuhaku:addSkill(Sorazhi)
Kuuhaku:addSkill(Shiroshi)
Tatsumi:addSkill(Lizhan)
Tatsumi:addSkill(Caokai)
Tatsumi:addSkill(Longhua)
Sakuya:addSkill(Huanshen)
Sakuya:addSkill(Sshiji)
Nagi:addSkill(Tianzi)
Nagi:addSkill(Yuzhai)
TokidoSaya:addSkill(Qiangdou)
TokidoSaya:addSkill(Qiangji)
TokidoSaya:addSkill(Jiaoti)
Kotori:addSkill(Zhuogui)
Kotori:addSkill(Tongyu)
Emilia:addSkill(Bingshu)
Emilia:addSkill(Lingshi)
Emilia:addSkill(Bingfeng)
Kuroko:addSkill(Shunshan)
Kuroko:addSkill(Dingshen)
Chiyuri:addSkill(Huanyuan)
Chiyuri:addSkill(Chengling)
--Kaneki:addSkill(Shiyu)
--Kaneki:addSkill(Banhe)
Rean:addSkill(Huanqi)
Rean:addSkill(Rwuren)
Rean:addSkill(Jueye)
Rean:setHeadMaxHpAdjustedValue()
Zuikaku:addSkill(Youdiz)
Zuikaku:addSkill(Eryu)
Natsume_Rin:addSkill(Maoqun)
Natsume_Rin:addSkill(Pasheng)
Natsume_Rin:addSkill(Rinjiuyuan)
Ryuuichi:addSkill(Quzheng)
Ryuuichi:addSkill(Nizhuan)
Ryuuichi:addSkill(Yanshen)
Ryuuichi:setHeadMaxHpAdjustedValue()
Chtholly:addSkill(Ranxin)
Chtholly:addSkill(Chiyi)
Yato:addSkill(Shenqi)
Yato:addSkill(Huojin)
Yato:addSkill(Zhanyuan)
Neko:addSkill(Moshi)
Neko:addSkill(Nekojiyi)
Oumashu:addSkill(Void)
Oumashu:addSkill(Wangguo)
Oumashu:setHeadMaxHpAdjustedValue()
Joshua:addSkill(Huanxi)
Joshua:addSkill(Jjueying)
Fegor:addSkill(yizhigame)
Fegor:addSkill(sibie)
SKaguya:addSkill(Slianji)
SKaguya:addSkill(Jinchi)
Saki:addSkill(Lingshang)
Saki:addSkill(LingshangMaxCards)
sgs.insertRelatedSkills(extension, "lingshang", "#lingshangMaxCards")
Saki:addSkill(Guiling)
Megumin:addSkill(Baolie)
Megumin:addSkill(Yinchang)
Lucy:addSkill(xingling)
Lucy:addSkill(xinglingShown)
sgs.insertRelatedSkills(extension, "xingling", "#xinglingShown")
Lucy:addSkill(lingqi)
ShionNezumi:addSkill(Kangshi)
ShionNezumi:addSkill(Qingban)
ShokuhouMisaki:addSkill(xinkong)
ShokuhouMisaki:addSkill(paifa)
ShokuhouMisaki:addSkill(paifatr)
sgs.insertRelatedSkills(extension, "paifa", "#paifatr")
Renne:addSkill(Chahui)
Renne:addSkill(Lianwu)
ShameimaruAya:addSkill(Jilan)
ShameimaruAya:addSkill(Shenfeng)
Tohka:addSkill(Aosha)
Tohka:addSkill(Jiankai)
sgs.insertRelatedSkills(extension, "aosha", "#aoshamod")
Violet:addSkill(Vshouji)
Violet:addSkill(Gongqing)
ZeroTwo:addSkill(Xieyu)
ZeroTwo:addSkill(Kuanghe)
Asuka:addSkill(Aoshi)
Asuka:addSkill(Xinshang)
Sakunahime:addSkill(gengzhong)
MiyazonoKaori:addSkill(zhilians)
MiyazonoKaori:addSkill(zhiliansShown)
sgs.insertRelatedSkills(extension, "zhilians", "#zhiliansShown")
MiyazonoKaori:addSkill(yixins)
MiyazonoKaori:addSkill(hezous)
Nagisa:addSkill(Bingruo)
Nagisa:addSkill(Yanju)
Nagisa:addRelateSkill("xiyuan")
extension:insertCompanionSkill("Tomoya","Nagisa","xiyuan")
Ushio:addSkill(Dingxin)

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("UseDefaultSkin") then skills:append(UseDefaultSkin) end
if not sgs.Sanguosha:getSkill("#sjuji_dis") then skills:append(SjujiDis) end
if not sgs.Sanguosha:getSkill("#pquannengmax") then skills:append(Pquannengmax) end
if not sgs.Sanguosha:getSkill("mjianshiglobal") then skills:append(MjianshiGlobal) end
if not sgs.Sanguosha:getSkill("#youjimax") then skills:append(Youjimax) end
if not sgs.Sanguosha:getSkill("#jienengmax") then skills:append(Jienengmax) end
if not sgs.Sanguosha:getSkill("#linggantri") then skills:append(Linggantri) end
if not sgs.Sanguosha:getSkill("#lizhanmax") then skills:append(Lizhanmax) end
if not sgs.Sanguosha:getSkill("#caokaitr") then skills:append(Caokaitr) end
if not sgs.Sanguosha:getSkill("#shijitr") then skills:append(Shijitr) end
if not sgs.Sanguosha:getSkill("#qiangdoujuli") then skills:append(Qiangdoujuli) end
if not sgs.Sanguosha:getSkill("#jt_tri") then skills:append(Jt_tri) end
if not sgs.Sanguosha:getSkill("#tianzi-maxcard") then skills:append(TianziMaxCards) end
if not sgs.Sanguosha:getSkill("#bs-mod") then skills:append(BingshuMod) end
if not sgs.Sanguosha:getSkill("#dingshen-keep") then skills:append(DingshenKeep) end
if not sgs.Sanguosha:getSkill("#dingshen-stopped") then skills:append(DingshenStopped) end
if not sgs.Sanguosha:getSkill("#moshimax") then skills:append(Moshimax) end
if not sgs.Sanguosha:getSkill("jiesha") then skills:append(Jiesha) end
if not sgs.Sanguosha:getSkill("#ranxintr") then skills:append(Ranxintr) end
if not sgs.Sanguosha:getSkill("#huanxidis") then skills:append(Huanxidis) end
if not sgs.Sanguosha:getSkill("huanxieffect") then skills:append(Huanxieffect) end
--if not sgs.Sanguosha:getSkill("#youdiz-mod") then skills:append(YoudizMod) end
if not sgs.Sanguosha:getSkill("#yizhigameKeep") then skills:append(yizhigameKeep) end
if not sgs.Sanguosha:getSkill("#yizhigamechusha") then skills:append(yizhigamechusha) end
if not sgs.Sanguosha:getSkill("#voidmod") then skills:append(VoidMod) end
if not sgs.Sanguosha:getSkill("#maoqun-maxcard") then skills:append(MaoqunMaxCards) end
if not sgs.Sanguosha:getSkill("#xinkongmax") then skills:append(xinkongmax) end
if not sgs.Sanguosha:getSkill("guilingglobal") then skills:append(Guilingglobal) end
if not sgs.Sanguosha:getSkill("#aoshamod") then skills:append(Aoshamod) end
if not sgs.Sanguosha:getSkill("xiyuan") then skills:append(Xiyuan) end
if not sgs.Sanguosha:getSkill("yixinsMaxCards") then skills:append(yixinsMaxCards) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
  ["herobattle"] = "诸神之章",
  ["choose_ban_kingdom"] = "选择一个禁用势力",
  ["random"] = "随机",
  ["bankingdomreal"] = "本局禁用现世势力",
  ["bankingdommagic"] = "本局禁用魔法势力",
  ["bankingdomscience"] = "本局禁用科学势力",
  ["bankingdomgame"] = "本局禁用游戏势力",
  ["bankingdomidol"] = "本局禁用偶像势力",

  ["#bankingdomreal"] = "<font color = '#F5ED07'><b>本局禁用现世势力</b></font>",
  ["#bankingdommagic"] = "<font color = '#F00C95'><b>本局禁用魔法势力</b></font>",
  ["#bankingdomscience"] = "<font color = '#615E5D'><b>本局禁用科学势力</b></font>",
  ["#bankingdomgame"] = "<font color = '#0CF0EC'><b>本局禁用游戏势力</b></font>",
  ["#bankingdomidol"] = "<font color = '#FF9EAC'><b>本局禁用偶像势力</b></font>",
	
  ["KMegumi"] = "加藤惠",
  ["@KMegumi"] = "路人女主的養成方法",
  ["#KMegumi"] = "圣人惠",
  ["~KMegumi"] = "但是~我才不管那些，伦也同学~是属于我的。",
  ["designer:KMegumi"] = "FlameHaze",
  ["cv:KMegumi"] = "安野希世乃",
  ["dicun"] = "低存",
  ["$dicun1"] = "啊~现在插嘴是不是不太好？",
  ["$dicun2"] = "我是不是该说句‘离伦也远点，你这偷腥猫’",
  [":dicun"] = "当你成为基本牌，普通锦囊牌的目标后，若你不是此牌的唯一目标，你可以令此牌对你取消之，摸一张牌，并进入存在缺失状态。",
  ["yuanyu"] = "缘遇",
  ["$yuanyu1"] = "伦也：那天~我与命运相遇了",
  ["$yuanyu2"] = "抱歉。不小心看到了",
  ["$yuanyu3"] = "有没有感受到那种仿佛喜欢上现实女生一般的....呼吸困难、内心焦躁，还有.....心跳加速呢？",
  [":yuanyu"] = "每轮限一次，当你的牌因弃置进入弃牌堆时，你可以选择其中一张记为“缘遇”牌并与牌堆顶五张牌以任意顺序置于牌堆顶。一名其他角色使用对应实体牌为“缘遇”牌的非技能牌时，清除此牌“缘遇”记录，然后你摸3张牌并可以交给其任意张牌。",
  ["@yuanyu"] = "交给该角色任意张牌", 
  ["%KMegumi"] = "“所以加油啊，伦也君！把我变成所有人都羨慕的幸福的女主角啊”",
  
  ["Sakuta"] = "梓川咲太",
  ["@Sakuta"] = "青春猪头少年系列",
  ["#Sakuta"] = "大师傅",
  ["designer:Sakuta"] = "光临长夜",
  ["cv:Sakuta"] = "石川界人",
  ["shuaiyan"] = "率言",
  [":shuaiyan"] = "回合内限一次，当你使用非技能牌指定一名其他角色为唯一目标后，你可以获得其区域内的一张牌，然后若其存活且与你势力相同，你摸一张牌，若其存活且其为女性，其摸一张牌。",
  ["shangxian"] = "伤现",
  [":shangxian"] = "一名其他角色受到伤害后，若你即将与其势力相同，且其“伤现牌”数量小于其体力上限，你可以受到一点无来源伤害，随机展示一个场上不存在的带“现世”标签的人物牌，其选择此牌一个技能获得之并将此牌置于人物牌上记为“伤现牌”。永久效果：一名角色于其回合内回复体力时，其选择失去一个以此法获得的技能并将对应“伤现牌”移出游戏。",
  ["shangxiangeneralcard"] = "伤现牌", 
  ["%Sakuta"] = "“我只要有一个人喜欢我就够了。就算全世界都嫌弃我，只要那个人需要我，我就能活下去”",

  ["KMisuzu"] = "神尾观铃",
  ["@KMisuzu"] = "AIR",
  ["#KMisuzu"] = "翼人之继承者",
  ["designer:KMisuzu"] = "晴空",
  ["cv:KMisuzu"] = "川上伦子",
  ["~KMisuzu"] = "因为我已不再是孤零零一个人了。所以，所以……已经可以结束了。（不可以！才刚刚开始的！我不是说了才刚刚开始的吗！）终点……",
  ["jiaozhi"] = "交织",
  [":jiaozhi"] = "准备阶段开始时，你可以选择场上最多x+1名角色，依次执行：若其判定区有“键”，则令其摸一张牌，否则你选择其一张牌将其视为“键”置于其判定区（x为你本局游戏永久跳过阶段数）。",
  ["mjianshi"] = "渐失",
  [":mjianshi"] = "出牌阶段限一次，你可以选择永久跳过一个判定/摸牌/出牌/弃牌阶段(下次进入该阶段时生效，需有明置的此技能才生效)，并选择场上一名其他玩家，选择一项： 1，其下个回合开始时获得一个该阶段。 2，其下次执行此阶段时跳过该阶段；然后你选择你或其摸x张牌(x为你本局游戏永久跳过阶段数)。锁定技，回合结束时，若你{手牌数}大于{你手牌上限+1}，你选择弃置2张手牌或失去一点体力。",
  ["@jiaozhi"] = "交织：选择角色",
  ["Judge"] = "判定阶段",
  ["Draw"] = "摸牌阶段",
  ["Play"] = "出牌阶段",
  ["Discard"] = "弃牌阶段",
  ["mjianshi_gain"] = "该角色下回合开始时获得此阶段",
  ["mjianshi_skip"] = "该角色下次跳过此阶段",
  ["$mjianshi"] = "%from 选择永久跳过 %arg",
  ["$mjianshi_gain"] = "%from 下回合开始时将获得一个额外的 %arg",
  ["$mjianshi_skip"] = "%from 下次将跳过 %arg",
  ["@mjianshi"] = "选择一名角色（摸牌）",
  ["$mjianshi1"] = "我昨晚也做了一个梦。（梦···？如果你真的做梦，情况不妙哦...）没事，哪里都不疼。",
  ["$mjianshi2"] = "我的梦今天结束了。（真的吗？真的什么都没有吗 ？哪里都不疼吗？）没事，ブイ～",
  ["%KMisuzu"] = "“很浪漫吧，想到自己能够翱翔于天际，就会觉得心胸爽朗”",

  ["Nagi"] = "三千院凪", 
	["#Nagi"] = "千金御宅",
	["@Nagi"] = "旋风管家", 	
	["~Nagi"] = "啊。啊。。。不行了，再也不行了。。。", 
	["designer:Nagi"] = "钉子",
	["cv:Nagi"] = "釘宮理惠",

	["tianzi"] = "天资",
	[":tianzi"] = "摸牌阶段，你可以额外摸一张牌。①：出牌阶段限一次，你可以令此回合内你的手牌上限-1。锁定技，此回合的弃牌阶段结束时，若你执行了①，你摸等同于此阶段内弃置的锦囊牌的张数的牌并展示之。",
	["@tianzi_draw"] = "天资",

	["yuzhai"] = "御宅",
	[":yuzhai"] = "结束阶段开始时，若于此回合内你弃置的牌的张数大于你的体力值，你可以弃置场上任意名其他角色0~X张牌（X为你弃置的牌数与当前体力值数的差且至多为3）。",
	["@yuzhai_cards"] = "御宅计数",
	["yuzhai-invoke"] = "请选择一名其他角色，发动“御宅”",
	["$tianzi1"] = "啊，好，决定了！",
    ["$tianzi2"] = "难以相信，要不要试试看呢",
    ["$yuzhai1"] = "总而言之，这样的下雨天学校什么的最讨厌啦",
    ["$yuzhai2"] = "去了学校又要浪费一天时间",
	["%Nagi"] = "“啊，好，决定了！”",
	
	["Zero"] = "零",
  ["@Zero"] = "从零开始的魔法书",
  ["#Zero"] = "泥暗之魔女",
  ["designer:Zero"] = "光临长夜",
  ["cv:Zero"] = "花守由美里",
  ["zhufa"] = "著法「零之书」",
  [":zhufa"] = "每回合限一次，当你使用一张普通锦囊牌时，你可以记录此牌名称并发动一次单体势力召唤，若有人响应，其获得此牌。出牌阶段限一次，你可以将一张手牌当作一张记录牌使用。",
  ["fashufengyin"] = "封印「法书封印」",
  [":fashufengyin"] = "一名其他角色使用一张指定目标的“著法”记录牌名的牌时，你可以弃置一张牌，令此牌无效。",
  ["liqi"] = "立契",
  [":liqi"] = "限定技，出牌阶段，你可以指定一名势力相同的其他角色；永久效果：该角色受到不为“实体杀”造成的伤害时，你代为承受该伤害；你/其的出牌阶段开始时，其/你可以选择自己一张牌交给你/其。",
  ["@liqi"] = "立契",
  ["@liqi_dest"] = "佣兵",
  ["liqieffect"] = "立契",
  ["%Zero"] = "“吾辈觉得能与你相遇真是太好了”",
  
  ["Chulainn"] = "库·丘林",
  ["@Chulainn"] = "Fate Stay Night",
  ["#Chulainn"] = "光之子",
  ["designer:Chulainn"] = "网瘾少年",
  ["cv:Chulainn"] = "神奈延年",
  ["~Chulainn"] = "哼，小丫头片子，等你长大点再来吧",
  ["bishi"] = "避矢",
  [":bishi"] = "当你受到其他角色对你造成的伤害时，若其与你的距离大于1且此人物牌明置，你可以选择暗置该人物牌，防止此伤害。",
  ["cichuan"] = "刺穿「Gáe Bolg」",
  [":cichuan"] = "结束阶段结束时，你可以展示你手牌中一张♦牌并指定一名攻击范围内人物牌上没有“枪”的其他角色，你对其造成一点伤害，若该角色存活，你将此牌置于该角色人物牌上，称为“枪”。永久效果：当人物牌上存在“枪”的角色回复体力时，弃置人物牌上的第一张“枪”，取消之。",
  ["qiang"] = "枪",
  ["@cichuan"] = "刺穿「Gáe Bolg」",
  ["~cichuan"] = "展示一张♦牌并选择一名攻击范围内的其他角色",
  ["%Chulainn"] = "“这样一来，总算是能使出一点真本事了”",
  ["$cichuan"] = "Gáe Bolg",

    ["yingdi"] = "影帝",
	[":yingdi"] = "锁定技，当你成为“杀”或“相爱相杀”的目标时，若你手牌数为场上最少，取消之。准备阶段开始时，若此人物牌明置且场上所有角色有明置牌，势力数不超过2，你失去此技能，获得技能“截杀”。",
	["$yingdi1"] = "我才搬到这边...什么也....",
	["$yingdi2"] = "我是刚搬到附近的李舜生。",
	["$yingdi3"] = "我叫李舜生，还没做过自我介绍吧。",
	["$yingdi4"] = "告诉组织。不管你们有什么企图，我都一定会将其击溃。",
	["$jiesha_effect"] = "%from 受到“截杀”的影响，无法响应 %arg 的效果。",
	["@real_hei"] = "黑的真面目",
	["jiesha"] = "截杀",
	["$jiesha1"] = "（扔匕首）",
	["$jiesha2"] = "...去死吧。",
	["$jiesha3"] = "速度还是我在你之上啊。",
	[":jiesha"] = "锁定技，若你装备有【双刃刀】，你的【杀】不可闪避。",
	["diansuo"] = "电索",
	["$diansuo1"] = "(放电)",
	["$diansuo2"] = "（绳索，放电）",
	["$diansuo3"] = "告诉组织。不管你们有什么企图，我都一定会将其击溃。",
	[":diansuo"] = "你造成伤害时，若你不处于连环状态，可令你与一名其他不处于连环状态的角色进入连环状态，视为其造成了此伤害。其他角色造成伤害时，若你处于连环状态，可解除你与一名其他处于连环状态的角色的连环状态，视为其受到了此伤害。",
	["@diansuo-prompt"] = "选择一名其他不处于连环状态的角色，你令你和其进入连环状态，视为该角色造成了此伤害。",
	["@diansuo-prompt-remove"] = "选择一名其他处于连环状态的角色，解除你和其的连环状态的角色的连环状态，视为其受到了此伤害。",
	["hei"] = "黑",
	["@hei"] = "黑之契约者",
	["#hei"] = "黒の契約者",
	["~hei"] = "再见，各位。再见，琥珀。",
	["designer:hei"] = "Sword Elucidator",
	["cv:hei"] = "木内秀信",
	["illustrator:hei"] = "",
	["$diansuo_effect"] = "%from 受到「电锁」的影响， 代替 %arg 成为 %arg2 的目标。",
	["$diansuo_source_change"] = "%from 受到「电锁」的影响， 代替 黑 成为 伤害的来源。",
	["%hei"] = "“告诉组织。不管你们有什么企图，我都一定会将其击溃”",
	
["#SE_Juji_XD"] = "由于<font color = 'gold'><b>狙击「PGM Ultima Ratio HecateII」</b></font>的效果，该「杀」强制无法被闪避。",
["#sjuji_dis"] = "狙击「PGM Ultima Ratio HecateII」",
["sjuji"] = "狙击「PGM Ultima Ratio HecateII」",
["$sjuji1"] = "碰~！(枪声）下一个！",
["$sjuji2"] = "结束了！碰！碰！碰！（枪声）",
[":sjuji"] = "锁定技，你与其他角色计算距离-1，你使用的【杀】不能被攻击范围内没有你的角色的【闪】响应。",
["jianyu"] = "箭雨「索尔斯·无制限歼灭」",
["se_jianyu$"] = "image=image/animate/se_jianyu.png",
["JianyuCard"] = "箭雨「提拉莉雅·无制限歼灭」",
["$jianyu1"] = "那个男人，有着能在战场中笑的强大，干掉那个男人，我也会....",
["$jianyu2"] = "还有什么....是我能做的",
[":jianyu"] = "出牌阶段限一次，你可以指定X名攻击范围内的角色（X为你已损失的体力且至少为1），视为你对他们使用一张不计入次数的【杀】。",
["Shino"] = "朝田诗乃",
["&Shino"] = "朝田诗乃",
["@Shino"] = "刀剑神域",
["#Shino"] = "深蓝の狙击手",
["~Shino"] = "怎么会！不可能！",
["designer:Shino"] = "Sword Elucidator",
["cv:Shino"] = "泽城美雪",
["%Shino"] = "“如果不竭尽全力到最后一刻的话，是无法取胜的”",

["Kuon"] = "柚叶久远",
["@Kuon"] = "传颂之物：虚伪的假面",
["#Kuon"] = "解放者后裔",
["~Kuon"] = "永别了",
["designer:Kuon"] = "FlameHaze",
["cv:Kuon"] = "种田梨沙",
["yaoshi"] = "药师",
["$yaoshi"] = "药做好了，可能会有一点点刺激，但是相对的效果很不错哦。",
[":yaoshi"] = "每回合限一次: ①当一名角色进入濒死状态时，你弃置一张红桃牌，令其回复一点体力。②一名角色出牌阶段开始时，你可以弃置一张手牌，若该角色出牌阶段使用的第一张牌与你弃置的牌花色不同，其受到你造成的一点伤害；若花色相同，你摸一张牌。",
["@yaoshi"] = "药师：弃置一张手牌",
["@yaoshi2"] = "药师：弃置一张红桃牌",
["shenxue"] = "神血「解放者之血」",
["Fl_shenxue$"] = "image=image/animate/Fl_shenxue.png",
["$shenxue"] = "爆炸音效",
[":shenxue"] = "当其他同势力角色阵亡或你进入濒死状态时，你可以摸一张牌并翻面，若因此处于叠置状态，令所有其他角色选择一项执行：1、弃置两张手牌。2、失去一点体力。",
--["@shenxue"] = "神血：选择至多两名势力不同的角色",
["@shenxue"] = "弃置两张手牌否则失去一点体力",
["@shenxue-discard"] = "神血：弃置两张手牌否则失去一点体力",
["shenxue_recover"] = "回复一点体力",
["shenxue_attack"] = "选择至多两名势力不同的角色",
["%Kuon"] = "“～かな”",

["PYuuki"] = "佑树",
["@PYuuki"] = "公主连结！Re:Dive",
["#PYuuki"] = "骑士君",
["~PYuuki"] = "",
["designer:PYuuki"] = "网瘾少年",
["cv:PYuuki"] = "阿部敦",
["pquanneng"] = "权能「公主骑士之力」",
[":pquanneng"] = "每回合限一次，当一名角色造成伤害时，若其存在明置女性人物牌，你可以摸一张牌，令该角色选择一项:1.观看你的手牌，并获得其中一张；2.获得一枚“蓄力”标记（场上存在此标记时你的手牌上限+1）；3.弃置人物牌上的一个“蓄力”标记，摸一张牌并回复一点体力。",
["@xuli"] = "蓄力",
["@haogandu"] = "好感度",
["pquanneng_seehandcards"] = "观看来源手牌并获得一张牌",
["pquanneng_gainmark"] = "获得一枚“蓄力”标记",
["pquanneng_losemark"] = "弃置人物牌上的一个“蓄力”标记，摸一张牌并回复一点体力",
["plianjie"] = "连结「与你的羁绊」",
[":plianjie"] = "主将技，此人物牌减少一个阴阳鱼。锁定技，当你发动一次“权能”后或者造成一次伤害时，获得一个“好感度”标记(上限为3)；你的准备阶段开始时，若你“好感度”标记为3，你可以弃置所有“好感度”标记，并从一个随机常规势力的三个随机未登场女性武将中选择一个替换你的副将。",--其他角色准备阶段开始时，若你有以此法记录的副将且其不在场上，你可以清除记录并替换为此副将，以此法替换副将时，不重置其限定技。",
["%PYuuki"] = "“让我们在你的选拔下成为最强吧”",

["Fumika"] = "美川文伽",
["@Fumika"] = "死后文",
["#Fumika"] = "倾听亡者之音",
["~Fumika"] = "…………（文伽！）",
["designer:Fumika"] = "Yuuki",
["cv:Fumika"] = "植田佳奈",
["youji"] = "邮寄",
[":youji"] = "当一名角色体力减少后，若其血量小于其体力上限一半且存活且没有“邮寄”标记，你可以摸一张牌并令该角色获得一枚“邮寄”标记。锁定技，你的手牌上限＋x（x为场上邮寄标记数）。",
["songxin"] = "送信",
[":songxin"] = "当一名“邮寄”角色A阵亡时，你可以令一名其他角色获得A的所有手牌，或令伤害来源摸一张牌并展示，然后令弃置与其不同类别的牌。若你有“邮寄”标记，你失去一枚“邮寄”标记，并摸一牌。",
["@songxin"] = "选择一名其他角色获得阵亡者所有手牌",
["%Fumika"] = "“别跟我开这种玩笑，我的心脏受不了”",
["@youji"] = "邮寄",
["songxin_source"] = "令来源摸一张牌并弃置与其类别不同的牌",
["songxin_choose"] = "选择一名其他角色获得阵亡角色所有手牌",
["$youji"] = "（人类可真是麻烦啊）什么事？（为什么活着时不说出来呢）有些事不死就说不出口",
["$songxin1"] = "我是来送信的，你是绫濑明日奈的恋人吗？",
["$songxin2"] = "死后文，来自死后世界的信件",
["$songxin3"] = "寄件人是町屋翔太，死后文是失去一切的人最后留下的思念，你有接受的义务",
["$songxin4"] = "（信？）嗯，有点特别的信，但是……但这是世界上最纯粹最美丽的思念",

["Sanya"] = "萨妮娅",
["@Sanya"] = "强袭魔女",
["#Sanya"] = "纤细如影",
["~Sanya"] = "",
["designer:Sanya"] = "奇洛",
["cv:Sanya"] = "门胁舞以",
["tancha"] = "探查",
["@tancha"] = "选择一名角色，视为对其使用知己知彼",
[":tancha"] = "出牌阶段开始时你可视为对一名角色使用一张【心灵读取】，此次结算中选择效果后，若观看手牌且牌中有【杀】或观看人物牌且人物牌势力与你所属势力名不同，视为你对其使用一张【杀】；否则你摸一张牌。",
["boxi"] = "薄息",
[":boxi"] = "一名其他角色的一张人物牌明置时，若其与你势力不同，你可以选择一名势力相同角色选择是否对其使用一张【杀】（不计入次数范围限制）；若相同，你可以选择一名势力相同的角色摸一张牌，若选择的角色不为你，你进入存在消失状态。",
["#boxi"] = "对目标使用一张杀",
["@boxi1"] = "选择一名势力相同的角色（摸牌）",
["@boxi2"] = "选择一名势力相同的角色（使用杀）",
["%Sanya"] = "“我并不会感到困扰的”",

["Estelle"] = "艾丝蒂尔",
["@Estelle"] = "空之轨迹",
["#Estelle"] = "耀目少女",
["~Estelle"] = "",
["designer:Estelle"] = "奇洛",
["cv:Estelle"] = "神田朱未",
["fenglun"] = "凤轮",
[":fenglun"] = "出牌阶段限一次，你可弃置一张牌并选择一名角色，根据牌的类型令其选择是否执行以下效果：基本牌，弃置一张【杀】；装备牌，弃置两张手牌；锦囊牌，你摸一张牌并视为对其使用一张【决斗】。若为否，其受到你的一点伤害。",
["@fenglun-basic"] = "弃置一张杀否则受到伤害",
["@fenglun-equip"] = "弃置两张手牌否则受到伤害",
["@fenglun-trick"] = "令来源摸一张牌并视为对你用一张决斗，否则受到伤害",
["$fenglun1"] = "不认真对待可是要被打飞的哦！",
["%Estelle"] = "“让我们互相守护对方，一起前行吧”",

["Houtarou"] = "折木奉太郎",
["@Houtarou"] = "冰菓",
["#Houtarou"] = "节能主义者",
["~Houtarou"] = "（里志）真是太没出息了，连我的一半时间都没泡到。注意到他时，居然已经晕过去了。",
["designer:Houtarou"] = "晴空&光临长夜",
["cv:Houtarou"] = "中村悠一",
["%Houtarou"] = "“没必要的事不做，必要的事尽快解决”",
["linggan"] = "灵感",
[":linggan"] = "每轮每个效果限一次：一名其他角色明置人物牌时，你可以观看牌堆底三张牌，并可以用一张手牌替换其中一张; 你明置此人物牌时，若你判定区没有【节能主义】，你可以摸2张牌，然后将牌堆顶一张牌当作【节能主义】放于你判定区。",
["jieneng"] = "节能",
[":jieneng"] = "锁定技，弃牌阶段/判定阶段开始时，若你判定区有“节能主义”，此回合你手牌上限+3（不叠加）。",
["tuili"] = "推理",
[":tuili"] = "当一名角色使用一张基本或锦囊牌时，若你手牌或牌堆底三张牌中有与其同名牌，你可以观看牌堆底3张牌，并可以弃置手牌或观看牌中的一张同名牌，令此技能此回合失效，然后你令1～2名角色各摸一张牌，每轮限一次{若你弃置的为手牌，你可暗置此人物牌}。",
["@linggan"] = "选择一张手牌交换",
["@tuili"] = "弃置一张同名牌",
["@tuili_choose"] = "选择1~2名角色",
["tuili_hide"] = "暗置此人物牌",
["$linggan1"] = "只是灵光一闪……运气好而已。",
["$linggan2"] = "我之前也说过，灵光乍现都是靠运气。",
["$jieneng1"] = "喜欢所谓“灰色生活”的学生也存在吧。",
["$jieneng2"] = "没必要的事不做，必要的事尽快解决。",
["$tuili1"] = "既然是机敏的秘密社团，就能料定他们会明目张胆地反其道而行之。",
["$tuili2"] = "他们从一开始就是7个人。在画面中出现的6个人，以及拿着摄影机拍摄的一个人，一共7人。",
["$tuili3"] = "真的不明白么，谁都没有理解到吗，那条无聊的信息。",
["%Houtarou"] = "“我差不多该厌倦灰色了”",

["Kuuhaku"] = "空白",
["@Kuuhaku"] = "NO GAME NO LIFE",
["#Kuuhaku"] = "『　』",
["~Kuuhaku"] = "",
["designer:Kuuhaku"] = "网瘾少年",
["cv:Kuuhaku"] = "松冈祯丞&茅野爱衣",
["youzheng"] = "游争",
[":youzheng"] = "准备阶段开始时，你可以指定一名势力不同的角色，双方各发起指令然后各摸一张牌，你对其发起拼点，败者执行胜者选择的指令（拼点点数相同则无事发生），然后若你为胜者，你可以展示并交换主副将。",
["@youzheng"] = "选择一名势力不同的角色",
["$youzheng1"] = "那么，开始游戏吧！",
["$youzheng2"] = "白以空白的名义接受你的挑战，史蒂夫输了的话就要听白的一个命令！",
["youzheng_command"] = "执行指令",
["youzheng_trans"] = "交换主副将并让对方获得拼点牌",
["sorazhi"] = "空智",
[":sorazhi"] = "主将技，每回合限两次，当你手牌数发生变化时，如果场上存在其他与你手牌数相等的角色，你可以选择其中一名角色，令其摸一张牌或者弃一张牌。",
["@sorazhi"] = "选择一名手牌数与你相等的其他角色",
["sora_draw"] = "令其摸一张牌",
["sora_discard"] = "令其弃一张牌",
["$sorazhi1"] = "这个世上根本没有所谓的运气，游戏的成败在开始时就决定了。",
["$sorazhi2"] = "自称的超能力者，你读到我这步棋了吗？(音效)将军。",
["shiroshi"] = "白识",
[":shiroshi"] = "副将技，当你体力值发生变化时，你可以观星x（x为场上与你体力相等的角色数），然后你可以令与你体力值相等的一名角色摸一张牌，然后你可以视为对其攻击范围的一名角色使用一张“心灵读取”",
["$shiroshi1"] = "空白还没有弱到会输给那种东西。",
["$shiroshi2"] = "将军！",
["@shiro"] = "选择一名体力与你相等的角色",
["@shiroshi"] = "选择一名目标攻击范围内的角色",
["exchange_two_general"] = "交换主副将",
["%Kuuhaku"] = "“空白永不败北！”",

["Tatsumi"] = "塔兹米",
["@Tatsumi"] = "斩·赤红之瞳",
["#Tatsumi"] = "铠之继承者",
["~Tatsumi"] = "抱歉.....无法遵守约定了",
["designer:Tatsumi"] = "FlameHaze",
["cv:Tatsumi"] = "齐藤壮马",
["lizhan"] = "历战",
["$lizhan"] = "我一定会..活着回来。",
[":lizhan"] = "锁定技，当你造成或受到一次伤害后，若你“历”标记小于体力上限，你获得一个“历”标记；当你有“历”标记时，手牌上限+1。",
["caokai"] = "操铠",
["Flcaokai$"] = "image=image/animate/Flcaokai.png",
["$caokai"] = "呃啊~~恶鬼缠身~~！",
[":caokai"] = "判定阶段开始时，你可以弃置一个“历”标记，若如此做，你获得效果X：直到你的下回合开始前，你的【杀】造成的非传导伤害+1。",
["longhua"] = "龙化",
["$longhua"] = "吼~~（龙吼声）",
[":longhua"] = "主将技，限定技，准备阶段开始时，若你“历”数量不小于体力上限且你体力不大于1，你可以增加一点体力上限并回复一点体力，然后你将操铠X改为：弃置你判定区一张牌，你的【杀】造成的非传导伤害+1，额定目标+1。锁定技，当你回合结束时，若你发动此限定技且“历”标记小于体力上限，移除此人物牌。",
["lizhan_mark"] = "历",
["#lizhan_mark"] = "历",
["@longhua"] = "龙化",
["%Tatsumi"] = "“恶鬼缠身！”",

["Sakuya"] = "十六夜咲夜",
["@Sakuya"] = "東方project",
["#Sakuya"] = "完美潇洒",
["~Sakuya"] = "大小姐，对.....不起",
["designer:Sakuya"] = "FlameHaze",
["cv:Sakuya"] = "东方Lost Word",
["huanshen"] = "幻身",
["$huanshen"] = "哼哼。这里面可是什么都没有哦。",
[":huanshen"] = "出牌阶段限一次/当你受到非杀造成的伤害时，你可以弃置至多等同于当前手牌数的牌，并摸等量的牌。",
["sshiji"] = "时计",
["Fhsshiji$"] = "image=image/animate/Fhsshiji.png",
["$sshiji"] = "时间啊......停止吧！",
[":sshiji"] = "每回合限一次，当你因“幻身”弃置牌时，若弃置牌颜色相同，且弃置牌不小于3或你没手牌，你可以回复一点体力，若至少有三张花色相同，你可以移动一名角色判定区所有牌，若有三种类别，你可以令当前回合角色叠置，若至少有三张同名，你可以从弃牌堆随机获得三张不同名的牌，且至你下个回合结束时你使用杀的额定次数+1。",
["sshiji_recover"] = "时计：回复体力",
["@sshiji_from"] = "时计：选择来源",
["@sshiji_to"] = "时计：选择去向",
["sshiji_turnover"] = "时计：当前回合角色叠置",
["sshiji_obtain"] = "时计：获得弃牌堆随机三张不同名牌",
["@huanshen"] = "幻身",
["~huanshen"] = "弃置手牌数的牌",
["%Sakuya"] = "“你的时间已经属于我了…”",

["TokidoSaya"] = "朱鹭户沙耶",
["@TokidoSaya"] = "Little Busters!",
["#TokidoSaya"] = "天然傲娇",
["cv:TokidoSaya"] = "樱井浩美",
["designer:TokidoSaya"] ="晴空",
["~TokidoSaya"] = "我竟然。。对理树同学，对这个世界，这么的喜欢。砰！——（枪声）（理树：沙耶，不知道什么时候，我觉得很久以前，我也是这么叫你的)",
["qiangdou"] = "枪斗",
[":qiangdou"] = "锁定技，当【键】在自己的判定区时，你的【杀】无距离限制且无视防具，且你造成伤害时摸一张牌，并弃置你判定区域的一张【键】。",
["$qiangdou1"] = "约定好了，砰砰——！（枪声）会见面的，砰砰——！一定会。",
["$qiangdou2"] = "你只会碍事，快让开，（横扫声）呀。。你这个混账东西，砰砰！——（枪声）",
["$qiangdou3"] = "总有一天我会带你去的，约会，我保证，（吸气）给我消失！",
["$qiangdou4"] = "因为约定过，砰砰！——（枪声）会再见，会再相恋，和理树同学，砰！——",
["jiaoti"] = "交替",
["qiangji"] = "强击",
[":qiangji"] = "主将技，出牌阶段限一次，你可以和一名玩家拼点，若你赢且判定区没有【键】，则你的拼点牌当做【键】置入你的判定区并获得对方拼点牌，反之则相反。",
["$qiangji1"] = "我需要Lucky Boy，做我的搭档，否则就杀了你，现在就杀了你，总之就杀了你。",
["$qiangji2"] = "你没办法开枪,所以你来找楼梯,我掩护你，（理树：我知道了）砰砰——！（枪声）。",
["$qiangji3"] = "（时风瞬：诱饵作战吗？难道你们以为我会上当吗？）是你输了，时风瞬。",
[":jiaoti"] = "副将技，出牌阶段限一次，你可以将一张手牌当作【键】使用，以此法使用结算后，若目标不为你且与你势力相同，其可以选择与你交换副将。",
["$jiaoti1"] = "如果可以的话，我想回到小时候，然后重新来过，重新来过，再次和理树君相遇。",
["$jiaoti2"] = "如果这次的任务顺利结束,我能邀请你去约会吗?（理树:去吧,我们两个）。",
["jiaoti_ex"] = "与来源交换副将",
["%TokidoSaya"] = "“重新来过，再和理树君相遇”",

["Kotori"] = "五河琴里",
["@Kotori"] = "Date A Live",
["#Kotori"] = "炎魔妹妹",
["~Kotori"] = "（士道）求你了...不要从我这里夺走琴里！她救了我...没有她，就不会有现在的我！...求你了！",
["designer:Kotori"] = "FlameHaze，光临长夜",
["cv:Kotori"] = "竹達彩奈",
["zhuogui"] = "灼鬼",
[":zhuogui"] = "出牌阶段限一次，你可以弃置任意张非基本牌并选择等量其他角色，视为对其使用一张不计入次数，对应实体牌为你弃置牌的“火杀”，然后此杀造成伤害后，你可以选择摸一张牌或弃置目标一张牌。",
["tongyu"] = "统御",
[":tongyu"] = "结束阶段开始时，你可以弃置一张手牌并指定1～2名其他角色，其选择使用一张杀或摸一张牌。",
["se_jiangui$"] = "image=image/animate/se_jiangui.png",
["zhuogui_draw"] = "摸一张牌",
["zhuogui_discard"] = "弃置目标一张牌",
["$zhuogui1"] = "燃烧吧！灼烂歼鬼（Camael）！",
["$zhuogui2"] = "灼烂歼鬼（Camael）·炮（Megiddo）！",
["$tongyu1"] = "拿起枪来。战斗还没结束呢。战争还没结束呢。",
["$tongyu2"] = "来吧，我们还能继续厮杀呢。这可是你期盼的战斗，是你希望的争斗啊！",
["@tongyu-discard"] = "统御：弃置一张手牌",
["@tongyu"] = "选择1~2名其他角色",
["@tongyu-slash"] = "使用一张杀，否则摸一张牌",
["%Kotori"] = "“神威灵装·五番（Elohim Gibor）！”",

["Emilia"]="爱蜜莉雅",
["#Emilia"]="银发半精灵",
["@Emilia"]="Re：从零开始的异世界生活",
["designer:Emilia"] = "光临长夜",
["cv:Emilia"] = "高桥李依",
["%Emilia"] = "“我的名字叫爱蜜莉雅，仅仅是爱蜜莉雅哦”",
["bingshu"] = "冰术",
[":bingshu"] = "你可以将一张黑色基本牌当作【冰杀】使用或打出，以此法使用无距离限制，额定目标数+1，每回合首次使用或打出时摸一张牌。",
["lingshi"] = "灵使",
[":lingshi"] = "准备阶段开始时，若你受伤，你可以随机从摸牌+弃牌堆获得一张基本牌；一名其他角色准备阶段开始时，若其受伤，你可以交给其一张红色基本牌，令其回复1点体力。",
["bingfeng"] = "冰封",
[":bingfeng"] = "限定技，一名其他势力相同的角色阵亡时，若有来源且不为你，你可以对来源计算距离不大于1的所有角色依次造成一点冰冻伤害，然后来源和你叠置。",
["@lingshi"] = "交给其一张红色基本牌",
["@bingfeng"] = "冰封",

["Kuroko"] = "白井黒子",
["@Kuroko"] = "魔法禁书目录",
["#Kuroko"] = "空间移动能力者",
["~Kuroko"] = "姐姐大人......",
["designer:Kuroko"] = "Sword Elucidator",
["cv:Kuroko"] = "新井里美",
["shunshan"] = "瞬闪",
[":shunshan"] = "出牌阶段限一次，你可以弃置一张牌，将一名距离1以内的角色区域内的一张牌移动到一个合理区域。若移动去向不为你，其可以使用一张【杀】。",
["$shunshan1"] = "我是「风机委员」，现在以损坏公物和抢劫现行犯的罪名逮捕你们！",
["$shunshan2"] = "哦呵呵呵呵，您要是忘了我的能力可是会让我很困扰的哦。",
["$shunshan3"] = "我是「风机委员」，我在这里的理由就没必要说明了吧。",
["dingshen"] = "定身",
[":dingshen"] = "当你对其他角色造成非传导伤害时，可以令目标获得一个“针”标记，其手牌上限-X，到其他角色距离+X，X为“针”标记数，其回合结束时清除所有“针”标记。 锁定技，你到有“针”标记的其他角色距离为1。",
["@Stop"] = "针",
["shunshan_to"] = "瞬闪：选择此次移动的目标",
["%Kuroko"] = "“姐姐大人黑子想成为你的力量！”",

["Kaneki"] = "金木研",
["@Kaneki"] = "東京喰種",
["#Kaneki"] = "黑色死神",
["~Kaneki"] = "",
["designer:Kaneki"] = "FlameHaze",
["cv:Kaneki"] = "花江夏樹",
["%Kaneki"] = "“错的不是我，是这个世界”",
["shiyu"] = "食欲",
[":shiyu"] = "锁定技，结束阶段开始时，若你本回合未造成过伤害，流失一点体力；若造成伤害数为1，摸1张牌；若造成伤害数不小于2，选择一项：1，摸两张牌。2，回复一点体力。",
["banhe"] = "半赫",
[":banhe"] = "准备阶段开始时，若你已受伤，你可以从摸牌+弃牌堆随机获得一张装备牌。",

["Chiyuri"] = "仓嶋千百合",
["@Chiyuri"] = "加速世界",
["#Chiyuri"] = "时间逆流",
["~Chiyuri"] = "为什么...会变成这样啊！为什么...非得被说得那么过分！",
["designer:Chiyuri"] = "昂翼天使",
["cv:Chiyuri"] = "豊崎愛生",
["huanyuan"] = "还原",
["huanyuancard"] = "还原",
["huanyuan"] = "还原",
["se_huanyuan$"] = "image=image/animate/se_huanyuan.png",
["$huanyuan1"] = "但...但是，起码这件事让我一份力吧，土豆沙拉和火腿奶酪三明治，都是小春喜欢的吧。",
["$huanyuan2"] = "我只是希望你能认为自己永远有着两个挚友，所以...",
["$huanyuan3"] = "那是因为，我的能力不是「治癒」啊。",
["$huanyuan4"] = "所以我理解了。我的能力不是「治癒」，而是「时间倒流」的力量。",
["$huanyuan5"] = "最喜欢！最喜欢你们两个了！",
["huanyuan_Draw"] = "使其补充手牌至你上一回合结束时的手牌数。",
["huanyuan_Hp"] = "令其恢复至你上一回合结束时的体力和体力上限。",
[":huanyuan"] = "出牌阶段限一次，你可以弃置一张基本牌并指定一名角色，你选择一项：1，令其将手牌调整至X（X为你上回合结束阶段结束时该角色的手牌数），至多以此法摸5张牌，2，令其将体力和体力上限还原至你上回合结束阶段结束时该角色的体力和体力上限。若为第一回合，则X改为4，「你上回合结束阶段结束时」改为「游戏开始时」。 ",
["chengling"] = "橙铃「Lime Bell」",
["chengling"] = "橙铃「Lime Bell」",
["se_chengling$"] = "image=image/animate/se_chengling.png",
["@LimeBell"] = "橙铃",
["$chengling1"] = "我之所以对你言听计从，是为了提高必杀技的级别，扩展可以倒流的时间。然后，就是瞄准了今天这个唯一的机会。我从来都没有成为过你的伙伴！",
["$chengling2"] = "柠檬召唤！",
[":chengling"] = "限定技。出牌阶段，你可以选择至多两名其他无暗置人物牌的角色，其依次执行：若其主/副人物与其游戏开始时不同且其游戏开始时的主/&副人物不在场，主/&副人物变更为游戏开始时对应人物；其对应位置获得当前主副人物牌上没有的技能，并重置当前主副人物拥有的限定技，然后其体力、体力上限调整至其当前主副人物组合的满状态。",
["%Chiyuri"] = "“柠檬召唤！”",

["Rean"] = "黎恩",
["@Rean"] = "闪之轨迹",
["#Rean"] = "灰之启动者",
["~Rean"] = "",
["designer:Rean"] = "奇洛",
["cv:Rean"] = "内山昂辉",
["huanqi"] = "唤骑",
[":huanqi"] = "主将技，此人物牌减少一个阴阳鱼。当你需要使用或打出一张【杀】时，你可以变更副将视为你使用或打出了一张【杀】，每回合限一次。",
["rwuren"] = "无仞",
[":rwuren"] = "副将技，出牌阶段限一次，若你有手牌，你可令一名角色展示你一张牌，若为【杀】，视为对其使用一张不计入次数的【杀】。",
["jueye"] = "绝叶",
[":jueye"] = "每当你使用一张无实体卡的【杀】或视为使用非转化杀时，你可弃置一张【杀】并选择至多两名非目标角色成为此次额外目标。",
["@jueye-discard"] = "绝叶：弃置一张杀",
["@jueye"] = "选择1~2名角色成为额外目标",
["%Rean"] = "“八葉一刀，無仭剣！”",
["$huanqi1"] = "来吧——灰烬骑士神，瓦利玛！",
["$rwuren1"] = "万物转化——“无”变成“有”，“有”又变成“无”！八葉一刀，無仭剣！",
["$jueye1"] = "心頭滅却、我的太刀乃“無”！灰之太刀・絶葉！",

["Joshua"] = "约修亚",
["@Joshua"] = "空之轨迹",
["#Joshua"] = "漆黑之牙",
["~Joshua"] = "",
["designer:Joshua"] = "奇洛",
["cv:Joshua"] = "斋贺弥月",
["huanxi"] = "幻袭",
[":huanxi"] = "出牌阶段限一次，你执行下列一项，并选择一名其他角色，令其选择执行其他一项：1.弃置一张基本牌；2.弃置一张装备牌；3.失去一点体力。无法执行的角色本回合获得效果：本回合无法使用或打出手牌，不能回复体力，且你到其距离为1。",
["jjueying"] = "绝影",
[":jjueying"] = "锁定技，你的体力值大于体力上限一半时，你的回合内可以额外使用一张黑桃【杀】；你的体力值不大于体力上限一半时，你的“幻袭”可以再指定一名其他角色执行剩余一项。",
["@huanxi-basic"] = "弃置一张基本牌否则视为选择“失去一点体力”",
["@huanxi-equip"] = "弃置一张装备牌否则视为选择“失去一点体力”",
["@huanxitarget-basic"] = "弃置一张基本牌否则获得“幻袭”后续效果",
["@huanxitarget-equip"] = "弃置一张装备牌否则获得“幻袭”后续效果",
["huanxi_basic"] = "弃置一张基本牌",
["huanxi_equip"] = "弃置一张装备牌",
["huanxi_hp"] = "失去一点体力",
["$huanxi1"] = "这样就结束了",
["%Joshua"] = "“我仍然不知道这条路通向哪里，但我相信你会看到更多的东西”",

["eryu"] = "二羽",
	["$eryu1"] = "翔鹤姐，要上了！舰首迎风，攻击队，开始起飞！",
	["$eryu2"] = "翔鹤姐姐还好吗？",
	["$eryu3"] = "感觉很好呀♪",
	[":eryu"] = "阵法技，当一张基本牌或普通锦囊牌指定目标后，若你为围攻角色且目标包含被围攻角色，且使用者为围攻角色，（你令）使用者可以将此牌交给另一名围攻角色，每回合限3次。",
	["youdiz"] = "诱敌",
	["$youdiz1"] = "第一波攻击编队，准备出击！",
	["$youdiz2"] = "第二波攻击编队，全体作战飞机，出击！",
	--[":youdiz"] = "出牌阶段限一次，你可以将一张装备牌当作【存在缺失】使用。锁定技，若你明置，你的【存在缺失】额定目标+1，使用时摸1张牌。",
	[":youdiz"] = "出牌阶段限一次，你可以令一名其他角色对你使用一张【杀】（无距离限制），然后若你体力值不小于其，你执行：令其进入存在缺失状态，并且若其与你势力不同，你摸一张牌。",
	["Zuikaku"] = "瑞鶴",
	["@Zuikaku"] = "艦隊collection",
	["#Zuikaku"] = "最后的正规空母",
	["~Zuikaku"] = "挺，挺能干的嘛…！",
	["designer:Zuikaku"] = "Sword Elucidator，光临长夜",
	["cv:Zuikaku"] = "野水伊織",
	["%Zuikaku"] = "“翔鹤姐，要上了！”",

	["Natsume_Rin"] = "棗鈴",
	["&Natsume_Rin"] = "棗鈴",
	["@Natsume_Rin"] = "Little Busters!",
	["#Natsume_Rin"] = "鈴喵",
	["~Natsume_Rin"] = "（被击败）......",
	["designer:Natsume_Rin"] = "Sword Elucidator",
	["cv:Natsume_Rin"] = "民安ともえ",
	["%Natsume_Rin"] = "“理树，拉住我的手吧！”",
	["maoqun"] = "猫群",
	["RinNeko"] = "猫",
	["$maoqun1"] = "就这样就这样~第一只直立行走的猫~",
	["$maoqun2"] = "烦死了！我没有朋友又怎么样？碍到你了嘛？你会死嘛？",
	["$maoqun3"] = "很好很好~喵~喵~",
	["$maoqun4"] = "你...今天也没带信来吗？",
	["$maoqun5"] = "不许欺负弱小！",
	["$maoqun6"] = "（殴打...）",
	["$maoqun7"] = "我上了！蛮不讲理的大恶人，天诛！~",
	--[":maoqun"] = "每轮限一次，当一名势力相同的角色受到伤害时，你可以将牌堆顶一张牌置于人物牌上，称为“猫”。你可以将一张“猫”当【异议】使用。",
	[":maoqun"] = "当一名势力相同的角色受到伤害时，若你“猫”数量小于场上存活人数的1.5倍，你可以将牌堆顶一张牌置于人物牌上，称为“猫”。出牌阶段，你可以弃置一张“猫”并选择一名角色，根据“猫”的花色对其造成以下影响至其回合结束。♠：摸牌阶段额定摸牌数-1。♣：手牌上限-1。♦：受到属性伤害+1。♥：其回复体力时，取消之，然后移除效果。每名角色无法重复分配已有效果。 ",
	["pasheng"] = "怕生",
	[":pasheng"] = "副将技，当你成为基本牌或普通锦囊的的唯一目标时，若来源不为你，你可以弃置你或来源判定区的一张牌，取消之。",
	["rinjiuyuan"] = "救援",
	[":rinjiuyuan"] = "主将技，一名角色进入濒死时，若其判定区没有【键】，你可以将牌堆顶一张牌当作【键】置于其判定区；判定区有【键】的角色受到濒死伤害时，你可以弃置其判定区的一张【键】。",
	["SE_Zhixing$"] = "image=image/animate/SE_Zhixing.png",
	["$rinjiuyuan1"] = "没问题的，我相信你。先给警察打个电话比较好吧。",
	["$rinjiuyuan2"] = "小毬，我会让你的愿望实现的。",
	["$rinjiuyuan3"] = "要放在担架上吗？...明白了！",
	["@Neko_S"] = "摸牌数-1",
	["@Neko_C"] = "手牌上限-1",
	["@Neko_D"] = "属性伤害+1",
	["@Neko_H"] = "回复体力取消",

	["Ryuuichi"] = "成步堂龙一",
	["@Ryuuichi"] = "逆转裁判",
	["#Ryuuichi"] = "传说的辩护士",
	["designer:Ryuuichi"] = "网瘾少年",
	["%Ryuuichi"] = "“异议あり！”",
	["quzheng"] = "取证",
	[":quzheng"] = "一名其他角色结束阶段结束时，若此回合有人受到伤害或阵亡，你可以弃置一张手牌，将一张本回合内以该角色为来源进入弃牌堆的牌置入你的武将牌上，称为“证据”（最多3张）。",
    ["nizhuan"] = "逆转",
	[":nizhuan"] = "主将技，此人物牌减少一个阴阳鱼。每回合限一次，你可以将一张“证据”当做“异议”使用或打出，若你以此法使用牌的花色与被响应的“杀”牌颜色相同，此异议结算后目标视为对使用者使用一张名称相同的“杀”。",
	["yanshen"] = "延审",
	[":yanshen"] = "副将技，一名角色准备阶段开始时，若其手牌数不小于当前体力值，你可以弃置两张“证据”，其选择其中一张获得，你获得另一张，然后其选择一项执行：1.跳过本回合首次判定和摸牌阶段；2.跳过本回合首次出牌和弃牌阶段。",
    ["evidence"] = "证据",
	["@quzheng"] = "弃置一张手牌",
	["@yanshen"] = "延审",
	["~yanshen"] = "弃置两张证据",
	["yanshen_1"] = "跳过本回合首次判定和摸牌阶段",
	["yanshen_2"] = "跳过本回合首次出牌和弃牌阶段。",


["Neko"] = "黑羽宁子",
["@Neko"] = "极黑的布伦希尔特",
["#Neko"] = "布伦希尔德", 
["designer:Neko"] = "FlameHaze",
["cv:Neko"] = "种田梨沙",
["%Neko"] = "“如果我们的数日能够拯救某个人的生命，我们的生命就有了好几倍的价值”",
["~Neko"] = "我早就决定长大后要这么做了，我喜欢良太，而且今后也会永远喜欢你！",
["moshi"] = "魔使",
[":moshi"] = "每回合限三次，当你使用非装备非技能牌指定其他角色为目标后，可以移除至多3枚“识”，根据移除“识”数触发效果:①移除的“识”为1,摸一张牌，本回合计算与其他角色的距离时-1, ②移除的“识”为2，弃置其中一名目标的一张装备牌，③移除的“识”为3，对其中任意名目标各造成一点伤害。",
["$moshi1"] = "有一件事我想说清楚。我不是你的青梅竹马，关于你的事，我也一概不知，我是第一次见到你。",
["$moshi2"] = "放心吧，我能消灭反物质，使用微型黑洞。",
["nekojiyi"] = "汲忆",
[":nekojiyi"] = "锁定技，当你于回合内使用一张非技能牌时，若该牌有花色且与本回合你使用的上一张有花色牌花色不同且此回合你之前使用牌的花色不包含此花色（本回合使用的第一张有花色牌视为与上一张不同花色），你获得一个“识”标记。",
["@neko_shi"] = "识",
["moshi_dis"] = "魔使距离",
["$nekojiyi"] = "青梅竹马？",

["Oumashu"] = "樱满集",
  ["&Oumashu"] = "樱满集",
  ["@Oumashu"] = "罪恶王冠",
  ["#Oumashu"] = "温柔的王",
  ["~Oumashu"] = "这不是..真的吧..",
  ["designer:Oumashu"] = "光临长夜",
  ["cv:Oumashu"] = "梶裕贵",
  ["%Oumashu"] = "“我使用这力量只是为拯救大家和小祈”",
  ["void"] = "虚空",
  [":void"] = "出牌阶段限一次，你可以弃置一张牌并指定一名其他有牌的角色，观看其所有牌并获得其中一张牌，然后若你以此法获得“杀”或“武器牌”，此回合你使用的第一张杀无距离限制，额定目标+1。若如此做，此回合结束时，若你拥有此牌或此牌在弃牌堆，这名角色获得此牌。",
  ["wangguo"] = "王国",
  [":wangguo"] = "主将技，此人物牌减少一个单独的阴阳鱼。你使用虚空时可以额外指定一名其他势力相同的角色为目标；你使用虚空指定势力相同的角色为目标时，可以失去一点体力，执行下列一项：1，令其回复一点体力；2，其摸2张牌，；3，弃置其判定区一张牌。",
  ["void_draw"] = "令目标摸两张牌",
  ["void_recover"] = "令目标回复一点体力",
  ["void_discard"] = "弃置目标判定区的一张牌",
  ["$void"] = "我想以后再也用不到这种能力了",
  ["$wangguo"] = "我使用这力量只是为拯救大家和小祈",

["Chtholly"] = "珂朵莉",
["&Chtholly"] = "珂朵莉",
["@Chtholly"] = "末日三问",
["#Chtholly"] = "幸福的女孩", 
["designer:Chtholly"] = "FlameHaze",
["cv:Chtholly"] = "田所梓",
["%Chtholly"] = "“我已经无法获得幸福了,因为我的身边已经充满幸福了”",
["~Chtholly"] = "看来梦一般的回忆，也到落幕时间了吧",
["ranxin"] = "燃心",
[":ranxin"] = "每回合限3次，你使用/以使用方式打出一张红色非技能牌时，若你“魔”小于3，你可以将牌堆顶一张牌作为“魔”置于人物牌上。锁定技，你有“魔”时，使用杀额定次数+1，你的杀造成伤害时弃置一张“魔”并摸一张牌。",
["$ranxin1"] = "因为...我发现了，其实我..早就已经被幸福包围了",
["$ranxin2"] = "现在我圆了梦，也有了美妙的回忆，已经没有什么遗憾了吧",
["chiyi"] = "斥忆",
[":chiyi"] = "锁定技，结束阶段结束时，若你有“魔”，你弃置所有“魔”，若弃置“魔”数不大于2，你失去一点体力，摸2张牌；若弃置“魔”数不小于3，你减一点体力上限，摸3张牌，并弃置一张手牌。",
["ranxin_magic"] = "魔",
["$chiyi"] = "假如..是假如哦...如果我会在五天后死去，你会对我温柔些吗？",

["Yato"] = "夜斗",
["@Yato"] = "野良神",
["#Yato"] = "祸津神", 
["designer:Yato"] = "FlameHaze，光临长夜",
["cv:Yato"] = "神谷浩史",
["~Yato"] = "呃..呃啊.呃",
["%Yato"] = "“汝乃有缘之人”",
["shenqi"] = "神器",
[":shenqi"] = "主将技，你明置此人物牌时，随机展示一张含有“魔法”势力标签的未出场人物牌，置于该人物牌上，称为“神器”；一名势力相同的其他角色阵亡时，你可以选择其一张人物牌，将其加入“神器”；当你使用【杀】时，你可以将一张“神器”与副将替换之(不因此获得“神器”拥有的限定技的标记)。",
["shenqigeneralcard"] = "神器",
["huojin"] = "祸津",
[":huojin"] = "副将技，准备阶段开始时，你可以令一名其他角色选择是否交给你一张牌，若其选择是，你可以对其指定的另一名其他角色使用一张【杀】（无距离次数限制）。",
["zhanyuan"] = "斩缘",
[":zhanyuan"] = "每回合限一次，你的杀对目标造成伤害后，可以弃置其区域内的一张牌，然后其进入存在缺失状态。",
["@huojin"] = "是否交给 %dest 一张牌",
["@huojin-slash"] = "对目标使用一张杀",
["$shenqi1"] = "来吧，伴器！",
["$shenqi2"] = "丰苇原中国，喧扰迷惑其之邪魅...",
["$huojin"] = "闭嘴！",
["$zhanyuan1"] = "汝乃有缘之人",
["$zhanyuan2"] = "你好~这里是快捷便宜又放心的外派神明夜斗",

	["Fegor"] = "芬格尔",
	["#Fegor"] = "怠惰的魔王",
	["@Fegor"] = "万亿魔坏神",
	["designer:Fegor"] = "clannad最爱",
    ["cv:Fegor"] = "田辺留依",
	["yizhigame"] = "遗志",
	[":yizhigame"] = "当一名其他角色死亡时，其可以交给你所有的牌并选择一项属性让你获得；手牌上限+2，出杀次数+1，摸牌阶段摸牌数+1。当你死亡前，你可以让一名角色获得技能“遗志”并获得你通过遗志增加的属性。",
	["sibie"] = "死别",
	[":sibie"] = "出牌阶段，你可以对一名体力值大于你的角色造成一点伤害，然后失去一点体力，然后，此回合该角色是此技能唯一合法目标。如果你因此死亡，该角色弃置装备区内所有牌。",
	["LuaZhiyan-invoke"] = "选择一名角色继承你的技能。",
	["%Fegor"] = "“看好了，这是我这一生最认真的一击”",
	["@yizhigame2"] = "出杀次数增加",
	["@yizhigame1"] = "手牌上限增加",
	["@yizhigame3"] = "摸牌张数增加",

    ["SKaguya"] = "四宫辉夜",
	["#SKaguya"] = "辉夜大小姐",
	["@SKaguya"] = "辉夜大小姐想让我告白～天才们的恋爱头脑战～",
	["designer:SKaguya"] = "光临长夜",
	["%SKaguya"] = "“お可愛いこと～”",
    ["cv:SKaguya"] = "古贺葵",
	["slianji"] = "恋计",
	[":slianji"] = "出牌阶段限一次，你可以交给一名其他角色一张牌，指定一种花色或类别，然后其选择一项：1，交给你一张该花色或类别的手牌。2，交给你两张手牌(不足全给)。",
	["@slianji"] = "交给%src 一张 %arg，否则交给%src 两张手牌",
	["#Slianji_choice"] = "%from 选择了 %arg",
	["jinchi"] = "矜持",
    [":jinchi"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你受到伤害时，若有伤害来源且其存活，则你可以展示手牌，伤害来源选择一项：1.弃置一张你手牌中最多的花色的手牌；2.防止此伤害。",
    ["&jinchi"] = "%src 发动了技能“矜持”，请弃置一张符合条件的手牌，否则防止此伤害",
    ["#jinchi_effect"] = "%from 的“%arg”效果触发，此伤害被防止",
	["$slianji1"] = "虽然我可以选择拒绝，但这样一来我之前的准备就没有任何意义了",
	["$slianji2"] = "特意伪造中奖函，还偷偷放到藤原的信箱里",
	["$slianji3"] = "瞄准会长本就不多的休息日所作的计划",
    ["$jinchi1"] = "不过，是会长的话倒也有那么极其再极其微小的一点可能性",
    ["$jinchi2"] = "为..为什么我要躲着他啊？这..这不就像是我..对会长有恋爱意识了吗？",
    ["$jinchi3"] = "不行！越接近越没法直视会长的脸",
    ["~SKaguya"] = "是啊..根本没什么神啊..",

	["Saki"] = "宫永咲",
	["#Saki"] = "裱人大魔王",
    ["@Saki"] = "天才麻将少女",
    ["cv:Saki"] = "植田佳奈",
	["designer:Saki"] = "Sword Elucidator, 好烦",
    ["%Saki"] = "“岭上开花！”",
    ["lingshang"] = "岭上",
    [":lingshang"] = "当一次性仅1张牌A不因弃置而进入弃牌堆时，若你的“咲”标记数＜4，且本回合触发该条件的次数=1+你本回合发动此技能的次数，则你可以弃置两张类别相同的牌，随机获得牌堆中的一张与A类别相同的牌，获得1枚“咲”。你的手牌上限+X（X为“咲”数）；摸牌阶段，你可以多摸X张牌。",
    ["SakiMark"] = "咲",
    ["#SakiMark"] = "咲",
    ["@lingshang"] = "你可以发动“岭上”",
    ["~lingshang"] = "选择两张类别彼此相同的牌→点击“确定”",
    ["guiling"] = "归零",
    [":guiling"] = "回合结束时，你须弃置所有“咲”。出牌阶段限一次，你可以选择1~3名其他角色并弃置等量“咲”，这些角色依次选择一项：1.交给你一张装备牌；2.你回复1点体力；3.你对其造成1点伤害。",
    ["guilingglobal"] = "归零",
    ["&guilingGive"] = "你可以交给 %src 一张装备牌",
    ["guilingDamage"] = "来源对你造成1点伤害",
    ["guilingRecover"] = "令来源回复1点体力",
	["SE_Lingshang$"] = "image=image/animate/SE_Lingshang.png",
["$lingshang1"] = "自摸，清一色 碰碰和 三暗刻 三杠子 赤宝牌1 岭上开花。",
["$lingshang2"] = "自摸，岭上开花。",
["$lingshang3"] = "杠",
["$lingshang4"] = "再来一个，杠",
["$guiling1"] = "我每次打麻将，都会变成这个样子..",
["$guiling2"] = "（和）只是这样？（咲）只是这样。",

["Megumin"] = "惠惠",
["#Megumin"] = "爆裂魔法使",
["@Megumin"] = "为美好的世界献上祝福",
["cv:Megumin"] = "高桥李依",
["~Megumin"] = "nice爆裂魔法",
["%Megumin"] = "“吾名惠惠，红魔族第一的魔法师兼爆裂魔法的操纵者！”",
["baolie"] = "爆裂",
[":baolie"] = "进入出牌阶段时，若你的“吟唱”不小于2，你可以弃置所有“吟唱”，对任意名角色依次分配X点火焰伤害，每名角色分配数不超过2（X为你此次弃置的“吟唱”数），然后你跳过此次出牌阶段；当你造成火焰伤害时，可以弃置一张“吟唱”，令伤害+1。",
["yinchang"] = "吟唱",
[":yinchang"] = "准备阶段开始时，你可以将一张与其余“吟唱”类别不同的牌置于人物牌上，称为“吟唱”，当你受到伤害后，你可以选择一张“吟唱”获得之。锁定技，若你“吟唱”数大于2，你额定摸牌数+1，手牌上限+1。",
["$baolie1"] = "Explosion！",
["$yinchang1"] = "呃呵呵，面对那么多敌人，怎么能忍住释放爆裂魔法的冲动啊！~不能忍！",
["$yinchang2"] = "被光明笼罩的漆黑啊！身披夜之衣的爆炎啊！以红魔族之名，显现原始的崩坏吧！",
["$yinchang3"] = "于终焉王国之地，引渡力量根源之物啊！在吾面前展现吧！",

["Lucy"] = "露西",
["#Lucy"] = "星灵魔导士",
["@Lucy"] = "妖精的尾巴",
["cv:Lucy"] = "平野绫",
["designer:Lucy"] = "Yuuki",
["%Lucy"] = "“我想留在公会里，我最喜欢妖精的尾巴了!”",
  ["~Lucy"] = "喂，露西！快点来这里，大家都在喔",
  ["xingling"] = "星灵",
  [":xingling"] = "明置此人物牌时，你可以获得场上所有方片。<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以将一张方片牌当作不可被金色宣言响应的【英灵召唤】使用。当你使用【英灵召唤】时，可以将副人物牌放在人物牌上，称为“星灵放置”。永久效果：回合结束时，若你有“星灵放置”，选择一项：1，弃置一张“星灵放置”。2，将副将变更为一张“星灵放置”，不以此法更新限定技。",
  ["xingling$"] = "image=image/animate/xingling.png",
  ["#xinglingShown"] = "星灵",
  ["$xingling"] = "语音",
  ["lingqi"] = "灵契",
  [":lingqi"] = "当你杀死一名角色时，你可以随机获得摸牌/弃牌堆的一张方片牌。",
  ["$lingqi"] = "语音",
  ["lingqi$"] = "image=image/animate/lingqis.png",
  ["xinglinggeneralcard"] = "星灵放置",
  ["xingling_discard"] = "弃置该人物牌",
  ["xingling_change"] = "副将变更为该人物牌",
  ["$xingling1"] = "打开吧，水瓶座之门，阿葵亚！",
  ["$xingling2"] = "打开吧，金牛座之门，塔罗斯！",
  ["$xingling3"] = "那我要上了，打开吧，白羊座之门，阿莉耶丝！",
  ["$xingling4"] = "打开吧，狮子座之门，洛基！",
  ["$xingling5"] = "打开吧，处女座之门，芭露歌！",
  ["$xingling6"] = "打开吧，双子座之门，杰米尼！",
  ["$lingqi1"] = "今后请多指教，主人  我才要你们多多指教 斯卡皮欧 阿莉耶丝 杰米尼",
  ["$lingqi2"] = "谢谢，露西",

["ShionNezumi"] = "紫苑＆老鼠",
["&ShionNezumi"] = "紫苑老鼠",
["#ShionNezumi"] = "No.6反抗者",
["@ShionNezumi"] = "未来都市NO.6",
["cv:ShionNezumi"] = "梶裕贵&细谷佳正",
["designer:ShionNezumi"] = "光临长夜",
["~ShionNezumi"] = "",
["%ShionNezumi"] = "“一定会再相见！”",
["kangshi"] = "抗市",
[":kangshi"] = "当场上有除你之外的唯一大势力时：①出牌阶段限一次，你可以受到一点无来源伤害，依次获得场上的大势力角色的一张牌，然后此回合你到这些角色距离视为1；②你可以令你摸牌阶段额定摸牌数+1。",
["qingban"] = "情绊",
[":qingban"] = "每名角色限一次，当一名角色进入濒死时，若你体力上限大于1，你可以对其发动：你失去一点体力上限，令其回复1点体力。",

	["ShokuhouMisaki"] = "食蜂操祈",
	["@ShokuhouMisaki"] = "某科学的超电磁炮",
	["#ShokuhouMisaki"] = "心理掌握",
	["designer:ShokuhouMisaki"] = "FlameHaze",
	["cv:ShokuhouMisaki"] = "浅仓杏美",
	["illustrator:ShokuhouMisaki"] = "游戏cg",
	["%ShokuhouMisaki"] = "“如果……就算是这样……这样，你还是能颠覆大人的预期，在某一天变得能想起我的事，回忆起我这个人——，我便会对你说一些话，那是我要对你说的，最甜蜜温柔、最重要的话……”",
	["~ShokuhouMisaki"] = "唔..呃呃~（遥控器掉落）",
	["xinkong"] = "心控「强制自白&行为控制」",
	[":xinkong"] = "<font color=\"purple\"><b>出牌阶段开始时，</b></font>可以指定一名其他角色A，选择（A无手牌默认选项一）:<font color=\"cyan\">①</b></font>重铸一张牌并令角色A展示所有手牌；<font color=\"cyan\">②</b></font>指定A以外的一名角色为B，你观看A手牌并获得其中1张，令A对B使用一张杀或失去一点体力（由A决定），本回合你手牌上限+2并结束出牌阶段。",
	["xinkong$"] = "image=image/animate/xinkong.png",
	["@xinkong1"] = "「强制自白」：重铸一张牌并令角色A展示所有手牌",
	["@xinkong2"] = "「行为控制」：观看并获得A1张手牌，令A对B使用一张杀否则其失去一点体力，本回合你手牌上限+2并结束出牌阶段",
	["@xinkonga"] = "选择一名其他角色A",
	["@xinkongb"] = "选择一名除其外的角色为B",
	["&xinkong"] = "选择一张牌",
	["#Card_Recast"] = "重铸选择牌",---"重铸因“%arg”选择的牌",
	["@xinkong-slash"] = "对角色B使用一张杀或失去一点体力",
	["xinkong_max"] = "手牌上限+2",
	["$xinkong1"] = "我一定会...窥探合作者的大脑。",
	["$xinkong2"] = "...真实的想法、行为准则。我会视情况操纵对方的感情和行动。",
	["$xinkong3"] = "把那件事...哔（遥控器音）....详细的告诉我。",
	["$xinkong4"] = "真是的，你突然搭话，我会很难办的，增加了我篡改记忆的麻烦。",
	["paifa"] = "派阀",
	[":paifa"] = "社团技，「女王派阀」。\n加入条件：其他角色准备阶段，你可以询问其是否加入你的「女王派阀」，每名角色限一次。\n社团效果：<font color=\"green\"><b>每回合限一次，</b></font>当「女王派阀」成员于回合外使用牌指定目标时，你可以弃置一张牌令其与你各摸一张牌/令所有成员各重铸一张牌。",
	["paifa$"] = "image=image/animate/paifa.png",
	["#paifatr"] = "派阀",
	["nvking"] = "「女王派阀」",
	["paifa_accept"] = "接受邀请加入「女王派阀」",
	["$refuse_club"] = "%from 拒绝了社团 %arg 的邀请",
	["paifa_draw"] = "可以弃置一张牌，该「女王派阀」成员与你各摸一张牌",
	["paifa_recast"] = "所有「女王派阀」成员各重铸一张牌",
	["@paifa_discard"] = "弃置一张牌",
	["&pf_recast"] = "选择一张牌",
	---["#pf_recast"] = "“%arg”选择的牌重铸",
	["$paifa1"] = "嗯呣~才和御坂同学说完那种话，我就没啥挑战力了。",
	["$paifa2"] = "之前那件事有眉目了吗？",
	["$paifa3"] = "那赶紧告诉我...关于御坂美琴的克隆人——Sisters。",

        ["Renne"] = "玲",
	["@Renne"] = "空之轨迹",
	["#Renne"] = "歼灭天使",
	["designer:Renne"] = "奇洛",
	["%Renne"] = "“超越善恶生死之处，我曾淡然走过”",
	["cv:Renne"] = "西原久美子",
        ["chahui"] = "茶会",
        [":chahui"] = "出牌阶段限一次，你可以对一名角色发起拼点，若你赢，你可以展示牌堆顶X张牌（X为拼点牌点数差）并可以选择其中一张牌视为对其使用之（不计入次数）；若你没赢，其获得你的拼点牌。",
        ["lianwu"] = "镰舞",
        [":lianwu"] = "当你用牌对其他角色造成伤害时，若此伤害牌有点数，你可以令其此回合内无法使用或打出点数大于此牌的牌。",
		["lianwumark"] = "镰舞标记",

		["ShameimaruAya"] = "射命丸文",
	["@ShameimaruAya"] = "東方project",
	["#ShameimaruAya"] = "传统幻想记者",
	["designer:ShameimaruAya"] = "奇洛，东方杀设计组",
	["%ShameimaruAya"] = "“あやややや～”",
	["jilan"] = "疾岚",
	[":jilan"] = "你可以跳过判定阶段和摸牌阶段，然后进行一次判定，你选择一项：1.获得此判定牌和场上的一张与此判定牌花色不同的牌；2.视为使用一张【杀】。",
	["shenfeng"] = "神风",
	[":shenfeng"] = "出牌阶段限一次，你可以弃一张手牌并观看一名角色的手牌，弃置其中至多两张牌，每弃置一张基本牌，其摸一张牌，否则你摸一张牌。",
	["@jilan"] = "疾岚",
	["~jilan"] = "选择【杀】的目标角色→点击确定",
	["jilan-invoke"] = "选择一名角色获得其区域内与此判定牌花色不同的牌",
	["jilan_obtain"] = "获得此判定牌和场上的一张与此判定牌花色不同的牌",
	["jilan_slash"] = "视为使用一张【杀】",

	["Tohka"] = "夜刀神十香",
	["#Tohka"] = "Princess",
	["@Tohka"] = "Date A Live",
	["designer:Tohka"] = "FlameHaze",
	["cv:Tohka"] = "井上麻里奈",
	["aosha"] = "鏖杀",
	[":aosha"] = "①每回合你首次使用的黑杀不计入次数且无距离限制。②出牌阶段限一次，若你没有“王座”，你可以弃置一张非基本牌，选择一种类型的装备牌，检索摸牌堆+弃牌堆一张此类型装备牌置于人物牌上作为“王座”。",
	["jiankai"] = "剑铠",
	[":jiankai"] = "①当你使用杀指定唯一目标时，可以根据“王座”包含的类型触发效果：{武器，弃置目标区域内一张牌；防具/宝物，摸一张牌；坐骑，若你手牌数不小于当前体力值，该杀不可闪避。}出牌阶段结束时，若你此回合发动过效果①，弃置所有“王座” 。②准备阶段/结束阶段 开始时，你可以使用一张“王座”。",
    ["throne"] = "王座",
	["Weapon"] = "武器",
	["Armor"] = "防具",
	["Horse"] = "一般坐骑", --进攻坐骑和防御坐骑的父类，可能存在一些特殊坐骑
	["OffensiveHorse"] = "进攻坐骑",
	["DefensiveHorse"] = "防御坐骑",
	["Treasure"] = "宝物",
	["#jiankai_XD"] = "由于<font color = 'gold'><b>剑铠</b></font>的效果，该「杀」强制无法被闪避。",
	["jiankai_discard"] = "剑铠：弃牌",
	["jiankai_draw"] = "剑铠：摸牌",
	["jiankai_hit"] = "剑铠：不可闪避",
	["@jiankai"] = "剑铠",
	["~jiankai"] = "使用此牌",
	["$aosha1"] = "鏖杀公！",
	["$aosha2"] = "那么，就开始吧！",
	["$aosha3"] = "你在看哪里？",
	["$jiankai1"] = "让你见识一下我的力量！",
	["$jiankai2"] = "鏖杀公—最后之剑！",
	["$jiankai3"] = "这样啊，那没办法了。",
	["~Tohka"] = "果然不行吗？我想要留在这里.....",

	["Violet"] = "薇尔莉特·伊芙加登",
	["&Violet"] = "薇尔莉特",
	["@Violet"] = "紫罗兰永恒花园",
	["#Violet"] = "人如其名",
	["~Violet"] = "",
	["designer:Violet"] = "光临长夜",
	["cv:Violet"] = "石川由依",
	["illustrator:Violet"] = "",
	["vshouji"]="手记",
	[":vshouji"]="出牌阶段限一次，你可以选择一名其他角色，其可以正面朝上交给你一张牌A，若如此做，其可以选择另一名其他角色B，你正面朝上交给B一张手牌，若此牌与A花色或点数相同，B可以立即使用此牌。",
	["gongqing"]="共情",
	[":gongqing"]="每回合限一次，当你获得一名其他角色的牌时/一名其他角色获得你的牌时，你可以弃置一张手牌，令其回复一点体力或手牌补至体力上限（最多摸5张）。",
	["vshoujivs"]="手记",
	["~vshouji"]="选择牌交给目标",
	["@vshouji"]="可以交给 %src 一张牌",
	["@vshouji1"]="手记：可以选择一名目标",
	["gongqingDraw"] = "手牌补至体力上限",
	["gongqingRecover"] = "回复一点体力",
	["%Violet"] = "“你将不再是道具，而是成为人如其名的人”",

	["ZeroTwo"] = "ZeroTwo",
	["@ZeroTwo"] = "DARLING in the FRANXX",
	["#ZeroTwo"] = "比翼之鸟",
	["~ZeroTwo"] = "什么时候都可以，如果我们有名为灵魂的东西，我还会在那个星球，再次与你相遇。我爱你，Darling。",
	["designer:ZeroTwo"] = "FlameHaze",
	["cv:ZeroTwo"] = "户松遥",
	["xieyu"] = "携驭",
	[":xieyu"] = "①若你有明置男性人物牌：当你使用杀时，可以弃置场上一张延时锦囊牌，选择增加一名此杀的合法额外目标。②每回合限一次，当你使用杀结算后，若你另一张人物牌明置，你可以失去一点体力，视为使用一张杀（有范围限制，不计入次数），然后暗置另一张人物牌且不可明置之直到回合结束。",
	["kuanghe"] = "狂鹤",
	[":kuanghe"] = "进入出牌阶段时，若你无明置男性人物牌且手牌不小于场上其他存活角色数：可以弃置所有手牌跳过出牌和弃牌阶段，对所有其他角色各造成一点伤害。当一名角色因“狂鹤”进入濒死状态时，你回复一点体力或摸一张牌。",
	["$xieyu1"] = "嗯~你果然和我是一样的，我们还真是很像呢。人类的眼泪，我很久没见了。",
	["$xieyu2"] = "来~过来吧！",
	["$xieyu3"] = "让我品尝一下你吧~ 从现在开始，你就是我的Darling了！",
	["$xieyu4"] = "纯音乐（鹤望兰启动BGM）",
	["$kuanghe1"] = "这样啊（伴随叫龙血流淌声），那我就认真一点好了~",
	["$kuanghe2"] = "嗬呃~~~，真的好想变成人类啊",
	["xieyu$"] = "image=image/animate/xieyu.png",
    ["kuanghe$"] = "image=image/animate/kuanghe.png",
	["@xieyu1"] = "选择一名判定区有牌的角色",
	["@xieyu"] = "携驭",
	["~xieyu"] = "选择【杀】的目标角色→点击确定",
	["recover"] = "回复体力",

	["Asuka"] = "惣流·明日香·兰格雷",
	["&Asuka"] = "明日香",
	["@Asuka"] = "EVA",
	["#Asuka"] = "第二适格者",
	["designer:Asuka"] = "FlameHaze",
	["cv:Asuka"] = "宫村优子",
	["aoshi"] = "傲势",
	[":aoshi"] = "准备阶段开始时，你可以与一名其他角色拼点，若赢，你对其造成1点伤害，然后若双方点数之差为双数，可以使用一张拼点牌；若输，你失去一点体力。锁定技，与手牌数不小于你的其他角色拼点时，点数增加x（x为已装备的防具+坐骑牌数）。",
    ["xinshang"] = "心伤",
	[":xinshang"] = "当你流失体力后，若因此进入濒死状态，将手牌补至x（x为你的体力上限+1），然后“傲势”失效直到你下回合结束；若未因此进入濒死状态，可以摸一张牌或使用一张手牌（不计入次数)。",
	["@aoshi"] = "你可以视为使用<font color=\"#FF8000\"><b>【%src】</b></font>",
    ["~aoshi"] = "请选择此牌的合法目标，若目标已确定则直接点击“确定”",
	["aoshi$"] = "image=image/animate/aoshi.png",
    ["xinshang$"] = "image=image/animate/xinshang.png",
	["$aoshi1"] = "喝啊~~",
["$aoshi2"] = "因为我是天才，所以和你们这种关系户完全不一样。",
["$aoshi3"] = "你是笨蛋吗？你已经没用了。要比优秀的话，结果显而易见。",
["$aoshi4"] = "世界第一台真正的EVA（PRODUCTION MODEL），是正式机型。",
["$xinshang1"] = "我不要...不要啊！！",
["$xinshang2"] = "杀了你..杀了你...杀了你......",
["$xinshang3"] = "那么，什么都不要做，不要再来我这里了。",
["$xinshang4"] = "你只会伤害我而已。",
["~Asuka"] = "只有我一个人是什么也干不了的。",

["Sakunahime"] = "佐久名",
    ["@Sakunahime"] = "天穗之咲稻姬",
    ["#Sakunahime"] = "天穗之咲稻姬",
    ["designer:Sakunahime"] = "clannad最爱",
    ["cv:Sakunahime"] = "大空直美",
    ["%Sakunahime"] = "“ ”",

    ["gengzhong"] = "耕种",
    [":gengzhong"] = "①与你势力相同的角色使用【桃】、【酒】或食物牌结算后，若“稻”数＜4，则你可以将此牌置于人物牌上，称为“稻”。②出牌阶段结束时，本回合进入弃牌堆的牌每有3张，你可以将1张“稻”分配给与你势力相同的角色。",
    ["paddy"] = "稻",
    ["&gengzhong"] = "选择一名与你势力相同的角色，其选择一张“稻”获得",


	["Nagisa"] = "古河渚",
	["@Nagisa"] = "Clannad",
	["#Nagisa"] = "小镇之光",
	["~Nagisa"] = "（朋也）渚...渚！...渚！......",
	["designer:Nagisa"] = "clannad最爱",
	["cv:Nagisa"] = "中原麻衣",
	["bingruo"] = "病弱",
	[":bingruo"] = "回合开始时，你可以选择一名你对其用“键”为合法目标的其他角色，然后随机将牌堆一张♥牌当作“键”置于其的判定区，然后若你判定区没有键，则你失去一点体力，随机将牌堆一张♥牌当作“键”置于你的判定区；回合结束时，若你判定区有“键”且体力为场上最少之一，你可以选择一名你对其用“键”为合法目标的其他角色，然后随机将牌堆一张♥牌当作“键”置于其的判定区。",
	["yanju"] = "演剧",
	[":yanju"] = "社团技，「光坂高校演剧部」。\n加入条件：当“键”移动到一名其他角色判定区时，你可以询问其是否加入「光坂高校演剧部」。\n社团效果：社团成员的判定区可以放置至多该社团成员数的“键”，社团成员的“键”进行判定时，判定成功条件改为“红色”牌。",
    ["xiyuan"] = "汐愿",
	[":xiyuan"] = "（冈崎朋也&古河渚）连携技，限定技，当你濒死求桃结束时，若你处于濒死状态，你可以将你人物牌中的“古河渚”替换为“冈崎汐”，然后回复一点体力，此阶段至游戏结束人物牌“古河渚”视为游戏内的人物牌。",
	["yanjubu"] = "「光坂高校演剧部」",
	["yanju_accept"] = "接受邀请加入「光坂高校演剧部」",
	["#YanjubuEffect"] = "由于%from 所在的%arg 影响，此次判定成功条件变为“红色牌”。",
	["DaoluA$"] = "image=image/animate/DaoluA.png",
	["@xiyuan"] = "汐愿",
	["%Nagisa"] = "“我希望不论什么时候，你都不要后悔我们的相遇”",

	["$bingruo1"] = "豆沙面包！",
	["$bingruo2"] = "你喜欢这所学校吗？我非常非常喜欢",
	["$bingruo3"] = "但是，这所有的一切，都在不断地改变着",
	["$bingruo4"] = "即使如此，你也会喜欢上这里吗？",
	["$bingruo5"] = "我是B班的古河渚",
	["$bingruo6"] = "是，请多指教，冈崎朋也同学",
	["$bingruo7"] = "这个公园对面的面包店就是我家，方便的话，有时间请来我家坐坐",
	["$bingruo8"] = "啊，你们已经这么要好了啊。（秋生）当然了，怎么能亏待女儿的朋友呢。（yeah）",
	["$bingruo9"] = "让我带您去吧，这个小镇愿望实现的地方",
	["$bingruo10"] = "（朋也）你就是你，现在尽你所能去做就好了，不是吗",
	["$bingruo11"] = "（秋生）去实现梦想吧，渚！",
	["$bingruo12"] = "（朋也）带我们去吧，渚，把我们......",
	["$bingruo13"] = "对不起，擅自做了这样的事情，但是我想还是联系一下比较好",
	["$bingruo14"] = "（朋也）这段时间我变得不怎么讨厌这所学校了。（渚）是吗，真太好了",
	["$bingruo15"] = "这是回礼，嘻嘻",
	["$bingruo16"] = "还是请假休息比较好吧",
	["$bingruo17"] = "无论如何还是想看一下，朋也君最后一次穿制服的样子",
	["$bingruo18"] = "朋也君，恭喜你毕业了。",
	["$bingruo19"] = "不可以因为这样就停下你的脚步，能前进的话就要一直前进，朋也君请继续前进吧。",
	["$bingruo20"] = "朋也君，快起床啦，朋也君",
	["$bingruo21"] = "今天开始要上班了，会迟到的",
	["$bingruo22"] = "可以的话晚饭也让我来做吧",
	["$bingruo23"] = "朋也君不寂寞吗？",
	["$bingruo24"] = "我回去之后，房间里就只剩下朋也君孤单一人。",
	["$bingruo25"] = "每次想到这，我就不禁想哭",
	["$bingruo26"] = "朋也君，搬家后有没有好好去见父亲一面？新家地址有没有好好告诉过他？",
	["$bingruo27"] = "不是现在也没关系，抽个时间我们一起去看一下你的父亲吧。",
	["$bingruo28"] = "我认为选择朋也君觉得最适合的路走下去就可以了",
	["$bingruo29"] = "不行，这样做是在逃避，不能因为这种事就选择逃避",
	["$bingruo30"] = "我只要朋友君在的话，无论去什么地方都行。但是，在离开这座小镇的时候，不怀着积极的心情是不行的。否则的话这里将不再是我们能回来的地方。",
	["$bingruo31"] = "这个小镇是我们出生的地方，是我们的小镇",
	["$bingruo32"] = "朋也君，朋也君！",
	["$bingruo33"] = "我也很没用，但是两个人在一起的话就能变得坚强。",
	["$bingruo34"] = "是的，我一直都会在你身边，无论何时，直到永远。",
	["$bingruo35"] = "靠近了呢。（完全喝醉了）我才没有醉呢！（喝醉的人都这么说！）",
	["$bingruo36"] = "虽然用了五年才毕业，但这是我非常喜欢的学校，是我努力过的地方，真是太感谢大家了！",
	["$bingruo37"] = "我，冈崎渚不会再哭了，无论是多么难过，也会努力去克服。",
	["$bingruo38"] = "不是这样的爸爸，我和朋也君是夫妻，所以",
	["$bingruo39"] = "H的事情也做过了！",
	["$bingruo40"] = "（团子大家族）",

	["$xiyuan1"] = "汐，这个名字怎么样？",
	["$xiyuan2"] = "（比起渚，汐要大的多嘛）是啊，因为是大海嘛。",
	["$xiyuan3"] = "是啊，能在家里生下她真是太好了，虽然这让小汐吃了不少苦",
	["$xiyuan4"] = "请和我交往吧，渚。",
	["xiyuan$"] = "image=image/animate/xiyuan.png",

	["Ushio"] = "岡崎汐",
	["&Ushio"] = "岡崎汐",
	["@Ushio"] = "Clannad",
	["#Ushio"] = "小镇之心",
	["~Ushio"] = "谁来，谁来救救汐...渚.....",
	["designer:Ushio"] = "clannad最爱",
	["cv:Ushio"] = "兴梠里美",
	["dingxin"] = "町心",
	["dingxin$"] = "image=image/animate/dingxin.png",
	["$dingxin1"] = "想去旅行（朋也）那是不可能的",
	["$dingxin2"] = "那么就我们两个人去吧",
	["$dingxin3"] = "但是，也有可以哭的地方。（朋也）嗯？哪里啊",
	["$dingxin4"] = "不，这个就好，喜欢这个",
	["$dingxin5"] = "那是独一无二的",
	["$dingxin6"] = "是为我选，为我买的东西。是爸爸第一次......",
	["$dingxin7"] = "（朋也）但是从今以后会为汐而努力的，所以..",
	["$dingxin8"] = "爸爸，那个，已经...可以不用忍着了吗？",
	["$dingxin9"] = "早苗说过，能哭的地方......只有厕所，和爸爸的怀里",
	["$dingxin10"] = "渚，我终于找到了，只有我能守护的，无可替代的东西",
	["$dingxin11"] = "（朋也）你怎么了，汐...好热！",
	["$dingxin12"] = "爸爸，要战胜阿秋。（朋也）我要待在你身边啦",
	["$dingxin13"] = "有点不甘心（朋也）你是站在我这边的呢。",
	["$dingxin14"] = "现在，现在就想去，去那片花田",
	["$dingxin15"] = "一定要现在才行",
	["$dingxin16"] = "想和爸爸两个人一起去",
	["$dingxin17"] = "没错，是你一直有唱给我听的歌",
	["$dingxin18"] = "再见了，爸爸",
	["$dingxin19"] = "（朋也）渚，我在这里。（渚）朋也君，太好了，你能叫住我。",
	[":dingxin"] = "锁定技。准备阶段开始时，你失去一点体力并随机将一张牌堆一张红桃牌当作“键”置于判定区，你的红桃手牌不计入手牌上限。当你进入濒死时，你可以依次弃置势力相同角色区域内共计12张红桃牌（区域牌可见），然后将体力回复至2，并将此人物牌更换为汐&渚。",
	["%Ushio"] = "“与人为善的小镇关爱镇里的居民，这应该是理所当然的事”",

	["Miyazono"] = "四月是你的谎言",
	
  ["MiyazonoKaori"] = "宫园薰",
  ["@MiyazonoKaori"] = "四月是你的谎言",
  ["#MiyazonoKaori"] = "倾逝之慕",
  ["designer:MiyazonoKaori"] = "FlameHaze",
  ["cv:MiyazonoKaori"] = "种田梨沙",
  ["illustrator:MiyazonoKaori"] = "Teeth-k",
  ["%MiyazonoKaori"] = "“Eloim Essaim Eloim Essaim 请聆听我的请求！”",
  ["~MiyazonoKaori"] = "我好害怕...好害怕...好害怕啊",
  
  ["zhilians"] = "秩恋",
  [":zhilians"] = "首次明置该人物牌时，令一名其他角色获得“恋”标记。当拥有“恋”的角色受到伤害时，可以令其摸一张牌，你受到等量伤害。",
  ["zhilians$"] = "image=image/animate/zhilians.png",
  ["@zhilians"] = "选择一名其他角色获得“恋”标记",
  ["$zhilians1"] = "看着我，抬起头，好好地看着我。",
  ["$zhilians2"] = "就因为你一直向下看，才会被关进五线谱的牢笼里。",
  ["$zhilians3"] = "没问题的，你的话肯定能做到。",
  ["@lian"] = "恋",
  ["#zhiliansShown"] = "秩恋",
  
  ["yixins"] = "遗信",
  [":yixins"] = "当你受到伤害后或进入濒死状态时，摸x张牌并将1~x张牌暗置于一名其他角色人物牌上作为“遗信”(x为你已损失体力值，至多2），若你进入濒死后未被救回，该角色可以立即获得人物牌上所有“遗信”。<font color=\"orange\">永久效果：一名其他角色摸牌阶段开始时，获得人物牌上的所有“遗信”，本回合手牌上限+1。</b></font>",
  ----[":yixins"] = "当你受到伤害后或进入濒死状态时，摸x张牌并将1~x张牌置于一名其他角色人物牌上作为“遗信”(x为你已损失体力值，至少1），若你进入濒死后未被救回，该角色可以立即获得人物牌上所有“遗信”。<font color=\"orange\">永久效果：一名其他角色摸牌阶段开始时，获得人物牌上的所有“遗信”，本回合手牌上限+1。</b></font>",
  ["yixins$"] = "image=image/animate/yixins.png",
  ["yixin"] = "遗信",
  ["@yixins"] = "选择放置“遗信”的目标",
  ["&yixins"] = "选择1~x张牌作为“遗信”",
  ["yixin_Current"] = "当前“遗信”目标",
  ["@yixin_can"] = "获得你人物牌上所有“遗信”",
  ["$yixins1"] = "看，奇迹什么的，是马上就会发生的吧。",
  ["$yixins2"] = "嗬~呼~呵呵~，你就在我心中哦！有马公生君。",
  ["$yixins3"] = "还有好多我所不知道的东西，我好羡慕什么都知道的小椿。",
  ["$yixins4"] = "BGM（贝多芬第9小提琴奏鸣曲A大调Op.47）",
  
  ["hezous"] = "合奏",
  [":hezous"] = "当你阵亡时，可以将所有牌置于一名存在“遗信”牌堆的角色人物牌上作为“幻奏”，其下个出牌阶段开始时获得所有“幻奏”且本回合其使用的“幻奏”牌不计入额定次数。",
  ["hezous$"] = "image=image/animate/hezous.png",
  ["@hezous"] = "选择一名人物牌上存在“遗信”的角色",
  ["huanzou"] = "幻奏",
  ["$hezous1"] = "这份心意传递到了吗？能传递到就好了。",
  ["$hezous2"] = "BGM（肖邦第一叙事曲Op.23）",
}

return {extension}