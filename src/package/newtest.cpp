
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
#include "guhuobox.h"
#include "revolution.h"

Key::Key(Card::Suit suit, int number)
    : DelayedTrick(suit, number)
{
    setObjectName("keyCard");
}

bool Key::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *source) const
{
    // please use this to check validity when put key
    int num = 0;
    int count=0;
    QList<const Player *> sib = source->getAliveSiblings();
    sib << source;
    foreach (const Player *p, sib){
        if(p->hasClub("yanjubu")){
             count=count+1;
        }
        if(p->hasShownSkill("kazoku") && p->isFriendWith(to_select)){
             return true;
        }
    }
    foreach (const Card *card, to_select->getJudgingArea())
    {
        if (card->objectName() == objectName())
        {
            num++;
        }
    }
    return targets.isEmpty() && (num == 0 ||(num<count && to_select->hasClub("yanjubu")));
}

void Key::takeEffect(ServerPlayer *target) const
{
    target->clearHistory();
#ifndef QT_NO_DEBUG
    if (!target->getAI() && target->askForSkillInvoke("userdefine:cancelkeyCard")) return;
#endif
}

void Key::onEffect(const CardEffectStruct &effect) const
{
    ServerPlayer *player = effect.to;
    if (player == NULL || !player->isAlive() || !player->isWounded())
        return;

    Room *room = player->getRoom();

    LogMessage log;
    log.from = player;
    log.arg = effect.card->objectName();
    log.type = "$KeyRecover";
    room->sendLog(log);

    RecoverStruct recover;
    recover.recover = 1;
    recover.card = effect.card;
    room->recover(player, recover, true);
}

//for managing anything needed to be done with key
class keyCardGlobalManagement : public TriggerSkill
{
public:
    keyCardGlobalManagement() : TriggerSkill("keyCard-global")
    {
        events << CardsMoveOneTime << Damaged << PreCardUsed << BeforeCardsMove;
        global = true;
    }

    virtual QMap<ServerPlayer *, QStringList> triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        QMap<ServerPlayer *, QStringList> skill_list;
        if (event==PreCardUsed){
            CardUseStruct use=data.value<CardUseStruct>();
            if (!use.card->isKindOf("Key"))
                return skill_list;
            if (room->getTag("keyList") == NULL)
            {
                QList<int> newList;
                room->setTag("keyList", QVariant::fromValue(newList));
            }
            QList<QVariant> ql = room->getTag("keyList").toList();
            if (!VariantList2IntList(ql).contains(use.card->getEffectiveId())){
                ql.append(QVariant::fromValue(use.card->getEffectiveId()));
            }
            room->setTag("keyList", ql);
        }
        if (event == BeforeCardsMove){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            QList<QVariant> ql = room->getTag("keyList").toList();
            QList<QVariant> q2 = room->getTag("xintiaoList").toList();
            foreach(auto p, room->getAlivePlayers()){
               foreach(auto c, p->getJudgingArea()){
                   if (c->isKindOf("Key")){
                       if (!VariantList2IntList(ql).contains(c->getEffectiveId())){
                           ql.append(QVariant::fromValue(c->getEffectiveId()));
                       }

                       //for xintiao
                       if (p->hasSkill("xintiao")){
                           if (!VariantList2IntList(q2).contains(c->getEffectiveId())){
                               q2.append(QVariant::fromValue(c->getEffectiveId()));
                           }
                       }
                   }
               }
            }
            room->setTag("keyList", ql);
            room->setTag("xintiaoList", q2);
        }
        if (event == CardsMoveOneTime)
        {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            for (int i = 0; i < move.card_ids.length(); i++)
            {
                if (!VariantList2IntList(room->getTag("keyList").toList()).contains(move.card_ids[i]))
                    continue;
                if (move.from != NULL && move.from->isAlive() && move.from_places[i] != NULL && move.from_places[i] == Player::PlaceDelayedTrick)
                {
                    ServerPlayer *from = NULL;
                    foreach(auto p, room->getAlivePlayers())
                    {
                        if (p->objectName() == move.from->objectName())
                        {
                            from = p;
                            break;
                        }
                    }

                    if (from != NULL && from->isAlive() && from->isWounded())
                    {
                        skill_list.insert(from, QStringList(objectName()));
                    }
                    else{
                        QList<QVariant> ql = room->getTag("keyList").toList();
                        ql.removeOne(QVariant::fromValue(move.card_ids[i]));
                        room->setTag("keyList", ql);
                    }

                }
            }
            /*QList<QVariant> ql = room->getTag("keyList").toList();
            foreach(auto p, room->getAlivePlayers()){
               foreach(auto c, p->getJudgingArea()){
                   if (c->isKindOf("Key")){
                       if (!VariantList2IntList(ql).contains(c->getEffectiveId())){
                           ql.append(QVariant::fromValue(c->getEffectiveId()));
                       }
                   }
               }
            }
            room->setTag("keyList", ql);*/
        }
        else if (event == Damaged)
        {
            auto damage = data.value<DamageStruct>();
            if (damage.damage > 0 && damage.to != NULL && damage.to->isAlive() && damage.to->containsTrick("keyCard") && damage.to == player)
            {
                skill_list.insert(damage.to, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        if (event == CardsMoveOneTime)
        {
            return true;
        }
        else if (event == Damaged)
        {
            const Card *key;
            foreach (const Card *card, ask_who->getJudgingArea())
            {
                if (card->isKindOf("Key"))
                {
                    key = card;
                }
            }

            LogMessage log;
            log.from = ask_who;
            log.type = "#DelayedTrick";
            log.arg = key->objectName();
            room->sendLog(log);

            JudgeStruct judge;
            judge.pattern = ".|diamond|.";
            judge.good = true;
            judge.reason = "keyCard";
            judge.who = ask_who;

            room->judge(judge);

            if (judge.isGood())
            {
                return true;
            }

        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event == Damaged)
        {
            const Card *key;
            foreach (const Card *card, ask_who->getJudgingArea())
            {
                if (card->isKindOf("Key"))
                {
                    key = card;
                }
            }

            CardMoveReason reason(CardMoveReason::S_REASON_PUT, ask_who->objectName());
            room->moveCardTo(key, ask_who, NULL, Player::DiscardPile, reason, true);
        }
        else if (event == CardsMoveOneTime)
        {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            for (int i = 0; i < move.card_ids.length(); i++)
            {
                if (!VariantList2IntList(room->getTag("keyList").toList()).contains(move.card_ids[i]))
                    continue;

                const Card *card = Sanguosha->getCard(move.card_ids[i]);
                if (!VariantList2IntList(room->getTag("keyList").toList()).contains(move.card_ids[i]))
                    continue;
                Key* key = new Key(card->getSuit(), card->getNumber());
                key->addSubcard(card);
                Card *trick = Sanguosha->cloneCard(key);
                Q_ASSERT(trick != NULL);
               // WrappedCard *wrapped = Sanguosha->getWrappedCard(move.card_ids[i]);
                //wrapped->takeOver(trick);
                //room->broadcastUpdateCard(room->getPlayers(), wrapped->getId(), wrapped);
                room->cardEffect(trick, ask_who, ask_who);

                    QList<QVariant> ql = room->getTag("keyList").toList();
                    ql.removeOne(QVariant::fromValue(move.card_ids[i]));
                    room->setTag("keyList", ql);
            }

        }
        return false;
    }

    virtual int getPriority() const
    {
        return 2;
    }
};

//Put an card as key for Key Skills
void putKeyFromId(Room *room, int id, ServerPlayer *from, ServerPlayer *to, QString skill_name)
{
    const Card *card = Sanguosha->getCard(id);
    Key* key = new Key(card->getSuit(), card->getNumber());
    key->addSubcard(card);
    key->setSkillName(skill_name);

    Card *trick = Sanguosha->cloneCard(key);
    Q_ASSERT(trick != NULL);
    WrappedCard *wrapped = Sanguosha->getWrappedCard(id);
    wrapped->takeOver(trick);
    room->broadcastUpdateCard(room->getPlayers(), wrapped->getId(), wrapped);
    wrapped->setShowSkill(card->showSkill());

    CardMoveReason reason(CardMoveReason::S_REASON_PUT, from->objectName(), to->objectName(), skill_name, "putkey");
    room->moveCardTo(wrapped, from, to, Player::PlaceDelayedTrick, reason, true);

    //addkey
    if (room->getTag("keyList") == NULL)
    {
        QList<int> newList;
        room->setTag("keyList", QVariant::fromValue(newList));
    }
    QList<QVariant> ql = room->getTag("keyList").toList();
    ql.append(QVariant::fromValue(key->getEffectiveId()));
    room->setTag("keyList", ql);
}

//real
ZhurenCard::ZhurenCard()
{
    will_throw = false;
}

bool ZhurenCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select != Self && targets.length() == 0;
}

bool ZhurenCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    int key_num = 0;
    foreach(auto p, targets){
        if (p != Self)
            foreach(const Card *card, p->getJudgingArea())
                key_num += card->isKindOf("Key") ? 1 : 0;
    }
    foreach(const Card *card, Self->getJudgingArea())
        key_num += card->isKindOf("Key") ? 1 : 0;
    return this->getSubcards().length() <= Self->getLostHp() + key_num;
}

void ZhurenCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (!target)
        return;
    player->tag["zhurenCardNum"] = QVariant::fromValue(this->subcardsLength());
    room->obtainCard(target, this, false);
}

class Zhuren : public ViewAsSkill
{
public:
    Zhuren() : ViewAsSkill("zhuren")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ZhurenCard");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        /*auto list = Self->getAliveSiblings();
        int key_num = 0;
        foreach(auto p, list){
            if (Self->isFriendWith(p))
                foreach(const Card *card, p->getJudgingArea())
                    key_num += card->isKindOf("Key") ? 1 : 0;
        }
        foreach(const Card *card, Self->getJudgingArea())
            key_num += card->isKindOf("Key") ? 1 : 0;
        return selected.length() < Self->getLostHp() + key_num;*/
        return true;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        ZhurenCard *zrc = new ZhurenCard();
        zrc->addSubcards(cards);
        zrc->setSkillName(objectName());
        zrc->setShowSkill(objectName());
        return zrc;
    }
};

class ZhurenTrigger : public TriggerSkill
{
public:
    ZhurenTrigger() : TriggerSkill("#zhuren")
    {
        frequency = NotFrequent;
        events << EventPhaseEnd;
        global=true;
    }
    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (TriggerSkill::triggerable(player) && player->tag["zhurenCardNum"].toInt()>0) {
            if (triggerEvent == EventPhaseEnd){
                if (player->isAlive() && player->getPhase() == Player::Finish && player->tag.contains("zhurenCardNum")){
                    int card_num = player->tag["zhurenCardNum"].toInt();
                    if (card_num > 0)
                        player->drawCards(card_num);
                    player->tag.remove("zhurenCardNum");
                }

            }
        }
    }
    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {        
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Guangyuvs : public OneCardViewAsSkill
{
public:
    Guangyuvs() : OneCardViewAsSkill("guangyu"){

    }

    bool viewFilter(const Card *card) const
    {
        return !card->isEquipped() && card->getSuitString() == "heart";
    }

    const Card *viewAs(const Card *originalCard) const
    {
        GuangyuCard *card = new GuangyuCard(originalCard->getSuit(), originalCard->getNumber());
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("guangyu_used1") == 0;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return player->getMark("guangyu_used1") == 0 && pattern.contains("guangyucard");
    }
};

class Guangyu : public TriggerSkill
{
public:
    Guangyu() : TriggerSkill("guangyu")
    {
        events << TurnStart << CardsMoveOneTime << CardUsed;
        view_as_skill = new Guangyuvs;
        can_preshow = true;
        relate_to_place = "head";
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getSkillName() == objectName()){
                room->setPlayerMark(player, "guangyu_used1", 1);
            }
        }
        if (event == TurnStart && !player->hasFlag("Point_ExtraTurn")) {
            room->setPlayerMark(player, "guangyu_used1", 0);
            room->setPlayerMark(player, "guangyu_used2", 0);
        }
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == CardsMoveOneTime && TriggerSkill::triggerable(player)) {
             CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
             if (move.reason.m_reason != CardMoveReason::S_REASON_USE && move.reason.m_reason != CardMoveReason::S_REASON_LETUSE && move.to_place == Player::DiscardPile && player->getMark("guangyu_used2") == 0){
                 foreach(int id, move.card_ids){
                     if (Sanguosha->getCard(id)->getSuitString() == "heart")
                         return QStringList(objectName());
                 }
             }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == CardsMoveOneTime && player->askForSkillInvoke(this, data)) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            QList<int> list;
            foreach(int id, move.card_ids){
                if (Sanguosha->getCard(id)->getSuitString() == "heart")
                    list << id;
            }
            room->fillAG(list, player);
            int id = room->askForAG(player, list, false, objectName());
            room->clearAG(player);
            room->setPlayerMark(player, "guangyu_used2", 1);
            player->tag["guangyu_id"] = QVariant::fromValue(id);
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }


    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        int id = player->tag["guangyu_id"].toInt();
        player->tag["guangyu_id"] = QVariant();
        room->obtainCard(player, id);
        return false;
    }
};

class Newshenzhi : public TriggerSkill
{
public:
    Newshenzhi() : TriggerSkill("newshenzhi")
    {
        frequency = Frequent;
        events << EventPhaseStart;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && (player->getPhase()==Player::Start||player->getPhase()==Player::Finish)) {
             return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }


    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        int count=room->alivePlayerCount();
        if (count>4)
            count=4;
        room->doLightbox("LuaShenzhi$", 1000);
        QList<int> shenzhi = room->getNCards(count, false);

        LogMessage log;
        log.type = "$ViewDrawPile";
        log.from = player;
        log.card_str = IntList2StringList(shenzhi).join("+");
        room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
        room->askForGuanxing(player, shenzhi);
        return false;
    }
};

GonglueCard::GonglueCard()
{
    will_throw=true;
}

bool GonglueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select != Self && targets.length() == 0;
}

void GonglueCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (!target)
        return;
    if (!target->isKongcheng()){
        QList<int> list = target->handCards();
        QList<int> disabled_ids;
        foreach(int id,list){
            const Card *card=Sanguosha->getCard(id);
            if (card->getColor()!=this->getColor()) {
                disabled_ids.append(id);
            }
        }

        room->fillAG(list,player);
        int card_id = room->askForAG(player,list,true,objectName());
        const Card *card=Sanguosha->getCard(card_id);
        if (card){
            room->obtainCard(player,card,false);
        }
        room->clearAG(player);
    }
}

class Gonglue : public ViewAsSkill
{
public:
    Gonglue() : ViewAsSkill("gonglue")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("GonglueCard");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        return selected.length()==0;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        GonglueCard *vs = new GonglueCard();
        vs->addSubcards(cards);
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

ShourenCard::ShourenCard()
{
    will_throw=true;
}

bool ShourenCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select != Self && targets.length() == 0 && to_select->getHp()>=Self->getHp();
}

void ShourenCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (!target)
        return;
    room->loseHp(target);
}

class Shouren : public OneCardViewAsSkill
{
public:
    Shouren() : OneCardViewAsSkill("shouren"){

    }

    bool viewFilter(const Card *card) const
    {
        return !card->isEquipped();
    }

    const Card *viewAs(const Card *originalCard) const
    {
        ShourenCard *card = new ShourenCard();
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ShourenCard");
    }
};

QiyuanCard::QiyuanCard()
{
    will_throw=true;
    target_fixed=true;
}

void QiyuanCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    QStringList deathplayer;
    foreach(ServerPlayer *p, room->getPlayers()) {
        if (p->isDead() && p->isFriendWith(player)){
            deathplayer.append(p->getGeneralName());
        }
    }
    if (deathplayer.length()==0){
        room->setPlayerFlag(player, "qiyuan_used");
        return;
    }
    QString tar=room->askForChoice(player,"se_qiyuan%", deathplayer.join("+"));
    ServerPlayer *target;
    foreach(ServerPlayer *p, room->getPlayers()) {
        if (p->isDead() && p->getGeneralName()==tar){
            target=p;
        }
    }
    QString name = target->getActualGeneral1()->objectName();
    player->loseMark("@se_qiyuan");
    room->doLightbox("se_qiyuan$", 3000);
    QStringList avaliable_generals;
    foreach(QString s,target->getSelected()){
        const General *general = Sanguosha->getGeneral(s);
        if (!room->getUsedGeneral().contains(s) && general->getKingdom()!= "careerist")
            avaliable_generals << s;
    }

    room->setPlayerProperty(player, "Duanchang", QVariant());
    QString to_change = room->askForGeneral(target, avaliable_generals, QString(), true, "qiyuan", player->getKingdom());

    if (!to_change.isEmpty()) {
        /*room->doDragonPhoenix(target, to_change, QString(), false, player->getKingdom(), true, "h");
        room->setPlayerProperty(target, "hp", 2);

        target->setChained(false);
        room->broadcastProperty(target, "chained");

        target->setFaceUp(true);
        room->broadcastProperty(target, "faceup");

        target->setKingdom(player->getKingdom());
        room->broadcastProperty(target, "kingdom");

        QVariant string;
        string = name+":"+to_change;
        room->getThread()->trigger(GeneralTransformed, room, target, string);

        target->drawCards(1);*/

        room->revivePlayer(target);
        room->transformHeadGeneralTo(target, to_change);
        if (target->getActualGeneral2()->isMale()){
            room->transformDeputyGeneralTo(target, "sujiang");
        }
        else{
            room->transformDeputyGeneralTo(target, "sujiangf");
        }
        room->setPlayerProperty(target, "hp", 2);

        target->setChained(false);
        room->broadcastProperty(target, "chained");

        target->setFaceUp(true);
        room->broadcastProperty(target, "faceup");

        target->drawCards(1);
    }
}

class Qiyuan : public ZeroCardViewAsSkill
{
public:
    Qiyuan() : ZeroCardViewAsSkill("qiyuan")
    {
        frequency = Limited;
        limit_mark = "@se_qiyuan";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@se_qiyuan") > 0 && !player->hasFlag("qiyuan_used");
    }

    virtual const Card *viewAs() const
    {
        QiyuanCard *vs = new QiyuanCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Lichang : public TriggerSkill
{
public:
    Lichang() : TriggerSkill("lichang")
    {
        frequency = Frequent;
        events << CardAsked;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        QString pattern = Sanguosha->getCurrentCardUsePattern();
        bool can=false;
        foreach(ServerPlayer *p, room->getAlivePlayers()){
            if (p->isFriendWith(player)&&p->getJudgingArea().length()>0)
                can=true;
        }

        if (TriggerSkill::triggerable(player)&&pattern=="jink"&&can==true){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer *> list;
            foreach(ServerPlayer *p, room->getAlivePlayers()){
                if (p->isFriendWith(player)&&p->getJudgingArea().length()>0)
                    list << p;
            }
            ServerPlayer *target = room->askForPlayerChosen(player,list,objectName(),QString(),true,true);
            if (target){
                room->setPlayerFlag(target,"lichang_target");
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target;
        foreach(ServerPlayer *p, room->getAlivePlayers()){
            if (p->isFriendWith(player)&&p->getJudgingArea().length()>0&&p->hasFlag("lichang_target"))
                target = p;
                room->setPlayerFlag(p,"-lichang_target");
        }
        if (!target)
            return false;
        int id = room->askForCardChosen(player,target,"j",objectName());
        room->throwCard(id,target,player);
        room->broadcastSkillInvoke(objectName(), player);
        Card *jink = Sanguosha->cloneCard("jink",Card::NoSuit,0);
        jink->setSkillName(objectName());
        room->provide(jink);
        return false;
    }
};

class Baonu : public PhaseChangeSkill
{
public:
    Baonu() : PhaseChangeSkill("baonu")
    {
        frequency = NotFrequent;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *shizuo, QVariant &, ServerPlayer* &) const
    {
        return (PhaseChangeSkill::triggerable(shizuo) && shizuo->getPhase() == Player::Draw) ? QStringList(objectName()) : QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *shizuo, QVariant &, ServerPlayer *) const
    {
        if (shizuo->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), shizuo);
            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *shizuo) const
    {
        Room *room = shizuo->getRoom();
        room->loseHp(shizuo);
        room->setPlayerFlag(shizuo, "baonu_used");
        shizuo->drawCards(shizuo->getLostHp());
        return false;
    }
};

JizhanCard::JizhanCard()
{
    will_throw=false;
}

bool JizhanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select != Self && targets.length() == 0 && Self->inMyAttackRange(to_select);
}

void JizhanCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (!target)
        return;
    room->obtainCard(target, this);
    DamageStruct da;
    da.from=player;
    da.to=target;
    da.damage=1;
    room->damage(da);
}

class Jizhan : public OneCardViewAsSkill
{
public:
    Jizhan() : OneCardViewAsSkill("jizhan"){

    }

    bool viewFilter(const Card *card) const
    {
        return true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        JizhanCard *card = new JizhanCard();
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("JizhanCard") && player->hasFlag("baonu_used");
    }
};

HeiyanCard::HeiyanCard()
{
}

bool HeiyanCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select != Self && targets.length() == 0;
}

void HeiyanCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (!target)
        return;
    room->loseHp(player);
    DamageStruct flame;
    flame.from=player;
    flame.to=target;
    flame.damage=1;
    flame.nature=DamageStruct::Fire;
    room->doLightbox("luablackflame$", 1000);
    room->damage(flame);
}

class Heiyan : public ZeroCardViewAsSkill
{
public:
    Heiyan() : ZeroCardViewAsSkill("heiyan")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("HeiyanCard");
    }

    const Card *viewAs() const
    {
        HeiyanCard *vs = new HeiyanCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Tianran : public TriggerSkill
{
public:
    Tianran() : TriggerSkill("tianran")
    {
        frequency = Compulsory;
        events << CardUsed << CardsMoveOneTime<< TargetConfirming;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player))
            return QStringList();
        /*if (event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card != NULL && use.card->isKindOf("EquipCard") && player->getEquips().length()>0) {

                    return QStringList(objectName());

            }
        }*/
        if(event == CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
                && !(move.to == player && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip))&&(move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD) {
                return QStringList(objectName());
            }
        }
        else if (event == TargetConfirming){
            CardUseStruct use = data.value<CardUseStruct>();

            if (use.card != NULL && use.card->isKindOf("EquipCard") && player->getEquips().length()>0) {

                    return QStringList(objectName());

            }

            if (use.card != NULL && use.card->getSubtype()=="single_target_trick" && !player->isKongcheng() && use.from!=player) {

                    return QStringList(objectName());

            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==CardUsed && (player->hasShownSkill(this) || player->askForSkillInvoke(this, data))) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        if (event == CardsMoveOneTime && (player->hasShownSkill(this) || player->askForSkillInvoke(this, data))){
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        if (event == TargetConfirming && (player->hasShownSkill(this) || player->askForSkillInvoke(this, data))){
            CardUseStruct use = data.value<CardUseStruct>();

            if (use.card->isKindOf("EquipCard")) {

                    return true;

            }

            if (use.card->getSubtype()=="single_target_trick") {

                bool discard=room->askForDiscard(player,objectName(),1,1,true,false,QString());
                if (discard){
                    room->broadcastSkillInvoke(objectName(), player);
                    return true;
                }

            }

        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==TargetConfirming){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("EquipCard") && player->getEquips().length()>0) {
               int id = room->askForCardChosen(player, player, "e", objectName());
               room->throwCard(id, player, player);
            }
        }
        if (event==CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            foreach(auto p, room->getOtherPlayers(player)){
                if (p->isFriendWith(player)){
                    QString choice = room->askForChoice(p, objectName(), "tianran_obtaincards+cancel", data);
                    if (choice=="tianran_obtaincards"){
                        DummyCard dummy(move.card_ids);
                        p->obtainCard(&dummy);
                        break;
                    }
                    else{
                        room->setPlayerFlag(p, "tianran_cancel");
                    }
                }
            }
            foreach(auto p, room->getAlivePlayers()){
               room->setPlayerFlag(p, "-tianran_cancel");
            }
        }
        return false;
    }
};

LiaoliCard::LiaoliCard()
{
}


bool LiaoliCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty();
}

void LiaoliCard::onEffect(const CardEffectStruct &effect) const
{

   RecoverStruct recover;
   recover.card = this;
   recover.who = effect.from;
   effect.to->getRoom()->recover(effect.to, recover);

   if ( effect.to->getHp() == effect.to->getMaxHp() )
           {
                 int upper = effect.to->getMaxHp();
                 int x = upper - effect.to->getHandcardNum();
                 if (x > 0)
                 effect.to->drawCards(x);
           }

}

class Liaoli : public OneCardViewAsSkill
{
public:
    Liaoli() : OneCardViewAsSkill("liaoli")
    {
        filter_pattern = "BasicCard|red|.|hand!";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "h") && !player->hasUsed("LiaoliCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        LiaoliCard *liaoli_card = new LiaoliCard;
        liaoli_card->addSubcard(originalCard->getId());
        liaoli_card->setShowSkill(objectName());
        return liaoli_card;
    }
};

class Wangxiang : public OneCardViewAsSkill
{
public:
    Wangxiang() : OneCardViewAsSkill("wangxiang"){
        relate_to_place="deputy";
        guhuo_type="s";
    }

    bool viewFilter(const Card *card) const
    {
        return card->isKindOf("BasicCard")&&card->isBlack();
    }

    const Card *viewAs(const Card *originalCard) const
    {
        QString pattern=Self->tag[objectName()].toString();
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
        return !player->hasUsed("ViewAsSkill_wangxiangCard");
    }
};

class Wangxiangeffect : public TriggerSkill
{
public:
    Wangxiangeffect() : TriggerSkill("wangxiangeffect")
    {
        events <<CardUsed;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use=data.value<CardUseStruct>();
        if (use.card->getSkillName()=="wangxiang"){
            room->setPlayerFlag(use.from,"wangxiang_used");
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Wucun : public TriggerSkill
{
public:
    Wucun() : TriggerSkill("wucun")
    {
        events << EventPhaseStart;
        frequency = NotFrequent;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player != NULL && player->isAlive() && player->getPhase() == Player::Start)
        {
            QList<ServerPlayer *> akaris = room->findPlayersBySkillName(objectName());
            LureTiger *luretiger = new LureTiger(Card::SuitToBeDecided, 0);
            luretiger->setSkillName(objectName());
            QList<const Player *> targets;
            luretiger->deleteLater();
            foreach (ServerPlayer *akari, akaris)
            {
                int max = 0;
                foreach (auto p, room->getOtherPlayers(akari))
                {
                    max = qMax(max, p->getHandcardNum());
                }

                if (akari != player && akari->getHandcardNum() < max && ((akari->hasShownAllGenerals() && akari->hasShownSkill(this))
                    || (!akari->hasShownSkill(this) && luretiger->targetFilter(targets, akari, player) && !player->isProhibited(akari, luretiger, targets))))
                {
                    skill_list.insert(akari, QStringList(objectName()));
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (ask_who->hasShownSkill(this))
        {
            if (ask_who->askForSkillInvoke(this, QVariant::fromValue(player)))
            {
                room->setPlayerFlag(ask_who, "wucun_tohide");
                room->broadcastSkillInvoke(objectName(), ask_who);
                return true;
            }
        }
        else
        {
            if (ask_who->askForSkillInvoke(this, QVariant::fromValue(player)))
            {
                room->setPlayerFlag(ask_who, "wucun_toshow");
                room->broadcastSkillInvoke(objectName(), ask_who);
                return true;
            }
        }
        room->setPlayerFlag(ask_who, "-wucun_tohide");
        room->setPlayerFlag(ask_who, "-wucun_toshow");
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *ask_who) const
    {
        if (ask_who->hasFlag("wucun_tohide"))
        {
            ask_who->hideGeneral(ask_who->inHeadSkills(this));
        }
        else if (player->isAlive() && ask_who->hasFlag("wucun_toshow"))
        {
            LureTiger *luretiger = new LureTiger(Card::SuitToBeDecided, 0);
            luretiger->setSkillName(objectName());
            QList<const Player *> targets;
            if (luretiger->targetFilter(targets, ask_who, player) && !player->isProhibited(ask_who, luretiger, targets))
                room->useCard(CardUseStruct(luretiger, player, ask_who));
        }

        ask_who->drawCards(1, objectName());

        room->setPlayerFlag(ask_who, "-wucun_tohide");
        room->setPlayerFlag(ask_who, "-wucun_toshow");
        return false;
    }
};

class Kongni : public TriggerSkill
{
public:
    Kongni() : TriggerSkill("kongni")
    {
        events << SlashEffected;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player))
            return QStringList();
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        if ((effect.slash->isBlack() && player->getEquips().length() == 0) || (effect.slash->isRed() && player->getEquips().length() > 0))
            return QStringList(objectName());

        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool invoke = player->hasShownSkill(this) ? true : player->askForSkillInvoke(objectName(), data);
        if (invoke)
        {
            if (player->hasShownSkill(this))
            {
                SlashEffectStruct effect = data.value<SlashEffectStruct>();
                LogMessage log;
                log.type = "#SkillNullify";
                log.from = player;
                log.arg = objectName();
                log.arg2 = effect.slash->objectName();
                room->sendLog(log);
            }
            room->broadcastSkillInvoke(objectName());
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *) const
    {
        return true;
    }
};

TiaojiaoCard::TiaojiaoCard()
{
    mute = true;
}

bool TiaojiaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (targets.length()>=2) return false;
    if (targets.isEmpty()) return to_select != Self && Self->inMyAttackRange(to_select);
    if (targets.length()==1) return targets.at(0)->inMyAttackRange(to_select) && to_select!=targets.at(0);
}

bool TiaojiaoCard::targetsFeasible(const QList<const Player *> &targets, const Player *) const
{
    return targets.length() == 2;
}

void TiaojiaoCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *tsukushi = card_use.from;

    LogMessage log;
    log.from = tsukushi;
    log.to << card_use.to;
    log.type = "#UseCard";
    log.card_str = toString();
    room->sendLog(log);

    QVariant data = QVariant::fromValue(card_use);
    RoomThread *thread = room->getThread();

    thread->trigger(PreCardUsed, room, tsukushi, data);
    room->broadcastSkillInvoke("tiaojiao", tsukushi);


    if (tsukushi->ownSkill("tiaojiao") && !tsukushi->hasShownSkill("tiaojiao"))
        tsukushi->showGeneral(tsukushi->inHeadSkills("tiaojiao"));

    thread->trigger(CardUsed, room, tsukushi, data);
    thread->trigger(CardFinished, room, tsukushi, data);
}

void TiaojiaoCard::use(Room *room, ServerPlayer *tsukushi, QList<ServerPlayer *> &targets) const
{
    if (targets.length()<=1)
        return;
    ServerPlayer *target = targets.at(0);
    ServerPlayer *slashTarget = targets.at(1);
    QList<ServerPlayer *> list;
    //ServerPlayer *slashTarget = room->askForPlayerChosen(tsukushi, list, "tiaojiao", QString(), true);
    if (slashTarget && !room->askForUseSlashTo(target, slashTarget, "@TiaojiaoSlash:" + tsukushi->getGeneralName() + ":" + target->getGeneralName() + ":" + slashTarget->getGeneralName(), false)){
        if (!target->isNude()){
            room->obtainCard(tsukushi, room->askForCardChosen(tsukushi, target, "hej", objectName()), false);
        }
    }
}

class Tiaojiao : public ZeroCardViewAsSkill
{
public:
    Tiaojiao() : ZeroCardViewAsSkill("tiaojiao")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("TiaojiaoCard");
    }

    const Card *viewAs() const
    {
        TiaojiaoCard *vs = new TiaojiaoCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Gangqu : public TriggerSkill
{
public:
    Gangqu() : TriggerSkill("gangqu")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << CardEffected;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==EventPhaseStart && TriggerSkill::triggerable(player)&&player->getPhase() == Player::Finish&&!player->isKongcheng() && player->getPile("gang").length() == 0){
            return QStringList(objectName());
        }
        else if (event==EventPhaseStart && TriggerSkill::triggerable(player)&&player->getPhase() == Player::Start && player->getPile("gang").length() > 0){
            if (player->getPile("gang").length() == 1){
                room->obtainCard(player, player->getPile("gang").first());
            }
            else{
                room->fillAG(player->getPile("gang"), player);
                room->obtainCard(player, room->askForAG(player, player->getPile("gang"), false, objectName()));
                room->clearAG(player);
            }
        }
        else if (event==CardEffected){
            CardEffectStruct effect = data.value<CardEffectStruct>();
            if (TriggerSkill::triggerable(player) && effect.to == player && player->getPile("gang").length() > 0 && effect.card->getTypeId()!= Card::TypeSkill &&effect.card->getSuit() == (Sanguosha->getCard(player->getPile("gang").first()))->getSuit()){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseStart){
            player->addToPile("gang", room->askForCardChosen(player, player, "h", objectName()));
        }
        else{
            room->broadcastSkillInvoke(objectName());
            room->doLightbox(objectName() + "$", 800);
            return true;
        }
        return false;
    }
};

class GangquClear : public DetachEffectSkill
{
public:
    GangquClear() : DetachEffectSkill("gangqu", "gang")
    {
        frequency = Compulsory;
    }
};

class Xieyan : public TriggerSkill
{
public:
    Xieyan() : TriggerSkill("xieyan")
    {
        frequency = Frequent;
        events << Damage;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)&&(!room->getCurrent()||!room->getCurrent()->hasFlag("xieyan_used"+player->objectName()))){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(damage.to))) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (room->getCurrent()){
            room->setPlayerFlag(room->getCurrent(),"xieyan_used"+player->objectName());
        }
        DamageStruct damage=data.value<DamageStruct>();
        if (damage.to->hasShownAllGenerals()){
            player->drawCards(1);
        }
        else{
            bool show=damage.to->askForGeneralShow(true,true);
            if (!show&&!damage.to->isNude()){
                int id = room->askForCardChosen(player,damage.to,"he",objectName());
                room->obtainCard(player, id, false);
            }
        }
        return false;
    }
};

