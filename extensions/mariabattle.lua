extension = sgs.Package("mariabattleskill", sgs.Package_GeneralPack)

Pure_Titan = sgs.Sanguosha:getGeneral("Pure_Titan")
Armored_Titan = sgs.Sanguosha:getGeneral("Armored_Titan")
Colossal_Titan = sgs.Sanguosha:getGeneral("Colossal_Titan")
Beast_Titan = sgs.Sanguosha:getGeneral("Beast_Titan")
Erwin = sgs.Sanguosha:getGeneral("Erwin")
Eren = sgs.Sanguosha:getGeneral("Eren")
Levi = sgs.Sanguosha:getGeneral("Levi")
Armin = sgs.Sanguosha:getGeneral("Armin")
Mikasa = sgs.Sanguosha:getGeneral("Mikasa")

--[[luawugou = sgs.CreateFilterSkill{
	name = "luawugou",
		view_filter = function(self, card)
		local lx =  card:getTypeId() 
		return lx == sgs.Card_TypeEquip 
		end, 
	view_as = function(self,card)	
	local id = card:getEffectiveId()
	local suit = getSuit() 
	local point = card:getNumber()
	local slash = sgs.Sanguosha:cloneCard("slash")
	local vs_card = sgs.Sanguosha:getWrappedCard(id)
	vs_card:setSkillName("luawugou")
	vs_card:takeOver(slash)
	return vs_card
	end,
}]]

luawugou = sgs.CreateFilterSkill{
	name = "luawugou" ,
	view_filter = function(self, to_select)
		return to_select:isKindOf("EquipCard") or to_select:isKindOf("TrickCard")
	end ,
	view_as = function(self, card)
		local id = card:getEffectiveId()
		local suit = card:getSuit() 
	    local point = card:getNumber()
		local new_card = sgs.Sanguosha:getWrappedCard(id)
		local slash = sgs.Sanguosha:cloneCard("slash", suit, point)
		new_card:setSkillName(self:objectName())
		new_card:takeOver(slash)
		new_card:setModified(true)
		return new_card
	end ,
}

powertitan = sgs.CreateTriggerSkill{
	name = "powertitan",
	events = {sgs.DrawNCards},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
		return true
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
		local n = data:toInt()
        data:setValue(n+2)
        return false		
	end ,
}

TitanbodyPro = sgs.CreateProhibitSkill{
	name = "titanbody_pro",
	is_prohibited = function(self, from, to, card, others)
		return from and from:hasShownSkill("titanbody") and card:isKindOf("EquipCard")
	end
}

TitanbodyRange = sgs.CreateAttackRangeSkill{
	name = "titanbody_range",
	fixed_func = function(self, target, include_weapon)
		if target:hasShownSkill("titanbody") then
			return 3
		else
			return -1
		end
	end
}

Titanbody = sgs.CreateTriggerSkill{
	name = "titanbody",
	events = {sgs.EventPhaseEnd, sgs.CardFinished, sgs.TargetConfirmed},
	frequency = sgs.Skill_Compulsory,
	on_record = function(self, event, room, player, data) 
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			for _,p in sgs.qlist(use.to) do
				if (p:getMark("titanbody_null")>0) then
					room:setPlayerMark(p, "Armor_Nullified", p:getMark("Armor_Nullified")-1)
					room:setPlayerMark(p, "titanbody_null", 0)
				end
			end
		end
	   if (event == sgs.TargetConfirmed) then
		    local use = data:toCardUse()
			if (use.from and use.from:hasSkill("titanbody") and player==use.from and use.card:isKindOf("Slash")) then
				for _,p in sgs.qlist(use.to) do
					room:setPlayerMark(p, "Armor_Nullified", p:getMark("Armor_Nullified")+1)
					room:setPlayerMark(p, "titanbody_null", 1)
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd and player:isWounded() and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase()== sgs.Player_Finish then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
		return true
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
        local recover = sgs.RecoverStruct()
		room:recover(player, recover, true)
	end,
}

Yinhua = sgs.CreateTriggerSkill{
	name = "yinhua",
	events = {sgs.GameStart, sgs.DamageInflicted},
	on_record = function(self, event, room, player, data) 
        if event == sgs.GameStart then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasSkill(self:objectName()) then
					p:gainMark("#kai", 10)
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if event == sgs.DamageInflicted and damage.nature == sgs.DamageStruct_Normal and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("#kai")>0 then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
		return true
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
        local damage = data:toDamage()
		if player:getMark("#kai")>= damage.damage then
			player:loseMark("#kai", damage.damage)
			return true
		else
			local n = player:getMark("#kai")
			player:loseMark("#kai", n)
			damage.damage = damage.damage - n
			data:setValue(damage)
		end
	end,
}

