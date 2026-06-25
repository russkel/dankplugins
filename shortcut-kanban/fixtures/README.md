# Fixtures (mock)

These are **small mock fixtures** illustrating the Shortcut REST API v3 shapes the
plugin consumes — **no real account data**. Do not commit captured production data
here (it leaks org/member/story info).

To capture real data **locally** for ad-hoc inspection (keep it untracked):

```bash
H=(-H "Shortcut-Token: $SHORTCUT_API_TOKEN")
B=https://api.app.shortcut.com/api/v3
curl -sS --fail "${H[@]}" "$B/member"     | jq . > member.json
curl -sS --fail "${H[@]}" "$B/members"    | jq . > members.json
curl -sS --fail "${H[@]}" "$B/workflows"  | jq . > workflows.json
curl -sS --fail "${H[@]}" "$B/iterations" | jq . > iterations.json
curl -sS --fail "${H[@]}" --get --data-urlencode "query=owner:$(jq -r .mention_name member.json)" "$B/search/stories" | jq . > stories.json
```

Shapes used by the plugin:
- `member` — flat: `{ id, mention_name, name }`
- `members[]` — `{ id, profile: { name, mention_name } }`
- `workflows[].states[]` — `{ id, type (unstarted|started|done|backlog), name }`
- `iterations[]` — `{ id, status (unstarted|started|done) }`
- stories — `{ data: [ { id, name, workflow_state_id, iteration_id, owner_ids, app_url } ] }`