class Sandun : public TriggerSkill
{
public:
    Sandun() : TriggerSkill("sandun")
    {
        relate_to_place="deputy",
        frequency = Frequent;
        events << TargetConfirmed <<EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (event== TargetConfirmed && TriggerSkill::triggerable(player) && use.card->isKindOf("Slash") && !player->getArmor() && use.to.contains(player) && !player->isNude()){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            bool discard=room->askForDiscard(player,objectName(),1,1,true,true,QString(),true);
            if (!discard)
                return false;
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QStringList stringlist=player->property("sandun").toStringList();
        QList<int> list;
        foreach(int id,room->getDrawPile()){
            const Card *card=Sanguosha->getCard(id);
            if (card->isKindOf("Armor"))
                list.append(id);
        }
        if (list.length()==0){
            return false;
        }
        room->fillAG(list,player);
        int id=room->askForAG(player,list,false,objectName());
        room->clearAG();
        room->useCard(CardUseStruct(Sanguosha->getCard(id), player, player));
        stringlist.append(Sanguosha->getCard(id)->objectName());
        player->setProperty("sandun",QVariant(stringlist));
        return false;
    }
};

class Sanduneffect : public TriggerSkill
{
public:
    Sanduneffect() : TriggerSkill("sanduneffect")
    {
        events <<EventPhaseEnd;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==EventPhaseEnd && room->getCurrent()->getPhase()==Player::Finish) {
           foreach(ServerPlayer *p, room->getAlivePlayers()){
               if (p->getArmor()&&p->property("sandun").toStringList().contains(p->getArmor()->objectName())){
                   room->obtainCard(p,p->getArmor());
               }
               QStringList list=p->property("sandun").toStringList();
               list.clear();
               p->setProperty("sandun",QVariant(list));
           }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Zhonger : public TriggerSkill
{
public:
    Zhonger() : TriggerSkill("zhonger")
    {
        relate_to_place="head",
        frequency = Frequent;
        events << CardUsed;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player)&& use.card->isKindOf("TrickCard")&&use.card->isBlack()&&(!room->getCurrent()||!room->getCurrent()->hasFlag("zhonger_used"+player->objectName()))){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        player->drawCards(1);
    }
};

class ZhongerTargetMod : public TargetModSkill
{
public:
    ZhongerTargetMod() : TargetModSkill("#zhonger-target")
    {
        pattern = "TrickCard";
    }

    virtual int getExtraTargetNum(const Player *from, const Card *card) const
    {
        if (card->isNDTrick()&&card->isBlack()&&from->hasShownSkill("zhonger"))
            return 1;
        else
            return 0;
    }

};

class Zhudao : public TriggerSkill
{
public:
    Zhudao() : TriggerSkill("zhudao")
    {
        frequency = Frequent;
        events << CardsMoveOneTime;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (TriggerSkill::triggerable(player)&&move.from&&move.from->objectName()==player->objectName()&&move.from_places.contains(Player::PlaceEquip)){
            return QStringList(objectName());
        }
        return QStringList();
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
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        room->broadcastSkillInvoke(objectName(), player);
        room->doLightbox("Zhudao$", 800);
        ServerPlayer *from=room->askForPlayerChosen(player, room->getAlivePlayers(), "Laiyuan");
        if (!from->isAllNude()){
            int id=room->askForCardChosen(player, from, "hej", objectName());
            if (id!=-1){
                Card *card=Sanguosha->getCard(id);
                room->setPlayerProperty(from, "zhudao_id", QVariant(id+1));
                Player::Place place = room->getCardPlace(id);
                int i=-1;
                if (place == Player::PlaceEquip){
                    if (card->isKindOf("Weapon")){
                        i=1;
                    }
                    if (card->isKindOf("Armor")){
                        i=2;
                    }
                    if (card->isKindOf("DefensiveHorse")){
                        i=3;
                    }
                    if (card->isKindOf("OffensiveHorse")){
                        i=4;
                    }
                    if (card->isKindOf("Treasure")){
                        i=5;
                    }
                }
                QList<ServerPlayer *> tos;
                foreach(ServerPlayer *p,room->getAlivePlayers()){
                    if (i!=-1){
                        if (i==1&&!p->getWeapon()){
                            tos.append(p);
                        }
                        if (i==2&&!p->getArmor()){
                            tos.append(p);
                        }
                        if (i==3&&!p->getDefensiveHorse()){
                            tos.append(p);
                        }
                        if (i==4&&!p->getOffensiveHorse()){
                            tos.append(p);
                        }
                        if (i==5&&!p->getTreasure()){
                            tos.append(p);
                        }
                    }
                    else if (place == Player::PlaceHand){
                        tos.append(p);
                    }
                    else if(!player->isProhibited(p,card)&&!p->containsTrick(card->objectName())){
                        tos.append(p);
                    }
                }
                if (tos.length()>0){
                    ServerPlayer *to=room->askForPlayerChosen(player, tos, "Quxiang");
                    if (to){
                        CardMoveReason reason=CardMoveReason(CardMoveReason::S_REASON_TRANSFER,player->objectName(),objectName(),"");
                        room->moveCardTo(card,from,to,place,reason);
                    }
                }
                room->setPlayerProperty(from, "zhudao_id", QVariant());
            }
        }
        room->setPlayerProperty(player,"faceup",QVariant(true));
        return false;
    }
};

class Sixu : public TriggerSkill
{
public:
    Sixu() : TriggerSkill("sixu")
    {
        frequency = NotFrequent;
        events << EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)&&player->getPhase()==Player::Play){
            return QStringList(objectName());
        }
        return QStringList();
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
        room->broadcastSkillInvoke(objectName(), player);
        QList<ServerPlayer *> list = room->getAlivePlayers();
        for(int i=1;i<=2;i++){
            ServerPlayer *from=room->askForPlayerChosen(player, list, "Laiyuan");
            if (from){
                list.removeOne(from);
            }
            if (!from->isAllNude()){
                int id=room->askForCardChosen(player, from, "hej", objectName());
                if (id!=-1){
                    Card *card=Sanguosha->getCard(id);
                    room->setPlayerProperty(from, "zhudao_id", QVariant(id+1));
                    Player::Place place = room->getCardPlace(id);
                    int i=-1;
                    if (place == Player::PlaceEquip){
                        if (card->isKindOf("Weapon")){
                            i=1;
                        }
                        if (card->isKindOf("Armor")){
                            i=2;
                        }
                        if (card->isKindOf("DefensiveHorse")){
                            i=3;
                        }
                        if (card->isKindOf("OffensiveHorse")){
                            i=4;
                        }
                        if (card->isKindOf("Treasure")){
                            i=5;
                        }
                    }
                    QList<ServerPlayer *> tos;
                    foreach(ServerPlayer *p,room->getAlivePlayers()){
                        if (i!=-1){
                            if (i==1&&!p->getWeapon()){
                                tos.append(p);
                            }
                            if (i==2&&!p->getArmor()){
                                tos.append(p);
                            }
                            if (i==3&&!p->getDefensiveHorse()){
                                tos.append(p);
                            }
                            if (i==4&&!p->getOffensiveHorse()){
                                tos.append(p);
                            }
                            if (i==5&&!p->getTreasure()){
                                tos.append(p);
                            }
                        }
                        else if (place == Player::PlaceHand){
                            tos.append(p);
                        }
                        else if(!player->isProhibited(p,card)&&!p->containsTrick(card->objectName())){
                            tos.append(p);
                        }
                    }
                    if (tos.length()==0){
                        continue;
                    }
                    ServerPlayer *to=room->askForPlayerChosen(player, tos, "Quxiang");
                    if (to){
                        CardMoveReason reason=CardMoveReason(CardMoveReason::S_REASON_TRANSFER,player->objectName(),objectName(),"");
                        room->moveCardTo(card,from,to,place,reason);
                    }
                    room->setPlayerProperty(from, "zhudao_id", QVariant(id+1));
                }
            }
        }
        player->turnOver();
        room->setPlayerFlag(player,"sixu_used");
        return false;
    }
};

class SixuMax : public MaxCardsSkill
{
public:
    SixuMax() : MaxCardsSkill("sixumax")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->hasFlag("sixu_used")){
            return 1;
        }
        return 0;
    }
};

class Zishang : public TriggerSkill
{
public:
    Zishang() : TriggerSkill("zishang")
    {
        frequency = NotFrequent;
        events << DamageCaused;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        DamageStruct damage = data.value<DamageStruct>();
        if (player == NULL) return skill_list;
        QList<ServerPlayer *> hikigayas = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *hikigaya, hikigayas) {
            if (hikigaya!=damage.to)
                skill_list.insert(hikigaya, QStringList(objectName()));
        }
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *hikigaya = ask_who;
        if (damage.to && hikigaya &&hikigaya->askForSkillInvoke(this, QVariant::fromValue(damage.to))) {
            room->broadcastSkillInvoke(objectName(), hikigaya);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *hikigaya = ask_who;
        if (!hikigaya)
            return false;
        room->doLightbox("SE_Zishang$", 1000);
        damage.to=hikigaya;
        data.setValue(damage);
        QList<ServerPlayer *> targets;
        foreach(ServerPlayer *p, room->getAlivePlayers()){
            if (p->isFriendWith(hikigaya)){
                targets.append(p);
            }
        }
        ServerPlayer *target = room->askForPlayerChosen(hikigaya,targets,objectName(),QString(),true);
        if (target){
            target->drawCards(1);
        }
        return false;
    }
};

class Zibi : public TriggerSkill
{
public:
    Zibi() : TriggerSkill("zibi")
    {
        frequency = Frequent;
        events << CardUsed << EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==CardUsed && player->getPhase()==Player::Play){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("BasicCard")||use.card->isKindOf("TrickCard")||use.card->isKindOf("EquipCard")){
                if (!use.to.contains(player)||use.to.length()>1){
                    room->setPlayerMark(player,"Zibi_not",1);
                    return QStringList();
                }
            }
        }
        if (event==EventPhaseEnd && TriggerSkill::triggerable(player) &&player->getMark("Zibi_not")==0 && player->getPhase()==Player::Finish) {
            return QStringList(objectName());
        }
        else if (event==EventPhaseEnd &&player->getMark("Zibi_not")>0 && player->getPhase()==Player::Finish){
            room->setPlayerMark(player,"Zibi_not",0);
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseEnd && player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseEnd){
            if (player->getMark("Zibi_not")==0){
                QStringList choices;
                choices << "SE_Zibi_D";
                bool min=true;
                foreach (ServerPlayer *p, room->getOtherPlayers(player)) {
                    if (p->getHp()<=player->getHp())
                        min=false;
                }
                if (min==true){
                    choices << "SE_Zibi_R";
                }
                QString choice = room->askForChoice(player, objectName(),choices.join("+"));
                if (choice=="SE_Zibi_R"){
                    RecoverStruct recover;
                    recover.recover = 1;
                    recover.who = player;
                    room->recover(player, recover, true);
                }
                else{
                     player->drawCards(1);
                }
            }
        }
        return false;
    }
};

class Wenchang : public TriggerSkill
{
public:
    Wenchang() : TriggerSkill("wenchang")
    {
        events << Damaged;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        if (triggerEvent == Damaged) {
            DamageStruct damage = data.value<DamageStruct>();
            if ( damage.to->isDead())
                return skill_list;

            QList<ServerPlayer *> yyuis = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *yyui, yyuis)
                if (yyui->canDiscard(yyui, "he") && !yyui->isNude())
                    skill_list.insert(yyui, QStringList(objectName()));
            return skill_list;
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *yyui = ask_who;

        if (yyui != NULL) {
            yyui->tag["wenchang_data"] = data;
            bool invoke = room->askForDiscard(yyui, objectName(), 1, 1, true, true, "@wenchang:" + player->objectName(), true);
            yyui->tag.remove("wenchang_data");

            if (invoke) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, yyui->objectName(), data.value<DamageStruct>().to->objectName());
                room->broadcastSkillInvoke(objectName(), yyui);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *yyui = ask_who;
        if (yyui == NULL) return false;
        DamageStruct damage = data.value<DamageStruct>();


        room->broadcastSkillInvoke(objectName());
        QList<int> ids = room->getNCards(1, false);
        const Card *card = Sanguosha->getCard(ids.first());
        room->obtainCard(player, card, false);
        room->showCard(player, ids.first());
        if(card->isRed())
        {
            RecoverStruct recover;
            recover.who = yyui;
            room->recover(player, recover, true);
        }
        return false;
    }
};

class Yuanxin : public TriggerSkill
{
public:
    Yuanxin() : TriggerSkill("yuanxin")
    {
        frequency = NotFrequent;
        events << DamageInflicted;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        DamageStruct damage = data.value<DamageStruct>();
        if (player == NULL  || damage.damage < 2  ) return skill_list;
        QList<ServerPlayer *> yyuis = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *yyui, yyuis) {
            if (room->getCurrent()==NULL || !room->getCurrent()->hasFlag(yyui->objectName()+"yuanxin")){
                skill_list.insert(yyui, QStringList(objectName()));
            }
        }
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *yyui = ask_who;
        if (damage.to && yyui &&yyui->askForSkillInvoke(this, QVariant::fromValue(player))) {
            room->broadcastSkillInvoke(objectName(), yyui);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (room->getCurrent()!=NULL){
          room->setPlayerFlag(room->getCurrent(),ask_who->objectName()+"yuanxin");
        }
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *yyui = ask_who;
        room->doLightbox("se_yuanxin$", 1500);
        damage.damage -= 1;
        data.setValue(damage);
        room->damage(DamageStruct("yuanxin", damage.from, yyui));
        return false;
    }
};

//magic

DuanzuiCard::DuanzuiCard()
{
    will_throw = false;
    mute = true;
}

bool DuanzuiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    FireSlash *s = new FireSlash(Card::NoSuit, 0);
    int ex = 0;
    foreach(auto sk, Sanguosha->getTargetModSkills()){
        if (sk->getExtraTargetNum(Self, s)>0)
            ex = ex+sk->getExtraTargetNum(Self, s);
    }

    return targets.length() <= ex && !Self->isProhibited(to_select, s) && Self != to_select;
}

void DuanzuiCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    Card *sub = Sanguosha->getCard(this->getSubcards().at(0));
    Card *card = Sanguosha->cloneCard("fire_slash",sub->getSuit(), sub->getNumber());
    card->setSkillName("duanzui");
    card->setShowSkill("duanzui");
    card->addSubcard(sub);
    room->useCard(CardUseStruct(card, card_use.from, card_use.to), false);
}

class Duanzui : public ViewAsSkill
{
public:
    Duanzui() :ViewAsSkill("duanzui")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("DuanzuiCard")&&player->hasSkill(objectName());
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() == 0 && to_select->isRed();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        DuanzuiCard *vs = new DuanzuiCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        vs->addSubcards(cards);
        return vs;
    }
};

class Tianhuo : public TriggerSkill
{
public:
    Tianhuo() : TriggerSkill("tianhuo")
    {
        frequency = Frequent;
        events << DamageCaused << DamageInflicted;
    }

    int getPriority(TriggerEvent) const
    {
        return 2;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DamageStruct damage=data.value<DamageStruct>();
        if (TriggerSkill::triggerable(player) && damage.nature==DamageStruct::Fire && (event==DamageInflicted || !player->hasFlag("tianhuo_used3"))) {
             return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==DamageCaused){
            room->broadcastSkillInvoke(objectName(),1,player);
            if (player->getPhase()!=Player::NotActive){
                if (!player->hasFlag("tianhuo_used")){
                  room->setPlayerFlag(player,"tianhuo_used");
                }
                else if(!player->hasFlag("tianhuo_used2")){
                    room->setPlayerFlag(player,"tianhuo_used2");
                }
                else{
                    room->setPlayerFlag(player,"tianhuo_used3");
                }
            }
            player->drawCards(1);
        }
        else{
            room->broadcastSkillInvoke(objectName(),2,player);
            player->drawCards(1);
            return true;
        }
        return false;
    }
};

MojuCard::MojuCard()
{
    will_throw = false;
}

bool MojuCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (Self->getEquips().contains(Sanguosha->getCard(this->getEffectiveId()))){
        return targets.length() == 0 && to_select != Self;
    }
    return targets.length() == 0;
}

void MojuCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (!target)
        return;

    int card_id = this->getSubcards().at(0);
    if (card_id == -1)
        return;
    Card *card = Sanguosha->getCard(card_id);
    room->moveCardTo(card, target, Player::PlaceEquip);
    QList<ServerPlayer *> players;
    foreach(ServerPlayer *p, room->getAlivePlayers()){
        foreach(const Card *c, p->getEquips()){
            if (c->getSuit() == card->getSuit()){
                players.append(p);
                break;
            }
        }
        if (!players.contains(p)){
            foreach(const Card *c, p->getJudgingArea()){
                if (c->getSuit() == card->getSuit()){
                    players.append(p);
                    break;
                }
            }
        }
    }
    if (players.count() == 0){
        return;
    }
    ServerPlayer *from = room->askForPlayerChosen(source, players, "moju", "@moju-from:::" + card->getSuitString());
    QList<int> disabled;
    foreach(const Card *c, from->getEquips()){
        if (c->getSuit() != card->getSuit()){
            disabled.append(c->getEffectiveId());
        }
    }
    foreach(const Card *c, from->getJudgingArea()){
        if (c->getSuit() != card->getSuit()){
            disabled.append(c->getEffectiveId());
        }
    }
    int from_id = room->askForCardChosen(source, from, "ej", objectName(), false, Card::MethodNone, disabled);
    Player::Place place = room->getCardPlace(from_id);
    const Card *from_card = Sanguosha->getCard(from_id);
    QList<ServerPlayer *> tos;

    int equip_index = -1;
    if (place == Player::PlaceEquip){
        const EquipCard *equip = qobject_cast<const EquipCard *>(from_card->getRealCard());
        equip_index = static_cast<int>(equip->location());
    }
    foreach(ServerPlayer *p, room->getOtherPlayers(from)){
        if (equip_index != -1) {
            if (p->getEquip(equip_index) == NULL)
                tos << p;
        }
        else {
            if (!source->isProhibited(p, from_card) && !p->containsTrick(from_card->objectName()))
                tos << p;
        }
    }
    ServerPlayer *to = room->askForPlayerChosen(source, tos, "moju_to", "@moju-to:::" + from_card->objectName());
    if (to)
        room->moveCardTo(from_card, from, to, place,
        CardMoveReason(CardMoveReason::S_REASON_TRANSFER,
        source->objectName(), "moju", QString()));
}

class Moju : public OneCardViewAsSkill
{
public:
    Moju() : OneCardViewAsSkill("moju"){

    }

    bool viewFilter(const Card *card) const
    {
        return card->isKindOf("EquipCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        MojuCard *mjc = new MojuCard();
        mjc->addSubcard(originalCard);
        mjc->setSkillName("moju");
        mjc->setShowSkill(objectName());
        return mjc;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MojuCard");
    }
};

class Jiejie : public TriggerSkill
{
public:
    Jiejie() : TriggerSkill("jiejie")
    {
        frequency = Frequent;
        events << DamageInflicted;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        QList<ServerPlayer *> hakazes = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *hakaze, hakazes) {
            if (hakaze->isFriendWith(player))
                skill_list.insert(hakaze, QStringList(objectName()));
        }
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *hakaze = ask_who;
        if (damage.to && hakaze && !room->getCurrent()->hasFlag(hakaze->objectName()+"jiejie_used")&&hakaze->askForSkillInvoke(this, QVariant::fromValue(player))) {
            room->getCurrent()->setFlags(hakaze->objectName()+"jiejie_used");
            room->broadcastSkillInvoke(objectName(), hakaze);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *hakaze = ask_who;
        if (!hakaze)
            return false;
        LogMessage log;
        log.type = "$jiejie_asked";
        log.from = hakaze;
        log.to.append(damage.to);
        room->sendLog(log);
        //room->getCurrent()->setFlags(hakaze->objectName()+"jiejie_used");
        int p = damage.to->getLostHp();
        if (p <= 0) {
            p = 1;
        }
        QList<int> card_ids = room->getNCards(p, false);
        room->fillAG(card_ids, hakaze);
        int id = room->askForAG(hakaze, card_ids, false, objectName());
        room->clearAG(hakaze);
        room->showCard(hakaze, id);
        room->obtainCard(hakaze, id);
        if (id != -1){
            const Card *card = Sanguosha->getCard(id);
            QList<int> ids;
            foreach(const Card* c, damage.to->getEquips()){
                if (card->getColor() == c->getColor()){
                    ids.append(c->getEffectiveId());
                }
            }
            if (ids.length()>0){
                room->fillAG(ids, hakaze);
                int id = room->askForAG(hakaze, ids, false, objectName());
                room->throwCard(id,damage.to,hakaze);
                room->clearAG(hakaze);
                room->doLightbox(objectName() + "$", 800);
                room->setEmotion(damage.to, "shield");
                if (damage.damage > 1){
                    damage.damage -= 1;
                    data.setValue(damage);
                }
                else{
                    return true;
                }
            }
        }
        return false;
    }
};


ShengjianCard::ShengjianCard()
{
    will_throw = false;
}

bool ShengjianCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    /*foreach(const Player *p, targets){
        if (to_select->isFriendWith(p)){
            return false;
        }
    }*/
    return targets.length()<Self->getAttackRange();
}

void ShengjianCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    if (targets.length() >= 3){
        room->doLightbox("se_shengjian$", 3000);
    }
    /*foreach(ServerPlayer *p, targets){
        if (p->getEquips().length()>0){
            int id=room->askForCardChosen(player,p,"e",objectName());
            room->throwCard(id,p,player);
        }
    }*/
    Slash *slash = new Slash(Suit::NoSuit,-1);
    slash->setSkillName("shengjian");
    room->useCard(CardUseStruct(slash, player, targets),false);
}

class Shengjianvs : public ZeroCardViewAsSkill
{
public:
    Shengjianvs() : ZeroCardViewAsSkill("shengjian")
    {
        response_pattern = "@@shengjian";
    }

    const Card *viewAs() const
    {
        ShengjianCard *vs = new ShengjianCard();
        vs->setSkillName(objectName());
        return vs;
    }
};

class Shengjian : public TriggerSkill
{
public:
    Shengjian() : TriggerSkill("shengjian")
    {
        frequency = NotFrequent;
        events << EventPhaseChanging << EventPhaseEnd << SlashProceed << Damage;
        view_as_skill= new Shengjianvs;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

     virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->getSkillName()=="shengjian"){
                if (damage.to->getEquips().length()>0){
                    int id=room->askForCardChosen(player,damage.to,"e",objectName());
                    room->throwCard(id,damage.to,player);
                }
            }
        }

    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == EventPhaseChanging){
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (TriggerSkill::triggerable(player) &&!player->isSkipped(Player::Play)&& change.to==Player::Play ) {
                 return QStringList(objectName());
            }
        }
        else if(event == EventPhaseEnd){
            if (player->getPhase()==Player::Finish){
               room->setPlayerMark(player, "shengjian_range", 0);
            }
        }
        else if (event == SlashProceed) {
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
            if (effect.from && effect.to && effect.slash->getSkillName()=="shengjian" && effect.to->getEquips().length()<effect.from->getEquips().length()){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == EventPhaseChanging && player->askForSkillInvoke(this, data)) {
            return true;
        }
        else if (event == SlashProceed){
            return true;
        }
        return false;
    }


    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event == EventPhaseChanging){
            if (room->askForUseCard(player,"@@shengjian","@shengjian")){
                player->skip(Player::Play);
            }
        }
        else
        {
            SlashEffectStruct effect = data.value<SlashEffectStruct>();
             room->slashResult(effect, NULL);
             return true;
        }
        /*if (player->getAttackRange()>1){
            if (room->askForUseCard(player,"@@shengjian","@shengjian")){
                player->skip(Player::Play);
            }
        }
        else{
            const Card *card = room->askForCard(player, ".|.|.|.", "@shengjian", QVariant::fromValue(player));
            if (card) {
              room->setPlayerMark(player, "shengjian_range", (card->getNumber()+card->getNumber()%2)/2);
            }
        }*/
        return false;
    }
};

class ShengjianRange : public AttackRangeSkill
{
public:
    ShengjianRange() : AttackRangeSkill("#shengjianrange")
    {
    }

    virtual int getFixed(const Player *target, bool include_weapon) const
    {
        if (target->hasShownSkill("shengjian") && !target->getWeapon()) {
            return 2;
        }
        return -1;
    }
};

class Wangzhe : public MaxCardsSkill
{
public:
    Wangzhe() : MaxCardsSkill("wangzhe")
    {
        relate_to_place = "head";
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        int n=0;
        Room *room=target->getRoom();
        foreach(ServerPlayer *p, room->getAlivePlayers()){
            if (p->isFriendWith(target)&&p->hasShownSkill(objectName())){
                n=n+(p->getLostHp()+p->getLostHp()%2)/2;
            }
        }
        return n;
    }
};

class Duimoli : public TriggerSkill
{
public:
    Duimoli() : TriggerSkill("duimoli")
    {
        events << TargetConfirming;
        relate_to_place = "deputy";
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card || use.card->getTypeId() != Card::TypeTrick || use.card->getNumber() > 2*player->getHp()) return QStringList();
        if (!use.to.contains(player)) return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();

        room->cancelTarget(use, player);

        data = QVariant::fromValue(use);
        return false;
    }
};

