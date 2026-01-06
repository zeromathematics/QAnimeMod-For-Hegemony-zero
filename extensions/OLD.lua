extension = sgs.Package("OLD", sgs.Package_GeneralPack)

Matsuri = sgs.General(extension, "Matsuri", "real", 3, false)
Youko = sgs.General(extension, "Youko", "magic", 3, false)
Yomi = sgs.General(extension, "Yomi", "science", 3, false)
Testarossa = sgs.General(extension, "Testarossa", "science", 4, false)
Asa = sgs.General(extension, "Asa", "game", 3, false)
NatalieHannah = sgs.General(extension, "NatalieHannah", "idol", 4, false)
NanamiRuchia = sgs.General(extension, "NanamiRuchia", "idol", 3, false)

--Matsuri轮次变化
Roundcount = sgs.CreateTriggerSkill{
	name = "Roundcount", 
	global = true,
	events = {sgs.TurnStart, sgs.GeneralRemoved, sgs.RemoveStateChanged, sgs.Death},
		---priority = 5,
	on_record = function(self, event, room, player, data) 
        if event == sgs.TurnStart then
			if player and player:isAlive() and (player:getActualGeneral1Name() ==  "Matsuri" or player:getActualGeneral2Name() ==  "Matsuri") and not player:hasFlag("Point_ExtraTurn") then--------
			    room:setPlayerMark(player, "&Roundcount", player:getMark("&Roundcount")+1)
				if player:hasShownSkill("yehuo") then
					if math.fmod(player:getMark("&Roundcount") + 1, 2) == 0 then
					   room:setPlayerMark(player, "##even", 0)
					   room:setPlayerMark(player, "##Odd", 1)
					elseif math.fmod(player:getMark("&Roundcount") + 1, 2) ~= 0 then
					   room:setPlayerMark(player, "##Odd", 0) 
					   room:setPlayerMark(player, "##even", 1)
					end
				end
				if player:getMark("&jiqiongused") > 0 then----冀穹次数重置
				   room:setPlayerMark(player, "&jiqiongused", 0)
				end   
			end
		end
		if (event == sgs.GeneralRemoved or event == sgs.RemoveStateChanged) and data:toString() == "Matsuri" then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			   if not p:hasSkill("yehuo") and (p:getMark("##even")> 0 or p:getMark("##Odd")> 0)  then 
			        room:setPlayerMark(p, "&Roundcount", 0)
					room:setPlayerMark(p, "&jiqiongused", 0)
					room:setPlayerMark(p, "##even", 0)
					room:setPlayerMark(p, "##Odd", 0)
			   end
			end
		end
		if event==sgs.Death then
		   local death = data:toDeath()
			---if death.who:getActualGeneral1Name() ==  "Matsuri" or death.who:getActualGeneral2Name() ==  "Matsuri" then
			if death.who:hasSkill("yehuo") then
			    room:setPlayerMark(death.who, "&Roundcount", 0)
				room:setPlayerMark(death.who, "&jiqiongused", 0)
				room:setPlayerMark(death.who, "##even", 0)
			    room:setPlayerMark(death.who, "##Odd", 0)
			--elseif death.who:getMark("@liufangzhe") > 0 then
                --room:doAnimate(2, "anim=skills/liufang") 	
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return "" 
	end,
}
 	

---冀穹

jiqiongvs=sgs.CreateZeroCardViewAsSkill{
 name="jiqiong",
 view_as = function(self)
   local pattern = sgs.Self:property("jiqiong_card"):toString()
   local idm=sgs.Self:property("jiqiong_number"):toInt()
   if pattern == "" then return nil end
   local vs = sgs.Sanguosha:cloneCard(pattern) 
   --local vs = sgs.Sanguosha:getCard(pattern)
   vs:addSubcard(sgs.Sanguosha:getCard(idm))
   return vs
 end,
 enabled_at_play=function(self,player)
   return false
 end,
 enabled_at_response = function(self, player, pattern)
    return pattern == "@@jiqiong"
 end
}

jiqiong = sgs.CreateTriggerSkill{
	name = "jiqiong",
	can_preshow = true,
	events = {sgs.HpLost, sgs.TurnStart},
	view_as_skill=jiqiongvs,
	----priority = 3,
    can_trigger = function(self, event, room, player, data)
	    if event == sgs.TurnStart then
		    local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
			   if sp ~= player then return false end
			   if sp and sp:isAlive() and sp:hasSkill(self:objectName()) and sp:getMark("&jiqiongused") == 0 and math.fmod(player:getMark("&Roundcount") + 1, 2) ~= 0 then
				  return self:objectName(), sp
			   end
			end   
        end
		if event == sgs.HpLost then
		    local players = room:findPlayersBySkillName(self:objectName())
			for _,p in sgs.qlist(players) do
			   if p and p:isAlive() and p:hasSkill(self:objectName()) and p == player then
				  return self:objectName(), p
			   end
			end   
        end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
	    if event == sgs.TurnStart then
			room:setPlayerMark(ask_who, "&jiqiongused", 1)
			if ask_who:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName(), ask_who)
				return true
			end
		end
		if event == sgs.HpLost then
			if ask_who:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName(), ask_who)
				return true
			end
		end	
		return false
	end,
    on_effect = function(self, event, room, player, data, ask_who)
		local list = sgs.IntList()
		local drawlist = room:getDrawPile()
		if drawlist:isEmpty() then return false end
		for _, id in sgs.qlist(room:getDrawPile()) do
			if sgs.Sanguosha:getCard(id) then
			   list:append(id)
			   break
			end 
		end
		if room:getDrawPile():length() > 1 then
			for i = 1, 1, 1 do
				if drawlist:length()-2+i >= 0 then
					list:append(drawlist:at(drawlist:length()-2+i))
				end
			end
		end
		local dis = sgs.IntList()
		for _,s in sgs.qlist(list) do
			local card = sgs.Sanguosha:getCard(s)
			if not card:isAvailable(ask_who) then
				dis:append(s)
			end
		end
		if not dis:isEmpty() then
		    if not list:isEmpty() then
			    room:fillAG(list, nil)
				local log = sgs.LogMessage()
				log.type = "$jiqiongshow"
				log.from = ask_who
				log.arg = self:objectName()
				log.card_str = table.concat(sgs.QList2Table(list), "+")
				room:sendLog(log)
				room:getThread():delay(1300)
				room:clearAG()
				room:clearAG(ask_who)
				local dummyX = sgs.DummyCard(list)
				room:throwCard(dummyX, sgs.CardMoveReason(0x1A, ask_who:objectName(), self:objectName(), ""), nil)
				dummyX:deleteLater()
			end
		elseif dis:isEmpty() then
		    room:fillAG(list, nil, dis)
			idm = room:askForAG(ask_who, list, false, self:objectName())
			local log = sgs.LogMessage()
			log.type = "$jiqiongshow"
			log.from = ask_who
			log.arg = self:objectName()
			log.card_str = table.concat(sgs.QList2Table(list), "+")
			room:sendLog(log)
			---room:getThread():delay(1300)
			room:clearAG()
			room:clearAG(ask_who)
			---list:removeOne(idm)
			--[[if not list:isEmpty() then
				local dummyX = sgs.DummyCard(list)
				room:throwCard(dummyX, sgs.CardMoveReason(0x1A, ask_who:objectName(), self:objectName(), ""), nil)
				dummyX:deleteLater()
			end]]
			if idm >=0 then
			   local car=sgs.Sanguosha:getCard(idm)
			   if car:isKindOf("EquipCard") then
			      local use=sgs.CardUseStruct()
				  use.card=car 
				  use.from=ask_who
				  use.to:append(ask_who)
				  room:useCard(use)
				elseif not car:isKindOf("EquipCard") then  
				   room:setPlayerProperty(ask_who,"jiqiong_card",sgs.QVariant(car:objectName()))
				   room:setPlayerProperty(ask_who,"jiqiong_number",sgs.QVariant(idm))
				   room:askForUseCard(ask_who, "@@jiqiong", "@jiqiong:" .. tostring(car:getName()))
		           --room:askForUseCard(ask_who, "@@jiqiong", "@jiqiong")
				   ---room:setPlayerProperty(ask_who, "jiqiong_card", sgs.QVariant())
				end   
			   --[[local to = room:askForPlayerChosen(ask_who, room:getAlivePlayers(), self:objectName())                        
				local use = sgs.CardUseStruct()
				use.from = ask_who
				use.to:append(to)
				use.card = sgs.Sanguosha:getCard(idm)
				room:useCard(use, false)]]
			end
		end	
    end,
}


