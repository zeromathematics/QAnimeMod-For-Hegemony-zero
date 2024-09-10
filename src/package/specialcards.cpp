#include "revolution.h"
#include "newtest.h"
#include "specialcards.h"
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
#include "qmath.h"
#include "room.h"
#include "lua-wrapper.h"

//real
class Mengxian : public TriggerSkill
{
public:
    Mengxian() : TriggerSkill("mengxian")
    {
        frequency = NotFrequent;
        events << EventPhaseStart;
    }
    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Draw)
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QString choice = room->askForChoice(player, objectName(), "basic+trick+equip");
        while (true){
            //QString equip = (player->isKongcheng() ? "" : "+equip");
            //QString choice = room->askForChoice(player, objectName(), "basic+trick+equip");
            JudgeStruct judge;
            judge.who = player;
            judge.negative = false;
            judge.play_animation = false;
            judge.time_consuming = true;
            judge.reason = objectName();
            judge.pattern = choice == "equip" ? "EquipCard" : (choice == "trick" ? "TrickCard" : "BasicCard");
            room->judge(judge);
            if ((judge.card->isKindOf("BasicCard") && choice == "basic") || (judge.card->isKindOf("TrickCard") && choice == "trick") || (judge.card->isKindOf("EquipCard") && choice == "equip")){
                if (judge.card->isKindOf("BasicCard"))
                    room->broadcastSkillInvoke(objectName(), 1);
                else if (judge.card->isKindOf("TrickCard"))
                    room->broadcastSkillInvoke(objectName(), 2);
                else
                    room->broadcastSkillInvoke(objectName(), 3);
                room->doLightbox(objectName() + "$", 500);
                room->obtainCard(player, judge.card);
                break;
            }
        }


        return false;
    }
};

class Yuanwang : public TriggerSkill
{
public:
    Yuanwang() : TriggerSkill("yuanwang")
    {
        frequency = Club;
        club_name = "sos",
        events << EventPhaseStart << EventPhaseEnd;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {

    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == EventPhaseStart){
            if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Play){
                QList<ServerPlayer *> targets = room->getOtherPlayers(player);
                QList<ServerPlayer *> targets_copy = targets;
                QList<ServerPlayer *> list;
                foreach(ServerPlayer *s, targets){
                    if (s->hasClub("sos")){
                        list.append(s);
                    }
                }
                foreach(ServerPlayer *s, targets_copy){
                    foreach(ServerPlayer *t, list){
                        if (s->isFriendWith(t)){
                            targets.removeOne(s);
                            break;
                        }
                    }
                    if (!s->hasShownOneGeneral() && targets.contains(s)){
                        targets.removeOne(s);
                    }
                }

                if (targets.count() > 0){
                    skill_list.insert(player, QStringList(objectName()));
                }
            }
        }
        else{
            if (player->hasClub("sos") && player->getPhase()==Player::Play){
                ThreatenEmperor *t = new ThreatenEmperor(Card::NoSuit,-1);
                if (t->isAvailable(player) && !player->isKongcheng()){
                    skill_list.insert(player, QStringList(objectName()));
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(event == EventPhaseStart && ask_who->askForSkillInvoke(this, data)){
            QList<ServerPlayer *> targets = room->getOtherPlayers(player);
            QList<ServerPlayer *> targets_copy = targets;
            QList<ServerPlayer *> list;
            foreach(ServerPlayer *s, targets){
                if (s->hasClub("sos")){
                    list.append(s);
                }
            }
            foreach(ServerPlayer *s, targets_copy){
                foreach(ServerPlayer *t, list){
                    if (s->isFriendWith(t)){
                        targets.removeOne(s);
                        break;
                    }
                }
                if (!s->hasShownOneGeneral() && targets.contains(s)){
                    targets.removeOne(s);
                }
            }
            ServerPlayer *target = room->askForPlayerChosen(ask_who, targets, objectName(), "@yuanwang", true);
            if (target){
               ask_who->tag["yuanwang_target"] = QVariant::fromValue(target);
               return true;
            }
        }
        else if (event == EventPhaseEnd && ask_who->askForSkillInvoke("yuanwangsos", data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *haruhi) const
    {
        if (event == EventPhaseStart){
            ServerPlayer *target = haruhi->tag["yuanwang_target"].value<ServerPlayer *>();
            if (target){
                room->broadcastSkillInvoke(objectName(), haruhi);

                if (room->askForChoice(target, objectName(), objectName() + "_accept+cancel", QVariant::fromValue(haruhi)) == objectName() + "_accept"){
                    target->addClub("sos");
                    if (!target->faceUp()){
                        target->turnOver();
                    }
                }
                else{
                    LogMessage log;
                    log.type = "$refuse_club";
                    log.from = target;
                    log.arg = "sos";
                    room->sendLog(log);
                }
            }
        }
        else{
            QList<int> dislist;
            foreach(auto id, haruhi->handCards()){
                if (!Sanguosha->getCard(id)->isBlack()){
                    dislist << id;
                }
            }
            room->fillAG(haruhi->handCards(), haruhi, dislist);
            int id = room->askForAG(haruhi, haruhi->handCards(), true, objectName());
            room->clearAG(haruhi);
            if (id > -1){
                Card *card = Sanguosha->getCard(id);
                ThreatenEmperor *t = new ThreatenEmperor(card->getSuit(),card->getNumber());
                t->addSubcard(card);
                CardUseStruct use;
                use.from = haruhi;
                use.to << haruhi;
                use.card = t;
                room->useCard(use);
            }

        }
        return false;
    }
};

PengtiaoCard::PengtiaoCard()
{
    target_fixed = true;
    will_throw = false;
}

void PengtiaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
     return;
}

class Pengtiaovs : public OneCardViewAsSkill
{
public:
    Pengtiaovs() : OneCardViewAsSkill("pengtiao"){
       response_or_use = true;
    }

    bool viewFilter(const Card *card) const
    {
        return card->isKindOf("Peach") || card->isKindOf("Analeptic") || card->getNumber()==13 || card->getSubtype() == "food_card";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        PengtiaoCard *vs = new PengtiaoCard();
        vs->addSubcard(originalCard->getId());
        vs->setSkillName(objectName());
        return vs;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "@@pengtiao";
    }
};

class Pengtiao : public TriggerSkill
{
public:
    Pengtiao() : TriggerSkill("pengtiao")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << CardUsed << EventPhaseEnd;
        view_as_skill = new Pengtiaovs;
    }

    virtual bool canPreshow() const
    {
        return true;
    }


    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
         if (event == EventPhaseEnd && player->getPhase() == Player::Play){
             foreach(auto p, room->getAlivePlayers()){
                if (p->hasFlag(player->objectName()+"pengtiao_target")){
                    room->setPlayerFlag(p, "-"+player->objectName()+"pengtiao_target");
                }
             }
         }
         if (event == CardUsed){
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card && !use.card->isKindOf("TrickCard") && use.card->getTypeId() != Card::TypeSkill && player->getPhase()==Player::Play){
                 foreach(auto p, room->getOtherPlayers(player)){
                     if (p->hasFlag(player->objectName()+"pengtiao_target") && p->isWounded()){
                         if (player->askForSkillInvoke("pengtiao_recover", QVariant::fromValue(p))){
                             RecoverStruct recover;
                             recover.recover = 1;
                             recover.who = player;
                             room->recover(p, recover, true);
                         }
                     }
                 }
             }
         }
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseStart && player->getPhase() == Player::Play && TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        return QStringList();
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)){
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        foreach(auto p, room->getOtherPlayers(player)){
            const Card *card = room->askForUseCard(p, "@@pengtiao", "@pengtiao");
            if (card) {
                room->obtainCard(player, card);
                room->setPlayerFlag(p, player->objectName()+"pengtiao_target");
                break;
            }
            else{
                room->setPlayerFlag(p, "pengtiao_cancel");
            }
            foreach(auto p, room->getAlivePlayers()){
               room->setPlayerFlag(p, "-pengtiao_cancel");
            }
        }

        return false;
    }
};

class Shiji : public TriggerSkill
{
public:
    Shiji() : TriggerSkill("shiji")
    {
        frequency = NotFrequent;
        events << CardUsed << Pindian;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Pindian){
            PindianStruct *pindian = data.value<PindianStruct *>();
            if (pindian->reason == objectName()){
                ServerPlayer *winner = pindian->isSuccess() ? pindian->from : pindian->to;
                ServerPlayer *loser = pindian->isSuccess() ? pindian->to : pindian->from;
                QString choices = "cancel";
                if (winner->getHp() < loser->getHp() && winner->isWounded()){
                   choices = "shiji_recover+"+choices;
                }
                if (winner->getHandcardNum() < loser->getHandcardNum()){
                   choices = "shiji_draw+"+choices;
                }
                QString choice = room->askForChoice(winner, objectName(), choices, data);
                if (choice == "shiji_recover"){
                    RecoverStruct recover;
                    recover.recover = 1;
                    room->recover(winner, recover, true);
                }
                if (choice == "shiji_draw"){
                    winner->drawCards(1);
                }
            }
        }
    }

     virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            QList<ServerPlayer *> yukihiras = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *yukihira, yukihiras)
                if ((use.card->isKindOf("Peach") || use.card->isKindOf("Analeptic") || use.card->getSubtype() == "food_card") && player->getPhase()==Player::Play && !yukihira->isKongcheng() && yukihira != player && !player->isKongcheng())
                    skill_list.insert(yukihira, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *yukihira) const
    {
        if (yukihira->askForSkillInvoke(this, QVariant::fromValue(player))){
            room->broadcastSkillInvoke(objectName(), yukihira);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *yukihira) const
    {
        if (yukihira->isKongcheng()||player->isKongcheng())
            return false;
        PindianStruct *pd = yukihira->pindianSelect(player, objectName());
        if (yukihira->pindian(pd)) {
           return true;
        }
        return false;
    }
};

class Revival : public TriggerSkill
{
public:
    Revival() : TriggerSkill("revival")
    {
        frequency = Limited;
        limit_mark = "@revival",
        events << DamageInflicted;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {

    }

     virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == DamageInflicted) {
            DamageStruct damage = data.value<DamageStruct>();
            QList<ServerPlayer *> fs = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *f, fs)
                if (f->getMark("@revival")>0 && f->getPhase() == Player::NotActive && f->isFriendWith(damage.to))
                    skill_list.insert(f, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *f) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (f->askForSkillInvoke(this, QVariant::fromValue(damage.to))){
            room->broadcastSkillInvoke(objectName(), rand()%2+1, f);
            f->loseMark("@revival");
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *f) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        room->setTag(f->objectName()+"revival"+damage.to->objectName(), QVariant(true));
        /*QList<int> list = room->getDiscardPile();
        QList<int> id_list;
        while(id_list.length()<5 && list.length()>0){
            int id = list.at(rand()%list.length());
            id_list << id;
            list.removeOne(id);
        }
        if (id_list.length() > 0){
            room->askForGuanxing(f, id_list);
        }*/

        QList<int> revival = room->getNCards(5, false);

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = f;
        log.card_str = IntList2StringList(revival).join("+");
        room->doNotify(f, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
        room->askForGuanxing(f, revival);

        QString choice = room->askForChoice(f, objectName(), "revival_prevent+revival_back");
        if (choice == "revival_prevent"){
            JudgeStruct judge;
            if (damage.card) {
                judge.pattern = ".|"+damage.card->getSuitString()+"|.";
            }
            judge.good = true;
            judge.reason = "revival";
            judge.who = f;
            room->judge(judge);
            if (damage.card && judge.card->getSuit()==damage.card->getSuit()){
                return true;
            }
        }
        else{
            room->broadcastSkillInvoke(objectName(), 3, f);
            room->loseMaxHp(f);
            if (f->isAlive()){
                f->gainAnInstantExtraTurn();
            }
        }
        return false;
    }
};

QList<ServerPlayer *> FhuanxingList;
class Fhuanxing : public TriggerSkill
{
public:
    Fhuanxing() : TriggerSkill("fhuanxing")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << Dying;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseStart && player->getPhase()==Player::Finish && TriggerSkill::triggerable(player) && !player->hasFlag("Point_ExtraTurn")){
            QList<ServerPlayer *> list;
            int n = 998;
            foreach(auto p, room->getAlivePlayers()){
                if (p->getHp() < n){
                    n = p->getHp();
                }
            }
            foreach(auto p, room->getAlivePlayers()){
                if (p->getHp() <= player->getHp() && p->isFriendWith(player) && p!=player){
                    list << p;
                }
            }
            if (list.length()>0){
                FhuanxingList = list;
                return QStringList(objectName());
            }
        }
        /*else if(event == Dying){
            DyingStruct dying = data.value<DyingStruct>();
            if (dying.who->isFriendWith(player) && TriggerSkill::triggerable(player) && player->getMaxHp()<4){
                return QStringList(objectName());
            }
        }*/
        return QStringList();
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseStart && player->askForSkillInvoke(this, data) ) {
            ServerPlayer *target=room->askForPlayerChosen(player,FhuanxingList,objectName(),QString(),true,true);
            FhuanxingList.clear();
            if (target){
              player->tag["fhuanxing_target"] = QVariant::fromValue(target);
              return true;
            }
        }
        else if (event == Dying){
            if(player->hasShownSkill(objectName()) || player->askForSkillInvoke(this, data)){
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart){
            ServerPlayer *dest = player->tag["fhuanxing_target"].value<ServerPlayer *>();
            if (dest && !player->isNude()){
                int id = room->askForCardChosen(player,player,"he",objectName());
                room->obtainCard(dest, id, false);
                if (player->getMaxHp()<4){
                    room->setPlayerProperty(player, "maxhp", QVariant(player->getMaxHp()+1));
                }
                room->setPlayerMark(player,"@revival", 1);
            }
        }
        else{
            DyingStruct dying = data.value<DyingStruct>();
            room->setPlayerProperty(player, "maxhp", QVariant(player->getMaxHp()+1));
            /*if (player->getHandcardNum()< player->getMaxHp()){
                player->drawCards(player->getMaxHp()-player->getHandcardNum());
            }*/
            player->drawCards(1);
            if (room->getTag(player->objectName()+"revival"+dying.who->objectName()).toBool()){
                if (room->askForChoice(player, objectName(), "revival_recover+cancel") == "revival_recover"){
                    int n = 1-dying.who->getHp();
                    RecoverStruct recover;
                    recover.recover = n;
                    recover.who = player;
                    room->recover(dying.who, recover, true);
                    room->loseHp(player,n);
                }
            }
        }
        return false;
    }
};