Zhuangji = sgs.CreateTriggerSkill{
	name = "zhuangji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageCaused},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if event == sgs.DamagDamageCaused and damage.card and damage.card:isKindOf("Slash") and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("#kai")>= 5 then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
		return true
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
        local damage = data:toDamage()
		damage.damage = damage.damage +1
		data:setValue(damage)
	end,
}

erwinchongfeng = sgs.CreateTriggerSkill{
	name = "erwinchongfeng",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase()== sgs.Player_Start then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
		return true
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		   if p:objectName() == player:objectName() then
		     local slash = sgs.Sanguosha:cloneCard("slash")
			 slash:setSkillName(self:objectName())
			 local use = sgs.CardUseStruct()
			 use.from = p
			 use.card = slash
			 for _,q in sgs.qlist(room:getAlivePlayers()) do
			   if (q:getKingdom()=="Titan" and q:getGeneralName()~= "Pure_Titan" and q:getGeneralName()~= "Beast_Titan") then
			     use.to:append(q)
			   end
			 end
			 room:useCard(use, false)
		   end
		end
		for _,p in sgs.qlist(room:getAlivePlayers()) do
		  if p:getGeneralName():startsWith("WOF_Soldier") then
		     local slash = sgs.Sanguosha:cloneCard("slash")
			 slash:setSkillName(self:objectName())
			 local use = sgs.CardUseStruct()
			 use.from = p
			 use.card = slash
			 for _,q in sgs.qlist(room:getAlivePlayers()) do
			   if (q:getKingdom()=="Titan" and q:getGeneralName()~= "Pure_Titan" and q:getGeneralName()~= "Beast_Titan") then
			     use.to:append(q)
			   end
			 end
			 room:useCard(use, false)
		  end
		end
        return false		
	end ,
}

hatefight = sgs.CreateTriggerSkill{
	name = "hatefight",
	events = {sgs.Damaged, sgs.DamageCaused},
	can_trigger = function(self, event, room, player, data)
		if event== sgs.Damaged and player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase()== sgs.Player_NotActive then
			return self:objectName()
		end
		if event == sgs.DamageCaused then
		   local damage = data:toDamage()
		   if player and player:hasSkill(self:objectName()) and damage.card and damage.card:isRed() and not player:isFriendWith(damage.to) then
		     return self:objectName()
		   end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
	    if event == sgs.Damaged then
		  return player:askForSkillInvoke(self, data)
		else
		  return true
		end
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
	    if event == sgs.Damaged then
          room:loseHp(player)
		  if player:isAlive() then
		    player:gainAnInstantExtraTurn()
		  end
        else
		  local damage = data:toDamage()
		  damage.damage = damage.damage + 1
		  data:setValue(damage)
        end
        return false		
	end ,
}

tongchou = sgs.CreateTriggerSkill{
	name = "tongchou",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase()== sgs.Player_Finish and player:getLostHp()>0 then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
	    return player:askForSkillInvoke(self, data)
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
	    local n = player:getLostHp()
		local list = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
           if p:isFriendWith(player) then
              list:append(p)		   
		   end
        end		
	    local players = room:askForPlayersChosen(player, list, self:objectName(), 0, n, "@tongchou-card", true)
		if players:length()==1 then
		  players:at(0):drawCards(n)
		elseif players:length()>1 then
		  for _,p in sgs.qlist(players) do
            p:drawCards(1)
          end	
		end
        return false		
	end ,
}

lijin = sgs.CreateTriggerSkill{
	name = "lijin",
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventAcquireSkill, sgs.HpChanged},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if event==sgs.EventPhaseStart and player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase()== sgs.Player_Start then
			return self:objectName()
		end
		local eren = room:findPlayerBySkillName(self:objectName())
		if event ~= sgs.EventPhaseStart and player and player:isAlive() and eren then
		   return "lijin", eren
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
	    return true
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
	  if event== sgs.EventPhaseStart then
	    for _,c in sgs.qlist(player:getJudgingArea()) do
		  room:throwCard(c, player, player)
		end
		room:setPlayerProperty(player, "chained", sgs.QVariant(false));
	  else
	    for _,p in sgs.qlist(room:getAlivePlayers()) do
		    if p:getGeneralName()=="Armored_Titan" or p:getGeneralName()=="Colossal_Titan" then
               room:setFixedDistance(ask_who,p,1)
			else
				room:setFixedDistance(ask_who,p,-1)
			end
		end
	  end
      return false		
	end ,
}