---坏蚀
huaishi = sgs.CreateTriggerSkill{
	name = "huaishi",
	----priority = 4,
	events = {sgs.EventPhaseChanging, sgs.Damage},---sgs.TurnStart, 
	on_record = function(self, event, room, player, data)
		--[[if event == sgs.TurnStart then 
			if player:getMark("&huaishiused")>0 and not player:hasFlag("Point_ExtraTurn") then
				room:setPlayerMark(player, "&huaishiused", 0)
			end
		end]]
		if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
		    if player:getMark("##huaishiloseMaxHp")>0 and change.to == sgs.Player_NotActive then
			   local x = player:getMark("##huaishiloseMaxHp")
			   room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+x))
			   room:setPlayerMark(player, "##huaishiloseMaxHp", 0)
			end	
		end
	end,
    can_trigger = function(self, event, room, player, data)
	    if event == sgs.Damage then
			local damage= data:toDamage()
			if player:hasSkill(self:objectName()) and player:objectName() == damage.from:objectName() and damage.to:isAlive() and damage.to:getMark("##huaishiloseMaxHp") == 0 and player:isAlive() then---and player:getMark("&huaishiused") == 0
			   if (player:inHeadSkills(self) and not player:hasShownGeneral2()) or (player:inDeputySkills(self) and not player:hasShownGeneral1()) or (player:getHp() == 1) then
				    return self:objectName()
				end   
			end
		end	
		return ""
	end,
	on_cost = function(self, event, room, player, data)
	    if player:askForSkillInvoke(self, data) then
		    ---room:setPlayerMark(player, "&huaishiused", 1)
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
	end,
    on_effect = function(self, event, room, player, data)
		if event == sgs.Damage then
            local damage= data:toDamage()
			room:loseMaxHp(damage.to)
			room:setPlayerMark(damage.to, "##huaishiloseMaxHp", 1)
			---room:setPlayerMark(damage.to, "##huaishiloseMaxHp", damage.to:getMark("##huaishiloseMaxHp")+1)
		end	
    end,
}


---夜祸
yehuo = sgs.CreateTriggerSkill{
	name = "yehuo",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventAcquireSkill, sgs.EventPhaseChanging, sgs.Damaged, sgs.GeneralShown, sgs.DamageForseen},----sgs.Death
	on_record = function(self, event, room, player, data)
	    if event == sgs.EventAcquireSkill then
			if data:toString():split(":")[1] == self:objectName() then
				local num = player:getMark("&Roundcount")
				if math.fmod(num + 1, 2) == 0 then
				   room:setPlayerMark(player, "##even", 0)
				   room:setPlayerMark(player, "##Odd", 1)
				elseif math.fmod(num + 1, 2) ~= 0 then
				   room:setPlayerMark(player, "##Odd", 0) 
				   room:setPlayerMark(player, "##even", 1)
				end
			end
		end
		if event == sgs.Damaged and player and player:isAlive() and not room:getCurrent():hasFlag(player:objectName().."yehuo") then
			room:setPlayerFlag(room:getCurrent(), player:objectName().."yehuo")
		end
	end,
    can_trigger = function(self, event, room, player, data)
	    if event == sgs.DamageForseen then
			local damage = data:toDamage()
			if player:isAlive() and player:hasSkill("yehuo") then
				local num = player:getMark("&Roundcount")
				if math.fmod(num + 1, 2) == 0 then
				   return self:objectName()
				end
			end
		end	
		if event == sgs.GeneralShown then
	        if player and player:isAlive() and player:inHeadSkills(self) == data:toBool() and player:hasSkill(self:objectName()) then
                return self:objectName()
            end
        end
		--[[if event == sgs.Death then
		    local death = data:toDeath()
			if death.who:objectName() == player:objectName() and player:hasSkill(self:objectName()) and player:objectName() == room:getCurrent():objectName() then
				return self:objectName()
			end
		end]]
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local players = room:findPlayersBySkillName(self:objectName())
            for _,Matsuri in sgs.qlist(players) do
				if (change.to == sgs.Player_NotActive) and Matsuri:hasSkill("yehuo") and Matsuri:isWounded() and room:getCurrent():hasFlag(Matsuri:objectName().."yehuo") then
					return self:objectName(), Matsuri
				end
			end	
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
	    if event == sgs.DamageForseen or event == sgs.GeneralShown then
			if player:hasShownSkill("yehuo") or player:askForSkillInvoke(self:objectName()) then
				---room:broadcastSkillInvoke(self:objectName())
				---room:doLightbox("yehuo$", 800)
				return true
			end
		end
		--[[if event == sgs.Death then 
		   if  player:hasShownSkill("yehuo") or player:askForSkillInvoke(self:objectName()) then
				return true
			end	
		end]]	
		if event == sgs.EventPhaseChanging then 
		   if ask_who:hasShownSkill("yehuo") or ask_who:askForSkillInvoke(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName())
				---room:doLightbox("yehuo$", 800)
				return true
			end	
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, ask_who)
	    if event==sgs.DamageForseen then
			local damage = data:toDamage()
			room:loseHp(player,damage.damage)
			return true
		end
		if event == sgs.GeneralShown then
            local num = player:getMark("&Roundcount")
			if math.fmod(num + 1, 2) == 0 then
			   room:setPlayerMark(player, "##even", 0)
			   room:setPlayerMark(player, "##Odd", 1)
			elseif math.fmod(num + 1, 2) ~= 0 then
			   room:setPlayerMark(player, "##Odd", 0) 
			   room:setPlayerMark(player, "##even", 1)
			end
        end
		--[[if event == sgs.Death then
           	local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yehuo-invoke", false, false)
			----local to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "yehuo-invoke", true, true)
			if to then
			   room:acquireSkill(to, "yehuoone")
			end
		end]]
		if event == sgs.EventPhaseChanging then
		    local recover = sgs.RecoverStruct()
			recover.who = ask_who
			recover.recover = 1
			room:recover(ask_who, recover, true)
		end	
    end,
}
---夜祸①
--[[yehuoone = sgs.CreateTriggerSkill{
	name = "yehuoone",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart, sgs.EventAcquireSkill, sgs.EventPhaseChanging, sgs.Damaged, sgs.GeneralShown, sgs.DamageForseen, sgs.Death},
	on_record = function(self, event, room, player, data)
	    if event == sgs.TurnStart then
			if player and player:isAlive() and player:hasSkill("yehuoone") and not player:hasFlag("Point_ExtraTurn") then
			    room:setPlayerMark(player, "&Roundcount", player:getMark("&Roundcount")+1)
				if player:hasShownSkill("yehuoone") then
					if math.fmod(player:getMark("&Roundcount") + 1, 2) == 0 then
					   room:setPlayerMark(player, "##even", 0)
					   room:setPlayerMark(player, "##Odd", 1)
					elseif math.fmod(player:getMark("&Roundcount") + 1, 2) ~= 0 then
					   room:setPlayerMark(player, "##Odd", 0) 
					   room:setPlayerMark(player, "##even", 1)
					end
				end   
			end
		end
	    if event == sgs.EventAcquireSkill then
			if data:toString():split(":")[1] == self:objectName() then
				local num = player:getMark("&Roundcount")
				if math.fmod(num + 1, 2) == 0 then
				   room:setPlayerMark(player, "##even", 0)
				   room:setPlayerMark(player, "##Odd", 1)
				elseif math.fmod(num + 1, 2) ~= 0 then
				   room:setPlayerMark(player, "##Odd", 0) 
				   room:setPlayerMark(player, "##even", 1)
				end
			end
		end
		if event == sgs.Damaged and player and player:isAlive() and not room:getCurrent():hasFlag(player:objectName().."yehuoone") then
			room:setPlayerFlag(room:getCurrent(), player:objectName().."yehuoone")
		end
		if event==sgs.Death then
		   local death = data:toDeath()
			if death.who:hasSkill("yehuoone") then
			    room:setPlayerMark(death.who, "&Roundcount", 0)
				room:setPlayerMark(death.who, "##even", 0)
			    room:setPlayerMark(death.who, "##Odd", 0)
			end
		end
	end,
    can_trigger = function(self, event, room, player, data)
	    if event == sgs.DamageForseen then
			local damage = data:toDamage()
			if player:isAlive() and player:hasSkill("yehuoone") then
				local num = player:getMark("&Roundcount")
				if math.fmod(num + 1, 2) == 0 then
				   return self:objectName()
				end
			end
		end	
		if event == sgs.GeneralShown then
	        if player and player:isAlive() and player:inHeadSkills(self) == data:toBool() and player:hasSkill(self:objectName()) then
                return self:objectName()
            end
        end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			local players = room:findPlayersBySkillName(self:objectName())
            for _,Matsuri in sgs.qlist(players) do
				if (change.to == sgs.Player_NotActive) and Matsuri:hasSkill("yehuoone") and Matsuri:isWounded() and room:getCurrent():hasFlag(Matsuri:objectName().."yehuoone") then
					return self:objectName(), Matsuri
				end
			end	
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
	    if event == sgs.DamageForseen or event == sgs.GeneralShown then
			if player:hasShownSkill("yehuoone") or player:askForSkillInvoke(self:objectName()) then
				return true
			end
		end
		if event == sgs.EventPhaseChanging then 
		   if ask_who:hasShownSkill("yehuoone") or ask_who:askForSkillInvoke(self:objectName()) then
				return true
			end	
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, ask_who)
	    if event==sgs.DamageForseen then
			local damage = data:toDamage()
			room:loseHp(player,damage.damage)
			return true
		end
		if event == sgs.GeneralShown then
            local num = player:getMark("&Roundcount")
			if math.fmod(num + 1, 2) == 0 then
			   room:setPlayerMark(player, "##even", 0)
			   room:setPlayerMark(player, "##Odd", 1)
			elseif math.fmod(num + 1, 2) ~= 0 then
			   room:setPlayerMark(player, "##Odd", 0) 
			   room:setPlayerMark(player, "##even", 1)
			end
        end
		if event == sgs.EventPhaseChanging then
		    local recover = sgs.RecoverStruct()
			recover.who = ask_who
			recover.recover = 1
			room:recover(ask_who, recover, true)
		end	
    end,
}]]


