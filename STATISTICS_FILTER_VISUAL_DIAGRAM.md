# Visual Diagram - Statistics Page With Filtered Data

## Full Page Layout With Numbered Sections

```
┌─────────────────────────────────────────────────────────────────────┐
│                     STATISTICS PAGE LAYOUT                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  SECTION 1: Hero Card (Farm Health)                                │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 🌱 Thriving                 [Circular Progress: 92%]          │ │
│  │ ✅ 156 Scans  🌾 3 Issues  📊 92% Healthy                     │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  [Status: DOESN'T CHANGE when filter selected]                    │
│                                                                     │
│  ═════════════════════════════════════════════════════════════════ │
│                                                                     │
│  SECTION 2: Health Trends & Forecast                              │
│  ┌─────────────────────────┐ ┌──────────────────────────┐         │
│  │ 📈 Month-over-Month     │ │ 14-Day Forecast: ✅      │         │
│  │      +5.2%              │ │   Disease Stable         │         │
│  └─────────────────────────┘ └──────────────────────────┘         │
│  [Status: DOESN'T CHANGE when filter selected]                    │
│                                                                     │
│  ═════════════════════════════════════════════════════════════════ │
│                                                                     │
│  SECTION 3: TIME RANGE FILTER ← USER INTERACTS HERE 👆             │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ [All Time]  [30 Days]  [7 Days ✓]                           │ │
│  │   (gray)     (gray)     (GREEN - selected)                   │ │
│  └──────────────────────────────────────────────────────────────┘ │
│  [Status: Button colors CHANGE, data below FILTERS]               │
│                                                                     │
│  ═════════════════════════════════════════════════════════════════ │
│                                                                     │
│  SECTION 4: Farm Overview                                          │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 🔍 Total Detections: 156 scans completed                      │ │
│  │ 🦠 Disease Types: 3 unique issues found                       │ │
│  │ 🏆 Top Issue: Early Blight most common detection             │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  [Status: DOESN'T CHANGE when filter selected]                    │
│                                                                     │
│  ═════════════════════════════════════════════════════════════════ │
│                                                                     │
│  SECTION 5: Risk Ranking                                           │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ 1. 🔴 Early Blight    45%  (Critical Threat)                 │ │
│  │ 2. 🟠 Late Blight     28%  (High Risk)                       │ │
│  │ 3. 🟡 Powdery Mildew  15%  (Medium Risk)                     │ │
│  │ 4. 🟢 Healthy          8%  (Low Risk)                        │ │
│  │ 5. 🟢 Others           4%  (Low Risk)                        │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  [Status: DOESN'T CHANGE when filter selected]                    │
│                                                                     │
│  ═════════════════════════════════════════════════════════════════ │
│                                                                     │
│  SECTION 6: ACTIVITY TIMELINE ← FILTERED DATA SHOWN HERE! 👈       │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │                                                               │ │
│  │ Detection Activity (Last 7 Days)         [7 days]            │ │
│  │ ▲ (When 7 Days selected)                                     │ │
│  │ │         █                                                  │ │
│  │ │    ██   █   ██                                             │ │
│  │ │ ██ ██   █   ██ ██                                          │ │
│  │ 5┤ ██ ██   █   ██ ██                                          │ │
│  │ 1└──────────────────────  (7 bars)                           │ │
│  │    Mon Tue Wed Thu Fri Sat Sun                               │ │
│  │                                                               │ │
│  │ ──────────────────────────────────────────────────────────── │ │
│  │                                                               │ │
│  │ 💡 Viewing last 7 days - great for weekly                   │ │
│  │    monitoring and trend spotting                             │ │
│  │                                                               │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  [Status: CHANGES when filter selected! ✅]                       │
│                                                                     │
│  ─── IF USER CLICKS "30 Days" ───                                 │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Detection Activity (Last 30 Days)       [30 days]            │ │
│  │                                                               │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ ────────────────────────────────────────────────────────── │ │
│  │ D1 D2 D3 ... D28 D29 D30  (30 bars instead of 7)           │ │
│  │                                                               │ │
│  │ 💡 Viewing last 30 days - perfect for monthly              │ │
│  │    health assessment and progress tracking                   │ │
│  │                                                               │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  [Title, bars, badge, message ALL updated! ✅]                   │
│                                                                     │
│  ─── IF USER CLICKS "All Time" ───                                │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ Detection Activity (All Time)           [65 days]            │ │
│  │                                                               │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  █  │ │
│  │ ────────────────────────────────────────────────────────── │ │
│  │ (All available history - 65 bars)                           │ │
│  │                                                               │ │
│  │ 💡 Viewing all history - see complete farm health          │ │
│  │    evolution over time                                       │ │
│  │                                                               │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  [Completely different view! Much more data! ✅]                  │
│                                                                     │
│  ═════════════════════════════════════════════════════════════════ │
│                                                                     │
│  SECTION 7: Farm Insights                                          │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ ✅ Excellent farm health - keep maintaining...               │ │
│  │ 📊 Multiple diseases detected - prioritize...                │ │
│  │ 🎯 Early Blight is dominant - prioritize treating...         │ │
│  │ 📈 Detection rate increased - boost monitoring...             │ │
│  │ 📋 Continue regular monitoring schedule                      │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  [Status: DOESN'T CHANGE when filter selected]                    │
│                                                                     │
│  ═════════════════════════════════════════════════════════════════ │
│                                                                     │
│  SECTION 8: Action Buttons                                         │
│  ┌───────────────────────────────────────────────────────────────┐ │
│  │ [📥 Export Health Report]                                    │ │
│  │ [🔄 Refresh Data]                                            │ │
│  └───────────────────────────────────────────────────────────────┘ │
│  [Status: DOESN'T CHANGE when filter selected]                    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Interactive Elements Shown

### Filter Button Selection States

```
DEFAULT (Page First Loads):
  [All Time]    [30 Days]    [7 Days ✓]
    ⚪ Gray       ⚪ Gray      🟢 GREEN ← Selected

