# 🎨 Statistics Page Redesign - Visual Mockup Guide

## Full Page Wireframe

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  📊 Farm Analytics                                         │
│  "Understand your crop health story"              [≡ Menu] │
│                                                            │
├────────────────────────────────────────────────────────────┤
│ ╔════════════════════════════════════════════════════════╗ │
│ ║  🟢 FARM HEALTH STATUS CARD                            ║ │
│ ║                                                        ║ │
│ ║  Status: EXCELLENT     Health Score: 92/100           ║ │
│ ║                                                        ║ │
│ ║  "Your chili crops are thriving! 🌱"                  ║ │
│ ║                                                        ║ │
│ ║  🟢 87% Healthy Plants  |  📊 2,347 Observations      ║ │
│ ║                                                        ║ │
│ ╚════════════════════════════════════════════════════════╝ │
│                                                            │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ 📅 TIME RANGE FILTERS                               │  │
│ │ [All Time] [30 Days] [7 Days] ← 7 Days selected     │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                            │
│ ╔════════════════════════════════════════════════════════╗ │
│ ║  📖 YOUR CROP STORY                                   ║ │
│ ║                                                        ║ │
│ ║  Total Observations ··············· 2,347             ║ │
│ ║  Average Health Score ············ 88.5%              ║ │
│ ║  Most Monitored Crop ··········· Chili Pepper        ║ │
│ ║  Last Data Check ·············· 2 hours ago           ║ │
│ ║                                                        ║ │
│ ╚════════════════════════════════════════════════════════╝ │
│                                                            │
│ ╔════════════════════════════════════════════════════════╗ │
│ ║  ⚠️  DISEASE THREAT ASSESSMENT (Ranked by Severity)   ║ │
│ ║                                                        ║ │
│ ║  🔴 CRITICAL                                          ║ │
│ ║  └─ Powdery Mildew ··············· 24 cases          ║ │
│ ║                                                        ║ │
│ ║  🟠 HIGH                                              ║ │
│ ║  └─ Leaf Spot ···················· 8 cases           ║ │
│ ║                                                        ║ │
│ ║  🟡 MODERATE                                          ║ │
│ ║  └─ Blight ······················· 3 cases           ║ │
│ ║                                                        ║ │
│ ║  🟢 LOW                                               ║ │
│ ║  └─ Mosaics ······················ 1 case            ║ │
│ ║                                                        ║ │
│ ╚════════════════════════════════════════════════════════╝ │
│                                                            │
│ ╔════════════════════════════════════════════════════════╗ │
│ ║  📈 CROP HEALTH JOURNEY (Last 7 Days)                ║ │
│ ║                                                        ║ │
│ ║      90 ┤                                              ║ │
│ ║      85 ┤      ╱╲                                       ║ │
│ ║      80 ┤     ╱  ╲       ╱──────╲                      ║ │
│ ║      75 ┤    ╱    ╲─────╱        ╲                     ║ │
│ ║      70 ┤   ╱                     ╲──────              ║ │
│ ║         ├──────────────────────────────────            ║ │
│ ║         Mon  Tue  Wed  Thu  Fri  Sat  Sun             ║ │
│ ║                                                        ║ │
│ ║  Trend: Declining (-5 points this week)              ║ │
│ ║  Message: "Monitor closely this week" ⚠️              ║ │
│ ║                                                        ║ │
│ ╚════════════════════════════════════════════════════════╝ │
│                                                            │
│ ╔════════════════════════════════════════════════════════╗ │
│ ║  🤖 AI-POWERED RECOMMENDATIONS                         ║ │
│ ║                                                        ║ │
│ ║  🎯 IMMEDIATE ACTION:                                 ║ │
│ ║  "Apply fungicide to control Powdery Mildew.          ║ │
│ ║   Best timing: Early morning when humidity high."     ║ │
│ ║                                                        ║ │
│ ║  💡 NEXT STEPS:                                       ║ │
│ ║  "Improve air circulation to reduce humidity and      ║ │
│ ║   prevent future outbreaks."                          ║ │
│ ║                                                        ║ │
│ ║  📋 TRACK PROGRESS:                                   ║ │
│ ║  "Monitor for 7 days after treatment to confirm       ║ │
│ ║   effectiveness."                                     ║ │
│ ║                                                        ║ │
│ ╚════════════════════════════════════════════════════════╝ │
│                                                            │
│ ╔════════════════════════════════════════════════════════╗ │
│ ║  📊 HEALTH METRICS COMPARISON                          ║ │
│ ║                                                        ║ │
│ ║  MONITORING SCORE: 92/100  ⭐⭐⭐⭐⭐                ║ │
│ ║  ├─ Detection System: 95%  (Active surveillance)      ║ │
│ ║  ├─ Data Quality: 88%  (Consistent observations)      ║ │
│ ║  └─ Alert System: 92%  (Timely notifications)         ║ │
│ ║                                                        ║ │
│ ║  HEALTH INDEX: 87/100  ⭐⭐⭐⭐                      ║ │
│ ║  ├─ Crop Status: 90%  (Good plant health)            ║ │
│ ║  ├─ Disease Pressure: 75%  (Some concerns)           ║ │
│ ║  └─ Growth Rate: 88%  (Expected development)         ║ │
│ ║                                                        ║ │
│ ╚════════════════════════════════════════════════════════╝ │
│                                                            │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ [📥 Export Report]  [🔄 Refresh Data]               │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                            │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## Color Palette