---缩地
suodi = sgs.CreateTriggerSkill{
	name = "suodi",
    events = {sgs.BeforeCardsMove},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.BeforeCardsMove then
		   local move = data:toMoveOneTime()
		   ----if room:getCurrent():getPhase() == sgs.Player_Discard then return false end
		   if (player:isDead() or not player:hasSkill(self:objectName())) then return false end
		   if player:getPhase()~=sgs.Player_Play then return false end
		   if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
                and (not move.to or move.to:objectName() ~= player:objectName() or (move.to_place ~= sgs.Player_PlaceHand and move.to_place ~= sgs.Player_PlaceEquip)) and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) then
					return self:objectName()  
		   end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if event == sgs.BeforeCardsMove and (player:hasShownSkill("suodi") or player:askForSkillInvoke(self, data)) then
		   return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
	    if event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getAlivePlayers()) do
				if p:isFriendWith(player) and (p:getJudgingArea():length()>0 or not p:isNude()) then
					targets:append(p)
				end
			end
			if targets:isEmpty() then return false end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "@suodi", false, false)
			if target then
				local idg = room:askForCardChosen(target, target, "hej", self:objectName())
				local cardg = sgs.Sanguosha:getCard(idg)
				if cardg then
					room:moveCardTo(cardg, target, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x09, target:objectName(), self:objectName(), ""))
					local log = sgs.LogMessage()
					log.type = "$suodiMoveToDiscardPile"
					log.from = target
					log.card_str = cardg:toString()
					room:sendLog(log)
					local ids = move.card_ids
					local dummy = {}
					local i = 0
					for _,card in sgs.qlist(ids) do
						local id = sgs.Sanguosha:getCard(card)
						table.insert(dummy, id)
					end
					local count = #dummy
					if count > 0 then
						for _,c in pairs(dummy) do
							local cid = c:getEffectiveId()
							ids:removeOne(cid)
						end
					end
				end
				if target ~= player then
				   target:drawCards(1)
				end
				data:setValue(move)
			end	
		end	
	end
}




---邪炎

sheyanyoukoCard = sgs.CreateSkillCard{
    name = "sheyanyoukoCard",
	will_throw = false,
	---handling_method = sgs.Card_MethodNone,
	mute = true,
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() and not to_select:isKongcheng()
    end,
	feasible = function(self, targets)
		return #targets > 0
	end,
    on_use = function(self, room, player, targets)
	    local tag = sgs.QVariant()
		tag:setValue(targets[1])
		room:setTag("sheyanyoukoTarget", tag)
		local card_to_use = sgs.IntList()
		for _, sd in sgs.qlist(self:getSubcards()) do
			card_to_use:append(sd)
	    end
		local n = 0
		for _, id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if card:getSuit() == self:getSuit() then
			----if card:getColor() == self:getColor() then
				card_to_use:append(id)
				n = n + 1
			end
			if n==1 then break end
		end
		if not card_to_use:isEmpty() then
		    --[[for _,ig in sgs.qlist(card_to_use) do
				for _,fid in sgs.qlist(card_to_use) do
					if ig ~= fid and sgs.Sanguosha:getCard(ig):getType() == sgs.Sanguosha:getCard(fid):getType() then
						room:setPlayerMark(player, "&sheyanyoukomove", 1)
					end
				end
			end]]
			local choice 
			choice = room:askForChoice(player, "sheyanyouko", "ccw+cw")
			if choice == "ccw" then
				player:setFlags("sheyanyoukoccw")
			elseif choice == "cw" then
				player:setFlags("sheyanyoukocw")
			end
			for _,targetA in ipairs(targets) do
				local list = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if player:hasFlag("sheyanyoukoccw") then
						if targetA:getSeat()> player:getSeat() then----逆时针
							if p:getSeat() > player:getSeat() and p:getSeat()<= targetA:getSeat() and not p:isKongcheng()then 
							  list:append(p)
							end  
						elseif targetA:getSeat()< player:getSeat() then 
							if (p:getSeat() > player:getSeat() or p:getSeat()<= targetA:getSeat()) and not p:isKongcheng()then
							   list:append(p) 
							end
						end
					elseif player:hasFlag("sheyanyoukocw")	then
						if targetA:getSeat()> player:getSeat() then----顺时针
							if (p:getSeat() < player:getSeat() or p:getSeat()>= targetA:getSeat()) and not p:isKongcheng()then 
							  list:append(p)
							end  
						elseif targetA:getSeat()< player:getSeat() then 
							if p:getSeat() < player:getSeat() and p:getSeat()>= targetA:getSeat() and not p:isKongcheng()then
							   list:append(p) 
							end
						end
					end
				end
				if player:hasFlag("sheyanyoukoccw") then
					player:setFlags("-sheyanyoukoccw")
				elseif player:hasFlag("sheyanyoukocw")	then
				   player:setFlags("-sheyanyoukocw")
				end   
				if not list:isEmpty()then  
				    if player:getMark("&sheyanyoukomove") > 0 then
					   room:doAnimate(2, "anim=skills/sheyanyouko")
					end
					local cards = sgs.Sanguosha:cloneCard("fire_attack")
					cards:setSkillName("sheyanyouko")
					for _,i in sgs.qlist(card_to_use) do
						cards:addSubcard(i)
					end
					room:useCard(sgs.CardUseStruct(cards,player,list), true)
					cards:deleteLater()
				end
				room:removeTag("sheyanyoukoTarget")
			end	
		end
    end,
}

sheyanyoukovs = sgs.CreateViewAsSkill{
	name = "sheyanyouko",
	view_filter=function(self,selected,to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		local vs = sheyanyoukoCard:clone()
		if #cards == 0 then return nil end
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])                
        end 
		vs:setShowSkill(self:objectName())	
		vs:setSkillName(self:objectName())		
		return vs 	
	end,
	enabled_at_play=function(self,player,pattern)
	    local a = 1
		if player:getMark("&sheyanyoukomove") > 0 then
			a = 2
		end
		return player:usedTimes("#sheyanyoukoCard") < a
	end,
}

sheyanyouko = sgs.CreateTriggerSkill{
	name = "sheyanyouko",
	can_preshow = true,
	view_as_skill = sheyanyoukovs,
	events = {sgs.CardFinished ,sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
	    if event == sgs.CardFinished then			
			local use = data:toCardUse()
			if player:isAlive() and use.card:getSkillName() == "sheyanyouko" then
				for _,ig in sgs.qlist(use.card:getSubcards()) do
					for _,fid in sgs.qlist(use.card:getSubcards()) do
						if ig ~= fid and sgs.Sanguosha:getCard(ig):getType() == sgs.Sanguosha:getCard(fid):getType() then
							room:setPlayerMark(player, "&sheyanyoukomove", 1)
						end
					end
				end
			end
		end	
		if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("&sheyanyoukomove") > 0 then
				room:setPlayerMark(player, "&sheyanyoukomove", 0)
			end
		end
		return ""
	end,
	can_trigger = function(self, event, room, player, data)
		return "" 
	end,
}



---除灵
chulingCard = sgs.CreateSkillCard{
    name = "chulingCard",
    filter = function(self, targets, to_select)
        return #targets == 0 and (to_select:hasEquip() or to_select:getJudgingArea():length() > 0) and sgs.Self:inMyAttackRange(to_select)
    end,
	feasible = function(self, targets)
		return #targets > 0
	end,
    on_use = function(self, room, source, targets)
		--[[local suit = sgs.Sanguosha:getCard(self:getSubcards():first()):getSuit()
		local target = targets[1]
		local list = sgs.IntList()
		for _,c in sgs.qlist(target:getCards("ej")) do
			if c:getSuit() == suit then
				list:append(c:getEffectiveId())
			end
		end]]
		local target = targets[1]
		local list = sgs.IntList()
		for _,c in sgs.qlist(target:getCards("ej")) do
			---if sgs.Sanguosha:getCard(c) then
			   list:append(c:getEffectiveId())
			---end  
		end
		if not list:isEmpty() then
			room:fillAG(list, source)
			local id = room:askForAG(source, list, false, self:objectName())
			local cardg = sgs.Sanguosha:getCard(id)
			room:clearAG(source)
			if cardg then
				room:moveCardTo(cardg, target, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, source:objectName(), self:objectName(), ""))
				local log = sgs.LogMessage()
				log.type = "$RecastCard"
				log.from = target
				log.card_str = cardg:toString()
				room:sendLog(log)
				target:drawCards(1, "recast")
			end 
			if not room:askForCard(source, ".|"..cardg:getSuitString().."|.|hand", "chulingSuit", sgs.QVariant(), sgs.Card_MethodDiscard) then
			   ----room:askForDiscard(source, "chuling", 2, 2, false, true)
			   room:loseHp(source)
			end
		end	
    end,
}

