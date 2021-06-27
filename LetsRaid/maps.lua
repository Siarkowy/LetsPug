--------------------------------------------------------------------------------
-- Let's Raid (c) 2019 by Siarkowy <http://siarkowy.net/letsraid>
-- Released under the terms of BSD 3-Clause "New" license (see LICENSE file).
--------------------------------------------------------------------------------

LetsRaid.supportedInstanceKeys = "kgmstzhbpnoj"

local locale = GetLocale()

-- /run for i=1,GetNumSavedInstances() do print(GetSavedInstanceInfo(i)) end
local instance_keys = {
    -- ["Reserved"] = "x",

    -- Tier 4
    ["Karazhan"] = "k",
    ["Gruul's Lair"] = "g",
    ["Magtheridon's Lair"] = "m",

    -- Tier 5
    ["Coilfang: Serpentshrine Cavern"] = "s",
    ["Tempest Keep"] = "t",
    ["Zul'Aman"] = "z",

    -- Tier 6
    ["The Battle for Mount Hyjal"] = "h",
    ["Black Temple"] = "b",
    ["The Sunwell"] = "p",

    -- Vanilla
    ["Naxxramas"] = "n",
    ["Onyxia's Lair"] = "o",
    ["Ahn'Qiraj Temple"] = "j",
}

function LetsRaid:GetInstanceKeyForMap(name)
    return instance_keys[name]
end

if locale == "deDE" then instance_keys = {
    ["Onyxias Hort"] = "o",
    ["Karazhan"] = "k",
    ["Naxxramas"] = "n",
    ["Die Schlacht um den Berg Hyjal"] = "h",
    ["Magtheridons Kammer"] = "m",
    ["Echsenkessel: Höhle des Schlangenschreins"] = "s",
    ["Festung der Stürme"] = "t",
    ["Der Schwarze Tempel"] = "b",
    ["Gruuls Unterschlupf"] = "g",
    ["Zul'Aman"] = "z",
    ["Der Sonnenbrunnen"] = "p",
} end

if locale == "esES" then instance_keys = {
    ["Guarida de Onyxia"] = "o",
    ["Karazhan"] = "k",
    ["Naxxramas"] = "n",
    ["La Batalla del Monte Hyjal"] = "h",
    ["Guarida de Magtheridon"] = "m",
    ["Reserva Colmillo Torcido: Caverna Santuario Serpiente"] = "s",
    ["El Castillo de la Tempestad"] = "t",
    ["Templo Oscuro"] = "b",
    ["Guarida de Gruul"] = "g",
    ["Zul'Aman"] = "z",
    ["La Fuente del Sol"] = "p",
} end

if locale == "esMX" then instance_keys = {
    ["Guarida de Onyxia"] = "o",
    ["Karazhan"] = "k",
    ["Naxxramas"] = "n",
    ["La Batalla del Monte Hyjal"] = "h",
    ["Guarida de Magtheridon"] = "m",
    ["Reserva Colmillo Torcido: Caverna Santuario Serpiente"] = "s",
    ["El Castillo de la Tempestad"] = "t",
    ["Templo Oscuro"] = "b",
    ["Guarida de Gruul"] = "g",
    ["Zul'Aman"] = "z",
    ["La Fuente del Sol"] = "p",
} end

if locale == "frFR" then instance_keys = {
    ["Repaire d’Onyxia"] = "o",
    ["Karazhan"] = "k",
    ["Naxxramas"] = "n",
    ["La bataille du mont Hyjal"] = "h",
    ["Le repaire de Magtheridon"] = "m",
    ["Glissecroc : caverne du sanctuaire du Serpent"] = "s",
    ["Donjon de la Tempête"] = "t",
    ["Temple noir"] = "b",
    ["Repaire de Gruul"] = "g",
    ["Zul’Aman"] = "z",
    ["Le Puits de soleil"] = "p",
} end

if locale == "koKR" then instance_keys = {
    ["오닉시아의 둥지"] = "o",
    ["카라잔"] = "k",
    ["낙스라마스"] = "n",
    ["하이잘 산 전투"] = "h",
    ["마그테리돈의 둥지"] = "m",
    ["갈퀴송곳니 저수지: 불뱀 제단"] = "s",
    ["폭풍우 요새"] = "t",
    ["검은 사원"] = "b",
    ["그룰의 둥지"] = "g",
    ["줄아만"] = "z",
    ["태양샘"] = "p",
} end

if locale == "ruRU" then instance_keys = {
    ["Логово Ониксии"] = "o",
    ["Каражан"] = "k",
    ["Наксрамас"] = "n",
    ["Битва за гору Хиджал"] = "h",
    ["Логово Магтеридона"] = "m",
    ["Кривой Клык: Змеиное святилище"] = "s",
    ["Крепость Бурь"] = "t",
    ["Черный храм"] = "b",
    ["Логово Груула"] = "g",
    ["Зул'Аман"] = "z",
    ["Солнечный Колодец"] = "p",
} end

if locale == "zhCN" then instance_keys = {
    ["奥妮克希亚的巢穴"] = "o",
    ["卡拉赞"] = "k",
    ["纳克萨玛斯"] = "n",
    ["海加尔山之战"] = "h",
    ["玛瑟里顿的巢穴"] = "m",
    ["盘牙湖泊：毒蛇神殿"] = "s",
    ["风暴要塞"] = "t",
    ["黑暗神殿"] = "b",
    ["格鲁尔的巢穴"] = "g",
    ["祖阿曼"] = "z",
    ["太阳之井"] = "p",
} end

if locale == "zhTW" then instance_keys = {
    ["奧妮克希亞的巢穴"] = "o",
    ["卡拉贊"] = "k",
    ["納克薩瑪斯"] = "n",
    ["海加爾山之戰"] = "h",
    ["瑪瑟里頓的巢穴"] = "m",
    ["盤牙:毒蛇神殿洞穴"] = "s",
    ["風暴要塞"] = "t",
    ["黑暗神廟"] = "b",
    ["戈魯爾之巢"] = "g",
    ["祖阿曼"] = "z",
    ["太陽之井"] = "p",
} end