```
PRIMARY COLORS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🟢 Green (Healthy)
   Light: #E8F5E9
   Main: #4CAF50
   Dark: #2E7D32
   Usage: Good status, healthy crops, low risk

🟡 Yellow (At Risk)
   Light: #FFF9C4
   Main: #FBC02D
   Dark: #F57F17
   Usage: Moderate concern, needs attention

🔴 Red (Critical)
   Light: #FFEBEE
   Main: #F44336
   Dark: #C62828
   Usage: Alert, urgent action needed

🔵 Blue (Information)
   Light: #E3F2FD
   Main: #2196F3
   Dark: #1565C0
   Usage: Data points, metrics, secondary info

⚫ Gray (Neutral)
   Light: #F5F5F5
   Main: #757575
   Dark: #424242
   Usage: Text, dividers, disabled states
```

---

## Section Color Schemes

### 1️⃣ Farm Health Status Card
```
┌────────────────────────────────────┐
│                                    │  Background: Light Green (#E8F5E9)
│  🟢 FARM HEALTH STATUS             │  Border: Green (#4CAF50)
│  Status: EXCELLENT | Score: 92/100 │  Text: Dark Gray (#424242)
│  "Your chili crops are thriving!"  │  Status Badge: Bright Green
│  🟢 87% Healthy • 📊 2.3K obs.     │
│                                    │
└────────────────────────────────────┘
```

### 4️⃣ Disease Assessment Card
```
🔴 CRITICAL - Powdery Mildew (24)     ← Red text on light red background
🟠 HIGH - Leaf Spot (8)                ← Orange text on light orange background
🟡 MODERATE - Blight (3)               ← Yellow text on light yellow background
🟢 LOW - Mosaics (1)                   ← Green text on light green background
```

### 7️⃣ Health Metrics Card
```
Monitoring Score: 92/100 ⭐⭐⭐⭐⭐   ← Blue background, gold stars
Health Index: 87/100 ⭐⭐⭐⭐        ← Blue background, gold stars
```

---

## Typography Hierarchy

```
PAGE TITLE (32px, Bold, Tracking 0.8px)
┌─────────────────────────────────────┐
│ Farm Analytics                      │
└─────────────────────────────────────┘

SUBTITLE (14px, Regular, Opacity 85%)
Understand your crop health story

SECTION HEADER (18px, Semi-Bold, Tracking 0.2px)
🔴 DISEASE THREAT ASSESSMENT (Ranked by Severity)

METRIC LABEL (14px, Regular)
Status: EXCELLENT

METRIC VALUE (24px, Bold, Color-coded)
92/100

SUPPORTING TEXT (12px, Regular, Opacity 75%)
Last data check: 2 hours ago

RECOMMENDATION TEXT (14px, Regular, Line-height 1.6)
Apply fungicide to control Powdery Mildew.
Best timing: Early morning when humid.
```