chuling = sgs.CreateZeroCardViewAsSkill{
	name = "chuling",
	view_as = function(self, cards)
		local vs = chulingCard:clone()
		vs:setShowSkill(self:objectName())	
		---vs:setSkillName(self:objectName())		
		return vs 	
	end,
	enabled_at_play = function(self, player)
		return player:usedTimes("#chulingCard") < 2
	end,
}


---乱红莲
luanhonglian = sgs.CreateTriggerSkill{
	name = "luanhonglian",
	events = {sgs.CardsMoveOneTime},---sgs.EventPhaseChanging, 
	--[[on_record = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if event == sgs.EventPhaseChanging and change.to == sgs.Player_NotActive then
			for _,Yomi in sgs.qlist(room:getAlivePlayers()) do
				if Yomi:getMark("#luanhonglianA") > 0 then
					room:setPlayerMark(Yomi, "#luanhonglianA", 0)
				end
			end
		end
	end,]]
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local reason = move.reason
			local basic = bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if player and player:isAlive() and player:hasSkill(self:objectName()) and move.card_ids:length() == 1 and basic ~= 0x01 and basic ~= 0x02 and basic ~= 0x03 and (move.from_places:contains(sgs.Player_PlaceDelayedTrick) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.to_place == sgs.Player_DiscardPile then
				 for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:inMyAttackRange(player) and player:canSlash(p, false) then---and player:getMark("#luanhonglianA") < 3
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local targets = sgs.SPlayerList()
			for _, p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:inMyAttackRange(player) and player:canSlash(p, false) then
					targets:append(p)
				end
			end

			if targets:isEmpty() then return false end

			local target = room:askForPlayerChosen(player, targets, self:objectName(), "@luanhonglian", true, true)
			if target then
				room:setPlayerProperty(player, "luanhonglian_target", sgs.QVariant(target:objectName()))
				---room:broadcastSkillInvoke("luanhonglian", player)
				---------room:setPlayerMark(player, "#luanhonglianA", player:getMark("#luanhonglianA") + 1)
				return true
			end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
		   room:doLightbox("luanhonglian$", 500)
		   local target_name = player:property("luanhonglian_target"):toString()
			player:removeTag("luanhonglian_target")
			local target = findPlayerByObjectName(target_name)
			if target and player:canSlash(target, false) then
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName(self:objectName())
				local use = sgs.CardUseStruct()
				use.card = slash
				use.from = player
				use.to:append(target)
				room:useCard(use, false)
			end	
		end
	end,
}
---失心
eling = sgs.CreateTriggerSkill{
	name = "eling",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Death},
    can_trigger = function(self, event, room, player, data)	
		if event==sgs.Death then
		   local death = data:toDeath()
		   if death.damage and death.damage.from and death.damage.from == player and player:hasSkill(self:objectName()) then---and death.damage.from:isFriendWith(death.damage.to)
		      return self:objectName()
		   end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("eling") or player:askForSkillInvoke(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName())
			room:doLightbox("eling$", 800)
			return true
		end	
		return false
	end,
    on_effect = function(self, event, room, player, data)
		if event==sgs.Death then
		    local death = data:toDeath()
			---room:setPlayerMark(player, "#luanhonglianA", 0)
			room:addPlayerHistory(player,"#chulingCard",-player:usedTimes("#chulingCard"))
			if player:isFriendWith(death.damage.to)then
				local kingdom = player:getKingdom()
				local role = player:getRole()
				room:setPlayerProperty(player, "kingdom" ,sgs.QVariant("careerist"))
				room:setPlayerProperty(player, "role" ,sgs.QVariant("careerist"))
				room:setPlayerProperty(player, "hp", sgs.QVariant(0))
			end	
		end
    end,
}



leiguang = sgs.CreateTriggerSkill{
	name = "leiguang" ,
	events = {sgs.CardUsed},	
	can_trigger = function(self, event, room, player, data)
	   if event == sgs.CardUsed then			
			local use = data:toCardUse()
			if player:isAlive() and player:hasSkill("leiguang") and player:objectName() == use.from:objectName() and use.card:isKindOf("Slash") then
				if player:getMark("SingleTargetTrick") > 0 or player:getMark("toplayer") > 0 or player:getMark("Thunder") > 0 then
  				    return self:objectName()
				end	
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
	    if event == sgs.CardUsed then			
			local use = data:toCardUse()
		    if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
		       room:broadcastSkillInvoke("leiguang")
			   --room:doLightbox("leiguang$", 1000)
		       return true
		    end
		end	
		return false	
	end,
	on_effect = function(self, event, room, player, data)
	    if event == sgs.CardUsed then
	        local use = data:toCardUse()
			if player:getMark("Thunder") > 0 then 
				local list = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				   if not use.to:contains(p) then list:append(p) end
				end
				local targets = room:askForPlayersChosen(player, list, self:objectName(), 0, 1, "leiguangtarget")
				if not targets:isEmpty() then
				   for _,p in sgs.qlist(targets) do
					 if not use.to:contains(p) then use.to:append(p) end
				   end
				   data:setValue(use)
				end
			end
			if player:getMark("SingleTargetTrick") > 0 then
				---room:addPlayerHistory(player, use.card:getClassName(),-1)
				for _,i in sgs.qlist(room:getAlivePlayers()) do
					if use.to:contains(i) and not i:isChained()then
						room:setPlayerProperty(i, "chained", sgs.QVariant(true))
					end
				end
			end	
			if player:getMark("toplayer") > 0 then
			       player:drawCards(1)
				   room:doLightbox("leiguang$", 800)
				   local log = sgs.LogMessage()
				   log.type = "$UseCard_thunder"
				   log.from = player
				   log.arg = self:objectName()
				   log.card_str = use.card:toString()
				   room:sendLog(log)
				   local newslash=sgs.Sanguosha:cloneCard("thunder_slash",use.card:getSuit(),use.card:getNumber())
				   newslash:addSubcard(use.card:getId())
				   use.card=newslash
				   data:setValue(use)
			end	   
		end	
		
	end
}

leiguangglobal = sgs.CreateTriggerSkill{
	name = "leiguangglobal",
	global = true,
	events = {sgs.CardFinished},
	  priority = 1,
	on_record = function(self, event, room, player, data) 
		if event == sgs.CardFinished then			
			local use = data:toCardUse()
			if player:isAlive() and player:hasSkill("leiguang") and player:objectName() == use.from:objectName() then 
				if (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard") or use.card:getSkillName() == "tehua") then
					room:setPlayerMark(player, "SingleTargetTrick", 0)	
					room:setPlayerMark(player, "toplayer", 0)
					room:setPlayerMark(player, "Thunder", 0)
					if use.card:isKindOf("TrickCard") and use.to:length() == 1 then---use.card:isKindOf("SingleTargetTrick")
						room:setPlayerMark(player, "SingleTargetTrick", 1)
					end	
					if use.to:contains(player)then
						room:setPlayerMark(player, "toplayer", 1)	
					end	
					if use.card:isKindOf("ThunderSlash") or use.card:isKindOf("Drowning") or use.card:isKindOf("Lightning") then
						room:setPlayerMark(player, "Thunder", 1)
					end	
					if use.card:getSkillName() == "tehua" then
                        room:setPlayerMark(player, "SingleTargetTrick", 1)
						room:setPlayerMark(player, "Thunder", 1)
					end
				end	
			end
		end	
	end,
	can_trigger = function(self, event, room, player, data)
		return "" 
	end,

}

tehuaCard = sgs.CreateSkillCard{
	name = "tehuaCard",
	target_fixed = true,
	on_use = function(self, room, player, targets)
	    room:setPlayerMark(player, "##tehua_open", 1)
		room:setPlayerMark(player, "Armor_Nullified", 1)
		room:doLightbox("tehua$", 800)
	end,
}

tehua = sgs.CreateZeroCardViewAsSkill{
	name = "tehua",
	view_as = function(self)
		local vs = tehuaCard:clone() 
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return player:getMark("##tehua_open") == 0
	end,
}

tehuaMaxCards = sgs.CreateMaxCardsSkill{
	name = "#tehua-maxcard",
	extra_func = function(self, player)
		if player:getMark("##tehua_open") > 0 then
           return -player:getMark("##tehua_open")
		end
		return 0
	end,
}

tehuaSt = sgs.CreateDistanceSkill{
	name = "#tehuaSt",
	correct_func = function(self, from, to)
		if from:getMark("##tehua_open") > 0 then
			return -99
		end
		return 0
	end
}


tehuaglobalCard = sgs.CreateSkillCard{
	name = "tehuaglobalCard",
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
        return #targets < 1 and sgs.Self:objectName() ~= to_select:objectName() and sgs.Self:inMyAttackRange(to_select)
	end,
	feasible = function(self, targets)
		return #targets == 1
	end,
    on_use = function(self, room, player, targets)
       local card = sgs.Sanguosha:cloneCard("slash")
       card:setSkillName("tehuaglobal")
	   for _,i in sgs.qlist(self:getSubcards()) do
         card:addSubcard(i)
	   end
	   local use = sgs.CardUseStruct()
	   use.card = card
	   use.from = player
	   for _,p in ipairs(targets) do
		use.to:append(p)
	   end
       room:useCard(use, false)
	end,
}

tehuaglobalVS = sgs.CreateViewAsSkill{
	name = "tehuaglobal",
	n = 1,
	view_filter = function(self,selected,to_select)
		return #selected == 0
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs = tehuaglobalCard:clone()
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])                
        end  
		vs:setSkillName("tehuaglobal")
		vs:setShowSkill("tehuaglobal")
		return vs
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@tehuaglobal"
	end,
}


