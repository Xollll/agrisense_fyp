# 🎨 HISTORY PAGE UI VISUAL GUIDE

## Color & Severity System

```
HEALTHY PLANT                          EARLY DISEASE (WARNING)
┌──────────────────────────┐          ┌──────────────────────────┐
│ 🟢 GREEN #10B981         │          │ 🟡 YELLOW #F59E0B        │
│ Low Risk Badge           │          │ Warning Badge            │
│ ℹ️ Info Icon            │          │ ⚠️ Warning Icon         │
│ "Your plant looks        │          │ "Early symptoms          │
│  healthy. No action      │          │  detected. Monitor       │
│  needed."                │          │  closely."               │
└──────────────────────────┘          └──────────────────────────┘

SEVERE DISEASE (CRITICAL)
┌──────────────────────────┐
│ 🔴 RED #DC2626           │
│ Critical Badge           │
│ ⚠️ Warning Icon         │
│ "Severe disease          │
│  detected. Immediate     │
│  action recommended."    │
└──────────────────────────┘
```

---

## Detection Card Layout

### Card Structure:
```
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║  🔴 Tomato Leaf Blight              📅 2025-12-12  🟡 Warning ║
║                                                                ║
║  ┌────────────────────────────────────────────────────────┐  ║
║  │ ⚠️ Early symptoms detected. Monitor closely.          │  ║
║  └────────────────────────────────────────────────────────┘  ║
║                                                                ║
║  Diagnosis Confidence                              65%        ║
║  ╔═════════════════════════════╦═════════════╗               ║
║  ║                             ║   Blue Color║               ║
║  ╚═════════════════════════════╩═════════════╝               ║
║                                                                ║
║  Recommended Action                                           ║
║  Water less frequently to reduce humidity around             ║
║  the leaves. Improve air circulation...                      ║
║  ┌──────────────────────────────────────────────────────┐  ║
║  │ View Full Recommendation →                           │  ║
║  └──────────────────────────────────────────────────────┘  ║
║                                                                ║
║                                        Tap for details →      ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
```

### Visual Elements:

1. **Colored Dot Indicator** (left side)
   ```
   Low Risk:  🟢 Green
   Warning:   🟡 Yellow
   Critical:  🔴 Red
   ```

2. **Colored Badge** (right side)
   ```
   Background: Severity color + 15% opacity
   Text: Severity label (Low Risk / Warning / Critical)
   Color: Full severity color
   ```

3. **Story Section**
   ```
   Container:
   - Background: Severity color + 8% opacity
   - Border: Severity color + 20% opacity
   - Icon: ℹ️ (info) for Low Risk, ⚠️ (warning) for others
   - Text: User-friendly message
   ```

4. **Confidence Bar**
   ```
   Color scheme:
   - 80%+ confidence: Cyan (#06B6D4)
   - 60-80% confidence: Sky blue (#0EA5E9)
   - 40-60% confidence: Amber (#F59E0B)
   - Below 40%: Red (#EF4444)
   ```

5. **Card Border & Shadow**
   ```
   Border: Severity color + 30% opacity
   Shadow: Severity color + 10% opacity
   Creates visual hierarchy
   ```

---

## Filter System

### Filter Chips:
```
┌─────────────┬────────────┬──────────┬──────────┐
│    All      │ Low Risk   │ Warning  │ Critical │
└─────────────┴────────────┴──────────┴──────────┘

Unselected:
  Background: Light gray
  Text: Dark gray

Selected:
  Background: Primary color (teal/cyan)
  Text: White
```

---

## Grouping System

### Timeline View:
```
╔════════════════════════════════════════╗
║ 📅 Today                           ↑ 3 ║
╚════════════════════════════════════════╝
  ┌──────────────────────────────────┐
  │ [Detection Card 1]               │
  └──────────────────────────────────┘
  ┌──────────────────────────────────┐
  │ [Detection Card 2]               │
  └──────────────────────────────────┘
  ┌──────────────────────────────────┐
  │ [Detection Card 3]               │
  └──────────────────────────────────┘

╔════════════════════════════════════════╗
║ 📅 This Week                       ↑ 2 ║
╚════════════════════════════════════════╝
  ┌──────────────────────────────────┐
  │ [Detection Card 4]               │
  └──────────────────────────────────┘
  ┌──────────────────────────────────┐
  │ [Detection Card 5]               │
  └──────────────────────────────────┘

╔════════════════════════════════════════╗
║ 📅 This Month                      ↓ 5 ║ ← Can be collapsed
╚════════════════════════════════════════╝

╔════════════════════════════════════════╗
║ 📅 Older                           ↓ 12║ ← Can be collapsed
╚════════════════════════════════════════╝
```

---

## Full Recommendation Modal

### Modal Layout:
```
╔════════════════════════════════════════════════╗
║                                                ║
║  Full Recommendation                   ✕      │  Header
║                                                ║
║  ┌────────────────────────────────────────┐  ║
║  │ Water less frequently to reduce        │  │
║  │ humidity around the leaves. Improve    │  │  Full Text
║  │ air circulation by pruning lower       │  │  (scrollable)
║  │ branches. Apply fungicide if           │  │
║  │ symptoms persist after 1 week.         │  │
║  │                                        │  │
║  │ Consider using sulfur-based            │  │
║  │ fungicides or neem oil for organic     │  │
║  │ gardens. Ensure proper spacing         │  │
║  │ between plants...                      │  │
║  └────────────────────────────────────────┘  ║
║                                                ║
╚════════════════════════════════════════════════╝
```

