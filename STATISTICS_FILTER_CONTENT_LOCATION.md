# Where Users See Filtered Data - Quick Answer

## TL;DR - Location on Screen

When a user clicks **"7 Days"**, **"30 Days"**, or **"All Time"** button:

### 📍 Filter Buttons Location
- **Middle of the Statistics page**
- After "Health Trends & Forecast" section
- Before "Farm Overview" section

### 📍 Filtered Data Display Location
- **Below the filter buttons**
- In the **"📈 Activity Timeline"** section
- Shows a **bar chart** with detection activity

---

## Visual Flow - What User Sees

### Step 1: Open Statistics Page
```
[Statistics Page Loads]
     ↓
[User sees filter buttons with "7 Days" selected by default]
[Below: Activity Timeline showing 7 days of data]
```

### Step 2: User Clicks "30 Days"
```
[User clicks "30 Days" button]
     ↓
[Button highlights green ✓]
[Chart IMMEDIATELY updates below]
     ↓
[Title changes to: "Detection Activity (Last 30 Days)"]
[Badge shows: "30 days"]
[Chart now shows 30 bars instead of 7]
[Message changes to: "perfect for monthly health assessment..."]
```

### Step 3: User Clicks "All Time"
```
[User clicks "All Time" button]
     ↓
[Button highlights green ✓]
[Chart IMMEDIATELY updates below]
     ↓
[Title changes to: "Detection Activity (All Time)"]
[Badge shows: "65 days" (or total available)]
[Chart shows all available data]
[Message changes to: "see complete farm health evolution..."]
```

---

## Exact Page Layout

```
Statistics Page (from top to bottom)
│
├─ 📱 Hero Card (Farm Health Summary)
│
├─ 📊 Health Trends & Forecast
│
├─ 🎯 TIME RANGE FILTER BUTTONS ← USER CLICKS HERE
│  │   [All Time]  [30 Days]  [7 Days ✓]
│
├─ 🌾 Farm Overview (Static)
│
├─ ⚠️ Risk Ranking (Static)
│
├─ ⭐ ACTIVITY TIMELINE ← FILTERED DATA SHOWS HERE
│  │   Title: "Detection Activity (Last X)"
│  │   [BAR CHART WITH FILTERED DATA]
│  │   💡 Context message
│
├─ 💡 Farm Insights (Static)
│
├─ Action Buttons (Static)
```

---

## What Changes vs What Stays Same

### ✅ CHANGES When User Selects Time Range
- **Activity Timeline Title**: Updates to show "Last 7 Days", "Last 30 Days", or "All Time"
- **Bar Chart Data**: Shows 7, 30, or all available days
- **Day Count Badge**: Updates to show "7 days", "30 days", or total
- **Insight Message**: Changes to context-aware tip for selected range

### ❌ DOESN'T CHANGE
- Hero Card (always shows overall farm health)
- Health Trends & Forecast
- Farm Overview statistics
- Risk Ranking
- Farm Insights
- Action Buttons

---

## Example - What User Sees in Chart

### When "7 Days" Selected:
```
Detection Activity (Last 7 Days)          [7 days]

        █
    ██  █
    ██  █  ██
██  ██  █  ██  ██
─────────────────────
Mon Tue Wed Thu Fri Sat Sun
```

### When "30 Days" Selected:
```
Detection Activity (Last 30 Days)         [30 days]

█  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █
────────────────────────────────
(30 bars = 30 days of history)
```

### When "All Time" Selected:
```
Detection Activity (All Time)             [65 days]

█  █  █  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █  █  █
──────────────────────────────────────────
(All available days since app started)
```

---

## How It Works - Technical

```
User clicks button
        ↓
setState() updates _selectedTimeRange
        ↓
Page rebuilds
        ↓
_buildHealthTrendChart() checks _selectedTimeRange
        ↓
Filters data:
   - 7 days selected → take(7) from timeline data
   - 30 days selected → take(30) from timeline data
   - All time selected → take(all) from timeline data
        ↓
Chart renders with filtered data
        ↓
User sees updated chart in "Activity Timeline" section
```

---

## Testing - How to Verify It Works

1. **Open Statistics Page** → Chart shows 7 days by default
2. **Click "30 Days"** → Chart updates to show 30 days (should be wider)
3. **Click "All Time"** → Chart shows all available data
4. **Click "7 Days"** → Returns to original 7-day view
5. **Check Title** → Should say "Last 7 Days", "Last 30 Days", or "All Time"
6. **Check Badge** → Should show correct day count
7. **Check Message** → Should show contextual tip

---

## Summary for User

### Question: "Where do I see the filtered data?"
**Answer**: In the **"📈 Activity Timeline"** section, which is located **below the filter buttons** on the Statistics page.

### Question: "What changes when I click a filter?"
**Answer**: 
- The bar chart below updates
- Title shows what you selected
- Badge shows number of days
- Message gives you relevant context

### Question: "Is the data live/instant?"
**Answer**: **Yes!** The chart updates immediately when you click a button - no waiting or page refresh needed.

### Question: "Does it affect other parts of the page?"
**Answer**: **No.** Only the Activity Timeline chart changes. Everything else stays the same (Health Score, Risk Ranking, Insights, etc.)