class Huaming : public TriggerSkill
{
public:
    Huaming() : TriggerSkill("huaming")
    {
        events << DamageInflicted;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        return;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == DamageInflicted) {
            QList<ServerPlayer *> meikos = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *meiko, meikos){
                bool can = false;
                foreach(auto p, room->getAlivePlayers()){
                    if (p->getMark("huamingtri")==0 && !p->hasShownAllGenerals()){
                        can = true;
                    }
                }
                if (can)
                    skill_list.insert(meiko, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (ask_who->askForSkillInvoke(this, QVariant::fromValue(damage.to))){
            if (!ask_who->hasShownSkill(this) && ask_who->getMark("huamingtri")==0){
                room->broadcastSkillInvoke(objectName(), 1, player);
                room->setPlayerMark(ask_who, "huamingtri", 1);
                room->setPlayerFlag(ask_who, "huamingselfshow");
            }
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (ask_who->hasFlag("huamingselfshow")){
           room->setPlayerFlag(ask_who, "-huamingselfshow");
           ask_who->drawCards(1);
           if (damage.damage<= 1)
              return true;
           else{
               damage.damage = damage.damage-1;
               data.setValue(damage);
           }
        }
        else{
           QList<ServerPlayer *> players;
           foreach(auto p, room->getOtherPlayers(ask_who)){
               if (!p->hasShownAllGenerals() && (p->getMark("huamingtri")==0)){
                   players<<p;
               }
           }
           room->sortByActionOrder(players);
           foreach(auto p, players){
               QString choice = room->askForChoice(p, "huaming", "huaming_show+cancel", QVariant::fromValue(ask_who));
               if (choice!="cancel"){
                   bool show = p->askForGeneralShow(true, true);
                   if (show){
                       room->setPlayerMark(p, "huamingtri", 1);
                       room->broadcastSkillInvoke(objectName(), 2, player);
                       p->drawCards(1);
                       if (damage.damage<= 1)
                          return true;
                       else{
                           damage.damage = damage.damage-1;
                           data.setValue(damage);
                       }
                   }
               }
           }
        }
        return false;
    }
};

class Xinyuan : public TriggerSkill
{
public:
    Xinyuan() : TriggerSkill("xinyuan")
    {
        events << EventPhaseEnd << CardsMoveOneTime;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip)) && player->getPhase()!=Player::NotActive){
                if (!(move.to == player && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip)) && (move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD ){
                    room->setPlayerMark(player, "xinyuan_num", player->getMark("xinyuan_num")+move.card_ids.length());
                }
            }
        }
        if (event == EventPhaseEnd && player->getPhase()==Player::Finish){
            room->setPlayerMark(player, "xinyuan_num", 0);
        }
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseEnd && player->getPhase()==Player::Discard && TriggerSkill::triggerable(player)){
            if (player->getMark("xinyuan_num")>= 2){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseEnd && player->askForSkillInvoke(this, data) ) {
            ServerPlayer *target=room->askForPlayerChosen(player,room->getAlivePlayers(),objectName(),QString(),true,true);
            if (target){
              player->tag["xinyuan_target"] = QVariant::fromValue(target);
              room->broadcastSkillInvoke(objectName(), player);
              return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *dest = player->tag["xinyuan_target"].value<ServerPlayer *>();
        if (dest){
            dest->drawCards(qMax(dest->getMaxHp()-dest->getHandcardNum(), 2));
        }
        return false;
    }
};

class Qifen : public TriggerSkill
{
public:
    Qifen() : TriggerSkill("qifen")
    {
        events << EventPhaseStart << CardsMoveOneTime;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {

    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseStart && player->getPhase()==Player::Finish && TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        return QStringList();
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseStart && player->askForSkillInvoke(this, data) ) {
            ServerPlayer *target=room->askForPlayerChosen(player,room->getAlivePlayers(),objectName(),QString(),true,true);
            if (target){
              player->tag["qifen_target"] = QVariant::fromValue(target);
              room->broadcastSkillInvoke(objectName(), player);
              return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *dest = player->tag["qifen_target"].value<ServerPlayer *>();
        if (dest){
            auto list = room->getAlivePlayers();
            room->sortByActionOrder(list);
            foreach(auto p, list){
                if (p->isFriendWith(dest)){
                    p->drawCards(1);
                }
            }
            if (player->getLostHp()>0){
                room->doLightbox(objectName() + "$", 800);
                foreach(ServerPlayer* p, list){
                    if (!p->isNude() && p->isFriendWith(dest)){
                        room->obtainCard(player, room->askForCardChosen(player, p, "he", objectName()), false);
                    }
                }
            }
        }
        return false;
    }
};

class Mishi : public TriggerSkill
{
public:
    Mishi() : TriggerSkill("mishi")
    {
        events << Dying;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (player!=dying.who && dying.who && dying.who->isAlive() && !room->getCurrent()->hasFlag("mishi_used") && TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        return QStringList();
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(dying.who)) ) {
            room->setPlayerFlag(room->getCurrent(), "mishi_used");
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        room->doLightbox(objectName() + "$", 800);
        room->showAllCards(player);
        room->loseHp(player);
        room->loseHp(dying.who);
        room->setPlayerFlag(dying.who, "mishi"+player->objectName());
        return false;
    }
};

class MishiTrigger : public TriggerSkill
{
public:
    MishiTrigger() : TriggerSkill("#mishi")
    {
        frequency = NotFrequent;
        events << AskForPeachesDone;
        global=true;
    }

    virtual int getPriority() const
    {
        return -4;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && player->getHp()>0) {
            foreach(auto p, room->getAlivePlayers()){
                if (player->hasFlag("mishi"+p->objectName())){
                    room->setPlayerFlag(player, "-mishi"+p->objectName());
                    if (player->isAlive() && !player->isNude()){
                        room->obtainCard(p , room->askForCardChosen(p, player, "he", objectName()), false);
                    }
                    break;
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

class Zhufu : public TriggerSkill
{
public:
    Zhufu() : TriggerSkill("zhufu")
    {
        frequency = Limited;
        limit_mark = "@zhufu";
        events << EventPhaseStart;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!player->isKongcheng() && player->getPhase() == Player::Draw && player->getMark("@zhufu") > 0 && TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        return QStringList();
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data) ) {
            player->loseMark("@zhufu");
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QList<int> ids = player->handCards();
        bool has = true;
        while (has && room->askForYiji(player, ids, objectName(),false, false, true, -1)) {
            bool newhas = false;
            foreach(int id, player->handCards()){
                if (ids.contains(id)){
                    newhas = true;
                }
            }
            has = newhas;
        }
        return false;
    }
};

//science
class Takamakuri : public TriggerSkill
{
public:
    Takamakuri() : TriggerSkill("Takamakuri")
    {
        frequency = NotFrequent;
        events << Damage;
    }
    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (TriggerSkill::triggerable(player))
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(damage.to))) {
            return true;
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *akari, QVariant &data, ServerPlayer *) const
    {
        if (event == Damage){
            DamageStruct damage = data.value<DamageStruct>();
            akari->setFlags("TakamakuriUsed");
            int id = room->getDrawPile().at(0);
            QList<int> ids;
            ids.append(id);
            room->fillAG(ids);
            room->getThread()->delay(800);

            room->clearAG();
            if (Sanguosha->getCard(id)->isKindOf("BasicCard")){
                room->broadcastSkillInvoke(objectName(), akari);
                room->obtainCard(akari, id);
                if (damage.to->getEquips().length() > 0)
                    room->throwCard(room->askForCardChosen(akari, damage.to, "e", objectName()), damage.to, akari);
            }
        }
        return false;
    }
};

class Tobiugachi : public TriggerSkill
{
public:
    Tobiugachi() : TriggerSkill("Tobiugachi")
    {
        frequency = NotFrequent;
        events << CardAsked;
    }
    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern == "jink" && TriggerSkill::triggerable(player) && player->getHandcardNum() > player->getHp())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *akari, QVariant &data, ServerPlayer *) const
    {
        if (event == CardAsked){
            if (room->askForDiscard(akari, objectName(), akari->getHandcardNum() - akari->getHp() + 1, akari->getHandcardNum() - akari->getHp() + 1)){
                akari->setFlags("TobiugachiUsed");
                Card* jink = Sanguosha->cloneCard("jink", Card::NoSuit, 0);
                jink->setSkillName(objectName());
                room->provide(jink);
                ServerPlayer *target = room->askForPlayerChosen(akari, room->getAlivePlayers(), objectName());
                QStringList list;
                foreach(QString s, target->getPileNames()){
                    if (target->getPile(s).length()>0 && !s.startsWith("#")){
                        list.append(s);
                    }
                }

                QString choice = "ToBiGetRegion";
                if (!list.isEmpty())
                    choice = room->askForChoice(akari, objectName(), "ToBiGetRegion+TobiGetPile");
                if (choice == "TobiGetPile"){
                    QString choice2 = room->askForChoice(akari, objectName() + "1", list.join("+"));
                    QList<int> pile = target->getPile(choice2);
                    room->fillAG(pile, akari);
                    int id = room->askForAG(akari, pile, false, objectName());
                    if (id == -1)
                        return false;
                    room->obtainCard(akari, id);
                    room->clearAG(akari);
                }
                else{
                    int id =  room->askForCardChosen(akari, target, "hej", objectName());
                    if (id == -1)
                        return false;
                    room->obtainCard(akari, id);
                }
            }
        }
        return false;
    }
};

class Fukurouza : public TriggerSkill
{
public:
    Fukurouza() : TriggerSkill("Fukurouza")
    {
        events << EventPhaseEnd;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        if (triggerEvent == EventPhaseEnd) {

            QList<ServerPlayer *> akaris = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *akari, akaris)
                if (player->getPhase() == Player::Finish && (akari->hasFlag("TobiugachiUsed")||akari->hasFlag("TakamakuriUsed")))
                    skill_list.insert(akari, QStringList(objectName()));
            return skill_list;
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *akari = ask_who;

        if (akari->askForSkillInvoke(this, data)) {
           return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *akari = ask_who;
        /*bool broad = true;
        if (akari && akari->isAlive() && akari->hasFlag("TobiugachiUsed") && room->askForSkillInvoke(akari, objectName() + "Tobi", data)){
            room->broadcastSkillInvoke(objectName());
            broad = false;
            DamageStruct damage;
            damage.from = akari;
            damage.to = player;
            damage.reason = objectName();
            room->damage(damage);
        }

        if (akari && akari->isAlive() && akari->hasFlag("TakamakuriUsed") && room->askForSkillInvoke(akari, objectName() + "Taka", data)){
            if (broad)
                room->broadcastSkillInvoke(objectName());
            akari->drawCards(1);
            akari->setFlags("-TakamakuriUsed");
        }*/
        room->broadcastSkillInvoke(objectName(), akari);
        akari->drawCards(1);
        if (akari && akari->isAlive() && akari->hasFlag("TobiugachiUsed"))
            akari->setFlags("-TobiugachiUsed");
        if (akari && akari->isAlive() && akari->hasFlag("TakamakuriUsed"))
            akari->setFlags("-TakamakuriUsed");
        return false;
    }
};

class Kioku : public TriggerSkill
{
public:
    Kioku() : TriggerSkill("kioku")
    {
        frequency = Compulsory;
        events << EventPhaseStart << Death;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Death){
            DeathStruct death = data.value<DeathStruct>();
            if (player == death.who && player->getPile("memory").length()>0 && player->hasSkill(this)){
                ServerPlayer *dest = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName());
                room->broadcastSkillInvoke(objectName(), 8, player);
                room->doLightbox("kioku$", 2500);
                DummyCard *dummy = new DummyCard;
                dummy->deleteLater();
                foreach(int id, player->getPile("memory")){
                    dummy->addSubcard(id);
                }
                dest->obtainCard(dummy, true);
                room->setPlayerMark(dest, "kioku_dest", 1);
                if (player->isAlive()){
                    player->removeGeneral(player->inHeadSkills(this));
                }
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseStart && player->getPhase()==Player::Play && TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        return QStringList();
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->hasShownSkill(objectName()) || player->askForSkillInvoke(this, data)){
            room->broadcastSkillInvoke(objectName(), rand()%7+1, player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        player->drawCards(1);
        if (!player->isKongcheng()){
            int id = room->askForCardChosen(player, player, "h", objectName());
            player->addToPile("memory", id);
        }
        if (player->getPile("memory").length() >= 9){
            ServerPlayer *dest = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName());
            room->broadcastSkillInvoke(objectName(), 8, player);
            room->doLightbox("kioku$");
            DummyCard *dummy = new DummyCard;
            dummy->deleteLater();
            foreach(int id, player->getPile("memory")){
                dummy->addSubcard(id);
            }
            dest->obtainCard(dummy, true);
            room->setPlayerMark(dest, "kioku_dest", 1);
            if (player->isAlive()){
                player->removeGeneral(player->inHeadSkills(this));
            }
        }
        return false;
    }
};

class KiokuMax : public MaxCardsSkill
{
public:
    KiokuMax() : MaxCardsSkill("kiokumax")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->getMark("kioku_dest")>0){
            return 2;
        }
        if (target->hasFlag("xiangsui_dest")){
            return target->getMaxHp()-target->getHp();
        }
        return 0;
    }
};

XiangsuiCard::XiangsuiCard()
{
    will_throw = false;
}

bool XiangsuiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty();
}

void XiangsuiCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    room->obtainCard(targets.at(0), this);
    room->setPlayerFlag(targets.at(0), "xiangsui_dest");
    player->drawCards(1);
    if (!player->isKongcheng()){
        int id = room->askForCardChosen(player, player, "h", objectName());
        player->addToPile("memory", id);
    }
}

