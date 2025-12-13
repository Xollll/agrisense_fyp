# Where to See Filtered Data - Complete Answer

## Your Question
> "Where to see the content when user click like 7 days or something?"

## Complete Answer

### 📍 WHERE TO SEE IT

**In the Statistics Page, in the "📈 Activity Timeline" section**

This section is located:
- **After**: Health Trends & Forecast, Filter Buttons, Farm Overview, Risk Ranking
- **Below**: The filter buttons (All Time, 30 Days, 7 Days)
- **Before**: Farm Insights and Action Buttons

---

### 🎯 WHAT THE USER SEES

When a user clicks a filter button:

```
User Clicks "30 Days" Button
           ↓
[Button highlights green]
           ↓
Chart below updates immediately with:

┌──────────────────────────────────────┐
│ 📈 Activity Timeline                 │
├──────────────────────────────────────┤
│                                      │
│ Detection Activity (Last 30 Days)    │  ← Title updates
│                        [30 days]     │  ← Badge shows day count
│                                      │
│ Bar Chart with 30 bars               │  ← Chart updates
│ (instead of 7 bars)                  │
│                                      │
│ ████ ████ ████ ████ ████ ... ████    │
│ ████ ████ ████ ████ ████ ... ████    │
│                                      │
│ 💡 Viewing last 30 days - perfect    │  ← Message updates
│    for monthly health assessment...  │
└──────────────────────────────────────┘
```

---

### ✨ WHAT CHANGES

**Chart Section Updates Immediately:**
1. ✅ **Title** → "Detection Activity (Last 30 Days)"
2. ✅ **Bar Count** → 30 bars instead of 7
3. ✅ **Badge** → Shows "30 days"
4. ✅ **Insight Message** → Context-aware tip
5. ✅ **Button Color** → Selected button turns green

**Everything Else Stays Same:**
- ❌ Farm Health Hero Card
- ❌ Health Trends & Forecast
- ❌ Farm Overview
- ❌ Risk Ranking
- ❌ Farm Insights
- ❌ Action Buttons

---

### 📱 VISUAL PAGE LAYOUT

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃      STATISTICS PAGE                 ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                      ┃
┃ 📱 Hero Card (Farm Health)           ┃
┃ ✓ Shows: Health %, Scans, Issues    ┃
┃ ❌ DOESN'T CHANGE                    ┃
┃                                      ┃
├─ GAP ─────────────────────────────────┤
┃                                      ┃
┃ 📊 Health Trends & Forecast          ┃
┃ ✓ Shows: Month-over-month, Outlook  ┃
┃ ❌ DOESN'T CHANGE                    ┃
┃                                      ┃
├─ GAP ─────────────────────────────────┤
┃                                      ┃
┃ 🎯 FILTER BUTTONS ← USER CLICKS HERE ┃
┃ [All Time] [30 Days] [7 Days ✓]     ┃
┃                                      ┃
├─ GAP ─────────────────────────────────┤
┃                                      ┃
┃ 🌾 Farm Overview                     ┃
┃ ✓ Shows: Total Scans, Disease Types  ┃
┃ ❌ DOESN'T CHANGE                    ┃
┃                                      ┃
├─ GAP ─────────────────────────────────┤
┃                                      ┃
┃ ⚠️ Risk Ranking                      ┃
┃ ✓ Shows: Top diseases by frequency  ┃
┃ ❌ DOESN'T CHANGE                    ┃
┃                                      ┃
├─ GAP ─────────────────────────────────┤
┃                                      ┃
┃ ⭐ ACTIVITY TIMELINE ← SEE DATA HERE ┃
┃ ╔════════════════════════════════╗  ┃
┃ ║ Detection Activity (Last 30..) ║  ┃ ← Title changes
┃ ║                 [30 days]       ║  ┃ ← Badge changes
┃ ║ ████ ████ ████ ████ ████ ...   ║  ┃ ← Chart changes
┃ ║ ████ ████ ████ ████ ████ ...   ║  ┃
┃ ║ 💡 Viewing last 30 days...      ║  ┃ ← Message changes
┃ ╚════════════════════════════════╝  ┃
┃ ✅ CHANGES WHEN FILTER SELECTED      ┃
┃                                      ┃
├─ GAP ─────────────────────────────────┤
┃                                      ┃
┃ 💡 Farm Insights                     ┃
┃ ✓ Shows: Smart AI recommendations   ┃
┃ ❌ DOESN'T CHANGE                    ┃
┃                                      ┃
├─ GAP ─────────────────────────────────┤
┃                                      ┃
┃ 📥 Action Buttons                    ┃
┃ ✓ Export, Refresh                    ┃
┃ ❌ DOESN'T CHANGE                    ┃
┃                                      ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

