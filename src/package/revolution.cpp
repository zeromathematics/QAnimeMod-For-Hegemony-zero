
#include "revolution.h"
#include "newtest.h"
#include "standard-basics.h"
#include "standard-tricks.h"
#include "strategic-advantage.h"
#include "client.h"
#include "engine.h"
#include "structs.h"
#include "gamerule.h"
#include "settings.h"
#include "roomthread.h"
#include "json.h"

ShifengCard::ShifengCard()
{
}

bool ShifengCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (targets.isEmpty()){
        return to_select->isWounded()||Self->inMyAttackRange(to_select);
    }
    else{
        if (!Self->inMyAttackRange(targets.at(0))){
              return false;
        }
        else{
            return Self->inMyAttackRange(to_select);
        }
    }
}

void ShifengCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
   int n = 0;
   QList<ServerPlayer *> list;
   foreach(auto p, targets){
       if (room->askForUseCard(p, "BasicCard+^Jink,TrickCard+^Nullification,EquipCard|.|.|hand", "@shifeng_use", -1, Card::MethodUse, false)!=NULL){
           n = n+1;
           list << p;
       }
   }
   if (n==0) {
       return;
   }
   QString choice = room->askForChoice(source, "shifeng" , "shifeng_selfdraw+shifeng_otherdraw");
   if (choice=="shifeng_selfdraw"){
       source->drawCards(n);
   }
   else{
       foreach(auto p, list){
           p->drawCards(1);
       }
   }
}

class ShifengVS : public ZeroCardViewAsSkill
{
public:
    ShifengVS() : ZeroCardViewAsSkill("shifeng"){
       response_pattern = "@@shifeng";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    const Card *viewAs() const
    {
        ShifengCard *vs = new ShifengCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Shifeng : public TriggerSkill
{
public:
    Shifeng() : TriggerSkill("shifeng")
    {
        frequency = NotFrequent;
        events << EventPhaseStart;
        view_as_skill = new ShifengVS;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Start){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (player->askForSkillInvoke(this, data) && room->askForUseCard(player, "@@shifeng", "@shifeng")){
            return false;
        }
        return false;
    }
};

ZhiyanCard::ZhiyanCard()
{
}

bool ZhiyanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->isKongcheng() && to_select != Self && !Self->hasFlag(to_select->objectName()+"zhiyan");
}

void ZhiyanCard::extraCost(Room *, const CardUseStruct &card_use) const
{
    ServerPlayer *yukino = card_use.from;
    PindianStruct *pd = yukino->pindianSelect(card_use.to.first(), "zhiyan");
    yukino->tag["zhiyan_pd"] = QVariant::fromValue(pd);
}

void ZhiyanCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    PindianStruct *pd = effect.from->tag["zhiyan_pd"].value<PindianStruct *>();
    effect.from->tag.remove("zhiyan_pd");
    if (pd != NULL) {
        bool success = effect.from->pindian(pd);
        pd = NULL;
        room->setPlayerFlag(effect.from, effect.to->objectName()+ "zhiyan");
        if (success){
            if (!effect.to->isNude()||effect.to->getJudgingArea().length()>0){
              int id = room->askForCardChosen(effect.from, effect.to, "hej", "zhiyan");
              room->throwCard(id, effect.to, effect.from);
            }
        }
        else{
            room->askForDiscard(effect.from, "zhiyan", 1, 1);
            room->setPlayerFlag(effect.from, "zhiyan_used");
        }
    } else
        Q_ASSERT(false);
}

class Zhiyan : public ZeroCardViewAsSkill
{
public:
    Zhiyan() : ZeroCardViewAsSkill("zhiyan")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->isKongcheng() && !player->hasFlag("zhiyan_used");
    }

    virtual const Card *viewAs() const
    {
        ZhiyanCard *card = new ZhiyanCard;
        card->setShowSkill(objectName());
        return card;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *) const
    {
        return 2;
    }
};

class Zuozhan : public TriggerSkill
{
public:
    Zuozhan() : TriggerSkill("zuozhan")
    {
        frequency = Frequent;
        events << EventPhaseStart << EventPhaseChanging;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event==EventPhaseStart && player != NULL && player->isAlive() && player->getPhase() == Player::Start)
        {
            QList<ServerPlayer *> yuris = room->findPlayersBySkillName(objectName());
            foreach(auto c, player->getJudgingArea()){
                if (!c->isKindOf("Key")){
                    return skill_list;
                }
            }

            foreach (ServerPlayer *yuri, yuris)
            {
                if ((yuri->getHp() < player->getHp() ||( player->hasClub("sss") && yuri->hasShownSkill("nishen"))))
                {
                    skill_list.insert(yuri, QStringList(objectName()));
                }
            }
        }
        else if (event == EventPhaseStart && player->getPhase() == Player::Finish){
            player->tag["zuozhan_tag"].clear();
        }
        else if (event == EventPhaseChanging){
            QStringList result = player->tag["zuozhan_tag"].toStringList();
            if (result.count() == 0){
                return skill_list;
            }
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive){
                player->tag["zuozhan_tag"].clear();
                return skill_list;
            }
            QString next = result.first();
            if (next == "1_Zuozhan"){
                change.to = Player::Judge;
            }
            else if (next == "2_Zuozhan"){
                change.to = Player::Draw;
            }
            else if (next == "3_Zuozhan"){
                change.to = Player::Play;
            }
            else if (next == "4_Zuozhan"){
                change.to = Player::Discard;
            }
            else if (next == "0_Zuozhan"){
                change.to = Player::Finish;
            }
            data.setValue(change);
            result.removeAt(0);
            if (result.count() == 0 && next != "0_Zuozhan"){
                result.append("0_Zuozhan");
            }
            player->tag["zuozhan_tag"] = QVariant(result);
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(ask_who->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event==EventPhaseStart){
            ServerPlayer * yuri = ask_who;
            room->broadcastSkillInvoke(objectName());
            if (player->hasClub("sss"))
                room->doLightbox(objectName() + "$", 800);
            QStringList choices;
            choices << "1_Zuozhan" << "2_Zuozhan" << "3_Zuozhan" << "4_Zuozhan";
            QString choice1 = room->askForChoice(yuri, "zuozhan1%from:" + player->objectName(), choices.join("+"));
            choices.removeAll(choice1);
            QString choice2 = room->askForChoice(yuri, "zuozhan2%from:" + player->objectName(), choices.join("+"));
            choices.removeAll(choice2);
            QString choice3 = room->askForChoice(yuri, "zuozhan3%from:" + player->objectName(), choices.join("+"));
            choices.removeAll(choice3);
            QString choice4 = choices.first();
            QStringList result;
            result << choice1 << choice2 << choice3 << choice4;

            player->tag["zuozhan_tag"] = QVariant(result);
        }

        return false;
    }
};

class Nishen : public TriggerSkill
{
public:
    Nishen() : TriggerSkill("nishen")
    {
        frequency = Club;
        club_name = "sss",
        events << Dying << Death;
    }
    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (event == Death){
            DeathStruct death = data.value<DeathStruct>();
            if (death.who->hasClub("sss") && player->hasSkill(this)){
                return QStringList(objectName());
            }
        }
        else if (event == Dying){
            DyingStruct dying = data.value<DyingStruct>();
            if (!dying.who->hasSkill(objectName())&& TriggerSkill::triggerable(player)){
                ServerPlayer *yuri = room->findPlayerBySkillName(objectName());
                if (!yuri || !yuri->isAlive() || dying.who->hasClub()){
                    return QStringList();
                }
                QStringList used = yuri->tag["sss_targets"].toStringList();
                if (used.contains(dying.who->objectName())){
                    return QStringList();
                }
                return QStringList(objectName());

            }
        }
       return QStringList();
   }

   virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
   {
       if (event == Death && (player->hasShownSkill(this)||player->askForSkillInvoke(this, data))){
           return true;
       }
       else if(event == Dying && player->askForSkillInvoke(this, data)){
           return true;
       }
       return false;
   }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event==Death){
            DeathStruct death = data.value<DeathStruct>();
            room->setTag("no_reward_or_punish", QVariant(death.who->objectName()));
            foreach(ServerPlayer *p, room->getPlayersByClub("sss")){
                if (p->getLostHp() > 0){
                    if (room->askForChoice(p, objectName(), "nishen_draw+nishen_recover", data) == "nishen_draw"){
                        p->drawCards(2);
                    }
                    else{
                        RecoverStruct recover;
                        recover.recover = 1;
                        room->recover(p, recover, true);
                    }
                }
                else{
                    p->drawCards(2);
                }
            }
        }
        if (event == Dying){
            DyingStruct dying = data.value<DyingStruct>();
            room->broadcastSkillInvoke(objectName(), player);
            if (room->askForChoice(dying.who, "nishen", "nishen_accept+cancel", QVariant::fromValue(player)) == "nishen_accept"){
                dying.who->addClub("sss");
            }
            else{
                LogMessage log;
                log.type = "$refuse_club";
                log.from = dying.who;
                log.arg = "sss";
                room->sendLog(log);
            }
            QStringList used = player->tag["sss_targets"].toStringList();
            used.append(dying.who->objectName());
            player->tag["sss_targets"] = used;
        }
    }
};

JiuzhuCard::JiuzhuCard()
{
}

bool JiuzhuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.length()<2){
        return to_select->getHp() <= Self->getHp() && to_select != Self;
    }
    return false;
}

void JiuzhuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    foreach(auto p ,targets){
        RecoverStruct recover;
        recover.recover = 1;
        room->recover(p, recover, true);
    }
    room->loseHp(source);
    if (targets.length()==1){
        targets.at(0)->drawCards(1);
    }
}


class Jiuzhu : public ZeroCardViewAsSkill
{
public:
    Jiuzhu() : ZeroCardViewAsSkill("jiuzhu")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JiuzhuCard");
    }

    virtual const Card *viewAs() const
    {
        JiuzhuCard *card = new JiuzhuCard;
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};

ShexinCard::ShexinCard()
{
}

bool ShexinCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.length()<1){
        return true;
    }
    return false;
}

void ShexinCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    Key *key = new Key(Card::SuitToBeDecided, -1);
    key->addSubcards(this->getSubcards());
    CardUseStruct use;
    use.from = source;
    use.to << target;
    use.card = key;
    room->useCard(use);
    target->drawCards(2);
    room->acquireSkill(target, "xintiao");
}

class ShexinVS : public OneCardViewAsSkill
{
public:
    ShexinVS() : OneCardViewAsSkill("shexin")
    {
        response_pattern = "@@shexin";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
        return to_select->getSuitString()=="heart";
    }

    virtual const Card *viewAs(const Card *card) const
    {
        auto xb = new ShexinCard;
        xb->addSubcard(card);
        xb->setShowSkill("shexin");
        xb->setSkillName("shexin");
        return xb;
    }
};

class Shexin : public TriggerSkill
{
public:
    Shexin() : TriggerSkill("shexin")
    {
        frequency = Limited;
        events << Dying;
        view_as_skill= new ShexinVS;
        relate_to_place = "deputy";
        limit_mark = "@shexin";
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
       if (TriggerSkill::triggerable(player)){
           DyingStruct dying= data.value<DyingStruct>();
           if ( dying.who==player && player->getMark("@shexin")>0){
               return QStringList(objectName());
           }
       }
       return QStringList();
   }

   virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
   {
       if (player->askForSkillInvoke(this, data)){
           return true;
       }
       return false;
   }
   virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
   {
        if (room->askForUseCard(player, "@@shexin", "@shexin")){
            player->loseMark("@shexin");
        }
        return false;
   }
};

class Xintiao : public TriggerSkill
{
public:
    Xintiao() : TriggerSkill("xintiao")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << CardsMoveOneTime;
    }


    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
       if (event == EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase()==Player::Start){
           foreach(auto p, room->getAlivePlayers()){
               foreach(auto c, p->getJudgingArea()){
                   if ( c->isKindOf("Key")){
                       return QStringList(objectName());
                   }
               }
           }
       }
       if (event == CardsMoveOneTime && TriggerSkill::triggerable(player)){
           CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
           if (!move.from || !move.from->isFriendWith(player)){
               return QStringList();
           }
           if (!move.from_places.contains(Player::PlaceDelayedTrick) || (move.to_place != Player::DiscardPile && move.to_place != Player::PlaceTable)){
               return QStringList();
           }
           /*if (move.reason.m_reason != CardMoveReason::S_REASON_DISCARD && move.reason.m_reason != CardMoveReason::S_REASON_DISMANTLE && move.reason.m_reason != CardMoveReason::S_REASON_THROW && move.reason.m_reason != CardMoveReason::S_REASON_RULEDISCARD){
               return QStringList();
           }*/
           foreach(int id, move.card_ids){
              if (VariantList2IntList(room->getTag("xintiaoList").toList()).contains(id)){
                  return QStringList(objectName());
              }
           }
       }
       return QStringList();
   }

   virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
   {
       if (player->askForSkillInvoke(this, data)){
           return true;
       }
       else if (event == CardsMoveOneTime){
           QList<QVariant> q2 = room->getTag("xintiaoList").toList();
           q2.clear();
           room->setTag("xintiaoList", q2);
       }
       return false;
   }
   virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
   {
        if (event == EventPhaseStart){
            QList<ServerPlayer*> list;
            QList<ServerPlayer*> list2;
            foreach(auto p, room->getAlivePlayers()){
                foreach(auto c, p->getJudgingArea()){
                    if ( c->isKindOf("Key") && !list.contains(p)){
                        list << p;
                    }
                }
            }
            foreach(auto p, room->getAlivePlayers()){
                if (!list.contains(p)){
                    list2 << p;
                }
            }
            ServerPlayer *from = room->askForPlayerChosen(player, list, objectName(), QString(), true);
            if (from && list2.length()>0){
                QList<int> ids;
                foreach(auto c, from->getJudgingArea()){
                    if ( c->isKindOf("Key")){
                        ids << c->getEffectiveId();
                    }
                }
                room->fillAG(ids, player);
                int id = room->askForAG(player, ids, true, objectName());
                room->clearAG(player);
                if (id > -1){
                    Card *card=Sanguosha->getCard(id);
                    ServerPlayer *to = room->askForPlayerChosen(player, list2, objectName(), QString(), false);
                    CardMoveReason reason=CardMoveReason(CardMoveReason::S_REASON_TRANSFER,player->objectName(),objectName(),"");
                    room->moveCardTo(card, from,to,room->getCardPlace(id),reason);
                }
            }

        }
        else{
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            foreach(int id, move.card_ids){
               if (VariantList2IntList(room->getTag("xintiaoList").toList()).contains(id)){
                   room->obtainCard(player, id);
               }
            }
            QList<QVariant> q2 = room->getTag("xintiaoList").toList();
            q2.clear();
            room->setTag("xintiaoList", q2);
        }
        return false;
   }
};

class Erdao : public TriggerSkill
{
public:
    Erdao() : TriggerSkill("erdao")
    {
        frequency = Frequent;
        events << EventPhaseStart;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Start){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (player->askForSkillInvoke(this, data)){
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }
    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        QString choice = room->askForChoice(player, objectName(), "erdao_extraslash+erdao_extratarget");
        if (choice == "erdao_extraslash") {
            room->setPlayerFlag(player, "erdao_extraslash");
            LogMessage log;
            log.from = player;
            log.type = "$ErdaoExtraslash";
            room->sendLog(log);
        }
        else{
            room->setPlayerFlag(player, "erdao_extratarget");
            LogMessage log;
            log.from = player;
            log.type = "$ErdaoExtratarget";
            room->sendLog(log);
        }
        return false;
    }
};

class ErdaoExtra : public TargetModSkill
{
public:
    ErdaoExtra() : TargetModSkill("#erdaoextra")
    {
    }

    virtual int getResidueNum(const Player *from, const Card *card) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasFlag("erdao_extraslash"))
            return 1;
        else
            return 0;
    }
    virtual int getExtraTargetNum(const Player *from, const Card *card) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasFlag("erdao_extratarget"))
            return 1;
        else
            return 0;
    }
};

class Fengbi : public TriggerSkill
{
public:
    Fengbi() : TriggerSkill("fengbi")
    {
        frequency = Frequent;
        events << GeneralShown << DrawNCards;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
       if (event==DrawNCards && TriggerSkill::triggerable(player) && player->hasShownOneGeneral() && !player->hasShownAllGenerals() && player->hasShownGeneral1() == player->inHeadSkills(this)){
           if (!player->hasShownOneGeneral())
               return QStringList();
           QStringList big_kingdoms = player->getBigKingdoms(objectName(), MaxCardsType::Max);
           bool invoke = !big_kingdoms.isEmpty();
           if (invoke) {
               if (big_kingdoms.length() == 1 && big_kingdoms.first().startsWith("sgs")) // for JadeSeal
                   invoke = big_kingdoms.contains(player->objectName());
               else if (player->getRole() == "careerist")
                   invoke = false;
               else
                   invoke = big_kingdoms.contains(player->getKingdom());
           }
           if (!invoke){
               return QStringList(objectName());
           }
       }
       if (event == GeneralShown){
           if ( TriggerSkill::triggerable(player) && player->hasShownAllGenerals()){
               bool head = player->inHeadSkills(this);
               room->detachSkillFromPlayer(player, objectName(), false, false, head);
               room->acquireSkill(player, "xingbao", true, head);
           }
       }
       return QStringList();
   }

   virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
   {
       if (player->askForSkillInvoke(this, data)){
           int n=0;
           foreach(auto p, room->getAlivePlayers()){
               if (player->isFriendWith(p)){
                   n = n+1;
               }
           }

           data = data.toInt() + n;
           room->broadcastSkillInvoke(objectName(), player);
           return true;
       }
       return false;
   }
   virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
   {
        return false;
   }
};


XingbaoCard::XingbaoCard()
{
    target_fixed = true;
}

void XingbaoCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_RECAST, card_use.from->objectName());
    reason.m_skillName = getSkillName();
    room->moveCardTo(this, card_use.from, NULL, Player::PlaceTable, reason, true);
    card_use.from->broadcastSkillInvoke("@recast");
    room->broadcastSkillInvoke("xingbao", card_use.from);

    LogMessage log;
    log.type = "#Card_Recast";
    log.from = card_use.from;
    log.card_str = card_use.card->toString();
    room->sendLog(log);

    QString skill_name = card_use.card->showSkill();
    if (!skill_name.isNull() && card_use.from->ownSkill(skill_name) && !card_use.from->hasShownSkill(skill_name))
        card_use.from->showGeneral(card_use.from->inHeadSkills(skill_name));

    QList<int> table_cardids = room->getCardIdsOnTable(this);
    if (!table_cardids.isEmpty())
    {
        DummyCard dummy(table_cardids);
        room->moveCardTo(&dummy, card_use.from, NULL, Player::DiscardPile, reason, true);
    }

    card_use.from->drawCards(1);
}

class XingbaoVS : public OneCardViewAsSkill
{
public:
    XingbaoVS() : OneCardViewAsSkill("xingbao")
    {
        response_pattern = "@@xingbao";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
        if (Self->hasFlag("xingbao_red")){
            return to_select->isRed();
        }
        else if (Self->hasFlag("xingbao_black")){
            return to_select->isBlack();
        }
    }

    virtual const Card *viewAs(const Card *card) const
    {
        auto xb = new XingbaoCard;
        xb->addSubcard(card);
        xb->setShowSkill("xingbao");
        xb->setSkillName("xingbao");
        return xb;
    }
};

class Xingbao : public TriggerSkill
{
public:
    Xingbao() : TriggerSkill("xingbao")
    {
        frequency = NotFrequent;
        events << Damage << CardFinished;
        view_as_skill= new XingbaoVS;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
       if (event == Damage && TriggerSkill::triggerable(player)){
           DamageStruct damage = data.value<DamageStruct>();
           if ( damage.card && damage.card->isKindOf("Slash") && (damage.card->isRed() || damage.card->isBlack())){
               return QStringList(objectName());
           }
       }
       if (event == CardFinished){
           CardUseStruct use = data.value<CardUseStruct>();
           if (use.card->hasFlag("xingbao_card")){
               use.card->clearFlags();
           }
       }
       return QStringList();
   }

   virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
   {
       if (player->askForSkillInvoke(this, data)){
           return true;
       }
       return false;
   }
   virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
   {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isRed()){
            room->setPlayerFlag(player, "xingbao_red");
        }
        if (damage.card && damage.card->isBlack()){
            room->setPlayerFlag(player, "xingbao_black");
        }
        if (room->askForUseCard(player, "@@xingbao", "@xingbao-recast") != NULL && !damage.card->hasFlag("xingbao_card"))
        {
            damage.card->setFlags("xingbao_card");
            room->addPlayerHistory(player, damage.card->getClassName(), -1);
        }
        room->setPlayerFlag(player, "-xingbao_red");
        room->setPlayerFlag(player, "-xingbao_black");
        return false;
   }
};

class Rennai : public TriggerSkill
{
public:
    Rennai() : TriggerSkill("rennai")
    {
        frequency = Compulsory;
        events << DamageInflicted << PreHpLost << EventPhaseStart << Death;
    }

