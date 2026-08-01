# 《山河有契：行旅之契》游戏设计

## High concept

一段由选择写成的山河旅程。玩家携一封未署名的旧契，从芦渡出发，穿过松岭、雨泽与故城，最终抵达天门关。旅途中的每次帮助、取舍与绕行都会改变同行者对玩家的信任、玩家对山河的理解，以及能否走到终点。

## Player promise

完成一次安静但有分量的短程旅途；选择没有明显的“善恶按钮”，结果会从此前积累的关系与资源中自然长出。15–20 分钟是待外部计时验证的设计目标，而不是当前对玩家承诺的时长。相同旅签可重放同一组遭遇，方便比较不同选择。

## Core loop

1. 阅读当前地域与遭遇。
2. 在两个有代价的行动中选择。
3. 阅读选择造成的余响，查看盘缠、信义与见闻的变化。
4. 主动继续前往下一地域，部分选项由此前状态解锁。
5. 在天门关得到“守契”“归乡”“远行”或“失路”结局，并从行旅笺回看因果路径。

## Scope

- Five regions with two deterministic encounter variants per region.
- Two choices per encounter, including state-gated choices.
- Four endings and a concise journey journal that pairs each decision/stat delta
  with its authored aftermath.
- Authored bilingual aftermath for all twenty choices.
- Reproducible route seeds, local autosave, restart, and new-route controls.
- All 32 combinations of the two variants across five regions are seed-reachable.
- A bounded local chronicle of the 128 newest unique completed paths plus a
  compact non-evicting set of discovered endings and all ten encounter variants,
  with exact replay for the five most recent routes. Recalling one during
  unfinished progress requires a second matching confirmation action.
- A bilingual selectable journey summary containing decisions, resource deltas,
  aftermaths, and a deployment-relative link with a validated exact-route
  signature plus the selected language. It starts that route once before resuming ordinary autosave
  behavior, with optional clipboard, local text download, and capability-detected device sharing.
- Persistent text-size, motion, and contrast controls that default to system preferences.
- Installable production play that restores an autosaved journey offline.
- A reduced-data install that keeps core offline play while deferring optional audio.
- Optional landscape ambience with no autoplay, persistent volume/mute, and background pause without auto-resume.
- Authored bilingual callbacks in later regions that echo the prior decision.
- Versioned local backup/restore for the journey, chronicle, and player preferences.
- Selectable text/JSON recovery when the browser cannot start a local export.
- Guarded two-step clearing for every local journey, chronicle, and preference record.
- A clearly disclosed in-memory continuation path when browser storage is denied.
- Honest best-effort storage status plus an explicit browser eviction-protection request.
- Chinese and English interface modes.
- Locale-matched document language, title, and description metadata, plus a
  target-language-marked switch that assistive technology can pronounce.
- Mouse, touch, keyboard, and narrow-screen play.
- No accounts, network dependency, monetization, combat, inventory grid, or backend.

## Rules

- Every resolved encounter advances the route and normally consumes provisions.
- Trust represents promises kept with people; insight represents attention paid to the land and its stories.
- A locked choice stays focusable and states the exact requirement rather than
  hiding it, while every activation path remains inert until it is unlocked.
- Reaching zero provisions before the final pass ends the journey in “lost”.
- High trust and insight produce “covenant”; remaining provisions can produce “homeward”; otherwise the player continues as a “wanderer”.

## Experience principles

- The landscape is the hero; interface chrome stays quiet.
- Choices communicate cost before commitment.
- No random outcome follows a choice. The seed selects encounters only.
- Failure is a complete authored ending, not a dead error screen.
- Motion is slow, orchestrated, and disabled by `prefers-reduced-motion`.

## Acceptance criteria

- A first-time player can begin, finish, restart, and start a new seeded journey.
- The first recent-route action never overwrites an unfinished journey.
- A shared route link supersedes an unrelated save once, then refresh resumes it normally.
- A fresh intro has an exact seed/route address before play and survives reload
  without recreating data that the player cleared.
- Consuming a one-time shared-route address immediately gives that intro save
  ownership, so reload cannot resurrect unrelated progress.
- Opening an English shared route without local data preserves both its language and encounters.
- All four endings are reachable through valid play and real browser journeys.
- Every non-terminal choice pauses on a persisted consequence beat.
- Refreshing restores an unfinished journey; an invalid save fails safely.
- A failed local download never claims success or removes the complete selectable artifact.
- Returning to a browser-cached page rechecks ownership before stale local state can be played.
- Completing complementary routes can reveal all ten authored encounters without exposing unseen titles early.
- An early lost ending reveals only encountered regions, never the unseen suffix of its route.
- Keyboard-triggered story transitions move focus to the new heading; language
  and clipboard actions retain focus on their originating control.
- Every control works with keyboard and touch and has an accessible name.
- Every locked narrative choice remains keyboard-discoverable, announces its
  disabled state and threshold, and cannot change the journey.
- Every visible pointer target measures at least 44 by 44 CSS pixels.
- The first keyboard control skips directly to the focusable story heading.
- Both Chinese and English layouts remain playable by touch at 360×740, and the
  desktop layout remains playable at 1440×900.
- Unit coverage is at least 99% for lines, statements, functions, and branches.
- Every named critical browser journey in `docs/E2E_COVERAGE.md` is automated.
