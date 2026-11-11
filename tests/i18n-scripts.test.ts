import { describe, expect, test } from "bun:test";
import {
  contentHash,
  localeAndKeyFromRelativePath,
  normalizeNewlines,
  toPosixPath,
} from "../scripts/i18n/lib.mjs";

describe("localeAndKeyFromRelativePath", () => {
  test("normalizes Windows separators so locale and i18nKey can be parsed", () => {
    expect(toPosixPath("en\\life\\2017\\foo.typ")).toBe("en/life/2017/foo.typ");
    expect(localeAndKeyFromRelativePath("en\\calix\\2026\\calix-initial.typ")).toEqual({
      pathLocale: "en",
      pathKey: "calix/2026/calix-initial",
    });
  });

  test("leaves POSIX paths unchanged", () => {
    expect(localeAndKeyFromRelativePath("zh/meta/2026/blog-update.typ")).toEqual({
      pathLocale: "zh",
      pathKey: "meta/2026/blog-update",
    });
  });
});

describe("contentHash", () => {
  const lf = "#show: main.with(\n  title: \"Example\",\n)\n";
  const crlf = "#show: main.with(\r\n  title: \"Example\",\r\n)\r\n";
  const mixed = "#show: main.with(\r\n  title: \"Example\",\r)\n";
  const expected = "sha256:bcc070f968804ac07492462f850e8a2691c281619498d0f5fee48dd93c689b06";

  test("hashes LF-normalized text so Windows checkouts match committed hashes", () => {
    expect(normalizeNewlines(crlf)).toBe(lf);
    expect(contentHash(lf)).toBe(expected);
    expect(contentHash(crlf)).toBe(expected);
    expect(contentHash(mixed)).toBe(expected);
  });
});