    void calcFreeze(Room *room, ServerPlayer *player) const{
            if (!player || player->isDead()){
                return;
            }
            if (room->askForChoice(player, objectName(), "rennai_hp+rennai_handcardnum") == "rennai_hp"){
                QStringList hps;
                foreach(ServerPlayer *p, room->getAlivePlayers()){

                    if (!hps.contains(QString::number(p->getHp()))){
                        hps.append(QString::number(p->getHp()));
                    }
                }
                int targetHp = room->askForChoice(player, objectName(), hps.join("+"), QVariant("hp")).toInt();
                if (room->askForChoice(player, objectName(), "rennai_gain+rennai_lose", QVariant("hp+" + QString::number(targetHp))) == "rennai_gain"){
                    foreach(ServerPlayer *p, room->getAlivePlayers()){
                        if (p->getHp() == targetHp){
                            p->gainMark("@Frozen_Eu");
                        }
                    }
                }
                else{
                    foreach(ServerPlayer *p, room->getAlivePlayers()){
                        if (p->getHp() == targetHp){
                            p->loseMark("@Frozen_Eu");
                        }
                    }
                }
            }
            else{
                QStringList handcardnums;
                foreach(ServerPlayer *p, room->getAlivePlayers()){
                    if (!handcardnums.contains(QString::number(p->getHandcardNum()))){
                        handcardnums.append(QString::number(p->getHandcardNum()));
                    }
                }
                int targetHandcardnum = room->askForChoice(player, objectName(), handcardnums.join("+"), QVariant("handcardnum")).toInt();
                if (room->askForChoice(player, objectName(), "rennai_gain+rennai_lose", QVariant("handcardnum+" + QString::number(targetHandcardnum))) == "rennai_gain"){
                    foreach(ServerPlayer *p, room->getAlivePlayers()){
                        if (p->getHandcardNum() == targetHandcardnum){
                            p->gainMark("@Frozen_Eu");
                        }
                    }
                }
                else{
                    foreach(ServerPlayer *p, room->getAlivePlayers()){
                        if (p->getHandcardNum() == targetHandcardnum){
                            p->loseMark("@Frozen_Eu");
                        }
                    }
                }
            }
        }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
       if (TriggerSkill::triggerable(player)){
           if (triggerEvent == DamageInflicted){
               DamageStruct damage = data.value<DamageStruct>();
               if (damage.to == player){
                  return QStringList(objectName());
               }
           }
           else if (triggerEvent == PreHpLost ){
               if ( player->getMark("@Patience") > 0){
                  return QStringList(objectName());
               }
           }
           else if (triggerEvent == EventPhaseStart && player->getPhase() == Player::Start){
               player->loseAllMarks("@Patience");
           }
       }
       else if (triggerEvent == Death){
           DeathStruct death = data.value<DeathStruct>();
           if (death.who->hasSkill(objectName())){
               foreach(ServerPlayer *p, room->getAlivePlayers()){
                   p->loseAllMarks("@Frozen_Eu");
               }
           }
       }
       return QStringList();
   }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (player->hasShownSkill(this)||player->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }
    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (triggerEvent == DamageInflicted){
                    DamageStruct damage = data.value<DamageStruct>();
                    if (damage.to->hasSkill(objectName()) && damage.to->getMark("@Patience") == 0){
                        room->loseHp(damage.to);
                        room->broadcastSkillInvoke(objectName(), rand()%2+1, player);
                        room->doLightbox(objectName() + "$", 800);
                        damage.to->gainMark("@Patience");
                        calcFreeze(room, damage.to);
                        return true;
                    }
                    else if (damage.to->hasSkill(objectName()) && damage.to->getMark("@Patience") > 0){
                        room->broadcastSkillInvoke(objectName(), rand()%2+3, player);
                        if (damage.from){
                            LogMessage log;
                            log.type = "$rennai_effect";
                            log.arg = damage.from->getGeneralName();
                            room->sendLog(log);
                            player->loseMark("@Patience");
                            calcFreeze(room, damage.to);
                        }
                        else if (damage.card){
                            LogMessage log;
                            log.type = "$rennai_effect";
                            log.arg = damage.card->getClassName();
                            room->sendLog(log);
                            player->loseMark("@Patience");
                            calcFreeze(room, damage.to);
                        }
                        else{
                            player->loseMark("@Patience");
                            calcFreeze(room, damage.to);
                        }
                        return true;
                    }
                }
                else if (triggerEvent == PreHpLost){
                    if (player->hasSkill(objectName()) && player->getMark("@Patience") > 0){
                        room->broadcastSkillInvoke(objectName(), rand()%2+3, player);
                        LogMessage log;
                        log.type = "$rennai_effect2";
                        room->sendLog(log);
                        calcFreeze(room, player);
                        player->loseMark("@Patience");
                        return true;
                    }
                }
        return false;
    }
};

class Zhanfang : public TriggerSkill
{
public:
    Zhanfang() : TriggerSkill("zhanfang")
    {
        frequency = NotFrequent;
        events << PreCardUsed << CardFinished << TrickCardCanceling << SlashProceed;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (triggerEvent == PreCardUsed){
                   CardUseStruct use = data.value<CardUseStruct>();
                   if (use.from->hasSkill(objectName())) {

                       if (!use.card->isKindOf("BasicCard") && !use.card->isNDTrick()){
                           return QStringList();
                       }

                       if (use.to.count() != 1){
                           return QStringList();
                       }
                       ServerPlayer *target = use.to.first();

                       if (target->getMark("@Frozen_Eu") > 0 ){
                           return QStringList(objectName());
                       }
                   }


               }
        else if (triggerEvent == CardFinished){
                    CardUseStruct use = data.value<CardUseStruct>();
                    if (use.from->isAlive() && use.card->hasFlag("zhanfang_card")){
                        foreach(ServerPlayer *p, use.to){
                            if (p->isAlive() && p->getEquips().count() > 0 && room->askForChoice(p, objectName(), "zhanfang_discard+cancel", data) == "zhanfang_discard"){
                                room->throwCard(room->askForCardChosen(p, p, "e", objectName()), p);
                                p->loseMark("@Frozen_Eu");
                            }
                        }
                    }
                }
        else if (triggerEvent == TrickCardCanceling && TriggerSkill::triggerable(player)){
                    CardEffectStruct effect = data.value<CardEffectStruct>();
                    if (effect.from && effect.from->isAlive() && effect.from->hasSkill(objectName()) && effect.to && effect.to->getMark("@Frozen_Eu") > 0){
                        return QStringList(objectName());
                    }
                }
                else if (triggerEvent == SlashProceed && TriggerSkill::triggerable(player)){
                    SlashEffectStruct effect = data.value<SlashEffectStruct>();
                    if (effect.from && effect.from->isAlive() && effect.from->hasSkill(objectName()) && effect.to && effect.to->getMark("@Frozen_Eu") > 0){
                        return QStringList(objectName());
                    }
                }
       return QStringList();
   }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (event == PreCardUsed && player->askForSkillInvoke(this, data)){
            return true;
        }
        else if((event == TrickCardCanceling ||event == SlashProceed )&&(player->hasShownSkill(this)||player->askForSkillInvoke(this, data))){
            return true;
        }
        return false;
    }
    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
       if (triggerEvent == PreCardUsed){
           CardUseStruct use = data.value<CardUseStruct>();
           ServerPlayer *target = use.to.first();

                           if (target->getMark("@Frozen_Eu") > 0){
                               use.to.clear();
                               QList<ServerPlayer *> list = room->getAlivePlayers();
                               room->sortByActionOrder(list);
                               foreach(ServerPlayer *p, list){
                                   if (p->getMark("@Frozen_Eu") > 0 && !use.to.contains(p)){
                                       use.to.append(p);
                                   }
                               }
                               use.card->setFlags("zhanfang_card");
                               room->broadcastSkillInvoke(objectName(), player);
                               room->doLightbox(objectName() + "$", 800);
                               data = QVariant::fromValue(use);
                           }
       }
       else if (triggerEvent == TrickCardCanceling){
                   CardEffectStruct effect = data.value<CardEffectStruct>();
                   if (effect.from && effect.from->isAlive() && effect.from->hasSkill(objectName()) && effect.to && effect.to->getMark("@Frozen_Eu") > 0){
                       LogMessage log;
                       log.type = "$zhanfang_effect";
                       log.from = effect.to;
                       log.arg = effect.card->objectName();
                       room->sendLog(log);
                       return true;
                   }
               }
               else if (triggerEvent == SlashProceed){
                   SlashEffectStruct effect = data.value<SlashEffectStruct>();
                   if (effect.from && effect.from->isAlive() && effect.from->hasSkill(objectName()) && effect.to && effect.to->getMark("@Frozen_Eu") > 0){
                       LogMessage log;
                       log.type = "$zhanfang_effect";
                       log.from = effect.to;
                       log.arg = effect.slash->objectName();
                       room->sendLog(log);
                       room->slashResult(effect, NULL);
                       return true;
                   }
               }
       return false;
    }
};

YaozhanCard::YaozhanCard()
{
}

bool YaozhanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.isEmpty()){
        return !to_select->hasShownOneGeneral() || !to_select->isFriendWith(Self);
    }
    return false;
}

void YaozhanCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
   ServerPlayer *target = targets.at(0);
   bool slash = room->askForUseSlashTo(target, source, "@yaozhan-slash:" + source->objectName(), false);
   if (slash && source->isAlive() && target->isAlive()){
       room->askForUseSlashTo(source, target, "@yaozhan-slash:" + source->objectName(), false);
   }
   else{
       QStringList choices;
       if (!target->isKongcheng())
           choices << "handcards";
       if (!target->hasShownAllGenerals())
           choices << "hidden_general";

       room->setPlayerFlag(target, "yaozhanTarget");        //for AI
       QString choice = room->askForChoice(source, "yaozhan%to:" + target->objectName(),
           choices.join("+"), QVariant::fromValue(target));
       room->setPlayerFlag(target, "-yaozhanTarget");
       LogMessage log;
       log.type = "#KnownBothView";
       log.from = source;
       log.to << target;
       log.arg = choice;
       foreach (ServerPlayer *p, room->getOtherPlayers(source, true))
           room->doNotify(p, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

       if (choice.contains("handcards")) {
           room->showAllCards(target, source);
       } else {
           QStringList list, list2;
           if (!target->hasShownGeneral1()) {
               list << "head_general";
               list2 << target->getActualGeneral1Name();
           }
           if (!target->hasShownGeneral2()) {
               list << "deputy_general";
               list2 << target->getActualGeneral2Name();
           }
           foreach (const QString &name, list) {
               LogMessage log;
               log.type = "$KnownBothViewGeneral";
               log.from = source;
               log.to << target;
               log.arg = Sanguosha->translate(name);
               log.arg2 = (name == "head_general" ? target->getActualGeneral1Name() : target->getActualGeneral2Name());
               room->doNotify(source, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
           }
           JsonArray arg;
           arg << "yaozhan";
           arg << JsonUtils::toJsonArray(list2);
           room->doNotify(source, QSanProtocol::S_COMMAND_VIEW_GENERALS, arg);
       }
   }
}

class Yaozhan : public ZeroCardViewAsSkill
{
public:
    Yaozhan() : ZeroCardViewAsSkill("yaozhan"){
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YaozhanCard");
    }

    const Card *viewAs() const
    {
        YaozhanCard *vs = new YaozhanCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Lianji : public TriggerSkill
{
public:
    Lianji() : TriggerSkill("lianji")
    {
        frequency = Frequent;
        events << EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Finish && player->getMark("lianji_times")> player->getHp()) {
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
           room->broadcastSkillInvoke(objectName(), player);
           return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        room->setPlayerMark(player, "lianji_times", 0);
        player->gainAnInstantExtraTurn();
        return false;
    }
};

class LianjiTrigger : public TriggerSkill
{
public:
    LianjiTrigger() : TriggerSkill("#lianji")
    {
        frequency = NotFrequent;
        events << CardFinished << Damage;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == CardFinished) {
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card!= NULL && use.card->isKindOf("Slash")){
                 room->setPlayerMark(player,"lianji_times",player->getMark("lianji_times")+1);
             }
        }
        if (event == Damage) {
             DamageStruct damage = data.value<DamageStruct>();
             if (damage.damage>0){
                 room->setPlayerMark(player,"lianji_times",player->getMark("lianji_times")+1);
             }
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Lianchui : public TriggerSkill
{
public:
    Lianchui() : TriggerSkill("lianchui")
    {
        frequency = NotFrequent;
        events << CardUsed;
        relate_to_place = "head";
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (triggerEvent==CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")&& player == use.from) {
                QList<ServerPlayer*> targets;
                foreach (ServerPlayer *to, room->getOtherPlayers(player)) {
                   if (!use.to.contains(to)&&player->inMyAttackRange(to)){
                       targets << to;
                   }
                }
                if (!targets.isEmpty())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer*> targets;
            CardUseStruct use = data.value<CardUseStruct>();
            foreach (ServerPlayer *to, room->getOtherPlayers(player)) {
               if (!use.to.contains(to)&&player->inMyAttackRange(to)){
                   targets << to;
               }
            }
            ServerPlayer *target=room->askForPlayerChosen(player,targets,objectName(),QString(),true,true);
            if (target){
                player->tag["lianchui_target"] = QVariant::fromValue(target);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag["lianchui_target"].value<ServerPlayer *>();
        if (target){
            room->broadcastSkillInvoke(objectName(),player);
            CardUseStruct use = data.value<CardUseStruct>();
            if (!target->hasShownOneGeneral()){
                target->askForGeneralShow(true, true);
            }
            if (!target->hasShownOneGeneral() || !target->isFriendWith(player)){
                use.to.append(target);
                data.setValue(use);
            }
        }
        return false;
    }
};

class Xianshu : public TriggerSkill
{
public:
    Xianshu () : TriggerSkill("xianshu")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << DrawNCards;
        relate_to_place = "deputy";
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (triggerEvent == EventPhaseStart){
            if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Start){
                return QStringList(objectName());
            }
            else if(player->hasFlag("xianshu_used") && player->getPhase()==Player::Finish){
                room->setPlayerFlag(player,"-xianshu_used");
            }
        }
        else if(triggerEvent == DrawNCards){
            if (player->hasFlag("xianshu_used")){
                room->setPlayerFlag(player,"-xianshu_used");
                data.setValue(data.toInt()-1);
            }
        }
        return QStringList();
   }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseStart&&player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer*> list;
            foreach(auto p, room->getAlivePlayers()){
                if (p->isMale()&&p->isWounded()){
                    list<<p;
                }
            }

            ServerPlayer *target=room->askForPlayerChosen(player,list,objectName(),QString(),true,true);
            if (target){
                player->tag["xianshu_target"] = QVariant::fromValue(target);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag["xianshu_target"].value<ServerPlayer *>();
        if (target){
            room->broadcastSkillInvoke(objectName(),player);
            room->setPlayerFlag(player,"xianshu_used");
            if (room->askForChoice(player,objectName(),"xianshurecover+xianshudraw") == "xianshurecover"){
                RecoverStruct recover;
                recover.recover = 1;
                recover.who = player;
                room->recover(target, recover, true);
            }
            else{
                target->drawCards(target->getLostHp());
            }
        }
        return false;
    }
};

class Huanbing : public TriggerSkill
{
public:
    Huanbing () : TriggerSkill("huanbing")
    {
        frequency = NotFrequent;
        events << DamageCaused << CardFinished;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (triggerEvent == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            if (TriggerSkill::triggerable(player) && damage.card && damage.card->isBlack()){
                return QStringList(objectName());
            }
        }
        else{
            CardUseStruct use= data.value<CardUseStruct>();
            if (use.card && use.card->isBlack() && use.card->isNDTrick() && TriggerSkill::triggerable(player) && !player->hasFlag("huanbing_used") && player->getPhase()!= Player::NotActive){
                return QStringList(objectName());
            }
        }
        return QStringList();
   }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (player->askForSkillInvoke(this, data)){
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }
    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (triggerEvent == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.to->isNude()){
                int id = room->askForCardChosen(player, damage.to, "he", objectName());
                room->throwCard(id, damage.to, player);
            }
        }
        else{
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), QString(), true, true);
            Card *c = Sanguosha->cloneCard("slash");
            if (target && !player->isProhibited(target, c)){
                room->setPlayerFlag(player, "huanbing_used");
                CardUseStruct use= data.value<CardUseStruct>();
                Card *card = Sanguosha->cloneCard("slash");
                card->addSubcards(use.card->getSubcards());
                card->setSkillName("huanbing");
                room->useCard(CardUseStruct(card, player, target), false);
            }
        }
        return false;
    }
};

class Guanli : public TriggerSkill
{
public:
    Guanli() : TriggerSkill("guanli")
    {
        frequency = Frequent;
        events <<  EventPhaseChanging;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (!player->hasFlag("SE_Guanli_on") && player != NULL && player->isAlive() && change.to == Player::Start )
        {
            QList<ServerPlayer *> asagis = room->findPlayersBySkillName(objectName());

            foreach (ServerPlayer *asagi, asagis)
            {
                if (!asagi->isNude())
                {
                    skill_list.insert(asagi, QStringList(objectName()));
                }
            }
        }
        else if(change.to == Player::Finish && player->hasFlag("SE_Guanli_on")){
            player->setFlags("-SE_Guanli_on");
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(ask_who->askForSkillInvoke(this, QVariant::fromValue(player)) && room->askForCard(ask_who,".|.|.|hand","@guanli:"+ player->objectName(),QVariant::fromValue(player), objectName())){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        room->broadcastSkillInvoke(objectName(), ask_who);
        player->setFlags("SE_Guanli_on");
        QString choice = room->askForChoice(ask_who, objectName(), "Gl_draw+Gl_play+Gl_discard");
        if(choice == "Gl_draw"){
           change.to = Player::Draw;
           data.setValue(change);
           player->insertPhase(Player::Draw);
        }
        if(choice == "Gl_play"){
           change.to = Player::Play;
           data.setValue(change);
           player->insertPhase(Player::Play);
        }
        if(choice == "Gl_discard"){
           change.to = Player::Discard;
           data.setValue(change);
           player->insertPhase(Player::Discard);
        }
        return false;
    }
};

PoyiCard::PoyiCard()
{
    mute = true;
}

bool PoyiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.length()>=2) return false;
    if (targets.isEmpty()) return to_select->getHp()>= Self->getHp() && !to_select->isFriendWith(Self);
    if (targets.length()==1) return targets.at(0)->inMyAttackRange(to_select) && to_select!=targets.at(0);
}

bool PoyiCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void PoyiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *asagi = card_use.from;

    LogMessage log;
    log.from = asagi;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, asagi , data);
    room->broadcastSkillInvoke("poyi", asagi );


    if (asagi ->ownSkill("poyi") && !asagi ->hasShownSkill("poyi"))
        asagi ->showGeneral(asagi ->inHeadSkills("poyi"));

    thread->trigger(CardUsed, room, asagi , data);
    thread->trigger(CardFinished, room, asagi , data);
}

void PoyiCard::use(Room *room, ServerPlayer *asagi , QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    ServerPlayer *slashTarget = targets.at(1);
    int index = asagi->startCommand(objectName());
    ServerPlayer *dest = NULL;
    if (index == 0) {
        dest = room->askForPlayerChosen(asagi, room->getAlivePlayers(), "command_poyi", "@command-damage");
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, asagi->objectName(), dest->objectName());
    }
    if (!target->doCommand(objectName(),index,asagi,dest)){
        Card *card = Sanguosha->cloneCard("slash");
        room->useCard(CardUseStruct(card, target, slashTarget), false);
    }
}

class Poyi : public ZeroCardViewAsSkill
{
public:
    Poyi() : ZeroCardViewAsSkill("poyi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("PoyiCard");
    }

    const Card *viewAs() const
    {
        PoyiCard *vs = new PoyiCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Trial : public TriggerSkill
{
public:
    Trial() : TriggerSkill("trial")
    {
        frequency = NotFrequent;
        events << TargetConfirmed << EventPhaseStart;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (triggerEvent==TargetConfirmed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card != NULL && (use.card->isKindOf("Slash")||(use.card->isBlack()&& use.card->isNDTrick())) && use.to.length()==1 && !use.to.contains(player)) {
                if (player->getMark("trial_used")==0)
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(),player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        room->setPlayerMark(player, "trial_used", 1);
        CardUseStruct use = data.value<CardUseStruct>();
        use.to.clear();
        use.to.append(player);
        data.setValue(use);
        QList<int> trial = room->getNCards(3, false);

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.card_str = IntList2StringList(trial).join("+");
        room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
        room->askForGuanxing(player, trial);
        player->drawCards(1);
        return false;
    }
};

class TrialTrigger : public TriggerSkill
{
public:
    TrialTrigger() : TriggerSkill("#trial")
    {
        frequency = NotFrequent;
        events << EventPhaseStart;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && player->getMark("trial_used")>0 && player->getPhase() == Player::RoundStart) {
             room->setPlayerMark(player,"trial_used",0);
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart){
            if (player->isAlive() && player->getPhase() == Player::RoundStart){
            }
        }
        return false;
    }
};

PoshiCard::PoshiCard()
{
    target_fixed = true;
    will_throw = false;
}
void PoshiCard::use(Room *room, ServerPlayer *aika, QList<ServerPlayer *> &) const
{
    room->loseHp(aika);
}

class Poshi : public ZeroCardViewAsSkill
{
public:
    Poshi() : ZeroCardViewAsSkill("poshi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("PoshiCard");
    }

    const Card *viewAs() const
    {
        PoshiCard *vs = new PoshiCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class PoshiDistance : public DistanceSkill
{
public:
    PoshiDistance() : DistanceSkill("#poshi-dist")
    {
    }

    virtual int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasUsed("PoshiCard"))
            return -1000;
        else
            return 0;
    }
};

class PoshiTargetMod : public TargetModSkill
{
public:
    PoshiTargetMod () : TargetModSkill("#poshitargetmod")
    {
    }

    virtual int getResidueNum(const Player *from, const Card *card) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->hasUsed("PoshiCard"))
            return 1000;
        else
            return 0;
    }
};


