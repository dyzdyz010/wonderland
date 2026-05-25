import { describe, expect, test } from "bun:test";
import { translationNoticeForStatus } from "../src/i18n/translation";

describe("translationNoticeForStatus", () => {
  test("labels machine-translated articles in the reader's locale", () => {
    expect(translationNoticeForStatus("machine", "zh")).toBe("由 AI 翻译");
    expect(translationNoticeForStatus("machine", "en")).toBe("Translated By AI");
  });

  test("does not label source or reviewed articles", () => {
    expect(translationNoticeForStatus("source", "zh")).toBeNull();
    expect(translationNoticeForStatus("reviewed", "en")).toBeNull();
  });
});
