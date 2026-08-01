import type { Encounter, EndingId, LocalizedText, StatKey } from "./types";

const text = (zh: string, en: string): LocalizedText => ({ zh, en });

export const REGION_NAMES: readonly LocalizedText[] = [
  text("芦渡", "Reed Ferry"),
  text("松岭", "Pine Ridge"),
  text("雨泽", "Rain Marsh"),
  text("故城", "Old City"),
  text("天门关", "Sky Gate"),
];

export const STAT_KEYS: readonly StatKey[] = ["provisions", "trust", "insight"];

export const STAT_NAMES: Readonly<Record<StatKey, LocalizedText>> = {
  provisions: text("盘缠", "Provisions"),
  trust: text("信义", "Trust"),
  insight: text("见闻", "Insight"),
};

export const ENCOUNTERS: readonly Encounter[] = [
  {
    id: "ferry-rope",
    region: 0,
    place: REGION_NAMES[0]!,
    title: text("断缆", "The Broken Rope"),
    body: text(
      "渡船的缆绳在夜雨里断了。老艄公没有开口，只把磨破的掌心摊在晨光下。",
      "The ferry rope snapped in the night rain. The old boatman says nothing; he only opens a weathered palm to the morning light.",
    ),
    choices: [
      {
        id: "mend-rope",
        label: text("留下来补缆", "Stay and mend the rope"),
        detail: text("慢半日，却有人记得你的名字。", "Lose half a day; gain a name remembered."),
        aftermath: text("新缆绷紧时，艄公第一次叫了你的名字。对岸的晨雾也恰好散开。", "When the new rope draws taut, the boatman speaks your name for the first time. The morning mist opens across the water."),
        effect: { provisions: -1, trust: 2, insight: 1 },
      },
      {
        id: "hire-skiff",
        label: text("雇小舟独渡", "Hire a skiff alone"),
        detail: text("赶上行程，但须多付盘缠。", "Keep your pace at a heavier cost."),
        aftermath: text("小舟很快，身后的断缆却在水声里敲了很久。", "The skiff is fast. Behind you, the broken rope keeps tapping against the landing long after."),
        effect: { provisions: -3, insight: 1 },
      },
    ],
  },
  {
    id: "ferry-letter",
    region: 0,
    place: REGION_NAMES[0]!,
    title: text("无主的信", "The Unclaimed Letter"),
    body: text(
      "水边石缝里压着一封湿信，只写了收信人的小名。对岸已有炊烟。",
      "A damp letter lies beneath a riverside stone, addressed only by a childhood name. Smoke rises across the water.",
    ),
    choices: [
      {
        id: "find-reader",
        label: text("逐户寻找收信人", "Find the letter's owner"),
        detail: text("陌生人的故事会拖慢脚步。", "A stranger's story will slow your steps."),
        aftermath: text("老妇人认出小名，没有拆信，只把它贴在胸口。她替你指向松岭的近路。", "An old woman recognizes the childhood name. She does not open the letter, only holds it to her chest, then points out a path toward Pine Ridge."),
        effect: { provisions: -1, trust: 2, insight: 1 },
      },
      {
        id: "leave-letter",
        label: text("将信留在渡亭", "Leave it at the ferry shelter"),
        detail: text("不问旧事，趁早潮过江。", "Ask no questions and catch the early tide."),
        aftermath: text("潮水把渡亭留在身后。那封信是否被人取走，你再也不会知道。", "The tide leaves the shelter behind. You will never know whether anyone claimed the letter."),
        effect: { provisions: -3, insight: 1 },
      },
    ],
  },
  {
    id: "ridge-fire",
    region: 1,
    place: REGION_NAMES[1]!,
    title: text("余火", "Embers"),
    body: text(
      "樵夫的小屋只剩一圈余火。山风将灰烬吹向更深的林子，也吹来一声孩子的咳嗽。",
      "Only a ring of embers remains of the woodcutter's hut. Mountain wind carries ash into the forest—and a child's cough toward you.",
    ),
    callbacks: [
      {
        afterChoices: ["mend-rope", "find-reader"],
        text: text("渡口有人托上山客捎来一句谢。樵夫听见你的名字，默默把火拨亮了一些。", "Someone at the ferry sent a word of thanks uphill. Hearing your name, the woodcutter quietly stirs the embers brighter."),
      },
      {
        afterChoices: ["hire-skiff", "leave-letter"],
        text: text("你比渡口的故事更早抵达松岭。风穿过空路，身后没有人叫你的名字。", "You reach Pine Ridge before any story from the ferry. Wind crosses the empty road; no one behind you calls your name."),
      },
    ],
    choices: [
      {
        id: "share-shelter",
        label: text("分粮搭起避风棚", "Share food and raise a shelter"),
        detail: text("今晚少一份口粮，多一个同行人。", "One meal fewer; one companion more."),
        aftermath: text("棚顶合拢，孩子的咳声慢慢平了。樵夫把最干的一根松枝留给你的火。", "The roof closes against the wind and the child's cough eases. The woodcutter saves his driest pine branch for your fire."),
        effect: { provisions: -2, trust: 1, insight: 1 },
      },
      {
        id: "take-high-road",
        label: text("趁天亮走高路", "Take the high road by daylight"),
        detail: text("路短且险，需要买一盏山灯。", "A shorter, harsher path requires a mountain lamp."),
        aftermath: text("山灯照出的路只够一人通过。入夜时，岭下那圈余火已经看不见了。", "The lamp reveals a path wide enough for one. By nightfall, the embers below have vanished from view."),
        effect: { provisions: -3, insight: 1 },
      },
    ],
  },
  {
    id: "ridge-bell",
    region: 1,
    place: REGION_NAMES[1]!,
    title: text("雾中铃", "A Bell in the Mist"),
    body: text(
      "雾里传来走失驮队的铜铃。旧路向东，铃声却在无人走的北坡。",
      "A lost caravan bell sounds through the mist. The old road turns east; the bell comes from the trackless northern slope.",
    ),
    callbacks: [
      {
        afterChoices: ["mend-rope", "find-reader"],
        text: text("渡口留下的人情让一名脚夫认出了你。他说，雾里每一声回应都可能救人。", "Kindness left at the ferry makes a porter recognize you. In fog, he says, every answered sound may save someone."),
      },
      {
        afterChoices: ["hire-skiff", "leave-letter"],
        text: text("独行让你早到了半刻，正好独自听见第一声铃。旧路上没有旁人替你作答。", "Traveling alone brings you here early enough to hear the first bell by yourself. No one on the old road can answer for you."),
      },
    ],
    choices: [
      {
        id: "follow-bell",
        label: text("循铃声进雾", "Follow the bell into the mist"),
        detail: text("找人比找路更费力。", "Finding people costs more than finding roads."),
        aftermath: text("你在北坡找到三匹驮马和一个冻僵的少年。铜铃重新响起时，不再像求救。", "On the northern slope you find three pack horses and a freezing boy. When the bell sounds again, it no longer sounds like a plea."),
        effect: { provisions: -2, trust: 1, insight: 1 },
      },
      {
        id: "mark-path",
        label: text("沿旧路留下路标", "Mark the old road and continue"),
        detail: text("帮后来人，也保全自己的行程。", "Help whoever follows without losing your pace."),
        aftermath: text("你把路标刻得很深。雾吞没铃声，却吞不掉树干上朝东的箭头。", "You cut the marker deep. The mist swallows the bell, but not the eastward arrow in the tree."),
        effect: { provisions: -3, insight: 1 },
      },
    ],
  },
  {
    id: "marsh-marker",
    region: 2,
    place: REGION_NAMES[2]!,
    title: text("水下界碑", "The Drowned Marker"),
    body: text(
      "退潮露出半块古界碑。泽民说它记着两村共用水道的旧约，只是再没人读得全。",
      "The falling tide reveals half an old boundary stone. Marsh folk say it records a shared-water covenant no one can read in full.",
    ),
    callbacks: [
      {
        afterChoices: ["share-shelter", "follow-bell"],
        text: text("松岭与你同行的人也挽起袖子。界碑旁很快多出几双愿意下水的脚。", "Those who joined you on Pine Ridge roll up their sleeves. Several pairs of willing feet gather beside the drowned marker."),
      },
      {
        afterChoices: ["take-high-road", "mark-path"],
        text: text("你独自走出松岭的雾，先看见界碑，也先听见两村彼此推诿。", "You leave Pine Ridge's mist alone, first to see the marker and first to hear the two villages pass responsibility between them."),
      },
    ],
    choices: [
      {
        id: "raise-marker",
        label: text("请同行人一起扶正", "Ask your companions to raise it"),
        detail: text("需要信义 2；旧字会显出方向。", "Requires 2 trust; old characters reveal a way."),
        aftermath: text("界碑立起，水线下露出“共渡”二字。两村老人沉默许久，开始重画水道。", "Raised upright, the marker reveals two submerged words: cross together. Elders from both villages begin drawing the waterway anew."),
        effect: { provisions: -2, trust: 1, insight: 2 },
        requirement: { stat: "trust", minimum: 2 },
      },
      {
        id: "force-causeway",
        label: text("买木料强铺便道", "Buy timber and force a causeway"),
        detail: text("最快，却几乎耗尽余粮。", "Fastest, but ruinously expensive."),
        aftermath: text("新木在泥水里一节节下沉。你赶在天黑前通过，身后只剩一条昂贵的直线。", "Fresh timber sinks piece by piece into the mud. You cross before dark, leaving an expensive straight line behind."),
        effect: { provisions: -4 },
      },
    ],
  },
  {
    id: "marsh-cranes",
    region: 2,
    place: REGION_NAMES[2]!,
    title: text("鹤群落处", "Where the Cranes Land"),
    body: text(
      "白鹤落在被淹的旧堤上。泽民相信它们记得安全的浅滩，只缺几个人同去探路。",
      "White cranes settle on a drowned embankment. The marsh folk believe they remember the safe shallows—if enough people will help search.",
    ),
    callbacks: [
      {
        afterChoices: ["share-shelter", "follow-bell"],
        text: text("松岭结下的同行人停在你身旁。鹤群落下时，已经有人替你数好了方向。", "Companions made on Pine Ridge stop beside you. When the cranes settle, someone is already counting their bearings with you."),
      },
      {
        afterChoices: ["take-high-road", "mark-path"],
        text: text("你从松岭独自下来，脚程很快。可要读懂整片浅滩，一双眼睛仍嫌太少。", "You descend Pine Ridge alone and quickly. Yet one pair of eyes is still too few to read an entire reach of shallows."),
      },
    ],
    choices: [
      {
        id: "read-shallows",
        label: text("结伴循鹤影探浅滩", "Follow the cranes together"),
        detail: text("需要信义 2；慢，却看懂水势。", "Requires 2 trust; slower, but teaches the water."),
        aftermath: text("鹤群三次起落，你们也三次改路。最后一个人上岸时，所有人都学会了看水色。", "The cranes rise and settle three times; you change course three times. By the last crossing, everyone has learned to read the color of water."),
        effect: { provisions: -2, trust: 1, insight: 2 },
        requirement: { stat: "trust", minimum: 2 },
      },
      {
        id: "buy-rafts",
        label: text("买下筏子直穿芦荡", "Buy rafts through the reeds"),
        detail: text("省时不省钱。", "Saves time, not provisions."),
        aftermath: text("筏子割开芦荡，也惊散了鹤群。你先到对岸，天空却忽然显得很空。", "The rafts cut through the reeds and scatter the cranes. You reach the far bank first; the sky feels abruptly empty."),
        effect: { provisions: -4 },
      },
    ],
  },
  {
    id: "city-ledger",
    region: 3,
    place: REGION_NAMES[3]!,
    title: text("旧账", "The Old Ledger"),
    body: text(
      "荒废的驿站里有一本完整路簿，夹着沿途百姓托付给守关人的名字。商贩愿出高价。",
      "An intact route ledger rests in the abandoned post house, carrying names entrusted to the gatekeeper. A trader offers a high price.",
    ),
    callbacks: [
      {
        afterChoices: ["raise-marker", "read-shallows"],
        text: text("泽边新认得的同行人替你翻开路簿。湿指印落在名字旁，像一条刚续上的水路。", "A companion from the marsh opens the ledger with you. Damp fingerprints beside the names look like a waterway newly joined."),
      },
      {
        afterChoices: ["force-causeway", "buy-rafts"],
        text: text("芦屑和新木的气味还留在衣上。商贩闻见了，便把价钱又抬高一成。", "The smell of reeds and fresh timber still clings to you. The trader notices and raises the offer once more."),
      },
    ],
    choices: [
      {
        id: "return-ledger",
        label: text("把路簿送回关口", "Carry the ledger to the pass"),
        detail: text("再背一件东西，也再守一份托付。", "Carry one more weight—and one more promise."),
        aftermath: text("你用布包好路簿。纸页不重，那些名字却让肩上的行囊沉了下去。", "You wrap the ledger in cloth. The pages weigh little; the names make the pack settle heavily on your shoulders."),
        effect: { provisions: -1, trust: 2, insight: 1 },
      },
      {
        id: "sell-ledger",
        label: text("卖给商贩换补给", "Sell it for supplies"),
        detail: text("盘缠有余，名字从此失散。", "Your pack grows full; the names disappear."),
        aftermath: text("商贩当场拆下旧纸。你的行囊鼓起来，风里却飘走了几片无人再认得的名字。", "The trader tears out the old paper at once. Your pack fills; scraps of names no one will recognize lift into the wind."),
        effect: { provisions: 2, trust: -1 },
      },
    ],
  },
  {
    id: "city-well",
    region: 3,
    place: REGION_NAMES[3]!,
    title: text("城心古井", "The Well at the City's Heart"),
    body: text(
      "古井被碎石压住，井栏刻着向山上传信的旧法。赶集的人只当它是块好石料。",
      "Rubble covers the old well. Its rim bears an old method for sending word uphill; market crews see only useful stone.",
    ),
    callbacks: [
      {
        afterChoices: ["raise-marker", "read-shallows"],
        text: text("泽民教你的水纹与井栏刻痕彼此相合。同行人喊来市集众人，一起辨认旧图。", "The water signs learned in the marsh align with the well's carvings. Your companions call the market crowd over to read the old diagram."),
      },
      {
        afterChoices: ["force-causeway", "buy-rafts"],
        text: text("一路买来的木与筏已经耗去不少盘缠。石匠看着你的行囊，知道你会听懂交易。", "Timber and rafts have already thinned your provisions. The mason eyes your pack and knows you understand a bargain."),
      },
    ],
    choices: [
      {
        id: "clear-well",
        label: text("同众人清出井栏", "Clear the well with the townsfolk"),
        detail: text("费一餐工夫，换回失传的办法。", "Spend a meal's labor to recover a lost method."),
        aftermath: text("最后一块碎石移开，井栏的刻痕连成一幅传讯图。有人已经跑去敲第一面鼓。", "When the last stone moves, the carvings become a signaling map. Someone is already running to strike the first drum."),
        effect: { provisions: -1, trust: 2, insight: 1 },
      },
      {
        id: "trade-stone",
        label: text("帮忙运石换补给", "Haul the stone for provisions"),
        detail: text("今日吃饱，旧刻就此散去。", "Eat well today; lose the inscription forever."),
        aftermath: text("石料换成热食，确实暖胃。井栏被劈开垫路时，那些细刻再也拼不回去了。", "The stone buys a hot meal, and it does warm you. Split for paving, the well's fine markings can never be joined again."),
        effect: { provisions: 2, trust: -1 },
      },
    ],
  },
  {
    id: "gate-names",
    region: 4,
    place: REGION_NAMES[4]!,
    title: text("关门将闭", "Before the Gate Closes"),
    body: text(
      "暮鼓已响。守关人问你：这一路带来的，究竟是一纸旧契，还是愿意彼此记得的人？",
      "The evening drum sounds. The gatekeeper asks: did you bring an old covenant, or people willing to remember one another?",
    ),
    callbacks: [
      {
        afterChoices: ["return-ledger", "clear-well"],
        text: text("你尚未开口，守关人已看见怀中的路簿，或听见故城新响的鼓。一路托付先替你答了一半。", "Before you speak, the gatekeeper sees the ledger at your chest—or hears Old City's restored drum. The promises you carried answer half the question."),
      },
      {
        afterChoices: ["sell-ledger", "trade-stone"],
        text: text("行囊比离城时更满，能作证的纸页与刻痕却没有一件来到关前。", "Your pack is fuller than when you left the city, but no page or carving has reached the gate to testify beside you."),
      },
    ],
    choices: [
      {
        id: "speak-names",
        label: text("讲出一路所记的名字", "Speak the names you carried"),
        detail: text("需要见闻 3；让旧契重新有了人。", "Requires 3 insight; give the old covenant people again."),
        aftermath: text("每说出一个名字，守关人便在旧契旁添一笔。暮鼓停了，关门仍为众人开着。", "With every name, the gatekeeper adds a mark beside the covenant. The evening drum ends; the gate remains open for everyone."),
        effect: { provisions: -1, trust: 1, insight: 1 },
        requirement: { stat: "insight", minimum: 3 },
      },
      {
        id: "show-paper",
        label: text("只呈上那纸旧契", "Present only the old document"),
        detail: text("完成托付，不多说一句。", "Complete the delivery without another word."),
        aftermath: text("守关人验过纸印，把旧契锁进木匣。关门准时合上，没有人问你一路见过谁。", "The gatekeeper verifies the seal and locks the covenant in a wooden box. The gate closes on time. No one asks whom you met."),
        effect: { provisions: -1 },
      },
    ],
  },
  {
    id: "gate-storm",
    region: 4,
    place: REGION_NAMES[4]!,
    title: text("最后一场山雨", "The Last Mountain Rain"),
    body: text(
      "关前山雨切断了石阶。身后的人问，要不要把一路学来的渡水办法再用一次。",
      "Mountain rain cuts the final stair. Those behind you ask whether the lessons of every crossing can serve once more.",
    ),
    callbacks: [
      {
        afterChoices: ["return-ledger", "clear-well"],
        text: text("故城保存下来的名字或讯号已经传到队尾。雨中有人依次回应，谁也不再只是陌生人。", "The names or signals preserved in Old City have reached the end of the line. Voices answer through the rain; no one is merely a stranger now."),
      },
      {
        afterChoices: ["sell-ledger", "trade-stone"],
        text: text("补给能让你多等一夜，却换不来熟悉这条旧水路的人。雨声里无人认得无人。", "Your supplies can buy another night, but not someone who knows the old waterway. In the rain, no one recognizes anyone."),
      },
    ],
    choices: [
      {
        id: "guide-crossing",
        label: text("带众人寻找旧水路", "Guide everyone by the old waterway"),
        detail: text("需要见闻 3；最后一次共同渡水。", "Requires 3 insight; one final crossing together."),
        aftermath: text("你辨出水色，同行人依次踏过暗石。雨未停，关前却第一次没有人被落在后面。", "You read the water and the others cross by hidden stones. The rain does not stop, but for once no one is left behind."),
        effect: { provisions: -1, trust: 1, insight: 1 },
        requirement: { stat: "insight", minimum: 3 },
      },
      {
        id: "wait-storm",
        label: text("独自等雨停", "Wait out the rain alone"),
        detail: text("稳妥抵达，也不再欠谁。", "Arrive safely, owing no one."),
        aftermath: text("雨停时石阶已经空了。你独自走到关门前，鞋袜干净，身后也没有脚步声。", "When the rain stops, the stair is empty. You reach the gate alone, your clothes dry and no footsteps behind you."),
        effect: { provisions: -1 },
      },
    ],
  },
];