tehuaglobal = sgs.CreateTriggerSkill{
	name = "tehuaglobal",
	global = true,
	view_as_skill = tehuaglobalVS,
	events = {sgs.EventPhaseStart, sgs.SlashMissed},
	on_record = function(self, event, room, player, data) 
      if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("##tehua_open") > 0 then
			room:setPlayerMark(player, "##tehua_open", 0)
			room:setPlayerMark(player, "Armor_Nullified", 0)
		end
		if event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			if player:isAlive() and player:getMark("##tehua_open") > 0 then 
				room:askForUseCard(player, "@@tehuaglobal", "@tehuaglobal")
			end
		end	
	end,
	can_trigger = function(self, event, room, player, data)
		return "" 
	end,

}



--授饪
shourenasaCard = sgs.CreateSkillCard{
	name = "shourenasaCard",
	--will_throw = true,---立即丢弃
	will_throw = false,
	mute = true,
	target_fixed = true,
	handling_method = sgs.Card_MethodRecast,
	on_use = function(self, room,player,targets)
		room:moveCardTo(self, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, player:objectName(), self:objectName(), ""))
		room:broadcastSkillInvoke("shourenasa")
		local log = sgs.LogMessage()
		log.type = "$RecastCard"
		log.from = player
		log.card_str = table.concat(sgs.QList2Table(self:getSubcards()), "+")
        room:sendLog(log)
		player:drawCards(self:subcardsLength(), "recast")
		local first = sgs.Sanguosha:getCard(self:getSubcards():at(0)):getSuit()
        local second = sgs.Sanguosha:getCard(self:getSubcards():at(1)):getNumber()
		local third = sgs.Sanguosha:getCard(self:getSubcards():at(2)):getType()
		local ids = sgs.IntList()
		local n = 0
		for _, id in sgs.qlist(room:getDrawPile()) do
		    if self:getSubcards():length()== 1 and sgs.Sanguosha:getCard(id):getSuit()== first then
			   ids:append(id)
			   n = n + 1
			elseif self:getSubcards():length()== 2 and sgs.Sanguosha:getCard(id):getSuit()== first and sgs.Sanguosha:getCard(id):getNumber()== second then
			   ids:append(id) 
			   n = n + 1
			elseif self:getSubcards():length()== 3 and sgs.Sanguosha:getCard(id):getSuit()== first and sgs.Sanguosha:getCard(id):getNumber()== second and sgs.Sanguosha:getCard(id):getType()== third then
				ids:append(id)
				n = n + 1
			end
			if n==self:getSubcards():length() then break end
		end
		if not ids:isEmpty() then
			room:fillAG(ids)
			local log = sgs.LogMessage()
			log.type = "$shourenasashow"
			log.from = player
			log.card_str = table.concat(sgs.QList2Table(ids), "+")
			room:sendLog(log)
			room:getThread():delay(1300)
			room:clearAG()	
			local has = false
			for _, i in sgs.qlist(ids) do
				local c = sgs.Sanguosha:getCard(i)
				if c:isKindOf("ArcheryAttack") or c:isKindOf("Duel") or c:isKindOf("FireAttack") or c:isKindOf("SavageAssault")or c:isKindOf("BurningCamps")or c:isKindOf("Drowning")or c:isKindOf("Lightning") or c:isKindOf("Slash")then
					has = true
					player:setFlags("shourenasa_loseHp")
				end
			end
			local t = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "&shourenasaobtain")
			player:setFlags("-shourenasa_loseHp")
			if t then
				local dummyX = sgs.DummyCard(ids)
				room:obtainCard(t, dummyX)
				dummyX:deleteLater()
			end
			if has then
			   room:loseHp(t)
			end
		end
	end,
}

shourenasa = sgs.CreateViewAsSkill{
	name = "shourenasa",
	n = 3,
	view_filter = function(self, selected, to_select)
	    for _,c in sgs.list(selected)do
			if c:getSuit()==to_select:getSuit()
			then return end
		end
		return not to_select:isEquipped() and not to_select:isAvailable(sgs.Self)and #selected<3
	end,
	view_as = function(self, cards)
	    if #cards > 0 then
			local new_card = shourenasaCard:clone()
			new_card:setShowSkill(self:objectName())	
			new_card:setSkillName(self:objectName())
			for i = 1, #cards, 1 do
				new_card:addSubcard(cards[i])
			end
			return new_card
		end	
	end,
	enabled_at_play = function(self, player,pattern)
		return not player:hasUsed("ViewAsSkill_shourenasaCard")
	end
}


---魔患
mohuan = sgs.CreateTriggerSkill{
	name = "mohuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and player:getMark("#mohuanDis") > 0 then
			room:setPlayerMark(player, "#mohuanDis", 0)
		end
	end,
    can_trigger = function(self, event, room, player, data)
		 if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,p in sgs.qlist(players) do
				if (move.to and move.to:objectName() == player:objectName() and player:objectName() == p:objectName() and (move.to_place == sgs.Player_PlaceHand)) and not move.card_ids:isEmpty() then
					if p:isAlive() and p:hasSkill("mohuan")and room:getCurrent():objectName() == p:objectName() then  
					    local num = 0
						for _, c in sgs.qlist(move.card_ids) do
							if sgs.Sanguosha:getCard(c):isKindOf("TrickCard") then
								num = num + 1
							end	
						end	
						if num > 0 then
						   return self:objectName(), p
						end   
					end  
				end
			end
	    end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
	    if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local who = sgs.QVariant()
			who:setValue(findPlayerByObjectName(move.to:objectName()))
			if ask_who:hasShownSkill("mohuan") or ask_who:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName(), ask_who)
				return true
			end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, ask_who)
	    if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
	        for _, c in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(c):isKindOf("TrickCard") then
					room:setPlayerCardLimitation(ask_who, "use,response,discard", sgs.Sanguosha:getCard(c):toString(), true)
					room:setPlayerMark(ask_who, "#mohuanDis", ask_who:getMark("#mohuanDis") + 1)  
				end	
			end
	    end
    end,
}

mohuanMaxCards = sgs.CreateMaxCardsSkill{
	name = "mohuanMaxCards",
	fixed_func = function(self, player)--锁定手牌上限
		local n = -1--不锁定
		if player:hasShownSkill("mohuan") then
			n = player:getMark("#mohuanDis")+2
		end
		return n
	end
}


---墨心
moxinCard = sgs.CreateSkillCard{
	name = "moxinCard",
	will_throw = false,
	mute = true,
	filter = function(self, targets, to_select)
	    if to_select:isRemoved() then return false end
	    return #targets < 1 and sgs.Self:objectName() ~= to_select:objectName()
	end,
	feasible = function(self, targets, to_select)
		return #targets == 1 and self:getSubcards():length()==3 and sgs.Sanguosha:getCurrentCardUsePattern()~= "slash"
	end,
	on_use = function(self, room, player, targets)
        if self:getSubcards():length()==3 then
		   local card = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		   card:setSkillName("moxin")
		   for _,i in sgs.qlist(self:getSubcards()) do
			 card:addSubcard(i)
		   end
		   local use = sgs.CardUseStruct()
		   use.card = card
		   use.from = player
		   for _,p in ipairs(targets) do
			use.to:append(p)
		   end
		   room:useCard(use, false)
		end   
	end
}


moxinvs = sgs.CreateViewAsSkill{
	name = "moxin",
	n = 3,
	expand_pile = "tongxinN",
	filter_pattern = ".|.|.|tongxinN",
	view_filter = function(self,selected,to_select)	
		return sgs.Self:getPile("tongxinN"):contains(to_select:getEffectiveId())
	end,
	view_as = function(self,cards)
		if #cards > 0 then 
			if #cards == 1 then
				local vs = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				if #cards == 0 then return nil end
				for var = 1, #cards, 1 do   
					vs:addSubcard(cards[var])                
				end  
				vs:setSkillName(self:objectName())
				vs:setShowSkill(self:objectName())
				return vs
			elseif #cards > 2 then
                local new_card = moxinCard:clone()
				new_card:setShowSkill(self:objectName())	
				new_card:setSkillName(self:objectName())
				for _, c in ipairs(cards) do
					new_card:addSubcard(c)
				end
				return new_card		
			end
		end	
	end,
	enabled_at_response = function(self,player,pattern)
		return player:getPile("tongxinN"):length()>0 and pattern == "slash"
	end,
	
}