### 🎬 STEP-BY-STEP USER FLOW

#### Step 1: Page Loads (Default: 7 Days Selected)
```
Statistics Page opens
       ↓
"7 Days" button is highlighted green (default)
       ↓
Chart shows: "Detection Activity (Last 7 Days)"
             [7 bars in chart]
             💡 Message about weekly monitoring
```

#### Step 2: User Clicks "30 Days" Button
```
User taps "30 Days" button
       ↓
Button highlights green
"7 Days" loses highlight
       ↓
Chart IMMEDIATELY updates:
  • Title: "Detection Activity (Last 30 Days)"
  • Bars: Now shows 30 bars
  • Badge: Shows "30 days"
  • Message: "perfect for monthly assessment"
```

#### Step 3: User Clicks "All Time" Button
```
User taps "All Time" button
       ↓
Button highlights green
"30 Days" loses highlight
       ↓
Chart IMMEDIATELY updates:
  • Title: "Detection Activity (All Time)"
  • Bars: Shows all available days (e.g., 65 bars)
  • Badge: Shows "65 days"
  • Message: "see complete farm evolution"
```

---

### 💾 CODE LOCATIONS FOR REFERENCE

| What | Where in Code | What It Does |
|------|---------------|--------------|
| Filter Buttons | Line 728-745 | Renders the 3 filter buttons |
| Button Click Handler | Line 771-780 | Handles click, updates selection |
| Selected State | Line 20 | Stores which filter is selected |
| Chart Filtering Logic | Line 1099-1119 | Determines days to show & filters data |
| Chart Display | Line 1096-1171 | Shows filtered chart with title, badge, message |
| Bar Chart Renderer | Line 1200-1264 | Renders individual bars |

---

### ⚡ KEY POINTS TO REMEMBER

✅ **Instant Update**: No loading, no page refresh - updates immediately when button clicked

✅ **Same Location**: User always sees the filtered chart in the same "Activity Timeline" section

✅ **Clear Feedback**: 
   - Button highlights green
   - Title changes
   - Badge shows day count
   - Message explains what they're viewing

✅ **Data-Driven**: Uses real data from `provider.timelineData`

✅ **Isolated Change**: Only the Activity Timeline chart changes, nothing else

---

### 🧪 HOW TO TEST IT

1. Open the app
2. Go to Statistics page
3. Look for the filter buttons in the middle of the page
4. Click "30 Days"
5. **Look down** at the "📈 Activity Timeline" section below
6. You should see:
   - Chart now shows more bars
   - Title says "Last 30 Days"
   - Badge shows "30 days"
7. Click "All Time"
8. Chart expands to show all data
9. Click "7 Days"
10. Chart shrinks back to 7 bars

---

## Summary

**Question**: Where do users see the filtered data?

**Answer**: In the **"📈 Activity Timeline"** section of the Statistics page, which appears **below the filter buttons** and shows a **bar chart** that updates instantly based on the selected time range.

**What updates**:
- Chart title
- Number of bars
- Day count badge
- Contextual message

**What doesn't update**:
- Everything else on the page (stays the same)

**How fast**: Instantly (no delay)

**How obvious**: Very clear - users see button highlight + chart update + title change + message update all together
