import type { Locale } from "./config";

export type TranslationStatus = "source" | "machine" | "reviewed" | string | undefined | null;

export function translationNoticeForStatus(
  status: TranslationStatus,
  locale: Locale,
): string | null {
  if (status !== "machine") return null;
  return locale === "zh" ? "由 AI 翻译" : "Translated By AI";
}