export const ENDINGS: Readonly<Record<EndingId, { title: LocalizedText; body: LocalizedText }>> = {
  covenant: {
    title: text("守契 · 山河有应", "Covenant · The Land Answers"),
    body: text(
      "旧契没有重新封存。它被誊成许多份，交到渡口、山村与泽民手里。你带来的不是答案，而是一条让人彼此找到的路。",
      "The covenant is not sealed away again. Copies travel to ferries, villages, and marsh homes. You brought no final answer—only a road by which people can find one another.",
    ),
  },
  homeward: {
    title: text("归乡 · 灯火可亲", "Homeward · Familiar Lights"),
    body: text(
      "你完成托付，也留下足够盘缠踏上归路。山河没有挽留，只在每个借宿的窗口为你多亮了一盏灯。",
      "You complete the charge and keep enough provisions for home. The land does not ask you to stay; it simply leaves one more lamp lit in every window that sheltered you.",
    ),
  },
  wanderer: {
    title: text("远行 · 路仍在前", "Wanderer · The Road Continues"),
    body: text(
      "关门在身后合拢。你没有成为传说，也没有回头。旧契的空白处还很长，足够写下下一条河与下一座山。",
      "The gate closes behind you. You become no legend, and you do not turn back. The covenant still has room for another river and another mountain.",
    ),
  },
  lost: {
    title: text("失路 · 芦火未熄", "Lost · A Reed Fire Remains"),
    body: text(
      "盘缠用尽，旅程停在半途。有人在泽边为你点起一束芦火。失路并非失约；记住旅签，再来一次。",
      "Your provisions run out before the pass. Someone lights a reed fire at the water's edge. A lost road is not a broken promise—remember the seed and try again.",
    ),
  },
};

export const encounterById = (id: string): Encounter => {
  const encounter = ENCOUNTERS.find((candidate) => candidate.id === id);
  if (!encounter) {
    throw new Error(`Unknown encounter: ${id}`);
  }
  return encounter;
};
