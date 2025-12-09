# Project Files Reference Guide

## 📋 What Each File Does

### 🏠 Core Application

**`lib/main.dart`** (531 lines) ✅ ACTIVE
- App initialization and setup
- MainWrapper with navigation
- DashboardPage with live detection polling
- About/Help dialogs
- Multi-provider setup

---

## 📄 Pages (4 pages)

**`lib/pages/dashboard.dart`** (in main.dart) ✅ ACTIVE
- Live camera stream display
- Real-time AI detections overlay
- AI recommendations widget
- Server health checking
- Auto-stream restart on server reconnect

**`lib/pages/settings_page.dart`** (261 lines) ✅ ACTIVE
- Live Detection toggle
- Update Interval selection
- Notifications settings
- Offline Mode toggle
- App version info
- Bottom padding for FAB menu

**`lib/pages/statistics_page_redesigned.dart`** (1100+ lines) ✅ ACTIVE
- Disease statistics charts
- Timeline data visualization
- Export to CSV button
- Export to PDF button
- Health percentage display
- Refresh data functionality
- Bottom padding for FAB menu

**`lib/pages/history_page.dart`** (150+ lines) ✅ ACTIVE
- Detection history list
- Filter by date/disease
- Individual detection details
- Supabase data fetching
- Bottom padding for FAB menu

---

## 🎨 Widgets (8 widgets, 7 active)

**`lib/widgets/enhanced_app_bar.dart`** ✅ ACTIVE
- Modern gradient app bar
- Dynamic theme colors
- Status indicators
- Used in: Dashboard, Settings, Statistics, History

**`lib/widgets/floating_menu_button.dart`** ✅ ACTIVE
- Floating action button for navigation
- Animated menu with dropdown
- Quick actions (Dark Mode, About, Help)
- Page navigation items
- Primary navigation method (replaced drawer)

**`lib/widgets/live_stream_widget.dart`** ✅ ACTIVE
- MJPEG stream display
- Detection overlays on video
- Loading state
- Error handling
- Server status indicator
- Used in: Dashboard

**`lib/widgets/mjpeg_stream.dart`** ✅ ACTIVE
- Low-level MJPEG protocol handler
- HTTP stream reading
- Frame buffer management
- Auto-reconnect logic
- Used by: LiveStreamWidget

**`lib/widgets/animated_live_indicator.dart`** ✅ ACTIVE
- Animated "LIVE" status badge
- Pulsing animation
- Used in: LiveStreamWidget

**`lib/widgets/ai_recommendation_widget.dart`** ✅ ACTIVE
- AI treatment recommendations display
- Calls Gemini API for insights
- Shows disease-specific advice
- Used in: Dashboard

**`lib/widgets/modern_card.dart`** ✅ ACTIVE
- Reusable card component
- Rounded corners, shadows
- Customizable content
- Used in: Settings, LiveStreamWidget

**`lib/widgets/disease_chart.dart`** ❌ UNUSED
- Disease statistics charts
- Uses fl_chart library
- NOT IMPORTED BY ANYTHING
- Can be deleted: **YES**

---

## 🔧 Services (11 services, all active)

**`lib/detection_service.dart`** ✅ ACTIVE
- Fetches AI detections from Flask server
- HTTP communication
- Retry logic via http_retry_service
- Used by: Dashboard, LiveStreamWidget

**`lib/gemini_service.dart`** ✅ ACTIVE
- Calls Google Gemini API
- Gets AI treatment recommendations
- Input validation via validation_service
- Used by: AIRecommendationWidget, DetectionManager

**`lib/services/detection_manager.dart`** ✅ ACTIVE
- Background polling service
- Runs every 10 seconds
- Fetches detections and recommendations
- Caches results locally
- Used by: main.dart

**`lib/services/local_cache_service.dart`** ✅ ACTIVE
- Local storage with SharedPreferences
- Offline data caching
- JSON serialization
- Used by: DetectionManager, SyncService

**`lib/services/sync_service.dart`** ✅ ACTIVE
- Syncs local cache with Supabase
- Network status monitoring
- Two-way data synchronization
- Used by: main.dart

