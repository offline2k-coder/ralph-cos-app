# Ralph-CoS GitHub Sync Guide

## Bidirectional Sync Overview

The app now supports **bidirectional sync** with your GitHub repository (my-notion-backup):

### **READ (Download from GitHub)**
- Pulls Notion backup markdown files and CSVs
- Updates local task database
- Runs automatically:
  - On app start (if credentials exist)
  - Every night at 03:00 CET via Workmanager
  - Manually via Settings → "SYNC NOW"

### **WRITE (Upload to GitHub)**
- Pushes tracking data back to GitHub
- Creates/updates files using GitHub API
- Runs automatically after each tracked event
- File: `ralph_logs/daily_kpis.json`

## How Write Sync Works

### GitHub API Method
Since git isn't available on Android, we use GitHub's REST API:

1. **GET** file to retrieve current SHA (required for updates)
2. **PUT** file with new content (base64 encoded)
3. Automatic commit with message
4. Updates happen in real-time

### What Gets Synced to GitHub

**File: `ralph_logs/daily_kpis.json`**

Tracks all your activity:
```json
[
  {
    "date": "2026-01-17",
    "timestamp": "2026-01-17T08:30:00.000Z",
    "event": "check_in",
    "data": {
      "current_streak": 42,
      "passes_available": 2,
      "total_days": 100,
      "longest_streak": 45
    }
  },
  {
    "date": "2026-01-17",
    "timestamp": "2026-01-17T20:15:00.000Z",
    "event": "evening_reflection",
    "data": {
      "kept_vow": true,
      "inbox_zero": true,
      "task_zero": true,
      "guilt_zero": false,
      "zeros_achieved": 2
    }
  },
  {
    "date": "2026-01-17",
    "timestamp": "2026-01-17T21:00:00.000Z",
    "event": "challenge_completion",
    "data": {
      "day": 15,
      "challenge_streak": 15
    }
  }
]
```

### Tracked Events

| Event | Triggers When | Data Tracked |
|-------|--------------|--------------|
| `check_in` | Daily check-in (05:00-09:00) | Streak, passes, total days, longest streak |
| `challenge_completion` | 30-day challenge day completed | Day number, challenge streak |
| `evening_reflection` | Evening ritual submitted | Vow kept, zeros achieved (inbox/task/guilt) |
| `streak_break` | Missed check-in without pass | Previous streak count |
| `pass_earned` | Reach 20-day milestone | Total passes available |

## Setup Requirements

### GitHub Personal Access Token (PAT)
Your token needs these permissions:
- ✅ `repo` (full repository access)
  - Includes: `repo:status`, `repo_deployment`, `public_repo`

### Verify in Settings
1. Open Settings
2. Check GitHub credentials are saved
3. Test with "SYNC NOW"
4. Check logs for success messages

## Viewing Your Data on GitHub

1. Go to: `https://github.com/offline2k-coder/my-notion-backup`
2. Navigate to: `ralph_logs/daily_kpis.json`
3. See all your tracked activity
4. View commit history to see updates
5. Download/analyze as needed

## Benefits of Bidirectional Sync

### ✅ Complete Backup
- All tracking data stored in GitHub
- Survives app reinstalls
- Can restore from GitHub

### ✅ Multi-Device Access
- View your stats from any device
- Build custom dashboards
- Export for analysis

### ✅ Version History
- GitHub tracks all changes
- See your progress over time
- Revert if needed

### ✅ Data Ownership
- You own the repository
- No third-party servers
- Full control over data

## Sync Timing

### Automatic Writes (Immediate)
Every tracked event instantly pushes to GitHub:
- Check-in → ~1-2 seconds
- Evening reflection → ~1-2 seconds
- Challenge completion → ~1-2 seconds

### Automatic Reads (Scheduled)
- **App start**: If credentials exist
- **03:00 CET daily**: Background sync
- **Manual**: Settings → "SYNC NOW"

## Troubleshooting

### Write Sync Fails
**Check:**
1. GitHub token is valid (Settings)
2. Token has `repo` permission
3. Internet connection active
4. Repository name is correct: `offline2k-coder/my-notion-backup`

**Logs:**
```
✅ Success: "Successfully synced KPIs to GitHub"
❌ Failure: "Failed to sync KPIs to GitHub"
```

### Read Sync Fails
**Check:**
1. Repository exists and is accessible
2. Token can read the repo
3. Branch is `main` (not `master`)

### File Doesn't Appear on GitHub
**Possible causes:**
1. First event not tracked yet (file created on first KPI)
2. Sync failed (check logs)
3. Wrong branch selected
4. Repository path incorrect

## Privacy & Security

### What's Safe
- ✅ Token stored in Flutter Secure Storage (encrypted)
- ✅ Token never logged or exposed
- ✅ HTTPS for all API calls
- ✅ No third-party services

### What to Know
- Your GitHub repo is private (keep it that way!)
- Don't share your PAT
- Regular token rotation recommended
- Review repo access periodically

## Advanced: Custom Analysis

### Export KPIs
```bash
# Clone your repo
git clone https://github.com/offline2k-coder/my-notion-backup.git

# View KPIs
cat ralph_logs/daily_kpis.json | jq .

# Count check-ins
cat ralph_logs/daily_kpis.json | jq '[.[] | select(.event=="check_in")] | length'

# Weekly zeros achieved
cat ralph_logs/daily_kpis.json | jq '[.[] | select(.event=="evening_reflection") | .data.zeros_achieved] | add'
```

### Build Dashboards
Import `daily_kpis.json` into:
- Google Sheets (for charts)
- Notion (for viewing)
- Excel (for pivot tables)
- Custom web app (for live dashboard)

## Future Enhancements

Possible additions:
- [ ] Sync evening reflections as markdown files
- [ ] Sync challenge completions to separate folder
- [ ] Weekly summary report generation
- [ ] Streak history visualization file
- [ ] Export to CSV option
- [ ] Multiple repo support
- [ ] Automatic daily commit summary

## Support

If sync issues persist:
1. Check GitHub API status: https://www.githubstatus.com/
2. Verify token permissions in GitHub settings
3. Review app logs for error messages
4. Test with manual "SYNC NOW" first

---

**Remember:** Every action you track in Ralph-CoS is now permanently stored in your GitHub repository. Your discipline journey is fully backed up and analyzable! 📊
