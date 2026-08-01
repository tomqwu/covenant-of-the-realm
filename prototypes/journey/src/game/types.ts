export type Locale = "zh" | "en";

export interface LocalizedText {
  readonly zh: string;
  readonly en: string;
}

export interface Stats {
  readonly provisions: number;
  readonly trust: number;
  readonly insight: number;
}

export type StatKey = keyof Stats;

export interface Requirement {
  readonly stat: StatKey;
  readonly minimum: number;
}

export interface Choice {
  readonly id: string;
  readonly label: LocalizedText;
  readonly detail: LocalizedText;
  readonly aftermath: LocalizedText;
  readonly effect: Partial<Stats>;
  readonly requirement?: Requirement;
}

export interface NarrativeCallback {
  readonly afterChoices: readonly string[];
  readonly text: LocalizedText;
}

export interface Encounter {
  readonly id: string;
  readonly region: number;
  readonly place: LocalizedText;
  readonly title: LocalizedText;
  readonly body: LocalizedText;
  readonly callbacks?: readonly NarrativeCallback[];
  readonly choices: readonly [Choice, Choice];
}

export type EndingId = "covenant" | "homeward" | "wanderer" | "lost";
export type GamePhase = "intro" | "playing" | "reflection" | "ended";

export interface JournalEntry {
  readonly encounterId: string;
  readonly choiceId?: string;
  readonly place: LocalizedText;
  readonly choice: LocalizedText;
  readonly aftermath: LocalizedText;
  readonly effect: Partial<Stats>;
}

export interface GameState {
  readonly version: 1;
  readonly seed: number;
  readonly locale: Locale;
  readonly phase: GamePhase;
  readonly route: readonly string[];
  readonly sceneIndex: number;
  readonly stats: Stats;
  readonly journal: readonly JournalEntry[];
  readonly ending?: EndingId;
}