class Xiangsui : public OneCardViewAsSkill
{
public:
    Xiangsui() : OneCardViewAsSkill("xiangsui")
    {
        filter_pattern = ".|.|.|memory";
        expand_pile = "memory";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("XiangsuiCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        XiangsuiCard *vs = new XiangsuiCard();
        vs->addSubcard(originalCard);
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

QString ZhenghePattern = "pattern";
class Zhenghevs : public ZeroCardViewAsSkill
{
public:
    Zhenghevs() : ZeroCardViewAsSkill("zhenghe"){

    }

    bool isEnabledAtPlay(const Player *player) const
    {
        ZhenghePattern = "slash";
        Slash *slash = new Slash(Card::NoSuit,-1);
        return slash->isAvailable(player) && player->getMark("@zhenghe")>0;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (pattern=="slash" || pattern=="jink" || pattern.contains("nullification")){
            ZhenghePattern = pattern.split("+").first();
            return player->hasSkill("zhenghe")&&player->getMark("@zhenghe")>0;
        }
        return false;
    }

    virtual bool isEnabledAtNullification(const ServerPlayer *player) const
    {
        if (player->getMark("@zhenghe")>0){
            ZhenghePattern = "nullification";
            return player->hasSkill("zhenghe");
        }
        return false;
    }

    const Card *viewAs() const
    {
        QString pattern = ZhenghePattern;

        Card *card=Sanguosha->cloneCard(pattern,Card::NoSuit,-1);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};

class Zhenghe : public TriggerSkill
{
public:
    Zhenghe() : TriggerSkill("zhenghe")
    {
        view_as_skill = new Zhenghevs;
        events << GeneralShown << CardUsed << CardResponded;
    }

    virtual bool canPreshow() const
    {
        return true;
    }


    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == GeneralShown){
            if (TriggerSkill::triggerable(player) && player->inHeadSkills(this) == data.toBool() && player->hasShownSkill(objectName()) && !room->getTag(player->objectName()+"zhengheshow").toBool() && player->getMark("@zhenghe")<3){
                room->setTag(player->objectName()+"zhengheshow", QVariant(true));
                player->gainMark("@zhenghe");
            }
        }
        else if (event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getSkillName()==objectName() && !use.card->isKindOf("Slash")){
                use.from->loseMark("@zhenghe");
            }
        }
        else{
            const Card *card = data.value<CardResponseStruct>().m_card;
            if (card->getSkillName()==objectName()){
                player->loseMark("@zhenghe");
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList list;
        if (event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            QList<ServerPlayer *> alices = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *alice, alices)
                if (alice->isFriendWith(player) && alice->getMark("@zhenghe")<3 && use.card->isKindOf("EquipCard"))
                    list.insert(alice, QStringList(objectName()));
        }
        return list;
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *alice) const
    {
        if (alice->hasShownSkill(objectName())||alice->askForSkillInvoke(this,data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *alice) const
    {
        alice->gainMark("@zhenghe");
        return false;
    }
};

JianwuCard::JianwuCard()
{
}

bool JianwuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && Self->inMyAttackRange(to_select);
}

void JianwuCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    player->loseMark("@jianwu");
    player->loseMark("@zhenghe");
    QList<ServerPlayer *> plist;
    QList<ServerPlayer *> tlist = room->getAlivePlayers();
    room->sortByActionOrder(tlist);
    auto list = target->getFormation();
    foreach(auto p, tlist){
        foreach(auto q, list){
            if (q->objectName() == p->objectName()){
                plist << p;
                break;
            }
        }
    }
    room->doLightbox("se_jianwu$", 2000);
    foreach (auto p, plist) {
       room->setEmotion(p, "skills/leaf");
       room->loseHp(p);
    }
    auto victim = room->askForPlayerChosen(player, plist, "jianwu");
    victim->turnOver();
}

class Jianwu : public ZeroCardViewAsSkill
{
public:
    Jianwu() : ZeroCardViewAsSkill("jianwu"){
        relate_to_place = "head";
        limit_mark = "@jianwu";
        frequency = Limited;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@zhenghe")>0 && player->getMark("@jianwu")>0;
    }

    const Card *viewAs() const
    {
        JianwuCard *vs = new JianwuCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

KanhuCard::KanhuCard()
{
}

bool KanhuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->isWounded();
}

void KanhuCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    player->loseMark("@zhenghe");
    RecoverStruct recover;
    recover.recover = 1;
    recover.who = player;
    room->recover(target, recover, true);

}

class Kanhu : public ZeroCardViewAsSkill
{
public:
    Kanhu() : ZeroCardViewAsSkill("kanhu"){
        relate_to_place = "deputy";
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("KanhuCard") && player->getMark("@zhenghe")>0;
    }

    const Card *viewAs() const
    {
        KanhuCard *vs = new KanhuCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Zhuangjia : public TriggerSkill
{
public:
    Zhuangjia() : TriggerSkill("zhuangjia")
    {
        events << GeneralShown << EventPhaseStart;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {

    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (event == GeneralShown){
            if (TriggerSkill::triggerable(player) && player->inHeadSkills(this) == data.toBool() && player->hasShownSkill(objectName())){
                return QStringList(objectName());
            }
        }
        else if (event == EventPhaseStart){
            if (TriggerSkill::triggerable(player)&&player->getPhase()==Player::Discard){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }
    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->hasShownSkill(objectName())||player->askForSkillInvoke(this,data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == GeneralShown){
            QStringList list;
            if (!player->getWeapon()){
                list<<"weapon";
            }
            if (!player->getArmor()){
                list<<"armor";
            }
            if (!player->getOffensiveHorse()){
                list<<"offensive_horse";
            }
            if (!player->getDefensiveHorse()){
                list<<"defensive_horse";
            }
            if (!player->getTreasure()){
                list<<"treasure";
            }
            while (list.length()>0) {
                QString s;
                if (list.length()==1){
                     s = list.first();
                }
                else{
                    s = list.at(qrand()%list.length());
                }
                list.removeOne(s);
                QList<int> ids;
                foreach(int i, room->getDrawPile()){
                    const Card *card = Sanguosha->getCard(i);
                    if (card->getSubtype() == s){
                        ids << i;
                    }
                }
                if (ids.length()>0){
                    auto id = ids.at(qrand()%ids.length());
                    CardsMoveStruct move;
                    move.card_ids << id;
                    move.from = NULL;
                    move.to = player;
                    move.to_place = Player::PlaceEquip;
                    room->moveCardsAtomic(move, true);
                }
            }
        }
        else{

        }
        return false;
    }
};

class ZhuangjiaMaxCards : public MaxCardsSkill
{
public:
    ZhuangjiaMaxCards() : MaxCardsSkill("zhuangjiamax")
    {
    }

    virtual int getFixed(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->hasShownSkill("zhuangjia")){
            return  target->getEquips().length();
        }
        else
            return -1;
    }
};

class Wuzhuang : public TriggerSkill
{
public:
    Wuzhuang() : TriggerSkill("wuzhuang")
    {
        events << CardsMoveOneTime << EventPhaseStart << EventPhaseEnd;
    }

     virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            bool has = false;
            foreach(int id, move.card_ids){
                if (Sanguosha->getCard(id)->isKindOf("EquipCard"))
                    has = true;
            }

            if (player->getPhase()== Player::NotActive &&TriggerSkill::triggerable(player)&&move.from&&move.from->objectName()==player->objectName()&&move.from_places.contains(Player::PlaceEquip)){
                return QStringList(objectName());
            }
            if (!player->hasFlag("wuzhuang_used")&&player->getPhase()!=Player::NotActive&&TriggerSkill::triggerable(player)&&move.from&&move.from->objectName()==player->objectName()&&( move.from_places.contains(Player::PlaceEquip)||move.from_places.contains(Player::PlaceHand) && has)){
                if (move.to_place == Player::DiscardPile || move.to_place == Player::PlaceTable){
                    return QStringList(objectName());
                }
            }
        }
        else if (triggerEvent == EventPhaseStart){
            if (TriggerSkill::triggerable(player)&&player->getPhase()==Player::Discard){
                return QStringList(objectName());
            }
        }
        else if (triggerEvent == EventPhaseEnd){
            if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Discard && player->hasFlag("wuzhuang_max")){
                room->setPlayerFlag(player, "-wuzhuang_max");
                QString _type = "EquipCard|.|.|hand"; // Handcards only
                room->removePlayerCardLimitation(player, "discard", _type);
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==CardsMoveOneTime) {
           if (player->getPhase()!= Player::NotActive){
               room->setPlayerFlag(player, "wuzhuang_used");
           }
           return player->askForSkillInvoke(this, data);
        }
        else if (event == EventPhaseStart){
            return player->hasShownSkill(objectName()) || player->askForSkillInvoke(this, data);
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (triggerEvent == CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (player->getPhase()== Player::NotActive){
                if (room->askForUseCard(player, "EquipCard|.|.|hand", "@wuzhuang_use", -1, Card::MethodUse, true)){
                    room->askForUseCard(player, "EquipCard|.|.|hand", "@wuzhuang_use", -1, Card::MethodUse, true);
                }
            }
            else{
                QList<int> list;
                foreach(int id, move.card_ids){
                    if (Sanguosha->getCard(id)->isKindOf("EquipCard")){
                        list << id;
                    }
                }
                if (!list.isEmpty()){
                    room->fillAG(list, player);
                    int id = room->askForAG(player,list,false,objectName());
                    room->clearAG(player);
                    room->obtainCard(player, id);
                }
            }
        }
        else if(triggerEvent==EventPhaseStart){
            player->setFlags("wuzhuang_max");
            QString _type = "EquipCard|.|.|hand"; // Handcards only
            room->setPlayerCardLimitation(player, "discard", _type, false);
        }
        return false;
    }
};

class WuzhuangMaxCards : public MaxCardsSkill
{
public:
    WuzhuangMaxCards() : MaxCardsSkill("wuzhuangmax")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->hasShownSkill("wuzhuang")){
            int num = 0;
            foreach (const Card* card, target->getHandcards()){
                num += card->isKindOf("EquipCard") ? 1 : 0;
            }
            return  num;
        }
        else
            return 0;
    }
};

class Duoquyan : public TriggerSkill
{
public:
    Duoquyan() : TriggerSkill("duoquyan")
    {
        frequency = NotFrequent;
        events <<  EventPhaseStart;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (player != NULL && player->isAlive() && player->getPhase() == Player::Start )
        {
            QList<ServerPlayer *> yuus = room->findPlayersBySkillName(objectName());

            foreach (ServerPlayer *yuu, yuus)
            {
                if (!yuu->isKongcheng() && !player->isFriendWith(yuu))
                {
                    skill_list.insert(yuu, QStringList(objectName()));
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(ask_who->askForSkillInvoke(this, QVariant::fromValue(player)) && room->askForCard(ask_who,"BasicCard","@duoquyan:"+ player->objectName(),QVariant::fromValue(player), objectName())){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        room->broadcastSkillInvoke(objectName(), ask_who);
        QString choice = room->askForChoice(player, objectName(), "duoqu_move+duoqu_command");
        if(choice == "duoqu_move"){
           if (!player->isNude()|| player->getJudgingArea().length()>0){
               int id = room->askForCardChosen(ask_who, player, "hej", objectName());
               const Card *card = Sanguosha->getCard(id);
               Player::Place place = room->getCardPlace(id);

               int equip_index = -1;
               if (place == Player::PlaceEquip) {
                   const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
                   equip_index = static_cast<int>(equip->location());
               }
               bool can = false;
               if (equip_index != -1) {
                   if (ask_who->getEquip(equip_index) == NULL)
                       can = true;
               } else if (place == Player::PlaceDelayedTrick) {
                   if (!ask_who->isProhibited(ask_who, card) && !ask_who->containsTrick(card->objectName()))
                       can = true;
               }
               else if (place == Player::PlaceHand){
                   can = true;
               }
               if (can){
                   room->moveCardTo(card, player, ask_who, place,
                       CardMoveReason(CardMoveReason::S_REASON_TRANSFER,
                       ask_who->objectName(), "duoquyan", QString()));

                   if (place == Player::PlaceDelayedTrick) {
                       CardUseStruct use(card, NULL, ask_who);
                       QVariant _data = QVariant::fromValue(use);
                       room->getThread()->trigger(TargetConfirming, room, ask_who, _data);
                       CardUseStruct new_use = _data.value<CardUseStruct>();
                       if (new_use.to.isEmpty())
                           card->onNullified(ask_who);

                       foreach(ServerPlayer *p, room->getAllPlayers())
                           room->getThread()->trigger(TargetConfirmed, room, p, _data);
                   }
               }
           }
        }
        else{
            int index = ask_who->startCommand(objectName());
            ServerPlayer *dest = NULL;
            if (index == 0) {
                dest = room->askForPlayerChosen(ask_who, room->getAlivePlayers(), "command_duoquyan", "@command-damage");
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), dest->objectName());
            }
            QList<ServerPlayer *> list = room->getAlivePlayers();
            room->sortByActionOrder(list);
            int x = 0;
            foreach (ServerPlayer *p, list) {
                if(!p->isFriendWith(player))
                    continue;
                if (!p->doCommand(objectName(),index,ask_who,dest)){
                    x = x+1;
                }
            }
            if (x>0)
                ask_who->drawCards(x);
            int max = 0;
            foreach (auto p, room->getOtherPlayers(ask_who))
            {
                max = qMax(max, p->getHandcardNum());
            }
            if (ask_who->getHandcardNum()>max){
                room->loseHp(ask_who);
            }
            if (x>0)
                room->loseHp(player);
        }
        return false;
    }
};

//magic
class Zhouxue : public TriggerSkill
{
public:
    Zhouxue() : TriggerSkill("zhouxue")
    {
        frequency = NotFrequent;
        events << Damage << Damaged;
    }
    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && (!room->getCurrent() || !room->getCurrent()->hasFlag(player->objectName() +  "zhouxue_invalid")))
            return QStringList(objectName());
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

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *kuriyama, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct judge;
        judge.pattern = ".|red";
        judge.good = true;
        judge.reason = "zhouxue";
        judge.who = kuriyama;

        room->judge(judge);
        if (judge.card->isRed()){
            QString choice = room->askForChoice(kuriyama, objectName(), "zhouxue_yes+cancel", data);
            if (choice == "zhouxue_yes")
                kuriyama->addToPile("zhouxue_blood", judge.card, true);
        }
        else{
            kuriyama->drawCards(1);
            if (room->getCurrent()){
               room->setPlayerFlag(room->getCurrent(), kuriyama->objectName() + "zhouxue_invalid");
            }
        }
        return false;
    }
};

QString XuerenPattern = "pattern";
class Xueren : public OneCardViewAsSkill
{
public:
    Xueren() : OneCardViewAsSkill("xueren")
    {
        filter_pattern = ".|.|.|zhouxue_blood";
        expand_pile = "zhouxue_blood";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        XuerenPattern = "slash";
        Slash *slash = new Slash(Card::NoSuit,-1);
        return slash->isAvailable(player)&&!player->getPile("zhouxue_blood").isEmpty() && !player->hasFlag("xueren_used");
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (pattern=="slash" || pattern=="jink"){
            XuerenPattern = pattern;
            return player->hasSkill("xueren") && !player->hasFlag("xueren_used");
        }
        return false;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        QString pattern = XuerenPattern;
        Card *card=Sanguosha->cloneCard(pattern,originalCard->getSuit(),originalCard->getNumber());
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};

class XuerenTrigger : public TriggerSkill
{
public:
    XuerenTrigger() : TriggerSkill("#xueren")
    {
        frequency = NotFrequent;
        events << CardResponded << CardUsed << EventPhaseEnd;
        global=true;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardResponded){
             const Card *card = data.value<CardResponseStruct>().m_card;
             if (card->getSkillName()=="xueren"){
                 if (room->getCurrent())
                     room->setPlayerFlag(player, "xueren_used");
             }
        }
        else if (triggerEvent == CardUsed){
             const Card *card = data.value<CardUseStruct>().card;
             if (card->getSkillName()=="xueren"){
                 if (room->getCurrent())
                     room->setPlayerFlag(player, "xueren_used");
                 if (card->isKindOf("Slash"))
                     room->addPlayerHistory(player, card->getClassName(), -1);
             }
        }
        else{
            if (player->getPhase()==Player::Finish){
                foreach(auto p, room->getAlivePlayers()){
                    room->setPlayerFlag(p, "-xueren_used");
                }
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {

        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class XuerenTargetMod : public TargetModSkill
{
public:
    XuerenTargetMod() : TargetModSkill("#xueren-target")
    {
        pattern = "Slash";
    }

    virtual int getDistanceLimit(const Player *from, const Card *card) const
    {

        if (card->getSkillName()=="xueren")
            return 1000;
        else
            return 0;
    }
};

class Caoxue : public TriggerSkill
{
public:
    Caoxue() : TriggerSkill("caoxue")
    {
        frequency = NotFrequent;
        events << DamageCaused << EventPhaseStart;
        relate_to_place = "deputy";
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
            if (triggerEvent == DamageCaused){
                 DamageStruct damage = data.value<DamageStruct>();
                 if (player->hasFlag("caoxue_yes") && !player->hasFlag(damage.to->objectName()+"caoxue_used") && (damage.to->getJudgingArea().length()>0||!damage.to->isNude()))
                     return QStringList(objectName());
            }
            else{
                if (player->getPhase()==Player::Start){
                    if (TriggerSkill::triggerable(player) && player->getPile("zhouxue_blood").length()>0)
                        room->setPlayerFlag(player, "caoxue_yes");
                }
            }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(damage.to))) {
            room->broadcastSkillInvoke(objectName(), player);
            room->setPlayerFlag(player, damage.to->objectName()+"caoxue_used");
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        int id = room->askForCardChosen(player, damage.to, "hej", objectName());
        room->obtainCard(player, id, false);
        return false;
    }
};

class Huanzhuang : public TriggerSkill
{
public:
    Huanzhuang() : TriggerSkill("huanzhuang")
    {
        frequency = NotFrequent;
        events << CardUsed << CardFinished;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardUsed){
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card->isKindOf("Slash") && player->hasFlag("huanzhuang_get")){
                 room->addPlayerHistory(player, use.card->getClassName(), -1);
                 room->setPlayerFlag(player, "-huanzhuang_get");
             }
        }
        return;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
            if (triggerEvent == CardUsed){
                 CardUseStruct use = data.value<CardUseStruct>();
                 if (TriggerSkill::triggerable(player) && ((use.card->isKindOf("Weapon")&& player->getWeapon()!= NULL) || (use.card->isKindOf("Armor")&& player->getArmor()!= NULL)) && !room->getCurrent()->hasFlag(player->objectName()+"huanzhuang1used"))
                     return QStringList(objectName());
            }
            else{
                CardUseStruct use = data.value<CardUseStruct>();
                if (TriggerSkill::triggerable(player) && (use.card->isKindOf("Slash") || use.card->isKindOf("Weapon") || use.card->isKindOf("Armor")) && !room->getCurrent()->hasFlag(player->objectName()+"huanzhuang2used")){
                    return QStringList(objectName());
                }
            }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            if (event == CardUsed)
                room->setPlayerFlag(room->getCurrent(), player->objectName()+"huanzhuang1used");
            if (event == CardFinished)
                room->setPlayerFlag(room->getCurrent(), player->objectName()+"huanzhuang2used");
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Weapon")&& player->getWeapon()!= NULL){
                room->obtainCard(player, player->getWeapon());
            }
            if (use.card->isKindOf("Armor")&& player->getArmor() != NULL){
                room->obtainCard(player, player->getArmor());
            }
        }
        else{
          CardUseStruct use = data.value<CardUseStruct>();
          QList<int> list;
          if (use.card->isKindOf("Slash")){
              foreach(auto id, room->getDrawPile()){
                  if (Sanguosha->getCard(id)->isKindOf("Weapon")|| Sanguosha->getCard(id)->isKindOf("Armor")){
                      list << id;
                  }
              }
              foreach(auto id, room->getDiscardPile()){
                  if (Sanguosha->getCard(id)->isKindOf("Weapon")|| Sanguosha->getCard(id)->isKindOf("Armor")){
                      list << id;
                  }
              }
          }
          else{
              foreach(auto id, room->getDrawPile()){
                  if (Sanguosha->getCard(id)->isKindOf("Slash")){
                      list << id;
                  }
              }
              foreach(auto id, room->getDiscardPile()){
                  if (Sanguosha->getCard(id)->isKindOf("Slash")){
                      list << id;
                  }
              }
          }
          if (!list.isEmpty()){
              int id = list.at(rand()%list.length());
              room->obtainCard(player, id);
              const Card *card = Sanguosha->getCard(id);
              if (card->isKindOf("Slash") && player->getPhase()!=Player::NotActive){
                  room->setPlayerFlag(player, "huanzhuang_get");
              }
          }
        }
        return false;
    }
};

class HuanzhuangTargetMod : public TargetModSkill
{
public:
    HuanzhuangTargetMod() : TargetModSkill("#huanzhuang-target")
    {
        pattern = "Slash";
    }

    virtual int getDistanceLimit(const Player *from, const Card *card) const
    {
        if (from->hasFlag("huanzhuang_get"))
            return 1000;
        else
            return 0;
    }
};

class Jingming : public TriggerSkill
{
public:
    Jingming() : TriggerSkill("jingming")
    {
        events << EventPhaseStart << EventPhaseEnd;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseEnd && player->getPhase()==Player::Finish){
            QList<ServerPlayer *> mikus;
            foreach(auto miku, mikus){
                QString choice;
                room->broadcastSkillInvoke(objectName(),2);
                if (player->isWounded()){
                    choice = room->askForChoice(miku, objectName(), "recover+eachdraw+youdiscard");
                }
                else{
                    choice = room->askForChoice(miku, objectName(), "eachdraw+youdiscard");
                }
                foreach(auto p, room->getAlivePlayers()){
                    if (player->getMark(p->objectName()+"noslash_jm")>0){
                        room->setPlayerMark(player, p->objectName()+"noslash_jm", 0);
                        mikus << p;
                    }
                }
                if (choice == "recover"){
                    RecoverStruct rcv = RecoverStruct();
                    rcv.recover = 1;
                    rcv.who = miku;
                    room->recover(player,rcv);
                }
                else if (choice == "eachdraw"){
                     player->drawCards(2);
                }
                else{
                    room->askForDiscard(miku, objectName(), 1, 1, false, true);
                }
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == EventPhaseStart){
            if (player->getPhase()==Player::Start){
                QList<ServerPlayer *> mikus = room->findPlayersBySkillName(objectName());
                foreach(auto miku, mikus){
                    if (miku != player && !miku->isKongcheng() && miku->canDiscard(miku, "h")){
                        skill_list.insert(miku, QStringList(objectName()));
                    }
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(event == EventPhaseStart && ask_who->askForSkillInvoke(this, QVariant::fromValue(player))){
            QString prompt = QString("@jmdiscard:%1:%2").arg(ask_who->objectName()).arg(player->objectName());
            const Card *card = room->askForCard(ask_who,".",prompt,QVariant::fromValue(player),objectName());
            if (card){
               return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        room->broadcastSkillInvoke(objectName(),1);
        room->setPlayerMark(player,ask_who->objectName()+"noslash_jm",1);
        //room->setPlayerCardLimitation(player, "use", "Slash", true);
        room->setPlayerFlag(player, "jingming_target");
        return false;
    }
};

class jingmingTargetMod : public TargetModSkill
{
public:
    jingmingTargetMod() : TargetModSkill("#jingming-target")
    {
        pattern = "Slash";
    }

    virtual int getResidueNum(const Player *from, const Card *card) const
    {
        if (from->hasFlag("jingming_target")){
            return -1;
        }
        return 0;
    }

};

YingxianCard::YingxianCard()
{
    target_fixed = true;
    will_throw = false;
}

void YingxianCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
     room->showCard(source, this->getEffectiveId());
     int number = this->getNumber();
     int x = qFloor(pow(number, 0.5));
     if (x<=0){
         return;
     }
     QList<int> list = room->getNCards(x);
     room->fillAG(list, source);
     int id = room->askForAG(source, list, false, "yingxian");
     const Card *card = Sanguosha->getCard(id);
     room->clearAG(source);
     QList<int> list2;
     foreach(int i, list){
         const Card *c = Sanguosha->getCard(i);
         if (c->getTypeId() == card->getTypeId()){
             list2<<i;
         }
     }
     CardsMoveStruct move;
     move.card_ids = list2;
     move.from = NULL;
     move.to = source;
     move.to_place = Player::PlaceHand;
     room->moveCardsAtomic(move, false);
     QList<ServerPlayer*> players;
     foreach(auto p, room->getAlivePlayers()){
         if (p->isFriendWith(source)){
             players<<p;
         }
     }
     room->askForYiji(source, list2, "yingxian", false, false, true, -1, players, CardMoveReason(), "@yingxian");
}

class Yingxian : public OneCardViewAsSkill
{
public:
    Yingxian() : OneCardViewAsSkill("yingxian"){
    }

    bool viewFilter(const Card *card) const
    {
        return !card->isEquipped();
    }

    const Card *viewAs(const Card *originalCard) const
    {
        YingxianCard *vs = new YingxianCard();
        vs->addSubcard(originalCard->getId());
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YingxianCard");
    }

};

class Shiting : public TriggerSkill
{
public:
    Shiting() : TriggerSkill("shiting")
    {
        events << TurnStart << TargetConfirmed << CardFinished;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==TurnStart){
            if(player->getMark("shiting_used")>0 && !player->hasFlag("Point_ExtraTurn")){
                room->setPlayerMark(player, "shiting_used", 0);
            }
        }
        return;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == TargetConfirmed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.from && !use.from->isFriendWith(player) && (use.card->isKindOf("Slash")||use.card->isNDTrick()) && use.to.length()==1 && use.to.at(0)->isFriendWith(player) && player->getMark("shiting_used")==0 && player->getPhase()==Player::NotActive){
                return QStringList(objectName());
            }
        }
        if (event==CardFinished){
           CardUseStruct use = data.value<CardUseStruct>();
           if (TriggerSkill::triggerable(player) && player->getMark("shiting_used")>0 && use.card->getTypeId() != Card::TypeSkill && use.card->getSubcards().length()>0 && player->getPhase()!=Player::NotActive && !player->hasFlag("shitingb_used")){
               return QStringList(objectName());
           }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event == TargetConfirmed && player->askForSkillInvoke(this, data)){
            //room->setPlayerFlag(player,"shiting_extraturn");
            room->setPlayerMark(player, "shiting_used", 1);
            return true;
        }
        if (event == CardFinished && player->askForSkillInvoke(this, data)){
            room->setPlayerFlag(player, "shitingb_used");
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event == TargetConfirmed){
            room->loseHp(player);
            player->gainAnInstantExtraTurn();
        }
        else{
            CardUseStruct use = data.value<CardUseStruct>();
            CardsMoveStruct move;
            move.card_ids = use.card->getSubcards();
            move.to_place = Player::DrawPileBottom;
            move.reason.m_reason = CardMoveReason::S_REASON_PUT;
            room->moveCardsAtomic(move, false);
        }
        return false;
    }
};

QiehuoCard::QiehuoCard()
{
}

bool QiehuoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && to_select->getWeapon();
}

void QiehuoCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (target->getWeapon()){
        room->obtainCard(player, target->getWeapon());
    }
}

class Qiehuo : public OneCardViewAsSkill
{
public:
    Qiehuo() : OneCardViewAsSkill("qiehuo"){

    }