---

## Spacing System

```
VERTICAL SPACING
────────────────────────────────────
24px - Between major sections
16px - Between cards/subsections
12px - Between items in a list
8px  - Between icon and label
4px  - Minimal gaps

HORIZONTAL SPACING
────────────────────────────────────
24px - Page left/right padding
16px - Card padding
12px - Internal section padding
8px  - Icon spacing

LINE HEIGHT
────────────────────────────────────
1.2  - Titles
1.5  - Labels
1.6  - Body text
1.8  - Recommendations
```

---

## Icon System

```
STATUS INDICATORS
🟢 Healthy/Good/Low Risk
🟡 At Risk/Moderate/Caution
🔴 Critical/High Risk/Alert

SECTION HEADERS
📊 Statistics/Data/Metrics
📈 Trends/Growth/Improvement
📖 Story/Context/Information
⚠️  Warnings/Alerts
🤖 AI/Recommendations
📅 Time/Calendar
🌾 Crops/Plants
💧 Water/Humidity
📋 Tracking/Monitoring
🎯 Actions/Goals

ACTION BUTTONS
📥 Export/Download
🔄 Refresh/Update
📞 Contact/Help
⚙️ Settings
```

---

## Component States

### Card Component
```
DEFAULT STATE
┌─────────────────────────────────┐
│  Section Title                  │
│  Content here                   │
│  More content                   │
└─────────────────────────────────┘

HOVER STATE (Desktop)
┌─────────────────────────────────┐  Box shadow increases
│  Section Title                  │  Background slightly darker
│  Content here                   │  Cursor changes
│  More content                   │
└─────────────────────────────────┘

TAP STATE (Mobile)
┌─────────────────────────────────┐  Slight scale change
│  Section Title                  │  Opacity feedback
│  Content here                   │
│  More content                   │
└─────────────────────────────────┘
```

### Button Component
```
PRIMARY BUTTON
┌────────────────────────┐
│  📥 Export Report      │  Green background, white text
└────────────────────────┘

SECONDARY BUTTON
┌────────────────────────┐
│  🔄 Refresh Data       │  Gray background, dark text
└────────────────────────┘

DISABLED BUTTON
┌────────────────────────┐
│  📥 Export Report      │  Light gray, opacity 50%
└────────────────────────┘
```

---

## Responsive Design

### Desktop (1024px+)
```
Full width layout
Two-column grids possible
Hover states active
Large touch targets
```

### Tablet (600px - 1024px)
```
Full width cards
Single column
Touch-optimized buttons
Vertical stacking
```

### Mobile (< 600px)
```
100% width minus padding
Vertical card stacking
Full-width buttons
Thumb-friendly spacing
Minimal text truncation
```

---

## Animation & Transitions

```
ENTRANCE ANIMATIONS
Cards fade in: 200ms ease-out
Content stagger: 50ms between items
Total page load: ~400ms

INTERACTION ANIMATIONS
Button tap: 100ms scale
Refresh spinner: 600ms rotation
Number changes: 300ms fade/slide

GESTURE ANIMATIONS
Pull-to-refresh: 400ms total
Swipe navigation: 250ms slide
Scroll parallax: 100ms offset
```

---

## Dark Mode Adaptation

```
Light Mode (Default)
Background: White (#FFFFFF)
Text: Dark Gray (#212121)
Cards: Light Gray (#F5F5F5)
Accents: Green (#4CAF50)

Dark Mode
Background: Dark Gray (#121212)
Text: White (#FFFFFF)
Cards: Slightly Lighter Gray (#1E1E1E)
Accents: Light Green (#66BB6A)
```

---

## Accessibility Considerations

```
COLOR CONTRAST
Minimum 4.5:1 for text
Minimum 3:1 for UI components

TEXT SIZING
Minimum 14px for body text
Maximum 120 characters per line
Line height minimum 1.5

TOUCH TARGETS
Minimum 44px × 44px
8px minimum spacing between targets

SEMANTIC STRUCTURE
Proper heading hierarchy
Alt text for images
ARIA labels for interactive elements
Screen reader optimization
```

---

## Mobile View Adjustments