class Chigui : public TriggerSkill
{
public:
    Chigui() : TriggerSkill("chigui")
    {
        frequency = NotFrequent;
        events << EventPhaseStart;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)&&player->getPhase()==Player::Finish){
            foreach(ServerPlayer *p, room->getOtherPlayers(player)){
                if (p->getWeapon())
                    return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QList<ServerPlayer *> list;
        foreach(ServerPlayer *p, room->getOtherPlayers(player)){
            if (p->getWeapon())
                list.append(p);
        }
        if (player->askForSkillInvoke(this, data)) {
            ServerPlayer *target=room->askForPlayerChosen(player,list,objectName(),QString(),true,true);
            if (target && target->getWeapon()){
                room->broadcastSkillInvoke(objectName(),player);
                room->loseHp(player);
                room->obtainCard(player,target->getWeapon());
                player->drawCards(1);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        bool can = false;
        foreach(ServerPlayer *p, room->getOtherPlayers(player)){
            if (p->getWeapon())
                can=true;
        }
        while (can==true && player->askForSkillInvoke(this, data)){
            can=false;
            QList<ServerPlayer *> list;
            foreach(ServerPlayer *p, room->getOtherPlayers(player)){
                if (p->getWeapon())
                    list.append(p);
            }
            ServerPlayer *target=room->askForPlayerChosen(player,list,objectName(),QString(),true,true);
            if (target && target->getWeapon()){
                room->broadcastSkillInvoke(objectName(),player);
                room->loseHp(player);
                room->obtainCard(player,target->getWeapon());
                player->drawCards(1);
            }
            foreach(ServerPlayer *p, room->getOtherPlayers(player)){
                if (p->getWeapon())
                    can=true;
            }
        }
        return false;
    }
};

class Buwu : public TriggerSkill
{
public:
    Buwu() : TriggerSkill("buwu")
    {
        frequency = NotFrequent;
        events << Damage << EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==Damage && TriggerSkill::triggerable(player)){
            DamageStruct damage=data.value<DamageStruct>();
            if(damage.to->isDead())
                return QStringList();
            if ((!damage.to->disableShow(true).contains(objectName()) && (damage.to->getActualGeneral1()->objectName()!="sujiang" || damage.to->getActualGeneral1()->objectName()!="sujiangf") ) || (!damage.to->disableShow(false).contains(objectName()) && (damage.to->getActualGeneral2()->objectName()!="sujiang" || damage.to->getActualGeneral2()->objectName()!="sujiangf"))){
                return QStringList(objectName());
            }
        }
        if (event==EventPhaseEnd&&player->getPhase()==Player::Finish){
            room->removePlayerDisableShow(player, objectName());
        }
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

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage=data.value<DamageStruct>();
        QStringList list;
        if (!damage.to->disableShow(true).contains(objectName()) && (damage.to->getActualGeneral1()->objectName()!="sujiang" || damage.to->getActualGeneral1()->objectName()!="sujiangf") )
            list.append("head_general");
        if (!damage.to->disableShow(false).contains(objectName()) && (damage.to->getActualGeneral2()->objectName()!="sujiang" || damage.to->getActualGeneral2()->objectName()!="sujiangf"))
            list.append("deputy_general");
        QString choice=room->askForChoice(player,objectName(),list.join("+"),data);
        room->broadcastSkillInvoke(objectName(),player);
        room->doLightbox("LuaBuwu$", 1000);
        if (choice=="head_general"){
            if (damage.to->hasShownGeneral1()){
                damage.to->hideGeneralWithoutChangingRole(true);
            }
            room->setPlayerDisableShow(damage.to, "h", objectName());
        }
        else{
            if (damage.to->hasShownGeneral2()){
                damage.to->hideGeneralWithoutChangingRole(false);
            }
            room->setPlayerDisableShow(damage.to, "d", objectName());
        }
        return false;
    }
};

class Tianmo : public TriggerSkill
{
public:
    Tianmo() : TriggerSkill("tianmo")
    {
        frequency = Frequent;
        events << SlashMissed << DamageDone << PreHpLost;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==SlashMissed && TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        else if (TriggerSkill::triggerable(player) && player->getMark("@tianmo")>0){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {

        if (event==SlashMissed && player->getMark("@tianmo")<2&& (player->hasShownSkill(objectName())||player->askForSkillInvoke(this, data))) {
            player->gainMark("@tianmo");
            return true;
        }
        else if (event!=SlashMissed && player->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==SlashMissed){
            return false;
        }
        else{
            player->loseMark("@tianmo");
            LogMessage msg;
            msg.type = "#TianmoDefense";
            msg.from = player;
            room->sendLog(msg);
            room->broadcastSkillInvoke(objectName(),player);
            if (event==DamageDone){
                DamageStruct damage = data.value<DamageStruct>();
                if (damage.damage > 1){
                    damage.damage -=1;
                    data.setValue(damage);
                }
                else{
                    return true;
                }
            }
            else{
                int lost=data.toInt();
                lost -=1;
                data.setValue(lost);
            }
        }
        return false;
    }
};

class Jinghua : public TriggerSkill
{
public:
    Jinghua() : TriggerSkill("jinghua")
    {
        frequency = NotFrequent;
        events << EventPhaseStart;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Start && !player->isKongcheng()){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)){
            ServerPlayer *dest = room->askForPlayerChosen(player,room->getAlivePlayers(),objectName());
            const Card *card = room->askForCard(player, ".", "@jinghua", data);
            if (card && dest){
                player->tag["jinghua_target"] = QVariant::fromValue(dest);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
       room->broadcastSkillInvoke(objectName(), player);
       ServerPlayer *dest = player->tag["jinghua_target"].value<ServerPlayer *>();
       player->tag.remove("jinghua_target");
       QString choice=room->askForChoice(dest,objectName()+"%","jinghua_getcard+jinghua_drawcard+jinghua_recover");
       if (choice == "jinghua_getcard") {
            QList<const Card *> judge= dest->getJudgingArea();
           if (judge.length() > 0){
               int id = room->askForCardChosen(player, dest, "j", "jinghua");
               room->obtainCard(player, id, true);
           }
       }
       else if (choice == "jinghua_recover") {
           RecoverStruct re = RecoverStruct();
           re.who = dest;
           room->recover(dest,re,true);
       }
       else{
           room->drawCards(player, 1);
           if (dest!=player){
             room->drawCards(dest, 1);
           }
       }
       return false;
    }
};

class Jiushu : public TriggerSkill
{
public:
    Jiushu() : TriggerSkill("jiushu")
    {
        frequency = Limited;
        limit_mark = "@tsubasa";
        events << AskForPeachesDone;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        if (triggerEvent == AskForPeachesDone) {
            DyingStruct dying = data.value<DyingStruct>();
            QList<ServerPlayer *> eustias = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *eustia, eustias)
                if (dying.who->getHp()<1 && eustia->getMark("@tsubasa")>0)
                    skill_list.insert(eustia, QStringList(objectName()));
            return skill_list;
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *eustia = ask_who;
        DyingStruct dying = data.value<DyingStruct>();
        if (eustia != NULL && eustia->askForSkillInvoke(this, QVariant::fromValue(dying.who))) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *eustia = ask_who;
        DyingStruct dying = data.value<DyingStruct>();
        ServerPlayer *source = dying.who;
        eustia->loseMark("@tsubasa");
        int num = source->getHandcardNum();
        room->setPlayerProperty(source,"hp",QVariant(1));
        int maxhp = source->getMaxHp();
        if (maxhp>5){
            maxhp=5;
        }
        if (num<maxhp){
            source->drawCards(maxhp-num);
        }
        room->broadcastSkillInvoke(objectName(), eustia);
        room->doLightbox("jiushu$", 3000);
        return false;
    }
};

CaibaoCard::CaibaoCard()
{
    target_fixed=true;
}

void CaibaoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    int num=source->getHandcardNum();
    if (num>5){
        num=5;
    }
    QList<int> card_ids = room->getNCards(num);
    if (num == 0) return;

    LogMessage log;
    log.type = "$ViewDrawPile";
    log.from = source;
    log.card_str = IntList2StringList(card_ids).join("+");
    room->doNotify(source, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());

    foreach (int id, card_ids) {
        room->moveCardTo(Sanguosha->getCard(id), source, Player::PlaceTable, CardMoveReason(CardMoveReason::S_REASON_TURNOVER, source->objectName(), "caibao", ""), false);
    }

    QList<ServerPlayer *> list = room->getAlivePlayers();

    foreach (int id, card_ids){
        if (source->isAlive()&&(Sanguosha->getCard(id)->isKindOf("EquipCard")||Sanguosha->getCard(id)->isKindOf("Slash"))){
            ServerPlayer *target=room->askForPlayerChosen(source,list,"caibao",QString(),true,true);
            if (target) {
                list.removeOne(target);
                QString choice=room->askForChoice(source,"caibao","caibaoslash+caibaofire_slash+caibaothunder_slash+caibaoice_slash",QVariant::fromValue(target));
                if (choice=="caibaoslash"){
                    choice="slash";
                }
                if (choice=="caibaofire_slash"){
                    choice="fire_slash";
                }
                if (choice=="caibaothunder_slash"){
                    choice="thunder_slash";
                }
                if (choice=="caibaoice_slash"){
                    choice="ice_slash";
                }
                Card *card = Sanguosha->cloneCard(choice,Sanguosha->getCard(id)->getSuit(), Sanguosha->getCard(id)->getNumber());
                if (!source->isProhibited(target, card)){
                    card->addSubcard(Sanguosha->getCard(id));
                    room->useCard(CardUseStruct(card, source, target),false);
                    card_ids.removeOne(id);
                }
            }
        }
    }
    if (!card_ids.isEmpty()) {
        QListIterator<int> i(card_ids);
        i.toBack();
        while (i.hasPrevious())
            room->getDrawPile().prepend(i.previous());
    }
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_PILE, QVariant(room->getDrawPile().length()));
}

class Caibao : public ZeroCardViewAsSkill
{
public:
    Caibao() : ZeroCardViewAsSkill("caibao"){
        //filter_pattern = ".|.|.|pika_gob";
        //expand_pile = "pika_gob";

    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("CaibaoCard");
    }

    const Card *viewAs() const
    {
        CaibaoCard *vs = new CaibaoCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

/*class Caibao : public TriggerSkill
{
public:
    Caibao() : TriggerSkill("caibao")
    {
        events << GeneralShown << EventPhaseStart << CardUsed;
        frequency = Frequent;
        view_as_skill=new Caibaovs;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == GeneralShown) {
            if (TriggerSkill::triggerable(player))
                return (data.toBool() == player->inHeadSkills(objectName())) ? QStringList(objectName()) : QStringList();
        }
        else if (triggerEvent == EventPhaseStart && player->getPhase()==Player::Start && player->hasShownSkill(objectName()))
            return QStringList(objectName());
        else if (triggerEvent == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getSkillName()==objectName()){
                room->setPlayerFlag(player,"caibao_used");
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart && player->askForSkillInvoke(objectName(),data)) {
            room->broadcastSkillInvoke(objectName(), rand()%3+1, player);
            return true;
        }

        if (triggerEvent == GeneralShown) {
            room->broadcastSkillInvoke(objectName(), rand()%3+1, player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == GeneralShown)
            player->addToPile("pika_gob", room->getNCards(4));
        else if (triggerEvent == EventPhaseStart) {
            int a = room->getDrawPile().length();
            if (a==0){
                a=1;
            }
            int j = rand()%a;
            player->addToPile("pika_gob",room->getDrawPile().at(j));
        }
        return false;
    }
};*/

GuailiCard::GuailiCard()
{
    target_fixed = true;
}

void GuailiCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    player->loseMark("@guailj");
    player->removeGeneral(false);
    foreach (ServerPlayer *p, room->getOtherPlayers(player)){
        if (p->getActualGeneral2()->objectName()!="sujiang" && p->getActualGeneral2()->objectName()!="sujiangf"){
           QString choice = room->askForChoice(p, objectName(), "guaili_remove+guaili_damage");
           if (choice == "guaili_remove"){
               p->removeGeneral(false);
               p->throwAllEquips();
           }
           else{
               DamageStruct da;
               da.from=player;
               da.to=p;
               da.damage=2;
               room->damage(da);
           }
        }
    }
}

class Guaili : public ZeroCardViewAsSkill
{
public:
    Guaili() : ZeroCardViewAsSkill("guaili")
    {
        frequency = Limited;
        limit_mark = "@guailj";
        relate_to_place = "head";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@guailj") > 0 && player->getActualGeneral2()->objectName()!="sujiang" && player->getActualGeneral2()->objectName()!="sujiangf";
    }

    virtual const Card *viewAs() const
    {
        GuailiCard *vs = new GuailiCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Tiansuo : public TriggerSkill
{
public:
    Tiansuo() : TriggerSkill("tiansuo")
    {
        events << TargetConfirmed;
        frequency = Frequent;
        relate_to_place = "deputy";
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (player==use.from && TriggerSkill::triggerable(player) && use.to.length()==1 && use.card->isKindOf("Slash") && !use.to.at(0)->isChained()){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this ,data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *target = use.to.at(0);
        room->setPlayerProperty(target, "chained", QVariant(true));
        if (target->getEquips().length()>0){
            int id = room->askForCardChosen(player, target, "e", objectName());
            room->throwCard(id, target, player);
        }
        return false;
    }
};

BoxueCard::BoxueCard()
{
}

bool BoxueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return true;
}

void BoxueCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    int num=0;
    foreach(auto p, targets){
       if(p->isFriendWith(source)){
           num = num +1;
       }
    }

    if (num > 0){
        int x = (num+num%2)/2;
        if (x>2) x= 2;
        source->drawCards(x);
    }
    bool canex=false;
    int urex=-1;
    QList<int> cards=room->getNCards(targets.length());
    room->doLightbox("luaboxue$", 1200);
    foreach(int id, cards){
        CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_SHOW,"","","","");
        room->moveCardTo(Sanguosha->getCard(id),NULL,Player::PlaceTable,reason,true);
    }
    foreach(ServerPlayer *target, targets){
        room->fillAG(cards);
        int want=room->askForAG(target,cards,false,objectName());
        room->getThread()->delay(1000);
        room->clearAG();
        room->clearAG(target);
        if (!target->isNude()){
            canex=true;
            urex=room->askForCardChosen(target,target,"he",objectName());
        }
        cards.removeOne(want);
        room->obtainCard(target,want,true);
        if (canex) {
            cards.append(urex);
            CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_SHOW,"","","","");
            room->moveCardTo(Sanguosha->getCard(urex),NULL,Player::PlaceTable,reason,true);
        }
        room->fillAG(cards);
        room->getThread()->delay(1000);
        room->clearAG();
        canex=false;
    }
    QString choice=room->askForChoice(source,objectName(),"throw+gx");
    if (choice=="throw"){
        foreach(int id, cards){
            room->throwCard(id,NULL);
        }
    }
    else{
        /*foreach(int id, cards){
            CardMoveReason reason = CardMoveReason(CardMoveReason::S_REASON_PUT,"","","","");
            room->moveCardTo(Sanguosha->getCard(id),NULL,Player::DrawPile ,reason,true);
        }*/
        room->askForGuanxing(source, cards, Room::GuanxingUpOnly);
    }
}

class Boxue : public ZeroCardViewAsSkill
{
public:
    Boxue() : ZeroCardViewAsSkill("boxue")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("BoxueCard");
    }

    const Card *viewAs() const
    {
        BoxueCard *vs = new BoxueCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

class Toushe : public TriggerSkill
{
public:
    Toushe() : TriggerSkill("toushe")
    {
        frequency = NotFrequent;
        events << EventPhaseChanging << EventPhaseEnd;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==EventPhaseChanging){
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (TriggerSkill::triggerable(player) && !player->isSkipped(Player::Play) && change.to==Player::Play && !player->isNude()) {
                 return QStringList(objectName());
            }
        }
        else if (event==EventPhaseEnd){
            QString skill=player->property("touying_type").toString();
            if (player->getPhase()==Player::Finish && skill!=""){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseChanging&&player->askForSkillInvoke(this, data)&&room->askForDiscard(player,objectName(),1,1,true,true,QString(),true)) {
            return true;
        }
        else if (event==EventPhaseEnd){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseChanging){
            bool discard=true;
            if (discard){
                room->broadcastSkillInvoke(objectName(),player);
                QStringList list;
                for (int i=0;i<998;i++) {
                    const Card *c=Sanguosha->getCard(i);
                    if (c&&c->isKindOf("Weapon")){
                        list.append(c->objectName());
                    }
                }
                QString choice=room->askForChoice(player,objectName(),list.join("+"));
                const Weapon *weapon;
                for (int i=0;i<998;i++) {
                    const Card *c=Sanguosha->getCard(i);
                    if (c&&c->objectName()==choice){
                        weapon= qobject_cast<const Weapon *>(c->getRealCard());
                    }
                }
                int n=weapon->getRange();
                room->doLightbox("image=image/big-card/"+choice+".png",1500);
                if (n<player->getAttackRange()){
                    n=player->getAttackRange();
                }
                room->setPlayerMark(player,"touying_range",n);
                player->setProperty("touying_type",QVariant(choice));
                room->acquireSkill(player,choice,true,player->inHeadSkills(this));
            }
        }
        else{
            if (player->getPhase()!=Player::Finish)
                return false;
            room->setPlayerMark(player,"touying_range",0);
            QString skill=player->property("touying_type").toString();
            room->detachSkillFromPlayer(player, skill, false, false, player->inHeadSkills(skill));
            player->setProperty("touying_type",QVariant());
        }
        return false;
    }
};

class TousheRange : public AttackRangeSkill
{
public:
    TousheRange() : AttackRangeSkill("#tousherange")
    {
    }

    virtual int getFixed(const Player *target, bool include_weapon) const
    {
        if (target->hasSkill("toushe")&&target->getMark("touying_range")>0) {
            int n=target->getMark("touying_range");
            return n;
        }
        return -1;
    }
};

QString JianjiePattern = "pattern";
class Jianjievs : public OneCardViewAsSkill
{
public:
    Jianjievs() : OneCardViewAsSkill("jianjie")
    {
        relate_to_place = "head";
        filter_pattern = ".|.|.|sword";
        expand_pile = "sword";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        JianjiePattern = "slash";
        Slash *slash = new Slash(Card::NoSuit,-1);
        return slash->isAvailable(player)&&!player->getPile("sword").isEmpty();
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (pattern=="slash" || pattern=="jink"){
            JianjiePattern = pattern;
            return player->hasSkill("jianjie");
        }
        return false;
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        QString pattern = JianjiePattern;
        Card *card=Sanguosha->cloneCard(pattern,originalCard->getSuit(),originalCard->getNumber());
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};

class JianjieRecord : public TriggerSkill
{
public:
    JianjieRecord() : TriggerSkill("#jianjie-record")
    {
        events << CardsMoveOneTime << EventPhaseEnd;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if ((move.reason.m_reason & CardMoveReason::S_MASK_BASIC_REASON) == CardMoveReason::S_REASON_DISCARD && move.to_place == Player::PlaceTable && player->getPhase()!=Player::NotActive){
                QStringList list = room->getTag(player->objectName()+"jianjie").toStringList();
                foreach (int id, move.card_ids) {
                    if (!list.contains(QString::number(id))){
                      list <<QString::number(id);
                    }
                }
                room->setTag(player->objectName()+"jianjie", QVariant(list));
            }
        }
        else if(event == EventPhaseEnd && player->getPhase()==Player::Finish) {
            room->setTag(player->objectName()+"jianjie", QVariant());
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

};

class Jianjie : public TriggerSkill
{
public:
    Jianjie() : TriggerSkill("jianjie")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << CardsMoveOneTime << EventPhaseEnd;
        relate_to_place = "head";
        view_as_skill=new Jianjievs;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==EventPhaseStart){
            QStringList list1 = room->getTag(player->objectName()+"jianjie").toStringList();
            QList<int> list;
            foreach(QString id, list1){
                if (room->getDiscardPile().contains(id.toInt()))
                    list << id.toInt();
            }
            if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Finish && player->getPile("sword").length()==0 && list.length()>0){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
   {
        if (event==EventPhaseStart && player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseStart){
            room->broadcastSkillInvoke(objectName(),player);
            QStringList list1 = room->getTag(player->objectName()+"jianjie").toStringList();
            QList<int> list;
            foreach(QString id, list1){
                if (room->getDiscardPile().contains(id.toInt()))
                    list << id.toInt();
            }

            QStringList kingdoms;
            int n=0;
            foreach(ServerPlayer *p, room->getAlivePlayers()){
                if ((p->hasShownGeneral1()||p->hasShownGeneral2())&&p->getRole()!="careerist"&&!kingdoms.contains(p->getKingdom())){
                    kingdoms.append(p->getKingdom());
                }
                else if (p->getRole()=="careerist"){
                    n=n+1;
                }
            }
            n=n+kingdoms.length();
            if (n >= list.length()) {
                n = list.length();
            }
            for (int i=1; i<=n; i++ ){
                room->fillAG(list, player);
                int id = room->askForAG(player,list,true,objectName());
                room->clearAG(player);
                if (id > -1){
                    player->addToPile("sword", id, true);
                    list.removeOne(id);
                }
                else{
                    break;
                }
            }
        }
        return false;
    }
};

class JianjieClear : public DetachEffectSkill
{
public:
    JianjieClear() : DetachEffectSkill("jianjie", "sword")
    {
        frequency = Compulsory;
    }
};

class Cangshan : public OneCardViewAsSkill
{
public:
    Cangshan() : OneCardViewAsSkill("cangshan"){
       response_or_use = true;
    }

    bool viewFilter(const Card *card) const
    {
        return card->isKindOf("EquipCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Card *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard->getId());
        slash->setSkillName(objectName());
        slash->setShowSkill(objectName());
        return slash;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        //return Slash::IsAvailable(player); --cannot use general slash to judge
        return true;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "slash" && player->hasSkill("cangshan");
    }
};

class CangshanTrigger : public TriggerSkill
{
public:
    CangshanTrigger() : TriggerSkill("#cangshan")
    {
        frequency = NotFrequent;
        events << CardResponded << CardUsed;
        global=true;
    }
    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == CardResponded){
             const Card *card = data.value<CardResponseStruct>().m_card;
             if (card->getSkillName()=="cangshan"){
                 player->drawCards(1);
             }
        }
        else if (triggerEvent == CardUsed){
             const Card *card = data.value<CardUseStruct>().card;
             if (card->getSkillName()=="cangshan"){
                 player->drawCards(1);
             }
        }
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class CangshanTargetMod : public TargetModSkill
{
public:
    CangshanTargetMod() : TargetModSkill("#cangshan-target")
    {
        pattern = "Slash";
    }

    virtual int getDistanceLimit(const Player *from, const Card *card) const
    {

        if (card->getSkillName()=="cangshan")
            return 1000;
        else
            return 0;
    }
};

YuehuangCard::YuehuangCard()
{
    target_fixed = true;
}

void YuehuangCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    foreach(auto p, room->getOtherPlayers(player)){
        if (p->isFriendWith(player) && player->inMyAttackRange(p)){
            const Card *card = room->askForCard(p, "EquipCard|.|.", "@YuehuangGive:"+p->objectName()+":"+player->objectName(), QVariant(), Card::MethodNone);
            if (card){
                room->obtainCard(player, card);
                room->setPlayerMark(player,"yuehuang",player->getMark("yuehuang")+1);
            }
        }
    }
}

class Yuehuang : public ZeroCardViewAsSkill
{
public:
    Yuehuang() : ZeroCardViewAsSkill("yuehuang"){

    }

    const Card *viewAs() const
    {
        YuehuangCard *card = new YuehuangCard();
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YuehuangCard");
    }
};

class YuehuangTargetMod : public TargetModSkill
{
public:
    YuehuangTargetMod() : TargetModSkill("#yuehuang-res")
    {
        pattern = "Slash";
    }

    virtual int getResidueNum(const Player *from, const Card *card) const
    {
        return from->getMark("yuehuang");
    }

};

class Jianshi : public TriggerSkill
{
public:
    Jianshi() : TriggerSkill("jianshi")
    {
        events << CardsMoveOneTime << CardFinished;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardFinished){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.from->hasFlag("jianshi_card")){
               foreach(auto p, use.to){
                   if (!p->isRemoved()){
                         room->setPlayerCardLimitation(p, "use", ".", false);
                         room->setPlayerProperty(p, "removed", QVariant(true));
                   }
               }
            }
        }

    }

   virtual QStringList triggerable(TriggerEvent event, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const{
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (event != CardsMoveOneTime || !TriggerSkill::triggerable(player)||(!move.from_places.contains(Player::DrawPile) && !move.from_places.contains(Player::DrawPileBottom))) return QStringList();
        if (move.to_place == Player::DrawPile || move.to_place == Player::DrawPileBottom){
            return QStringList();
        }
        bool can=false;
        foreach(int id, move.card_ids){
            if (Sanguosha->getCard(id)->isKindOf("Key")){
                can=true;
            }
        }
        if (can==false){
           return QStringList();
        }
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *kotori = player;
        if (kotori &&kotori->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), kotori);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        ServerPlayer *kotori = player;
        if (!kotori)
            return false;
        CardsMoveStruct new_move;
        new_move.from = move.to;
        new_move.card_ids = move.card_ids;
        new_move.from_pile_name = move.to_pile_name;
        new_move.from_place = move.to_place;
        new_move.reason.m_reason = CardMoveReason::S_REASON_TRANSFER;
        new_move.to = kotori;
        new_move.to_place = Player::PlaceHand;
        room->moveCardsAtomic(new_move, true);
        if (move.to && kotori->isFriendWith(move.to) && move.to->objectName()!=kotori->objectName()){
            ServerPlayer *to = room->findPlayerbyobjectName(move.to->objectName());
            QString choice = room->askForChoice(kotori, objectName(), "jianshi_recover+jianshi_draw+cancel", QVariant::fromValue(to));
            if (choice == "jianshi_recover"){
                RecoverStruct recover;
                recover.recover = 1;
                recover.who = player;
                room->recover(to, recover, true);
            }
            else if (choice == "jianshi_draw"){
                to->drawCards(2);
            }
        }
        room->setPlayerFlag(kotori, "jianshi_card");
        const Card *card = room->askForUseCard(kotori, "Key", "@jianshi-use");
        room->setPlayerFlag(kotori, "-jianshi_card");
        return false;
    }

};

class Qiyue : public TriggerSkill
{
public:
    Qiyue() : TriggerSkill("qiyue")
    {
        events << EventPhaseEnd << CardsMoveOneTime << PileSwaped;
    }
    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (!move.from_places.contains(Player::DrawPile) && !move.from_places.contains(Player::DrawPileBottom)){
                return;
            }
            if (player && player->isAlive() && player->getMark("qiyue_calculate")>0 && !player->hasFlag("qiyue_return_max")){
                if (room->getDrawPile().length() == 0){
                    player->setFlags("qiyue_return_max");
                }
            }
        }
        if (event == PileSwaped){
            if (player && player->isAlive() && player->getMark("qiyue_calculate")>0 && !player->hasFlag("qiyue_return_max")){
                player->setFlags("qiyue_return_max");
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (triggerEvent!=EventPhaseEnd) return skill_list;
        int min = 998;
        foreach(auto p, room->getAlivePlayers()){
            if (p->getHp()<min)
                min = p->getHp();
        }

        if (player->getPhase()!=Player::Finish ||player->getHp() > min) return skill_list;
        bool can=false;
        foreach(const Card *card, player->getJudgingArea()){
            if (card->isKindOf("Key")){
                can=true;
            }
        }
        if (can==false){
           return skill_list;
        }
        QList<ServerPlayer *> kotoris = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *kotori, kotoris) {
           skill_list.insert(kotori, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *kotori = ask_who;
        if (kotori &&kotori->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), kotori);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *kotori = ask_who;
        if (!kotori)
            return false;
        int n= 5-kotori->getHp();
        room->doLightbox("qiyue$", 2000);
        room->setPlayerMark(player, "qiyue_calculate", 1);
        foreach (ServerPlayer *p, room->getAlivePlayers()){
            bool can=false;
            foreach(const Card *card, p->getJudgingArea()){
                if (card->isKindOf("Key")){
                    can=true;
                }
            }
            if (can==true){
                p->drawCards(n);
            }
        }
        foreach (ServerPlayer *p, room->getAlivePlayers()){
            bool can=false;
            foreach(const Card *card, p->getJudgingArea()){
                if (card->isKindOf("Key")){
                    can=true;
                }
            }
            if (can==true){
                for (int i=1;i<=n;i++){
                    if (!p->isNude()){
                        int id=room->askForCardChosen(p,p,"hej",objectName());
                        room->throwCard(id,p,p);
                    }
                }
            }
        }
        room->setPlayerMark(player, "qiyue_calculate", 0);
        if (player->hasFlag("qiyue_return_max")){
            player->setFlags("-qiyue_return_max");
            room->setPlayerProperty(player, "maxhp", QVariant::fromValue(player->getMaxHp()+1));
        }
        //room->loseHp(kotori);
        return false;
    }

};

KekediCard::KekediCard()
{
    mute = true;
}

bool KekediCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    return targets.length() == 1;
}

bool KekediCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty())
        return false;
    foreach (const Card *card, to_select->getEquips()) {
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        Q_ASSERT(equip);
        int equip_index = static_cast<int>(equip->location());
        foreach (const Player *p, to_select->getSiblings()) {
            if (!p->getEquip(equip_index))
                return true;
        }
    }
    foreach (const Card *card, to_select->getJudgingArea()) {
        foreach (const Player *p, to_select->getSiblings()) {
            if (!p->containsTrick(card->objectName()))
                return true;
        }
    }
    return false;
}

void KekediCard::use(Room *room, ServerPlayer *kurumi, QList<ServerPlayer *> &targets) const
{
    if (targets.isEmpty())
        return;

    ServerPlayer *from = targets.first();
    if (from->getCards("ej").isEmpty())
        return;

    int card_id = room->askForCardChosen(kurumi, from, "ej", "kekedi");
    const Card *card = Sanguosha->getCard(card_id);
    Player::Place place = room->getCardPlace(card_id);

    int equip_index = -1;
    if (place == Player::PlaceEquip) {
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        equip_index = static_cast<int>(equip->location());
    }

    QList<ServerPlayer *> tos;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (equip_index != -1) {
            if (p->getEquip(equip_index) == NULL)
                tos << p;
        } else {
            if (!kurumi->isProhibited(p, card) && !p->containsTrick(card->objectName()))
                tos << p;
        }
    }

    room->setTag("KekediTarget", QVariant::fromValue(from));
    ServerPlayer *to = room->askForPlayerChosen(kurumi, tos, "kekedi", "@kekedi-to:::" + card->objectName());
    if (to) {
        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, from->objectName(), to->objectName());

        room->moveCardTo(card, from, to, place,
            CardMoveReason(CardMoveReason::S_REASON_TRANSFER,
            kurumi->objectName(), "kekedi", QString()));

        if (place == Player::PlaceDelayedTrick) {
            CardUseStruct use(card, NULL, to);
            QVariant _data = QVariant::fromValue(use);
            room->getThread()->trigger(TargetConfirming, room, to, _data);
            CardUseStruct new_use = _data.value<CardUseStruct>();
            if (new_use.to.isEmpty())
                card->onNullified(to);

            foreach(ServerPlayer *p, room->getAllPlayers())
                room->getThread()->trigger(TargetConfirmed, room, p, _data);
        }
    }
    room->removeTag("KekediTarget");
}

class KekediViewAsSkill : public ZeroCardViewAsSkill
{
public:
    KekediViewAsSkill() : ZeroCardViewAsSkill("kekedi")
    {
        response_pattern = "@@kekedi";
    }

    virtual const Card *viewAs() const
    {
        KekediCard *card = new KekediCard();
        card->setShowSkill(objectName());
        card->setSkillName(objectName());
        return card;
    }
};

class Kekedi : public TriggerSkill
{
public:
    Kekedi() : TriggerSkill("kekedi")
    {
        events << EventPhaseStart;
        view_as_skill = new KekediViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Start){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (player->askForSkillInvoke(this, data)) {
            if (player->getHandcardNum()%2 == 0){
                ServerPlayer *target = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), QString(), true, true);
                if (target){
                    player->tag["shidan_target"] = QVariant::fromValue(target);
                    room->setPlayerFlag(player, "kekedi_used");
                    return true;
                }
            }
            else{
                if (room->askForUseCard(player, "@@kekedi", "@kekedi")){
                    room->broadcastSkillInvoke(objectName(), rand()%2+1, player);
                    room->setPlayerFlag(player, "kekedi_used");
                    return true;
                }
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *target = player->tag["shidan_target"].value<ServerPlayer *>();
        player->tag["shidan_target"] = QVariant::fromValue(NULL);
        if (target) {
            Card *card = Sanguosha->cloneCard("fire_slash");
            card->setSkillName(objectName());
            room->broadcastSkillInvoke(objectName(), rand()%2+3, player);
            room->doLightbox("SE_Shidan$", 800);
            room->useCard(CardUseStruct(card, player, target));
        }
        return false;
    }

};

class Kekedieff : public DrawCardsSkill
{
public:
   Kekedieff() : DrawCardsSkill("#kekedieff")
    {
        frequency = Compulsory;
    }

    bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->hasFlag("kekedi_used")) {
            return true;
        }
        return false;
    }

    int getDrawNum(ServerPlayer *kurumi, int n) const
    {
        Room *room = kurumi->getRoom();
        if (n>0){
          return n;
        }
        else{
            return 0;
        }
    }
};

BadanCard::BadanCard()
{
    target_fixed = true;
}

void BadanCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    QList<int> list;
    QList<int> aglist;
    room->doLightbox("SE_Badan$", 3000);
    player->loseMark("@Eight");
    foreach (ServerPlayer *p, room->getAlivePlayers()){
        if (p->isFriendWith(player) && !p->isNude()){
            int id = room->askForCardChosen(p, p, "he", objectName());
            list << Sanguosha->getCard(id)->getNumber();
            room->throwCard(id, p, p);
        }
    }
    foreach(int id, room->getDiscardPile()){
        if (list.contains(Sanguosha->getCard(id)->getNumber())){
            aglist << id;
        }
    }
    int n = 0;
    foreach (ServerPlayer *p, room->getAlivePlayers()){
        if (p->isFriendWith(player) && !aglist.isEmpty()){
            n = n+1;
            room->fillAG(aglist, p, QList<int>(), room->getPlayers());
            int id = room->askForAG(p, aglist, false, objectName());
            room->obtainCard(p, id, true);
            aglist.removeOne(id);
            room->clearAG();
        }
    }
    if (n == 0)
        return;
    RecoverStruct recover;
    recover.recover = n;
    recover.who=player;
    room->recover(player, recover);
}

class Badan : public ZeroCardViewAsSkill
{
public:
    Badan() : ZeroCardViewAsSkill("badan")
    {
        frequency = Limited;
        limit_mark = "@Eight";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@Eight") > 0;
    }

    virtual const Card *viewAs() const
    {
        BadanCard *vs = new BadanCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};

LingjieCard::LingjieCard()
{
}

bool LingjieCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    if (!targets.isEmpty() || to_select == Self || !to_select->hasShownOneGeneral() || to_select->isChained())
        return false;

    return to_select->canBeChainedBy(Self) && !Self->isFriendWith(to_select) && !Self->willBeFriendWith(to_select);
}

void LingjieCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    auto target = targets[0];
    if (target == NULL)
        return;

    QList<ServerPlayer *> enemies;
    QList<ServerPlayer *> friends;

    foreach (auto p, room->getAlivePlayers())
    {
        if (!p->isChained() && p->canBeChainedBy(source))
        {
            if (target->isFriendWith(p))
            {
                enemies << p;
            }
            if (source == p)
            {
                friends << p;
            }
        }
    }

    int diffNum = qAbs(enemies.length() - friends.length());
    QList<ServerPlayer *> to_handle;
    to_handle << enemies;
    to_handle << friends;

    room->sortByActionOrder(to_handle);

    LogMessage log;
    log.type = "#LingjieChain";
    log.from = source;
    log.to << to_handle;
    log.arg = "lingjie";
    room->sendLog(log);

    foreach (auto to, to_handle)
    {
        room->setPlayerProperty(to, "chained", true);
    }

    if (diffNum > 0)
        room->drawCards(source, qMin(diffNum, 3), "lingjie");
}

class Lingjie : public ZeroCardViewAsSkill
{
public:
    Lingjie() : ZeroCardViewAsSkill("lingjie")
    {
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("LingjieCard");
    }

    virtual const Card *viewAs() const
    {
        auto lj = new LingjieCard;
        lj->setSkillName(objectName());
        lj->setShowSkill(objectName());
        return lj;
    }
};

XuwuCard::XuwuCard()
{
    target_fixed = true;
}

void XuwuCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    CardMoveReason reason(CardMoveReason::S_REASON_RECAST, card_use.from->objectName());
    reason.m_skillName = getSkillName();
    room->moveCardTo(this, card_use.from, NULL, Player::PlaceTable, reason, true);
    card_use.from->broadcastSkillInvoke("@recast");
    room->broadcastSkillInvoke("xuwu", card_use.from);

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

    // then

    if (card_use.from->getEquips().length() == 0)
        card_use.from->drawCards(1);
}

class XuwuVS : public OneCardViewAsSkill
{
public:
    XuwuVS() : OneCardViewAsSkill("xuwu")
    {
        response_pattern = "@@xuwu";
        filter_pattern = "EquipCard|.|.|.";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getPhase()!= Player::NotActive){
            return player->usedTimes("XuwuCard") <3;
        }
    }

    virtual const Card *viewAs(const Card *card) const
    {
        auto xw = new XuwuCard;
        xw->addSubcard(card);
        xw->setShowSkill("xuwu");
        xw->setSkillName("xuwu");
        return xw;
    }
};

class Xuwu : public MasochismSkill
{
public:
    Xuwu() : MasochismSkill("xuwu")
    {
        view_as_skill = new XuwuVS;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *louise, QVariant &, ServerPlayer* &) const
    {
        if (MasochismSkill::triggerable(louise) && !louise->isNude())
            return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *louise, QVariant &, ServerPlayer *) const
    {
        if (room->askForUseCard(louise, "@@xuwu", "@xuwu-recast") != NULL)
        {
            room->broadcastSkillInvoke(objectName(), louise);
            return true;
        }
        return false;
    }

    virtual void onDamaged(ServerPlayer *, const DamageStruct &) const
    {
        return;
    }
};

//science
class Weixiao : public TriggerSkill
{
public:
    Weixiao() : TriggerSkill("weixiao")
    {
        frequency = NotFrequent;
        events << EventPhaseStart;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Finish && !player->isNude()){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), QString(), true, true);
            if (target && room->askForDiscard(player, objectName(), 1, 1, true, true, QString(), true)) {
                player->tag["weixiao_target"] = QVariant::fromValue(target);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag["weixiao_target"].value<ServerPlayer *>();
        if (target->getHandcardNum()<=target->getHp()){
            room->drawCards(target, 2, "weixiao");
        }
        else{
            room->askForDiscard(target, "weixiao", 2, 2, false, true);
        }
        room->broadcastSkillInvoke(objectName());
        room->doLightbox("weixiao$", 2000);
        return false;
    }
};