    bool viewFilter(const Card *card) const
    {
        return true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QiehuoCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        QiehuoCard *vs = new QiehuoCard();
        vs->addSubcard(originalCard);
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

SujiuCard::SujiuCard()
{
    target_fixed = true;
    will_throw = false;
}

void SujiuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
     room->showAllCards(source);
     int x = 0;
     foreach(auto id, source->handCards()){
         if (Sanguosha->getCard(id)->isKindOf("Weapon")){
             x = x+1;
         }
     }

     QList<int> list;
     for(int i = 1; i<= x ; i++){
         int n = room->getDrawPile().length();
        if (n-i >=0 ){
            list << room->getDrawPile().at(n-i);
        }
     }
     if (x>0 && list.length()<x){
         source->drawCards(x);
         return;
     }
     if (x==0){
         return;
     }

     CardsMoveStruct move;
     move.card_ids = list;
     move.from = NULL;
     move.to = source;
     move.to_place = Player::PlaceHand;
     room->moveCardsAtomic(move, false);
}

class Sujiu : public ZeroCardViewAsSkill
{
public:
    Sujiu() : ZeroCardViewAsSkill("sujiu"){

    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("SujiuCard") && !player->isKongcheng();
    }

    const Card *viewAs() const
    {
        SujiuCard *vs = new SujiuCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

GuandaiCard::GuandaiCard()
{
    target_fixed = true;
    will_throw = false;
}

void GuandaiCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    int n = this->getSubcards().length();
    room->obtainCard(player, this);
    room->askForDiscard(player, "guandai", n, n, false, true, QString(), true);
}

class Guandaivs : public ViewAsSkill
{
public:
    Guandaivs() : ViewAsSkill("guandai"){
        expand_pile = "duan";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (Self->getHandcards().contains(to_select)||Self->getEquips().contains(to_select))
            return false;
        return true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "@@guandai";
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        GuandaiCard *vs = new GuandaiCard();
        vs->addSubcards(cards);
        vs->setSkillName(objectName());
        return vs;
    }
};

class Guandai : public TriggerSkill
{
public:
    Guandai() : TriggerSkill("guandai")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << CardsMoveOneTime;
        view_as_skill = new Guandaivs;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==CardsMoveOneTime){
            auto move = data.value<CardsMoveOneTimeStruct>();
            if (move.reason.m_skillName == objectName() && player->objectName() == move.reason.m_playerId && player->getPhase()!=Player::NotActive){
                foreach(int i, move.card_ids){
                    Card *c1 = Sanguosha->getCard(i);
                    foreach(int j, move.card_ids){
                        Card *c2 = Sanguosha->getCard(j);
                        if (c1->getTypeId()!=c2->getTypeId()){
                            room->setPlayerFlag(player, "guandai_draw");
                        }
                    }
                }
            }
        }
        if (event== EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish && player->hasFlag("guandai_draw")){
            if (player->askForSkillInvoke("guandai_draw")){
                player->drawCards(1);
            }
        }
        if (event== EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase() == Player::Play && !player->getPile("duan").isEmpty())
            room->askForUseCard(player, "@@guandai", "@guandai");
    }


    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event== EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase() == Player::Start && player->getPile("duan").isEmpty())
            return QStringList(objectName());


        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event== EventPhaseStart && player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        auto list = room->getNCards(4);
        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.card_str = IntList2StringList(list).join("+");
        room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

        foreach (int id, list) {
            room->moveCardTo(Sanguosha->getCard(id), player, Player::PlaceTable, CardMoveReason(CardMoveReason::S_REASON_TURNOVER, player->objectName(), "caibao", ""), false);
        }

        room->fillAG(list, player);
        int id = room->askForAG(player, list, false, objectName());
        room->clearAG(player);
        foreach(int i, list){
            if (Sanguosha->getCard(i)->getColor()==Sanguosha->getCard(id)->getColor()){
                player->addToPile("duan", i);
                list.removeOne(i);
            }
        }

        if (!list.isEmpty()) {
            QListIterator<int> i(list);
            i.toBack();
            while (i.hasPrevious())
                room->getDrawPile().prepend(i.previous());
        }
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_PILE, QVariant(room->getDrawPile().length()));
        return false;
    }
};

