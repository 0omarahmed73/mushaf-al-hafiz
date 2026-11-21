# Contract: Backup file

File name: `mushaf-backup-YYYY-MM-DD.json` (local date of export). UTF-8 JSON.

```json
{
  "app": "mushaf-hafiz",
  "version": 1,
  "exportedAt": "2026-11-20T21:04:00+02:00",
  "wirds": [
    {"id": 1, "name": "الورد اليومي", "type": "reading", "currentPage": 213, "dailyPages": 20,
     "targetDate": null, "khatmaCount": 0, "notifyEnabled": true, "notifyMinutes": 1200,
     "color": 4280391411, "sortOrder": 0, "createdAt": "2026-11-20T10:00:00+02:00"}
  ],
  "wirdDays": [{"wirdId": 1, "day": "2026-11-20", "startPage": 193, "endPage": 212, "done": true}],
  "bookmarks": [{"id": 1, "wirdId": 1, "page": 77, "note": null, "createdAt": "2026-11-20T11:00:00+02:00"}],
  "settings": {"activeWirdId": "1", "lastViewedPage": "213", "kahfEnabled": "true",
               "kahfMinutes": "1260", "todayPanelExpanded": "true"}
}
```

## Rules

- Export includes every row of every user table and every setting.
- Import:
  - `app` ≠ `"mushaf-hafiz"` → `FormatException`, no change.
  - `version` > 1 → `FormatException`, no change.
  - Malformed JSON or a page outside 1–604 → `FormatException`, no change.
  - Otherwise, after the user confirms «سيُستبدل كل ما في التطبيق. متابعة؟», all user tables are
    cleared and refilled in **one transaction**; on any error the transaction rolls back.
- Round trip (export → import) MUST reproduce identical rows and settings (SC-005).