class Chidun : public TriggerSkill
{
public:
    Chidun() : TriggerSkill("chidun")
    {
        frequency = NotFrequent;
        events << DamageInflicted << DamageComplete;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

     virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        DamageStruct damage = data.value<DamageStruct>();
        if (triggerEvent == DamageInflicted && player->isAlive())
        {
            if (damage.damage < 1 || damage.transfer)
                return skill_list;

            QList<ServerPlayer *> ayanamis = room->findPlayersBySkillName(objectName());

            foreach (ServerPlayer *ayanami, ayanamis)
                if ((ayanami->isFriendWith(player) || ayanami->willBeFriendWith(player)) && ayanami != player)
                    skill_list.insert(ayanami, QStringList(objectName()));
        }
        else if (triggerEvent == DamageComplete && damage.transfer && damage.transfer_reason == objectName() && damage.to == player && player->isAlive())
            skill_list.insert(player, QStringList(objectName()));
        return skill_list;
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (triggerEvent == DamageInflicted && ask_who->askForSkillInvoke(objectName(), QVariant::fromValue(damage.to)))
        {
            room->broadcastSkillInvoke(objectName());
            return true;
        }
        else if (triggerEvent == DamageComplete)
        {
            ServerPlayer *slasher = NULL;           
            foreach (ServerPlayer *tar, room->getAlivePlayers())
                if (tar->hasFlag("chidun_tar"))
                    slasher = tar;
            if (slasher)
                slasher->setFlags("-chidun_tar");
            QString prompt = "@chidun:";
            if (damage.from){
                prompt = "@chidun:" + damage.from->objectName();
                if (room->askForUseSlashTo(slasher, damage.from, prompt, false, false, false))
                    return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event == DamageInflicted)
        {
            ask_who->drawCards(1, objectName());

            DamageStruct damage = data.value<DamageStruct>();
            damage.to->setFlags("chidun_tar");
            damage.transfer = true;
            damage.to = ask_who;
            damage.transfer_reason = objectName();

            player->tag["TransferDamage"] = QVariant::fromValue(damage);

            LogMessage log;
            log.type = "#ChidunTransfer";
            log.from = ask_who;
            log.to << damage.to;
            log.arg = objectName();
            log.arg2 = QString::number(damage.damage);

            room->sendLog(log);

            return true;
        }
        return false;
    }
};

class Tiancai : public TriggerSkill
{
public:
    Tiancai() : TriggerSkill("tiancai")
    {
        frequency = Frequent;
        events << BeforeCardsMove;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.to || player != move.to || move.to_place != Player::PlaceHand || !move.from_places.contains(Player::DrawPile)||player->hasFlag("tiancai_current")||(room->getCurrent()&&room->getCurrent()->hasFlag(player->objectName()+"tiancai")))
            return QStringList();
        int l=0;
        for (int i = 0; i < move.card_ids.length(); i++){
            if (move.from_places.at(i)==Player::DrawPile){
                l=l+1;
            }
        }
        if (l==0)
            return QStringList();
        if (TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->setPlayerFlag(player,"tiancai_current");
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        int l=0;
        for (int i = 0; i < move.card_ids.length(); i++){
            if (move.from_places.at(i)==Player::DrawPile){
                l=l+1;
            }
        }
        //room->setPlayerFlag(player,"tiancai_current");
        room->setPlayerFlag(room->getCurrent(),player->objectName()+"tiancai");
        QList<int> tiancai = room->getNCards(2*l);
      /*for(int i = 0; i < 2*l; i++)
            tiancai.append(room->getDrawPile().at(i));*/
        AskForMoveCardsStruct result = room->askForMoveCards(player, tiancai, QList<int>(), true, objectName(), "", objectName(), l, l, false, false, QList<int>() << -1);
        DummyCard dummy(result.bottom);
        player->obtainCard(&dummy, false);
        for(int i = 0; i < result.top.length(); i++)
            room->getDrawPile().insert(i,result.top.at(i));
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_PILE, QVariant(room->getDrawPile().length()));
        LogMessage a;
        a.type = "#TiancaiResult";
        a.arg = QString::number(l);
        a.from = player;
        room->sendLog(a);
        LogMessage b;
        b.type = "$GuanxingTop";
        b.from = player;
        b.card_str = IntList2StringList(result.top).join("+");
        room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, b.toVariant());
        move.card_ids.clear();
        data.setValue(move);
        room->setPlayerFlag(player,"-tiancai_current");
        return false;
    }
};

class Zhushou : public TriggerSkill
{
public:
    Zhushou() : TriggerSkill("zhushou")
    {
        frequency = Frequent;
        events << EventPhaseStart;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL||player->getPhase()!=Player::Play) return skill_list;
        QList<ServerPlayer *> kurisus = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *kurisu, kurisus) {
            if (kurisu->isFriendWith(player)&&kurisu->getMark("zhushou_used")==0)
                skill_list.insert(kurisu, QStringList(objectName()));
        }
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *kurisu = ask_who;
        if (kurisu && kurisu->askForSkillInvoke(this, QVariant::fromValue(player))) {
            room->broadcastSkillInvoke(objectName(), kurisu);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *kurisu = ask_who;
        int hp =player->getHp();
        player->drawCards(hp);;
        room->setPlayerMark(kurisu,"zhushou_used",1);
        if (!room->askForCard(player,"TrickCard", "@zhushou")){
           if (player->getCards("he").length()>=player->getHp()){
               room->askForDiscard(player, objectName(), player->getHp(), player->getHp(), false, true);
           }
           else{
               player->throwAllHandCardsAndEquips();
           }
        }
    }
};

class ZhushouTrigger : public TriggerSkill
{
public:
    ZhushouTrigger() : TriggerSkill("#zhushou")
    {
        frequency = NotFrequent;
        events << TurnStart;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player) && (player->getMark("zhushou_used")>0||player->getMark("future_card")>0) && !player->hasFlag("Point_ExtraTurn")) {
             room->setPlayerMark(player,"zhushou_used",0);
        }
        return QStringList();
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == EventPhaseStart){
            if (player->isAlive() && player->getPhase() == Player::RoundStart){
                room->setPlayerMark(player,"zhushou_used",0);
                /*int n= player->getMark("future_card");
                room->setPlayerMark(player,"future_card",0);
                if (n>player->getHandcardNum()+player->getEquips().length())
                    n=player->getHandcardNum()+player->getEquips().length();
                QList<int> list = room->askForExchange(player,objectName(),n,n,QString());
                CardsMoveStruct move(list, NULL, Player::DrawPile,
                    CardMoveReason(CardMoveReason::S_REASON_PUT, player->objectName(), objectName(), QString()));
                room->moveCardsAtomic(move, false);
                LogMessage log;
                log.type = "$ViewDrawPile";
                log.from = player;
                log.card_str = IntList2StringList(list).join("+");
                room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
                room->askForGuanxing(player, list, Room::GuanxingUpOnly);*/
            }
        }
        return false;
    }
};

class Huansha : public TriggerSkill
{
public:
    Huansha() : TriggerSkill("huansha")
    {
        frequency = Compulsory;
        events << DamageInflicted << TargetConfirmed << CardFinished;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==DamageInflicted){
            DamageStruct damage=data.value<DamageStruct>();
            if (TriggerSkill::triggerable(player) && (!damage.card || damage.card->getEffectiveId()<0 || damage.nature!=DamageStruct::Normal)) {
                 return QStringList(objectName());
            }
        }
        if (event==CardFinished){
            CardUseStruct use=data.value<CardUseStruct>();
            foreach(ServerPlayer *p, use.to){
                room->removePlayerDisableShow(p,objectName());
                room->removePlayerMark(p,"@all_skill_invalidity",p->getMark("huansha"));
                p->setMark("huansha",0);
                /*QStringList InvalidSkill = p->property("invalid_skill_has").toString().split("+");
                foreach(const Skill *skill, p->getActualGeneral1()->getSkillList()){
                    if (InvalidSkill.contains(skill->objectName()+":huansha")){
                     InvalidSkill.removeOne(skill->objectName()+":huansha");
                    }
                }
                foreach(const Skill *skill, p->getActualGeneral2()->getSkillList()){
                    if (InvalidSkill.contains(skill->objectName()+":huansha")){
                     InvalidSkill.removeOne(skill->objectName()+":huansha");
                    }
                }
                p->setProperty("invalid_skill_has",QVariant(InvalidSkill.join("+")));*/
                if (p->getMark("huansha_head")>0){
                    p->setMark("huansha_head",0);
                    room->setPlayerMark(p, "skill_invalidity_head", p->getMark("skill_invalidity_head")-1);
                }
                if (p->getMark("huansha_deputy")>0){
                    p->setMark("huansha_deputy",0);
                    room->setPlayerMark(p, "skill_invalidity_deputy", p->getMark("skill_invalidity_deputy")-1);
                }
            }
        }
        if (event==TargetConfirmed){
            CardUseStruct use=data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && player==use.from && use.card->isKindOf("Slash")&&(!use.to.contains(player)||use.to.length()>1)) {
                 return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==DamageInflicted&&(player->hasShownSkill(objectName())||player->askForSkillInvoke(this, data))) {
            return true;
        }
        if (event==TargetConfirmed&&(player->hasShownSkill(objectName())||player->askForSkillInvoke(this, data))) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==DamageInflicted){
            room->broadcastSkillInvoke(objectName(),rand()%2+1,player);
            DamageStruct damage=data.value<DamageStruct>();
            if (damage.damage >= 2){
                room->doLightbox("Huansha$", 2000);
                damage.damage -=1;
                data.setValue(damage);
            }
            else{
                room->doLightbox("Huansha_Short$", 800);
                return true;
            }
        }
        if (event==TargetConfirmed){
            CardUseStruct use=data.value<CardUseStruct>();
            foreach(ServerPlayer *p, use.to){
                room->setPlayerDisableShow(p, "hd", objectName());
                QStringList choices;
                if (p->hasShownGeneral1()){
                    choices << p->getActualGeneral1Name();
                }
                if (p->hasShownGeneral2()){
                    choices << p->getActualGeneral2Name();
                }
                QString general="";
                if (!choices.isEmpty()){
                    general=room->askForGeneral(player,choices.join("+"),QString(),true,objectName(),data);
                }
                room->broadcastSkillInvoke(objectName(),3,player);
                if (general!=""){
                    p->addMark("huansha");
                    room->addPlayerMark(p,"@all_skill_invalidity");
                    QStringList InvalidSkill = p->property("invalid_skill_has").toString().split("+");
                    if (general==p->getActualGeneral1Name()){
                        p->addMark("huansha_head");
                        room->setPlayerMark(p, "skill_invalidity_head", p->getMark("skill_invalidity_head")+1);
                        /*const General *g=Sanguosha->getGeneral(general);
                        foreach(const Skill *skill, g->getSkillList()){
                            if (!InvalidSkill.contains(skill->objectName()+":huansha")){
                             InvalidSkill<<skill->objectName()+":huansha";
                            }
                        }

                        p->setProperty("invalid_skill_has",QVariant(InvalidSkill.join("+")));*/
                    }
                    if (general==p->getActualGeneral2Name()){
                        p->addMark("huansha_deputy");
                        room->setPlayerMark(p, "skill_invalidity_deputy", p->getMark("skill_invalidity_deputy")+1);
                        /*const General *g=Sanguosha->getGeneral(general);
                        foreach(const Skill *skill, g->getSkillList()){
                            if (!InvalidSkill.contains(skill->objectName()+":huansha")){
                             InvalidSkill<<skill->objectName()+":huansha";
                            }
                        }
                        p->setProperty("invalid_skill_has",QVariant(InvalidSkill.join("+")));*/
                    }
                    LogMessage log;
                    log.type = general==p->getActualGeneral1Name() ? "#HuanshaHeadSkills" : "#HuanshaDeputySkills";
                    log.from = player;
                    log.to << p;
                    log.arg = "huansha";
                    room->sendLog(log);
                }
            }
        }
        return false;
    }
};

class Dapo : public TriggerSkill
{
public:
    Dapo() : TriggerSkill("dapo")
    {
        frequency = NotFrequent;
        events << DamageCaused << Damage;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        DamageStruct damage = data.value<DamageStruct>();
        if (player == NULL) return skill_list;
        if (triggerEvent==DamageCaused){
            QList<ServerPlayer *> toumas = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *touma, toumas) {
                if (touma!=damage.to && touma!=damage.from && !touma->isKongcheng() && !damage.from->isKongcheng() && touma->getHp()>=damage.to->getHp())
                    skill_list.insert(touma, QStringList(objectName()));
            }
        }
        else{
            if (TriggerSkill::triggerable(player)&&damage.card&&damage.card->isKindOf("Slash")&&player->hasFlag("dapo_state")){
                room->setPlayerFlag(player,"-dapo_state");
                ServerPlayer *dest = NULL;
                ServerPlayer *from = NULL;
                foreach(ServerPlayer *p, room->getAlivePlayers()){
                    if (p->hasFlag("dapo_to")){
                        dest=p;
                        room->setPlayerFlag(p,"-dapo_to");
                    }
                    if (p->hasFlag("dapo_from")){
                        from=p;
                        room->setPlayerFlag(p,"-dapo_from");
                    }
                }
                QString choice = room->askForChoice(player,objectName(),"dapo_to+dapo_from+cancel");
                if (choice=="dapo_to" && dest != NULL && dest->isAlive() && room->askForChoice(dest,"transform","transform+cancel",data)=="transform"){
                    dest->showGeneral(false);
                    room->transformDeputyGeneral(dest);
                }
                else if(choice=="dapo_from" && from != NULL && from->isAlive()){
                    from->showGeneral(true);
                    room->transformHeadGeneral(from);
                }
            }
        }
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *touma = ask_who;
        QString prompt = "show:" + damage.from->objectName() + ":" + damage.to->objectName();
        if (damage.from && touma && touma->askForSkillInvoke(this, prompt)) {
            room->broadcastSkillInvoke(objectName(), touma);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *touma = ask_who;
        ServerPlayer *dest = damage.to;
        room->doLightbox("SE_Dapo$", 1500);
        if (!touma||touma->isKongcheng()||damage.from->isKongcheng())
            return false;
        PindianStruct *pd = touma->pindianSelect(damage.from, objectName());
        if (touma->pindian(pd)) {
            damage.to=touma;
            data.setValue(damage);
            touma->drawCards(1);
            room->setPlayerFlag(touma,"dapo_state");
            room->setPlayerFlag(dest,"dapo_to");
            room->setPlayerFlag(damage.from,"dapo_from");
            const Card *slash = room->askForUseSlashTo(touma, damage.from, "@dapo-slash", false);
            room->setPlayerFlag(touma,"-dapo_state");
            room->setPlayerFlag(dest,"-dapo_to");
            room->setPlayerFlag(damage.from,"-dapo_from");
        }
        return false;
    }
};

class Vector : public TriggerSkill
{
public:
    Vector() : TriggerSkill("vector")
    {
        frequency = NotFrequent;
        events << CardEffect;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardEffectStruct effect = data.value<CardEffectStruct>();
        QList<ServerPlayer *> targets;
        foreach(ServerPlayer *p, room->getOtherPlayers(player)){
            if (!effect.from || !Sanguosha->isProhibited(effect.from, p, effect.card))
                targets.append(p);
        }
        if (TriggerSkill::triggerable(player) && targets.count() > 0 && !player->isKongcheng() && effect.to && effect.to == player && (effect.card->isKindOf("BasicCard")||effect.card->isNDTrick())){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardEffectStruct effect = data.value<CardEffectStruct>();
        QList<ServerPlayer *> targets;
        foreach(ServerPlayer *p, room->getOtherPlayers(player)){
            if (!effect.from || !Sanguosha->isProhibited(effect.from, p, effect.card))
                targets.append(p);
        }
        if (player->askForSkillInvoke(this, data)) {
            ServerPlayer *target = room->askForPlayerChosen(player, targets, objectName(), QString("@vector-select:%1::%2").arg(effect.from != NULL ? effect.from->objectName() : "No Source", effect.card->objectName()), true, true);
            if (target && room->askForCard(player, "BasicCard", QString("@vector-discard:%1::%2").arg(effect.from != NULL ? effect.from->objectName() : "No Source", effect.card->objectName()), data, objectName())) {
                player->tag["vector_target"] = QVariant::fromValue(target);
                return true;
            }
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardEffectStruct effect = data.value<CardEffectStruct>();
        effect.to = player->tag["vector_target"].value<ServerPlayer *>();
        room->broadcastSkillInvoke(objectName());
        room->doLightbox(objectName() + "$", 800);
        data.setValue(effect);
    }
};

BianhuaCard::BianhuaCard()
{
    target_fixed = true;
}

void BianhuaCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    QList<int> cards = room->getNCards(5);
    QList<int> left = cards;
    room->fillAG(cards, player);
    int id = room->askForAG(player, cards, false, objectName());
    room->obtainCard(player, id);
    left.removeOne(id);
    room->clearAG(player);
    CardsMoveStruct move = CardsMoveStruct();
    move.card_ids = left;
    move.to_place = Player::DiscardPile;
    room->moveCardsAtomic(move, true);
}

class Bianhua : public OneCardViewAsSkill
{
public:
    Bianhua() : OneCardViewAsSkill("bianhua"){

    }

    bool viewFilter(const Card *card) const
    {
        return true;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        BianhuaCard *card = new BianhuaCard();
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("BianhuaCard")<2;
    }
};

class Paojivs : public ViewAsSkill
{
public:
    Paojivs() :ViewAsSkill("paoji")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->hasSkill(objectName());
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "slash" && player->hasSkill("paoji");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() == 0 && to_select->isBlack();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        Card *vs = Sanguosha->cloneCard("thunder_slash");
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        vs->addSubcards(cards);
        return vs;
    }
};

class Paoji : public TriggerSkill
{
public:
    Paoji() :TriggerSkill("paoji")
    {
        events << SlashMissed;
        frequency = NotFrequent;
        view_as_skill = new Paojivs;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        if (effect.slash->objectName() == "thunder_slash") return QStringList(objectName());
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *mikoto, QVariant &data, ServerPlayer *) const
    {
        if (mikoto->askForSkillInvoke(this, data)) {
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, mikoto->objectName(), data.value<SlashEffectStruct>().to->objectName());
            room->broadcastSkillInvoke(objectName(), mikoto);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *mikoto, QVariant &data, ServerPlayer *) const
    {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        QStringList list;
        list <<"draw_one_card" << "slash_to_target";
        Card *s = Sanguosha->cloneCard("drowning");
        if (!mikoto->isProhibited(effect.to, s) && effect.to->getEquips().length()>0){
            list << "paoji_drown";
        }
        QString choice = room->askForChoice(mikoto, objectName(), list.join("+")  , data);
        if (choice == "draw_one_card"){
            mikoto->drawCards(1);
        }
        else if(choice == "slash_to_target"){
            const Card *slash = room->askForUseSlashTo(mikoto, effect.to, "@paoji-slash", false);
        }
        else{
            CardUseStruct use;
            use.from = mikoto;
            use.to << effect.to;
            use.card = s;
            room->useCard(use);
        }
        return false;
    }
};

class PaojiTargetMod : public TargetModSkill
{
public:
  PaojiTargetMod() : TargetModSkill("#paoji-1")
  {
  }

  int getDistanceLimit(const Player *from, const Card *card) const
  {
      if (card->getSkillName()=="paoji" )
          return 1000;
      else
          return 0;
  }
};

class Dianci : public TriggerSkill
{
public:
    Dianci() : TriggerSkill("dianci")
    {
        events << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == CardsMoveOneTime && TriggerSkill::triggerable(player) && player->getPhase() == Player::NotActive) {
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from == player && (move.from_places.contains(Player::PlaceHand) || move.from_places.contains(Player::PlaceEquip))
                && !(move.to == player && (move.to_place == Player::PlaceHand || move.to_place == Player::PlaceEquip))) {
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *mikoto) const
    {
        if (mikoto->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), mikoto);
            return true;
        }

        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *, QVariant &, ServerPlayer *mikoto) const
    {
        QString choice = room->askForChoice(mikoto, objectName(), "chain_target+know_target");
        if (choice == "chain_target"){
            ServerPlayer *dest = room->askForPlayerChosen(mikoto, room->getAlivePlayers(), objectName(), QString(), false, true);
            room->setPlayerProperty(dest, "chained", QVariant(!dest->isChained()));
        }
        else {
            ServerPlayer *dest = room->askForPlayerChosen(mikoto, room->getOtherPlayers(mikoto),objectName());
            Card *card = Sanguosha->cloneCard("known_both", Card::NoSuit, -1);
            card->setSkillName(objectName());
            room->useCard(CardUseStruct(card, mikoto, dest));
        }
        return false;
    }
};

class Gaoxiao : public DrawCardsSkill
{
public:
   Gaoxiao() : DrawCardsSkill("gaoxiao")
    {
        frequency = Compulsory;
    }

    bool canPreshow() const
    {
        return true;
    }

    bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (player->hasShownSkill(objectName())||player->askForSkillInvoke(this)) {
            room->broadcastSkillInvoke(objectName(), qrand() % 2 + 1, player);
            return true;
        }
        return false;
    }

    int getDrawNum(ServerPlayer *redo, int n) const
    {
        Room *room = redo->getRoom();
        room->sendCompulsoryTriggerLog(redo, objectName());

        return n + 1;
    }
};

class GaoxiaoTargetMod : public TargetModSkill
{
public:
  GaoxiaoTargetMod() : TargetModSkill("#gaoxiao-1")
  {
  frequency = Compulsory;
  }

  int getDistanceLimit(const Player *from, const Card *card) const
  {
      if (from->hasShownSkill("gaoxiao") )
          return 1000;
      else
          return 0;
  }
};

class Gaokang : public TriggerSkill
{
public:
    Gaokang() : TriggerSkill("gaokang")
    {
        frequency = NotFrequent;
        events << DamageInflicted;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        DamageStruct damage = data.value<DamageStruct>();
        if (player == NULL ) return skill_list;

                  QList<ServerPlayer *> redos = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *redo, redos)
                if (redo->canDiscard(redo, "he") && !redo->isKongcheng())
                    if (redo->distanceTo(damage.to) <= 1 && redo->distanceTo(damage.to)>-1)
                    skill_list.insert(redo, QStringList(objectName()));
            return skill_list;




    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *redo = ask_who;

        if (redo != NULL) {
            redo->tag["gaokang_data"] = data;
            DamageStruct damage = data.value<DamageStruct>();
            bool invoke = redo->askForSkillInvoke(this, QVariant::fromValue(damage.to)) && room->askForCard(redo, ".|black|.|hand", "@gaokang", data);
            redo->tag.remove("gaokang_data");

            if (invoke) {
                room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, redo->objectName(), data.value<DamageStruct>().to->objectName());
                room->broadcastSkillInvoke(objectName(), redo);
                return true;
            }
        }
        return false;
    }
    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *redos = ask_who;
                damage.damage -= 1;
                 data.setValue(damage);

                 if (damage.damage < 1)
                     return true;

        return false;
    }
};

class Jiasugaobai : public TriggerSkill
{
public:
    Jiasugaobai() : TriggerSkill("jiasugaobai")
    {
        frequency = NotFrequent;
        events << TargetConfirming << CardEffected;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == TargetConfirming){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card->isKindOf("Duel")){
                return QStringList(objectName());
            }
        }
        else{
            CardEffectStruct effect = data.value<CardEffectStruct>();
            if (effect.card->hasFlag("jiasugaobai")){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event== TargetConfirming && player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer *> list;
            foreach(ServerPlayer *p, room->getOtherPlayers(player)){
                if (p->isMale()){
                    list << p;
                }
            }
            ServerPlayer *dest = room->askForPlayerChosen(player, list, objectName(),QString(), true, true);
            if (dest){
                player->tag["gaobaikuro_target"] = QVariant::fromValue(dest);
                return true;
            }
        }
        else if(event== CardEffected){
            return true;
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event== TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            room->broadcastSkillInvoke(objectName(), player);
            ServerPlayer *dest = player->tag["gaobaikuro_target"].value<ServerPlayer *>();
            if (dest){
                dest->drawCards(1);
                use.card->setFlags("jiasugaobai");
            }
        }
        else{
            CardEffectStruct effect = data.value<CardEffectStruct>();
            DamageStruct d;
            d.from=effect.from;
            d.to=effect.to;
            d.damage=1;
            d.card=effect.card;
            room->damage(d);
            return true;
        }
        return false;
    }
};

class Juedoujiasu : public TriggerSkill
{
public:
    Juedoujiasu() : TriggerSkill("juedoujiasu")
    {
        frequency = NotFrequent;
        events << TargetConfirming <<CardUsed << CardFinished << Damaged;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == TargetConfirming || event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card->isKindOf("Duel")){
                return QStringList(objectName());
            }
        }
        else if(event==CardFinished){
            CardUseStruct use = data.value<CardUseStruct>();
            if(use.card->hasFlag("jdjs")){
                if (use.from->hasFlag("jdjs")){
                    use.from->drawCards(1);
                    room->setPlayerFlag(use.from,"-jdjs");
                }
                foreach(ServerPlayer *to, use.to){
                    if (to->hasFlag("jdjs")){
                        to->drawCards(1);
                        room->setPlayerFlag(to,"-jdjs");
                    }
                }
            }
            room->setCardFlag(use.card, "-jdjs");
        }
        else if(event == Damaged){
           DamageStruct damage = data.value<DamageStruct>();
           if (damage.card && damage.card->hasFlag("jdjs")){
               room->setPlayerFlag(player,"jdjs");
           }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if ((event== TargetConfirming || event == CardUsed )&& player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event== TargetConfirming|| event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            room->broadcastSkillInvoke(objectName(), player);
            player->drawCards(1);
            use.card->setFlags("jdjs");
        }
        return false;
    }
};

class Sexunyu : public TriggerSkill
{
public:
    Sexunyu() : TriggerSkill("sexunyu")
    {
        frequency = NotFrequent;
        events << TargetConfirming << TargetConfirmed;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == TargetConfirming){
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card->isKindOf("Slash") && use.card->isBlack()){
                return QStringList(objectName());
            }
        }
        else{
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card->isKindOf("Slash") && use.card->isBlack() && player==use.from){
                return QStringList(objectName());
            }
        }
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
        if (event== TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            use.to.clear();
            data.setValue(use);
            Card *duel = Sanguosha->cloneCard("duel");
            duel->setSkillName(objectName());
            CardUseStruct u = CardUseStruct();
            u.card = duel;
            u.from = use.from;
            u.to << player;
            room->useCard(u);
            room->broadcastSkillInvoke(objectName(),player);
        }
        else{
            CardUseStruct use = data.value<CardUseStruct>();
            Card *duel = Sanguosha->cloneCard("duel");
            duel->setSkillName(objectName());
            CardUseStruct u = CardUseStruct();
            u.card = duel;
            u.from = player;
            u.to =use.to;
            room->useCard(u);
            use.to.clear();
            data.setValue(use);
            room->broadcastSkillInvoke(objectName(),player);
        }
        return false;
    }
};

class Shuangqiang : public TriggerSkill
{
public:
    Shuangqiang() : TriggerSkill("shuangqiang")
    {
        frequency = NotFrequent;
        events << CardUsed;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player)&& use.to.count() > 0 && use.card->getNumber()%2==0 && use.card->getNumber()>0 && use.card->getTypeId()!= Card::TypeSkill){
            foreach(auto p, use.to){
                if (!player->hasFlag(p->objectName()+"shuangqiang")&&(!room->getCurrent()||!room->getCurrent()->hasFlag(p->objectName()+"shuangqiang"))){
                    return QStringList(objectName());
                }
            }
        }
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
        CardUseStruct use = data.value<CardUseStruct>();
        QList<ServerPlayer*> list;
        foreach(auto p, use.to){
            if (!player->hasFlag(p->objectName()+"shuangqiang")&&(!room->getCurrent()||!room->getCurrent()->hasFlag(p->objectName()+"shuangqiang"))){
                list<<p;
            }
        }
        ServerPlayer *target=room->askForPlayerChosen(player,list,objectName());
        if (player->getPhase()!=Player::NotActive)
            room->setPlayerFlag(player, target->objectName()+"shuangqiang");
        else if (room->getCurrent())
            room->setPlayerFlag(room->getCurrent(),target->objectName()+"shuangqiang");
        room->broadcastSkillInvoke(objectName(),player);
        room->doLightbox("SE_Shuangqiang$", 800);
        if (!target->isAllNude()){
            int id=room->askForCardChosen(player,target,"hej",objectName());
            room->throwCard(id, target, player);
        }
        return false;
    }
};

class Wujie : public TriggerSkill
{
public:
    Wujie() : TriggerSkill("wujie")
    {
        frequency = NotFrequent;
        events << Damage;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
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
        DamageStruct damage = data.value<DamageStruct>();
        QList<ServerPlayer *> list;
        QList<ServerPlayer *> list2;
        foreach(ServerPlayer *p, room->getAlivePlayers()){
            if (p->isFriendWith(player)&&p->inMyAttackRange(damage.to)){
                list.append(p);
            }
            if (p->isFriendWith(player)){
                list2.append(p);
            }
        }
        QString choices="wujie_givecard";
        if (list.count()>0)
            choices="wujie_givecard+wujie_drawcard";
        QString choice=room->askForChoice(player,objectName(),choices,data);
        if (choice=="wujie_givecard"){
            ServerPlayer *target=room->askForPlayerChosen(player,list2,objectName());
            room->broadcastSkillInvoke(objectName(),player);
            room->doLightbox("SE_Xinlai$", 800);
            if (!player->isNude()){
                int id=room->askForCardChosen(player,player,"he",objectName());
                room->obtainCard(target,id);
            }
        }
        else{
            ServerPlayer *target=room->askForPlayerChosen(player,list,objectName());
            room->broadcastSkillInvoke(objectName(),player);
            room->doLightbox("SE_Xinlai$", 800);
            target->drawCards(1);
        }
        return false;
    }
};

class Huanxing : public TriggerSkill
{
public:
    Huanxing() : TriggerSkill("huanxing")
    {
        frequency = NotFrequent;
        events << TargetConfirming << EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==TargetConfirming && TriggerSkill::triggerable(player)&&player->getPhase()==Player::NotActive&&player->getMark("huanxing_used")==0){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("Slash")||use.card->isNDTrick()){
                return QStringList(objectName());
            }
        }
        else{
            if (player->getPhase()==Player::Finish){
                foreach(ServerPlayer *p, room->getAlivePlayers()){
                    room->setPlayerMark(p,"huanxing_used",0);
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(use.from)) && room->askForUseSlashTo(player, use.from, "@huanxing-slash", false)) {
                room->setPlayerMark(player,"huanxing_used",1);
            //const Card *card = room->askForUseCard(player, "TrickCard+^Nullification,BasicCard+^Jink,EquipCard|.|.|hand", "@huanxing");
                room->broadcastSkillInvoke(objectName(), player);
                room->doLightbox("huanxing$", 300);
                return true;
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {        
        CardUseStruct use = data.value<CardUseStruct>();
        use.to.removeOne(player);
        data.setValue(use);
        return false;
    }
};

class Fushang : public TriggerSkill
{
public:
    Fushang() : TriggerSkill("fushang")
    {
        frequency = NotFrequent;
        events << EventPhaseEnd;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)&&player->getPhase()==Player::Finish){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer *> list;
            foreach(ServerPlayer *p, room->getAlivePlayers()){
                if (p->isWounded()){
                    list<<p;
                }
            }
            ServerPlayer *dest=room->askForPlayerChosen(player, list, objectName(),QString(),true,true);
            if (dest){
                player->tag["fushang_target"] = QVariant::fromValue(dest);
                return true;
            }
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        room->broadcastSkillInvoke(objectName(), player);
        ServerPlayer *dest = player->tag["fushang_target"].value<ServerPlayer *>();
        if (dest) {
            dest->drawCards(1);
            if (dest->getJudgingArea().length()>0){
                int id = room->askForCardChosen(player,dest,"j",objectName());
                room->throwCard(id,dest,player);
            }
        }
        return false;
    }
};

class Nangua : public TriggerSkill
{
public:
    Nangua() : TriggerSkill("nangua")
    {
        events << Dying << HpRecover;
        frequency = Frequent;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)){
            if (event == Dying){
                DyingStruct dying = data.value<DyingStruct>();
                if (dying.who==player){
                    return QStringList(objectName());
                }
            }
            else if (event == HpRecover){
                RecoverStruct re = data.value<RecoverStruct>();
                if (re.who && re.who->getHp() < 2 && re.who==player){
                    return QStringList(objectName());
                }
            }
        }
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
        if (event==Dying){
            room->broadcastSkillInvoke(objectName(), player);
            player->drawCards(3);
        }
        else if (event == HpRecover){
            if (room->askForChoice(player, objectName(), "nangua_recover+nangua_turnover", data) == "nangua_recover"){
                if (player->getHp() < 1){
                    RecoverStruct recover;
                    recover.recover = 1 - player->getHp();
                    recover.who=player;
                    room->recover(player, recover);
                    room->setPlayerProperty(player, "hp", 1);
                }
            }
            else{
                player->turnOver();
            }
        }
        return false;
    }
};

class Jixian : public TriggerSkill
{
public:
    Jixian() : TriggerSkill("jixian")
    {
        events << EventPhaseEnd;
    }

