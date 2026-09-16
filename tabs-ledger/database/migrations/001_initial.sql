INSERT OR IGNORE INTO schema_migrations
  (version, name, applied_at)
VALUES
  (1, 'initial', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));
