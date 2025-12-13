# Where Users See Time Range Filter Results

## Visual Layout on Statistics Page

```
┌─────────────────────────────────────────────────────────────┐
│                    STATISTICS PAGE                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📱 HERO CARD (Farm Health Summary)                         │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ 🌱 Thriving    [Circular Progress: 92% Health]       │  │
│  │ ✅ 156 Scans   🌾 3 Issues Found   📊 92% Healthy   │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  📊 HEALTH TRENDS & FORECAST                               │
│  ┌─────────────────────┐ ┌────────────────────────┐       │
│  │ 📈 Month-over-Month │ │ 14-Day Forecast: ✅   │       │
│  │    +5.2%            │ │    Disease Stable      │       │
│  └─────────────────────┘ └────────────────────────┘       │
│  Forecast: "Disease trending downward - working well!"    │
│                                                             │
│  🎯 TIME RANGE FILTER ← USER CLICKS HERE                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │All Time  │  │30 Days   │  │7 Days  ✓ │  (selected)   │
│  └──────────┘  └──────────┘  └──────────┘                 │
│                                                             │
│  ═════════════════════════════════════════════════════════ │
│  AFTER USER CLICKS - SEE BELOW ⬇️                          │
│  ═════════════════════════════════════════════════════════ │
│                                                             │
│  📈 ACTIVITY TIMELINE ← FILTERED DATA SHOWN HERE            │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Detection Activity (Last 7 Days)        [7 days]    │  │
│  │                                                     │  │
│  │        ███                                          │  │
│  │        ███                                          │  │
│  │   █████ ███ ███                                     │  │
│  │ ██████████████                                      │  │
│  │ ███████████████                                     │  │
│  │ ──────────────────────                              │  │
│  │  Mon Tue Wed Thu Fri Sat Sun                        │  │
│  │   2   1   3   2   5   1   2   (detection counts)   │  │
│  │                                                     │  │
│  │ 💡 Viewing last 7 days - great for weekly          │  │
│  │    monitoring and trend spotting                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  🌾 FARM OVERVIEW (Static - always shows totals)           │
│  📊 RISK RANKING (Static - shows all diseases)             │
│  💡 FARM INSIGHTS (Static - general insights)              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## What Happens When User Clicks a Filter Button

### Step 1: User Clicks "30 Days"
```
Location on Screen: Middle of page, after "Health Trends & Forecast"

User Action:
  ┌──────────┐
  │30 Days   │ ← Click here
  └──────────┘
```

### Step 2: Chart Updates Immediately
```
Location on Screen: Below the filter buttons (in "Activity Timeline" section)

Visual Changes:
  BEFORE:                          AFTER (User clicked "30 Days"):
  ┌─────────────────────────┐      ┌──────────────────────────────┐
  │Detection Activity       │      │Detection Activity            │
  │(Last 7 Days) [7 days]   │      │(Last 30 Days)    [30 days]  │
  │                         │      │                              │
  │  ███                    │      │  ███ ██ ███ ██ ███          │
  │  ███                    │      │  ███ ██ ███ ██ ███          │
  │  ███ ███                │      │  ███ ██ ███ ██ ███          │
  │  ███ ███ ███            │      │  ███ ██ ███ ██ ███          │
  │  ───────────            │      │  ─────────────────          │
  │  M T W T F S S          │      │  (30 bars instead of 7)     │
  │                         │      │                              │
  │7 days ago ← Oldest data │      │30 days ago ← Older data     │
  └─────────────────────────┘      └──────────────────────────────┘
```

## Complete Content View - Where Each Section Appears

### Page Structure (Top to Bottom)
```
Line 138-147: HERO CARD
   │
   │ (24px gap)
   │
Line 148-151: HEALTH TRENDS & FORECAST
   │
   │ (24px gap)
   │
Line 152: TIME RANGE FILTER BUTTONS ← User interacts here
   │ ┌─────────────────────────────────┐
   │ │ [All Time] [30 Days] [7 Days]   │
   │ └─────────────────────────────────┘
   │
   │ (24px gap)
   │
Line 154: QUICK STATS (Farm Overview)
   │
   │ (24px gap)
   │
Line 156: DISEASE THREAT CARDS
   │
   │ (24px gap)
   │
Line 158: ⭐ HEALTH TREND CHART ← FILTERED DATA DISPLAYED HERE
   │ ┌──────────────────────────────────────────────┐
   │ │ 📈 Activity Timeline                         │
   │ │                                              │
   │ │ Title: Detection Activity (Last 7/30/All)    │
   │ │ Badge: Shows "7 days", "30 days", etc.      │
   │ │                                              │
   │ │ [BAR CHART - Shows filtered data]            │
   │ │                                              │
   │ │ Insight: Context-specific message           │
   │ └──────────────────────────────────────────────┘
   │
   │ (24px gap)
   │
Line 160: SMART INSIGHTS
   │
   │ (24px gap)
   │
Line 162: ACTION BUTTONS (Export, Refresh)
```

## What The Chart Shows - Detailed View

### When User Clicks "7 Days"
```
Title:  "Detection Activity (Last 7 Days)"
Badge:  "7 days"
Data:   Takes 7 most recent data points from provider.timelineData
Chart:  Shows 7 bars (one per day, last 7 days)
Tip:    "📅 Viewing last 7 days - great for weekly monitoring and trend spotting"

