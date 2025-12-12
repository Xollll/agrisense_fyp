# History Page - Visual Reference & UI Guide

## 🎨 Component Layouts

### Detection Card - Complete Layout

```
┌────────────────────────────────────────────────┐
│ My Disease Name          2024-01-15  [Warning] │
├────────────────────────────────────────────────┤
│                                                │
│ Early symptoms detected. Monitor closely.      │
│                                                │
│ Diagnosis Confidence                      75%  │
│ [████████████░░░░░░░░░░░░░░░░░░░░░░░░]        │
│                                                │
│ Recommended Action                             │
│ The first 2-3 lines of the recommendation    │
│ text appears here with ellipsis if longer...  │
│ [View Full Recommendation]                     │
│                                                │
│                              → Tap for details │
└────────────────────────────────────────────────┘
```

### Severity Badge Variants

```
[Healthy]    - Green background, green text, green border
[Low Risk]   - Green background, green text, green border
[Warning]    - Yellow background, yellow text, yellow border
[Critical]   - Red background, red text, red border
```

### Time Period Section Header

```
┌────────────────────────────────────────┐
│ 📅 Today                     [5]  ▼    │
└────────────────────────────────────────┘
```

When expanded (▼ shows ▲):
- Shows all today's detections below
- Count badge shows number of items
- Click to collapse

---

## 📱 Screen Layouts

### Main History Page

```
┌──────────────────────────────────────┐
│ ← History                        ☰   │ ← Enhanced App Bar
├──────────────────────────────────────┤
│ Detections    |    Diseases Found   │ ← Quick Stats Bar
│      12       |         3            │
├──────────────────────────────────────┤
│ [search icon] Search disease... [X]  │ ← Search Bar
│ [All][Healthy][Low Risk][Warning]... │ ← Filter Chips
│                           [Sort ▼]   │ ← Sort Dropdown
├──────────────────────────────────────┤
│ 📅 Today                        [3] ▼ │ ← Collapsible Section
│                                      │
│ ┌──────────────────────────────────┐ │ ← Detection Card
│ │ Powdery Mildew  2024-01-15 [Crit]│ │
│ │ Severe disease detected. Immed...│ │
│ │ Diagnosis: 92%                  │ │
│ │ [████████████░░░░░░░░░░░░░░░░░] │ │
│ │ First 2-3 lines of recommend... │ │
│ │                    → Tap for det │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ Early Blight    2024-01-15 [Warn]│ │
│ │ Early symptoms detected. Monitor │ │
│ │ Diagnosis: 65%                  │ │
│ │ [████████░░░░░░░░░░░░░░░░░░░░░] │ │
│ │ Action: Monitor soil moisture...│ │
│ │                    → Tap for det │ │
│ └──────────────────────────────────┘ │
│                                      │
│ 📅 This Week                    [5] ▼ │
│                                      │
│ [More items...]                      │
│                                      │
│ 📅 This Month                   [8] ▲ │
│ [Collapsed]                          │
│                                      │
│ 📅 Older                        [2] ▲ │
│ [Collapsed]                          │
└──────────────────────────────────────┘
```

---

## 🔍 Details Modal - Full Layout

```
┌──────────────────────────────────────┐
│                   ─────              │ ← Drag indicator
│                             [X]      │ ← Close button
├──────────────────────────────────────┤
│                                      │
│ ● Powdery Mildew      2024-01-15    │ ← Header with severity dot
│                             [Critical]
│                                      │
│ Severe disease detected. Immediate  │ ← Story text
│ action recommended.                 │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ Plant Health Status              │ │ ← Health Status
│ │                                  │ │
│ │ ⚠️  Disease Detected             │ │
│ │ Your plant may have health       │ │
│ │ issues that need attention       │ │
│ └──────────────────────────────────┘ │
│                                      │
│ Diagnosis Confidence                │ ← Confidence Section
│ [████████████░░░░░░░░░░░░░]  92.5% │
│ How confident the AI model is...    │
│                                      │
│ Recommended Action                  │ ← Full Recommendation
│ ┌──────────────────────────────────┐ │
│ │ 1. Apply fungicide spray to all │ │
│ │ affected areas                   │ │
│ │ 2. Improve air circulation      │ │
│ │ 3. Remove affected leaves       │ │
│ │ 4. Monitor daily for 2 weeks... │ │
│ └──────────────────────────────────┘ │
│                                      │
│ Detection Details                   │ ← Details Table
│ ┌──────────────────────────────────┐ │
│ │ Disease  │  Powdery Mildew      │ │
│ │ ─────────────────────────────────│ │
│ │ Status   │  Disease Detected    │ │
│ │ ─────────────────────────────────│ │
│ │ Severity │  Critical            │ │
│ │ ─────────────────────────────────│ │
│ │ Date     │  2024-01-15          │ │
│ └──────────────────────────────────┘ │
│                                      │
└──────────────────────────────────────┘
```

---

## 💾 Full Recommendation Modal

```
┌──────────────────────────────────────┐
│ Full Recommendation          [X]     │
├──────────────────────────────────────┤
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ Full recommendation text here:  │ │
│ │                                  │ │
│ │ 1. Apply fungicide spray to all │ │
│ │ affected plant parts            │ │
│ │                                  │ │
│ │ 2. Improve air circulation by   │ │
│ │ pruning nearby plants           │ │
│ │                                  │ │
│ │ 3. Remove severely affected     │ │
│ │ leaves immediately              │ │
│ │                                  │ │
│ │ 4. Monitor the plant daily for  │ │
│ │ the next 2 weeks                │ │
│ │                                  │ │
│ │ 5. Repeat spray every 7-10 days │ │
│ │ until symptoms disappear        │ │
│ │                                  │ │
│ │ 6. Improve soil drainage and    │ │
│ │ avoid overhead watering         │ │
│ │                                  │ │
│ │ [content scrolls if longer]     │ │
│ └──────────────────────────────────┘ │
│                                      │
└──────────────────────────────────────┘
```