class Qiaoshou : public TriggerSkill
{
public:
    Qiaoshou() : TriggerSkill("qiaoshou")
    {
        frequency = NotFrequent;
        events <<  DamageInflicted;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        auto damage = data.value<DamageStruct>();
        if (player != NULL && player->isAlive())
        {
            QList<ServerPlayer *> sps = room->findPlayersBySkillName(objectName());

            foreach (ServerPlayer *sp, sps)
            {
                if ((!damage.from||sp!=damage.from) && sp->inMyAttackRange(damage.to) && (!sp->isNude() || !sp->getPile("duan").isEmpty()) && sp->getPhase() == Player::NotActive)
                {
                    skill_list.insert(sp, QStringList(objectName()));
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(ask_who->askForSkillInvoke(this, QVariant::fromValue(player)) /*&& room->askForDiscard(ask_who,objectName(),1,1,true,true)*/){
            QList<int> list = ask_who->getPile("duan");
            foreach(auto c, ask_who->getCards("he")){
                list << c->getEffectiveId();
            }
            room->fillAG(list, ask_who);
            int id = room->askForAG(ask_who, list, true, objectName());
            room->clearAG(ask_who);
            if (id > -1){
                room->throwCard(id, ask_who, ask_who);
                room->broadcastSkillInvoke(objectName(), ask_who);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        auto slash = Sanguosha->cloneCard("fire_slash");
        auto use = CardUseStruct();
        use.from = ask_who;
        use.to << player;
        use.card = slash;
        room->useCard(use);
        return false;
    }
};

//game
PenglaiCard::PenglaiCard()
{
}

bool PenglaiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->isKongcheng() && to_select!=Self;
}

void PenglaiCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (!target->isKongcheng()){
        room->askForDiscard(target, "penglai", 1, 1);
        if (target->isWounded()){
            RecoverStruct recover;
            recover.recover = 1;
            recover.who = player;
            room->recover(target, recover, true);
        }
    }
}

class Penglai : public ZeroCardViewAsSkill
{
public:
    Penglai() : ZeroCardViewAsSkill("penglai"){

    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("PenglaiCard");
    }

    const Card *viewAs() const
    {
        PenglaiCard *vs = new PenglaiCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Jiansivs : public ZeroCardViewAsSkill
{
public:
    Jiansivs() : ZeroCardViewAsSkill("jiansi"){

    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "@@jiansi";
    }

    const Card *viewAs() const
    {
        QString pattern = Self->property("jiansi_card").toString();
        int id = Self->property("jiansi_number").toInt();
        if (pattern == "")
            return NULL;
        //Card *vs = Sanguosha->cloneCard(pattern);
        Card *vs = Sanguosha->getCard(id);
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        //vs->addSubcard(id);
        return vs;
    }
};

class Jiansi : public TriggerSkill
{
public:
    Jiansi() : TriggerSkill("jiansi")
    {
        view_as_skill = new Jiansivs;
        events << CardUsed << CardResponded << EventPhaseEnd << EventPhaseChanging;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
         if (event == CardUsed){
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card->getTypeId() != Card::TypeSkill && room->getCurrent()){
                 room->setPlayerMark(use.from, "jiansi_times", 1);
             }
         }
         if (event == CardResponded){
             CardResponseStruct r = data.value<CardResponseStruct>();
             if (r.m_card && r.m_card->getTypeId() != Card::TypeSkill && room->getCurrent()){
                 room->setPlayerMark(player, "jiansi_times", 1);
             }
         }
         if (event == EventPhaseChanging){
             PhaseChangeStruct change = data.value<PhaseChangeStruct>();
             if (change.to == Player::NotActive){
                 foreach(auto p , room->getAlivePlayers()){
                     room->setPlayerMark(p, "jiansi_times", 0);
                 }
             }
         }
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == EventPhaseEnd){
            if (player->getPhase()==Player::Finish){
                QList<ServerPlayer *> eirins = room->findPlayersBySkillName(objectName());
                foreach(ServerPlayer *eirin, eirins)
                    if (eirin->getMark("jiansi_times")>0)
                        skill_list.insert(eirin, QStringList(objectName()));
            }
        }

        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if(ask_who->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *eirin) const
    {
        QList<int> list;
        QList<int> disabled_ids;
        int x=2;
        QList<int> &drawPile = room->getDrawPile();
        int l=drawPile.length();
        /*for (int i=1; i<= x; i++) {
          if (l-i>=0) {
            list << drawPile.at(l-i);
            const Card *card = Sanguosha->getCard(drawPile.at(l-i));
            if (!card->isAvailable(eirin)) {
                disabled_ids << drawPile.at(l-i);
            }
          }
        }*/
        if (l > 0) {
          list << drawPile.at(0);
          const Card *card = Sanguosha->getCard(drawPile.at(0));
          if (!card->isAvailable(eirin)) {
              disabled_ids << drawPile.at(0);
          }
        }
        if (l > 1) {
          list << drawPile.at(l-1);
          const Card *card = Sanguosha->getCard(drawPile.at(l-1));
          if (!card->isAvailable(eirin)) {
              disabled_ids << drawPile.at(l-1);
          }
        }
        if (!list.isEmpty()){
             room->fillAG(list, eirin ,disabled_ids);
             int id = room->askForAG(eirin,list,true,"jiansi");
             room->clearAG(eirin);
             if (id > -1){
                 const Card *card = Sanguosha->getCard(id);
                 if (card->isKindOf("EquipCard")) {
                     CardUseStruct use;
                     use.from = eirin;
                     use.to << eirin;
                     use.card =card;
                     room->useCard(use);
                     CardsMoveStruct move = CardsMoveStruct();
                     list.removeOne(id);
                     move.card_ids = list;
                     move.to = eirin;
                     move.to_place = Player::PlaceTable;
                     move.reason = CardMoveReason(CardMoveReason::S_REASON_TURNOVER, eirin->objectName(), objectName(), NULL);
                     room->moveCardsAtomic(move, true);
                     CardMoveReason reason = CardMoveReason();
                     reason.m_reason = CardMoveReason::S_REASON_THROW;
                     reason.m_playerId = eirin->objectName();
                     room->moveCardTo(Sanguosha->getCard(list.at(0)), NULL, Player::DiscardPile, reason, true);
                 }
                 else{
                     room->setPlayerProperty(eirin, "jiansi_card", QVariant(card->objectName()));
                     room->setPlayerProperty(eirin, "jiansi_number", QVariant(id));
                     if (room->askForUseCard(eirin, "@@jiansi", "@jiansi")){
                         CardsMoveStruct move = CardsMoveStruct();
                         list.removeOne(id);
                         move.card_ids = list;
                         move.to = eirin;
                         move.to_place = Player::PlaceTable;
                         move.reason = CardMoveReason(CardMoveReason::S_REASON_TURNOVER, eirin->objectName(), objectName(), NULL);
                         room->moveCardsAtomic(move, true);
                         CardMoveReason reason = CardMoveReason();
                         reason.m_reason = CardMoveReason::S_REASON_THROW;
                         reason.m_playerId = eirin->objectName();
                         room->moveCardTo(Sanguosha->getCard(list.at(0)), NULL, Player::DiscardPile, reason, true);
                     }
                 }
             }
        }
        return false;
    }
};

TaxianCard::TaxianCard()
{
}
bool TaxianCard::targetFilter(const QList<const Player *> &, const Player *to_select, const Player *Self) const
{
    return to_select != Self && Self->inMyAttackRange(to_select) && Self->canSlash(to_select);
}

bool TaxianCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() > 0;
}

void TaxianCard::use(Room *room, ServerPlayer *ayanami, QList<ServerPlayer *> &targets) const
{
    ThunderSlash *slash = new ThunderSlash(Card::NoSuit, 0);
    if (targets.length() >= 3){
        slash->setSkillName("taxian");
    }

    room->useCard(CardUseStruct(slash, ayanami, targets), false);
    foreach(ServerPlayer *p , targets){
        if (p->inMyAttackRange(ayanami)){
            Slash *slash = new Slash(Card::NoSuit, 0);
            slash->setSkillName("taxian");
            room->useCard(CardUseStruct(slash, p, ayanami));
        }
    }
}

class Taxian : public ZeroCardViewAsSkill
{
public:
    Taxian() : ZeroCardViewAsSkill("taxian")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TaxianCard");
    }

    const Card *viewAs() const
    {
        TaxianCard *vs = new TaxianCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Guishen : public TriggerSkill
{
public:
    Guishen() : TriggerSkill("guishen")
    {
        frequency = NotFrequent;
        events << EventPhaseEnd << Damage << EventPhaseChanging;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {

        if(triggerEvent ==EventPhaseChanging && data.value<PhaseChangeStruct>().to == Player::NotActive){
            player->loseAllMarks("@Guishen");
        }
        return;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (triggerEvent == Damage){
            DamageStruct da = data.value<DamageStruct>();
            if (da.from && da.from->hasSkill(objectName()) && da.from->getPhase() != Player::NotActive){
                return QStringList(objectName());
                //da.from->gainMark("@Guishen", 1);

            }
        }
            if (triggerEvent == EventPhaseEnd){
                 if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish && player->getMark("@Guishen") >= player->getHp())
                     return QStringList(objectName());
            }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == EventPhaseEnd && player->askForSkillInvoke(this, data)) {
            return true;
        }
        if (event == Damage && (player->hasShownSkill(objectName())|| player->askForSkillInvoke(this, data) ))
            return true;
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == Damage){
            player->gainMark("@Guishen", 1);
        }
        else{
            RecoverStruct recover;
            recover.recover = player->getMark("@Guishen") - player->getHp();
            recover.who = player;
            if (recover.recover>0)
                room->recover(player, recover, true);
            if (player->getMaxHp() - player->getHandcardNum()>0){
                player->drawCards(player->getMaxHp() - player->getHandcardNum());
            }
        }

        return false;
    }
};

class Zhongquan : public TriggerSkill
{
public:
    Zhongquan() : TriggerSkill("zhongquan")
    {
        frequency = Limited;
        events << EventPhaseStart << DamageInflicted;
        limit_mark = "@inu_from";
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        return;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseStart && TriggerSkill::triggerable(player) && player->getMark("@inu_from")>0 && player->getPhase()==Player::Start){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == EventPhaseStart && player->askForSkillInvoke(this, data)) {
            ServerPlayer *target=room->askForPlayerChosen(player,room->getOtherPlayers(player),objectName(),QString(),true,true);
            if (target){
                player->loseMark("@inu_from");
                player->tag["zhongquan_target"] = QVariant::fromValue(target);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag["zhongquan_target"].value<ServerPlayer *>();
        if (target){
            target->gainMark("@inu_to");
        }
        return false;
    }
};

class ZhongquanTrigger : public TriggerSkill
{
public:
    ZhongquanTrigger() : TriggerSkill("#zhongquan")
    {
        frequency = NotFrequent;
        events << DamageForseen;
        global=true;
    }

    int getPriority(TriggerEvent) const
    {
        return 2;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (player == damage.to && damage.to->getMark("@inu_to")>0){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        auto sp = room->findPlayerBySkillName("zhongquan");
        if (sp){
            damage.to = sp;
            sp->drawCards(1);
            data.setValue(damage);
        }
        return false;
    }
};

class Dstp : public TriggerSkill
{
public:
    Dstp() : TriggerSkill("dstp")
    {
        events << DamageInflicted;
        frequency = Compulsory;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        return;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (TriggerSkill::triggerable(player) && damage.damage>1){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (player->hasShownSkill(this)||player->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        room->sendCompulsoryTriggerLog(player, objectName());
        DamageStruct damage = data.value<DamageStruct>();
        damage.damage = 1;
        data.setValue(damage);
        return false;
    }
};

class Guihuan : public TriggerSkill
{
public:
    Guihuan() : TriggerSkill("guihuan")
    {
        events << EventPhaseStart << EventPhaseEnd;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == EventPhaseStart){
            if (player->getPhase()==Player::Start && player->getMark("@inu_to")>0){
                auto sp = room->findPlayerBySkillName(objectName());
                if (sp){
                    QString choice = room->askForChoice(player, objectName(), "guihuan_hp+guihuan_card+cancel");
                    if (choice=="guihuan_hp"){
                        room->setPlayerProperty(player, "hp", QVariant(sp->getHp()));
                    }
                    if (choice=="guihuan_card"){
                        if (player->getHandcardNum()<sp->getHandcardNum()){
                            player->drawCards(qMin(sp->getHandcardNum()-player->getHandcardNum(),5));
                        }
                        else if (player->getHandcardNum()>sp->getHandcardNum()){
                            room->askForDiscard(player, objectName(), player->getHandcardNum()-sp->getHandcardNum(),player->getHandcardNum()-sp->getHandcardNum());
                        }
                    }
                }
            }
        }
        return;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        return false;
    }
};

class Shuangreny : public TriggerSkill
{
public:
    Shuangreny() : TriggerSkill("shuangreny")
    {
        frequency = NotFrequent;
        events << CardUsed;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (triggerEvent==CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")&& player == use.from) {
                QList<ServerPlayer*> targets;
                foreach (ServerPlayer *to, room->getOtherPlayers(player)) {
                   if (!use.to.contains(to)){
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
               if (!use.to.contains(to)){
                   targets << to;
               }
            }
            ServerPlayer *target=room->askForPlayerChosen(player,targets,objectName(),QString(),true,true);
            if (target){
                player->tag["shuangren_target"] = QVariant::fromValue(target);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag["shuangren_target"].value<ServerPlayer *>();
        if (target){
            room->broadcastSkillInvoke(objectName(),player);
            CardUseStruct use = data.value<CardUseStruct>();
            use.to.append(target);
            data.setValue(use);
        }
        return false;
    }
};

class Zhanwang : public TriggerSkill
{
public:
    Zhanwang() : TriggerSkill("zhanwang")
    {
        events << DamageCaused;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        DamageStruct damage = data.value<DamageStruct>();
        if (!damage.to || !damage.to->hasShownOneGeneral() || damage.to == player) return QStringList();
        if (!damage.card || !(damage.card->isKindOf("Slash"))) return QStringList();
        if (damage.to->getActualGeneral2Name().contains("sujiang")) return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        QStringList choices;
        if (damage.to->hasEquip())
            choices << "discard";
        choices << "remove";
        QString choice = room->askForChoice(damage.to, objectName(), choices.join("+"));
        if (choice == "discard") {
            if (!room->askForCard(damage.to, ".|.|.|equipped!", "@zhanwang-discard:" + player->objectName())) {
                QList<const Card *> equips_candiscard;
                foreach (const Card *e, damage.to->getEquips()) {
                    if (damage.to->canDiscard(damage.to, e->getEffectiveId()))
                        equips_candiscard << e;
                }

                const Card *rand_c = equips_candiscard.at(qrand() % equips_candiscard.length());
                room->throwCard(rand_c, damage.to);
            }
        } else {
            damage.to->removeGeneral(false);
        }
    }
};

class Youmurecord : public TriggerSkill
{
public:
    Youmurecord() : TriggerSkill("#youmurecord")
    {
        frequency = NotFrequent;
        events << PreCardUsed;
        global=true;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        auto use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player) && player->getPhase()!=Player::NotActive && use.card->getTypeId()!= Card::TypeSkill) {
            if (!player->hasFlag("youmu_odd")){
                room->setPlayerFlag(player, "-youmu_even");
                room->setPlayerFlag(player, "youmu_odd");
            }
            else{
                room->setPlayerFlag(player, "-youmu_odd");
                room->setPlayerFlag(player, "youmu_even");
            }
        }
        return;
    }

     virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Louguan : public TriggerSkill
{
public:
    Louguan() : TriggerSkill("louguan")
    {
        frequency = NotFrequent;
        events << CardUsed << CardFinished << TargetConfirmed;
    }
    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished) {
             CardUseStruct use = data.value<CardUseStruct>();
             foreach(auto p, use.to){
                 if (p->getMark("louguan_null")>0){
                     room->setPlayerMark(p, "Armor_Nullified", p->getMark("Armor_Nullified")-1);
                     room->setPlayerMark(p, "louguan_null", 0);
                 }
             }
        }
        if (event == TargetConfirmed) {
             CardUseStruct use = data.value<CardUseStruct>();
             if (use.card->hasFlag("louguan_slash") && player==use.from){
                 foreach(auto p, use.to){
                     if (p != use.from){
                         room->setPlayerMark(p, "Armor_Nullified", p->getMark("Armor_Nullified")+1);
                         room->setPlayerMark(p, "louguan_null", 1);
                     }
                 }
             }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (triggerEvent==CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")&& player == use.from && player->getPhase()!=Player::NotActive && !player->hasFlag("louguan_used") && player->hasFlag("youmu_odd")) {
                QList<ServerPlayer*> targets;
                foreach (ServerPlayer *to, room->getAlivePlayers()) {
                   if (!use.to.contains(to)&&player->distanceTo(to)==1){
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
            foreach (ServerPlayer *to, room->getAlivePlayers()) {
               if (!use.to.contains(to)&&player->distanceTo(to)==1){
                   targets << to;
               }
            }
            if(targets.isEmpty())
                return false;
            QList<ServerPlayer *> newtargets = room->askForPlayersChosen(player,targets,objectName(),0,targets.length(), QString(),true);
            player->tag["louguan_target"] = QVariant::fromValue(newtargets);
            room->setPlayerFlag(player, "louguan_used");
            room->setPlayerMark(player, "bailou_last", 0);
            room->setPlayerMark(player, "louguan_last", 1);
            use.card->setFlags("louguan_slash");
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QList<ServerPlayer *> targets = player->tag["louguan_target"].value<QList<ServerPlayer *> >();
        if (!targets.isEmpty()){
            room->broadcastSkillInvoke(objectName(),player);
            CardUseStruct use = data.value<CardUseStruct>();
            foreach(auto p, targets){
                use.to.append(p);              
            }
            data.setValue(use);
        }
        return false;
    }
};

class Bailou : public TriggerSkill
{
public:
    Bailou() : TriggerSkill("bailou")
    {
        frequency = NotFrequent;
        events << CardUsed << SlashProceed << Damage;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==Damage){
            auto damage = data.value<DamageStruct>();
            if (damage.card && damage.card->hasFlag("bailou_slash") && !damage.to->isNude()){
                room->askForDiscard(damage.to, objectName(), 1, 1 ,false, true);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
        if (triggerEvent==CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")&& player == use.from && player->getPhase()!=Player::NotActive && !player->hasFlag("bailou_used") && player->hasFlag("youmu_even")) {
                return QStringList(objectName());
            }
        }
        if (triggerEvent==SlashProceed){
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            if (effect.slash->hasFlag("bailou_slash")){
                return QStringList(objectName());
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == CardUsed && player->askForSkillInvoke(this, data)) {
            room->setPlayerFlag(player, "bailou_used");
            room->setPlayerMark(player, "louguan_last", 0);
            room->setPlayerMark(player, "bailou_last", 1);
            return true;
        }
        if (event == SlashProceed){
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            use.card->setFlags("bailou_slash");
            return false;
        }
        else{
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            room->slashResult(effect, NULL);
            return true;
        }
    }
};

class Rengui : public TriggerSkill
{
public:
    Rengui() : TriggerSkill("rengui")
    {
        events << Damage << EventPhaseEnd << DamageInflicted;
        relate_to_place = "head";
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==Damage && TriggerSkill::triggerable(player)&&(!room->getCurrent()||!room->getCurrent()->hasFlag("rengui_used"+player->objectName())) && player->getMark("louguan_last")>0 && player->getPhase()!=Player::NotActive){
            return QStringList(objectName());
        }
        if (event==DamageInflicted && TriggerSkill::triggerable(player)&&(!room->getCurrent()||!room->getCurrent()->hasFlag("rengui_used"+player->objectName())) && player->getMark("bailou_last")>0 && player->getPhase()==Player::NotActive){
            auto damage = data.value<DamageStruct>();
            if (damage.from)
                return QStringList(objectName());
        }
        if (event == EventPhaseEnd && player->getPhase()== Player::Finish){
            foreach(ServerPlayer *p, room->getOtherPlayers(player)){
                room->setFixedDistance(player,p,-1);
                p->setMark("rengui"+player->objectName(),p->getMark("rengui"+player->objectName())-1);
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            if (room->getCurrent()){
                room->setPlayerFlag(room->getCurrent(),"rengui_used"+player->objectName());
            }
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {

        if (event==Damage){
            room->setPlayerFlag(player, "rengui_in");
            foreach(ServerPlayer *p, room->getOtherPlayers(player)){
                room->setFixedDistance(player,p,1);
                p->setMark("rengui"+player->objectName(),p->getMark("rengui"+player->objectName())+1);
            }
        }
        if (event==DamageInflicted){
            if (room->askForUseSlashTo(player, room->getOtherPlayers(player), "@rengui-slash")){
                return true;
            }
        }
        return false;
    }
};

class RenguiTargetMod : public TargetModSkill
{
public:
    RenguiTargetMod() : TargetModSkill("#rengui-target")
    {
        pattern = "Slash";
    }

    virtual int getResidueNum(const Player *from, const Card *card) const
    {
        if (from->hasFlag("rengui_in"))
            return 1;
        else
            return 0;
    }

};

class Shenqiang : public TriggerSkill
{
public:
    Shenqiang() : TriggerSkill("shenqiang")
    {
        frequency = NotFrequent;
        events << TargetConfirmed;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==TargetConfirmed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && player==use.from && use.card && use.card->isKindOf("Slash") && player->getPhase()==Player::Play && !player->hasFlag("shenqiang_used") && !player->isKongcheng()) {
                 return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data) && room->askForCard(player,"BasicCard","@shenqiang:"+ player->objectName(), data, objectName())) {
            room->broadcastSkillInvoke(objectName(), player);
            room->setPlayerFlag(player, "shenqiang_used");
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QVariantList jink_list = player->tag["Jink_" + use.card->toString()].toList();

        room->sendCompulsoryTriggerLog(player, objectName());

        foreach(auto p, use.to){
            int index = use.to.indexOf(p);
            LogMessage log;
            log.type = "#NoJink";
            log.from = p;
            p->getRoom()->sendLog(log);
            jink_list[index] = 0;
        }

        player->tag["Jink_" + use.card->toString()] = jink_list;
        return false;
    }
};

class Xuecheng : public TriggerSkill
{
public:
    Xuecheng() : TriggerSkill("xuecheng")
    {
        frequency = Limited;
        limit_mark = "@xuecheng";
        events << EventPhaseStart << EventPhaseChanging << DamageInflicted << EventPhaseEnd << Damage;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damage && player->getPhase() != Player::NotActive){
            room->setPlayerFlag(player, "xue_damage");
        }
        if (event == EventPhaseEnd && player->getPhase() == Player::Finish){
            auto sp = room->findPlayerBySkillName(objectName());
            if (sp && player->getMark("@xue")>0 && !player->hasFlag("xue_damage") && !player->isNude()){
                room->askForDiscard(player, objectName(), 1, 1, false, true);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase() == Player::Finish && player->getMark(this->getLimitMark())>0)
            return QStringList(objectName());        
        if (event == EventPhaseChanging && data.value<PhaseChangeStruct>().to == Player::Start){
            foreach(auto p, room->getOtherPlayers(player)){
                if (p->getMark(player->objectName()+"xuecheng")>0){
                    room->setPlayerMark(p, player->objectName()+"xuecheng", 0);
                    p->loseMark("@xue");
                }
            }
        }
        if (event == DamageInflicted){
            auto damage = data.value<DamageStruct>();
            if (TriggerSkill::triggerable(player) && damage.from && damage.from->getMark("@xue")>0){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == EventPhaseStart && player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer *> to_choose;
            foreach(ServerPlayer *p, room->getAlivePlayers()) {
                if (player!=p)
                    to_choose << p;
            }

            QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, to_choose, objectName(), 0, 998, "@xuecheng-card", true);
            if (choosees.length()>0 ){
                room->broadcastSkillInvoke(objectName(), player);
                player->loseMark("@xuecheng");
                player->tag["xuecheng_invoke"] = QVariant::fromValue(choosees);
                return true;
            }
        }
        if (event == DamageInflicted && (player->hasShownSkill(this)||player->askForSkillInvoke(this, data))){
            return true;
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == EventPhaseStart){
            QList<ServerPlayer *> targets = player->tag["xuecheng_invoke"].value<QList<ServerPlayer *> >();
            foreach(auto p, targets){
                room->setPlayerMark(p, player->objectName()+"xuecheng", 1);
                p->gainMark("@xue");
            }
        }
        if (event == DamageInflicted){
            room->sendCompulsoryTriggerLog(player, objectName());
            return true;
        }
        return false;
    }
};

class Mingyun : public TriggerSkill
{
public:
    Mingyun() : TriggerSkill("mingyun")
    {
        events << EventPhaseEnd;
    }


    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!player->isKongcheng() && event == EventPhaseEnd && player->getPhase() == Player::Finish && TriggerSkill::triggerable(player) && !player->hasFlag("shenqiang_used")){
           return QStringList(objectName());
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QList<ServerPlayer *> list;
        if (event == EventPhaseEnd && player->askForSkillInvoke(this, data)) {
            foreach(auto p, room->getOtherPlayers(player)){
                if (!p->isKongcheng())
                    list << p;
            }

            ServerPlayer * target = room->askForPlayerChosen(player, list, objectName(), QString(), true);
            if (target ){
                room->broadcastSkillInvoke(objectName(), player);
                player->tag["mingyun_invoke"] = QVariant::fromValue(target);
                return true;
            }
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        auto target = player->tag["mingyun_invoke"].value<ServerPlayer *>();
        if (target){
            const Card *card1 = NULL;
            const Card *card2 = NULL;
            if (!player->isKongcheng()){
                card1 = room->askForCardShow(player, player, objectName());
            }
            if (!target->isKongcheng()){
                card2 = room->askForCardShow(target, player, objectName());
            }
            if (card1 && card2){
                room->showCard(player, card1->getEffectiveId());
                room->showCard(target, card2->getEffectiveId());
                room->obtainCard(target, card1);
                room->obtainCard(player, card2);
                if (card1->getSuit()==card2->getSuit()){
                    QList<ServerPlayer *> list;
                    foreach(auto s, player->getVisibleSkillList()){
                        if (s->getFrequency()==Skill::Limited && player->hasShownSkill(s->objectName()) && !list.contains(player) && !s->isAttachedLordSkill())
                            list<<player;
                    }
                    foreach(auto s, target->getVisibleSkillList()){
                        if (s->getFrequency()==Skill::Limited && target->hasShownSkill(s->objectName()) && !list.contains(target) && !s->isAttachedLordSkill())
                            list<<target;
                    }
                    if (!list.isEmpty()){
                        auto dest = room->askForPlayerChosen(player, list, objectName());
                        QStringList skills;
                        foreach(auto s, dest->getVisibleSkillList()){
                            if (s->getFrequency()==Skill::Limited && !s->isAttachedLordSkill() && dest->hasShownSkill(s->objectName()))
                                skills << s->objectName();
                        }
                        QString skill = room->askForChoice(player, objectName(), skills.join("+"), data);
                        const Skill *sk = Sanguosha->getSkill(skill);
                        if (dest->getMark(sk->getLimitMark())==0){
                            dest->gainMark(sk->getLimitMark());
                        }
                    }
                }
                if (card1->getNumber()==card2->getNumber()){
                    player->drawCards(2);
                    target->drawCards(2);
                }
                if (card1->objectName()==card2->objectName()){
                    room->loseHp(player);
                    room->loseHp(target);
                }
            }

        }
        return false;
    }
};

//Fading Cards
MapoTofu::MapoTofu(Card::Suit suit, int number)
    : BasicCard(suit, number)
{
    setObjectName("mapo_tofu");
}

QString MapoTofu::getSubtype() const
{
    return "food_card";
}

bool MapoTofu::IsAvailable(const Player *player, const Card *tofu)
{
    MapoTofu *newanaleptic = new MapoTofu(Card::NoSuit, 0);
    newanaleptic->deleteLater();
#define THIS_TOFU (tofu == NULL ? newanaleptic : tofu)
    if (player->isCardLimited(THIS_TOFU, Card::MethodUse) || player->isProhibited(player, THIS_TOFU))
        return false;

    return player->usedTimes("MapoTofu") <= Sanguosha->correctCardTarget(TargetModSkill::Residue, player, THIS_TOFU);
#undef THIS_ANALEPTIC
}

bool MapoTofu::isAvailable(const Player *player) const
{

    return IsAvailable(player, this) && BasicCard::isAvailable(player);
}

bool MapoTofu::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() == 0 && Self->distanceTo(to_select) <= 1 && to_select->getMark("mtUsed") == 0;
}

void MapoTofu::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    BasicCard::onUse(room, use);
}

void MapoTofu::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (targets.isEmpty())
        targets << source;
    BasicCard::use(room, source, targets);
}

void MapoTofu::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    //room->setEmotion(effect.to, "mapo_tofu");//TODO

    DamageStruct damage;
    damage.to = effect.to;
    damage.damage = effect.to->getHp() > 0 ? effect.to->getHp() - 1: 0;
    int toDamge = damage.damage;
    // damage.chain = false;
    damage.chain = true;
    damage.nature = DamageStruct::Fire;
    effect.to->getRoom()->damage(damage);
    LogMessage log;
    log.type = "#MapoTofuUse";
    log.from = effect.from;
    log.to << effect.to;
    log.arg = objectName();
    room->sendLog(log);
    effect.to->setMark("mtUsed", toDamge + 1);
}

Tacos::Tacos(Card::Suit suit, int number)
    : BasicCard(suit, number)
{
    setObjectName("tacos");
    target_fixed = true;
}

QString Tacos::getSubtype() const
{
    return "food_card";
}

bool Tacos::isAvailable(const Player *player) const
{
    return BasicCard::isAvailable(player);
}

void Tacos::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    BasicCard::onUse(room, use);
}

void Tacos::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (targets.isEmpty())
        targets << source;
    BasicCard::use(room, source, targets);
}

void Tacos::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    QList<int> list;
    foreach(auto id, room->getDiscardPile()){
        if (Sanguosha->getCard(id)->objectName()!="tacos")
            list<<id;
    }

    int n=list.length();
    if (n==0)
        return;
    int j = rand()%n;
    effect.to->obtainCard(Sanguosha->getCard(list.at(j)));

    n = qFloor((room->getDiscardPile().length())*3/4);
    if (n==0)
        return;
    CardsMoveStruct move;
    for(int i = 0; i<n; i++){
        move.card_ids << room->getDiscardPile().at(i);
    }
    move.to_place = Player::DrawPile;
    move.reason.m_reason=CardMoveReason::S_REASON_PUT;
    room->moveCardsAtomic(move,true);
}

LinkStart::LinkStart(Card::Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("link_start");
    target_fixed = true;
}

QString LinkStart::getSubtype() const
{
    return "link_start";
}

void LinkStart::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    SingleTargetTrick::onUse(room, use);
}

void LinkStart::onEffect(const CardEffectStruct &effect) const{
    ServerPlayer *player = effect.to;
    Room *room = effect.to->getRoom();
    QList<int> weapons;
    QList<int> armors;
    bool science = false;
    if (player->hasShownOneGeneral() && player->getKingdom()=="science")
        science = true;
    foreach(int i, room->getDrawPile()){
        const Card *card = Sanguosha->getCard(i);
        if (card->getSubtype() == "weapon"){
            weapons << i;
        }
    }
    foreach(int i, room->getDrawPile()){
        const Card *card = Sanguosha->getCard(i);
        if (card->getSubtype() == "armor"){
            armors << i;
        }
    }
    int weapon = -1;
    int armor = -1;
    if (!weapons.isEmpty()){
        if (science){
            QList<int> weapons3;
            for (int i = 0; i < 3; i++){
                if (!weapons.isEmpty()){
                     int wid = weapons.at(rand()%weapons.length());
                     weapons.removeOne(wid);
                     weapons3 << wid;
                }
            }
            room->fillAG(weapons3, player);
            weapon = room->askForAG(player, weapons3, false, objectName());
            room->clearAG(player);
        }
        else{
            weapon = weapons.at(rand()%weapons.length());
        }
    }
    if (!armors.isEmpty()){
        if (science){
            QList<int> armors3;
            for (int i = 0; i < 3; i++){
                if (!armors.isEmpty()){
                     int aid = armors.at(rand()%armors.length());
                     armors.removeOne(aid);
                     armors3 << aid;
                }
            }
            room->fillAG(armors3, player);
            armor = room->askForAG(player, armors3, false, objectName());
            room->clearAG(player);
        }
        else{
            armor = armors.at(rand()%armors.length());
        }
    }
    if (weapon > -1){
        room->obtainCard(player, weapon);
    }
    if (armor > -1){
        room->obtainCard(player, armor);
    }
}

bool LinkStart::isAvailable(const Player *player) const
{
    return !player->isProhibited(player, this) && TrickCard::isAvailable(player);
}

RenkinCard::RenkinCard()
{
    target_fixed = true;
}

void RenkinCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    room->setPlayerFlag(player, "-renkin_game");
    int x = 0;
    foreach(int i, this->getSubcards()){
        x = x + Sanguosha->getCard(i)->getNumber();
    }
    QList<int> ids;
    foreach(int id, room->getDrawPile()){
        if (Sanguosha->getCard(id)->getNumber()==x)
            ids << id;
    }
    if (!ids.isEmpty()){
        room->fillAG(ids, player);
        int choice = room->askForAG(player, ids, false, objectName());
        room->clearAG(player);
        room->obtainCard(player, choice);
    }
}

class Renkin : public ViewAsSkill
{
public:
    Renkin() : ViewAsSkill("renkin"){

    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
       int t = 0;
       foreach(auto c, selected){
           t = t+c->getNumber();
       }
       if (Self->hasFlag("renkin_game")){
         return t<=13 && t+to_select->getNumber()<=13;
       }
       else{
           return selected.length()==0 && to_select->getNumber()<=13;
       }
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "@@renkin";
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        RenkinCard *vs = new RenkinCard();
        vs->addSubcards(cards);
        vs->setSkillName(objectName());
        return vs;
    }
};

RenkinChouwa::RenkinChouwa(Card::Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("renkin_chouwa");
    target_fixed = true;
}

QString RenkinChouwa::getSubtype() const
{
    return "renkin_chouwa";
}

void RenkinChouwa::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    SingleTargetTrick::onUse(room, use);
}

void RenkinChouwa::onEffect(const CardEffectStruct &effect) const{
    ServerPlayer *player = effect.to;
    Room *room = effect.to->getRoom();
    bool game = player->hasShownOneGeneral() && player->getKingdom()=="game";
    if (game){
       room->setPlayerFlag(player, "renkin_game");
    }
    if (!room->askForUseCard(player, "@@renkin", "@renkin")){
        room->setPlayerFlag(player, "-renkin_game");
    }
}

bool RenkinChouwa::isAvailable(const Player *player) const
{
    return !player->isProhibited(player, this) && TrickCard::isAvailable(player);
}

//herobattle
Music::Music(Card::Suit suit, int number)
    : BasicCard(suit, number)
{
    setObjectName("music");
}

QString Music::getSubtype() const
{
    return "assist_card";
}


bool Music::isAvailable(const Player *player) const
{

    return player && player->isAlive() && !player->isCardLimited(this, Card::MethodUse, true) && BasicCard::isAvailable(player);
}

bool Music::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.length() < 1+Sanguosha->correctCardTarget(TargetModSkill::ExtraTarget, Self, this);
}

