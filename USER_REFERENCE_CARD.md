# AgriSense UI Reference Card

## 🌿 Plant Status Indicator

### ✅ Healthy (No Disease Detected)
```
┌─────────────────────────────────────┐
│ ✅ Plant Status                     │
│                                     │
│ Your plant looks healthy!           │
│ No disease detected.                │
│ Keep up the good care!              │
└─────────────────────────────────────┘
```
- Green background
- No "Ask AI for Tips" button
- Message: Reassuring and encouraging

---

## 🔴 Disease Detected (Active)

### What You See
```
┌─────────────────────────────────────┐
│ 💡 Get AI Tips    🔴 ACTIVE         │
│ Leaf Spot                           │
├─────────────────────────────────────┤
│ [AI recommendation text...]         │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Ask AI for Tips                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ⚠️ Disease detected! Click to get   │
│    AI-powered treatment tips.       │
└─────────────────────────────────────┘
```

### What It Means
- 🔴 RED badge = Disease is CURRENTLY visible in camera
- Disease label shown: "Leaf Spot", "Powdery Mildew", etc.
- "Ask AI for Tips" button is active and clickable
- Urgent messaging encourages immediate action

### What To Do
1. **Click "Ask AI for Tips"** to get treatment recommendations
2. Recommendations appear instantly (or loading spinner appears)
3. Follow the AI recommendations
4. Wait for disease to disappear

---

## ⏸️ Disease Detected But Resolved (No Longer Visible)

### What You See
```
┌─────────────────────────────────────┐
│ 💡 Get AI Tips   ⏸️ RESOLVED        │
│ Leaf Spot                           │
├─────────────────────────────────────┤
│ [Previous AI recommendation text...] │
│                                     │
│ ┌─────────────────────────────────┐ │
│ │ Ask AI for Tips                 │ │
│ └─────────────────────────────────┘ │
│                                     │
│ ℹ️ Disease was detected earlier.    │
│    Click to review recommendations. │
└─────────────────────────────────────┘
```

### What It Means
- ⏸️ GRAY badge = Disease is NO LONGER visible
- Disease label STILL shown for context
- Plant may have recovered, or disease is temporarily not visible
- "Ask AI for Tips" button still works
- Less urgent messaging (informational)

### What To Do
1. Monitor the plant for signs of recovery
2. Click "Ask AI for Tips" again to review treatment steps
3. Continue monitoring to ensure disease is truly gone
4. If disease reappears, badge will change back to 🔴 Active

---

## 🔄 Quick State Transitions

### Scenario 1: Healthy Plant
```
✅ Healthy
    ↓ (disease appears in camera)
🔴 Active Leaf Spot
    ↓ (user rotates camera, disease no longer visible)
⏸️ Resolved Leaf Spot
    ↓ (disease reappears in camera)
🔴 Active Leaf Spot (again)
    ↓ (continuous monitoring - disease gone for good)
⏸️ Resolved Leaf Spot (stays resolved)
    ↓ (many days pass, no reappearance)
✅ Healthy (badge eventually hides when no recent detections)
```

---

## 🎯 Button States

### Normal State (Ready to Click)
```
┌──────────────────────────────────┐
│ 🌟 Ask AI for Tips               │
└──────────────────────────────────┘
```
- Orange background
- White text
- Clickable

### Loading State (Waiting for AI)
```
┌──────────────────────────────────┐
│ ⏳ Getting Tips...                │
└──────────────────────────────────┘
```
- Orange background
- Spinner visible
- NOT clickable (disabled)
- Takes ~2-5 seconds typically

### Error State (API Failed)
```
⚠️ Error getting AI recommendation: [error message]
```
- Red banner at top of screen
- Button returns to normal state
- User can click again to retry

---

## 📱 Mobile View

