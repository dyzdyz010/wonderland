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

export type ArticleNoticeBadge = {
  label: string;
  icon: string;
};

export type ArticleNoticeInput = {
  translationStatus?: TranslationStatus;
  aiAuthored?: boolean | null;
};

export function articleNoticeBadges(
  input: ArticleNoticeInput,
  locale: Locale,
): ArticleNoticeBadge[] {
  const notices: ArticleNoticeBadge[] = [];
  const translationNotice = translationNoticeForStatus(input.translationStatus, locale);
  if (translationNotice) {
    notices.push({ label: translationNotice, icon: "mdi:translate" });
  }
  if (input.aiAuthored === true) {
    notices.push({
      label: locale === "zh" ? "由 AI 撰写" : "Written By AI",
      icon: "mdi:robot-outline",
    });
  }
  return notices;
}
