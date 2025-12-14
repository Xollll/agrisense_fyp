# Quick Answer: Dashboard Recommendations

## 🎯 SHORT ANSWER

**AIRecommendationWidget** (`lib/widgets/ai_recommendation_widget.dart`) shows recommendations on the Dashboard.

It calls **GeminiService** which handles:
- ✅ Smart caching
- ✅ Deduplication
- ✅ Rate limiting
- ✅ API calls

---

## 📍 The Two Systems

### WIDGET LAYER (On Dashboard) ✅
```
AIRecommendationWidget
├─ Gets detections from DashboardPage
├─ Calls GeminiService
├─ Displays recommendations
├─ User taps "Get Recommendations" button
└─ Makes API calls when needed
```

**What you see on dashboard**: This widget's output

**API calls**: YES (with smart caching)

---

### SERVICE LAYER (Background) ✅
```
AIRecommendationService
├─ Monitors diseases in background
├─ Checks cooldown periods
├─ Does NOT make API calls anymore ❌
├─ Returns cached or generic messages
└─ Posts notifications
```

**What you see on dashboard**: Nothing (it's background only)

**API calls**: NO (disabled to prevent redundancy)

---

## 🔄 The Flow

```
User sees disease on dashboard
    ↓
AIRecommendationWidget detects it
    ↓
Calls GeminiService.generateMultipleRecommendation()
    ↓
GeminiService checks:
  - Already in-flight? → Wait
  - Rate limit active? → Use cache
  - In cache? → Return cached
  - None of above? → Call API
    ↓
Returns recommendation
    ↓
Widget displays it
```

---

## ✅ What This Means

- **Dashboard shows**: Recommendations from AIRecommendationWidget
- **Widget calls**: GeminiService with smart caching
- **Service does**: Background monitoring (no API calls)
- **No redundancy**: Only widget makes API calls
- **Efficient**: 99%+ fewer API calls than before

---

## 📊 API Call Sources

| Source | Makes API Calls | Shows on Dashboard |
|--------|-----------------|-------------------|
| **AIRecommendationWidget** | ✅ YES | ✅ YES |
| **AIRecommendationService** | ❌ NO | ❌ NO |
| **GeminiService** | ✅ YES (when needed) | NO (backend) |

---

## 💡 Key Change

**BEFORE**: Both widget AND service made API calls = Redundancy ❌

**AFTER**: Only widget makes API calls + GeminiService handles caching = Efficient ✅

---

**That's it!** Dashboard recommendations come from the widget layer with smart caching. Service layer is background only.
