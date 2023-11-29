--宫泽风花
sgs.ai_skill_invoke.moliang = true

sgs.ai_skill_playerchosen.moliang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	return targets[1]
end

sgs.ai_skill_invoke.yuanshu = true

sgs.ai_skill_playerchosen.yuanshu = function(self, targets)
	targets = sgs.QList2Table(targets)
	local Yyui
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:hasSkill("wenchang") then Yyui = target end --无脑给团子
	end
	if Yyui then return Yyui end
	self:sort(targets, "handcard")
	return targets[1]
end

--鸣护艾丽莎
sgs.ai_skill_invoke.quming = function(self, data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

sgs.ai_skill_invoke.yangming = true

--樱井望
sgs.ai_skill_invoke.yueyin = function(self, data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

--更科瑠夏
sgs.ai_skill_invoke.kunxin = function(self, data) --来自徐庶
	local target = data:toPlayer()
	local has_attack_skill = target:hasSkills("luanji|shuangxiong")
	if not self:isFriend(target) and (self:getOverflow(target) > 1 or target:getHandcardNum() > 4) then
		local weak_count = 0
		for _, p in ipairs(self.friends) do
			if (target:canSlash(p, nil, true) or has_attack_skill) and self:isWeak(p) then
				weak_count = weak_count + 1
				if weak_count > 1 then
					return true
				end
			end
			if (target:canSlash(p, nil, true) or has_attack_skill) and p:getHp() == 1 then
				return true
			end
		end
	end
	if self:isEnemy(target) and self.player:getHp() == 1 then
		for _, p in ipairs(self.friends) do
			if (target:canSlash(p, nil, true) or has_attack_skill) and self:isWeak(p) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_choice.kunxin = "kunxinPlayer"

sgs.ai_skill_invoke.luanxin = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target) and not self:isWeak()
end