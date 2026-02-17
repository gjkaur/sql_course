-- Module 6: Event Logging System
-- JSONB for flexible event payloads

-- ============================================
-- Schema
-- ============================================

CREATE TABLE IF NOT EXISTS events (
  id BIGSERIAL PRIMARY KEY,
  event_type VARCHAR(100) NOT NULL,
  user_id BIGINT,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- GIN index for payload queries
CREATE INDEX IF NOT EXISTS idx_events_payload ON events USING GIN (payload);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at);

-- ============================================
-- Seed data
-- ============================================

INSERT INTO events (event_type, user_id, payload) VALUES
  ('page_view', 1, '{"page": "/home", "referrer": "google.com"}'),
  ('click', 1, '{"element": "buy_button", "product_id": 5}'),
  ('purchase', 1, '{"order_id": 101, "total": 149.99, "items": [1, 2, 3]}'),
  ('page_view', 2, '{"page": "/products", "search": "laptop"}'),
  ('error', NULL, '{"message": "Connection timeout", "code": 504}');

-- ============================================
-- Query examples
-- ============================================

-- Events with product_id in payload
SELECT * FROM events WHERE payload ? 'product_id';

-- Events where payload contains order_id
SELECT * FROM events WHERE payload @> '{"order_id": 101}';

-- Extract page from page_view events
SELECT id, payload->>'page' AS page, created_at
FROM events
WHERE event_type = 'page_view';

-- Events in last hour
SELECT * FROM events
WHERE created_at > NOW() - INTERVAL '1 hour';