```
┌─────────────────────────────┐
│  Farm Analytics             │  No subtitle on mobile
│  [≡]                        │
├─────────────────────────────┤
│                             │
│ ┌───────────────────────┐   │  Cards full width
│ │ 🟢 FARM HEALTH STATUS │   │
│ │ Excellent | 92/100    │   │  Smaller padding
│ │ "Thriving!"           │   │
│ │ 87% Healthy • 2.3K    │   │  Text slightly smaller
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │ [All Time]            │   │  Single column buttons
│ │ [30 Days]             │   │
│ │ [7 Days] ← Selected   │   │
│ └───────────────────────┘   │
│                             │
│ ┌───────────────────────┐   │
│ │ 📖 YOUR CROP STORY    │   │
│ │                       │   │
│ │ Observations: 2,347   │   │  Stacked layout
│ │ Health: 88.5%         │   │
│ │ Crop: Chili Pepper    │   │
│ │ Check: 2 hours ago    │   │
│ └───────────────────────┘   │
│                             │
│ [Pull to refresh ↓]         │
│                             │
└─────────────────────────────┘
```

---

## Visual Feedback Examples

### Status Messages Based on Health Score

```
92-100: 🟢 "Your chili crops are thriving!"
        Green card, confident tone, success emoji

75-91:  🟡 "Your crops are doing well - stay vigilant"
        Yellow card, cautionary tone, watch emoji

50-74:  🟠 "Attention needed - address issues soon"
        Orange card, urgent tone, alert emoji

Below 50: 🔴 "Critical attention required immediately"
          Red card, urgent tone, danger emoji
```

---

## Data Visualization Styles

### Health Score Progress Ring
```
        90°
        │
  ┌─────┼─────┐
  │     │     │
  │  92%│     │  Circular progress indicator
  │    ╱ ╲    │  Colored arc (green for healthy)
  └───╱   ╲───┘  Inner text shows percentage
      │   │
     180°
```

### 7-Day Trend Bar Chart
```
Heights: Variable based on score
Colors:  Gradient from green (good) to red (bad)
Values:  Shown above bars on hover/tap
Baseline: Dashed line at average
```

### Disease Distribution Pie Chart
```
Slices: One per disease category
Colors: Red/Orange/Yellow/Green based on severity
Labels: Disease name + percentage
Interaction: Tap to see detailed statistics
```

---

## Information Architecture

```
DEPTH 1 - Overview (1 glance)
Farm Health Status → Tells you everything you need to know

DEPTH 2 - Analysis (1-2 minutes)
Disease Assessment + Health Journey → Understand the problems

DEPTH 3 - Action (2-3 minutes)
AI Recommendations + Metrics → Know what to do

DEPTH 4 - Details (Optional)
Full metrics comparison + Historical data → Deep dive

DEPTH 5 - Export (End of journey)
Export report → Share with advisors or keep records
```

---

## Error States

```
⚠️ NO DATA
┌─────────────────────────────────┐
│ ⚠️ No Data Available            │
│                                 │
│ "Ensure sensors are active      │
│  and connected. Check back      │
│  in a few minutes."             │
│                                 │
│ [🔄 Retry]  [📞 Get Help]       │
└─────────────────────────────────┘

❌ ERROR LOADING
┌─────────────────────────────────┐
│ ❌ Error Loading Data           │
│                                 │
│ "Something went wrong.          │
│  Check your internet and        │
│  try again."                    │
│                                 │
│ [🔄 Retry]  [📞 Support]        │
└─────────────────────────────────┘

⏳ LOADING
┌─────────────────────────────────┐
│                                 │
│        ⟳ Loading...             │
│                                 │
│     (Spinning animation)        │
│                                 │
└─────────────────────────────────┘
```

---

## Summary

This visual guide ensures:

✅ **Consistency** - Colors, spacing, typography are unified  
✅ **Clarity** - Visual hierarchy guides the eye  
✅ **Accessibility** - Proper contrast and sizing  
✅ **Responsiveness** - Works on all device sizes  
✅ **Engagement** - Beautiful, modern appearance  
✅ **Usability** - Intuitive, easy to understand  

The result: A statistics page that tells a story farmers can understand at a glance.

