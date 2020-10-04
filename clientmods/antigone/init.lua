antigone={}

local antm = false

local chance = 10

local lastutter=0

local qmsg = "Go then if you must, but remember, no matter how foolish your deeds, those who love you will love you still."

local prlv = "Goodbye to the sun that shines for me no longer!"

local smsg = "Unnatural silence signifies no good."

local qdb = {
    "All men make mistakes, but a good man yields when he knows his course is wrong, and repairs the evil. The only crime is pride.",
    "A man, though wise, should never be ashamed of learning more, and must unbend his mind.",
    "I was born to join in love, not hate - that is my nature.",
    "Grief teaches the steadiest minds to waver.",
    "We have only a little time to please the living. But all eternity to love the dead.",
    "When I have tried and failed, I shall have failed.",
    "Leave me to my own absurdity.",
    "No one loves the messenger who brings bad news.",
    "A state which belongs to just one man is no true state.",
    "It is not right if I am wrong. But if I am young, and right, what does my age matter?",
    "There is no greater evil than men's failure to consult and to consider.",
    "Nobody has a more sacred obligation to obey the law than those who make the law.",
    "Do not fear for me. Make straight your own path to destiny.",
    "Do not believe that you alone can be right. The man who thinks that,The man who maintains that only he has the power. To reason correctly, the gift to speak, the soul. A man like that, when you know him, turns out empty.",
    "I have no love for a friend who loves in words alone.",
    "There is no happiness where there is no wisdom",
    "Numberless are the world's wonders, but none more wonderful than man.",
    "Oh it's terrible when the one who does the judging judges things all wrong.",
    "I have nothing but contempt for the kind of governor who is afraid, for whatever reason, to follow the course that he knows is best for the State.",
    "Reason is God's crowning gift to a man.",
    "Tell me the news, again, whatever it is… sorrow and I are hardly strangers. I can bear the worst.",
    "What do I care for life when you are dead?",
    "It is the dead, not the living, who make the longest demands.",
    "A friend in word is never friend of mine.",
    "There let her pray to the one god she worships: Death--who knows?--may just reprieve her from death. Or she may learn a last, better late than never, what a waste of breath it is to worship Death.",
    "No yield to the dead! Never stab the fighter when he's down. Where's the glory, killing the dead twice over?",
    "I know not, but strained silence, so I deem, is no less ominous than excessive grief.",
    "What a splendid king you'd make of a desert island - you and you alone.",
"I don't even exist—I'm no one. Nothing.",
"No man, my lord, should make a vow, for if he ever swears he will not do a thing.",
"When misfortune comes, The wisest even lose their mother wit",
"I didn't say yes. I can say no to anything I say vile, and I don't have to count the cost. But because you said yes, all that you can do, for all your crown and your trappings, and your guards—all that your can do is to have me killed.",
"One must wait until evening to see how splendid the day has been.",
"Every way leads but astray.",
"Know'st not whate'er we do is done in love?",
"Love resistless in fight, all yield at a glance of thine eye, Love who pillowed all night on a maiden's cheek dost lie, Over the upland holds. Shall mortals not yield to thee",
"True, as unwisdom is the worst of ills",
"Good advice, if there's any good in suffering. Quickest is best when trouble blocks the way.",
"Chastisement for errors past – Wisdom brings to age at last.",
"But if I am young, thou shouldest look to my merits, not to my years.",
"Alas! How sad when reasoners reason wrong",
"To guild refined gold, to paint the lily, to throw perfume on the violet is just fuckin' silly.",
"Each lie we tell incurs a debt to the truth. Sooner or later the debt is paid. That is how an RBMK rector core explodes – lies!",
"I know who I am, and I know whatI've done. In a just world, I would be shot for my lies. But not for this. Not for the truth.",
"This death of mine Is of no importance; but if I had left my brother. Lying in death unburied, I should have suffered. Now I do not.",
"Your edict, King, was strong! But all your strength is weakness itself against the immortal unrecorded laws of the Gods.",
"'Why worry about something thatisn't going to happen.' That'sperfect. They should put that on our money",
"This talking is a great weariness: your words are distasteful to me, and I am sure that mine seem so to you. And yet they should not seem so: I should have praise and honor for what I have done. All these men here would praise me were their lips not frozen shut with fear of you.",
"The dead man and the gods who rule the dead know whose act this was. Words are not friends.",
"You shall not lessen my death by sharing it.",
"Out there in the wilderness, and lock her living in a vault of stone. She shall have food, As the custom is, to absolve the State of her death. And there let her pray to the gods of hell. They are her only gods: Perhaps they will show her an escape from death, or she may learn, though late, that piety shown the dead is pity in vain."
}


function cchat.getquote()
    if not antm then return end
    chance = chance - 1
    if math.random(chance) > 1 then return end
    chance=10
    if os.time() < lastutter + 15 then return end
    lastutter=os.time()
    local keyset = {}
    local qt = 1
    for k in pairs(qdb) do
        table.insert(keyset, k)
    end
-- now you can reliably return a random key
    qt = qdb[keyset[math.random(#keyset)]]
    minetest.send_chat_message(qt)
end

minetest.register_chatcommand('aqt',{
params='',
description='get a random antigone quote',
func=function(param)
    cchat.getquote()
end
})

table.insert(minetest.registered_on_receiving_chat_message, 1, function(msg)
    if not antm and minetest.localplayer:get_name() == "antigone" then
        antm=true
        minetest.display_chat_message("-----antig detected. quote funcs activated.")
    end
    if not antm then return end
        local s = msg:find('^<Berastone>')
        local t = msg:find('^<oneplustwo>')
        local t = msg:find('^<oneminustwo>')
        local u = msg:find('^<mobilec>')
        local v = msg:find('^<creon>')
        local v = msg:find('^Herpera')
        local v = msg:find('^Kant')
        local v = msg:find('^Demotivator')
        local v = msg:find('^dupp')
        local zz = msg:find("^<cora>")
        local zzz = msg:find("antigone ")
        local zzzz = msg:find(" antigone")
        local zzzzz = msg:find("antigone:")
        local cc = msg:find("From cora: say")
        if cc then chance = 1 end
        if s or t or u or v or zz or zzz or zzzz or zzzzz or cc then
            cchat.getquote()
            --minetest.display_chat_message(msg)
        end
end)