class PoshiTrigger : public TriggerSkill
{
public:
    PoshiTrigger() : TriggerSkill("#poshi")
    {
        frequency = NotFrequent;
        events << CardFinished << TargetConfirmed;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == CardFinished) {
             CardUseStruct use = data.value<CardUseStruct>();
             foreach(auto p, use.to){
                 if (p->getMark("poshi_null")>0){
                     room->setPlayerMark(p, "Armor_Nullified", p->getMark("Armor_Nullified")-1);
                     room->setPlayerMark(p, "poshi_null", 0);
                 }
             }
        }
        if (event == TargetConfirmed) {
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.from && use.from->hasUsed("PoshiCard")){
                 foreach(auto p, use.to){
                     if (p != use.from){
                         room->setPlayerMark(p, "Armor_Nullified", p->getMark("Armor_Nullified")+1);
                         room->setPlayerMark(p, "poshi_null", 1);
                     }
                 }
             }
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Liansuo : public TriggerSkill
{
public:
    Liansuo() : TriggerSkill("liansuo")
    {
        frequency = NotFrequent;
        events << CardsMoveOneTime << EventPhaseStart;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *aika, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(aika) && event == CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)){
                return QStringList();
            }
            if (!move.from || aika->getPhase() != Player::NotActive || move.from ==aika){
                return QStringList();
            }
            if (move.reason.m_reason != CardMoveReason::S_REASON_DISCARD && move.reason.m_reason != CardMoveReason::S_REASON_DISMANTLE && move.reason.m_reason != CardMoveReason::S_REASON_THROW && move.reason.m_reason != CardMoveReason::S_REASON_RULEDISCARD){
                return QStringList();
            }
            if (move.card_ids.length() == 0){
                return QStringList();
            }
            if (aika->getMark("aikadraw")>=4){
                return QStringList();
            }
            return QStringList(objectName());
        }
        else if (event == EventPhaseStart && aika->getPhase()==Player::RoundStart){
            room->setPlayerMark(aika, "aikadraw", 0);
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *aika, QVariant &data, ServerPlayer *ask_who) const
    {
        if (aika->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *aika, QVariant &data, ServerPlayer *) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        QList<int> list = move.card_ids;
        foreach(int id, list){
            Card *c = Sanguosha->getCard(id);
            if (id == list.at(0) || (id != list.at(0) && aika->getMark("aikadraw")<4 && aika->askForSkillInvoke(this, data))){
                room->setPlayerMark(aika, "aikadraw", aika->getMark("aikadraw")+1);
                room->broadcastSkillInvoke(objectName(), aika);
                QList<int> card_ids = room->getNCards(1);
                Card *c1 = Sanguosha->getCard(card_ids.at(0));
                LogMessage log;
                log.type = "$ViewDrawPile";
                log.from = aika;
                log.card_str = IntList2StringList(card_ids).join("+");
                room->doNotify(aika, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
                foreach (int id, card_ids) {
                    room->moveCardTo(Sanguosha->getCard(id), aika, Player::PlaceTable, CardMoveReason(CardMoveReason::S_REASON_TURNOVER, aika->objectName(), "liansuo", ""), false);
                }
                if (c->getTypeId()==c1->getTypeId()){
                    room->obtainCard(aika, c1);
                }
                else{
                    room->throwCard(c1, aika);
                    ServerPlayer *target = room->askForPlayerChosen(aika, room->getAlivePlayers(), objectName(), QString(), true);
                    if (target){
                        room->setPlayerProperty(target, "chained", QVariant(true));
                    }
                }
            }
        }

        return false;
    }
};