**`lib/services/supabase_service.dart`** ✅ ACTIVE
- Supabase database operations
- Fetch/insert/update detections
- Detection history queries
- Used by: SyncService, StatisticsService, HistoryPage

**`lib/services/statistics_service.dart`** ✅ ACTIVE
- Analytics calculations
- Disease stats aggregation
- Timeline data processing
- Used by: StatisticsProvider

**`lib/services/export_service.dart`** ✅ ACTIVE (FIXED)
- CSV export functionality
- PDF report generation
- File sharing
- Used by: StatisticsPage (now properly integrated!)

**`lib/services/http_retry_service.dart`** ✅ ACTIVE
- HTTP retry mechanism
- Exponential backoff
- Connection timeout handling
- Used by: detection_service, gemini_service

**`lib/services/validation_service.dart`** ✅ ACTIVE
- Input validation helper
- Data format checking
- Used by: gemini_service

**`lib/theme/theme_service.dart`** ✅ ACTIVE
- Theme persistence (SharedPreferences)
- Light/Dark mode storage
- Used by: main.dart, ThemeProvider

---

## 📊 Providers (2 providers, all active)

**`lib/providers/app_settings_provider.dart`** ✅ ACTIVE
- App settings state management
- Live updates toggle
- Notification settings
- Offline mode toggle
- Used by: main.dart, SettingsPage, DetectionManager

**`lib/providers/statistics_provider.dart`** ✅ ACTIVE
- Statistics state management
- Disease stats caching
- Timeline data caching
- Summary statistics
- Used by: main.dart, StatisticsPage

---

## 🎨 Theme (3 files, all active)

**`lib/theme/app_theme.dart`** ✅ ACTIVE
- Light theme definition
- Dark theme definition
- Color schemes
- Typography
- Used by: main.dart, SettingsPage

**`lib/theme/theme_provider.dart`** ✅ ACTIVE
- Theme state management
- Dark/Light toggle
- Used by: main.dart

---

## 📦 Config

**`lib/config/network_config.dart`** ✅ (mentioned in gemini_service.dart)
- Network configuration constants
- API endpoints
- Timeouts

---

## Summary Table

| Category | File | Status | Purpose |
|----------|------|--------|---------|
| **Core** | main.dart | ✅ | App initialization & navigation |
| **Pages** | settings_page.dart | ✅ | Settings UI |
| | statistics_page_redesigned.dart | ✅ | Analytics & export |
| | history_page.dart | ✅ | Detection history |
| | dashboard (in main.dart) | ✅ | Live stream & recommendations |
| **Widgets** | enhanced_app_bar.dart | ✅ | Modern top bar |
| | floating_menu_button.dart | ✅ | Navigation FAB |
| | live_stream_widget.dart | ✅ | Video stream display |
| | mjpeg_stream.dart | ✅ | Stream rendering |
| | animated_live_indicator.dart | ✅ | Live status badge |
| | ai_recommendation_widget.dart | ✅ | AI suggestions UI |
| | modern_card.dart | ✅ | Reusable card |
| | disease_chart.dart | ❌ | Unused charts |
| **Services** | detection_service.dart | ✅ | API client |
| | gemini_service.dart | ✅ | AI API client |
| | detection_manager.dart | ✅ | Background polling |
| | local_cache_service.dart | ✅ | Offline storage |
| | sync_service.dart | ✅ | Data sync |
| | supabase_service.dart | ✅ | Database |
| | statistics_service.dart | ✅ | Analytics |
| | export_service.dart | ✅ | CSV/PDF export |
| | http_retry_service.dart | ✅ | Retry logic |
| | validation_service.dart | ✅ | Input validation |
| | theme_service.dart | ✅ | Theme storage |
| **Providers** | app_settings_provider.dart | ✅ | Settings state |
| | statistics_provider.dart | ✅ | Analytics state |
| **Theme** | app_theme.dart | ✅ | Theme definitions |
| | theme_provider.dart | ✅ | Theme state |

---

## 🎯 Bottom Line

**27 out of 28 files are actively used and working together!**

The only candidate for deletion is:
- `lib/widgets/disease_chart.dart` (unused, 315 lines)

**All other files serve an important purpose in the application.** ✅
