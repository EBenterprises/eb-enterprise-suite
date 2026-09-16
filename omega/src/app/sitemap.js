export default function sitemap() {
  const base = "https://omega.example";

  return [
    { url: `${base}/` },
    { url: `${base}/portal` },
    { url: `${base}/legal/privacy` },
    { url: `${base}/legal/terms` },
    { url: `${base}/legal/copyright` },
  ];
}
