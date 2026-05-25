import type { Locale } from "./config";

export const DEFAULT_TRANSLATION_STATUS = "source" as const;

export type TranslationStatusValue = "source" | "machine" | "reviewed";
export type TranslationStatus = TranslationStatusValue | string | undefined | null;

export function normalizeTranslationStatus(status: TranslationStatus): TranslationStatusValue | string {
  return status ?? DEFAULT_TRANSLATION_STATUS;
}

export function translationNoticeForStatus(
  status: TranslationStatus,
  locale: Locale,
): string | null {
  if (normalizeTranslationStatus(status) !== "machine") return null;
  return locale === "zh" ? "由 AI 翻译" : "Translated By AI";
}