---

## 🎯 Severity Badge Visual Guide

### Healthy Badge
```
┌────────────┐
│    ✓       │  Color: #10B981 (Green)
│  Healthy   │  Background: Green (15% opacity)
└────────────┘  Border: Green (40% opacity)
```

### Low Risk Badge
```
┌─────────────┐
│   Low Risk  │  Color: #10B981 (Green)
└─────────────┘  Background: Green (15% opacity)
                 Border: Green (40% opacity)
```

### Warning Badge
```
┌─────────────┐
│   Warning   │  Color: #F59E0B (Yellow/Amber)
└─────────────┘  Background: Amber (15% opacity)
                 Border: Amber (40% opacity)
```

### Critical Badge
```
┌─────────────┐
│  Critical   │  Color: #DC2626 (Red)
└─────────────┘  Background: Red (15% opacity)
                 Border: Red (40% opacity)
```

---

## 📊 Diagnosis Confidence Bar

### Visual Representation

```
Very Weak (0-40%)
[███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░]  25%
Color: #EF4444 (Red)

Weak (40-60%)
[████████░░░░░░░░░░░░░░░░░░░░░░░░░]  45%
Color: #F59E0B (Amber)

Moderate (60-80%)
[███████████████░░░░░░░░░░░░░░░░░░]  65%
Color: #0EA5E9 (Blue)

Strong (80-100%)
[████████████████████████░░░░░░░░░░]  85%
Color: #06B6D4 (Cyan)
```

---

## 🎨 Color Palette

### Primary Colors
| Name | Hex | Use |
|------|-----|-----|
| Green | #10B981 | Healthy, Low Risk badges, accents |
| Amber | #F59E0B | Warning badge, weak confidence |
| Red | #DC2626 | Critical badge, disease |
| Cyan | #06B6D4 | Strong confidence indicator |

### Secondary Colors
| Name | Hex | Use |
|------|-----|-----|
| Light Gray | #F3F4F6 | Backgrounds in light mode |
| Medium Gray | #E5E7EB | Borders, dividers |
| Dark Gray | #6B7280 | Secondary text |
| Very Dark Gray | #111827 | Primary text |

### Dark Mode Colors
| Name | Hex | Use |
|------|-----|-----|
| Dark BG | #111827 | Card backgrounds |
| Dark Gray 800 | #1F2937 | Lighter areas |
| Dark Gray 700 | #374151 | Borders |
| Light Gray | #D1D5DB | Text |

---

## 📏 Spacing & Sizing

### Card Dimensions
- Padding: 16px all sides
- Border radius: 16px
- Box shadow: 4px blur, 2px offset, 4% opacity
- Max width: Full available width

### Badge Sizing
- Padding: 12px horizontal, 6px vertical
- Border radius: 8px
- Font size: 12px
- Font weight: 700 (bold)

### Section Header Height
- Padding: 14px horizontal, 10px vertical
- Min height: ~44px (tap target)
- Icon size: 18px
- Border radius: 10px

### Progress Bar
- Height: 6px (card), 10px (modal)
- Border radius: 8px
- Min width: 100px

---

## 🔤 Typography

### Font Sizes
- **Headline Small**: 24px (details modal title)
- **Title Large**: 20px (modal headers)
- **Title Small**: 14px (section titles)
- **Body Medium**: 14px (main text)
- **Body Small**: 12px (secondary text, descriptions)
- **Label Large**: 14px (emphasis labels)
- **Label Small**: 12px (captions, hints)

### Font Weights
- **700 (Bold)**: Titles, labels, badges
- **600 (SemiBold)**: Subheadings, important text
- **500 (Medium)**: Descriptions, body text
- **400 (Regular)**: General text

### Line Heights
- Default: 1.2
- Card text: 1.4
- Modal body: 1.6-1.8

---

## 🖼️ Dark Mode Variants

All UI components have dark mode variants:

### Light Mode Card
- Background: White
- Text: Dark gray
- Border: Light gray
- Shadow: 4% black opacity

### Dark Mode Card
- Background: Gray-900
- Text: Light gray
- Border: Gray-800
- Shadow: 4% black opacity

---

## 📱 Responsive Behavior

### Phone (< 600px)
- Single column layout
- Full-width cards
- Touch-friendly button sizes (44px min)

### Tablet (600-900px)
- Still single column
- Cards with max width constraints
- Slightly larger padding

### Desktop (> 900px)
- Constrained width container
- Center-aligned content
- Enhanced spacing

---

## ✨ Interactive Elements

### Tap States
- Card: Slight background color change on tap
- Badge: No visual change (not tappable)
- Button: Color shift on tap
- Section header: Background color change

### Feedback
- Search clear button: Icon color change
- Expand/collapse arrow: Icon rotation + color change
- Filter chip: Background color change on selection
- Modal: Smooth slide-up animation

---

## 🎬 Animations & Transitions

- **Modal appearance**: Slide up from bottom (200ms)
- **Expand/collapse**: Icon rotation + content fade
- **Pull-to-refresh**: Standard Flutter indicator
- **Loading state**: Circular progress indicator
- **Transitions**: All smooth with Material curves

---

## ♿ Accessibility

- **Min touch target**: 44x44 pt
- **Color contrast**: WCAG AA compliant
- **Font size**: Min 12px for readability
- **Labels**: All buttons and badges have clear labels
- **Semantic**: Proper use of Widgets hierarchy
- **Dark mode**: Full theme support

---

**Reference Complete** ✅
Visual specifications are production-ready.