    void doJixian(Room *room, ServerPlayer *player, QVariant &data) const
    {
        ServerPlayer *p = player->tag["jixian_target"].value<ServerPlayer *>();
        if (p){
            int num = player->getLostHp();
            if (num<=0){
                num=1;
            }
            if (num > 2){
                room->broadcastSkillInvoke(objectName(), 1, player);
            }
            else{
                room->broadcastSkillInvoke(objectName(), 2, player);
            }
            room->damage(DamageStruct(objectName(), player, p, num));
            if (num > 1){
                room->detachSkillFromPlayer(player, objectName(), false, false, player->inHeadSkills(this));
                room->loseHp(player);
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)){
            if (player->isNude()){
                return QStringList();
            }
            if (event == EventPhaseEnd && player->getPhase()==Player::Finish){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (!player->isNude()&&player->askForSkillInvoke(this, data)) {
            ServerPlayer *p = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), QString(), true, true);
            if (p){
                if (room->askForDiscard(player, objectName(), 1, 1, false, true)){
                    player->tag["jixian_target"] = QVariant::fromValue(p);
                    return true;
                }
            }
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        doJixian(room, player, data);
        return false;
    }
};

class Qixin : public TriggerSkill
{
public:
    Qixin() : TriggerSkill("qixin")
    {
        frequency = Frequent;
        events << TargetChosen;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.to.isEmpty() && use.from==player && TriggerSkill::triggerable(player) && (use.card->isKindOf("Slash")||use.card->isKindOf("Duel")) && (!room->getCurrent()||!room->getCurrent()->hasFlag("qixin_used"))){
            QStringList targets;
            foreach (ServerPlayer *to, use.to) {
                targets << to->objectName();
            }
            if (!targets.isEmpty())
                return QStringList(objectName() + "->" + targets.join("+"));
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (ask_who->askForSkillInvoke(this, QVariant::fromValue(player))) {
            if (room->getCurrent()){
                room->setPlayerFlag(room->getCurrent(), "qixin_used");
            }
            room->broadcastSkillInvoke(objectName(), ask_who);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *player) const
    {
        room->doLightbox("SE_Qixin$", 800);
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *source = use.from;
        QList<ServerPlayer *> alls;
        foreach(ServerPlayer *p, room->getOtherPlayers(player)){
            alls.append(p);
        }
            room->sortByActionOrder(alls);
            foreach(ServerPlayer *anjiang, alls) {
                if (anjiang->hasShownOneGeneral()) continue;

                QString kingdom = source->getKingdom();
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

                bool full = (source->getRole() == "careerist" || ((lord == NULL || !lord->hasShownGeneral1()) && num >= room->getPlayers().length() / 2));

                if (anjiang->getKingdom() == kingdom && !full) {
                    anjiang->askForGeneralShow(false, true);
                }
                else{
                    room->askForChoice(anjiang,objectName(),"cannot_showgeneral+cancel",data);
                }
            }
            if (source->getRole() != "careerist") {
                QList<ServerPlayer *> all_lieges = room->getLieges(source->getKingdom(), source);
                foreach (ServerPlayer *p, all_lieges) {
                    if (p->inMyAttackRange(target)&&!room->askForUseSlashTo(p,target,"qixin:"+target->objectName(),false)){
                        p->drawCards(1);
                    }
                }
            }
            bool invoke = true;
            int n = source->getPlayerNumWithSameKingdom(objectName(), QString(), MaxCardsType::Normal);
            foreach (auto p, room->getOtherPlayers(player)) {
                /*if (kingdom == "god") continue;
                if (dfowner->getRole() == "careerist") {
                    if (kingdom == "careerist")
                        continue;
                } else if (dfowner->getKingdom() == kingdom)
                    continue;*/
                int other_num = p->getPlayerNumWithSameKingdom("AI", p->getKingdom(), MaxCardsType::Normal);
                if (other_num > 0 && other_num < n) {
                    invoke = false;
                    break;
                }
            }

            if (invoke) {
                player->drawCards(1);
            }
    }
};

class Juejue : public TriggerSkill
{
public:
    Juejue() : TriggerSkill("juejue")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << EventPhaseEnd << GeneralShown;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase()==Player::Start && !player->isNude()){
            return QStringList(objectName());
        }
        if (event==EventPhaseEnd && player->getPhase()==Player::Finish){
            foreach(ServerPlayer *p, room->getAlivePlayers()){
                foreach(ServerPlayer *q, room->getAlivePlayers()){
                    if (p->getMark("juejue"+q->objectName())>0){
                        room->setFixedDistance(p,q,-1);
                        p->setMark("juejue"+q->objectName(),p->getMark("juejue"+q->objectName())-1);
                    }
                }
            }
        }
        if (event == GeneralShown){
            ServerPlayer *eren = room->getCurrent();
            ServerPlayer *target = eren->tag["juejue_target"].value<ServerPlayer *>();
            if (eren && target && eren->getMark("juejue"+target->objectName())>0){
                foreach(auto p, room->getAlivePlayers()){
                    if (p->isFriendWith(eren) && p->getMark("juejue"+target->objectName())==0){
                        room->setFixedDistance(p,target,1);
                        p->setMark("juejue"+target->objectName(),p->getMark("juejue"+target->objectName())+1);
                    }
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseStart&&player->askForSkillInvoke(this, data)) {
            ServerPlayer *target=room->askForPlayerChosen(player,room->getOtherPlayers(player),objectName(),QString(),true,true);
            if (target && room->askForDiscard(player,objectName(),1,1,true,true,QString(),true)){
                player->tag["juejue_target"] = QVariant::fromValue(target);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag["juejue_target"].value<ServerPlayer *>();
        if (target){
            room->broadcastSkillInvoke(objectName(),player);
            room->doLightbox("se_chouyuan$", 1000);
            foreach(ServerPlayer *p, room->getAlivePlayers()){
                if (p->isFriendWith(player)){
                    room->setFixedDistance(p,target,1);
                    p->setMark("juejue"+target->objectName(),p->getMark("juejue"+target->objectName())+1);
                }
            }
        }
    }
};

class Xianjing : public TriggerSkill
{
public:
    Xianjing() : TriggerSkill("xianjing")
    {
        frequency = NotFrequent;
        events << EventPhaseStart << TargetConfirming;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.from && event==TargetConfirming && TriggerSkill::triggerable(player) && use.card->getSuit()!=Card::NoSuit && use.card->getSuit()!=Card::NoSuitBlack && use.card->getSuit()!=Card::NoSuitRed && use.from!=player && player->getPile("bomb").length()>0 && use.card->getTypeId()!=Card::TypeSkill){
            return QStringList(objectName());
        }
        if (event==EventPhaseStart && player->getPhase()==Player::Finish && TriggerSkill::triggerable(player) && player->getPile("bomb").length()<4){
            return QStringList(objectName());
        }
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
       if (event==EventPhaseStart){
           room->broadcastSkillInvoke(objectName(),player);
           player->drawCards(1);
           if (!player->isKongcheng()){
               player->addToPile("bomb", room->askForCardChosen(player,player,"h",objectName()), false);
           }
       }
       else{
           CardUseStruct use = data.value<CardUseStruct>();
           QList<int> list;
           foreach(int id, player->getPile("bomb")){
               Card *card = Sanguosha->getCard(id);
               if (card->getSuit()==use.card->getSuit()){
                   list << id;
               }
           }
           if (list.length()>0){
               room->fillAG(list ,player);
               int id = room->askForAG(player, list, true, objectName());
               room->clearAG(player);
               if (id < 0) return false;
               room->throwCard(id, player, player);
               room->broadcastSkillInvoke(objectName(),player);
               room->damage(DamageStruct(objectName(), player, use.from));
               if (use.from->getHandcardNum()>use.from->getHp()){
                   room->askForDiscard(use.from, objectName(), use.from->getHandcardNum()-use.from->getHp(), use.from->getHandcardNum()-use.from->getHp(), false, false);
               }
           }
       }
       return false;
    }
};

class XianjingClear : public DetachEffectSkill
{
public:
    XianjingClear() : DetachEffectSkill("xianjing", "bomb")
    {
        frequency = Compulsory;
    }
};

//game
class Mengfeng : public TriggerSkill
{
public:
    Mengfeng()
        : TriggerSkill("mengfeng")
    {
        events << CardUsed << CardResponded << EventPhaseStart;
    }


    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==EventPhaseStart && player->getPhase()==Player::Start){
            room->removePlayerDisableShow(player, objectName());
        }
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card && use.card->getSuit() == Card::Heart && use.card->getTypeId() != Card::TypeSkill) {
                if (use.from && TriggerSkill::triggerable(player)) {
                    return QStringList(objectName());
                }
            }
        } else if (event == CardResponded) {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_card && resp.m_card->getSuit() == Card::Heart) {
                if (resp.m_who && TriggerSkill::triggerable(player)) {
                    return QStringList(objectName());
                }
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->hasShownSkill(objectName())||player->askForSkillInvoke(this, data)) {
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), "@tuizhi", true, true);
            if (target)
                player->tag["tuizhi_target"] = QVariant::fromValue(target);
            return target != NULL;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag["tuizhi_target"].value<ServerPlayer *>();
        room->broadcastSkillInvoke(objectName(),player);
        target->drawCards(1);
        QString choices = "mengfeng_hide";
        if (!room->getCurrent()->hasFlag(player->objectName()+"mengfeng_tans"+target->objectName())){
            choices = "mengfeng_trans+mengfeng_hide";
        }
        QString choice = room->askForChoice(player, objectName(), choices, data);
        if (choice == "mengfeng_trans" && room->askForChoice(target,"transform","transform+cancel",data)=="transform"){
            room->setPlayerFlag(room->getCurrent(),player->objectName()+"mengfeng_tans"+target->objectName());
            target->showGeneral(false);
            room->transformDeputyGeneral(target);
        }
        else if (choice == "mengfeng_hide"){
            QList<ServerPlayer *> list;
            foreach(auto p, room->getAlivePlayers()){
                if (p->hasShownOneGeneral() && !p->isFriendWith(player) && ((p->hasShownGeneral1() && p->getActualGeneral1()->objectName()!="sujiang" && p->getActualGeneral1()->objectName()!="sujiangf") || (p->hasShownAllGenerals() && p->getActualGeneral2()->objectName()!="sujiang" && p->getActualGeneral2()->objectName()!="sujiangf")) )
                    list << p;
            }
            if (list.length()>0){
                ServerPlayer *tar = room->askForPlayerChosen(player, list, objectName()+"hide", "@mengfeng", true);
                if (!tar) return false;
                QStringList choices;
                if (tar->hasShownGeneral1() && (tar->getActualGeneral1()->objectName()!="sujiang" && tar->getActualGeneral1()->objectName()!="sujiangf") ){
                    choices <<tar->getActualGeneral1Name();
                }
                if (tar->hasShownGeneral2() && (tar->getActualGeneral2()->objectName()!="sujiang" && tar->getActualGeneral2()->objectName()!="sujiangf") ){
                    choices << tar->getActualGeneral2Name();
                }
                QString general="";
                if (!choices.isEmpty()){
                    general=room->askForGeneral(player,choices.join("+"),QString(),true,objectName(),data);
                    if (general==tar->getActualGeneral1Name()){
                        if (tar->hasShownGeneral1()){
                            tar->hideGeneralWithoutChangingRole(true);
                        }
                        room->setPlayerDisableShow(tar, "h", objectName());
                    }
                    else{
                        if (tar->hasShownGeneral2()){
                            tar->hideGeneralWithoutChangingRole(false);
                        }
                        room->setPlayerDisableShow(tar, "d", objectName());
                    }
                }
            }
        }
        return false;
    }
};

ReimugiveCard::ReimugiveCard()
{
    will_throw = false;
    m_skillName = "reimugive";
}

bool ReimugiveCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select->hasSkill("saiqian") && targets.length() == 0 && to_select != Self;
}

void ReimugiveCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.at(0);
    if (!target)
        return;
    room->broadcastSkillInvoke("saiqian", target);
    room->obtainCard(target, this, false);
    if (!target->isNude() && player->isWounded() && room->askForCard(target, ".|red|.|.", "@saiqian:" + player->objectName(), QVariant::fromValue(player))){
        RecoverStruct recover;
        recover.recover = 1;
        recover.who = target;
        room->recover(player, recover, true);
    }
}

class Reimugive : public ViewAsSkill
{
public:
    Reimugive() : ViewAsSkill("reimugive")
    {
        attached_lord_skill = true;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("ReimugiveCard");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *) const
    {
        return selected.length() < 2;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        ReimugiveCard *zrc = new ReimugiveCard();
        zrc->addSubcards(cards);
        zrc->setSkillName(objectName());
        zrc->setShowSkill(objectName());
        return zrc;
    }
};

class Saiqian : public TriggerSkill
{
public:
    Saiqian()
        : TriggerSkill("saiqian")
    {
        events << GeneralShown << EventAcquireSkill << GeneralTransformed;
        frequency = NotFrequent;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const{
        if ((event==GeneralShown||event==GeneralTransformed)&&TriggerSkill::triggerable(player)&&player->inHeadSkills(this)==data.toBool()){
            foreach(auto p, room->getOtherPlayers(player)){
                room->attachSkillToPlayer(p, "reimugive");
            }
        }
        else if (event==EventAcquireSkill){
            if (data.toString().split(":").first()==objectName()){
                foreach(auto p, room->getOtherPlayers(player)){
                    room->attachSkillToPlayer(p, "reimugive");
                }
            }
        }
        return QStringList();
    }
};

class Tongjie : public TriggerSkill
{
public:
    Tongjie()
        : TriggerSkill("tongjie")
    {
        events << GeneralShown << GeneralHidden << GeneralRemoved << EventPhaseStart << Death << EventAcquireSkill << EventLoseSkill;
        frequency = Compulsory;
    }

    void doTongjie(Room *room, ServerPlayer *reimu, bool set) const
    {
        if (set && !reimu->tag["tongjie"].toBool()) {
            foreach (ServerPlayer *p, room->getOtherPlayers(reimu))
                room->setPlayerDisableShow(p, "hd", "tongjie");

            reimu->tag["tongjie"] = true;
        } else if (!set && reimu->tag["tongjie"].toBool()) {
            foreach (ServerPlayer *p, room->getOtherPlayers(reimu))
                room->removePlayerDisableShow(p, "tongjie");

            reimu->tag["tongjie"] = false;
        }
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {

        if (player == NULL)
            return ;
        if (event != Death && !player->isAlive())
            return ;
        ServerPlayer *c = room->getCurrent();
        if (c == NULL || (event != EventPhaseStart && c->getPhase() == Player::NotActive) || c != player)
            return ;

        if ((event == GeneralShown || event == EventPhaseStart || event == EventAcquireSkill) && !player->hasShownSkill(this))
            return ;
        if ((event == GeneralShown || event == GeneralHidden) && (!player->ownSkill(this) || player->inHeadSkills(this) != data.toBool()))
            return ;
        if (event == GeneralRemoved && data.toString() != "Reimu")
            return ;
        if (event == EventPhaseStart && !(player->getPhase() == Player::RoundStart || player->getPhase() == Player::NotActive))
            return ;
        if (event == Death && (data.value<DeathStruct>().who != player || !player->hasShownSkill(this)))
            return ;
        if ((event == EventAcquireSkill || event == EventLoseSkill) && data.toString().split(":").first() != objectName())
            return ;

        bool set = false;
        if (event == GeneralShown || event == EventAcquireSkill || (event == EventPhaseStart && player->getPhase() == Player::RoundStart))
            set = true;

        doTongjie(room, player, set);
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (ask_who->hasShownSkill(objectName())||ask_who->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;

        if (player == NULL) return skill_list;
        if (event == GeneralShown) {
            bool s = data.toBool();
            ServerPlayer *target = player;
            if (target && target->isAlive()) {
                foreach (ServerPlayer *p, room->findPlayersBySkillName(objectName())) {
                    if (p != target)
                        skill_list.insert(p, QStringList(objectName()));
                }
            }
        }
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        room->notifySkillInvoked(ask_who, objectName());
        ask_who->drawCards(1);
        return false;
    }
};

class Mingqie : public TriggerSkill
{
public:
    Mingqie() : TriggerSkill("mingqie")
    {
        frequency = NotFrequent;
        events << CardUsed;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player)&& use.to.count() > 0 && use.card->getSuit() == Card::Spade && use.card->getTypeId()!= Card::TypeSkill && (!use.to.contains(player)||use.to.length()>1)){
            return QStringList(objectName());
        }
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
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.to.contains(player))
            use.to.removeOne(player);
        ServerPlayer *target=room->askForPlayerChosen(player,use.to,objectName());
        room->broadcastSkillInvoke(objectName(),player);
        if (!target->isAllNude()){
            int id=room->askForCardChosen(player,target,"hej",objectName());
            if (id != use.card->getEffectiveId()){
               room->obtainCard(player, id, false);
            }
        }
        return false;
    }
};

class Mopao : public TriggerSkill
{
public:
    Mopao() : TriggerSkill("mopao")
    {
        frequency = NotFrequent;
        events << CardsMoveOneTime << EventPhaseEnd;
        relate_to_place = "head";
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==CardsMoveOneTime){
            auto move = data.value<CardsMoveOneTimeStruct>();
            if (TriggerSkill::triggerable(player)&& move.to && move.to == player && move.to_place == Player::PlaceHand && player->getPhase() == Player::Play){
                player->addMark("mopao_gain");
            }
        }
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==EventPhaseEnd){
            if (TriggerSkill::triggerable(player)&& player->getPhase()==Player::Play && player->getMark("mopao_gain") >=2){
                room->setPlayerMark(player, "mopao_gain", 0);
                return QStringList(objectName());
            }
            room->setPlayerMark(player, "mopao_gain", 0);
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            ServerPlayer *target = room->askForPlayerChosen(player, room->getAlivePlayers(), objectName(), QString(), true);
            if (target){
                auto list = target->getFormation();
                bool discard = room->askForDiscard(player, objectName(), list.length(), list.length(), true, true);
                if (discard){
                   room->broadcastSkillInvoke(objectName(), player);
                   player->tag["mopao_target"] = QVariant::fromValue(target);
                   return true;
                }
            }
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        ServerPlayer *target = player->tag["mopao_target"].value<ServerPlayer *>();
        if (target){
            auto list = target->getFormation();
            QList<ServerPlayer*> players;
            foreach(auto p, list){
                foreach(auto q, room->getAlivePlayers()){
                    if (p->objectName() == q->objectName())
                        players<<q;
                }
            }
            room->sortByActionOrder(players);
            foreach(auto p, players){
                auto damage = DamageStruct();
                damage.from = player;
                damage.to = p;
                room->damage(damage);
            }
        }
        return false;
    }
};

NuequCard::NuequCard()
{
    mute = true;
    will_throw = false;
}

bool NuequCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    FireSlash *s = new FireSlash(Card::NoSuit, 0);
    if (!targets.isEmpty() || Self->isProhibited(to_select, s)) return false;
    QList<const Player *> players = Self->getAliveSiblings();
    players << Self;
    int min = 1000;
    foreach(const Player *p, players) {
        if (min > p->getHp() && !p->isFriendWith(Self))
            min = p->getHp();
    }

    return to_select->getHp()==min && !to_select->isFriendWith(Self);
}

void NuequCard::use(Room *room, ServerPlayer *kongou, QList<ServerPlayer *> &targets) const
{
    Card *sub = Sanguosha->getCard(this->getSubcards().at(0));
    Card *card = Sanguosha->cloneCard("fire_slash", sub->getSuit(), sub->getNumber());
    card->addSubcard(sub->getEffectiveId());
    card->setSkillName("nuequ");
    room->useCard(CardUseStruct(card, kongou, targets), false);
}

class Nuequ : public ViewAsSkill
{
public:
    Nuequ() : ViewAsSkill("nuequ")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("NuequCard");
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() == 0 && !to_select->isEquipped();
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        NuequCard *nqc = new NuequCard();
        nqc->addSubcards(cards);
        nqc->setSkillName(objectName());
        nqc->setShowSkill(objectName());
        return nqc;
    }
};


class BurningLove : public TriggerSkill
{
public:
    BurningLove() : TriggerSkill("BurningLove")
    {
        frequency = NotFrequent;
        events << DamageCaused;
    }
    int getPriority(TriggerEvent) const
    {
        return -2;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (TriggerSkill::triggerable(player)&& damage.nature == DamageStruct::Fire && damage.from->isAlive() && damage.card && damage.card->isKindOf("FireSlash") && !damage.transfer && !damage.chain){
            return QStringList(objectName());
        }
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

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        room->broadcastSkillInvoke(objectName());
        QString choice = room->askForChoice(player, objectName(), "nuequ_chain+nuequ_discard", data);
        /*RecoverStruct recover;
        recover.recover = 1;
        recover.who = damage.to;
        room->recover(damage.to, recover, true);*/
        if (choice == "nuequ_chain"){
            foreach (auto p, room->getAlivePlayers()){
                if (p->isFriendWith(damage.to)&&!p->isChained()){
                    room->setPlayerProperty(p, "chained", QVariant(true));
                }
            }
        }
        else if(damage.to->getHp()>0){
            for(int i = 0; i < damage.to->getHp(); i++){
                if (damage.to->getEquips().length()>0){
                    int id = room->askForCardChosen(player,damage.to,"e",objectName());
                    room->throwCard(id, damage.to, player);
                }
            }
        }
        return false;
    }
};

class Weishi : public TriggerSkill
{
public:
    Weishi() : TriggerSkill("weishi")
    {
        events << EventPhaseStart;
        frequency = NotFrequent;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (TriggerSkill::triggerable(player)&& player->getPhase() == Player::Play && !player->isKongcheng()){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *kaga, QVariant &data, ServerPlayer *) const
    {
        room->broadcastSkillInvoke(objectName());
        QList<ServerPlayer *> targets;
        foreach(ServerPlayer *player, room->getOtherPlayers(kaga)){
            if (player->getPileNames().length() > 0 || player->isFriendWith(kaga)){
                targets.append(player);
            }
        }
        targets.append(kaga);
        ServerPlayer * target = room->askForPlayerChosen(kaga, targets, objectName());
        QStringList list;
        foreach(QString s, target->getPileNames()){
            if (target->getPile(s).length()>0 && !s.startsWith("#")){
                list.append(s);
            }
        }

        if (target->isFriendWith( kaga)){
            if (!list.contains("Kansaiki")){
                list.append("Kansaiki");
            }
        }
        if (list.isEmpty()) return false;
        QString choice = room->askForChoice(kaga, objectName(), list.join("+"));
        int id = room->askForCardChosen(kaga, kaga, "h", objectName(), true);
        target->addToPile(choice, id, true);
        Card *card = Sanguosha->getCard(id);
        if (card->isKindOf("BasicCard")){
            RecoverStruct recover;
            recover.recover = 1;
            recover.who = target;
            room->recover(target, recover, true);
        }
        else if(card->isKindOf("EquipCard")){
            kaga->drawCards(1);
        }
        return false;
    }
};

class WeishiRecord : public TriggerSkill
{
public:
    WeishiRecord() : TriggerSkill("#weishi-record")
    {
        events << CardsMoveOneTime;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==CardsMoveOneTime && TriggerSkill::triggerable(player)){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            int n =0;
            foreach(auto p, room->getAlivePlayers()){
                n= n+ p->getPile("Kansaiki").length();
            }
            room->setPlayerMark(player, "Kansaiki", n);
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer* &) const
    {
        return QStringList();
    }

};

class WeishiDistance : public DistanceSkill
{
  public:
    WeishiDistance(): DistanceSkill("#weishidistance")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->getPile("Kansaiki").length()>0)
            return -from->getPile("Kansaiki").length();
        else
            return 0;
    }
};

HongzhaCard::HongzhaCard()
{
    mute = true;
    will_throw = false;
}

bool HongzhaCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    Slash *s = new Slash(Card::NoSuit, 0);
    return to_select != Self && targets.length() < Self->getMark("Kansaiki") && Self->getHp() >= 2 && !Self->isProhibited(to_select, s);
}

void HongzhaCard::use(Room *room, ServerPlayer *kaga, QList<ServerPlayer *> &targets) const
{
    Card *sub = Sanguosha->getCard(this->getSubcards().at(0));
    Card *card = Sanguosha->cloneCard("slash", sub->getSuit(), sub->getNumber());
    card->addSubcard(sub->getEffectiveId());
    card->setSkillName("hongzha");
    room->useCard(CardUseStruct(card, kaga, targets), false);
}

class Hongzha : public ViewAsSkill
{
public:
    Hongzha() : ViewAsSkill("hongzha")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("HongzhaCard") && player->getMark("@FireCaused") == 0;
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() == 0 && to_select->isKindOf("BasicCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        HongzhaCard *hzc = new HongzhaCard();
        hzc->addSubcards(cards);
        hzc->setSkillName(objectName());
        hzc->setShowSkill(objectName());
        return hzc;
    }
};

class WeishiClear : public DetachEffectSkill
{
public:
    WeishiClear() : DetachEffectSkill("weishi", "Kansaiki")
    {
        frequency=Compulsory;
    }

};

class Jifeng : public TriggerSkill
{
public:
    Jifeng() : TriggerSkill("jifeng")
    {
        frequency = Frequent;
        events << EventPhaseEnd << EventPhaseChanging << HpChanged;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
   {
        if (event == EventPhaseChanging && data.value<PhaseChangeStruct>().to == Player::NotActive){
            foreach(ServerPlayer *p, room->getAlivePlayers()){
                if (p->hasFlag("jifeng_pro")){
                    room->setPlayerFlag(p, "-jifeng_pro");
                }
            }
        }
        else if (event == HpChanged && data.toInt() != 0){
            room->setPlayerFlag(player, "jifeng_pro");
        }

   }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (triggerEvent == EventPhaseEnd && player->getPhase()==Player::Finish){
            if (player == NULL) return skill_list;
            QList<ServerPlayer *> shimakazes= room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *shimakaze, shimakazes) {
                if (shimakaze != player && !shimakaze->hasFlag("jifeng_pro") && !shimakaze->isRemoved())
                    skill_list.insert(shimakaze, QStringList(objectName()));
            }
        }
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *shimakaze = ask_who;
        if (shimakaze && shimakaze->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), shimakaze);
            room->doLightbox("se_jifeng$", 400);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *shimakaze = ask_who;
        ServerPlayer *last;
        foreach (ServerPlayer *p, room->getPlayers()){
            if (p->objectName()==shimakaze->getLast()->objectName()){
                last = p;
            }
        }
        /*while (last && last->isDead()){
            room->swapSeat(shimakaze, last);
            foreach (ServerPlayer *p, room->getPlayers()){
                if (p->objectName()==shimakaze->getLast()->objectName()){
                    last = p;
                }
            }
        }*/
        if (last){
          room->swapSeat(shimakaze, last);
        }
        return false;
    }
};

YuleiCard::YuleiCard()
{
    target_fixed = true;
}


void YuleiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    int n = this->getSubcards().length();
    QList<ServerPlayer *> list;
    room->doLightbox("se_jifeng$", 800);
    for (int i=1; i<=n ; i++){
        ServerPlayer *next;
        Player *p = source->getNext();
        foreach (ServerPlayer *q, room->getPlayers()){
            if (q->objectName()==p->objectName()){
                next = q;
            }
        }
        room->swapSeat(source, next);
        if (next->isAlive() && !list.contains(next)){
            list << next;
        }
    }
    foreach(ServerPlayer *target, list){
        Card *card = Sanguosha->cloneCard("thunder_slash");
        room->useCard(CardUseStruct(card, source, target), false);
    }
}

class Yulei : public ViewAsSkill
{
public:
    Yulei() :ViewAsSkill("yulei")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("YuleiCard")&&player->hasSkill(objectName());
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return to_select->isKindOf("BasicCard");
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;
        YuleiCard *vs = new YuleiCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        vs->addSubcards(cards);
        return vs;
    }
};

class Huibi : public TriggerSkill
{
public:
    Huibi() : TriggerSkill("huibi")
    {
        frequency = NotFrequent;
        events << EventPhaseEnd << TargetConfirming;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (event==TargetConfirming && TriggerSkill::triggerable(player) && (use.card->isKindOf("Slash")||use.card->isNDTrick()) && use.from!=NULL && !player->hasFlag("huibi_used") && !player->isKongcheng()){
            return QStringList(objectName());
        }
        if (event==EventPhaseEnd && player->getPhase()==Player::Finish){
            foreach(auto p, room->getAlivePlayers()){
                room->setPlayerFlag(p,"-huibi_used");
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)&&room->askForCard(player, "BasicCard|.|.|hand", "@huibi", data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
       CardUseStruct use = data.value<CardUseStruct>();
       room->doLightbox("se_jifeng$", 800);
       room->setPlayerFlag(player,"huibi_used");
       ServerPlayer *next;
       Player *p = player->getNext();
       foreach (ServerPlayer *q, room->getPlayers()){
           if (q->objectName()==p->objectName()){
               next = q;
           }
       }
       room->swapSeat(player, next);
       room->cancelTarget(use, player);
       data = QVariant::fromValue(use);
       return false;
    }
};

GongfangCard::GongfangCard()
{
    target_fixed = true;
}

void GongfangCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    if (player->usedTimes("GongfangCard")==1){
       player->drawCards(1);
       Card *card = Sanguosha->getCard(this->getSubcards().at(0));
       if (card->isKindOf("BasicCard")){
           room->setPlayerFlag(player, "gongfang_basic");
       }
       else if(card->isKindOf("TrickCard")){
           room->setPlayerFlag(player, "gongfang_trick");
       }
       else{
           room->setPlayerFlag(player, "gongfang_equip");
       }
    }
    if (player->usedTimes("GongfangCard")==2){
        Card *card = Sanguosha->getCard(this->getSubcards().at(0));
        if (card->isKindOf("BasicCard")&&player->hasFlag("gongfang_basic")){
            player->drawCards(1);
        }
        else if(card->isKindOf("TrickCard")&&player->hasFlag("gongfang_trick")){
            player->drawCards(1);
        }
        else if(card->isKindOf("EquipCard")&&player->hasFlag("gongfang_equip")){
            player->drawCards(1);
        }
        else{
            if (card->isKindOf("BasicCard")){
                room->setPlayerFlag(player, "gongfang_basic");
            }
            else if(card->isKindOf("TrickCard")){
                room->setPlayerFlag(player, "gongfang_trick");
            }
            else{
                room->setPlayerFlag(player, "gongfang_equip");
            }
            QStringList list;
            QList<int> cardlist = room->getDrawPile();
            while(!cardlist.isEmpty()){
                int id = cardlist.at(rand()%cardlist.length());
                Card *c = Sanguosha->getCard(id);
                if (!list.contains("BasicCard")&&c->isKindOf("BasicCard")){
                    list << "BasicCard";
                }
                if (!list.contains("TrickCard")&&c->isKindOf("TrickCard")){
                    list << "TrickCard";
                }
                if (!list.contains("EquipCard")&&c->isKindOf("EquipCard")){
                    list << "EquipCard";
                }
                cardlist.removeOne(id);
            }
            QString choice = room->askForChoice(player,"gongfang", list.join("+"));
            foreach(auto id, room->getDrawPile()){
                Card *c = Sanguosha->getCard(id);
                if (choice=="BasicCard"&&c->isKindOf("BasicCard")){
                    room->obtainCard(player, c);
                    break;
                }
                if (choice=="TrickCard"&&c->isKindOf("TrickCard")){
                    room->obtainCard(player, c);
                    break;
                }
                if (choice=="EquipCard"&&c->isKindOf("EquipCard")){
                    room->obtainCard(player, c);
                    break;
                }
            }
        }
    }
    if (player->usedTimes("GongfangCard")==3){
        Card *card = Sanguosha->getCard(this->getSubcards().at(0));
        if (card->isKindOf("BasicCard")&&player->hasFlag("gongfang_basic")){
            player->drawCards(1);
        }
        else if(card->isKindOf("TrickCard")&&player->hasFlag("gongfang_trick")){
            player->drawCards(1);
        }
        else if(card->isKindOf("EquipCard")&&player->hasFlag("gongfang_equip")){
            player->drawCards(1);
        }
        else{

            QStringList list;
            QList<int> cardlist = room->getDrawPile();
            while(!cardlist.isEmpty()){
                int id = cardlist.at(rand()%cardlist.length());
                Card *c = Sanguosha->getCard(id);
                if (!list.contains(c->objectName())){
                    list << c->objectName();
                }
                cardlist.removeOne(id);
            }

            QStringList type_list;

            for(int id=0; id<999; id++){
                Card *c = Sanguosha->getCard(id);
                if (!type_list.contains("BasicCard")&&c->isKindOf("BasicCard")&& room->getDrawPile().contains(id)){
                    type_list << "BasicCard";
                }
                if (!type_list.contains("TrickCard")&&c->isKindOf("TrickCard")&& room->getDrawPile().contains(id)){
                    type_list << "TrickCard";
                }
                if (!type_list.contains("EquipCard")&&c->isKindOf("EquipCard")&& room->getDrawPile().contains(id)){
                    type_list << "EquipCard";
                }
            }

            QString type = room->askForChoice(player,"gongfang_type", type_list.join("+"));

            QStringList name_list;
            QList<int> nlist;

            for(int id=0; id<999; id++){
                Card *c = Sanguosha->getCard(id);
                if (!c) continue;
                if (type == "BasicCard" && !name_list.contains(c->objectName())&& c->isKindOf("BasicCard")&& room->getDrawPile().contains(id)){
                    name_list << c->objectName();
                    nlist << id;
                }
                if (type == "TrickCard" && !name_list.contains(c->objectName())&& c->isKindOf("TrickCard")&& room->getDrawPile().contains(id)){
                    name_list << c->objectName();
                    nlist << id;
                }
                if (type == "EquipCard" && !name_list.contains(c->objectName())&& c->isKindOf("EquipCard")&& room->getDrawPile().contains(id)){
                    name_list << c->objectName();
                    nlist << id;
                }
            }

            //QString choice = room->askForChoice(player,"gongfang_name", name_list.join("+"));
            room->fillAG(nlist, player);
            int chooseid = room->askForAG(player, nlist, false, "gongfang");
            room->clearAG(player);
            foreach(auto id, room->getDrawPile()){
                Card *c = Sanguosha->getCard(id);
                if (c->objectName()==Sanguosha->getCard(chooseid)->objectName()){
                    room->obtainCard(player, c);
                    break;
                }
            }
        }
    }
}


class Gongfang : public OneCardViewAsSkill
{
public:
    Gongfang() : OneCardViewAsSkill("gongfang"){

    }