Example Data Visualization:
    5│                █
     │          ██    █
     │      ██  ██  ██ █ ██
     │    ██ ██ ██  ██ █ ██
    1│    ██ ██ ██  ██ █ ██
     └────────────────────────
      Mon Tue Wed Thu Fri Sat Sun
      (1)  (2)  (3)  (2)  (5)  (1)  (2)  ← detection counts
```

### When User Clicks "30 Days"
```
Title:  "Detection Activity (Last 30 Days)"
Badge:  "30 days"
Data:   Takes 30 most recent data points from provider.timelineData
Chart:  Shows up to 30 bars (one per day, last 30 days)
Tip:    "📅 Viewing last 30 days - perfect for monthly health assessment..."

Example Data Visualization:
    5│  █  █  █  █  █  █  █  █  █  █
     │  █  █  █  █  █  █  █  █  █  █
     │  █  █  █  █  █  █  █  █  █  █
    1│  █  █  █  █  █  █  █  █  █  █
     └────────────────────────────────
      D1 D2 D3 D4 D5 ... D28 D29 D30
      (Last 30 days of data)
```

### When User Clicks "All Time"
```
Title:  "Detection Activity (All Time)"
Badge:  "65 days" (or however many days of history exist)
Data:   Takes ALL data points from provider.timelineData
Chart:  Shows ALL available bars
Tip:    "📅 Viewing all history - see complete farm health evolution..."

Example Data Visualization:
    5│  █  █  █  █  █  █  █  █  █  █  █  █
     │  █  █  █  █  █  █  █  █  █  █  █  █
     │  █  █  █  █  █  █  █  █  █  █  █  █
    1│  █  █  █  █  █  █  █  █  █  █  █  █
     └──────────────────────────────────────
      Day 1      Day 15      Day 30  ... Day 65
      (Complete history since app started)
```

## Code Flow - How Filter Selection Updates the Chart

```
┌──────────────────────────────────────────────┐
│ User Clicks "30 Days" Button                 │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│ _buildModernFilterChip() onTap fires         │
│                                              │
│ setState(() {                                │
│   _selectedTimeRange = 1;  // 1 = 30 Days   │
│ });                                          │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│ Widget rebuilds entire page                  │
│ _buildContent() is called again              │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│ Line 158: _buildHealthTrendChart() is called │
│                                              │
│ This function checks:                        │
│   switch(_selectedTimeRange) {               │
│     case 1: // Now 1 = 30 Days              │
│       daysToShow = 30;                      │
│       timeRangeLabel = 'Last 30 Days';     │
│       break;                                │
│   }                                          │
│                                              │
│   final recentData =                        │
│     provider.timelineData.take(30).toList(); │
│                                              │
│   Chart displays with:                      │
│   - Title: "Detection Activity (Last 30..."│
│   - Badge: "30 days"                        │
│   - Data: 30 bars                           │
│   - Message: context-aware tip              │
└──────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────┐
│ USER SEES UPDATED CHART                     │
│ Same location on page, new data displayed    │
└──────────────────────────────────────────────┘
```

## Key Locations to Remember

| Element | Location on Page | What It Does |
|---------|-----------------|--------------|
| Filter Buttons | Line 152 | User clicks here to select time range |
| Chart Title | Line 1115 | Updates to show selected range |
| Data Badge | Line 1122 | Shows "7 days", "30 days", etc. |
| Bar Chart | Line 1140 | Displays filtered data with bars |
| Insight Message | Line 1155 | Shows context-aware tip |

## User Perspective - What They Experience

**Before clicking any button:**
```
Statistics Page loads
All Time (unselected)  30 Days (unselected)  7 Days (selected by default)
                                                        ↑ Green, highlighted
```

**After clicking "30 Days":**
```
All Time (unselected)  30 Days (selected)    7 Days (unselected)
                            ↑ Green, highlighted

Chart below updates immediately:
- Title: "Detection Activity (Last 30 Days)"
- Chart: Now shows 30 bars instead of 7
- Badge: Shows "30 days"
- Tip: "perfect for monthly health assessment"
```

**After clicking "All Time":**
```
All Time (selected)    30 Days (unselected)  7 Days (unselected)
    ↑ Green, highlighted

Chart below updates immediately:
- Title: "Detection Activity (All Time)"
- Chart: Shows ALL available data (e.g., 65 days)
- Badge: Shows "65 days"
- Tip: "see complete farm health evolution over time"
```

## Summary

✅ **Filter Buttons Location**: Middle of the Statistics page (after Health Trends, before Quick Stats)
✅ **Filtered Content Location**: In the "📈 Activity Timeline" section below the filter buttons
✅ **What Updates**: 
   - Chart title
   - Chart data (bars shown)
   - Data badge (day count)
   - Contextual insight message
✅ **When**: Immediately when user clicks a button (no delays)
✅ **Static Sections**: Everything else (Hero Card, Quick Stats, Risk Ranking, Insights, Buttons) stays the same