---

## Details Modal - Complete View

### Full Details Modal Structure:
```
╔════════════════════════════════════════════════╗
║                                                ║
║                     ─────                  ✕  │  Header
║                                                ║
║  🔴 Tomato Leaf Blight             🟡 Warning │  Title
║  📅 2025-12-12                                 ║
║                                                ║
║  Plant Health Status                           │  Section 1
║  ┌────────────────────────────────────────┐  ║
║  │ 🏥 Disease Detected                    │  ║
║  │ Your plant may have health issues      │  ║
║  │ that need attention.                   │  ║
║  └────────────────────────────────────────┘  ║
║                                                ║
║  Diagnosis Confidence                          │  Section 2
║  ╔═════════════════════════════╦═════╗        ║
║  ║████████████████████████░░░░░║ 65% ║        ║
║  ╚═════════════════════════════╩═════╝        ║
║  How confident the AI model is in this        ║
║  diagnosis                                    ║
║                                                ║
║  Recommended Action                            │  Section 3
║  ┌────────────────────────────────────────┐  ║
║  │ Water less frequently to reduce        │  ║
║  │ humidity. Improve air circulation.     │  ║
║  │ Apply fungicide if needed...           │  ║
║  └────────────────────────────────────────┘  ║
║                                                ║
║  Detection Details                             │  Section 4
║  ┌────────────────────────────────────────┐  ║
║  │ Disease          Tomato Leaf Blight    │  ║
║  │ ─────────────────────────────────────  │  ║
║  │ Status           Disease Detected      │  ║
║  │ ─────────────────────────────────────  │  ║
║  │ Severity         Warning               │  ║
║  │ ─────────────────────────────────────  │  ║
║  │ Date             2025-12-12            │  ║
║  └────────────────────────────────────────┘  ║
║                                                ║
╚════════════════════════════════════════════════╝
```

---

## Severity Decision Tree

```
                    ┌─ Detection Input
                    │
                    ▼
            ┌─────────────────┐
            │ Get Label &     │
            │ Confidence      │
            └─────────────────┘
                    │
                    ▼
            ┌─────────────────┐
            │ Is "Healthy"?   │
            │ (or "Normal",   │
            │  "Good")        │
            └─────────────────┘
                 /        \
               YES        NO
              /            \
             ▼              ▼
        ┌─────────┐    ┌──────────────┐
        │  LOW    │    │ Check Conf.  │
        │ (Green) │    │              │
        └─────────┘    └──────────────┘
                            |
                     /──────┼──────\
                    /       |       \
                 ≥0.80    0.50-0.79  <0.50
                /          |          \
               ▼           ▼           ▼
          ┌─────────┐ ┌─────────┐ ┌─────────┐
          │CRITICAL │ │ WARNING │ │  LOW    │
          │ (Red)   │ │(Yellow) │ │(Green)  │
          └─────────┘ └─────────┘ └─────────┘
```

---

## Dark Mode Support

### Colors in Light Mode:
```
Card Background:    White
Text Primary:       Black
Text Secondary:     Gray (shade 700)
Border:             Gray (shade 100)
Section BG:         Gray (shade 50)
```

### Colors in Dark Mode:
```
Card Background:    Gray (shade 900)
Text Primary:       White
Text Secondary:     Gray (shade 400)
Border:             Gray (shade 800)
Section BG:         Gray (shade 800)
```

### Severity Colors (Both Modes):
```
Low Risk:     #10B981 (Green) - unchanged
Warning:      #F59E0B (Yellow) - unchanged
Critical:     #DC2626 (Red) - unchanged
Confidence:   Uses cyan/blue palette - unchanged
```

---

## Responsive Design

### Mobile (Portrait):
```
Width: Full screen
Padding: 16px horizontal
Card Height: Auto (content-based)
Font Size: 13-15px
```

### Tablet (Landscape):
```
Width: Full screen
Padding: 24px horizontal
Card Height: Auto (content-based)
Font Size: 13-15px
```

### Modals:
```
All modals use bottom sheet
Scrollable if content > viewport
Respects keyboard height
Works on all screen sizes
```

---

## Animation & Interaction

### Card Interactions:
```
1. Tap Card → Opens Details Modal
2. Click "View Full Recommendation" → Opens Recommendation Modal
3. Click Section Header → Collapse/Expand

All interactions are responsive and immediate
```

### Smooth Transitions:
```
- Modal bottom sheet slide-up animation
- No janky scrolling
- Smooth list animations
- Responsive touch feedback
```

---

## Accessibility Features

```
✓ Color not only indicator (icons + text)
✓ Clear text hierarchy
✓ Sufficient contrast ratios
✓ Touch targets: min 48x48dp
✓ Semantic HTML structure
✓ Screen reader friendly labels
✓ Dark mode support
```

---

## Quick Reference: Severity Indicators

```
┌─────────────┬──────────┬──────────┬────────────┐
│   Severity  │  Color   │  Label   │   Icon     │
├─────────────┼──────────┼──────────┼────────────┤
│ Low Risk    │ 🟢 Green │ Low Risk │ ℹ️ Info    │
│ Warning     │ 🟡 Yellow│ Warning  │ ⚠️ Alert   │
│ Critical    │ 🔴 Red   │ Critical │ ⚠️ Alert   │
└─────────────┴──────────┴──────────┴────────────┘
```

---

**Last Updated**: December 12, 2025
**Design System**: Material 3
**Platform**: Flutter
