# 🎨 History Page Timeline - Visual Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    HISTORY PAGE SYSTEM                      │
└─────────────────────────────────────────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │               │
            ┌───────▼────┐  ┌──────▼────────┐
            │ UI LAYER   │  │ DATA LAYER    │
            └───────┬────┘  └──────┬────────┘
                    │               │
        ┌───────────┼───────────┐   │
        │           │           │   │
    ┌───▼──┐ ┌──────▼────┐ ┌───▼──▼────┐
    │Search│ │Filter+Srt │ │Timeline   │
    │      │ │           │ │ Grouping  │
    └──────┘ └───────────┘ └──────────┘
        │           │            │
        │           │            │
        └───────────┼────────────┘
                    │
            ┌───────▼────────┐
            │ Supabsae DB    │
            │ (Detections)   │
            └────────────────┘
```

---

## Data Flow Diagram

```
Database
   │
   ▼
┌──────────────────────┐
│ Raw Detections List  │
│  47 items with:      │
│  - label             │
│  - confidence        │
│  - timestamp         │
│  - solution          │
└──────────┬───────────┘
           │
           ▼
    ┌──────────────────────────────┐
    │ _filterDetections()          │
    │ ├─ Apply filter (confidence) │
    │ ├─ Apply search (disease)    │
    │ └─ Apply sort (date/conf)    │
    └──────────┬───────────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │ _groupDetectionsByDate()     │
    │ ├─ Today: [d1, d2]           │
    │ ├─ This Week: [d3-d10]       │
    │ ├─ This Month: [d11-d25]     │
    │ └─ Older: [d26-d47]          │
    └──────────┬───────────────────┘
               │
               ▼
    ┌──────────────────────────────┐
    │ Build UI                     │
    │ ├─ Quick Stats Bar           │
    │ ├─ Search Field              │
    │ ├─ Filter Chips              │
    │ ├─ Sort Dropdown             │
    │ └─ Timeline Sections         │
    └──────────────────────────────┘
```

---

## Component Hierarchy

```
HistoryPage (Widget)
│
└─ _HistoryPageState (State)
   │
   ├─ initState()
   │  └─ Load detections from Supabase
   │
   ├─ _buildHistoryContent()
   │  │
   │  ├─ FutureBuilder
   │  │  │
   │  │  ├─ Quick Stats Bar
   │  │  │  ├─ Total count
   │  │  │  └─ Disease count
   │  │  │
   │  │  ├─ Search & Filter Section
   │  │  │  ├─ TextField (search)
   │  │  │  ├─ FilterChips (All/Healthy/Warning/Critical)
   │  │  │  └─ DropdownButton (sort)
   │  │  │
   │  │  └─ Timeline ListView
   │  │     ├─ _buildDateSection('Today')
   │  │     │  ├─ Section Header (expandable)
   │  │     │  └─ _DetectionCard (x2)
   │  │     │
   │  │     ├─ _buildDateSection('This Week')
   │  │     │  ├─ Section Header
   │  │     │  └─ _DetectionCard (x8)
   │  │     │
   │  │     ├─ _buildDateSection('This Month')
   │  │     │  ├─ Section Header
   │  │     │  └─ _DetectionCard (x15)
   │  │     │
   │  │     └─ _buildDateSection('Older')
   │  │        ├─ Section Header
   │  │        └─ _DetectionCard (x22)
   │  │
   │  └─ _DetectionCard (reusable)
   │     ├─ Disease name
   │     ├─ Confidence bar
   │     ├─ Status badge
   │     └─ Tap listener → Detail Modal
   │
   └─ State Management
      ├─ _searchQuery (String)
      ├─ _sortBy (String)
      ├─ _expandedToday (bool)
      ├─ _expandedThisWeek (bool)
      ├─ _expandedThisMonth (bool)
      └─ _expandedOlder (bool)
```

---

## State Flow Diagram

```
┌─────────────┐
│ Initial UI  │
└──────┬──────┘
       │
       ▼
┌──────────────────┐
│ User Interactions│
└──────┬───────────┘
       │
       ├─ Types in search ────────┐
       │                          │
       ├─ Clicks filter chip ─────┤
       │                          │
       ├─ Changes sort ───────────┤
       │                          │
       └─ Taps section header ────┤
                                  │
                                  ▼
                        ┌─────────────────┐
                        │ setState() call  │
                        └────────┬────────┘
                                 │
                 ┌───────────────┼──────────────┐
                 │               │              │
                 ▼               ▼              ▼
        ┌──────────────┐ ┌────────────┐ ┌──────────────┐
        │ Filter List  │ │ Group List │ │ Build New UI │
        │              │ │            │ │              │
        │ Apply all    │ │ Group by   │ │ Render       │
        │ criteria     │ │ date       │ │ sections     │
        └──────────────┘ └────────────┘ └──────────────┘
                 │               │              │
                 └───────────────┼──────────────┘
                                 │
                                 ▼
                        ┌─────────────────┐
                        │  Screen Updates │
                        │  (Rerender)     │
                        └─────────────────┘
```

---

## Timeline Section Animation

```
Initial State: Today Section Expanded
┌─────────────────────────────┐
│ 📅 Today        (2)    ▼    │
├─────────────────────────────┤
│ • Disease 1 - 2025-12-08    │
│ • Disease 2 - 2025-12-08    │
└─────────────────────────────┘

User Taps on Header
│
▼ (triggers setState with _expandedToday = false)

Result: Today Section Collapsed
┌─────────────────────────────┐
│ 📅 Today        (2)    ►    │
└─────────────────────────────┘
[Content hidden, minimal space]