void Music::onUse(Room *room, const CardUseStruct &card_use) const
{
    BasicCard::onUse(room, card_use);
}

void Music::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->getCurrent()->setMark("music_times", room->getCurrent()->getMark("music_times")+1);
    /*int n = room->getCurrent()->getMark("music_times");
    LogMessage log;
    log.arg = QString::number(n);
    log.type = "#MusicTimes";
    room->sendLog(log);*/
    BasicCard::use(room, source, targets);
}

void Music::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    int n = room->getCurrent()->getMark("music_times");
    QString choice = room->askForChoice(effect.to, objectName(),"music_maxh+music_range+music_distance+music_moreslash", QVariant::fromValue(effect.from));
    room->setPlayerMark(effect.to, "#"+choice.remove("_"), effect.to->getMark("#"+choice.remove("_"))+1);
    /*if (effect.to == room->getCurrent())
        effect.to->setMark("music_selfturn", 1);*/
    LogMessage log;
    log.from = effect.to;
    log.arg = QString::number(n);
    log.type = "#MusicTimes"+choice;
    room->sendLog(log);
}

class MusicGlobal : public TriggerSkill
{
public:
    MusicGlobal() : TriggerSkill("#musicglobal")
    {
        frequency = Compulsory;
        events << EventPhaseChanging;
        global=true;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        auto phase = data.value<PhaseChangeStruct>();
        if (phase.to == Player::NotActive){
            room->setPlayerMark(player, "music_times", 0);
            if (player->getTreasure() && player->getTreasure()->objectName()=="Idolyousei" && player->getMark("Equips_Nullified_to_Yourself")==0){
                LogMessage log;
                log.from = player;
                log.type = "#IdolyouseiEffect";
                room->sendLog(log);
                return;
            }
            if (player->hasShownOneGeneral() && player->getKingdom() == "idol" && player->getRole() != "careerist"){
                foreach(auto p, room->getAlivePlayers()){
                    if (p->getTreasure() && p->getTreasure()->objectName()=="Idolyousei" && p->hasShownSkill("qingge")){
                        LogMessage log;
                        log.from = p;
                        log.to << player;
                        log.type = "#QinggeEffect";
                        room->sendLog(log);
                        return;
                    }
                }
            }
            room->setPlayerMark(player, "#musicmaxh", 0);
            room->setPlayerMark(player, "#musicrange", 0);
            room->setPlayerMark(player, "#musicdistance", 0);
            room->setPlayerMark(player, "#musicmoreslash", 0);
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class MusicMaxCards : public MaxCardsSkill
{
public:
    MusicMaxCards() : MaxCardsSkill("musicmax")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        return target->getMark("#musicmaxh");
    }
};

class MusicRange : public AttackRangeSkill
{
public:
    MusicRange() : AttackRangeSkill("musicrange")
    {
    }

    virtual int getExtra(const Player *target, bool include_weapon) const
    {
       return target->getMark("#musicrange");
    }
};

class MusicDistance : public DistanceSkill
{
  public:
    MusicDistance(): DistanceSkill("musicdistance")
    {
    }

    int getCorrect(const Player *from, const Player *to) const
    {
        return to->getMark("#musicdistance");
    }
};

class MusicTargetMod : public TargetModSkill
{
public:
    MusicTargetMod () : TargetModSkill("musictargetmod")
    {
    }

    virtual int getResidueNum(const Player *from, const Card *card) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        return from->getMark("#musicmoreslash");
    }
};

Clowcard::Clowcard(Card::Suit suit, int number)
    : BasicCard(suit, number)
{
    setObjectName("clowcard");
}

QString Clowcard::getSubtype() const
{
    return "multi_card";
}

bool Clowcard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *s = new Slash(this->getSuit(), this->getNumber());
    return s->targetFilter(targets, to_select, Self);
}