### Smartphone (Vertical)
```
┌──────────────────────────────┐
│ CAMERA STREAM (280px height) │
└──────────────────────────────┘

Detections
┌──────────────────────────────┐
│ 🌿 Leaf Spot                 │
└──────────────────────────────┘

AI Recommendations
┌──────────────────────────────┐
│ 💡 Tips      🔴 Active       │
│ Leaf Spot                    │
│                              │
│ [Full AI recommendation text]│
│                              │
│ [Ask AI for Tips Button]     │
│                              │
│ Help message...              │
└──────────────────────────────┘
```

---

## 🎨 Color Guide

### Status Colors
| Status | Color | Icon | Meaning |
|--------|-------|------|---------|
| **Healthy** | 🟢 Green | ✅ | No disease |
| **Active** | 🔴 Red | 🔴 | Disease currently visible |
| **Resolved** | ⚫ Gray | ⏸️ | Disease not currently visible |

### Component Colors
| Component | Color | Hex Code |
|-----------|-------|----------|
| Healthy Background | Green Gradient | #E8F5E9 → #C8E6C9 |
| Active Background | Orange Gradient | #FFE0B2 → #FFECB3 |
| Resolved Badge | Gray | #F5F5F5 / #9E9E9E |
| Active Badge | Red | #FFEBEE / #E53935 |
| Button | Orange | #FF9800 |

---

## 📊 FAQ

### Q: What does 🔴 Active mean?
**A**: The disease is currently visible in the camera. Take action now!

### Q: What does ⏸️ Resolved mean?
**A**: The disease was detected but is not currently visible. It may have been treated or is temporarily off-camera.

### Q: Can I ask for AI tips when it's Resolved?
**A**: Yes! The "Ask AI for Tips" button works for both Active and Resolved diseases.

### Q: What if the disease comes back?
**A**: The badge will change to 🔴 Active automatically and you'll get a new urgent message.

### Q: Why does the healthy message disappear when I see a disease?
**A**: Because disease context is more important than a generic healthy message. The disease label and tips are more helpful.

### Q: Can I manually clear the disease?
**A**: Currently no, but this may be added in future updates. Close and reopen the app to reset.

### Q: How often is the camera checked for diseases?
**A**: The system checks every 700 milliseconds (10+ times per second) for very fast detection.

### Q: Does clicking "Ask AI for Tips" multiple times cost more?
**A**: No! The app is smart and caches the recommendations. Clicking again for the same disease shows the cached result instantly.

---

## ⚡ Quick Tips

1. **For Active Disease**: Act quickly! The disease is currently affecting your plant.
2. **For Resolved Disease**: Monitor for reappearance. Treatment may be ongoing.
3. **For Healthy Plants**: Maintain good practices. Prevention is easier than cure!
4. **Low Signal**: Make sure camera/network connection is stable for best detection.
5. **Multiple Diseases**: The system tracks the latest detected disease. Check carefully!
6. **AI Tips**: Always reliable and based on the specific disease detected.

---

## 🔄 Camera Tips for Best Detection

1. **Angle**: Point directly at the diseased leaf/part
2. **Lighting**: Good natural light is best (avoid shadows)
3. **Cleanliness**: Keep camera lens clean
4. **Steadiness**: Keep camera still for 2-3 seconds
5. **Distance**: 20-30cm from plant is ideal
6. **Patience**: Wait for detection to confirm (usually < 5 seconds)

---

## 📞 Support

- **"Ask AI for Tips" button not responding?** 
  - Check internet connection
  - Wait for any loading spinner to finish
  - Try again in a few seconds

- **Disease not being detected?**
  - Try different angle/lighting
  - Get closer to the diseased part
  - Ensure camera is clean

- **Text is too small?**
  - Pinch-zoom on the card
  - Check your device's accessibility settings

---

## 🎓 Learn More

- Quick Guide: `PERSISTENT_DISEASE_QUICK_GUIDE.md`
- Technical Details: `PERSISTENT_DISEASE_UI_FIX.md`
- Visual Examples: `PERSISTENT_DISEASE_UI_VISUAL_COMPARISON.md`

---

**Last Updated**: Current Version
**Status**: ✅ Production Ready
**Version**: 2.0 - Persistent Disease Detection UI