    bool viewFilter(const Card *card) const
    {
        return !card->isEquipped();
    }

    const Card *viewAs(const Card *originalCard) const
    {
        GongfangCard *card = new GongfangCard();
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return player->usedTimes("GongfangCard")<3;
    }
};

class Fuxing : public TriggerSkill
{
public:
    Fuxing() : TriggerSkill("fuxing")
    {
        frequency = NotFrequent;
        events << CardsMoveOneTime;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        if (!move.to || player != move.to || move.to_place != Player::PlaceHand ||player->getPhase()==Player::Draw ||(move.from && move.from == player)||player->hasFlag("fuxing_current")||(room->getCurrent()&&room->getCurrent()->hasFlag(player->objectName()+"fuxing")))
            return QStringList();
        bool can = false;
        foreach (auto p, room->getAlivePlayers()){
            if (p->isWounded() && player->getMark("fuxing_pro"+p->objectName()) == 0){
                can = true;
            }
        }
        if (!can)
            return QStringList();
        if (TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer*> list;
            foreach(auto p, room->getAlivePlayers()){
                if (p->isWounded() && p!= player && player->getMark("fuxing_pro"+p->objectName()) == 0){
                    list <<p;
                }
            }

            ServerPlayer *dest=room->askForPlayerChosen(player,list,objectName(),QString(),true,true);
            if (dest){
                room->broadcastSkillInvoke(objectName(), player);
                player->tag["fuxing_invoke"] = QVariant::fromValue(dest);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->getPhase()!=Player::NotActive){
            room->setPlayerFlag(player, "fuxing_current");
        }
        else if (room->getCurrent()){
            room->setPlayerFlag(room->getCurrent(), player->objectName()+"fuxing");
        }
        CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
        ServerPlayer *dest = player->tag["fuxing_invoke"].value<ServerPlayer *>();
        DummyCard dummy(move.card_ids);
        dest->obtainCard(&dummy, false);
        RecoverStruct recover;
        recover.recover = 1;
        recover.who = player;
        room->recover(dest, recover, true);
        if (dest->getHp()>=dest->getMaxHp()){
            room->setPlayerMark(player, "fuxing_pro"+dest->objectName(),1);
        }
        return false;
    }
};

class Zhishu : public TriggerSkill
{
public:
    Zhishu() : TriggerSkill("zhishu")
    {
        frequency = Limited;
        events << EventPhaseStart <<  EventPhaseEnd;
        relate_to_place = "head";
        limit_mark = "@zhishu";
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event==EventPhaseStart){
            if (TriggerSkill::triggerable(player) && player->getPhase()==Player::Finish && player->getMark("@zhishu")>0){
                return QStringList(objectName());
            }
        }
        else if(player->getPhase()==Player::Finish){
            foreach(auto p, room->getAlivePlayers()){
                if (p->getMark("zhishu_effect")>0){
                   room->setPlayerMark(p,"zhishu_effect",0);
                   p->gainAnExtraTurn();
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
   {
        if (event==EventPhaseStart && player->askForSkillInvoke(this, data)) {
            QList<ServerPlayer *> to_choose;
            foreach(ServerPlayer *p, room->getAlivePlayers()) {
                if (player->isFriendWith(p))
                    to_choose << p;
            }

            QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, to_choose, objectName(), 0, 998, "@zhishu-card", true);
            if (choosees.length()>0 ){
                player->tag["zhishu_invoke"] = QVariant::fromValue(choosees);
                return true;
            }
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==EventPhaseStart){
            player->loseMark("@zhishu");
            room->broadcastSkillInvoke(objectName(),player);
            room->doSuperLightbox("Kurt", objectName());
            QList<ServerPlayer *> targets = player->tag["zhishu_invoke"].value<QList<ServerPlayer *> >();
            foreach(auto p, targets){
                room->setPlayerMark(p,"zhishu_effect",1);
            }
        }
        return false;
    }
};

class Zhanshu : public OneCardViewAsSkill
{
public:
    Zhanshu() : OneCardViewAsSkill("zhanshu"){
        guhuo_type="k";
        relate_to_place = "deputy";
    }

    bool viewFilter(const Card *card) const
    {
        return Self->getHandcards().contains(card);
    }

    const Card *viewAs(const Card *originalCard) const
    {
        QString pattern=Self->tag[objectName()].toString();
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
        return !player->hasFlag("zhanshu_used");
    }

};

class Wuming : public PhaseChangeSkill
{
public:
    Wuming() : PhaseChangeSkill("wuming")
    {
        frequency = Compulsory;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (!PhaseChangeSkill::triggerable(player))
             return QStringList();

        if (player->getPhase() == Player::Draw) {
            bool can_invoke = false;
            QList<ServerPlayer *> other_players = room->getOtherPlayers(player);
            foreach (ServerPlayer *player, other_players) {
                if (!player->isKongcheng()) {
                    can_invoke = true;
                    break;
                }
            }

            return can_invoke ? QStringList(objectName()) : QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (!player->hasShownSkill(objectName()) && !player->askForSkillInvoke(this, data)){
            return false;
        }
        QList<ServerPlayer *> to_choose;
        foreach(ServerPlayer *p, room->getOtherPlayers(player)) {
            if (player->canGetCard(p, "h"))
                to_choose << p;
        }

        QStringList kingdoms;
        int n = 0;
        foreach(ServerPlayer *p, room->getAlivePlayers()){
            if ((p->hasShownGeneral1()||p->hasShownGeneral2())&&p->getRole()!="careerist"&&!kingdoms.contains(p->getKingdom())){
                kingdoms.append(p->getKingdom());
            }
            else if(p->getRole()=="careerist"){
                n = n+1;
            }
        }
        int x= kingdoms.length()+n;
        QList<ServerPlayer *> choosees = room->askForPlayersChosen(player, to_choose, objectName(), 0, x, "@wuming-card", true);
        if (choosees.length() > 0 || player->hasShownSkill(objectName())) {
            room->sortByActionOrder(choosees);
            player->tag["wuming_invoke"] = QVariant::fromValue(choosees);
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }

        return false;
    }

    virtual bool onPhaseChange(ServerPlayer *source) const
    {
        QList<ServerPlayer *> targets = source->tag["wuming_invoke"].value<QList<ServerPlayer *> >();
        source->tag.remove("wuming_invoke");

        Room *room = source->getRoom();

        QList<CardsMoveStruct> moves;

        foreach(auto p, targets){
            CardsMoveStruct move;
                move.card_ids << room->askForCardChosen(source, p, "h", "wuming", false, Card::MethodGet);
                move.to = source;
                move.to_place = Player::PlaceHand;
                moves.push_back(move);
        }

        room->moveCardsAtomic(moves, false);

        return true;
    }
};

AzuyizhiCard::AzuyizhiCard()
{
}


bool AzuyizhiCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *) const
{
    return targets.isEmpty();
}

void AzuyizhiCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
   room->loseHp(source);
   if(source->isAlive() && !room->askForUseCard(targets.at(0), "@@yizhiresponse", "@yizhiresponse")){
       targets.at(0)->turnOver();
   }

}

/*class Azuyizhi : public ZeroCardViewAsSkill
{
public:
    Azuyizhi() : ZeroCardViewAsSkill("azuyizhi"){

    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("AzuyizhiCard");
    }

    const Card *viewAs() const
    {
        AzuyizhiCard *vs = new AzuyizhiCard();
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }
};*/

class Azuyizhi : public TriggerSkill
{
public:
    Azuyizhi() : TriggerSkill("azuyizhi")
    {
        events << Damage << EventPhaseStart << DamageCaused;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==EventPhaseStart && player->getPhase()==Player::RoundStart && player->getMark("##azuyizhi")>0){
            room->setPlayerMark(player, "##azuyizhi", 0);
        }
    }


    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        if (triggerEvent == Damage) {
            DamageStruct damage = data.value<DamageStruct>();
            if (!damage.from)
                return skill_list;
            QList<ServerPlayer *> azus = room->findPlayersBySkillName(objectName());
            foreach(ServerPlayer *azu, azus)
                skill_list.insert(azu, QStringList(objectName()));
            return skill_list;
        }
        if (triggerEvent == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.from->getMark("##azuyizhi")>0){
                skill_list.insert(damage.from, QStringList(objectName()));
                return skill_list;
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *azu = ask_who;
        DamageStruct damage = data.value<DamageStruct>();
        if (event == Damage && azu->askForSkillInvoke(this, QVariant::fromValue(damage.from))) {
            room->broadcastSkillInvoke(objectName(), azu);
            return true;
        }
        if (event == DamageCaused)
            return true;
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (event == DamageCaused){
            return true;
        }
        else if (event == Damage){
            ServerPlayer *azu = ask_who;
            room->loseHp(azu);
            if(azu->isAlive() && damage.from->isAlive()/*!room->askForUseCard(damage.from, "@@yizhiresponse", "@yizhiresponse")*/){
                QString choice = room->askForChoice(azu, objectName(), "yizhi_turnover+yizhi_discard+yizhi_pro", data);
                if (choice == "yizhi_turnover"){
                    damage.from->drawCards(1);
                    damage.from->turnOver();
                }
                else if(choice == "yizhi_discard"){
                    DummyCard *dummy = new DummyCard;
                    dummy->deleteLater();
                    foreach(auto c, damage.from->getHandcards()){
                        if (c->isKindOf("Weapon") || c->isKindOf("Slash")){
                            dummy->addSubcard(c);
                        }
                    }
                    foreach(auto c, damage.from->getEquips()){
                        if (c->isKindOf("Weapon") || c->isKindOf("Slash")){
                            dummy->addSubcard(c);
                        }
                    }
                    room->throwCard(dummy, damage.from, damage.from);
                }
                else{
                    room->setPlayerMark(damage.from, "##azuyizhi", 1);
                }
            }
        }
        return false;
    }
};

YizhiresponseCard::YizhiresponseCard()
{
    target_fixed = true;
}

void YizhiresponseCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{

}

class Yizhiresponse : public ViewAsSkill
{
public:
    Yizhiresponse() : ViewAsSkill("yizhiresponse")
    {
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return false;
    }

    bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "@@yizhiresponse";
    }

    bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        if (selected.length()==0){
            return to_select->isKindOf("Weapon")||to_select->isKindOf("Slash");
        }
        else if(selected.length()==1 && selected.at(0)->isKindOf("Weapon")){
            return to_select->isKindOf("Slash");
        }
        else if(selected.length()==1 && selected.at(0)->isKindOf("Slash")){
            return to_select->isKindOf("Weapon");
        }
        return false;
    }

    const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length()!=2)
            return NULL;
        YizhiresponseCard *zrc = new YizhiresponseCard();
        zrc->addSubcards(cards);
        zrc->setSkillName(objectName());
        zrc->setShowSkill(objectName());
        return zrc;
    }
};

class Gewu : public TriggerSkill
{
public:
    Gewu() : TriggerSkill("gewu")
    {
        frequency = NotFrequent;
        events << EventPhaseChanging;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        PhaseChangeStruct change = data.value<PhaseChangeStruct>();
        if (TriggerSkill::triggerable(player) &&!player->isSkipped(Player::Play)&& change.to==Player::Play && !player->isKongcheng()) {
             return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }


    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        foreach(ServerPlayer *p, room->getOtherPlayers(player)){
            if (p->isFriendWith(player)){
                if (player->distanceTo(p)<=1 && player->distanceTo(p)>-1){
                    RecoverStruct recover;
                    recover.recover = 1;
                    recover.who = player;
                    room->recover(p, recover, true);
                }
            }
        }

        if (!player->isKongcheng()){
            bool discard = room->askForDiscard(player, objectName(), 1, 1, true);
            if (!discard) return false;
            QList<ServerPlayer*> list;
            foreach(auto p, room->getOtherPlayers(player)){
                if (p->isFriendWith(player)){
                    list<<p;
                }
            }
            ServerPlayer *dest=room->askForPlayerChosen(player,list,objectName(),QString(),true,true);
            if (dest){
                dest->gainAnExtraTurn();
            }
            return true;
        }
        return false;
    }
};

class Kuangquan : public TriggerSkill
{
public:
    Kuangquan() : TriggerSkill("kuangquan")
    {
        events << DamageCaused;
        frequency = NotFrequent;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (TriggerSkill::triggerable(player) && !player->isNude() && !damage.chain){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        if (player->askForSkillInvoke(this, QVariant::fromValue(damage.to)) && room->askForCard(player, "..", "@emeng", data, objectName())) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *yuudachi, QVariant &data, ServerPlayer *) const
    {
        room->broadcastSkillInvoke(objectName());
        DamageStruct damage = data.value<DamageStruct>();
        damage.damage =  damage.damage+1;
        data.setValue(damage);
        return false;
    }
};

class Emeng : public TriggerSkill
{
public:
    Emeng() : TriggerSkill("emeng")
    {
        events << Dying << DrawNCards << EventPhaseStart;
        frequency = Frequent;
        relate_to_place = "head";
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event== EventPhaseStart && TriggerSkill::triggerable(player) && player->getPhase()==Player::Start && player->getHp()<=1){
            return QStringList(objectName());
        }
        if (event== EventPhaseStart && player->getPhase()==Player::Start && player->getMark("emeng_trigger")>0){
            room->setPlayerMark(player, "emeng_trigger", 0);
            foreach(auto p, room->getOtherPlayers(player)){
                room->setFixedDistance(player, p, -1);
                room->setFixedDistance(p, player, -1);
            }
        }
        if (event == DrawNCards && player->getMark("emeng_trigger")>0){
            room->broadcastSkillInvoke(objectName(),rand()%3 +1, player);
            data.setValue(data.toInt()+1);
        }
        if (event == Dying && TriggerSkill::triggerable(player) && !player->isRemoved() && data.value<DyingStruct>().who == player){
            return QStringList(objectName());
        }
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
        if (event== EventPhaseStart){
            room->broadcastSkillInvoke(objectName(),rand()%3 +1, player);
            room->doLightbox("se_suo$", 500);
            room->doLightbox("se_luo$", 500);
            room->doLightbox("se_men$", 1000);
            room->doLightbox("se_wo$", 300);
            room->doLightbox("se_you$", 300);
            room->doLightbox("se_hui$", 300);
           room->doLightbox("se_lai$", 300);
           room->doLightbox("se_le$", 300);
           room->doLightbox("se_a$", 1000);
            room->doLightbox("se_emeng$", 2000);
            room->setPlayerMark(player, "emeng_trigger", 1);
            foreach(auto p, room->getOtherPlayers(player)){
                room->setFixedDistance(player, p, 1);
                room->setFixedDistance(p, player, 1);
            }
        }
        if (event == Dying){
            QList<ServerPlayer *> list;
            foreach(auto p, room->getOtherPlayers(player)){
                if (!p->isRemoved()){
                    list <<p;
                }
            }

            ServerPlayer *target = room->askForPlayerChosen(player, list, "emeng");
            if (!target){
                return false;
             }
            while( target->objectName() != player->getNextAlive()->objectName()){
                room->getThread()->delay(100);
                ServerPlayer *next;
                Player *p = player->getNext();
                foreach (ServerPlayer *q, room->getPlayers()){
                    if (q->objectName()==p->objectName()){
                        next = q;
                    }
                }
                room->swapSeat(player, next);
            }
            room->doLightbox("se_chongzhuang$", 1500);
            Card *card = Sanguosha->cloneCard("slash");
            card->setSkillName("chongzhuang");
            room->broadcastSkillInvoke(objectName(),4, player);
            room->useCard(CardUseStruct(card, player, target), false);
        }
        return false;
    }
};

class EmengTargetMod : public TargetModSkill
{
public:
    EmengTargetMod () : TargetModSkill("#emengtargetmod")
    {
    }

    virtual int getResidueNum(const Player *from, const Card *card) const
    {
        if (!Sanguosha->matchExpPattern(pattern, from, card))
            return 0;

        if (from->getMark("emeng_trigger")>0)
            return 1000;
        else
            return 0;
    }
};

class Leimu : public TriggerSkill
{
public:
    Leimu() : TriggerSkill("leimu")
    {
        events << GeneralShown << CardsMoveOneTime;
        frequency = Frequent;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == GeneralShown) {
            if (TriggerSkill::triggerable(player))
                return (data.toBool() == player->inHeadSkills(objectName())) ? QStringList(objectName()) : QStringList();
        }
        else{
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.from_places.contains(Player::DrawPile) && room->getDrawPile().length()-move.card_ids.length()<1 && TriggerSkill::triggerable(player) && player->hasShownAllGenerals()){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == GeneralShown && player->askForSkillInvoke(this, data)) {
            return true;
        }
        else if ( player->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if (triggerEvent == GeneralShown){
           QList<ServerPlayer *> targets = room->askForPlayersChosen(player, room->getOtherPlayers(player), objectName(), 0, 3, QString(), true);
           room->broadcastSkillInvoke(objectName(), player);
           room->doLightbox("se_leimu$", 1200);
           room->sortByActionOrder(targets);
           foreach(auto p, targets){
               DamageStruct da;
               da.from=player;
               da.to=p;
               da.damage=1;
               da.nature= DamageStruct::Thunder;
               room->damage(da);
           }
        }
        else{
            player->hideGeneral(player->inHeadSkills(this));
        }
        return false;
    }
};

class Yezhan : public TriggerSkill
{
public:
    Yezhan() : TriggerSkill("yezhan")
    {
        events << DamageCaused;
        frequency = NotFrequent;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == DamageCaused) {
            DamageStruct damage = data.value<DamageStruct>();
            if (TriggerSkill::triggerable(player) && (damage.nature!=DamageStruct::Normal || damage.to->getHp()<=damage.damage)){
                if (room->getCurrent() && room->getCurrent()->hasFlag( player->objectName()+"yezhan_used"))
                    return QStringList();
                return QStringList(objectName());
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == DamageCaused && player->askForSkillInvoke(this, data)) {
            if (!player->hasShownSkill(objectName())){
                room->setPlayerFlag(player, "yezhan_first");
            }
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (triggerEvent == DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            if (player->hasFlag("yezhan_first")){
                room->broadcastSkillInvoke(objectName(), player);
                room->doLightbox("se_yezhan$", 1200);
                damage.damage=damage.damage+1;
                data.setValue(damage);
                room->setPlayerFlag(player, "-yezhan_first");
            }
            else{
                bool tri = false;
                auto players = room->getAlivePlayers();
                room->sortByActionOrder(players);
                foreach(auto p, players){
                    if (p->willBeFriendWith(player)&&!p->hasShownAllGenerals()){
                        bool show=p->askForGeneralShow(true, true);
                        if (show){
                            room->broadcastSkillInvoke(objectName(), player);
                            room->doLightbox("se_yezhan$", 1200);
                            damage.damage=damage.damage+1;
                            data.setValue(damage);
                            tri = true;
                            break;
                        }
                    }
                    else if(!p->hasShownOneGeneral()){
                        room->askForChoice(p,objectName(),"cannot_showgeneral+cancel",data);
                    }
                }
                if (!tri){
                    QList<ServerPlayer *> list;
                    foreach(auto p, room->getAlivePlayers()){
                        if (p->isFriendWith(player) && p->hasShownAllGenerals()){
                            list << p;
                        }
                    }
                    ServerPlayer *dest = room->askForPlayerChosen(player, list, objectName(), QString(), true);
                    if (dest){
                        if (room->getCurrent())
                            room->setPlayerFlag(room->getCurrent(), player->objectName()+"yezhan_used");
                        if (dest == player){
                            player->hideGeneral(!player->inHeadSkills(this));
                        }
                        else{
                          QString choice = room->askForChoice(player,objectName(),"yezhan_head+yezhan_deputy",data);
                         if (choice == "yezhan_head"){
                             dest->hideGeneral(true);
                         }
                          else{
                             dest->hideGeneral(false);
                         }

                        }
                    }
                }
            }
        }
        return false;
    }
};

class Jiyi : public TriggerSkill
{
public:
    Jiyi()
        : TriggerSkill("jiyi")
    {
        events << EventPhaseStart << EventPhaseChanging;
    }