Shinai::Shinai(Suit suit, int number)
    : Weapon(suit, number, 2)
{
    setObjectName("Shinai");
    target_fixed = false;
}
bool Shinai::targetFilter(const QList<const Player*> &targets, const Player *to_select, const Player *Self) const
{
    return Self->distanceTo(to_select)<=1 && ((Self == to_select && !this->isEquipped()) || !to_select->getWeapon()) && targets.length()<1;
}

class ShinaiSkill : public ZeroCardViewAsSkill
{
public:
    ShinaiSkill() : ZeroCardViewAsSkill("Shinai")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("Equips_Nullified_to_Yourself")==0 && player->getWeapon() && player->getWeapon()->objectName()=="Shinai" && !player->hasUsed("ViewAsSkill_ShinaiCard");
    }

    virtual const Card *viewAs() const
    {
        if (!Self->getWeapon() || Self->getWeapon()->objectName()!="Shinai")
            return NULL;
        Card *card = Sanguosha->getCard(Self->getWeapon()->getEffectiveId());
        return card;
    }
};

class ShinaiEffect : public TriggerSkill
{
public:
    ShinaiEffect() : TriggerSkill("ShinaiEffect")
    {
        frequency = Compulsory;
        events << PreCardUsed << DamageCaused << TargetConfirmed << CardFinished;
        //global = true;
    }

    virtual int getPriority() const
    {
        return -3;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if ((!player->hasWeapon("Shinai") && player->property("touying_type").toString()!="Shinai") || player->getMark("Equips_Nullified_to_Yourself")>0)
            return QStringList();
        if (event == PreCardUsed){
           auto use = data.value<CardUseStruct>();
           if (use.card->isKindOf("Slash") && use.card->objectName()!= "slash")
               return QStringList(objectName());
        }
        if (event == DamageCaused){
           auto damage = data.value<DamageStruct>();
           if (damage.card && damage.card->isKindOf("Slash"))
               return QStringList(objectName());
        }
        if (event == TargetConfirmed){
           auto use = data.value<CardUseStruct>();
           if (use.card && use.card->isKindOf("Slash") && use.to.length()>1 && use.from && use.from == player)
               return QStringList(objectName());
        }
        if (event == CardFinished){
           auto use = data.value<CardUseStruct>();
           if (use.card->isKindOf("Slash"))
               return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return true;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == PreCardUsed){
           auto use = data.value<CardUseStruct>();
           Slash *s = new Slash(Card::SuitToBeDecided, -1);
           s->addSubcards(use.card->getSubcards());
           use.card = s;
           s->setObjectName("slash");
           data.setValue(use);
        }
        if (event == DamageCaused){
           auto damage = data.value<DamageStruct>();
           if (damage.damage>1){
               damage.damage = damage.damage-1;
               data.setValue(damage);
           }
           else{
               return true;
           }
        }
        if (event == TargetConfirmed){
           auto use = data.value<CardUseStruct>();
           foreach(auto p, use.to){
               room->cancelTarget(use, p);
           }
           data = QVariant::fromValue(use);
        }
        if (event == CardFinished){
           auto use = data.value<CardUseStruct>();
           foreach(auto p, use.to){
               p->drawCards(1);
           }
        }
    }
};

Josou::Josou(Suit suit, int number)
    : Armor(suit, number)
{
    setObjectName("Josou");
    target_fixed = false;
}
bool Josou::targetFilter(const QList<const Player*> &targets, const Player *to_select, const Player *Self) const
{
    return Self->distanceTo(to_select)<=1 && ((Self == to_select && !this->isEquipped()) || !to_select->getArmor()) && targets.length()<1;
}

void Josou::onInstall(ServerPlayer *player) const
{
    Room *room = player->getRoom();
    auto skill = Sanguosha->getSkill(objectName());
    if (skill) {
        if (skill->inherits("ViewAsSkill")) {
           room->attachSkillToPlayer(player, objectName());
        }
        else if (skill->inherits("TriggerSkill")) {
           auto tirggerskill = Sanguosha->getTriggerSkill(objectName());
           room->getThread()->addTriggerSkill(tirggerskill);
        }
    }
    if (player->isMale() && !player->isKongcheng()){
        room->askForDiscard(player, "Josou", 1, 1, false);
    }
}

void Josou::onUninstall(ServerPlayer *player) const
{
    Room *room = player->getRoom();
    const Skill *skill = Sanguosha->getSkill(this);
    if (skill) {
        if (skill->inherits("ViewAsSkill")) {
            room->detachSkillFromPlayer(player, this->objectName(), true);
        } else if (skill->inherits("TriggerSkill")) {
            const TriggerSkill *trigger_skill = qobject_cast<const TriggerSkill *>(skill);
            if (trigger_skill->getViewAsSkill())
                room->detachSkillFromPlayer(player, this->objectName(), true);
        }
    }
    if (player->isMale() && !player->isKongcheng()){
        room->askForDiscard(player, "Josou", 1, 1, false);
    }
}

class JosouSkill : public ZeroCardViewAsSkill
{
public:
    JosouSkill() : ZeroCardViewAsSkill("Josou")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->hasArmorEffect(objectName()) && player->getArmor() && player->getArmor()->objectName()=="Josou" && !player->hasUsed("ViewAsSkill_JosouCard");
    }

    virtual const Card *viewAs() const
    {
        if (!Self->getArmor() || Self->getArmor()->objectName()!="Josou")
            return NULL;
        Card *card = Sanguosha->getCard(Self->getArmor()->getEffectiveId());
        return card;
    }
};

class JosouMaxCards : public MaxCardsSkill
{
public:
    JosouMaxCards() : MaxCardsSkill("josoumax")
    {
    }

    virtual int getExtra(const ServerPlayer *player, MaxCardsType::MaxCardsCount) const
    {
        if (player->isMale() && player->hasArmorEffect("Josou")){
            return -1;
        }
        else{
            return 0;
        }
    }
};

class JosouEffect : public TriggerSkill
{
public:
    JosouEffect() : TriggerSkill("JosouEffect")
    {
        frequency = Compulsory;
        events << DamageInflicted;
    }

    virtual int getPriority() const
    {
        return -3;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == DamageInflicted && player->hasArmorEffect("Josou") && player->getArmor() && player->getArmor()->objectName()=="Josou"){
           auto damage = data.value<DamageStruct>();
           if (!damage.from) return QStringList();
           if (damage.from && (player->isMale() && damage.from->isFemale()) || (damage.from->isMale() && player->isFemale()))
               return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return player->askForSkillInvoke("Josou");
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardMoveReason reason(CardMoveReason::S_REASON_NATURAL_ENTER, player->objectName(), objectName(), QString());
        room->moveCardTo(player->getArmor(), NULL, Player::DiscardPile, reason, true);
        DamageStruct damage = data.value<DamageStruct>();
        LogMessage log;
        log.type = "#Josou";
        log.from = player;
        if (damage.from)
            log.to << damage.from;
        log.arg = QString::number(damage.damage);
        if (damage.nature == DamageStruct::Normal)
            log.arg2 = "normal_nature";
        else if (damage.nature == DamageStruct::Fire)
            log.arg2 = "fire_nature";
        else if (damage.nature == DamageStruct::Thunder)
            log.arg2 = "thunder_nature";
        room->sendLog(log);
        return true;
    }
};

