import { describe, expect, test } from "bun:test";
import { isNavigationLinkActive, normalizeNavigationPath } from "../src/utils/navigation";

describe("navigation active state", () => {
  test("normalizes trailing slashes, query strings, and hashes", () => {
    expect(normalizeNavigationPath("/zh/article/?page=2")).toBe("/zh/article");
    expect(normalizeNavigationPath("/zh/article/#latest")).toBe("/zh/article");
    expect(normalizeNavigationPath("/")).toBe("/");
  });

  test("keeps localized home active only on the exact localized root", () => {
    expect(isNavigationLinkActive("/zh/", "/zh/", "exact")).toBe(true);
    expect(isNavigationLinkActive("/zh/", "/zh/about/", "exact")).toBe(false);
    expect(isNavigationLinkActive("/en/", "/en/article/", "exact")).toBe(false);
  });

  test("keeps section links active for their descendant pages", () => {
    expect(isNavigationLinkActive("/zh/article", "/zh/article/tutorials/2025/example/")).toBe(true);
    expect(isNavigationLinkActive("/zh/tag", "/zh/tag/typst/")).toBe(true);
    expect(isNavigationLinkActive("/zh/archive", "/zh/article/")).toBe(false);
  });
});
