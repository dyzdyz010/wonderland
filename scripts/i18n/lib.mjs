import { createHash } from "node:crypto";

/** Convert Windows or mixed path separators to POSIX `/` for locale/key parsing. */
export function toPosixPath(value) {
  return value.replaceAll("\\", "/");
}

/** Canonicalize newlines to LF so hashes match the committed Git (LF) sources. */
export function normalizeNewlines(text) {
  return text.replaceAll("\r\n", "\n").replaceAll("\r", "\n");
}

/** SHA-256 of LF-normalized text, prefixed like existing translationSourceHash values. */
export function contentHash(text) {
  return `sha256:${createHash("sha256").update(normalizeNewlines(text), "utf8").digest("hex")}`;
}

/** Parse `zh|en/.../slug.typ` (any separator) into path locale and language-neutral key. */
export function localeAndKeyFromRelativePath(relativeToKind) {
  const posix = toPosixPath(relativeToKind);
  const [pathLocale, ...rest] = posix.split("/");
  const pathKey = rest.join("/").replace(/\.typ$/, "");
  return { pathLocale, pathKey };
}