moxin = sgs.CreateTriggerSkill{
	name = "moxin",
	can_preshow = true,
	view_as_skill = moxinvs,
	events = {sgs.DamageCaused},---sgs.GeneralShown, 
    can_trigger = function(self, event, room, player, data)
	    --[[if event == sgs.GeneralShown then
	        if player and player:isAlive() and player:inHeadSkills(self) == data:toBool() and player:hasSkill(self:objectName()) then
                return self:objectName()
            end
        end]]
		if event==sgs.DamageCaused then
		    local damage = data:toDamage()
		    if player and player:isAlive() and player:hasSkill("moxin") and damage.from:objectName() == player:objectName() and not damage.card:isRed() and player:getPile("tongxinN"):length()< 5 then
				return self:objectName()
			end	
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("moxin") or player:askForSkillInvoke(self:objectName()) then
				----room:broadcastSkillInvoke(self:objectName())
				----room:doLightbox("xuerui$", 800)
			return true
		end
	end,
	on_effect = function(self, event, room, player, data)
		local list = sgs.IntList()
		for _,id in sgs.qlist(room:getDiscardPile()) do
			local c = sgs.Sanguosha:getCard(id)
			list:append(id)
		end
		if not list:isEmpty() then player:addToPile("tongxinN", list:at(math.random(0, list:length()-1))) end	
	end,
}

---雪睿

xuerui = sgs.CreateTriggerSkill{
	name = "xuerui",
	events = {sgs.TargetConfirming},
    can_trigger = function(self, event, room, player, data)	
		if event == sgs.TargetConfirming then
		   local use = data:toCardUse()
		   local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
			   if use.to:length() ~= 1 then return false end
			   if use.card:isKindOf("SkillCard") or use.card:isKindOf("EquipCard") then return false end
			   if sp and sp:isAlive() and sp:hasSkill(self:objectName()) and use.to:contains(sp) and (sp:canDiscard(sp, "h") or sp:getPile("tongxinN"):length()>1 ) and not room:getCurrent():hasFlag(sp:objectName().."xuerui")then
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
		local tar = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(sp)) do
			if sp:inMyAttackRange(p) and not use.to:contains(p) and p~= use.from and not p:isRemoved() then---sp:distanceTo(p) == 1
				tar:append(p)
			end
		end
		if sp:isAlive() and sp:askForSkillInvoke(self, dat) then
		   targets = room:askForPlayerChosen(sp, tar, self:objectName(), "&xuerui", true, false)
		end
		if targets then
			sp:setProperty("xuerui_target", sgs.QVariant(targets:objectName()))
			room:setPlayerFlag(room:getCurrent(), sp:objectName().."xuerui")
			room:broadcastSkillInvoke(self:objectName())
			return true
	   end
	end,
    on_effect = function(self, event, room, player, data, sp)
	    if event == sgs.TargetConfirming then
		    local use = data:toCardUse()
			local targets = findPlayerByObjectName(sp:property("xuerui_target"):toString())
		    if not targets then return false end 
			local choice_list = {}
			if sp:canDiscard(sp, "h") then table.insert(choice_list, "throwh") end
			if sp:getPile("tongxinN"):length()>1 then table.insert(choice_list, "throwx") end
			if #choice_list == 0 then return false end
			local choice = room:askForChoice(player, self:objectName(), table.concat(choice_list, "+"), data)
			if choice == "throwh" then
			   sp:throwAllHandCards()
			elseif choice == "throwx" then
                local tongxinN = sp:getPile("tongxinN")
				local to_throw = sgs.IntList()
				for i = 0,1,1 do
					local card_id = 0
					room:fillAG(tongxinN,sp)
					if tongxinN:length() == 2 - i then
						card_id = tongxinN:first()
					else
						card_id = room:askForAG(sp,tongxinN,false,self:objectName())
					end
					room:clearAG(sp)
					tongxinN:removeOne(card_id)
					to_throw:append(card_id)
				end
				local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
				for _,id in sgs.qlist(to_throw) do
					slash:addSubcard(id)
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,"",self:objectName(),"")
				room:throwCard(slash,reason,nil)
				slash:deleteLater()
			end
			use.from = sp
			use.to:removeOne(sp)
			use.to:append(targets)
			data:setValue(use)
			if use.card and use.card:isKindOf("DelayedTrick") then
			   room:moveCardTo(use.card,targets,sgs.Player_PlaceDelayedTrick)
			end
		end
    end,
}

---专情

zhuanqingvs = sgs.CreateZeroCardViewAsSkill{
	name = "zhuanqing",
	view_as = function(self)
		local vs = zhuanqingCard:clone() 
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
	    local tos = player:getAliveSiblings()
		tos:append(player)
		for _,p in sgs.qlist(tos)do
			if p:hasSkill("zhenzhu") then
				return false
			end
		end
		return true
	end,
}

zhuanqingCard = sgs.CreateSkillCard{
	name = "zhuanqingCard",
	filter = function(self, targets, to_select, Self)
		if #targets ~= 0 then return false end
		return #targets == 0
	end ,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		room:acquireSkill(target, "zhenzhu")
	end ,
}

zhuanqing = sgs.CreateTriggerSkill{
	name = "zhuanqing",
	can_preshow = true,
	view_as_skill = zhuanqingvs,
	events = {sgs.GeneralRemoved, sgs.RemoveStateChanged, sgs.Death},
	on_record = function(self, event, room, player, data) 		
		if (event == sgs.GeneralRemoved or event == sgs.RemoveStateChanged) and data:toString() == "NanamiRuchia" then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			   if p:hasSkill("zhenzhu") then 
			      room:detachSkillFromPlayer(p, "zhenzhu") 
			   end
			end
		end
		if event==sgs.Death then
		   local death = data:toDeath()
			if death.who:getActualGeneral1Name() ==  "NanamiRuchia" or death.who:getActualGeneral2Name() ==  "NanamiRuchia" then
			    for _,p in sgs.qlist(room:getAlivePlayers()) do
				   if p:hasSkill("zhenzhu") then 
					  room:detachSkillFromPlayer(p, "zhenzhu") 
				   end
				end
			elseif death.who:hasSkill("zhenzhu") then	
			       room:detachSkillFromPlayer(death.who, "zhenzhu") 
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		return "" 
	end,
}

---恋歌
liangeevs = sgs.CreateViewAsSkill{
	name = "liangee",
	n = 4,
	mute = true,
	view_filter = function(self, selected, to_select)
		for _,c in sgs.list(selected)do
			if c:getSuit()==to_select:getSuit()
			then return end
		end
		return #selected<4
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local card = sgs.Sanguosha:cloneCard("shining_concert")
		for _,c in pairs(cards) do
			card:addSubcard(c)
		end
		card:setShowSkill(self:objectName())	
		card:setSkillName(self:objectName())
		return card
	end,
	enabled_at_play=function(self,player)
		return not player:hasUsed("ViewAsSkill_liangeeCard")
	end,
}

liangee = sgs.CreateTriggerSkill{
	name = "liangee",
	can_preshow = true,
	view_as_skill = liangeevs,
	events = {sgs.CardUsed},
    can_trigger = function(self, event, room, player, data)
		if event==sgs.CardUsed then
		    local use = data:toCardUse()
		    if player and player:isAlive() and player:hasSkill("liangee") and use.card:getSkillName() == "liangee" then
				return self:objectName()
			end	
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("liangee") or player:askForSkillInvoke(self:objectName()) then
			---room:broadcastSkillInvoke(self:objectName())
				----room:doLightbox("liangee$", 800)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
	    if event==sgs.CardUsed then
		    local use = data:toCardUse()
			local suitlist = {"spade", "heart", "club", "diamond"}
			for _, c in sgs.qlist(use.card:getSubcards()) do
			    local suit = sgs.Sanguosha:getCard(c):getSuitString()
				if suit == "spade" then
					table.removeOne(suitlist, suit)
				elseif suit == "club" then
					table.removeOne(suitlist, suit)
				elseif suit == "heart" then
					table.removeOne(suitlist, suit)
				elseif suit == "diamond" then
					table.removeOne(suitlist, suit)
				end
			end
			local list = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			   if use.to:contains(p) then list:append(p) end
			end
			local targetlist = sgs.SPlayerList()
			for _,ip in sgs.qlist(list) do
				for _, q in sgs.qlist(ip:getCards("h")) do
					if not table.contains(suitlist, q:getSuitString()) then
						targetlist:append(ip)
						break
					end
				end
			end	
			if not targetlist:isEmpty()  then
				for _,g in sgs.qlist(targetlist) do
					---sgs.Room_cancelTarget(use, g)
					local nullified_list = use.nullified_list
					table.insert(nullified_list, g:objectName())
					use.nullified_list = nullified_list
					---data:setValue(use)
				end
				data:setValue(use)
				if not player:hasSkill("zhenzhu") then
				   for _,m in sgs.qlist(targetlist) do
					    local damage = sgs.DamageStruct()
						damage.from = player
						damage.to = m
						room:damage(damage)
				   end
			    end
			end
		end		
	end,
}
---珍珠
zhenzhu = sgs.CreateTriggerSkill{
	name = "zhenzhu",
    events = {sgs.HpChanged},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.HpChanged and player:hasSkill(self:objectName()) and player:isAlive() and not room:getCurrent():hasFlag(player:objectName().."zhenzhu")then
			return self:objectName()  
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
        if event == sgs.HpChanged and player:askForSkillInvoke(self, data) then
		    ---room:setPlayerFlag(room:getCurrent(), player:objectName().."zhenzhu")
			----room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
	    if event == sgs.HpChanged then
		    ---local choice = room:askForChoice(player, "zhenzhu", "@zhenzhu1+@zhenzhu2")
			---if choice == "@zhenzhu1" then
			while room:getDrawPile():length()<3 do
				room:swapPile()
			end
			local cards = sgs.IntList()
			for _, id in sgs.qlist(room:getDrawPile()) do
				if sgs.Sanguosha:getCard(id) then
				   cards:append(id)
				   break
				end 
			end	
			local PileLength =  room:getDrawPile():length()*0.5
			if PileLength<2 then return false end
			for i=1 ,PileLength ,1 do
				cards:append(room:getDrawPile():at(PileLength-i))
				break
			end
			for i = 1, 1, 1 do
				if room:getDrawPile():length()-2+i >= 0 then
					cards:append(room:getDrawPile():at(room:getDrawPile():length()-2+i))
					break
				end
			end
			room:fillAG(cards, player)
			idd = room:askForAG(player, cards, true, self:objectName())
			---room:getThread():delay(1300)
			room:clearAG(player)
			room:obtainCard(player, idd, false)
			--[[for _, p in sgs.qlist(room:getAlivePlayers()) do
			   if p:hasShownSkill("zhuanqing") then
				   ---p:drawCards(1, "zhuanqing")
					if p ~= player then
						local card = room:askForCard(p, ".|.|.|.", "@zhuanqing_give", sgs.QVariant(), sgs.Card_MethodNone)
						if card then
							room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(0x17, p:objectName(), player:objectName(), self:objectName(), ""))
						end	
				   end
			   end
			end]]
		end	
	end
}



