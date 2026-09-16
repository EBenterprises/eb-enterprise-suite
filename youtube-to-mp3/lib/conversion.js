export const AUDIO_QUALITIES = [
  { value: "128", label: "128 kbps" },
  { value: "192", label: "192 kbps" },
  { value: "256", label: "256 kbps" },
  { value: "320", label: "320 kbps" }
];

export function createJob(url, quality) {
  return {
    id: crypto.randomUUID(),
    url,
    quality,
    status: "queued",
    progress: 0,
    createdAt: new Date().toISOString()
  };
}