User Taps Again
│
▼ (triggers setState with _expandedToday = true)

Back to: Today Section Expanded
┌─────────────────────────────┐
│ 📅 Today        (2)    ▼    │
├─────────────────────────────┤
│ • Disease 1 - 2025-12-08    │
│ • Disease 2 - 2025-12-08    │
└─────────────────────────────┘
```

---

## Search & Filter Logic

```
User Types: "leaf spot"
│
▼
_filterDetections() called
│
├─ Check confidence level (filter)
│  └─ Keep if matches selected filter
│
├─ Check disease name (search)
│  └─ Keep if contains "leaf spot" (case-insensitive)
│
├─ Sort results
│  └─ Order by: Newest, Oldest, or Confidence
│
▼
Return filtered, searched, sorted list
│
▼
_groupDetectionsByDate() called
│
▼
_buildDateSection() for each group
│
▼
Render UI with updated data
```

---

## Date Grouping Logic

```
Raw Detection: timestamp = "2025-12-08T14:30:45"
│
▼
Extract date: "2025-12-08"
│
▼
Compare with boundaries:
├─ Is it today? (2025-12-08 == today)
│  └─ YES → Add to "Today" group
│
├─ Is it within last 7 days? (after weekAgo)
│  └─ YES → Add to "This Week" group
│
├─ Is it within last 30 days? (after monthAgo)
│  └─ YES → Add to "This Month" group
│
└─ Else
   └─ Add to "Older" group

Result:
┌──────────────────────────┐
│ Grouped Detections Map   │
├──────────────────────────┤
│ 'Today' → [d1, d2]       │
│ 'This Week' → [d3-d10]   │
│ 'This Month' → [d11-d25] │
│ 'Older' → [d26-d47]      │
└──────────────────────────┘
```

---

## Performance Optimization

```
Without Timeline View (Old)
┌──────────────────────────┐
│ ListView with 47 items   │
│ All items rendered       │
│ Scroll to find anything  │
│ Memory: High             │
│ Jank: Possible           │
└──────────────────────────┘

With Timeline View (New)
┌──────────────────────────┐
│ Sections (4)             │
│ Only expanded items      │
│   render (25 visible)    │
│ Collapsed sections = 0   │
│ Tap to expand when need  │
│ Memory: Lower            │
│ Performance: Smooth      │
└──────────────────────────┘

Result: 47% fewer items rendered initially
        More responsive UI
        Better mobile experience
```

---

## Quick Stats Calculation

```
All Detections (47 items)
│
├─ Extract disease labels
│  ├─ "Leaf Spot"
│  ├─ "Blight"
│  ├─ "Anthracnose"
│  ├─ "Rust"
│  ├─ "Powdery Mildew"
│  └─ "Healthy" (ignored)
│
└─ Count unique labels = 5

Display: "5 diseases"
```

---

## Responsive Layout

```
Mobile (≤600px)
┌─────────────────┐
│ App Bar         │
├─────────────────┤
│ Stats [1 col]   │
├─────────────────┤
│ Search [full]   │
├─────────────────┤
│ Filters [scroll]│
├─────────────────┤
│ Timeline [full] │
│ Section 1       │
│ Expanded        │
│   Card 1        │
│   Card 2        │
│                 │
│ Section 2       │
│ Collapsed (>)   │
└─────────────────┘

Tablet (600-1024px)
┌─────────────────────────┐
│ App Bar                 │
├─────────────────────────┤
│ [Stats 2 cols]          │
├─────────────────────────┤
│ Search  [Sort dropdown] │
│ Filters [visible]       │
├─────────────────────────┤
│ Timeline [2 col layout] │
│ Section 1 | Section 2   │
│ Cards     | Cards       │
└─────────────────────────┘

Desktop (>1024px)
┌─────────────────────────────────────┐
│ App Bar                             │
├─────────────────────────────────────┤
│ [Stats: 2 cols] [Search] [Sort]     │
│ [Filters: all visible]              │
├─────────────────────────────────────┤
│ Timeline: Full width                │
│ Section 1 | Section 2 | Section 3   │
│ Cards     | Cards     | Cards       │
└─────────────────────────────────────┘
```

---

## Color & Visual Hierarchy

```
Primary Color (Theme)
├─ Section Headers
├─ Quick Stats Values
├─ Filter Chip (selected)
└─ Icons

Primary @ 15% opacity
├─ Section backgrounds
└─ Accent backgrounds

Primary @ 10% opacity
├─ Borders
├─ Dividers
└─ Subtle highlights

Primary @ 8% opacity
├─ Badges (count)
└─ Light accents

Grey Tones
├─ Secondary text
├─ Disabled state
├─ Helper text
└─ Filter chip (unselected)

White/Black
├─ Card backgrounds
├─ Text (primary)
└─ Dividers
```

---

## Extension Points

```
                  HistoryPage
                      │
         ┌────────────┬┴┬────────────┐
         │            │ │            │
    [Phase 1]  [Phase 1] [Phase 1]  [Phase 2]
    Timeline    Search    Filter    Disease Chart
         │            │         │       │
         ├─ Easy      ├─ Done   ├─Done ├─ Add pie chart
         ├─ Working   ├─ Fast   ├─Smooth ├─ Show frequency
         └─ Clean     └─ Real   └─ Smart └─ Visual insights
                      time

Other Extensions:
├─ Calendar view
├─ Export to CSV
├─ Bulk actions (delete)
├─ Custom date range
├─ Advanced filtering
├─ Disease comparisons
└─ Severity indicators
```

---

This visual architecture shows how the Timeline View organizes, filters, groups, and displays detection data efficiently across all screen sizes.