class EquipGlobal : public TriggerSkill
{
public:
    EquipGlobal() : TriggerSkill("#equipglobal")
    {
        frequency = Compulsory;
        events << PreCardUsed;
        global=true;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        auto use = data.value<CardUseStruct>();
        if (use.card->isKindOf("EquipCard") && player->hasEquip(use.card) && use.from){
            room->addPlayerHistory(use.from, "ViewAsSkill_" + use.card->objectName() + "Card");
        }
        if (use.card->isKindOf("Music") && use.card->getSkillName()== "Negi" && use.from){
            if (!room->getCurrent()->hasFlag("Negi_used")){
                room->setPlayerFlag(room->getCurrent(), "Negi_used");
            }
            else{
                room->setPlayerFlag(room->getCurrent(), "Negi_used2");
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class IdolyouseiViewAsSkill : public ZeroCardViewAsSkill
{
public:
    IdolyouseiViewAsSkill() : ZeroCardViewAsSkill("Idolyousei")
    {
        response_pattern = "@@Idolyousei!";
    }

    virtual const Card *viewAs() const
    {
        Music *music = new Music(Card::NoSuit, 0);
        music->setSkillName(objectName());
        return music;
    }
};

Idolyousei::Idolyousei(Suit suit, int number)
    : Treasure(suit, number)
{
    setObjectName("Idolyousei");
}

void Idolyousei::onInstall(ServerPlayer *player) const
{
    Room *room = player->getRoom();
    if (!room->askForUseCard(player, "@@Idolyousei!", "@Idolyousei")) {
        Music *music = new Music(Card::NoSuit, 0);
        music->setSkillName(objectName());
        QList<ServerPlayer *> targets;
        foreach (ServerPlayer *p, room->getAlivePlayers()) {
            if (!player->isProhibited(p, music))
                targets << p;
        }
        if (targets.isEmpty()) {
            delete music;
        } else {
            ServerPlayer *target = targets.at(qrand() % targets.length());
            room->useCard(CardUseStruct(music, player, target), false);
        }
    }
}

Igiari::Igiari(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    target_fixed = true;
    setObjectName("igiari");
}

void Igiari::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    // does nothing, just throw it
    QList<int> table_cardids = room->getCardIdsOnTable(this);
    if (!table_cardids.isEmpty()) {
        DummyCard dummy(table_cardids);
        CardMoveReason reason(CardMoveReason::S_REASON_USE, source->objectName());
        room->moveCardTo(&dummy, NULL, Player::DiscardPile, reason);
    }
}

bool Igiari::isAvailable(const Player *) const
{
    return false;
}

Negi::Negi(Suit suit, int number)
    : Weapon(suit, number, 2)
{
    setObjectName("Negi");
}

class NegiSkillVS : public OneCardViewAsSkill
{
public:
    NegiSkillVS() : OneCardViewAsSkill("Negi")
    {
    }

    bool isEnabledAtPlay(const Player *player) const{
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const{
        return pattern == "@@Negi";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const{
        return !to_select->isEquipped();
    }

    virtual const Card *viewAs(const Card *card) const
    {

        auto music = new Music(card->getSuit(), card->getNumber());
        music->addSubcard(card);
        music->setSkillName("Negi");
        return music;
    }
};

class NegiSkill : public WeaponSkill
{
public:
    NegiSkill() : WeaponSkill("Negi")
    {
        events << Damage;
        view_as_skill = new NegiSkillVS;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (damage.card && damage.card->isKindOf("Slash") && player->usedTimes("ViewAsSkill_NegiCard")<2 && !room->getCurrent()->hasFlag("Negi_used2")){
            room->askForUseCard(player, "@@Negi", "@Negi");
        }


        return false;
    }
};

Idolclothes::Idolclothes(Suit suit, int number)
    : Armor(suit, number)
{
    setObjectName("Idolclothes");
}

class IdolclothesSkill : public ArmorSkill
{
public:
    IdolclothesSkill() : ArmorSkill("Idolclothes")
    {
        events << TargetConfirming;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card && use.card->getTypeId()!=Card::TypeSkill && use.to.length()>1 && player->askForSkillInvoke(this, data)){
            auto choice = room->askForChoice(player, objectName(), "ic_self+ic_others", data);
            if (choice == "ic_self"){
                room->cancelTarget(use, player);
                data = QVariant::fromValue(use);
            }
            else{
                foreach(auto p, use.to){
                    if (p == player)
                        continue;
                    room->cancelTarget(use, p);
                }
                data = QVariant::fromValue(use);
            }
        }


        return false;
    }
};

ShiningConcert::ShiningConcert(Card::Suit suit, int number, bool is_transferable)
    : AOE(suit, number)
{
    setObjectName("shining_concert");
    transferable = is_transferable;
}

void ShiningConcert::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    QString choices = "sc_draw+sc_recover+cancel";
    if (effect.to->hasShownOneGeneral() && effect.to->getKingdom() == "idol")
        choices = "sc_draw+sc_recover+sc_drboth+cancel";
    QString choice = room->askForChoice(effect.to, objectName(), choices, QVariant::fromValue(effect.from));
    if (choice == "sc_draw" || choice == "sc_drboth"){
        effect.to->drawCards(1);
    }
    if (choice == "sc_recover" || choice == "sc_drboth"){
        RecoverStruct recover;
        recover.recover = 1;
        recover.who = effect.from;
        room->recover(effect.to, recover, true);
    }
    if (choice != "cancel") {
        if (!effect.to->isNude()){
            int id = room->askForCardChosen(effect.from, effect.to, "he", objectName());
            room->obtainCard(effect.from, id, false);
        }
    }
}

IdolRoad::IdolRoad(Card::Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    setObjectName("idol_road");
    target_fixed = true;
}

QString IdolRoad::getSubtype() const
{
    return "idol_road";
}

void IdolRoad::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    SingleTargetTrick::onUse(room, use);
}

void IdolRoad::onEffect(const CardEffectStruct &effect) const{
    ServerPlayer *player = effect.to;
    Room *room = effect.to->getRoom();
    player->setProperty("ir_times", QVariant(player->property("ir_times").toInt()+1));
    QStringList choices;
    choices << "ir_draw";
    if (!effect.to->hasShownGeneral1() && effect.to->disableShow(true).isEmpty())
        choices << "show_head";
    if (effect.to->getGeneral2() && !effect.to->hasShownGeneral2() && effect.to->disableShow(false).isEmpty())
        choices << "show_deputy";

    QString choice = room->askForChoice(player, objectName(), choices.join("+"));
    if (choice.contains("show")) {
        player->showGeneral(choice == "show_head");
        player->drawCards(2, objectName());
    }else{
        int x = qMin(player->property("ir_times").toInt(), room->getAlivePlayers().length());
        player->drawCards(x, objectName());
    }
}

bool IdolRoad::isAvailable(const Player *player) const
{
    return !player->isProhibited(player, this) && TrickCard::isAvailable(player);
}

HimitsuKoudou::HimitsuKoudou(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    target_fixed = true;
    setObjectName("himitsu_koudou");
    will_throw = false;
}

void HimitsuKoudou::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    if (room->getCurrent()){
        ServerPlayer *player = room->getCurrent();
        player->obtainCard(this, true);
        QString color = this->isRed() ? "red" : "black";
        if (color == "black")
            color = this->isBlack() ? "black" : "no_suit";
        if (color == "no_suit"){
            return;
        }

        if (isRed()){
            LogMessage log;
            log.type = "#HimitsuRedDetails";
            log.from = room->getCurrent();
            log.arg = getSuitString();
            room->sendLog(log);
        }
        if (isBlack()){
            LogMessage log;
            log.type = "#HimitsuBlackDetails";
            log.from = room->getCurrent();
            log.arg = getSuitString();
            room->sendLog(log);
        }

        room->setPlayerCardLimitation(player, "use,response", ".|"+color+"|.|.", true);
    }
}

bool HimitsuKoudou::isAvailable(const Player *) const
{
    return false;
}

MemberRecruitment::MemberRecruitment(Suit suit, int number)
    : SingleTargetTrick(suit, number)
{
    target_fixed = true;
    setObjectName("member_recruitment");
}

bool MemberRecruitment::isAvailable(const Player *player) const
{
    bool invoke = false;
    if (!player->hasShownOneGeneral())
        return false;

    return TrickCard::isAvailable(player);
}

void MemberRecruitment::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardUseStruct use = card_use;
    if (use.to.isEmpty())
        use.to << use.from;
    SingleTargetTrick::onUse(room, use);
}

void MemberRecruitment::onEffect(const CardEffectStruct &effect) const
{
    Room *room = effect.to->getRoom();
    if (effect.to->hasShownOneGeneral()){
        ServerPlayer *dest = NULL;
        foreach(auto p, room->getOtherPlayers(effect.to)){
            if (!p->hasShownOneGeneral()){
                if (p->willBeFriendWith(effect.to)){
                    if (p->askForGeneralShow(true, true)){
                        dest = p;
                        break;
                    }
                }
                else{
                    room->askForChoice(p, objectName(), "cannot_showgeneral+cancel");
                }
            }
        }
        if (dest){
            effect.to->drawCards(1);
            dest->drawCards(1);
            QStringList choices;
            choices << "cancel";
            foreach(auto s, effect.to->getVisibleSkillList()){
                if (s->getFrequency() == Skill::Club && effect.to->hasShownSkill(s)){
                    choices << s->getClubName();
                }
            }
            QString club = room->askForChoice(dest, objectName(), choices.join("+"));
            if (club != "cancel")
                dest->addClub(club);
        }
        else{
            /*CardMoveReason reason(CardMoveReason::S_REASON_RECAST, effect.to->objectName());
            reason.m_skillName = objectName();
            room->moveCardTo(this, effect.to, NULL, Player::PlaceTable, reason, true);
            effect.to->broadcastSkillInvoke("@recast");

            LogMessage log;
            log.type = "#Card_Recast";
            log.from = effect.to;
            log.card_str = this->toString();
            room->sendLog(log);

            QList<int> table_cardids = room->getCardIdsOnTable(this);
            if (!table_cardids.isEmpty())
            {
                DummyCard dummy(table_cardids);
                room->moveCardTo(&dummy, effect.to, NULL, Player::DiscardPile, reason, true);
            }*/

            effect.to->drawCards(1);
        }
    }
    else{
        effect.to->drawCards(1);
    }
}

SpecialCardPackage::SpecialCardPackage() : Package("herobattlecard", CardPack)
{
    skills << new MusicMaxCards << new MusicRange << new MusicDistance << new MusicTargetMod << new MusicGlobal << new Skill("clowcard");
    skills << new ShinaiSkill << new JosouSkill << new EquipGlobal << new ShinaiEffect << new JosouMaxCards <<new JosouEffect << new IdolyouseiViewAsSkill << new NegiSkill << new IdolclothesSkill;

    QList<Card *> horses;

    horses
        << new DefensiveHorse(Card::Club, 4);

    horses.at(0)->setObjectName("MagicBroom");

    QList<Card *> cards;
    Music *music = new Music(Card::Heart, 10);
    music->setTransferable(true);
    Clowcard *clowcard = new Clowcard(Card::Club, 8);
    clowcard->setTransferable(true);
    HimitsuKoudou *himitsu = new HimitsuKoudou(Card::Diamond, 9);
    himitsu->setTransferable(true);
    cards << new Music(Card::Spade, 9) << new Music(Card::Diamond, 8) << music << new Music(Card::Club, 11);
    cards << new Clowcard(Card::Heart, 2) << new Clowcard(Card::Heart, 11) << new Clowcard(Card::Diamond, 6) << new Clowcard(Card::Club, 6) << new Clowcard(Card::Club, 7) << clowcard;
    cards << new Shinai << new Josou << horses;
    cards << new Idolyousei << new Igiari(Card::Club, 10) << new Igiari(Card::Club, 12) << new Negi << new Idolclothes << new ShiningConcert(Card::Heart, 1);
    cards << new IdolRoad(Card::Diamond, 2) << new IdolRoad(Card::Diamond, 3);
    cards << himitsu << new HimitsuKoudou(Card::Club, 9) << new MemberRecruitment(Card::Diamond, 11);

    foreach(Card *card, cards)
        card->setParent(this);


}

FadingPackage::FadingPackage()
    : Package("fading")
{
    skills << new XuerenTargetMod << new XuerenTrigger << new KiokuMax << new HuanzhuangTargetMod << new ZhuangjiaMaxCards << new WuzhuangMaxCards << new ZhongquanTrigger << new Youmurecord << new RenguiTargetMod << new MishiTrigger << new Renkin << new jingmingTargetMod;

    General *haruhi = new General(this, "haruhi", "real", 3, false);
    haruhi->addSkill(new Mengxian);
    haruhi->addSkill(new Yuanwang);
    General *yukihira = new General(this, "Yukihira", "real", 4);
    yukihira->addSkill(new Pengtiao);
    yukihira->addSkill(new Shiji);
    General *fsatoru = new General(this, "Fsatoru", "real", 4);
    fsatoru->addSkill(new Revival);
    fsatoru->addSkill(new Fhuanxing);
    General *meiko = new General(this, "Meiko", "real", 3, false);
    meiko->addSkill(new Huaming);
    meiko->addSkill(new Xinyuan);
    General *nagase = new General(this, "nagase", "real", 3, false);
    nagase->addSkill(new Qifen);
    nagase->addSkill(new Mishi);
    nagase->addSkill(new Zhufu);

    General *akari = new General(this, "Akari", "science", 3, false);
    akari->addSkill(new Takamakuri);
    akari->addSkill(new Tobiugachi);
    akari->addSkill(new Fukurouza);
    akari->addCompanion("Aria");
    General *isla = new General(this, "Isla", "science", 3, false);
    isla->addSkill(new Kioku);
    isla->addSkill(new Xiangsui);
    General *alice = new General(this, "Alice", "science", 3, false);
    alice->addSkill(new Zhenghe);
    alice->addSkill(new Jianwu);
    alice->addSkill(new Kanhu);
    alice->addCompanion("Kirito");
    General *arnval = new General(this, "Arnval", "science", 3, false);
    arnval->addSkill(new Zhuangjia);
    arnval->addSkill(new Wuzhuang);
    General *oyuu = new General(this, "Oyuu", "science");
    oyuu->addSkill(new Duoquyan);
    oyuu->addCompanion("Nao");

    General *kuriyama = new General(this, "Kuriyama", "magic", 4, false);
    kuriyama->addSkill(new Zhouxue);
    kuriyama->addSkill(new Xueren);
    kuriyama->addSkill(new Caoxue);
    kuriyama->setDeputyMaxHpAdjustedValue();
    General *eruza = new General(this, "Eruza", "magic", 4, false);
    eruza->addSkill(new Huanzhuang);
    General *khntmiku = new General(this, "khntmiku", "magic", 3, false);
    khntmiku->addSkill(new Jingming);
    khntmiku->addSkill(new Yingxian);
    General *homura = new General(this, "Homura", "magic", 3, false);
    homura->addSkill(new Shiting);
    homura->addSkill(new Qiehuo);
    homura->addSkill(new Sujiu);
    General *wilhelmina = new General(this, "Wilhelmina", "magic", 3, false);
    wilhelmina->addSkill(new Guandai);
    wilhelmina->addSkill(new Qiaoshou);
    wilhelmina->addCompanion("Shana");

    General *eirin  = new General(this, "Eirin", "game", 3, false);
    eirin->addSkill(new Penglai);
    eirin->addSkill(new Jiansi);
    eirin->addCompanion("Reisen");
    General *ayanamiR = new General(this, "AyanamiR", "game", 3, false);
    ayanamiR->addSkill(new Taxian);
    ayanamiR->addSkill(new Guishen);
    General *shigure = new General(this, "Shigure", "game", 3, false);
    shigure->addSkill(new Zhongquan);
    shigure->addSkill(new Dstp);
    shigure->addSkill(new Guihuan);
    shigure->addCompanion("Yuudachi");
    General *youmu = new General(this, "Youmu", "game", 4, false);
    //youmu->addSkill(new Shuangreny);
    //youmu->addSkill(new Zhanwang);
    youmu->addSkill(new Louguan);
    youmu->addSkill(new Bailou);
    youmu->addSkill(new Rengui);
    youmu->setHeadMaxHpAdjustedValue();
    General *remilia = new General(this, "Remilia", "game", 3, false);
    remilia->addSkill(new Shenqiang);
    remilia->addSkill(new Xuecheng);
    remilia->addSkill(new Mingyun);


    addMetaObject<MapoTofu>();
    addMetaObject<Tacos>();
    addMetaObject<PengtiaoCard>();
    addMetaObject<XiangsuiCard>();
    addMetaObject<PenglaiCard>();
    addMetaObject<JianwuCard>();
    addMetaObject<KanhuCard>();
    addMetaObject<TaxianCard>();
    addMetaObject<YingxianCard>();
    addMetaObject<QiehuoCard>();
    addMetaObject<SujiuCard>();
    addMetaObject<RenkinCard>();
    addMetaObject<GuandaiCard>();
    addMetaObject<Music>();
}

FadingCardPackage::FadingCardPackage() : Package("fadingcard", CardPack)
{
    QList<Card *> cards;
    cards << new MapoTofu(Card::Spade, 1);
    cards << new Tacos(Card::Heart, 13);
    cards << new Tacos(Card::Club, 3);
    cards << new LinkStart(Card::Spade, 11);
    cards << new RenkinChouwa(Card::Heart, 4);

    foreach(Card *card, cards)
        card->setParent(this);


}

ADD_PACKAGE(SpecialCard)
ADD_PACKAGE(Fading)
ADD_PACKAGE(FadingCard)