Matsuri:addSkill(jiqiong)
Matsuri:addSkill(huaishi)
Matsuri:addSkill(yehuo)
Youko:addSkill(suodi)
Youko:addSkill(sheyanyouko)
Yomi:addSkill(chuling)
Yomi:addSkill(luanhonglian)
Yomi:addSkill(eling)
Testarossa:addSkill(leiguang)
Testarossa:addSkill(tehua)
Asa:addSkill(shourenasa)
Asa:addSkill(mohuan)
NatalieHannah:addSkill(moxin)
NatalieHannah:addSkill(xuerui)
NanamiRuchia:addSkill(zhuanqing)
NanamiRuchia:addSkill(liangee)
NanamiRuchia:addRelateSkill("zhenzhu")

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("Roundcount") then skills:append(Roundcount) end
----if not sgs.Sanguosha:getSkill("yehuoone") then skills:append(yehuoone) end
if not sgs.Sanguosha:getSkill("leiguangglobal") then skills:append(leiguangglobal) end
if not sgs.Sanguosha:getSkill("#tehua-maxcard") then skills:append(tehuaMaxCards) end
if not sgs.Sanguosha:getSkill("#tehuaSt") then skills:append(tehuaSt) end
if not sgs.Sanguosha:getSkill("tehuaglobal") then skills:append(tehuaglobal) end
if not sgs.Sanguosha:getSkill("mohuanMaxCards") then skills:append(mohuanMaxCards) end
if not sgs.Sanguosha:getSkill("zhenzhu") then skills:append(zhenzhu) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
  ["OLD"] = "旧番测试包",
	
  ["Matsuri"] = "四方茉莉",
  ["@Matsuri"] = "SOLA",
  ["#Matsuri"] = "冀览穹空",
  ["designer:Matsuri"] = "FlameHaze",
  ["cv:Matsuri"] = "能登麻美子",
  ["illustrator:Matsuri"] = "",
  ["%Matsuri"] = "“如果可以的话，能让我最后再许一次愿吗？三人一起看到的..那个时候的天空..无法到达的..那遥远的约定之地”",
  ["~Matsuri"] = "亡语",
  
  
  ["jiqiong"] = "冀穹",
  [":jiqiong"] = "你的偶数轮开始/失去体力后，可以亮出牌堆两端的牌，若其均可使用则你使用其中之一，否则弃置之。",
  ["jiqiong$"] = "image=image/animate/jiqiong.png",
  ["$jiqiong1"] = "活了几百年，但却没有一次能站在真正的蓝天下。",
  ["$jiqiong2"] = "我晒不了太阳。",
  ["$jiqiong3"] = "那种光明无限延伸的空间，以及那清澈透明的蓝色，都无法去体会。",
  ---["@jiqiong"]="冀穹",
  ["~jiqiong"]="冀穹：使用选中的牌",
  ["@jiqiong"] = "你可以使用此<font color=\"#BA8EC1\"><b>【%src】</b></font>，或者点击“取消”",
  ---["jiqiong-invoke"]="选择目标，你对其使用<font color=\"#A0FFF9\"><b>【%src】</b></font>",
  ["$jiqiongshow"] = "%from 发动 %arg 亮出牌堆两端的 %card",
  
  ["huaishi"] = "坏蚀",
  [":huaishi"] = "状态技，若你体力为1/仅明置此人物，当你造成伤害后，可以令目标体力上限-1直到其回合结束（不可叠加）。",
  ["huaishi$"] = "image=image/animate/huaishi.png",
  ["$huaishi"] = "滋滋滋~",
  ["huaishiloseMaxHp"] = "坏蚀",
  
  ["yehuo"] = "夜祸",
  [":yehuo"] = "锁定技，你奇数轮内即将受到的伤害视为失去体力；每回合结束后，若本回合你受到过伤害则恢复一点体力。",----②你于回合内死亡时，令一名其他角色获得“夜祸①”。
  ["$yehuo"] = "我不是人类",
  --["Roundcount"] = "轮次",
  ["even"] = "偶",
  ["Odd"] = "奇",
  ["yehuo-invoke"] = "选择一名角色，其获得技能“夜祸”。",
  
  ["yehuoone"] = "夜祸",
  [":yehuoone"] = "锁定技，你奇数轮内即将受到的伤害视为失去体力；每回合结束后，若本回合你受到过伤害则恢复一点体力。",
  
  
  ["Youko"] = "阳子",
  ["@Youko"] = "犬神",
  ["#Youko"] = "狐妖之女",
  ["designer:Youko"] = "FlameHaze",
  ["cv:Youko"] = "堀江由衣",
  ["illustrator:Youko"] = "AI",
  ["%Youko"] = "“启太你总这样~梆！”",
  ["~Youko"] = "呃啊~",
  
  ["suodi"] = "缩地",
  [":suodi"] = "当你于出牌阶段弃置牌时，改为令一名同势力角色将其区域内一张牌直接置入弃牌堆，若该角色不为你则其摸一张牌。",
  ["$suodiMoveToDiscardPile"] = "上述弃牌改为%from将%card直接置入弃牌堆",
  ["@suodi"] = "弃牌同势力角色区域内一张牌来代替此次弃牌/取消" ,
  ["suodi$"] = "image=image/animate/suodi.png",
  ["$suodi1"] = "缩地！",
  ["$suodi2"] = "如果启太和我一起去的话，我就做很多特别服务给你哟~缩地。",
  
  ["sheyanyouko"] = "邪炎",---蛇炎
  [":sheyanyouko"] = "出牌阶段限一次，你可以选择一张牌并指定座位和方向，将此牌与牌堆一张相同花色的牌当作【异端审判】对该路线上所有其他角色使用。若这些牌类别相同则本回合此技能限制次数+1。",
  ----["$sheyanyoukoshow"] = "%from 展示牌堆顶的 %card",
  ["$sheyanyouko1"] = "嘿~还挺结实的嘛，那么看来就算我这么做你也死不了咯。",
  ["$sheyanyouko2"] = "死了吗？",
  ["$sheyanyouko3"] = "邪炎。",
  
  
  ["Yomi"] = "谏山黄泉",
  ["@Yomi"] = "食灵",
  ["#Yomi"] = "黑巫女",
  ["designer:Yomi"] = "FlameHaze",
  ["cv:Yomi"] = "水原薰",
  ["illustrator:Yomi"] = "",
  ["%Yomi"] = "“神乐，你是我最后的宝物”",
  ["~Yomi"] = "你明白我真正愿望是什么吧？我真正的愿望，真正的祈求。",
  
  ["chuling"] = "除灵",
  [":chuling"] = "<font color=\"green\"><b>出牌阶段限两次，</b></font>可以重铸你或攻击范围内一名角色场上一张牌，然后你弃置一张与此牌同花色的手牌,否则失去一点体力。",
  ["chuling$"] = "image=image/animate/chuling.png",
  ["$chulingMoveToDiscardPile"] = "%from 将 %card 置入弃牌堆",
  ["chulingSuit"] = "弃置一张该花色手牌，否则失去一点体力",
  ["$chuling1"] = "噗呲~",
  ["$chuling2"] = "怎么样都好啦，这种事。",
  ["$chuling3"] = "事到如今，无所谓了。",
  ["$chuling4"] = "在这里的你们的眼睛已经死了呢。",
  
  ["luanhonglian"] = "纵鵺「乱红莲」",
  [":luanhonglian"] = "当场上一张牌不因使用/打出/弃置进入弃牌堆时，则你可以视为对一名攻击范围内包含你的角色使用一张不限次杀。",
  ["@luanhonglian"] = "可以视为对攻击范围内含你的一名角色使用一张【杀】" ,
  ["luanhonglian$"] = "image=image/animate/luanhonglian.png",
  ["luanhonglianA"] = "纵鵺",
  ["$luanhonglian1"] = "乱红莲。",
  ["$luanhonglian2"] = "真没意思。",
  ["$luanhonglian3"] = "阿啦，人数不够呢，是跑了吗？还是死了？",
  ["$luanhonglian4"] = "hello~神乐~",
  
  ["eling"] = "失心",----恶灵
  [":eling"] = "锁定技，当你杀死角色时，重置“除灵”次数，若其为同势力，则你势力变为黑幕并将体力变为0。",
  ["eling$"] = "image=image/animate/eling.png",
  ["$eling1"] = "我现在就是死亡的污秽。",
  ["$eling2"] = "杀了我。",
  
  
  ["Testarossa"] = "菲特·泰斯特罗莎·哈洛温",
  ["&Testarossa"] = "菲特",
  ["@Testarossa"] = "魔法少女奈叶",
  ["#Testarossa"] = "温柔的金色闪光",
  ["designer:Testarossa"] = "FlameHaze",
  ["illustrator:Testarossa"] = "薄羽陽炎＠修行中",
  ["cv:Testarossa"] = "水树奈奈",
  ["~Testarossa"] = "",
  ["%Testarossa"] = "“我们的一切尚未开始。所以，和过去的自己，永别吧！”",
  ["leiguang"] = "雷光",
  ["leiguang$"] = "image=image/animate/leiguang.png",
  [":leiguang"] = "当你使用杀时，根据你上个结算完毕的使用牌/技能：\n①<font color=\"#FF9c00\">「锦囊牌目标为1/特化」</b></font>横置目标；\n②<font color=\"#FF9c00\">「雷属性伤害牌/特化」</b></font>可额外指定一个目标；\n③<font color=\"#FF9c00\">「目标包含你」</b></font>视为雷杀并摸一张牌。",
  ["$leiguang1"] = "Scythe form",
  ["$leiguang2"] = "非常抱歉，我要上了",
  ["$leiguang3"] = "第3模式(Third Form)",
  ["$leiguang4"] = "光子灵枪·繁星飞耀",
  --["Thunder"] = "雷伤",
  --["toplayer"] = "目标为你",
  ["leiguangtarget"] = "可以为此杀选择一个额外目标",
  ["$UseCard_thunder"] = "%from 发动 %arg 将 %card 变为雷杀",

  ["tehua"] = "特化",
  [":tehua"] = "状态技，出牌阶段，你可以启用效果<font color=\"#FF5800\"><b>[防具失效；手牌上限-1；与其他角色距离视为1；杀被抵消时则可以将一张牌当作杀使用]</b></font>直到下回合开始。",
  ["$tehua"] = "限定解除·真音速模式",
  ["tehua$"] = "image=image/animate/tehua.png",
  ["tehuaglobal"] = "特化效果",
  ["tehua_open"] = "特化",
  ["@tehuaglobal"] = "可以将一张牌当杀使用",
  ["~tehuaglobal"] = "请选择杀的目标",
  
  
  ["Asa"] = "时雨亚沙",
  ["@Asa"] = "SHUFFLE",
  ["#Asa"] = "惊愕的时雨",
  ["designer:Asa"] = "FlameHaze",
  ["cv:Asa"] = "伊藤美纪",
  ["illustrator:Asa"] = "",
  ["%Asa"] = "“哈~啰~♪今天也是两人一起上学吗？感情还真是好呢~”",
  ["~Asa"] = "我怎么了呢？搬家的时候累着了？",
  
  ["shourenasa"] = "授饪",
  [":shourenasa"] = "出牌阶段限一次，你可以重铸至多3张花色不同且不可使用的手牌，亮出牌堆中等量符合以下条件的牌<font color=\"#FF5800\"><b>[首张重铸牌花色+次牌点数+末牌类别]</b></font>，令一名角色获得之，若其中包含伤害牌则该角色失去一点体力。",
  ["shourenasa$"] = "image=image/animate/shourenasa.png",
  ["$shourenasa1"] = "hello~！",
  ["$shourenasa2"] = "今天也是两个人一起上学~你们两个感情还是那么好。",
  ["$shourenasa3"] = "是不是这种攻击才比较像女孩子呢~",
  ["$shourenasa4"] = "你真的这样认为吗~",
  ["&shourenasaobtain"] = "选择一名其他角色，其获得展示牌",
  ["$RecastCard"] = "%from 将 %card 重铸",
  ["$shourenasashow"] = "%from 亮出牌堆的 %card",
    
  ["mohuan"] = "魔患",
  [":mohuan"] = "锁定技，你回合内获得的锦囊牌不可使用/打出/弃置直到回合结束；你手牌上限为X+2，X为你本回合获得的锦囊牌数。",
  ["$mohuan"] = "语音",
  ["mohuanDis"] = "魔患", 
  
  
  ["NatalieHannah"] = "美墨渚＆雪城穗乃香",
  ["&NatalieHannah"] = "渚＆穗乃香",
  ["@NatalieHannah"] = "光之美少女·无印",
  ["#NatalieHannah"] = "黑白天使",
  ["designer:NatalieHannah"] = "FlameHaze",
  ["cv:NatalieHannah"] = "本名阳子&野上由加奈",
  ["illustrator:NatalieHannah"] = "",
  ["%NatalieHannah"] = "“光之使者，Cure Black&Cure White！”",
  ["~NatalieHannah"] = "没力气了~（穗乃香）我也是，已经不行了（渚）",
  
  ["moxin"] = "墨转",--墨心
  [":moxin"] = "①你的“同心”牌可以按以下规则使用或打出：1张当【杀】；3张当【相爱相杀】。②当你不因红色牌造成伤害时，若“同心”牌＜5，则随机将弃牌堆1张牌置于该人物上作为“同心”。",
  ["moxin$"] = "image=image/animate/moxin.png",
  ["$moxin1"] = "White！",
  ["$moxin2"] = "将邪恶之心击碎！",
  ["tongxinN"] = "同心",
  
  ["xuerui"] = "雪回",--雪睿
  [":xuerui"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你成为基本或锦囊牌的唯一目标时，可以选择攻击范围内的另一名角色，弃置所有手牌或2张“同心”牌，将目标转移给其，然后此牌来源改为你。",
  ["$xuerui1"] = "Black！",
  ["$xuerui2"] = "才不会就这样结束！",
  ["throwh"] = "弃置所有手牌",
  ["throwx"] = "弃置2张“同心”牌",
  ["&xuerui"] = "雪睿：可以选择另一名角色，弃置手牌或2张“同心”牌，将目标转移给其",
  
  
  ["NanamiRuchia"] = "七海露西亚",
  ["@NanamiRuchia"] = "人鱼的旋律",
  ["#NanamiRuchia"] = "粉色人鱼公主",
  ["designer:NanamiRuchia"] = "FlameHaze",
  ["cv:NanamiRuchia"] = "中田明日见",
  ["illustrator:NanamiRuchia"] = "",
  ["~NanamiRuchia"] = "但是...事实上...我有一点点难过...",
  ["%NanamiRuchia"] = "“大海记得所有的事....”",
  ["zhuanqing"] = "专情",
  ["zhuanqing$"] = "image=image/animate/zhuanqing.png",
  [":zhuanqing"] = "①出牌阶段，若场上无“珍珠”，则你可以令一名角色获得技能“珍珠”。②此人物离场时，移除“珍珠”。",----②你造成伤害时，若目标有“珍珠”则可以防止之并令其摸一张牌。
  ["@zhuanqing_give"] = "可以选择一张牌交给发动“珍珠”的角色",
  ["$zhuanqing1"] = "虽然也可以理解海斗的心情，但分隔两地实在有点寂寞...",
  ["$zhuanqing2"] = "是啊，我们第一次相遇的那个夜晚...",
  ["$zhuanqing3"] = "真是的~海斗...今天是相聚的最后一晚耶",
  
  ["zhenzhu"] = "珍珠",
  [":zhenzhu"] = "当你体力值变化时，可以从牌堆中间以及两端的牌中选择一张获得。",
  ["$zhenzhu"] = "语音",
  ["@zhenzhu"] = "选择一张牌用于置换", 
  
  ["liangee"] = "恋歌",
  ["liangee$"] = "image=image/animate/liangee.png",
  [":liangee"] = "出牌阶段限一次，你可以将任意不同花色牌当作【闪耀演唱】使用，此牌对手牌中存在此牌包含花色的目标无效，若你无“珍珠”则其各受到你造成的一点伤害。",
  ["$liangee1"] = "🎶太陽の樂園 -Promised Land-",
  ["$liangee2"] = "🎶Before the Moment",
  ["$liangee3"] = "🎶Legend of Mermaid",
  ["$liangee4"] = "🎶爱の温度℃",
  
}

return {extension}