AFTER USER CLICKS "30 Days":
  [All Time]    [30 Days ✓]  [7 Days]
    ⚪ Gray       🟢 GREEN      ⚪ Gray ← Selected

AFTER USER CLICKS "All Time":
  [All Time ✓]  [30 Days]    [7 Days]
    🟢 GREEN      ⚪ Gray       ⚪ Gray ← Selected
```

---

## Chart Comparison - Visual Differences

### 7 Days View
```
                █
            ██  █
        ██  ██  █  ██
    ██  ██  ██  █  ██  ██
──────────────────────────────
Mon Tue Wed Thu Fri Sat Sun
 2   1   3   2   5   1   2
(Total: 16 detections across 7 days)
```

### 30 Days View
```
█  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █
──────────────────────────────────────
D1 D2 D3 ... D10 ... D20 ... D30
(Total: ~150 detections across 30 days - MORE DATA!)
```

### All Time View
```
█  █  █  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █  █  █
█  █  █  █  █  █  █  █  █  █  █  █
██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██ ██
─────────────────────────────────────────────
(All history since day 1 - COMPLETE picture!)
```

---

## Information Hierarchy

```
Filter Buttons (User controls)
        ↓ (User clicks)
        ↓
Chart Section Updates (What user sees)
├─ Title updates
├─ Data badge updates
├─ Bar chart updates
└─ Message updates

Everything else stays the same
```

---

## Timeline - What Happens

```
TIME: User sees page load
│
├─ Chart shows: "Last 7 Days" (default)
├─ Bars: 7 bars visible
├─ Message: "weekly monitoring"
│
│
TIME: User clicks "30 Days"
│
├─ Button highlight changes
├─ Chart updates:
│  ├─ Title: "Last 30 Days"
│  ├─ Bars: 30 bars visible
│  ├─ Badge: "30 days"
│  └─ Message: "monthly assessment"
│
│
TIME: User clicks "All Time"
│
├─ Button highlight changes
├─ Chart updates:
│  ├─ Title: "All Time"
│  ├─ Bars: All bars visible
│  ├─ Badge: "65 days"
│  └─ Message: "complete evolution"
│
│
TIME: User clicks "7 Days"
│
└─ Back to original state
```

---

## Key Takeaway

**User Experience Flow:**

```
📍 LOCATION: Middle of Statistics page (where filter buttons are)
       ↓ (User clicks)
       ↓
📍 LOCATION: Below filter buttons (Activity Timeline section)
       ↓ (What updates)
       ↓
✅ Chart title, bars, badge, message ALL UPDATE INSTANTLY
✅ Visual feedback is immediate and clear
✅ User sees exactly what time period they're viewing
```

**What makes it obvious:**
1. 🟢 Button turns green (visual feedback)
2. 📝 Title changes (text feedback)
3. 📊 Bars update (data feedback)
4. 🏷️ Badge shows day count (numeric feedback)
5. 💡 Message explains (contextual feedback)

**All 5 pieces of feedback happen simultaneously = Clear UX!**