suzhan = sgs.CreateTriggerSkill{
	name = "suzhan",
	events = {sgs.SlashMissed},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
	    return player:askForSkillInvoke(self, data)
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
	    player:drawCards(1)
        return false		
	end ,
}

suzhanres = sgs.CreateTargetModSkill{
	name = "#suzhanres" ,
	residue_func= function(self, player, card)
		if (player:hasSkill("suzhan") and card:isKindOf("Slash")) then
			return 1000
		end
		return 0
	end ,
}

pojing = sgs.CreateTriggerSkill{
	name = "pojing",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
	    local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.card:isKindOf("Slash") and damage.to:isAlive() then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
	    return player:askForSkillInvoke(self, data)
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
	    local damage = data:toDamage()
	    room:loseMaxHp(damage.to)
		local n = damage.to:getHandcardNum()
		if n>0 then
		  for i = 1, math.ceil(n/2) ,1 do
		     local id = room:askForCardChosen(player, damage.to, "h", self:objectName())
			 room:throwCard(id, damage.to, player)
		  end
		end
        return false		
	end ,
}

dongcha = sgs.CreateTriggerSkill{
	name = "dongcha",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
	    local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.card:isKindOf("Slash") and damage.to:isAlive() then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
	    return player:askForSkillInvoke(self, data)
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
	    local damage = data:toDamage()
	    room:loseMaxHp(damage.to)
		local n = damage.to:getHandcardNum()
		if n>0 then
		  for i = 1, math.ceil(n/2) ,1 do
		     local id = room:askForCardChosen(player, damage.to, "h", self:objectName())
			 room:throwCard(id, damage.to, player)
		  end
		end
        return false		
	end ,
}

tanji = sgs.CreateTriggerSkill{
	name = "tanji",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Frequent,
	can_trigger = function(self, event, room, player, data)
	    local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.card:isKindOf("Slash") and damage.to:isAlive() then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
	    return player:askForSkillInvoke(self, data)
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
	    local damage = data:toDamage()
	    room:loseMaxHp(damage.to)
		local n = damage.to:getHandcardNum()
		if n>0 then
		  for i = 1, math.ceil(n/2) ,1 do
		     local id = room:askForCardChosen(player, damage.to, "h", self:objectName())
			 room:throwCard(id, damage.to, player)
		  end
		end
        return false		
	end ,
}


siyou = sgs.CreateTriggerSkill{
	name = "siyou",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Limited,
	can_trigger = function(self, event, room, player, data)
	    local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.card:isKindOf("Slash") and damage.to:isAlive() then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data,ask_who)
	    return player:askForSkillInvoke(self, data)
	end ,
	on_effect = function(self, event, room, player, data,ask_who)
	    local damage = data:toDamage()
	    room:loseMaxHp(damage.to)
		local n = damage.to:getHandcardNum()
		if n>0 then
		  for i = 1, math.ceil(n/2) ,1 do
		     local id = room:askForCardChosen(player, damage.to, "h", self:objectName())
			 room:throwCard(id, damage.to, player)
		  end
		end
        return false		
	end ,
}

colossaltitan = sgs.CreateTriggerSkill{
	name = "colossaltitan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirmed, sgs.ConfirmDamage},
	can_trigger = function(self, event, room, player, data)
	local use = data:toCardUse()
	local source = use.from
		if player and player:isAlive() and player:hasSkill(self:objectName()) 
		and player:objectName() == source:objectName() then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(),player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
		if event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			local reason = damage.card
			if reason:isKindOf("Slash") then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local slash = use.card
				if slash:isKindOf("Slash") then
				local source = use.from
					if player:objectName() == source:objectName() then
						local targets = use.to
						for _,target in sgs.qlist(targets) do
						local room = player:getRoom()
						room:setPlayerMark(target, "Armor_Nullified", 1)
						end
					end
				end
		end
			
	end
}

colossaltitan2 = sgs.CreateTargetModSkill{
	name = "#colossaltitan2" ,
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill("colossaltitan") then
			return 3
		end
	end,
}

colossaltitan3 = sgs.CreateProhibitSkill{
	name = "#colossaltitan3",
	is_prohibited = function(self, from, to, card, others)
		if to:hasSkill("colossaltitan") then
			return card:isKindOf("EquipCard")
		end
	end
}