class Yinguo : public TriggerSkill
{
public:
    Yinguo() : TriggerSkill("yinguo")
    {
        frequency = Limited;
        events << Death;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *aika, QVariant &data, ServerPlayer* &) const
    {
        if (aika->hasSkill(this) && event == Death){
            DeathStruct death = data.value<DeathStruct>();
            if (death.who != aika || !aika->hasSkill(this) ){
                return QStringList();
            }
            if (room->getTag(aika->objectName()+"yinguo_used").toBool()){
                return QStringList();
            }
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *aika, QVariant &data, ServerPlayer *ask_who) const
    {
        if (aika->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *aika, QVariant &data, ServerPlayer *) const
    {
        DeathStruct death = data.value<DeathStruct>();
        room->setTag(aika->objectName()+"yinguo_used", QVariant(true));
        QList<ServerPlayer*> list;
        foreach(auto p, room->getAlivePlayers()){
            if(p->hasShownOneGeneral() || p->hasShownAllGenerals()){
                list << p;
            }
        }
        if (list.length()==0){
            return false;
        }
        else{
            ServerPlayer *p1 = room->askForPlayerChosen(aika,list,objectName(),"@yinguo",true,true);
            ServerPlayer *p2;
            if (p1) {
              list.removeOne(p1);
            }
            if (list.length()>0){
              p2 = room->askForPlayerChosen(aika,list,objectName(),"@yinguo2",true,true);
            }
            QList<ServerPlayer*> targets;
            if (p1){
                targets << p1;
            }
            if (p2){
                targets << p2;
            }
            QList<int> ids = aika->handCards();
            if (p1 && p2){
                while (!aika->isKongcheng()){
                    room->askForYiji(aika, ids, objectName(), false, false, false, -1, targets);
                }
            }
            else if (!targets.isEmpty()){
                room->obtainCard(targets.at(0),aika->wholeHandCards(),false);
            }
            QStringList avaliable_generals;
            foreach(QString s,aika->getSelected()){
                if (s!=aika->getActualGeneral1Name()&&s!=aika->getGeneral2Name())
                    avaliable_generals << s;
            }
            if (p1 && room->askForChoice(aika,"yinguo","yinguo1_transform+cancel",data)=="yinguo1_transform") {
                QString to_change = room->askForGeneral(aika, avaliable_generals, QString(), true, "yinguo", p1->getKingdom());
                p1->showGeneral(false);
                room->transformDeputyGeneralTo(p1, to_change);
                avaliable_generals.removeOne(to_change);
            }
            if (p2 && room->askForChoice(aika,"yinguo","yinguo2_transform+cancel",data)=="yinguo2_transform") {
                QString to_change = room->askForGeneral(aika, avaliable_generals, QString(), true, "yinguo", p2->getKingdom());
                p2->showGeneral(false);
                room->transformDeputyGeneralTo(p2, to_change);
                avaliable_generals.removeOne(to_change);
            }
        }
        return false;
    }
};


//game
ChichengCard::ChichengCard()
{
    target_fixed = true;
    will_throw = false;
}
void ChichengCard::use(Room *room, ServerPlayer *akagi, QList<ServerPlayer *> &) const
{
    akagi->addToPile("akagi_lv", this);
    if (this->getSubcards().length()>1){
        RecoverStruct recover;
        recover.recover = 1;
        room->recover(akagi, recover, true);
    }
}

class Chicheng : public ViewAsSkill
{
public:

    Chicheng() : ViewAsSkill("chicheng")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ChichengCard");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *card) const
    {
        return true;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        ChichengCard *zrc = new ChichengCard();
        zrc->addSubcards(cards);
        zrc->setSkillName(objectName());
        zrc->setShowSkill(objectName());
        return zrc;
    }
};

class Zhikong : public TriggerSkill
{
public:
    Zhikong() : TriggerSkill("zhikong")
    {
        frequency = Frequent;
        events <<  EventPhaseStart << DamageCaused << EventPhaseChanging;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == EventPhaseStart && player != NULL && player->isAlive() && player->getPhase() == Player::Start )
        {
            QList<ServerPlayer *> akagis = room->findPlayersBySkillName(objectName());

            foreach (ServerPlayer *akagi, akagis)
            {
                if (akagi->getPile("akagi_lv").length()>0 && akagi->getHp() > 1)
                {
                    skill_list.insert(akagi, QStringList(objectName()));
                }
            }
        }
        else if(event == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.to && damage.to->isAlive() && damage.from->hasFlag("se_zhikong_on") && damage.card && damage.card->isKindOf("Slash")){
                if (rand()%100 < 62){
                    damage.damage= damage.damage+1;
                    data.setValue(damage);
                }
            }
        }

        else if(event == EventPhaseChanging){
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to==Player::Finish && player->hasFlag("se_zhikong_on")){
                player->setFlags("-se_zhikong_on");
                foreach(auto p, room->getOtherPlayers(player)){
                    if(p->getMark("has_been_Armor_Nullified")==0){
                        room->setPlayerMark(p, "Armor_Nullified", 0);
                    }
                    else{
                        room->setPlayerMark(p, "has_been_Armor_Nullified", 0);
                    }
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(ask_who->askForSkillInvoke(this, QVariant::fromValue(player))){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *akagi = ask_who;
        room->fillAG(akagi->getPile("akagi_lv"), akagi);
        int id = room->askForAG(akagi, akagi->getPile("akagi_lv"), false, objectName());
        room->clearAG(akagi);
        room->throwCard(id, akagi);
        room->broadcastSkillInvoke(objectName(), akagi);
        room->doLightbox("se_zhikong$", 800);
        if (player->isFriendWith(akagi)){
            akagi->drawCards(1);
        }
        player->setFlags("se_zhikong_on");
        foreach(auto p, room->getOtherPlayers(player)){
            if(p->getMark("Armor_Nullified")==0){
                room->setPlayerMark(p, "Armor_Nullified", 1);
            }
            else{
                room->setPlayerMark(p, "has_been_Armor_Nullified", 1);
            }
        }

        return false;
    }
};

FanqianCard::FanqianCard()
{
    target_fixed = true;
}
void FanqianCard::use(Room *room, ServerPlayer *asashio, QList<ServerPlayer *> &) const
{
    QList<ServerPlayer *> all = room->getAlivePlayers();
    QStringList string;
    foreach(ServerPlayer *p, all){
        string.append(QString::number(p->getSeat()));
    }
    QString targetName = room->askForChoice(asashio, "fanqian", string.join("+"));
    ServerPlayer *target;
    foreach(ServerPlayer *p, all){
        if (QString::number(p->getSeat()) == targetName){
            target = p;
            break;
        }
    }
    if (target){
        Card *card = Sanguosha->getCard(this->subcards.at(0));
        card->setSkillName("fanqian");
        room->setTag("fanqian_target", QVariant().fromValue(target));
        CardUseStruct use = CardUseStruct(card, asashio, target);
        room->useCard(use);
    }
}


class FanqianVS : public OneCardViewAsSkill
{
public:
    FanqianVS() : OneCardViewAsSkill("fanqian")
    {
    }

    bool viewFilter(const Card *to_select) const
    {
        return !to_select->isKindOf("Collateral") && !to_select->isKindOf("Jink") && !to_select->isKindOf("Nullification") && !to_select->isKindOf("DelayedTrick") &&!to_select->isEquipped();
    }

    const Card *viewAs(const Card *originalCard) const
    {
        FanqianCard *fqc = new FanqianCard();
        fqc->addSubcard(originalCard);
        fqc->setShowSkill("fanqian");
        fqc->setSkillName("fanqian");
        return fqc;
    }
};

class Fanqian : public TriggerSkill
{
public:
    Fanqian() : TriggerSkill("fanqian")
    {
        view_as_skill = new FanqianVS;
        events << PreCardUsed;
    }

    bool trigger(TriggerEvent, Room *room, ServerPlayer *, QVariant &data) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if ((use.card->isKindOf("AOE") || use.card->isKindOf("GlobalEffect")) && use.card->getSkillName() == "fanqian"){
            use.to.clear();
            use.to.append(room->getTag("fanqian_target").value<ServerPlayer *>());
            data = QVariant::fromValue(use);
        }

        return false;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const{
        return QStringList();
    }
};

class Buyu : public TriggerSkill
{
public:
    Buyu() : TriggerSkill("buyu")
    {
        events << EventPhaseStart << EventPhaseEnd << TargetConfirmed;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (event == EventPhaseStart){
            if (player->getPhase() == Player::Play && TriggerSkill::triggerable(player)){
                return QStringList(objectName());
            }
        }
        else if(event == EventPhaseEnd){
                    foreach(ServerPlayer *p, room->getAlivePlayers()){
                        if (p->getMark("@Buyu") > 0)
                            p->loseAllMarks("@Buyu");
                    }
        }
        else if (event == TargetConfirmed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.from && use.from==player && use.from->hasShownSkill(objectName()) && use.card && !(use.card->isKindOf("Slash") && use.card->isBlack())){
                foreach(ServerPlayer *p, use.to){
                    if (p->getMark("@Buyu") > 0){
                        if (!use.from->hasFlag("Buyu_sdraw_played")){
                            room->broadcastSkillInvoke(objectName(), 1);
                            use.from->setFlags("Buyu_sdraw_played");
                        }

                        use.from->drawCards(1);
                        return QStringList();
                    }
                }
                if (!use.from->isNude() && use.from->hasFlag("buyu_used")){
                    if (!use.from->hasFlag("Buyu_sdis_played")){
                        room->broadcastSkillInvoke(objectName(), 2);
                        use.from->setFlags("Buyu_sdis_played");
                    }
                    room->askForDiscard(use.from, objectName(), 1, 1, false, true);
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(player->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *asashio, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event == EventPhaseStart){
                room->broadcastSkillInvoke(objectName(), 1);
                ServerPlayer *target = room->askForPlayerChosen(asashio, room->getAlivePlayers(), objectName());
                if (target){
                    target->gainMark("@Buyu");
                    asashio->setFlags("buyu_used");
                }

        }
        return false;
    }
};

//lord

class Jinji : public TriggerSkill
{
public:
    Jinji() : TriggerSkill("jinji$")
    {
        events << Damage << EventPhaseStart << GeneralShown;
    }

     /*virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (event==GeneralShown && TriggerSkill::triggerable(player)&&data.toBool()==player->inHeadSkills(this)){
            room->broadcastSkillInvoke(objectName(), 1, player);
            room->acquireSkill(player, "jiyuunotsubasa");
        }
        if (event==EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase()==Player::Start){
            return QStringList(objectName());
        }
        return QStringList();
    }*/

   virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
   {
        TriggerList skill_list;
        if (event==GeneralShown && TriggerSkill::triggerable(player)&&data.toBool()==player->inHeadSkills(this)){
            room->broadcastSkillInvoke(objectName(), 1, player);
            room->acquireSkill(player, "jiyuunotsubasa");
        }
        /*if (event==EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase()==Player::Start){
            skill_list.insert(player, QStringList(objectName()));
        }*/
        if (event == Damage){
            QList<ServerPlayer *> erens = room->findPlayersBySkillName(objectName());
            DamageStruct damage = data.value<DamageStruct>();
            foreach (ServerPlayer *eren, erens) {
                if (damage.to->isFriendWith(eren) && damage.damage>0 && damage.from->isAlive())
                    skill_list.insert(eren, QStringList(objectName()));
            }
        }
        return skill_list;
   }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (event==EventPhaseStart && player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer*> list;
            foreach(auto p , room->getAlivePlayers()){
                if (!player->isFriendWith(p) && p->getMark("jinji_used")==0){
                    list << p;
                }
            }
            ServerPlayer *target=room->askForPlayerChosen(player,list,objectName(),QString(),true, true);
            if(target){
             player->tag["quzhu_target"] = QVariant::fromValue(target);
             room->setPlayerMark(target, "jinji_used", 1);
             return true;
            }
        }
        if (event == Damage){
            if (player->askForSkillInvoke("jinji", data)){
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (triggerEvent == EventPhaseStart){
            ServerPlayer *target = ask_who->tag["quzhu_target"].value<ServerPlayer *>();
            if (target){
                target->gainMark("@quzhu");
                room->setFixedDistance(ask_who, target, 1);
                if (ask_who->getMark("jinji_first")==0) {
                    room->setPlayerMark(ask_who, "jinji_first", 1);
                    room->doLightbox("Erenattack1$", 1000);
                }
            }
        }
        if (triggerEvent == Damage){
            DamageStruct damage = data.value<DamageStruct>();
            damage.from->gainMark("@quzhu", damage.damage);
            room->setFixedDistance(ask_who, damage.from, 1);
            if (ask_who->getMark("jinji_first")==0) {
                room->setPlayerMark(ask_who, "jinji_first", 1);
                room->doLightbox("Erenattack1$", 2000);
            }
        }
        return false;
    }
};

int shisoPower(Card *card)
{
    int n = card->getNumber();
    if (n<=10){
        return 1;
    }
    else if(n==11){
        return 2;
    }
    else if(n==12){
        return 3;
    }
    else{
        return 4;
    }
}

class Shizu : public TriggerSkill
{
public:
    Shizu() : TriggerSkill("shizu")
    {
        events << TargetChosen << Damage << GeneralShown;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (event==TargetChosen){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && player->hasSkill("zahyo")&& use.card != NULL && (use.card->isKindOf("Slash")||use.card->isKindOf("Duel"))) {
                QStringList targets;
                foreach (ServerPlayer *to, use.to) {
                    int n = 0;
                    foreach(int id, player->getPile("roads")){
                        if(Sanguosha->getCard(id)->getNumber()>10){
                          n = n+1;
                        }
                    }

                    if (n >= 1)
                        targets << to->objectName();
                }
                if (!targets.isEmpty())
                    return QStringList(objectName() + "->" + targets.join("+"));
            }
        }
        if (event==GeneralShown && TriggerSkill::triggerable(player)&&data.toBool()==player->inHeadSkills(this)){
            foreach(auto p, room->getAlivePlayers()){
                room->attachSkillToPlayer(p, "shiso");
            }
            room->attachSkillToPlayer(player, "zahyo");
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event==TargetChosen){
            if (ask_who->askForSkillInvoke("zahyo", QVariant::fromValue(player))) {
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (triggerEvent==TargetChosen){
           CardUseStruct use = data.value<CardUseStruct>();
           QList<int> list0;
           foreach(int id, ask_who->getPile("roads")){
               if(Sanguosha->getCard(id)->getNumber()>10){
                 list0 << id;
               }
           }
           room->fillAG(list0, ask_who);
           int id = room->askForAG(ask_who,list0, false, objectName());
           room->clearAG(ask_who);
           room->throwCard(id, ask_who, ask_who);
           int index = ask_who->startCommand(objectName());
           ServerPlayer *dest = NULL;
           if (index == 0) {
               dest = room->askForPlayerChosen(ask_who, room->getAlivePlayers(), "command_shizu", "@command-damage");
               room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), dest->objectName());
           }
           QStringList list;
           foreach(auto p, room->getAlivePlayers()){
               QStringList big_kingdoms = p->getBigKingdoms(objectName(), MaxCardsType::Max);
               bool invoke = !big_kingdoms.isEmpty();
               if (invoke) {
                   if (big_kingdoms.length() == 1 && big_kingdoms.first().startsWith("sgs")) // for JadeSeal
                       invoke = big_kingdoms.contains(p->objectName());
                   else if (p->getRole() == "careerist")
                       invoke = false;
                   else
                       invoke = big_kingdoms.contains(p->getKingdom());
               }
               if (invoke || p->getKingdom()==ask_who->getKingdom()){
                   if (!list.contains(p->getKingdom())){
                       list<< p->getKingdom();
                   }
               }
           }
           QString choice = room->askForChoice(ask_who, objectName(), list.join("+"));
           room->setEmotion(player, "skills/zahyo");
          if (choice == ask_who->getKingdom()){
              QList<ServerPlayer *> alls = room->getOtherPlayers(ask_who);
                  room->sortByActionOrder(alls);
                  foreach(ServerPlayer *anjiang, alls) {
                      if (anjiang->hasShownOneGeneral()) continue;

                      QString kingdom = ask_who->getKingdom();
                      ServerPlayer *lord = NULL;

                      int num = 0;
                      foreach (ServerPlayer *p, room->getAllPlayers(true)) {
                          if (p->getKingdom() != kingdom) continue;
                          QStringList list = room->getTag(p->objectName()).toStringList();
                          if (!list.isEmpty()) {
                              const General *general = Sanguosha->getGeneral(list.first());
                              if (general->isLord())
                                  lord = p;
                          }
                          if (p->hasShownOneGeneral() && p->getRole() != "careerist")
                              num++;
                      }

                      bool full = (ask_who->getRole() == "careerist" || ((lord == NULL || !lord->hasShownGeneral1()) && num >= room->getPlayers().length() / 2));

                      if (anjiang->getKingdom() == kingdom && !full) {
                          anjiang->askForGeneralShow(false, true);
                      }
                      else{
                          room->askForChoice(anjiang,objectName(),"cannot_showgeneral+cancel",data);
                      }
                  }
          }
          foreach (ServerPlayer *p, room->getOtherPlayers(ask_who)) {
              if(!p->hasShownOneGeneral())
                  continue;
              if (p->getKingdom()==choice&&!room->askForUseSlashTo(p, player,"player:"+player->objectName(),false)){
                  if (p->getKingdom()==ask_who->getKingdom()){
                      if (!p->doCommand(objectName(),index,ask_who,dest)){
                          p->drawCards(1);
                      }
                  }
                  else{
                     p->doCommandForcely(objectName(),index,ask_who,dest);
                  }
              }
              if (p->getKingdom()==ask_who->getKingdom() && p->getKingdom()==choice && room->askForChoice(p,"transform","transform+cancel",data)=="transform"){
                  p->showGeneral(false);
                  room->transformDeputyGeneral(p);
              }
          }
        }
        return false;
    }
};

class Zahyo : public TriggerSkill
{
public:
    Zahyo() : TriggerSkill("zahyo")
    {
        events << TargetChosen;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        return false;
    }
};


class Jiyuunotsubasa : public TriggerSkill
{
public:
    Jiyuunotsubasa() : TriggerSkill("jiyuunotsubasa")
    {
        events << Damaged << Damage << EventAcquireSkill << DamageCaused << PreCardUsed << TurnStart;
        attached_lord_skill = true;
    }

     virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        /*if (event== EventAcquireSkill && TriggerSkill::triggerable(player)&& data.toString().split(":").first()==objectName()){
            foreach(auto p, room->getAlivePlayers()){
                if (p->hasShownOneGeneral()&&!p->isFriendWith(player)){
                    p->gainMark("@quzhu");
                    room->setFixedDistance(player, p, 1);
                }
            }
        }
        if (event == Damage){
            QList<ServerPlayer *> erens = room->findPlayersBySkillName(objectName());
            DamageStruct damage = data.value<DamageStruct>();
            foreach (ServerPlayer *eren, erens) {
                if (damage.to->isFriendWith(eren) && damage.damage>0)
                    skill_list.insert(eren, QStringList(objectName()));
            }
        }*/
        if (event==TurnStart){
            ServerPlayer *eren = room->getCurrent();
            if (!eren || !TriggerSkill::triggerable(eren))
                return skill_list;
            //if (!eren->faceUp() || eren->isChained() || eren->getJudgingArea().length()>0 || )
            skill_list.insert(eren, QStringList(objectName()));
        }

        if (event == DamageCaused){
            QList<ServerPlayer *> erens = room->findPlayersBySkillName(objectName());
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.card || (!damage.card->isKindOf("Slash")&&(!damage.card->isKindOf("Duel")))){
                return skill_list;
            }
            foreach (ServerPlayer *eren, erens) {
                if (damage.to->getMark("@quzhu")>0 && damage.from == eren && damage.to->getMark("@quzhu") >= 2)
                    skill_list.insert(eren, QStringList(objectName()));
            }
        }
        if (event == PreCardUsed){
            QList<ServerPlayer *> erens = room->findPlayersBySkillName(objectName());
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card || (!use.card->isKindOf("Slash")&&(!use.card->isKindOf("Duel")))){
                return skill_list;
            }
            int n = 0;
            foreach(auto p, room->getAlivePlayers()){
                n=n+p->getMark("@quzhu");
            }
            int m = 0;
            foreach(auto p, use.to){
                m=m+p->getMark("@quzhu");
            }
            foreach (ServerPlayer *eren, erens) {
                if ( m>0 && use.from == eren && n > 2)
                    skill_list.insert(eren, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (event == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            if (player->askForSkillInvoke("quzhudamage", QVariant::fromValue(damage.to))){
                return true;
            }
        }
        if (event == PreCardUsed){
            if (player->askForSkillInvoke("quzhuaddtarget", data)){
                return true;
            }
        }
        if (event == TurnStart){
            if (player->hasShownSkill(this)||player->askForSkillInvoke("erenfate",data)){
                return true;
            }
        }

        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            damage.damage =  damage.damage+1;
            data.setValue(damage);
        }
        if (event == PreCardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            use.to.clear();
            QList<ServerPlayer *> list = room->getAlivePlayers();
            room->sortByActionOrder(list);
            foreach(ServerPlayer *p, list){
                if (p->getMark("@quzhu") > 0){
                    use.to.append(p);
                }
            }
            data = QVariant::fromValue(use);
        }
        if(event == TurnStart){
            if ((!ask_who->faceUp() || ask_who->isChained())&&ask_who->askForSkillInvoke("erenfate_normalize")){
                if (!ask_who->faceUp()){
                  ask_who->turnOver();
                }
                room->setPlayerProperty(ask_who, "chained", QVariant(false));
                QStringList choices;
                choices<<"eren_damage";
                if (ask_who->getPile("roads").length()>0)
                    choices << "discard_road";
                QString choice = room->askForChoice(ask_who, "erenfate", choices.join("+"));
                if (choice == "eren_damage"){
                    DamageStruct da;
                    da.from= NULL;
                    da.to=ask_who;
                    room->damage(da);
                }
                else{
                    room->fillAG(ask_who->getPile("roads"), ask_who);
                    int id = room->askForAG(ask_who, ask_who->getPile("roads"), false, objectName());
                    room->clearAG(ask_who);
                    room->throwCard(id, ask_who, ask_who);
                }
            }
            if (ask_who->isAlive() &&ask_who->getJudgingArea().length()>0 && ask_who->askForSkillInvoke("erenfate_discardjudge", data)){
                int id0 = room->askForCardChosen(ask_who, ask_who, "j", objectName());
                room->throwCard(id0, ask_who, ask_who);
                QStringList choices;
                choices<<"eren_damage";
                if (ask_who->getPile("roads").length()>0)
                    choices << "discard_road";
                QString choice = room->askForChoice(ask_who, "erenfate", choices.join("+"));
                if (choice == "eren_damage"){
                    DamageStruct da;
                    da.from= NULL;
                    da.to=ask_who;
                    room->damage(da);
                }
                else{
                    room->fillAG(ask_who->getPile("roads"), ask_who);
                    int id = room->askForAG(ask_who, ask_who->getPile("roads"), false, objectName());
                    room->clearAG(ask_who);
                    room->throwCard(id, ask_who, ask_who);
                }
            }
            if (ask_who->isAlive()&&ask_who->askForSkillInvoke("erenfate_seefuture", data)){
                int n =0;
                foreach(auto p, room->getAlivePlayers()){
                    if (p->getMark("@quzhu")>0){
                        n=n+1;
                    }
                    if (p->isFriendWith(ask_who)){
                        n=n+1;
                    }
                }
                QList<int> shenzhi = room->getNCards(n, false);

                LogMessage log;
                log.type = "$ViewDrawPile";
                log.from = ask_who;
                log.card_str = IntList2StringList(shenzhi).join("+");
                room->doNotify(ask_who, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
                room->askForGuanxing(ask_who, shenzhi);
                QStringList choices;
                choices<<"eren_damage";
                if (ask_who->getPile("roads").length()>0)
                    choices << "discard_road";
                QString choice = room->askForChoice(ask_who, "erenfate", choices.join("+"));
                if (choice == "eren_damage"){
                    DamageStruct da;
                    da.from= NULL;
                    da.to=ask_who;
                    room->damage(da);
                }
                else{
                    room->fillAG(ask_who->getPile("roads"), ask_who);
                    int id = room->askForAG(ask_who, ask_who->getPile("roads"), false, objectName());
                    room->clearAG(ask_who);
                    room->throwCard(id, ask_who, ask_who);
                }
            }
        }
        return false;
    }
};

ShisoCard::ShisoCard()
{
    will_throw = false;
}

bool ShisoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    if (targets.isEmpty()){
        return to_select->hasShownSkill("shizu") && to_select->getPile("roads").length()<13;
    }
}

void ShisoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (!source->hasShownOneGeneral()){
        source->askForGeneralShow(false, false);
    }
    ServerPlayer *target = targets.at(0);
    target->addToPile("roads", this);
}

class Shiso : public ViewAsSkill
{
public:

    Shiso() : ViewAsSkill("shiso")
    {
        attached_lord_skill = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        const Player *eren = player->getLord();
        if (!eren || !eren->hasShownSkill("shizu") || !player->willBeFriendWith(eren))
            return false;
        return !player->hasUsed("ShisoCard") && player->canShowGeneral();
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *card) const
    {
        return selected.length() < 1 && (card->getSuitString()=="heart" || card->getSuitString()=="spade");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        ShisoCard *zrc = new ShisoCard();
        zrc->addSubcards(cards);
        zrc->setSkillName(objectName());
        zrc->setShowSkill(objectName());
        return zrc;
    }
};

//double kingdoms
class Suipian : public TriggerSkill
{
public:
    Suipian() : TriggerSkill("suipian")
    {
        frequency = Frequent;
        events << EventPhaseStart << Damaged;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
   {
        TriggerList skill_list;
        if (event == EventPhaseStart){
            if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Start && player->getPile("Fragments").isEmpty()){
               skill_list.insert(player, QStringList(objectName()));
            }
        }
        else if(event == Damaged){
            DamageStruct damage = data.value<DamageStruct>();
            QList< ServerPlayer*> rikas = room->findPlayersBySkillName(objectName());
            foreach(auto rika, rikas){
                if (damage.to->isAlive() && damage.to ->isFriendWith(rika) && rika->getPile("Fragments").length()>0){
                    skill_list.insert(rika, QStringList(objectName()));
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *rika) const
    {
        if(rika->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *rika) const
    {
        if (event == EventPhaseStart){
           room->broadcastSkillInvoke(objectName(), rand()%2 +1 ,rika);
           int n = 1;
           foreach(auto p, room->getAlivePlayers()){
               if (p ->isFriendWith(player)){
                   n = n+1;
               }
           }

           QList<int> list = room->getNCards(n, false);
           rika->addToPile("Fragments", list);
           if (n>2){
               room->askForDiscard(rika, objectName(), 1, 1 ,false, true, QString());
           }
        }
        else{
           room->broadcastSkillInvoke(objectName(), rand()%4 +3 ,rika);
           room->fillAG(rika->getPile("Fragments"), rika);
           int id = room->askForAG(rika, rika->getPile("Fragments"), false, objectName());
           room->clearAG(rika);
           room->obtainCard(player, id);
           if (room->askForChoice(player,"transform","transform+cancel",data)=="transform"){
               player->showGeneral(false);
               room->transformDeputyGeneral(player);
           }
        }
        return false;
    }
};

class LunhuiRecord : public TriggerSkill
{
public:
    LunhuiRecord() : TriggerSkill("#lunhuirecord")
    {
        frequency = NotFrequent;
        events << CardFinished << EventPhaseEnd << CardUsed;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == CardFinished){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card!=NULL && (use.card->isKindOf("BasicCard")||use.card->isNDTrick()) && player->getPhase() == Player::Play) {
                 room->setPlayerProperty(player, "lunhui_card", QVariant(use.card->objectName()));
            }
        }
        else if(event == EventPhaseEnd){
            if (player->getPhase() == Player::Play){
                 room->setPlayerProperty(player, "lunhui_card", QVariant(""));
            }
        }
        else{
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card != NULL && use.card->getSkillName()=="lunhui"){
                room->setPlayerFlag(player, "lunhui_used");
            }
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Lunhui : public OneCardViewAsSkill
{
public:
    Lunhui() : OneCardViewAsSkill("lunhui"){
        filter_pattern = ".|.|.|Fragments";
        expand_pile = "Fragments";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        QString pattern=Self->property("lunhui_card").toString();
        if (pattern=="")
            return NULL;
        Card *card=Sanguosha->cloneCard(pattern,originalCard->getSuit(),originalCard->getNumber());
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasFlag("lunhui_used") && player->getKingdom()=="magic";
    }

};

PoxiaoCard::PoxiaoCard()
{
}

bool PoxiaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.isEmpty()){
        return true;
    }
    return false;
}

void PoxiaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    QString choice = room->askForChoice(source,"poxiao","Mipa_Basic+Mipa_NotBasic");
    if (choice == "Mipa_Basic") {
        target->gainMark("@mipa_basic");
        room->setPlayerCardLimitation(target, "use,response", "BasicCard+^Slash", false);
    }
    else{
        target->gainMark("@mipa_notbasic");
        room->setPlayerCardLimitation(target, "use,response", "^BasicCard", false);
    }
}

class Poxiao : public OneCardViewAsSkill
{
public:
    Poxiao() : OneCardViewAsSkill("poxiao"){
        filter_pattern = ".|.|.|Fragments";
        expand_pile = "Fragments";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("PoxiaoCard") && player->getKingdom()=="real";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        PoxiaoCard *vs = new PoxiaoCard();
        vs->addSubcard(originalCard);
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class PoxiaoTrigger : public TriggerSkill
{
public:
    PoxiaoTrigger() : TriggerSkill("#poxiao")
    {
        frequency = NotFrequent;
        events << EventPhaseEnd;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseEnd) {
             if (player->getPhase()==Player::Finish){
                 if (player->getMark("@mipa_basic") > 0) {
                     player->loseMark("@mipa_basic");
                     room->removePlayerCardLimitation(player, "use,response", "BasicCard+^Slash");
                  }
                 if (player->getMark("@mipa_notbasic") > 0) {
                     player->loseMark("@mipa_notbasic");
                     room->removePlayerCardLimitation(player, "use,response", "^BasicCard");
                 }
             }
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Yandan : public TriggerSkill
{
public:
    Yandan() : TriggerSkill("yandan")
    {
        frequency = NotFrequent;
        events << CardsMoveOneTime << Death;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *makoto, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(makoto) && event == CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.from_places.contains(Player::PlaceHand) && !move.from_places.contains(Player::PlaceEquip)){
                return QStringList();
            }
            if (!move.from || move.from->getPhase() != Player::NotActive){
                return QStringList();
            }
            if (move.reason.m_reason != CardMoveReason::S_REASON_DISCARD && move.reason.m_reason != CardMoveReason::S_REASON_DISMANTLE && move.reason.m_reason != CardMoveReason::S_REASON_THROW && move.reason.m_reason != CardMoveReason::S_REASON_RULEDISCARD){
                return QStringList();
            }
            if (move.card_ids.length() == 0){
                return QStringList();
            }
            if (makoto->getPile("yandan").length() > makoto->getMaxHp()){
                return QStringList();
            }
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *makoto, QVariant &data, ServerPlayer *ask_who) const
    {
        if (makoto->askForSkillInvoke(this, data)){
            room->broadcastSkillInvoke(objectName(), makoto);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *makoto, QVariant &data, ServerPlayer *) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        QList<int> list = move.card_ids;
        room->fillAG(list, makoto);
        int id = room->askForAG(makoto, list, true, objectName());
        room->clearAG(makoto);
        if (id != -1){
            makoto->addToPile("yandan", id);
        }
        return false;
    }
};

class YandanMaxCards : public MaxCardsSkill
{
public:
    YandanMaxCards() : MaxCardsSkill("#yandan")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->hasSkill("yandan")){
            int i = target->getPile("yandan").length() > 0 ? 1 : 0;
            return  i + target->getMark("yandan_death");
        }
        else
            return 0;
    }
};

class Lunpo : public TriggerSkill
{
public:
    Lunpo() : TriggerSkill("lunpo")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << EventPhaseChanging << Death << CardUsed;
        relate_to_place = "head";
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
   {
        TriggerList skill_list;
        if (event == EventPhaseStart){

        }
        else if(event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("EquipCard")|| use.card->isKindOf("DelayedTrick") ||use.to.isEmpty()){
                return skill_list;
            }
            QList< ServerPlayer*> makotos = room->findPlayersBySkillName(objectName());
            foreach(auto makoto, makotos){
                foreach(int id, makoto->getPile("yandan")){
                    if (use.card->getSuit()==Sanguosha->getCard(id)->getSuit()){
                      skill_list.insert(makoto, QStringList(objectName()));
                      break;
                    }
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *makoto) const
    {
        if(makoto->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *makoto) const
    {
        if (event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            QList<int> list;
            foreach(int id, makoto->getPile("yandan")){
                if (Sanguosha->getCard(id)->getSuit() == use.card->getSuit()){
                    list.append(id);
                }
            }
            room->fillAG(list, makoto);
            int id = room->askForAG(makoto, list, true, objectName());
            room->clearAG(makoto);
            if (id != -1){
                room->throwCard(id, makoto, makoto);
                room->broadcastSkillInvoke(objectName(), makoto, 2);
                room->doLightbox("lunpo$", 300);
                return true;
            }
        }
        return false;
    }
};

class Zizheng : public ViewAsSkill
{
public:
    Zizheng() : ViewAsSkill("zizheng")
    {
        relate_to_place = "deputy";
        expand_pile = "yandan";
        response_pattern = "nullification";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Self->getHandcards().contains(to_select)||Self->getEquips().contains(to_select))
            return false;
        return selected.length()<2;
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length()<2)
            return NULL;
        Card *ncard = new HegNullification(Card::SuitToBeDecided, -1);
        ncard->addSubcards(cards);
        ncard->setSkillName(objectName());
        ncard->setShowSkill(objectName());
        return ncard;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "nullification";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    virtual bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        QList <int> list = player->getPile("yandan");
        if (list.length()>1){
            return true;
        }
        return false;
    }
};

class ZizhengTrigger : public TriggerSkill
{
public:
    ZizhengTrigger() : TriggerSkill("#zizheng")
    {
        frequency = NotFrequent;
        events << CardFinished;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == CardFinished) {
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card!= NULL && use.card->getSubcards().length()>=2 && use.card->getSkillName()=="zizheng"){
                 Card *c1 = Sanguosha->getCard(use.card->getSubcards().at(0));
                 Card *c2 = Sanguosha->getCard(use.card->getSubcards().at(1));
                 if (c1->getSuit()==c2->getSuit() || c1->getNumber()==c2->getNumber()){
                    if ( room->askForChoice(player,"zizheng","zizheng_transform+cancel",data)=="zizheng_transform"){
                        QStringList avaliable_generals;
                        foreach(QString s,player->getSelected()){
                            if (s!=player->getActualGeneral1Name()&&s!=player->getGeneral2Name())
                                avaliable_generals << s;
                        }
                        QString to_change = room->askForGeneral(player, avaliable_generals, QString(), true, "zizheng", player->getKingdom());
                        player->showGeneral(false);
                        room->transformDeputyGeneralTo(player, to_change);
                    }
                 }
             }
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

//ice_slash
class IceSlashSkill : public TriggerSkill
{
public:
    IceSlashSkill() : TriggerSkill("IceSlash")
    {
        events << DamageCaused;
        global = true;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();

        if (damage.card && damage.card->isKindOf("IceSlash")
            && !damage.to->isNude() && damage.by_user
            && !damage.chain && !damage.transfer && player->askForSkillInvoke(this, data)) {
            if (damage.from->canDiscard(damage.to, "he")) {
                int card_id = room->askForCardChosen(player, damage.to, "he", "IceSword", false, Card::MethodDiscard);
                room->throwCard(Sanguosha->getCard(card_id), damage.to, damage.from);

                if (damage.from->isAlive() && damage.to->isAlive() && damage.from->canDiscard(damage.to, "he")) {
                    card_id = room->askForCardChosen(player, damage.to, "he", "IceSword", false, Card::MethodDiscard);
                    room->throwCard(Sanguosha->getCard(card_id), damage.to, damage.from);
                }
            }
            return true;
        }
        return false;
    }
};

//new cards
GuangyuCard::GuangyuCard(Suit suit, int number, bool is_transferable) : BasicCard(suit, number)
{
    setObjectName("guangyucard");
    target_fixed = false;
    transferable = is_transferable;
}

QString GuangyuCard::getSubtype() const
{
    return "assist_card";
}

bool GuangyuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    int total_num = 1 + Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
    if (targets.length() >= total_num)
        return false;

    return true;
}

void GuangyuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    BasicCard::onUse(room, use);
}

void GuangyuCard::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    //room->setEmotion(effect.from, "guangyu");

    if (effect.to->hasFlag("Global_Dying") && Sanguosha->getCurrentCardUseReason() != CardUseStruct::CARD_USE_REASON_PLAY) {
        // recover hp
        RecoverStruct recover;
        recover.card = this;
        recover.who = effect.from;
        room->recover(effect.to, recover ,true);
    } else {
        room->setPlayerProperty(effect.to, "chained", QVariant(false));
        if (!effect.to->faceUp()){
            effect.to->turnOver();
        }
    }

    foreach(auto c, effect.to->getJudgingArea()){
        if (c->isKindOf("Key")){
            room->obtainCard(effect.to, c);
        }
    }
}

bool GuangyuCard::isAvailable(const Player *player) const
{
    return !player->isProhibited(player, this) && BasicCard::isAvailable(player);
}


RevolutionPackage::RevolutionPackage()
    : Package("revolution")
{

  skills << new Xingbao << new Jiyuunotsubasa << new Shiso << new Zahyo << new TrialTrigger<< new LianjiTrigger
        << new LunhuiRecord << new PoxiaoTrigger << new YandanMaxCards << new PoshiDistance << new PoshiTargetMod << new PoshiTrigger << new ZizhengTrigger << new Xintiao;

  //real
  General *yukino = new General(this, "Yukino", "real", 3, false);
  yukino->addSkill(new Shifeng);
  yukino->addSkill(new Zhiyan);
  yukino->addCompanion("Hikigaya");

  General *yuri = new General(this, "yuri", "real", 3, false);
  yuri->addSkill(new Zuozhan);
  yuri->addSkill(new Nishen);

  General *yuzuru = new General(this, "Yuzuru", "real", 4);
  yuzuru->addSkill(new Jiuzhu);
  yuzuru->addSkill(new Shexin);
  yuzuru->addRelateSkill("xintiao");
  yuzuru->setDeputyMaxHpAdjustedValue(-1);
  yuzuru->addCompanion("Kanade");

  //science
  General *kirito = new General(this, "Kirito", "science", 4);
  kirito->addSkill(new Erdao);
  kirito->addSkill(new ErdaoExtra);
  insertRelatedSkills("erdao", "#erdaoextra");
  kirito->addSkill(new Fengbi);
  kirito->addCompanion("SE_Asuna");
  kirito->addRelateSkill("xingbao");

  General *eugeo = new General(this, "Eugeo", "science", 3);
  eugeo->addSkill(new Rennai);
  eugeo->addSkill(new Zhanfang);
  eugeo->addCompanion("Kirito");

  General *yuuki = new General(this, "Yuuki", "science", 4, false);
  yuuki->addSkill(new Yaozhan);
  yuuki->addSkill(new Lianji);
  yuuki->addCompanion("SE_Asuna");

  General *WSaki = new General(this, "WSaki", "science", 3, false);

  //magic
  General *rem = new General(this, "Rem", "magic", 3, false);
  rem->addSkill(new Lianchui);
  rem->addSkill(new Xianshu);
  rem->addSkill(new Huanbing);
  General *asagi = new General(this, "Asagi", "magic", 3, false);
  asagi->addSkill(new Guanli);
  asagi->addSkill(new Poyi);
  //General *arc4subaru = new General(this, "Arc4subaru", "magic", 3);
  //arc4subaru->addSkill(new Trial);
  General *fuwaaika = new General(this, "Fuwaaika", "magic", 3, false);
  fuwaaika->addSkill(new Poshi);
  fuwaaika->addSkill(new Liansuo);
  fuwaaika->addSkill(new Yinguo);

  //game
  General *akagi= new General(this, "Akagi", "game", 4, false);
  akagi->addSkill(new Chicheng);
  akagi->addSkill(new Zhikong);
  akagi->addCompanion("Kaga");
  General *asashio = new General(this, "Asashio", "game", 3, false);
  asashio->addSkill(new Fanqian);
  asashio->addSkill(new Buyu);

  //lord
  /*General *lorderen = new General(this, "lord_SE_Eren$", "science", 4, true, true);
  lorderen->addSkill(new Jinji);
  lorderen->addRelateSkill("jiyuunotsubasa");
  lorderen->addSkill(new Shizu);
  lorderen->addRelateSkill("zahyo");
  insertRelatedSkills("shizu", "zahyo");*/

  //boss
  //General *shiso_no_kyojin = new General(this, "Shiso_no_kyojin", "god", 5, true, true);

  //double kingdom
  General *rika = new General(this, "Rika", "magic|real", 3, false);
  rika->addSkill(new Suipian);
  rika->addSkill(new Lunhui);
  rika->addSkill(new Poxiao);
  General *nmakoto = new General(this, "NMakoto", "science|real", 4);
  nmakoto->addSkill(new Yandan);
  nmakoto->addSkill(new Lunpo);
  nmakoto->addSkill(new Zizheng);
  nmakoto->setHeadMaxHpAdjustedValue(-1);

  addMetaObject<ShifengCard>();
  addMetaObject<ZhiyanCard>();
  addMetaObject<XingbaoCard>();
  addMetaObject<ShisoCard>();
  addMetaObject<FanqianCard>();
  addMetaObject<PoyiCard>();
  addMetaObject<ChichengCard>();
  addMetaObject<YaozhanCard>();
  addMetaObject<PoxiaoCard>();
  addMetaObject<PoshiCard>();
  addMetaObject<JiuzhuCard>();
  addMetaObject<ShexinCard>();
}

RevolutionCardPackage::RevolutionCardPackage() : Package("revolutioncard", CardPack)
{
    QList<Card *> cards;
    cards << new IceSlash(Card::Spade, 7)
        << new IceSlash(Card::Spade, 7)
        << new IceSlash(Card::Spade, 8)
        << new IceSlash(Card::Spade, 8)
        << new IceSlash(Card::Spade, 8)
        << new GuangyuCard(Card::Heart, 5)
        << new GuangyuCard(Card::Heart, 6)
        << new GuangyuCard(Card::Heart, 9);

    foreach(Card *card, cards)
        card->setParent(this);

}

ADD_PACKAGE(Revolution)
ADD_PACKAGE(RevolutionCard)
