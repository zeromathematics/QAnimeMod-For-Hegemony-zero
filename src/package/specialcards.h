#ifndef SPECIALCARDS
#define SPECIALCARDS

#include "package.h"
#include "card.h"
#include "wrappedcard.h"
#include "skill.h"
#include "standard.h"
#include "generaloverview.h"


class SpecialCardPackage : public Package
{
    Q_OBJECT

public:
    SpecialCardPackage();
};

class FadingCardPackage : public Package
{
    Q_OBJECT

public:
    FadingCardPackage();
};

class FadingPackage : public Package
{
    Q_OBJECT

public:
    FadingPackage();
};

class MapoTofu : public BasicCard
{
    Q_OBJECT

public:
    Q_INVOKABLE MapoTofu(Card::Suit suit, int number);
    QString getSubtype() const;

    static bool IsAvailable(const Player *player, const Card *analeptic = NULL);

    bool isAvailable(const Player *player) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class Tacos : public BasicCard
{
    Q_OBJECT

public:
    Q_INVOKABLE Tacos(Card::Suit suit, int number);
    QString getSubtype() const;

    bool isAvailable(const Player *player) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
};

class LinkStart : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE LinkStart(Card::Suit suit, int number);

    virtual QString getSubtype() const;

    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    //virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
    virtual bool isAvailable(const Player *player) const;
};

class RenkinChouwa : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE RenkinChouwa(Card::Suit suit, int number);

    virtual QString getSubtype() const;

    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    //virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
    virtual bool isAvailable(const Player *player) const;
};

class PengtiaoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE PengtiaoCard();
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class XiangsuiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE XiangsuiCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class PenglaiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE PenglaiCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class JianwuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE JianwuCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class KanhuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE KanhuCard();
    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class TaxianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE TaxianCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    virtual bool targetsFeasible(const QList<const Player *> &targets, const Player *Self) const;
};

class YingxianCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE YingxianCard();

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class QiehuoCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE QiehuoCard();

    virtual bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class SujiuCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE SujiuCard();

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class RenkinCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE RenkinCard();

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

class GuandaiCard : public SkillCard
{
    Q_OBJECT

public:
    Q_INVOKABLE GuandaiCard();

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
};

//herobattle
class Music : public BasicCard
{
    Q_OBJECT

public:
    Q_INVOKABLE Music(Card::Suit suit, int number);
    QString getSubtype() const;

    bool isAvailable(const Player *player) const;
    void onUse(Room *room, const CardUseStruct &card_use) const;
    void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    void onEffect(const CardEffectStruct &effect) const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
};

class  Clowcard : public BasicCard
{
    Q_OBJECT

public:
    Q_INVOKABLE Clowcard(Card::Suit suit, int number);
    QString getSubtype() const;
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
};

class Shinai : public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE Shinai(Card::Suit suit = Diamond, int number = 1);
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
};

class Josou : public Armor
{
    Q_OBJECT

public:
    Q_INVOKABLE Josou(Card::Suit suit = Club, int number = 13);
    bool targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const;
    void onInstall(ServerPlayer *player) const;
    void onUninstall(ServerPlayer *player) const;
};

class Idolyousei : public Treasure
{
    Q_OBJECT

public:
    Q_INVOKABLE Idolyousei(Card::Suit suit = Heart, int number = 7);
    void onInstall(ServerPlayer *player) const;
};

class Igiari : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE Igiari(Card::Suit suit, int number);

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    virtual bool isAvailable(const Player *player) const;
};

class Negi : public Weapon
{
    Q_OBJECT

public:
    Q_INVOKABLE Negi(Card::Suit suit = Diamond, int number = 7);
};

class Idolclothes : public Armor
{
    Q_OBJECT

public:
    Q_INVOKABLE Idolclothes (Card::Suit suit = Diamond, int number = 5);
};

class ShiningConcert : public AOE
{
    Q_OBJECT

public:
    Q_INVOKABLE ShiningConcert(Card::Suit suit, int number, bool is_transferable = false);

    //virtual bool isAvailable(const Player *player) const;
    //virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

class IdolRoad : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE IdolRoad(Card::Suit suit, int number);

    virtual QString getSubtype() const;

    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    //virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
    virtual bool isAvailable(const Player *player) const;
};

class HimitsuKoudou : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE HimitsuKoudou(Card::Suit suit, int number);

    virtual void use(Room *room, ServerPlayer *source, QList<ServerPlayer *> &targets) const;
    virtual bool isAvailable(const Player *player) const;
};

class MemberRecruitment : public SingleTargetTrick
{
    Q_OBJECT

public:
    Q_INVOKABLE MemberRecruitment(Card::Suit suit, int number);

    virtual bool isAvailable(const Player *player) const;

    virtual void onUse(Room *room, const CardUseStruct &card_use) const;
    virtual void onEffect(const CardEffectStruct &effect) const;
};

#endif // SPECIALCARDS