juesiCard = sgs.CreateSkillCard{
		name = "juesiCard",
		target_fixed = false,
		filter = function(self, targets, to_select)
				return (#targets == 0) and (to_select:getHp() > sgs.Self:getHp()) 
			end,
		on_use = function(self, room, source, targets)
			local target = targets[1]
			local mps = target:getHp()
			if mps > 5 then
			mps = 5
			end
			source:gainMark("@mpzs", mps)
			room:loseHp(source)
			room:setPlayerFlag(source, "juesi_used")
			if source:isAlive() then
				source:loseAllMarks("@mpzs")
				local next = source:getNextAlive()while(next ~= target) do
				room:swapSeat(source, next)
				next = source:getNextAlive()
				end
					local x = target:getHp()
					local i = source:getHp()
					while(x > i) do
					local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit, 0)
					slash:setSkillName("juesi")
					local use = sgs.CardUseStruct()
					use.card = slash
					use.from = source
					local dest = targets[1]
					use.to:append(dest)
					room:useCard(use)
					i = i + 1
					end
			end
		end
	}
	juesi = sgs.CreateViewAsSkill{
		name = "juesi",
		n = 0,
		view_filter = function(self, selected, to_select)
		end,
		enabled_at_play = function(self, player)
			return not player:hasFlag("juesi_used")
		end, 
		view_as = function(self, cards) 
			local jscard = juesiCard:clone()
			return jscard
		end
	}

	juesimp = sgs.CreateTriggerSkill{
		name = "juesimp",
		events = {sgs.Dying},
		on_record = function(self, event, room, player, data)
			local dying = data:toDying()
			local dest = dying.who
			if dest:hasSkill("juesi") and player:hasSkill("juesi") then
			local count = player:getMark("@mpzs")
			room:drawCards(dest, count, "juesimp")
			dest:loseAllMarks("@mpzs")
			end
		end
	}


local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("powertitan") then skills:append(powertitan) end
if not sgs.Sanguosha:getSkill("erwinchongfeng") then skills:append(erwinchongfeng) end
if not sgs.Sanguosha:getSkill("hatefight") then skills:append(hatefight) end
if not sgs.Sanguosha:getSkill("tongchou") then skills:append(tongchou) end
if not sgs.Sanguosha:getSkill("lijin") then skills:append(lijin) end
if not sgs.Sanguosha:getSkill("suzhan") then skills:append(suzhan) end
if not sgs.Sanguosha:getSkill("#suzhanres") then skills:append(suzhanres) end
if not sgs.Sanguosha:getSkill("pojing") then skills:append(pojing) end
if not sgs.Sanguosha:getSkill("dongcha") then skills:append(dongcha) end
if not sgs.Sanguosha:getSkill("tanji") then skills:append(tanji) end
if not sgs.Sanguosha:getSkill("siyou") then skills:append(siyou) end
if not sgs.Sanguosha:getSkill("luawugou") then skills:append(luawugou) end
if not sgs.Sanguosha:getSkill("titanbody_pro") then skills:append(TitanbodyPro) end
if not sgs.Sanguosha:getSkill("titanbody_range") then skills:append(TitanbodyRange) end
if not sgs.Sanguosha:getSkill("titanbody") then skills:append(Titanbody) end
if not sgs.Sanguosha:getSkill("yinhua") then skills:append(Yinhua) end
if not sgs.Sanguosha:getSkill("zhuangji") then skills:append(Zhuangji) end
if not sgs.Sanguosha:getSkill("colossaltitan") then skills:append(colossaltitan) end
if not sgs.Sanguosha:getSkill("#colossaltitan2") then skills:append(colossaltitan2) end
if not sgs.Sanguosha:getSkill("#colossaltitan3") then skills:append(colossaltitan3) end
if not sgs.Sanguosha:getSkill("juesi") then skills:append(juesi) end
if not sgs.Sanguosha:getSkill("juesimp") then skills:append(juesimp) end
sgs.Sanguosha:addSkills(skills)

Pure_Titan:addSkill("luawugou")
Pure_Titan:addSkill("titanbody")
Armored_Titan:addSkill("powertitan")
Armored_Titan:addSkill("titanbody")
Armored_Titan:addSkill("yinhua")
Armored_Titan:addSkill("zhuangji")
Colossal_Titan:addSkill("powertitan")
Colossal_Titan:addSkill("colossaltitan")
Beast_Titan:addSkill("powertitan")
Erwin:addSkill("erwinchongfeng")
Eren:addSkill("hatefight")
Eren:addSkill("tongchou")
Eren:addSkill("lijin")
Levi:addSkill("suzhan")
Levi:addSkill("#suzhanres")
Levi:addSkill("pojing")
Mikasa:addSkill("juesi")
Armin:addSkill("dongcha")
--Armin:addSkill("tanji")
Armin:addSkill("siyou")

sgs.LoadTranslationTable{
  ["mariabattleskill"] = "玛利亚夺还战技能包",
}

return {extension}