    virtual QStringList triggerable(TriggerEvent e, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (e == EventPhaseStart) {
            if (player->getPhase() == Player::Draw && player->hasSkill(this))
                return QStringList(objectName());
        } else if (e == EventPhaseChanging) {
            PhaseChangeStruct change = data.value<PhaseChangeStruct>();
            if (change.to == Player::NotActive && player->hasFlag(objectName())) {
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent e, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (e == EventPhaseStart) {
            player->setFlags(objectName());
            return true;
        } else if (e == EventPhaseChanging) {
            //invoke->invoker->setFlags("-zhunbei");
            LogMessage msg;
            msg.type = "#TouhouBuff";
            msg.from = player;
            room->sendLog(msg);
            room->notifySkillInvoked(player, objectName());
            player->drawCards(3);
        }
        return false;
    }
};

class Zmqiji : public OneCardViewAsSkill
{
public:
    Zmqiji() : OneCardViewAsSkill("zmqiji"){
        guhuo_type="bt";
    }

    bool viewFilter(const Card *card) const
    {
        return Self->getHandcards().contains(card) && Self->getHandcardNum()==1;
    }

    const Card *viewAs(const Card *originalCard) const
    {
        QString pattern=Self->tag[objectName()].toString();
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
        return !player->hasUsed("ViewAsSkill_zmqijiCard");
    }

};

class Qijieffect : public TriggerSkill
{
public:
    Qijieffect() : TriggerSkill("qijieffect")
    {
        events <<CardUsed<<EventPhaseEnd;
        global=true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (event == CardUsed){
            CardUseStruct use=data.value<CardUseStruct>();
            if (use.card->getSkillName()=="zmqiji" && use.from->getPhase()!=Player::NotActive){
                room->setPlayerFlag(use.from,"qiji_used");
            }

            //for all such effect
            if (use.card->getSkillName()=="zhanshu"){
                room->setPlayerFlag(use.from,"zhanshu_used");
                room->setPlayerMark(player, use.card->objectName()+"zhanshu", 1);
            }
        }
        if (event == EventPhaseEnd){
            if (player->getPhase()==Player::Finish){
                room->setPlayerMark(player,"qiubang_distance",0);
                room->setPlayerMark(player,"qiubang_slash",0);
                room->setPlayerMark(player,"yuehuang",0);
                foreach(auto p, room->getAlivePlayers()){
                  room->setPlayerFlag(p, "-jiaxiangused");
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return false;
    }
};

class Xiangqi : public TriggerSkill
{
public:
    Xiangqi()
        : TriggerSkill("xiangqi")
    {
        events << Damaged;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        TriggerList skill_list;
        if (!damage.by_user)
            return skill_list;
        foreach (ServerPlayer *satori, room->findPlayersBySkillName(objectName())) {
            if (damage.from && damage.from != satori && damage.card && !damage.from->isKongcheng() && damage.to != damage.from && damage.to->isAlive()
                && (satori->inMyAttackRange(damage.to) || damage.to == satori))
                skill_list.insert(satori, QStringList(objectName()));
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        QString prompt = "show:" + damage.from->objectName() + ":" + damage.to->objectName() + ":" + damage.card->objectName();
        ask_who->tag["xiangqi_from"] = QVariant::fromValue(damage.from);
        ask_who->tag["xiangqi_to"] = QVariant::fromValue(damage.to);
        ask_who->tag["xiangqi_card"] = QVariant::fromValue(damage.card);
        if (ask_who->askForSkillInvoke(this, prompt)) {
            room->broadcastSkillInvoke(objectName(), player);
            ask_who->showSkill(objectName());
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), damage.from->objectName());
            int id = room->askForCardChosen(ask_who, damage.from, "hs", objectName());
            room->showCard(damage.from, id);
            ask_who->tag["xiangqi_id"] = QVariant::fromValue(id);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        int id = ask_who->tag["xiangqi_id"].toInt();
        ask_who->tag.remove("xiangqi_id");
        Card *showcard = Sanguosha->getCard(id);
        bool same = false;
        if (showcard->getTypeId() == damage.card->getTypeId())
            same = true;

        if (same && damage.to != ask_who) {
            room->throwCard(id, damage.from, ask_who);
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, ask_who->objectName(), damage.to->objectName());

            room->damage(DamageStruct(objectName(), ask_who, damage.to));
        } else
            room->obtainCard(damage.to, showcard);

        return false;
    }
};

class Duxin : public TriggerSkill
{
public:
    Duxin()
        : TriggerSkill("duxin")
    {
        events << TargetConfirming;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (use.card->isKindOf("SkillCard") || use.from == NULL || use.to.length() != 1 || use.from == use.to.first() || use.from->hasFlag("Global_ProcessBroken"))
            return QStringList();

        ServerPlayer *satori = player;
        if (satori->hasSkill(objectName()) && !use.from->hasShownAllGenerals()) {
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const{
        if (player->hasShownSkill(objectName())||player->askForSkillInvoke(this, data)){
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QStringList list;
        if (!use.from->hasShownGeneral1()){
            list << use.from->getActualGeneral1Name();
        }
        if (!use.from->hasShownGeneral2()){
            list << use.from->getActualGeneral2Name();
        }
        foreach (const QString &name, list) {
            LogMessage log;
            log.type = "$KnownBothViewGeneral";
            log.from = player;
            log.to << use.from;
            log.arg = name;
            log.arg2 = use.from->getRole();
            room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
        }
        JsonArray arg;
        arg << objectName();
        arg << JsonUtils::toJsonArray(list);
        room->doNotify(player, QSanProtocol::S_COMMAND_VIEW_GENERALS, arg);
        return false;
    }
};

//first extension
class Qiubang : public TriggerSkill
{
public:
    Qiubang()
        : TriggerSkill("qiubang")
    {
        events << CardUsed;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (TriggerSkill::triggerable(player)&&player->getPhase()==Player::Play&& use.card->getTypeId() !=  Card::TypeSkill){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const{
        if (player->askForSkillInvoke(this, data)){
            room->broadcastSkillInvoke(objectName());
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        QString choice = room->askForChoice(player, objectName(), "qiubang_distance+qiubang_slash", data);
        /*if (use.card->isRed()){
            room->setPlayerMark(player, "qiubang_distance", player->getMark("qiubang_distance")+1);
        }
        else if(use.card->isBlack()){
            room->setPlayerMark(player, "qiubang_slash", player->getMark("qiubang_slash")+1);
        }*/
        room->setPlayerMark(player, choice, player->getMark(choice)+1);
        LogMessage log;
        log.type = "#Qiubang"+choice;
        log.from = player;
        room->sendLog(log);
        return false;
    }
};

class QiubangDistance : public DistanceSkill
{
  public:
    QiubangDistance(): DistanceSkill("#qiubangdistance")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->getMark("qiubang_distance")>0)
            return -from->getMark("qiubang_distance");
        else
            return 0;
    }
};

class QiubangTargetMod : public TargetModSkill
{
public:
    QiubangTargetMod() : TargetModSkill("#qiubang-target")
    {
        pattern = "Slash";
    }

    virtual int getExtraTargetNum(const Player *from, const Card *card) const
    {
        if (from->getMark("qiubang_slash")>0)
            return from->getMark("qiubang_slash");
        else
            return 0;
    }

};

RandongSummon::RandongSummon()
    : ArraySummonCard("randong")
{
}

class Randong : public BattleArraySkill
{
public:
    Randong() : BattleArraySkill("randong", HegemonyMode::Formation)
    {
        events << TargetConfirming;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card || use.to.length()!=1 || (!use.card->isKindOf("Slash")&&!use.card->isNDTrick())){
            return skill_list;
        }
        if (player->aliveCount() < 4)
            return skill_list;
        QList<ServerPlayer *> k1s = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *k1, k1s) {
            if (k1->inFormationRalation(player)&&k1->getFormation().length()>1 && (use.to.at(0)==k1||(!k1->isKongcheng() &&k1->canDiscard(k1, "h"))))
                skill_list.insert(k1, QStringList(objectName()));
        }
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *k1 = ask_who;
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *dest = use.to.at(0);
        k1->setProperty("randong_from", QVariant::fromValue(use.from));
        if (k1 && k1->askForSkillInvoke(this, QVariant::fromValue(dest))) {
            k1->setProperty("randong_from", QVariant());
            if (k1!=dest && !k1->isKongcheng()){
                int id = room->askForCardChosen(k1,k1,"h",objectName());
                room->throwCard(id, k1, k1);
            }
            else if(k1!=dest && k1->isKongcheng()){
                return false;
            }
            room->broadcastSkillInvoke(objectName(), k1);
            room->doBattleArrayAnimate(k1);
            return true;
        }
        k1->setProperty("randong_from", QVariant());
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        ServerPlayer *k1 = ask_who;
        player->drawCards(1);
        Card *duel = Sanguosha->cloneCard("duel", use.card->getSuit(), use.card->getNumber());
        duel->setSkillName(objectName());
        duel->addSubcard(use.card);
        use.card = duel;
        data.setValue(use);
        return false;
    }
};

class Kongyun : public TriggerSkill
{
public:
    Kongyun() : TriggerSkill("kongyun")
    {
        events << EventPhaseStart;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        QList<ServerPlayer *> koromos = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *koromo, koromos) {
            if (koromo!=player && player->getPhase()==Player::Play && player->getHandcardNum()>koromo->getHandcardNum()+2) {
                skill_list.insert(koromo, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (ask_who->askForSkillInvoke(this, QVariant::fromValue(player))){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *to, QVariant &data, ServerPlayer *koromo) const
    {
        int id = room->askForCardChosen(koromo, to, "h", objectName(), true);
        if (id == -1)
            return false;
        room->showCard(to, id);
        QString choice = room->askForChoice(koromo, objectName(), "kongdi_di+kongdi_discard");
        room->broadcastSkillInvoke(objectName());
        if (choice == "kongdi_di"){
            CardsMoveStruct move;
            move.card_ids.append(id);
            move.to_place = Player::DrawPileBottom;
            move.reason.m_reason = CardMoveReason::S_REASON_PUT;
            room->moveCardsAtomic(move, false);
        }
        else{
            room->throwCard(id, to, koromo);
        }
        return false;
    }
};

// Aocai by QSanguosha V2 , maybe Para. Modified by OmnisReen

#include "json.h"
class LaoyueViewAsSkill : public ZeroCardViewAsSkill
{
public:
    LaoyueViewAsSkill() : ZeroCardViewAsSkill("laoyue")
    {
        response_or_use = true;
    }

    virtual bool isEnabledAtPlay(const Player *) const
    {
        return false;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        if (!player->hasSkill("laoyue")){
            return false;
        }      
        const Card *card = Sanguosha->cloneCard(pattern);
        if (player->getPhase() != Player::NotActive || player->hasFlag("Global_LaoyueFailed") || player->isRemoved()) return false;
        /*if (pattern == "slash")
            return Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE_USE;
        else*/ if (pattern.contains("peach"))
            return player->getMark("Global_PreventPeach") == 0 && !player->hasFlag("Global_PreventPeach");
        else if (pattern.contains("analeptic"))
            return true;
        return card && card->isKindOf("BasicCard");
    }
    virtual const Card *viewAs() const
    {
        LaoyueCard *laoyue_card = new LaoyueCard;
        QString pattern = Sanguosha->currentRoomState()->getCurrentCardUsePattern();
        if (pattern.contains("peach+analeptic") && Self->getMark("Global_PreventPeach") > 0)
            pattern = "analeptic+guangyucard";
        laoyue_card->setUserString(pattern);
        laoyue_card->setSkillName("laoyue");
        laoyue_card->setShowSkill("laoyue");
        return laoyue_card;
    }
};

using namespace QSanProtocol;

class Laoyue : public TriggerSkill
{
public:
    Laoyue() : TriggerSkill("laoyue")
    {
        events << CardAsked << TargetConfirmed << Dying;
        view_as_skill = new LaoyueViewAsSkill;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (player->hasFlag("AI_laoyueused")){
            room->setPlayerFlag(player, "-AI_laoyueused");
        }
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        /*QString pattern = data.toStringList().first();
        Card *card = Sanguosha->cloneCard(pattern);
        if (player->getPhase() == Player::NotActive && (card->isKindOf("BasicCard")))
            return QStringList(objectName());*/
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return room->askForSkillInvoke(player, objectName(), data);
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        QList<int> ids;

        for (int i = 0; i < 2; i++)
        {
            room->getThread()->trigger(FetchDrawPileCard, room, NULL);
            if (room->getDrawPile().isEmpty())
                room->swapPile();
            ids << room->getDrawPile().takeLast();
        }

        QList<int> enabled, disabled;
        foreach (int id, ids)
        {
            if (Sanguosha->getCard(id)->objectName().contains(data.toStringList().first()))
                enabled << id;
            else
                disabled << id;
        }
        int id = Laoyue::view(room, player, ids, enabled, disabled);

        if (id != -1)
        {
            const Card *card = Sanguosha->getCard(id);
            room->provide(card);
            return true;
        }
        return false;
    }

    static int view(Room *room, ServerPlayer *player, QList<int> &ids, QList<int> &enabled, QList<int> &disabled)
    {
        int result = -1, index = -1;
        QList<int> &drawPile = room->getDrawPile();

        // Remove log because of it's hide for others

        room->broadcastSkillInvoke("laoyue");
        room->notifySkillInvoked(player, "laoyue");

        room->fillAG(ids, player);
        room->getThread()->delay(2500);
        room->clearAG(player);

        QString choice = enabled.length()>0 ? (player->getHandcardNum() >= 2 ? room->askForChoice(player, "laoyue", "use+put+replace+cancel") : room->askForChoice(player, "laoyue", "use+replace+cancel")):(player->getHandcardNum() >= 2 ? room->askForChoice(player, "laoyue", "put+replace+cancel") : room->askForChoice(player, "laoyue", "replace+cancel"));
        if (choice == "use")
        {
            if (enabled.isEmpty())
            {
                room->fillAG(ids, player, disabled);
                room->getThread()->delay(2000);
                room->clearAG(player);
            }
            else
            {
                room->fillAG(ids, player, disabled);
                int id = room->askForAG(player, enabled, true, "laoyue");
                if (id != -1)
                {
                    index = ids.indexOf(id);
                    ids.removeOne(id);
                    result = id;
                }
                room->clearAG(player);
            }
            for (int i = ids.length() - 1; i >= 0; i--)
                drawPile.append(ids.at(i));
        }
        else if (choice == "put")
        {
            QList<int> ex = room->askForExchange(player, "laoyue", 2, 2, "@laoyue-put", "", ".|.|.|hand");
            if (ex.length() == 2)
            {
                CardsMoveStruct move1(QList<int>(), player, NULL, Player::PlaceHand, Player::DrawPileBottom,
                    CardMoveReason(CardMoveReason::S_REASON_OVERRIDE, player->objectName(), "laoyue", QString()));
                CardsMoveStruct move2(QList<int>(), NULL, player, Player::DrawPileBottom, Player::PlaceHand,
                    CardMoveReason(CardMoveReason::S_REASON_OVERRIDE, player->objectName(), "laoyue", QString()));
                move2.card_ids.append(ids);
                move1.card_ids.append(ex);
                QList<CardsMoveStruct> moves;
                moves.append(move2);
                moves.append(move1);
                room->moveCardsAtomic(moves, false);
            }
        }
        else if (choice == "replace")
        {
            auto topCards = room->getNCards(2, true);
            CardsMoveStruct move1(QList<int>(), NULL, NULL, Player::DrawPile, Player::DrawPileBottom,
                CardMoveReason(CardMoveReason::S_REASON_OVERRIDE, player->objectName(), "laoyue", QString()));
            CardsMoveStruct move2(QList<int>(), NULL, NULL, Player::DrawPileBottom, Player::DrawPile,
                CardMoveReason(CardMoveReason::S_REASON_OVERRIDE, player->objectName(), "laoyue", QString()));
            move2.card_ids.append(ids);
            move1.card_ids.append(topCards);
            QList<CardsMoveStruct> moves;
            moves.append(move2);
            moves.append(move1);
            room->moveCardsAtomic(moves, false);
            for (int i = ids.length() - 1; i >= 0; i--)
                drawPile.prepend(ids.at(i));
        }
        else if (choice == "cancel")
        {
            for (int i = ids.length() - 1; i >= 0; i--)
                drawPile.append(ids.at(i));
            room->setPlayerFlag(player, "Global_LaoyueFailed");
            return -1;
        }

        room->doBroadcastNotify(QSanProtocol::S_COMMAND_UPDATE_PILE, drawPile.length());

        if (result == -1)
            room->setPlayerFlag(player, "Global_LaoyueFailed");
        else if (choice == "use")
        {
            LogMessage log;
            log.type = "#LaoyueUse";
            log.from = player;
            log.arg = "laoyue";
            log.arg2 = QString("CAPITAL(%1)").arg(index + 1);
            room->sendLog(log);
        }

        if (choice == "put")
        {
            LogMessage log;
            log.type = "#LaoyuePut";
            log.from = player;
            log.arg = "laoyue";
            room->sendLog(log);
        }
        else if (choice == "replace")
        {
            LogMessage log;
            log.type = "#LaoyueReplace";
            log.from = player;
            log.arg = "laoyue";
            room->sendLog(log);
        }

        return result;
    }
};

LaoyueCard::LaoyueCard()
{
}

bool LaoyueCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetFilter(targets, to_select, Self) && !Self->isProhibited(to_select, card, targets);
}

bool LaoyueCard::targetFixed() const
{
    if (Sanguosha->currentRoomState()->getCurrentCardUseReason() == CardUseStruct::CARD_USE_REASON_RESPONSE)
        return true;
    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetFixed();
}

bool LaoyueCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    const Card *card = NULL;
    if (!user_string.isEmpty())
        card = Sanguosha->cloneCard(user_string.split("+").first());
    return card && card->targetsFeasible(targets, Self);
}

const Card *LaoyueCard::validateInResponse(ServerPlayer *user) const
{
    user->showSkill("laoyue");
    Room *room = user->getRoom();
    QList<int> ids;
    for (int i = 0; i < 2; i++)
    {
        room->getThread()->trigger(FetchDrawPileCard, room, NULL);
        if (room->getDrawPile().isEmpty())
            room->swapPile();
        ids << room->getDrawPile().takeLast();
    }
    QStringList names = toString().split(":").last().split("+");
    if (names.contains("slash")) names << "fire_slash" << "thunder_slash" << "ice_slash" << "clowcard";
    if (names.contains("jink")) names << "clowcard";
    QList<int> enabled, disabled;
    foreach (int id, ids)
    {
        if (names.contains(Sanguosha->getCard(id)->objectName()))
            enabled << id;
        else
            disabled << id;
    }
    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = user;
    log.arg = "laoyue";
    room->sendLog(log);
    int id = Laoyue::view(room, user, ids, enabled, disabled);
    return Sanguosha->getCard(id);
}

const Card *LaoyueCard::validate(CardUseStruct &cardUse) const
{
    cardUse.m_isOwnerUse = false;
    ServerPlayer *user = cardUse.from;
    user->showSkill("laoyue");
    Room *room = user->getRoom();
    QList<int> ids;
    for (int i = 0; i < 2; i++)
    {
        room->getThread()->trigger(FetchDrawPileCard, room, NULL);
        if (room->getDrawPile().isEmpty())
            room->swapPile();
        ids << room->getDrawPile().takeLast();
    }
    QStringList names = toString().split(":").last().split("+");
    if (names.contains("slash")) names << "fire_slash" << "thunder_slash";
    QList<int> enabled, disabled;
    foreach (int id, ids)
    {
        if (names.contains(Sanguosha->getCard(id)->objectName()))
            enabled << id;
        else
            disabled << id;
    }
    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = user;
    log.arg = "laoyue";
    room->sendLog(log);
    int id = Laoyue::view(room, user, ids, enabled, disabled);
    return Sanguosha->getCard(id);
}

class Zhengchang : public TriggerSkill
{
public:
    Zhengchang()
        : TriggerSkill("zhengchang")
    {
        events << TargetConfirming;
        frequency = Compulsory;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        CardUseStruct use = data.value<CardUseStruct>();
        if (!use.card || use.card->getTypeId() != Card::TypeTrick || (!use.card->isBlack()&&use.card->isNDTrick())) return QStringList();
        if (!use.to.contains(player)) return QStringList();
        if (!use.from || player->willBeFriendWith(use.from)) return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const{
        if (player->hasShownSkill(objectName())||player->askForSkillInvoke(this, data)){
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        room->sendCompulsoryTriggerLog(player, objectName());
        CardUseStruct use = data.value<CardUseStruct>();

        room->cancelTarget(use, player); // Room::cancelTarget(use, player);

        data = QVariant::fromValue(use);
        return false;
    }
};

class Tucao : public TriggerSkill
{
public:
    Tucao()
        : TriggerSkill("tucao")
    {
        events << CardUsed;
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == CardUsed){
            if (player == NULL) return skill_list;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card || !use.from || use.card->getTypeId() == Card::TypeSkill || (!use.card->isKindOf("Slash")&&!use.card->isKindOf("TrickCard"))){
                return skill_list;
            }
            QList<ServerPlayer *> kagamis = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *kagami, kagamis) {
                if (!kagami->isKongcheng() && kagami !=use.from)
                    skill_list.insert(kagami, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *kagami = ask_who;
        CardUseStruct use = data.value<CardUseStruct>();
        kagami->setProperty("tucao_card", QVariant::fromValue(use.card));
        if (kagami && kagami->askForSkillInvoke(this, QVariant::fromValue(use.from))) {
            kagami->setProperty("tucao_card", QVariant());
            CardUseStruct use = data.value<CardUseStruct>();
            const Card *card;
            if (use.card->isKindOf("BasicCard")){
               card = room->askForCard(kagami, "^BasicCard|.|.|hand", "@tucao", data);
            }
            if (use.card->isKindOf("TrickCard")){
               card = room->askForCard(kagami, "^TrickCard|.|.|hand", "@tucao", data);
            }
            if (card){
              if (card->isRed()){
                  room->setPlayerFlag(kagami, "tucao_red");
              }
              else{
                  room->setPlayerFlag(kagami, "tucao_black");
              }
              return true;
            }
        }
        kagami->setProperty("tucao_card", QVariant());
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *kagami = ask_who;
        CardUseStruct use = data.value<CardUseStruct>();
        if (kagami->hasFlag("tucao_red")){
            room->setPlayerFlag(kagami, "-tucao_red");
            kagami->drawCards(1);
            use.from->drawCards(1);
        }
        else{
            room->setPlayerFlag(kagami, "-tucao_black");
            QVariant dataforai = QVariant::fromValue(kagami);
            if (use.card->isKindOf("BasicCard") && !room->askForCard(use.from, ".Basic", "@tucao-discard:" + kagami->objectName(), dataforai)) {
                foreach(auto p, use.to){
                    use.nullified_list << p->objectName();
                }
                data = QVariant::fromValue(use);
            }
            else if(use.card->isKindOf("TrickCard") && !room->askForCard(use.from, ".Trick", "@tucao-discard:" + kagami->objectName(), dataforai)){
                if (!use.card->isNDTrick()){
                    foreach(auto p, use.to){
                        room->cancelTarget(use, p);
                    }
                    data = QVariant::fromValue(use);
                }
                else{
                    foreach(auto p, use.to){
                        use.nullified_list << p->objectName();
                    }
                    data = QVariant::fromValue(use);
                }
            }
        }
        return false;
    }
};

class Xietivs : public OneCardViewAsSkill
{
public:
    Xietivs() : OneCardViewAsSkill("xieti"){
       response_or_use = true;
    }

    bool viewFilter(const Card *card) const
    {
        return card->isKindOf("EquipCard");
    }

    const Card *viewAs(const Card *originalCard) const
    {
        Card *slash = new Slash(originalCard->getSuit(), originalCard->getNumber());
        slash->addSubcard(originalCard->getId());
        slash->setSkillName(objectName());
        slash->setShowSkill(objectName());
        return slash;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return Slash::IsAvailable(player);
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern == "slash" && player->hasSkill("xieti");
    }
};

class Xieti : public TriggerSkill
{
public:
    Xieti()
        : TriggerSkill("xieti")
    {
        events << CardUsed << CardResponded << TargetConfirmed;
        view_as_skill = new Xietivs;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (player->isRemoved()){
            return QStringList();
        }
        if (event == CardUsed) {
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card && use.card->getSkillName()==objectName()) {
                if (use.from && TriggerSkill::triggerable(player)) {
                    return QStringList(objectName());
                }
            }
        } else if (event == CardResponded) {
            CardResponseStruct resp = data.value<CardResponseStruct>();
            if (resp.m_card && resp.m_card->getSkillName()==objectName()) {
                if (resp.m_who && TriggerSkill::triggerable(player)) {
                    return QStringList(objectName());
                }
            }
        }
        else{
            CardUseStruct use = data.value<CardUseStruct>();
            if (TriggerSkill::triggerable(player) && use.card->getSkillName()==objectName() && player==use.from){
                QStringList targets;
                foreach (ServerPlayer *to, use.to) {
                    if (!to->hasShownAllGenerals())
                        targets << to->objectName();
                }
                if (!targets.isEmpty())
                    return QStringList(objectName() + "->" + targets.join("+"));
            }
        }

        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event!=TargetConfirmed &&player->askForSkillInvoke(this, data)) {
            return true;
        }
        else if (event==TargetConfirmed && ask_who->askForSkillInvoke(this, QVariant::fromValue(player))){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event!=TargetConfirmed){
            QString choice = room->askForChoice(player, objectName(), "move_left+move_right");
            if (choice == "move_left"){
                room->swapSeat(player, room->findPlayerbyobjectName(player->getLast()->objectName(), true));
            }
            else{
                room->swapSeat(player, room->findPlayerbyobjectName(player->getNext()->objectName(), true));
            }
        }
        else{
            player->askForGeneralShow(true);
        }
        return false;
    }
};

HuodanSummon::HuodanSummon()
    : ArraySummonCard("huodan")
{
}

class Huodan : public BattleArraySkill
{
public:
    Huodan() : BattleArraySkill("huodan", HegemonyMode::Siege)
    {
        events << DamageCaused;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual TriggerList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player->aliveCount()<4){
            return skill_list;
        }
        DamageStruct damage = data.value<DamageStruct>();
        QList<ServerPlayer *> skill_owners = room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *skill_owner, skill_owners) {
            if (BattleArraySkill::triggerable(skill_owner)
                && damage.card != NULL && damage.card->isKindOf("Slash") && damage.card->isBlack() && player->inSiegeRelation(skill_owner, damage.to) && !damage.to->getActualGeneral2Name().contains("sujiang")) {
                skill_list.insert(skill_owner, QStringList(objectName() + "->" + damage.to->objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *ask_who) const
    {
        if (ask_who != NULL && ask_who->askForSkillInvoke(this, data)) {
            room->doBattleArrayAnimate(ask_who, skill_target);
            room->broadcastSkillInvoke(objectName(), ask_who);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        damage.to->removeGeneral(false);
        return false;
    }
};

class Shanyao : public TriggerSkill
{
public:
    Shanyao()
        : TriggerSkill("shanyao")
    {
        events << SlashMissed;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        if (effect.slash->isRed()&&TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        SlashEffectStruct effect = data.value<SlashEffectStruct>();
        player->drawCards(1);
        Card *slash = Sanguosha->cloneCard("slash",Card::NoSuit,0);
        slash->setSkillName(objectName());
        CardUseStruct use;
        use.card = slash;
        use.from = player;
        use.to.append(effect.to);
        room->useCard(use, false);
        return false;
    }
};

class Jiansu : public TriggerSkill
{
public:
    Jiansu()
        : TriggerSkill("jiansu")
    {
        events << Damaged << EventPhaseStart;
    }

    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event==Damaged){
            DamageStruct damage = data.value<DamageStruct>();
            if (damage.card && damage.card->isKindOf("Slash")&& damage.to->getMark("jiansub")>0&&(damage.from->getMark("jiansua")>0||damage.from==room->getCurrent())){
                foreach(auto p, room->getAlivePlayers()){
                    if (p->getMark("jiansua")>0){
                        p->drawCards(1);
                        room->getCurrent()->drawCards(1);
                    }
                }
            }
        }
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;

        if(player->getPhase()==Player::Finish){
            QList<ServerPlayer *> asunas = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *asuna, asunas) {
                if (player!=asuna && room->getAlivePlayers().length()>1){
                    skill_list.insert(asuna, QStringList(objectName()));
                }
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (ask_who != NULL && ask_who->askForSkillInvoke(this, QVariant::fromValue(player))) {
            room->broadcastSkillInvoke(objectName(), ask_who);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *s = room->askForPlayerChosen(ask_who, room->getOtherPlayers(player),objectName(),"jiansu_invoke", true,true);
        if (s!=NULL && s!=ask_who){
                    room->setPlayerMark(s, "jiansub", 1);
                    room->setPlayerMark(ask_who, "jiansua", 1);
                    if (s->isAlive()){
                      const Card *slash = room->askForUseSlashTo(ask_who, s, "#jiansu", false);
                    }
                    if (s->isAlive()){
                      const Card *slash2 = room->askForUseSlashTo(player, s, "#jiansu", false);
                    }
                    room->setPlayerMark(s, "jiansub", 0);
                    room->setPlayerMark(ask_who, "jiansua", 0);
        }
        return false;
    }
};

ShixianCard::ShixianCard()
{
    target_fixed = true;
    will_throw = false;
    mute = true;
}


void ShixianCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    if (!show_skill.isEmpty() && !(source->inHeadSkills(show_skill) ? source->hasShownGeneral1() : source->hasShownGeneral2()))
        source->showGeneral(source->inHeadSkills(this->show_skill));

    if (!show_skill.isEmpty()) room->broadcastSkillInvoke("shixian", source);
    SkillCard::onUse(room, card_use);
}

void ShixianCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isAlive()){
        source->addToPile("shikongcundang", subcards, !source->hasShownSkill("jiaxiang"));
        room->drawCards(source, subcards.length());
    }
}

class Shixian : public ViewAsSkill
{
public:
    Shixian() : ViewAsSkill("shixian")
    {
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return selected.length() < Self->getMaxHp();
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.isEmpty())
            return NULL;

        ShixianCard *Shixian_card = new ShixianCard;
        Shixian_card->addSubcards(cards);
        Shixian_card->setSkillName(objectName());
        Shixian_card->setShowSkill(objectName());
        return Shixian_card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("ShixianCard") && player->getPile("shikongcundang").length()==0;
    }
};

class ShixianMax : public MaxCardsSkill
{
public:
    ShixianMax() : MaxCardsSkill("shixianmax")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->hasShownSkill("shixian") && target->getPile("shikongcundang").length()> target->getHp()){
            return target->getPile("shikongcundang").length()- target->getHp();
        }
        return 0;
    }
};

class Jiaxiang : public TriggerSkill
{
public:
    Jiaxiang() : TriggerSkill("jiaxiang")
    {
        events << TargetConfirming << EventPhaseStart;
        relate_to_place = "head";
    }

    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event == TargetConfirming){
            if (player == NULL) return skill_list;
            CardUseStruct use = data.value<CardUseStruct>();
            if (!use.card || !use.from || use.to.length()!=1 || use.card ->getSuit() == Card::NoSuit|| use.card->getTypeId() == Card::TypeSkill || use.card->isKindOf("EquipCard")){
                return skill_list;
            }
            QList<ServerPlayer *> okarins = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *okarin, okarins) {
                if (okarin->getPile("shikongcundang").length()>0 && (use.to.at(0)->isFriendWith(okarin)||use.from->isFriendWith(okarin)) && !room->getCurrent()->hasFlag("jiaxiangused"+okarin->objectName()))
                    skill_list.insert(okarin, QStringList(objectName()));
            }
        }
        if (event == EventPhaseStart){
            if (player->getPhase()!=Player::Start || !TriggerSkill::triggerable(player) || player->getPile("shikongcundang").length()==0){
                return skill_list;
            }
            int n=998;
            foreach(auto p, room->getAlivePlayers()){
                if (n>p->getHandcardNum()){
                    n = p->getHandcardNum();
                }
            }
            if (n == player->getHandcardNum()){
                skill_list.insert(player, QStringList(objectName()));
            }
        }
        return skill_list;
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        ServerPlayer *okarin = ask_who;
        if (okarin && okarin->askForSkillInvoke(this, data)) {
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event == TargetConfirming){
            CardUseStruct use = data.value<CardUseStruct>();
            ServerPlayer *okarin = ask_who;
            ServerPlayer *from = use.from;
            ServerPlayer *to = use.to.at(0);
            QList<int> list;
            foreach(int id, okarin->getPile("shikongcundang")){
                Card *card = Sanguosha->getCard(id);
                if (card->getColor()==use.card->getColor()){
                    list << id;
                }
            }
            if (list.length()>0){
                room->fillAG(list ,okarin);
                int id = room->askForAG(okarin, list, true, objectName());
                room->clearAG(okarin);
                if (id < 0) return false;
                room->setPlayerFlag(room->getCurrent(), "jiaxiangused"+okarin->objectName());
                room->throwCard(id, okarin, okarin);
                room->broadcastSkillInvoke(objectName(), rand()%4+1, okarin);
                room->cancelTarget(use, to);
                data = QVariant::fromValue(use);
                room->useCard(CardUseStruct(Sanguosha->getCard(id), from, to));
            }
        }
        if (event == EventPhaseStart){
            room->broadcastSkillInvoke(objectName(), 5, ask_who);
            ServerPlayer *okarin = ask_who;
            QList<int> list = okarin->getPile("shikongcundang");
            if (list.length()>0){
                room->fillAG(list ,okarin);
                int id = room->askForAG(okarin, list, false, objectName());
                room->clearAG(okarin);
                room->obtainCard(okarin, id, true);
            }
            DummyCard *dummy = new DummyCard;
            dummy->deleteLater();
            foreach(int id,okarin->getPile("shikongcundang")){
                dummy->addSubcard(id);
            }
            room->throwCard(dummy, okarin, okarin);
        }
        return false;
    }
};

TiaoyueCard::TiaoyueCard()
{
    target_fixed = true;
}


void TiaoyueCard::onUse(Room *room, const CardUseStruct &card_use) const
{
    ServerPlayer *source = card_use.from;
    if (!show_skill.isEmpty() && !(source->inHeadSkills(show_skill) ? source->hasShownGeneral1() : source->hasShownGeneral2()))
        source->showGeneral(source->inHeadSkills(this->show_skill));

    if (!show_skill.isEmpty()) room->broadcastSkillInvoke("tiaoyue", source);
    SkillCard::onUse(room, card_use);
}

void TiaoyueCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &) const
{
    if (source->isAlive()){
        room->doLightbox("se_tiaoyue$", 2000);
        DummyCard *dummy = new DummyCard;
        dummy->deleteLater();
        foreach(int id, source->getPile("shikongcundang")){
            dummy->addSubcard(id);
        }
        source->obtainCard(dummy, true);
    }
}

class Tiaoyue : public ViewAsSkill
{
public:
    Tiaoyue() : ViewAsSkill("tiaoyue")
    {
        relate_to_place = "deputy";
    }

    virtual bool viewFilter(const QList<const Card *> &selected, const Card *to_select) const
    {
        return !Self->isJilei(to_select) && selected.length() < (Self->getPile("shikongcundang").length()+1)/2 && !to_select->isKindOf("BasicCard");
    }

    virtual const Card *viewAs(const QList<const Card *> &cards) const
    {
        if (cards.length() < (Self->getPile("shikongcundang").length()+1)/2)
            return NULL;

        TiaoyueCard *vs = new TiaoyueCard;
        vs->addSubcards(cards);
        vs->setSkillName(objectName());
        vs->setShowSkill(objectName());
        return vs;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->canDiscard(player, "he") && !player->hasUsed("ShixianCard") && !player->hasUsed("TiaoyueCard") && player->getPile("shikongcundang").length()>0;
    }
};

class Shuji : public TriggerSkill
{
public:
    Shuji() : TriggerSkill("shuji")
    {
        events << CardsMoveOneTime << EventPhaseStart << EventPhaseEnd;
    }

     virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (triggerEvent == CardsMoveOneTime){
            CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
            if (move.reason.m_reason != CardMoveReason::S_REASON_USE && move.reason.m_reason != CardMoveReason::S_REASON_LETUSE){
                return QStringList();
            }

            if (move.card_ids.length() != 1 || move.to_place != Player::DiscardPile || !TriggerSkill::triggerable(player) || player->isNude()){
                return QStringList();
            }
            foreach(int card_id, move.card_ids){
                Card *card = Sanguosha->getCard(card_id);
                if (card->isKindOf("TrickCard")){

                    QList<int> list = player->getPile("huanshu");
                    if (list.length() > 8){
                        return QStringList();
                    }
                    bool has_same = false;
                    foreach(int id, list){
                        if (Sanguosha->getCard(id)->getClassName() == card->getClassName()){
                            has_same = true;
                            break;
                        }
                    }

                    if (!has_same){
                        return QStringList(objectName());
                    }
               }
           }
        }
        else if (triggerEvent == EventPhaseStart){
            if (TriggerSkill::triggerable(player)&&player->getPhase()==Player::Discard){
                return QStringList(objectName());
            }
        }
        else if (triggerEvent == EventPhaseEnd){
            if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Discard && player->hasFlag("shuji_max")){
                room->setPlayerFlag(player, "-shuji_max");
                QString _type = "TrickCard|.|.|hand"; // Handcards only
                room->removePlayerCardLimitation(player, "discard", _type);
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (event==CardsMoveOneTime) {
           CardsMoveOneTimeStruct move = data.value<CardsMoveOneTimeStruct>();
           Card *card = Sanguosha->getCard(move.card_ids.at(0));
           return player->askForSkillInvoke(this, data) && room->askForDiscard(player, objectName(), 1, 1, true, true, "@shuji-discard:" + card->getName());
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
            ServerPlayer *dalian = player;
            foreach(int card_id, move.card_ids){
                Card *card = Sanguosha->getCard(card_id);
                if (card->isKindOf("TrickCard")){

                    QList<int> list = dalian->getPile("huanshu");
                    if (list.length() > 8){
                        return false;
                    }
                    bool has_same = false;
                    foreach(int id, list){
                        if (Sanguosha->getCard(id)->getClassName() == card->getClassName()){
                            has_same = true;
                            break;
                        }
                    }

                    if (has_same){
                        continue;
                    }

                    room->setTag("shuji-card", QVariant(card_id));
                    room->broadcastSkillInvoke(objectName(), rand() % 3 + 1, dalian);
                    dalian->addToPile("huanshu", card_id);
                    room->removeTag("shuji-card");
                }
            }
        }
        else if(triggerEvent==EventPhaseStart){
            room->setPlayerFlag(player, "shuji_max");
            QString _type = "TrickCard|.|.|hand"; // Handcards only
            room->setPlayerCardLimitation(player, "discard", _type, false);
        }
        return false;
    }
};

class ShujiMaxCards : public MaxCardsSkill
{
public:
    ShujiMaxCards() : MaxCardsSkill("shujimax")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->hasShownSkill("shuji")){
            int num = 0;
            foreach (const Card* card, target->getHandcards()){
                num += card->isKindOf("TrickCard") ? 1 : 0;
            }
            return  num;
        }
        else
            return 0;
    }
};

class Jicheng : public TriggerSkill
{
public:
    Jicheng() : TriggerSkill("jicheng")
    {
        events << GeneralShown << EventPhaseEnd << EventAcquireSkill << EventLoseSkill << GeneralHidden << GeneralTransformed;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (event == GeneralShown || event == GeneralTransformed) {
            if (TriggerSkill::triggerable(player) && (!player->hasFlag("jichengchange"))){
                if ((player->inHeadSkills(objectName())&&player->hasShownGeneral2())||(!player->inHeadSkills(objectName()) && player->hasShownGeneral1())){
                    return QStringList(objectName());
                }
            }
        }
        else if (event==EventPhaseEnd){
            if (TriggerSkill::triggerable(player)&&player->getPhase()==Player::Finish&&player->getMark("kaiqiused")>0){
                room->setPlayerMark(player, "kaiqiused", 0);
                return QStringList(objectName());
            }
        }
        else if (event==EventAcquireSkill){
            if (data.toString().split(":").first()==objectName()){
                if ((player->inHeadSkills(objectName())&&player->hasShownGeneral2())||(!player->inHeadSkills(objectName()) && player->hasShownGeneral1())){
                    room->broadcastSkillInvoke(objectName());
                    room->doLightbox("jicheng$", 3000);
                    room->acquireSkill(player,"kaiqi",true,!player->inHeadSkills(objectName()));
                    room->acquireSkill(player,"shoushi",true,!player->inHeadSkills(objectName()));
                }
            }
        }
        else if (event==GeneralHidden){
            if (!player->hasFlag("jichengchange")){
                if (player->hasSkill("kaiqi") || player->hasSkill("shoushi")){
                    room->detachSkillFromPlayer(player, "kaiqi", false, false, data.toBool());
                    room->detachSkillFromPlayer(player, "shoushi", false, false, data.toBool());
                }
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if ((event == GeneralShown || event == GeneralTransformed)&& (player->hasShownSkill(objectName())||player->askForSkillInvoke(this, data))){
            return true;
        }
        else if (event==EventPhaseEnd){
            return player->askForSkillInvoke(this, data);
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if ((event == GeneralShown || event == GeneralTransformed)){
          if (!player->hasSkill("kaiqi")||!player->hasSkill("shoushi")){
              room->broadcastSkillInvoke(objectName());
              room->doLightbox("jicheng$", 2000);
              room->acquireSkill(player,"kaiqi",true, !player->inHeadSkills(objectName()));
              room->acquireSkill(player,"shoushi",true, !player->inHeadSkills(objectName()));
          }
        }
        else{
            if (player->inHeadSkills(objectName())){
                if (room->askForChoice(player,"transform","transform+cancel",data)=="transform"){
                    room->setPlayerFlag(player, "jichengchange");
                    player->showGeneral(false);
                    room->transformDeputyGeneral(player);
                    room->setPlayerFlag(player, "-jichengchange");
                }
            }
            else{
                /*if (room->askForChoice(player,"transform_head","transform_head+cancel",data)=="transform_head"){
                    room->setPlayerFlag(player, "jichengchange");
                    player->showGeneral(true);
                    room->transformHeadGeneral(player);
                    room->setPlayerFlag(player, "-jichengchange");
                }*/
                if (room->askForChoice(player,"transform","transform+cancel",data)=="transform"){
                    room->setPlayerFlag(player, "jichengchange");
                    player->showGeneral(false);
                    room->transformDeputyGeneral(player);
                    room->setPlayerFlag(player, "-jichengchange");
                }
            }
        }
        return false;
    }
};

class Kaiqi : public TriggerSkill
{
public:
    Kaiqi() : TriggerSkill("kaiqi")
    {
        events << EventPhaseStart;
    }

     virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (TriggerSkill::triggerable(player) && player->getPhase() == Player::Play && player->getPile("huanshu").length()>0){
            return QStringList(objectName());
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        return player->askForSkillInvoke(this, data);
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        QList<ServerPlayer *> left = room->getAlivePlayers();
        int i = 0;
        while (player->getPile("huanshu").length() > 0 && left.length() > 0){
            ServerPlayer *target = room->askForPlayerChosen(player, left, objectName(), "@shuji-prompt", true);
            if (!target){
                return false;
            }
            if (i == 0){
                room->broadcastSkillInvoke(objectName());
                room->doLightbox("kaiqi$", 800);
            }
            i++;

            left.removeOne(target);
            QList<int> card_ids = player->getPile("huanshu");
            room->fillAG(card_ids, player);
            int id = room->askForAG(player, card_ids, false, objectName());
            room->clearAG(player);
            if (id == -1){
                return false;
            }
            room->obtainCard(target, id);
            room->setPlayerMark(player, "kaiqiused", 1);
        }
        return false;
    }
};

class Shoushi : public TriggerSkill
{
public:
    Shoushi() : TriggerSkill("shoushi")
    {
        events << CardUsed << TargetConfirming;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (event==TargetConfirming && TriggerSkill::triggerable(player) &&use.card->isKindOf("TrickCard") && player->getPile("huanshu").length()>0){
             foreach(auto id, player->getPile("huanshu")){
                 Card *card = Sanguosha->getCard(id);
                 if (card->objectName()==use.card->objectName()){
                     return QStringList(objectName());
                 }
             }
        }
        if (event==CardUsed && TriggerSkill::triggerable(player) &&use.card->isNDTrick() && player->getPile("huanshu").length()>0){
            int n=0;
            foreach(auto id, player->getPile("huanshu")){
                 Card *card = Sanguosha->getCard(id);
                 if (card->getSuit()==use.card->getSuit()){
                     n=n+1;
                 }
             }
            if (n>=2){
                return QStringList(objectName());
            }
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

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event==CardUsed){
            player->drawCards(1);
        }
        else{
            CardUseStruct use = data.value<CardUseStruct>();
            room->cancelTarget(use, player);
            data = QVariant::fromValue(use);
        }
        return false;
    }
};

GaixieCard::GaixieCard()
{
    target_fixed = true;
}

void GaixieCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    room->loseMaxHp(player);
    player->drawCards(1);
    player->gainMark("@gaixie");
}

class Gaixie : public ZeroCardViewAsSkill
{
public:
    Gaixie() : ZeroCardViewAsSkill("gaixie"){

    }

    const Card *viewAs() const
    {
        GaixieCard *card = new GaixieCard();
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }

    bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("GaixieCard")&&player->getMaxHp()>1;
    }
};

class GaixieMax : public MaxCardsSkill
{
public:
    GaixieMax() : MaxCardsSkill("#gaixiemax")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->hasShownSkill("gaixie") && target->getMark("@gaixie")>0){
            return 1;
        }
        return 0;
    }
};

class GaixieDraw : public DrawCardsSkill
{
public:
   GaixieDraw() : DrawCardsSkill("#gaixiedraw")
    {
        frequency = Compulsory;
    }

    bool canPreshow() const
    {
        return false;
    }

    bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer *) const
    {
        if ((player->hasShownSkill("gaixie")&&player->getMark("@gaixie")>0)||(player->getMark("@gaixie")>0&& player->askForSkillInvoke("gaixie"))) {
            room->broadcastSkillInvoke(objectName(), qrand() % 2 + 1, player);
            return true;
        }
        return false;
    }

    int getDrawNum(ServerPlayer *kotarou, int n) const
    {
        Room *room = kotarou->getRoom();
        room->sendCompulsoryTriggerLog(kotarou, "gaixie");

        return n +qMin(kotarou->getMark("@gaixie"), 3);
    }
};

