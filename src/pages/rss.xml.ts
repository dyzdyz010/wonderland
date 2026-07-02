import { DEFAULT_LOCALE, withLocale } from "../i18n/config";

export const prerender = false;

export function GET() {
  return new Response(null, {
    status: 301,
    headers: {
      Location: withLocale(DEFAULT_LOCALE, "/rss.xml"),
    },
  });
}
