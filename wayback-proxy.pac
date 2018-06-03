function FindProxyForURL (url, host) {
  if (shExpMatch(host, "archive-it.org")) { return "DIRECT"; }
  if (shExpMatch(host, "www.archive-it.org")) { return "DIRECT"; }
  if (shExpMatch(host, "piwik.archive.org")) { return "DIRECT"; }
  if (shExpMatch(host, "partner.archive-it.org")) { return "DIRECT"; }
  if (url.substring(0, 6) == "https:") { return "PROXY wayback.archive-it.org:8081"; }

  return "PROXY wayback.archive-it.org:8081";
}