class GaixieDistance : public DistanceSkill
{
  public:
    GaixieDistance(): DistanceSkill("#gaixiedistance")
    {
    }

    int getCorrect(const Player *from, const Player *) const
    {
        if (from->hasSkill("gaixie") && from->hasShownSkill("gaixie"))
            return -from->getMark("@gaixie");
        else
            return 0;
    }
};

QiequCard::QiequCard()
{
}

bool QiequCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select != Self && targets.length() == 0 && (!to_select->isNude()||to_select->getJudgingArea().length()>0);
}

void QiequCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    ServerPlayer *target = targets.first();
    JudgeStruct judge;
    judge.reason = "qiequ";
    judge.who = target;
    room->judge(judge);
    QList<int> list;
    foreach(auto id, target->handCards()){
        if (Sanguosha->getCard(id)->getColor()!=judge.card->getColor())
            list << id;
    }
    foreach(auto c, target->getEquips()){
        if (c->getColor()!=judge.card->getColor())
            list << c->getEffectiveId();
    }
    foreach(auto c, target->getJudgingArea()){
        if (c->getColor()!=judge.card->getColor())
            list << c->getEffectiveId();
    }
    if (list.length() == target->getCards("hej").length()){
         room->showAllCards(target, source);
    }
    int id = room->askForCardChosen(source, target, "hej", "qiequ", true, Card::MethodNone, list);
    if (id > -1){
        room->obtainCard(source, id);
    }
}

class Qiequ : public OneCardViewAsSkill
{
public:
    Qiequ(): OneCardViewAsSkill("qiequ"){

    }

    bool viewFilter(const Card *card) const
    {
        return true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("QiequCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        QiequCard *card = new QiequCard;
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};


ZuduiSummon::ZuduiSummon()
    : ArraySummonCard("zudui")
{
}

class Zudui : public BattleArraySkill
{
public:
    Zudui() : BattleArraySkill("zudui", HegemonyMode::Formation)
    {
        events << EventPhaseStart << Death << EventLoseSkill << EventAcquireSkill
            << GeneralShown << GeneralHidden << GeneralRemoved << RemoveStateChanged;
    }

    virtual bool canPreshow() const
    {
        return false;
    }

    virtual QStringList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        if (player == NULL) return QStringList();

        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() != Player::RoundStart)
                return QStringList();
        } else if (triggerEvent == Death) {
            DeathStruct death = data.value<DeathStruct>();
            if (player != death.who)
                return QStringList();
        }

        foreach (ServerPlayer *p, room->getPlayers()) {
            if (p->getMark("zudui_qiangyun") > 0 && p->hasSkill("qiangyun") && !p->hasInnateSkill("qiangyun")) {
                p->setMark("zudui_qiangyun", 0);
                room->detachSkillFromPlayer(p, "qiangyun", true, true);
            }
        }

        if (triggerEvent == EventLoseSkill && data.toString().split(":").first() == "zudui")
            return QStringList();
        if (triggerEvent == GeneralHidden && player->ownSkill(this) && player->inHeadSkills(objectName()) == data.toBool())
            return QStringList();
        if (triggerEvent == GeneralRemoved && data.toString() == "kazuma")
            return QStringList();
        if (player->aliveCount() < 4)
            return QStringList();

        ServerPlayer *current = room->getCurrent();
        if (current && current->isAlive() && current->getPhase() != Player::NotActive) {
            QList<ServerPlayer *> kazumas = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *kazuma, kazumas) {

                if (kazuma->hasShownSkill(this) && kazuma->inFormationRalation(current) && !kazuma->hasInnateSkill("qiangyun")) {
                    room->doBattleArrayAnimate(kazuma);
                    kazuma->setMark("zudui_qiangyun", 1);
                    room->attachSkillToPlayer(kazuma, "qiangyun");
                }
            }
        }

        return QStringList();
    }

};

class Qiangyun : public TriggerSkill
{
public:
    Qiangyun() : TriggerSkill("qiangyun")
    {
        events << AskForRetrial;
    }

    virtual QStringList triggerable(TriggerEvent, Room *room, ServerPlayer *player, QVariant &, ServerPlayer * &) const
    {
        if (!TriggerSkill::triggerable(player)) return QStringList();
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *) const
    {
        JudgeStruct *judge = data.value<JudgeStruct *>();
        const Card *ori = judge->card;
        QString suit = room->askForChoice(player,objectName(), "spade+heart+diamond+club", data);
        QList<int> list;
        foreach(auto id, room->getDrawPile()){
            Card *c = Sanguosha->getCard(id);
            if (c->getSuitString()==suit){
                list << id;
            }
        }

        Card *card;

        if (list.length()>0){
            int n = rand()%list.length();
            card = Sanguosha->getCard(list.at(n));
        }

        room->retrial(card, player, judge, objectName());
        judge->updateResult();

        /*if(ori->getTypeId()==card->getTypeId()){
            room->obtainCard(player, card);
        }*/
        return false;
    }
};

class Tulong : public TriggerSkill
{
public:
    Tulong() : TriggerSkill("tulong")
    {
        events << DamageCaused << TargetConfirmed << TargetChosen;
        frequency = Compulsory;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        if (event== DamageCaused ){
            DamageStruct damage = data.value<DamageStruct>();
            if (TriggerSkill::triggerable(player)&&damage.card && damage.card->isKindOf("Slash")&&damage.to->getHp()>=player->getHp()&&!damage.chain){
                return QStringList(objectName());
            }
        }
        if (event==TargetConfirmed && TriggerSkill::triggerable(player) &&use.card->isKindOf("Slash") && player==use.from){
             foreach(auto p, use.to){
                 if (!p->hasShownOneGeneral())
                     return QStringList();
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
                 if (invoke){
                     return QStringList(objectName());
                 }
             }
        }
        if (event==TargetChosen  && TriggerSkill::triggerable(player) && use.card != NULL && use.card->isKindOf("Slash")){
            QStringList targets;
            foreach (ServerPlayer *to, use.to) {
                int handcard_num = to->getHandcardNum();
                if (handcard_num >= player->getHandcardNum())
                    targets << to->objectName();
            }
            if (!targets.isEmpty())
                return QStringList(objectName() + "->" + targets.join("+"));
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (event==TargetChosen && (player->hasShownSkill(objectName())||player->askForSkillInvoke(this, QVariant::fromValue(skill_target)))) {
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        else if (event!=TargetChosen && (skill_target->hasShownSkill(objectName())||skill_target->askForSkillInvoke(this, data))){
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event==DamageCaused){
            DamageStruct damage = data.value<DamageStruct>();
            room->sendCompulsoryTriggerLog(player, objectName());
            damage.damage =  damage.damage+1;
            data.setValue(damage);
        }
        else if(event==TargetConfirmed){
            CardUseStruct use = data.value<CardUseStruct>();
            room->sendCompulsoryTriggerLog(player, objectName());
            room->addPlayerHistory(player, use.card->getClassName(), -1);
        }
        else{
            CardUseStruct use = data.value<CardUseStruct>();
            QVariantList jink_list = ask_who->tag["Jink_" + use.card->toString()].toList();

            room->sendCompulsoryTriggerLog(ask_who, objectName());

            int index = use.to.indexOf(player);
            LogMessage log;
            log.type = "#NoJink";
            log.from = player;
            player->getRoom()->sendLog(log);
            jink_list[index] = 0;

            ask_who->tag["Jink_" + use.card->toString()] = jink_list;
        }
        return false;
    }
};


CongyunSummon::CongyunSummon()
    : ArraySummonCard("congyun")
{
}

class Congyun : public BattleArraySkill
{
public:
    Congyun() : BattleArraySkill("congyun", HegemonyMode::Formation)
    {
        events << CardFinished;
    }

    virtual bool canPreshow() const
    {
        return true;
    }

    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
   {
       CardUseStruct use = data.value<CardUseStruct>();
       if (player->aliveCount() < 4)
           return QStringList();
       if (event== CardFinished ){
           if (TriggerSkill::triggerable(player)&&use.card->isKindOf("Slash")&&player->getFormation().length()>1){
               return QStringList(objectName());
           }
       }
       return QStringList();
   }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (player->askForSkillInvoke(this, data)) {
            room->doBattleArrayAnimate(player);
            room->broadcastSkillInvoke(objectName(), player);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        CardUseStruct use = data.value<CardUseStruct>();
        foreach(auto p, room->getOtherPlayers(player)){
            if (player->inFormationRalation(p) && player!=p){
               QString choice = room->askForChoice(p, objectName(), "congyun_slash+congyun_give+cancel", data);
               QList<ServerPlayer*> list;
               foreach(auto q, use.to){
                   if (q->isAlive())
                       list << q;
               }

               if (choice=="congyun_slash" && !list.isEmpty()){
                   room->askForUseSlashTo(p, list, "@congyun-slash", false);
               }
               if (choice=="congyun_give"&&!p->isNude()){
                   int id = room->askForCardChosen(p,p,"he",objectName());
                   room->obtainCard(player,id, false);
               }
            }

        }
        return false;
    }
};

MaihuoCard::MaihuoCard()
{
    will_throw = false;
    handling_method = Card::MethodNone;
}

bool MaihuoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return to_select != Self && targets.length() == 0;
}

void MaihuoCard::use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const
{
    room->moveCardTo(Sanguosha->getCard(subcards.first()), NULL, Player::DrawPile);
    QList<int> card_to_show = room->getNCards(2, false);
    CardsMoveStruct move(card_to_show, NULL, Player::PlaceTable, CardMoveReason(CardMoveReason::S_REASON_TURNOVER, targets.first()->objectName()));
    room->moveCardsAtomic(move, true);
    room->getThread()->delay();
    bool bothred = true;
    DummyCard *dummy = new DummyCard;
    dummy->deleteLater();
    foreach (int id, card_to_show) {
        dummy->addSubcard(id);
        if (!Sanguosha->getCard(id)->isRed())
            bothred = false;
    }

    room->obtainCard(targets.first(), dummy);
    if (bothred) {
        QString choice = "draw";
        if (source->isWounded())
            choice = room->askForChoice(source, "maihuo", "draw+recover");
        if (choice == "draw")
            source->drawCards(2);
        else {
            RecoverStruct recover;
            recover.who = source;
            room->recover(source, recover);
        }
    }
}

class Maihuo : public OneCardViewAsSkill
{
public:
    Maihuo()
        : OneCardViewAsSkill("maihuo")
    {
        filter_pattern = ".|.|.|hand";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasUsed("MaihuoCard");
    }

    virtual const Card *viewAs(const Card *originalCard) const
    {
        MaihuoCard *card = new MaihuoCard;
        card->addSubcard(originalCard);
        card->setSkillName(objectName());
        card->setShowSkill(objectName());
        return card;
    }
};

class Wunian : public TriggerSkill
{
public:
    Wunian() : TriggerSkill("wunian")
    {
        events << Predamage << TargetConfirming;
        frequency = Compulsory;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        if (event==Predamage && TriggerSkill::triggerable(player)){
            return QStringList(objectName());
        }
        else if(event==TargetConfirming && TriggerSkill::triggerable(player)){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->getTypeId() == Card::TypeTrick && player->isWounded() && use.from && player!=use.from) {
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (player->hasShownSkill(objectName())||player->askForSkillInvoke(this, data)){
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent e, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (e == Predamage) {
            DamageStruct damage = data.value<DamageStruct>();

            ServerPlayer *target
                = room->askForPlayerChosen(player, room->getOtherPlayers(player), objectName(), "@wunian_transfer:" + damage.to->objectName(), false, true);
            damage.from = target;
            damage.transfer = true;
            data = QVariant::fromValue(damage);
        } else if (e == TargetConfirming) {
            CardUseStruct use = data.value<CardUseStruct>();
            room->cancelTarget(use, player);
            data = QVariant::fromValue(use);
            LogMessage log;
            log.type = "#SkillAvoid";
            log.from = player;
            log.arg = objectName();
            log.arg2 = use.card->objectName();
            room->notifySkillInvoked(player, objectName());
            room->sendLog(log);
        }
        return false;
    }
};

class Qianlei : public TriggerSkill
{
public:
    Qianlei() : TriggerSkill("qianlei")
    {
        events << Dying;
    }

     virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer* &) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        if (!dying.damage || !dying.damage->from || !TriggerSkill::triggerable(player)){
            return QStringList();
        }
        return QStringList(objectName());
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        player->setProperty("qianlei_from", QVariant::fromValue(dying.damage->from));
        if (player->askForSkillInvoke(this, QVariant::fromValue(dying.who))){
            player->setProperty("qianlei_from", QVariant());
            return true;
        }
        player->setProperty("qianlei_from", QVariant());
        return false;
    }

    virtual bool effect(TriggerEvent e, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DyingStruct dying = data.value<DyingStruct>();
        QString choice = room->askForChoice(player, objectName(), "se_qianlei_first+se_qianlei_second", data);
        if (choice == "se_qianlei_first"){
            if (player->isNude()){
                return false;
            }
            int id = room->askForCardChosen(player, player, "he", objectName());
            if (id == -1) return false;
            room->broadcastSkillInvoke(objectName(), rand()%3+1);
            room->doLightbox("se_qianlei1$", 1200);
            room->obtainCard(dying.who, id);
            Card *card = Sanguosha->cloneCard("slash", Card::NoSuit, 0);
            card->setSkillName(objectName());
            CardUseStruct use;
            use.from = player;
            use.to.append(dying.damage->from);
            use.card = card;
            room->useCard(use, false);
        }
        else{
            if (dying.who->getHandcardNum()==0) return false;
            room->broadcastSkillInvoke(objectName(), rand()%2+4);
            room->doLightbox("se_qianlei2$", 1200);
            room->showAllCards(dying.who, player);
            foreach (auto c , dying.who->getHandcards()){
                if (c->isRed()) {
                    room->throwCard(c, dying.who, player);
                }
            }
        }
        return false;
    }
};

class Shuacun : public TriggerSkill
{
public:
    Shuacun() : TriggerSkill("shuacun")
    {
        events << TargetConfirmed << EventPhaseEnd << EventPhaseChanging;
    }

     virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event== TargetConfirmed){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.from && use.from->getPhase()==Player::Play && use.card->getTypeId() != Card::TypeSkill){
                foreach(auto p, use.to){
                    room->setPlayerFlag(p, "sonzaikan_aru");
                }
            }
        }
        if (event== EventPhaseChanging && data.value<PhaseChangeStruct>().from == Player::Play){
            QList<ServerPlayer *> fubukis = room->getAlivePlayers();
            foreach (ServerPlayer *fubuki, fubukis) {
                if(fubuki->hasFlag("sonzaikan_aru")) {
                    room->setPlayerFlag(fubuki, "-sonzaikan_aru");
                }
            }
        }
    }
     virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (event== EventPhaseEnd && player->getPhase()==Player::Play){
            QList<ServerPlayer *> fubukis = room->findPlayersBySkillName(objectName());
            foreach (ServerPlayer *fubuki, fubukis) {
                if (!fubuki->hasFlag("sonzaikan_aru") &&  !fubuki->isKongcheng() && player != fubuki){
                    skill_list.insert(fubuki, QStringList(objectName()));
                }
                /*else if(fubuki->hasFlag("sonzaikan_aru")) {
                    room->setPlayerFlag(fubuki, "-sonzaikan_aru");
                }*/
            }
        }


        return skill_list;
    }

    virtual bool cost(TriggerEvent event, Room *room, ServerPlayer *skill_target, QVariant &data, ServerPlayer *player) const
    {
        if (event == EventPhaseEnd){
            if (player->askForSkillInvoke(this, data)){
                room->broadcastSkillInvoke(objectName());
                return true;
            }
        }
        return false;
    }

     virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        if (event == EventPhaseEnd){
            int num = ask_who->getHandcardNum()/2;
            bool good;
            if (num>0){
                good = room->askForDiscard(ask_who, objectName(), num, num, false, false);
            }
            else{
                good = true;
            }
            if (good){
                ask_who->drawCards(ask_who->getHandcardNum());
            }
        }
        return false;
    }
};

//companion skills
class Lixiangjianqiao : public TriggerSkill
{
public:
    Lixiangjianqiao() : TriggerSkill("lixiangjianqiao")
    {
        frequency = Frequent;
        events << DamageInflicted <<EventAcquireSkill;
    }

    virtual TriggerList triggerable(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList skill_list;
        if (player == NULL) return skill_list;
        if (triggerEvent==EventAcquireSkill){
            if (data.toString().split(":").first()==objectName()){
                room->broadcastSkillInvoke(objectName(), rand()%2+1, player);
                room->doLightbox("Lixiangjianqiao$",2500);
            }
            return skill_list;
        }
        QList<ServerPlayer *> shibers= room->findPlayersBySkillName(objectName());
        foreach (ServerPlayer *shiber, shibers) {
            if (shiber->willBeFriendWith(player) && !shiber->property("utopia").toStringList().contains(player->objectName()))
                skill_list.insert(shiber, QStringList(objectName()));
        }
    }

    virtual bool cost(TriggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *shiber = ask_who;
        if (damage.to && shiber && shiber->askForSkillInvoke(this, QVariant::fromValue(damage.to))) {
            room->broadcastSkillInvoke(objectName(), rand()%2+3,shiber);
            return true;
        }
        return false;
    }

    virtual bool effect(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer *ask_who) const
    {
        DamageStruct damage = data.value<DamageStruct>();
        ServerPlayer *shiber = ask_who;
        if (!shiber)
            return false;
        if (player->isWounded()){
            RecoverStruct recover;
            recover.recover = 1;
            recover.who = shiber;
            room->recover(player, recover, true);
        }
        QStringList list=shiber->property("utopia").toStringList();
        list.append(player->objectName());
        shiber->setProperty("utopia",QVariant(list));
        return true;
    }
};

NewtestPackage::NewtestPackage()
    : Package("newtest")
{
   skills << new keyCardGlobalManagement;
   skills << new ZhurenTrigger << new CangshanTrigger << new CangshanTargetMod;
   skills << new ZhushouTrigger << new PaojiTargetMod << new Reimugive;
   skills << new Sanduneffect << new Wangxiangeffect << new Qijieffect;
   skills << new Lixiangjianqiao << new Qiangyun;
   skills << new SixuMax << new Yizhiresponse << new ShujiMaxCards << new Kaiqi << new Shoushi << new ShixianMax << new ShengjianRange;

   General *tomoya = new General(this, "Tomoya", "real");
   tomoya->addSkill(new Zhuren);
   tomoya->addSkill(new Guangyu);
   tomoya->setHeadMaxHpAdjustedValue();
   tomoya->addRelateSkill("xiyuan");
   General *keima = new General(this, "Keima", "real", 3);
   keima->addSkill(new Newshenzhi);
   keima->addSkill(new Gonglue);
   General *kanade = new General(this, "Kanade", "real", 3, false);
   kanade->addSkill(new Shouren);
   kanade->addSkill(new Qiyuan);
   kanade->addSkill(new Lichang);
   General *shizuo = new General(this, "Shizuo", "real", 5);
   shizuo->addSkill(new Baonu);
   shizuo->addSkill(new Jizhan);
   General *yuuta = new General(this, "Yuuta", "real");
   yuuta->addSkill(new Heiyan);
   yuuta->addSkill(new Wangxiang);
   yuuta->setDeputyMaxHpAdjustedValue(-1);
   yuuta->addCompanion("Rikka");
   General *akarin = new General(this, "Akarin", "real", 3, false);
   akarin->addSkill(new Wucun);
   akarin->addSkill(new Kongni);
   General *tsukushi = new General(this, "tsukushi", "real", 3, false);
   tsukushi->addSkill(new Tiaojiao);
   tsukushi->addSkill(new Gangqu);
   //tsukushi->addSkill(new GangquClear);
   //insertRelatedSkills("gangqu", "#gangqu-clear");
   General *rikka = new General(this, "Rikka", "real", 3, false);
   rikka->addSkill(new Xieyan);
   rikka->addSkill(new Sandun);
   rikka->addSkill(new Zhonger);
   rikka->addSkill(new ZhongerTargetMod);
   insertRelatedSkills("zhonger", "#zhonger-target");
   General *taiga = new General(this, "Taiga", "real", 3, false);
   taiga->addSkill(new Zhudao);
   taiga->addSkill(new Sixu);
   General *tukasa = new General(this, "Tukasa", "real", 3, false);
   tukasa->addSkill(new Tianran);
   tukasa->addSkill(new Liaoli);
   General *hikigaya = new General(this, "Hikigaya", "real", 4);
   hikigaya->addSkill(new Zishang);
   hikigaya->addSkill(new Zibi);
   General *yyui = new General(this, "Yyui", "real", 3, false);
   yyui->addSkill(new Wenchang);
   yyui->addSkill(new Yuanxin);

   General *shana = new General(this, "Shana", "magic", 3, false);
   shana->addSkill(new Duanzui);
   shana->addSkill(new Tianhuo);
   General *hakaze = new General(this, "hakaze", "magic", 3, false);
   hakaze->addSkill(new Moju);
   hakaze->addSkill(new Jiejie);
   General *saber = new General(this, "Saber", "magic", 4, false);
   saber->addSkill(new Shengjian);
   saber->addSkill(new Wangzhe);
   saber->addSkill(new Duimoli);
   saber->setDeputyMaxHpAdjustedValue();
   saber->addRelateSkill("lixiangjianqiao");
   saber->addCompanion("EmiyaShirou");
   insertCompanionSkill("Saber","EmiyaShirou","lixiangjianqiao");
   General *odanobuna = new General(this, "odanobuna", "magic", 3, false);
   odanobuna->addSkill(new Chigui);
   odanobuna->addSkill(new Buwu);
   odanobuna->addSkill(new Tianmo);
   General *Eustia = new General(this, "Eustia", "magic", 3, false);
   Eustia->addSkill(new Jinghua);
   Eustia->addSkill(new Jiushu);
   General *kinpika = new General(this, "Kinpika", "magic", 3);
   kinpika->addSkill(new Caibao);
   kinpika->addSkill(new Guaili);
   kinpika->addSkill(new Tiansuo);
   General *mao_maoyu = new General(this, "mao_maoyu", "magic", 4, false);
   mao_maoyu->addSkill(new Boxue);
   General *shirou = new General(this, "EmiyaShirou", "magic");
   shirou->addSkill(new Toushe);
   shirou->addSkill(new TousheRange);
   shirou->addSkill(new Jianjie);
   shirou->addSkill(new JianjieRecord);
   //shirou->addSkill(new JianjieClear);
   shirou->addRelateSkill("lixiangjianqiao");
   insertRelatedSkills("toushe", "#tousherange");
   insertRelatedSkills("jianjie", "#jianjie-record");
   shirou->setHeadMaxHpAdjustedValue(-1);
   General *kntsubasa=new General(this,"kntsubasa","magic",4,false);
   kntsubasa->addSkill(new Cangshan);
   kntsubasa->addSkill(new Yuehuang);
   kntsubasa->addSkill(new YuehuangTargetMod);
   insertRelatedSkills("yuehuang", "#yuehuang-res");
   General *kkotori = new General(this, "KKotori", "magic", 3, false);
   kkotori->addSkill(new Jianshi);
   kkotori->addSkill(new Qiyue);
   General *kurumi = new General(this, "Kurumi", "magic", 3, false);
   kurumi->addSkill(new Kekedi);
   kurumi->addSkill(new Kekedieff);
   insertRelatedSkills("kekedi", "#kekedieff");
   kurumi->addSkill(new Badan);
   General *louise = new General(this, "Louise", "magic", 3, false);
   louise->addSkill(new Lingjie);
   louise->addSkill(new Xuwu);

   General *ayanami = new General(this, "ayanami", "science", 3, false);
   ayanami->addSkill(new Weixiao);
   ayanami->addSkill(new Chidun);
   General *touma = new General(this, "Touma", "science", 4);
   touma->addSkill(new Huansha);
   touma->addSkill(new Dapo);
   touma->addCompanion("Mikoto");
   General *acc = new General(this, "acc", "science", 3);
   acc->addSkill(new Vector);
   acc->addSkill(new Bianhua);
   General *mikoto = new General(this, "Mikoto", "science", 3, false);
   mikoto->addSkill(new Paoji);
   mikoto->addSkill(new Dianci);
   General *redo = new General(this, "redo", "science", 3);
   redo->addSkill(new Gaoxiao);
   redo->addSkill(new GaoxiaoTargetMod);
   insertRelatedSkills("gaoxiao", "#gaoxiao-1");
   redo->addSkill(new Gaokang);
   General *kuroyukihime = new General(this, "Kuroyukihime", "science", 3, false);
   kuroyukihime->addSkill(new Jiasugaobai);
   kuroyukihime->addSkill(new Juedoujiasu);
   kuroyukihime->addSkill(new Sexunyu);
   General *aria = new General(this, "Aria", "science", 3, false);
   aria->addSkill(new Shuangqiang);
   aria->addSkill(new Wujie);
   General *nao = new General(this, "Nao", "science", 3, false);
   nao->addSkill(new Huanxing);
   nao->addSkill(new Fushang);
   General *mine = new General(this, "Mine", "science", 3, false);
   mine->addSkill(new Nangua);
   mine->addSkill(new Jixian);
   General *eren = new General(this, "SE_Eren", "science", 4);
   eren->addSkill(new Qixin);
   eren->addSkill(new Juejue);
   General *kurisu = new General(this, "Kurisu", "science", 3, false);
   kurisu->addSkill(new Tiancai);
   kurisu->addSkill(new Zhushou);
   General *sakamoto = new General(this, "Sakamoto", "science", 4);
   sakamoto->addSkill(new Xianjing);
   //sakamoto->addSkill(new XianjingClear);
   //insertRelatedSkills("xianjing", "#xianjing-clear");


   General *reimu = new General(this, "Reimu", "game", 3, false);
   reimu->addSkill(new Mengfeng);
   reimu->addSkill(new Saiqian);
   //reimu->addRelateSkill("reimugive");
   insertRelatedAttachSkill("saiqian", "reimugive");
   //reimu->addSkill(new Tongjie);
   reimu->addCompanion("Marisa");
   General *marisa = new General(this, "Marisa", "game", 4, false);
   marisa->addSkill(new Mingqie);
   marisa->addSkill(new Mopao);
   marisa->setHeadMaxHpAdjustedValue();
   General *kongou = new General(this, "Kongou", "game", 4, false);
   kongou->addSkill(new Nuequ);
   kongou->addSkill(new BurningLove);
   General *Kaga = new General(this, "Kaga", "game", 4, false);
   Kaga->addSkill(new Weishi);
   Kaga->addSkill(new WeishiDistance);
   Kaga->addSkill(new WeishiRecord);
   Kaga->addSkill(new Hongzha);
   //Kaga->addSkill(new WeishiClear);
   insertRelatedSkills("weishi", 2, "#weishi-record", "#weishidistance");
   General *shimakaze = new General(this, "Shimakaze", "game", 3, false);
   shimakaze->addSkill(new Jifeng);
   shimakaze->addSkill(new Huibi);
   General *nanoka = new General(this, "Nanoka", "game", 3, false);
   nanoka->addSkill(new Gongfang);
   nanoka->addSkill(new Fuxing);
   General *kurt = new General(this, "Kurt", "game", 3);
   kurt->addSkill(new Zhishu);
   kurt->addSkill(new Zhanshu);
   kurt->addSkill(new Wuming);
   General *azura = new General(this, "Azura", "game", 3, false);
   azura->addSkill(new Azuyizhi);
   azura->addSkill(new Gewu);
   General *yuudachi = new General(this, "Yuudachi", "game", 4, false);
   yuudachi->addSkill(new Kuangquan);
   yuudachi->addSkill(new Emeng);
   yuudachi->addSkill(new EmengTargetMod);
   insertRelatedSkills("emeng", "#emengtargetmod");
   yuudachi->setHeadMaxHpAdjustedValue(-1);
   General *kitagami = new General(this, "Kitagami", "game", 3, false);
   kitagami->addSkill(new Leimu);
   kitagami->addSkill(new Yezhan);
   General *sanae = new General(this, "Sanae", "game", 3, false);
   sanae->addSkill(new Jiyi);
   sanae->addSkill(new Zmqiji);
   General *satori = new General(this, "Satori", "game", 3, false);
   satori->addSkill(new Xiangqi);
   satori->addSkill(new Duxin);

  //first extension
   General *k1 = new General(this, "k1", "real", 4);
   k1->addSkill(new Qiubang);
   k1->addSkill(new QiubangDistance);
   k1->addSkill(new QiubangTargetMod);
   insertRelatedSkills("qiubang", 2, "#qiubangdistance", "#qiubang-target");
   k1->addSkill(new Randong);

   General *koromo = new General(this, "Koromo", "real", 3, false);
   koromo->addSkill(new Kongyun);
   koromo->addSkill(new Laoyue);

   General *kagami = new General(this, "Kagami", "real", 3, false);
   kagami->addSkill(new Zhengchang);
   kagami->addSkill(new Tucao);
   kagami->addCompanion("Tukasa");

   General *rentaro = new General(this, "Rentaro", "science", 4);
   rentaro->addSkill(new Xieti);
   rentaro->addSkill(new Huodan);

   General *asuna = new General(this, "SE_Asuna", "science", 3, false);
   asuna->addSkill(new Shanyao);
   asuna->addSkill(new Jiansu);

   General *okarin = new General(this, "Okarin", "science", 4);
   okarin->addSkill(new Shixian);
   okarin->addSkill(new Jiaxiang);
   okarin->addSkill(new Tiaoyue);
   okarin->setHeadMaxHpAdjustedValue(-1);
   okarin->addCompanion("Kurisu");

   General *dalian = new General(this, "Dalian", "magic", 3, false);
   dalian->addSkill(new Shuji);
   dalian->addSkill(new Jicheng);
   dalian->addRelateSkill("kaiqi");
   dalian->addRelateSkill("shoushi");

   General *kotarou = new General(this, "Kotarou", "magic", 5);
   kotarou->addSkill(new Gaixie);
   kotarou->addCompanion("KKotori");
   kotarou->addSkill(new GaixieMax);
   kotarou->addSkill(new GaixieDraw);
   kotarou->addSkill(new GaixieDistance);
   insertRelatedSkills("gaixie", 3, "#gaixiemax", "#gaixiedraw", "#gaixiedistance");

   General *kazuma = new General(this, "Kazuma", "magic", 4);
   kazuma ->addSkill(new Qiequ);
   kazuma ->addSkill(new Zudui);
   kazuma->addRelateSkill("qiangyun");

   General *samurai = new General(this, "Samurai", "game", 4, false);
   samurai->addSkill(new Tulong);
   samurai->addSkill(new Congyun);

   General *koishi = new General(this, "Koishi", "game", 3, false);
   koishi->addSkill(new Maihuo);
   koishi->addSkill(new Wunian);
   koishi->addCompanion("Satori");

   General *fubuki = new General(this, "Fubuki", "game", 3, false);
   fubuki->addSkill(new Qianlei);
   fubuki->addSkill(new Shuacun);

   addMetaObject<Key>();
   addMetaObject<ZhurenCard>();
   addMetaObject<GonglueCard>();
   addMetaObject<ShourenCard>();
   addMetaObject<QiyuanCard>();
   addMetaObject<JizhanCard>();
   addMetaObject<LiaoliCard>();
   addMetaObject<HeiyanCard>();
   addMetaObject<TiaojiaoCard>();
   addMetaObject<DuanzuiCard>();
   addMetaObject<MojuCard>();
   addMetaObject<ShengjianCard>();
   addMetaObject<CaibaoCard>();
   addMetaObject<GuailiCard>();
   addMetaObject<KekediCard>();
   addMetaObject<BadanCard>();
   addMetaObject<BoxueCard>();
   addMetaObject<NuequCard>();
   addMetaObject<HongzhaCard>();
   addMetaObject<BianhuaCard>();
   addMetaObject<YuleiCard>();
   addMetaObject<LingjieCard>();
   addMetaObject<XuwuCard>();
   addMetaObject<GongfangCard>();
   addMetaObject<AzuyizhiCard>();
   addMetaObject<YizhiresponseCard>();
   addMetaObject<RandongSummon>();
   addMetaObject<YuehuangCard>();
   addMetaObject<HuodanSummon>();
   addMetaObject<ReimugiveCard>();
   addMetaObject<CongyunSummon>();
   addMetaObject<LaoyueCard>();
   addMetaObject<GaixieCard>();
   addMetaObject<MaihuoCard>();
   addMetaObject<ShixianCard>();
   addMetaObject<TiaoyueCard>();
   addMetaObject<QiequCard>();
   addMetaObject<ZuduiSummon>();
}

NewtestCardPackage::NewtestCardPackage()
    : Package("newtestcard",CardPack)
{
    QList<Card *> cards;
    cards << new Key(Card::Heart, 10)
        << new Key(Card::Heart, 4)
        << new Key(Card::Diamond, 8)
        << new Key(Card::Spade, 11)
        << new Key(Card::Club, 1);

    foreach(Card *card, cards)
        card->setParent(this);

    addMetaObject<Key>();
}

ADD_PACKAGE(Newtest)
ADD_PACKAGE(NewtestCard)
