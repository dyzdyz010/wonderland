import { describe, expect, test } from "bun:test";
import {
  DEFAULT_TRANSLATION_STATUS,
  normalizeTranslationStatus,
  translationNoticeForStatus,
} from "../src/i18n/translation";

describe("translationNoticeForStatus", () => {
  test("labels machine-translated articles in the reader's locale", () => {
    expect(translationNoticeForStatus("machine", "zh")).toBe("由 AI 翻译");
    expect(translationNoticeForStatus("machine", "en")).toBe("Translated By AI");
  });

  test("does not label source or reviewed articles", () => {
    expect(translationNoticeForStatus("source", "zh")).toBeNull();
    expect(translationNoticeForStatus("reviewed", "en")).toBeNull();
  });

  test("defaults missing translation status to source", () => {
    expect(DEFAULT_TRANSLATION_STATUS).toBe("source");
    expect(normalizeTranslationStatus(undefined)).toBe("source");
    expect(normalizeTranslationStatus(null)).toBe("source");
    expect(normalizeTranslationStatus("machine")).toBe("machine");
    expect(normalizeTranslationStatus("reviewed")).toBe("reviewed");
  });
});
