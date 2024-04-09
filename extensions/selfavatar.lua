extension = sgs.Package("selfavatar", sgs.Package_GeneralPack)

zerojustice = sgs.General(extension,"zerojustice","god",4,true,true)
clannaddaisuki = sgs.General(extension,"clannaddaisuki","god",4,false,true)
favoryuuki = sgs.General(extension,"favoryuuki","god",4,true,true)
qingkong = sgs.General(extension,"qingkong","god",4,true,true)
qiluo = sgs.General(extension,"qiluo","god",4,true,true)
Mizuwaza = sgs.General(extension,"Mizuwaza","god",3,true,true)
Tenthclass = sgs.General(extension,"Tenthclass","god",4,true,true)
FlameHaze = sgs.General(extension,"FlameHaze","god",4,true,true)
Internetjuvenile = sgs.General(extension,"Internetjuvenile","god",4,true,true)
KurashinaAsuka = sgs.General(extension,"KurashinaAsuka","god",4,true,true)

zerojusticeskill = sgs.CreateTriggerSkill{
	name = "zerojusticeskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

clannaddaisukiskill = sgs.CreateTriggerSkill{
	name = "clannaddaisukiskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

favoryuukiskill = sgs.CreateTriggerSkill{
	name = "favoryuukiskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

qingkongskill = sgs.CreateTriggerSkill{
	name = "qingkongskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

qiluoskill = sgs.CreateTriggerSkill{
	name = "qiluoskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

Mizuwazaskill = sgs.CreateTriggerSkill{
	name = "Mizuwazaskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

Tenthclassskill = sgs.CreateTriggerSkill{
	name = "Tenthclassskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

FlameHazeskill = sgs.CreateTriggerSkill{
	name = "FlameHazeskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

Internetjuvenileskill = sgs.CreateTriggerSkill{
	name = "Internetjuvenileskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

KurashinaAsukaskill = sgs.CreateTriggerSkill{
	name = "KurashinaAsukaskill",
	events = {sgs.GameStart},
	can_trigger = function(self, event, room, player, data)
		return ""
	end ,
}

zerojustice:addSkill(zerojusticeskill)
clannaddaisuki:addSkill(clannaddaisukiskill)
favoryuuki:addSkill(favoryuukiskill)
qingkong:addSkill(qingkongskill)
qiluo:addSkill(qiluoskill)
Mizuwaza:addSkill(Mizuwazaskill)
Tenthclass:addSkill(Tenthclassskill)
FlameHaze:addSkill(FlameHazeskill)
Internetjuvenile:addSkill(Internetjuvenileskill)
KurashinaAsuka:addSkill(KurashinaAsukaskill)

sgs.LoadTranslationTable{
  ["selfavatar"] = "动漫杀大家族",
  
  ["zerojustice"] = "光临长夜",
  ["#zerojustice"] = "国战创始",
  ["designer:zerojustice"] = "",
  ["illustrator:zerojustice"] = "",
  ["cv:zerojustice"] = "",
  ["zerojusticeskill"] = "零正",
  [":zerojusticeskill"] = "由SE大佬创造的动漫杀入坑，自此成为动漫杀忠实粉丝之一。自学lua和源码编写，从程序零基础小白成为神杀代码专家，写了很多人物和卡牌，并创造了动漫杀国战版。梦想是推广动漫杀国战，让更多人喜欢上这款游戏。打法稳健，喜爱菜刀系人物。",
  
  ["clannaddaisuki"] = "clannad最爱",
  ["#clannaddaisuki"] = "动漫杀元老",
  ["designer:clannaddaisuki"] = "",
  ["illustrator:clannaddaisuki"] = "",
  ["cv:clannaddaisuki"] = "",
  ["clannaddaisukiskill"] = "小哲",
  [":clannaddaisukiskill"] = "动漫杀元老之一，设计了很多经典角色和卡牌机制。喜爱日常类动漫作品，动漫杀技术高超，局势分析准确，动漫杀实力派担当之一。",
  
  ["favoryuuki"] = "Yuuki",
  ["#favoryuuki"] = "紫色木棉",
  ["designer:favoryuuki"] = "",
  ["illustrator:favoryuuki"] = "",
  ["cv:favoryuuki"] = "",
  ["favoryuukiskill"] = "木棉",
  [":favoryuukiskill"] = "我是yuuki，其实这名字刚用的时候只是一个单纯喜爱的人物。但是，经过因“yuuki”认识了“Asuna”而让我下定决心在网上就以“yuuki”自称。嘛，就是这样了。",
  
  ["qingkong"] = "晴空",
  ["#qingkong"] = "天气之子",
  ["designer:qingkong"] = "",
  ["illustrator:qingkong"] = "",
  ["cv:qingkong"] = "",
  ["qingkongskill"] = "创绘",
  [":qingkongskill"] = "我是晴空，从高中入坑动漫杀到现在成为社畜已经n个年头了，说动漫杀满载着回忆也不足为过，喜欢动漫、绘画和游戏开发，而画上的人物是我看板娘雾织（起名都和天气有关啊，喂），因为她又菜又爱玩所以一些渣操当作她打出来的好了（大雾），多指教， 也希望动漫杀越做越好~",
  
  ["qiluo"] = "奇洛",
  ["#qiluo"] = "幻岭绯灭",
  ["designer:qiluo"] = "",
  ["illustrator:qiluo"] = "",
  ["cv:qiluo"] = "",
  ["qiluoskill"] = "恋梦",
  [":qiluoskill"] = "我是奇洛，是一名老牌三国杀设计者，名称源于自撰穿越小说的角色，图片角色纠结再三还是选择了阿比，fate魔伊厨、天麻厨、轨迹厨、zard粉等(混进了什么？？)。对三国杀的发展和现环境非常不满，励志创造一个阳间的三国杀环境，称之为恋梦计划。动漫杀集合了各路英设豪杰，是非常不错的漫杀作品，也很荣幸能加入这个大家庭之中，(外)神也会指引动漫杀迎向更好的未来~",
  
  ["Mizuwaza"] = "花宫瑞业",
  ["#Mizuwaza"] = "楚汉之樱",
  ["designer:Mizuwaza"] = "",
  ["illustrator:Mizuwaza"] = "笹倉さくら",
  ["cv:Mizuwaza"] = "",
  ["Mizuwazaskill"] = "敏识",
  [":Mizuwazaskill"] = "因为在低潮时期分别遇见了三国杀和LoveLive，从而成为这两个企划的忠实粉丝。虽然在2022年4月24日才加入动漫杀大家庭，但是论认真和热忱的程度却丝毫不逊色于各位前辈们，尤其是以成功设计出乙坂有宇和绝大部分偶像而自豪。曾用名“樱内瑞业”，后来于2024年元月，由于改推乙宗梢而改姓“花宫”。",

  ["Tenthclass"] = "十等兵",
  ["#Tenthclass"] = "新觉似啸",
  ["designer:Tenthclass"] = "",
  ["illustrator:Tenthclass"] = "",
  ["cv:Tenthclass"] = "",
  ["Tenthclassskill"] = "漫年",
  [":Tenthclassskill"] = "因迷恋新颖的武将设计方式而爱上这里，蒙受长夜厚恩，遂愿脑干涂地，喜欢和大家一起交谈，在闲暇时想做个时代的梦。",

  ["FlameHaze"] = "FlameHaze",
  ["#FlameHaze"] = "两界之嗣",
  ["designer:FlameHaze"] = "",
  ["illustrator:FlameHaze"] = "",
  ["cv:FlameHaze"] = "",
  ["FlameHazeskill"] = "火雾",
  [":FlameHazeskill"] = "我是FlameHaze，这名字其实是我入坑作里的一个名字，是与扰乱世界平衡的“红世使徒”战斗的异能者总称。这群人为了大义，能毫不犹豫地献出生命，却不会被世人记得，在当时给我留下很深的印象，加上主角是钉宫四萌（这个是主要原因233），就用了这个名词作为id。也正是因为入坑作蕴含萌、战斗元素，我在后来又迷上了光美系列，不同于传统意义上的魔法少女，该系列的拳拳到肉属实有点难顶（美少女版龙珠），出于对这个系列的爱，我也贡献了一点光美系列的设计。虽然我加入漫杀的时间比较晚，但爱永远不晚。",

  ["Internetjuvenile"] = "网瘾少年",
  ["#Internetjuvenile"] = "行乐之人",
  ["designer:Internetjuvenile"] = "",
  ["illustrator:Internetjuvenile"] = "",
  ["cv:Internetjuvenile"] = "",
  ["Internetjuvenileskill"] = "烁思",
  [":Internetjuvenileskill"] = "各位来玩的杀友们好，我叫网瘾少年，名如其人因为热爱接触动漫杀，也因设计动漫包武将和长夜接触并跟随他来到国战，设计时喜欢求新求还原，也尽力求平衡，也希望大家在玩的同时多多提建议，祝大家玩得开心^_^。",

  ["KurashinaAsuka"] = "明日香",
  ["#KurashinaAsuka"] = "苍空的魔术师",
  ["designer:KurashinaAsuka"] = "",
  ["illustrator:KurashinaAsuka"] = "",
  ["cv:KurashinaAsuka"] = "",
  ["KurashinaAsukaskill"] = "回弹",
  [":KurashinaAsukaskill"] = "大家好，我是明日香。偶然在群聊中发现了动漫杀并热爱动漫杀，感谢群主长夜大佬和群里的各位，我结识了很多朋友，也有幸拿到第一届长夜杯国战冠军。现在一个人经常会打开动漫杀玩（并顺便找bug）。日后会尝试跟着群里的大佬们学习武将设计，希望有朝一日能为自己喜欢的冷门角色设计技能，同时也希望能有更多可爱的朋友喜欢上动漫杀。最后附上我最喜欢的一句话————仰望天空，注视天空，答案就在那里。",
}

return {extension}