# Layout Management Compliance Prompt

## 🎯 Purpose

This document provides a **comprehensive prompt** for ensuring all UI changes remain compliant with the admin-controlled layout management system in Cash Flex.

---

## 📋 System Overview

The Cash Flex app uses a **dynamic layout management system** where admins can:
- ✅ Enable/disable components
- ✅ Reorder components (except fixed ones)
- ✅ Add badges and headings
- ✅ Configure component-specific settings

---

## 🏗️ Home Page Structure

### Fixed Components (Always Render First - Position Cannot Change)

1. **Top Bar** - Profile picture + Welcome text
   - Not admin-controlled

2. **TOP ROW - Featured Games** (Fixed Position)
   - `promo-app-1` (Scratch & Earn) - Left side
   - `promo-app-2` (Fruit Match) - Right side
   - **Admin Control:** Enable/Disable only (position fixed)
   - **Layout:** Horizontal row, side-by-side
   - **If both disabled:** Row is hidden

3. **SECOND ROW - Wallet + Quick Actions** (Fixed Position)
   - **Left Side (50% width):** Wallet card (always shown)
   - **Right Side (50% width):** 
     - Watch & Earn button (top)
     - Follow & Earn button (bottom)
   - **Component ID:** `how-to-earn-follow-us`
   - **Admin Control:** Enable/Disable only (position fixed)

### Dynamic Components (Admin Controlled Order & Visibility)

**Below the fixed rows**, components render based on admin panel configuration:
- `promo-app-3` - Promotion App 3
- `promo-app-4` - Promotion App 4
- `gemee-jackpot` - Lucky Bonus
- `tic-tac-toe` - Catch Coins / Tic Tac Toe
- `math-quiz` - General Quiz
- `adjoe` - Play Games (Adjoe)
- `more-apps` - Trending Apps / More Apps
- `review-offers` - Review Offers
- `rate-us` - Rate Us card

**Note:** `promo-app-1` and `promo-app-2` are **skipped** in dynamic content rendering (already shown at top).

---

## ✅ Compliance Rules

### Rule 1: Fixed Components Must Always Render First

**Components that are ALWAYS shown first (not admin-controlled position):**
- Top bar (profile + welcome)
- `promo-app-1` (Scratch & Earn) - Top row left (if enabled)
- `promo-app-2` (Fruit Match) - Top row right (if enabled)
- Wallet card - Second row left (always shown)
- `how-to-earn-follow-us` - Second row right (if enabled)

**Implementation Pattern:**
```dart
// In home_page.dart - Always render these BEFORE DynamicHomeContent
// Check admin config for enable/disable
Consumer(
  builder: (context, ref, child) {
    final layoutAsync = ref.watch(layoutConfigProvider);
    return layoutAsync.when(
      data: (layoutConfig) {
        final showApp1 = LayoutService.shouldShowHomepageComponent(
          'promo-app-1',
          layoutConfig,
        );
        // Render if enabled
      },
      // ... handle loading/error states
    );
  },
),
```

### Rule 2: Skip Fixed Components in Dynamic Content

**In `dynamic_home_content.dart`:**
```dart
// CRITICAL: Skip promo-app-1 and promo-app-2 in dynamic rendering
if (current.id == 'promo-app-1' || current.id == 'promo-app-2') {
  i++;
  continue; // Skip - already shown at top
}
```

**Why:** Without this, `promo-app-1` and `promo-app-2` would appear twice (once fixed, once dynamic).

### Rule 3: Respect Admin Panel Enable/Disable

**Fixed components can still be disabled:**
- If `promo-app-1` is disabled in admin → Don't show in top row
- If `promo-app-2` is disabled in admin → Don't show in top row
- If `how-to-earn-follow-us` is disabled → Don't show Watch & Follow buttons

**Implementation:**
```dart
// Always check admin config before rendering fixed components
final shouldShow = LayoutService.shouldShowHomepageComponent(
  'promo-app-1',
  layoutConfig,
);
if (shouldShow) {
  // Show component
}
```

### Rule 4: Admin Panel Order Does NOT Affect Fixed Components

- `promo-app-1` and `promo-app-2` order in admin panel is **ignored**
- They always appear at the top in a horizontal row
- Other components respect admin panel order

### Rule 5: Dynamic Components Respect Admin Order

All components below the fixed rows:
- Render in order specified by admin panel
- Can be enabled/disabled via admin
- Can have badges, headings, etc. configured
- Respect special pairing rules (e.g., jackpot + 2 cards in row)

---

## 🔧 Required Code Patterns

### Pattern 1: Fixed Component with Admin Check

```dart
Consumer(
  builder: (context, ref, child) {
    final layoutAsync = ref.watch(layoutConfigProvider);
    return layoutAsync.when(
      data: (layoutConfig) {
        final shouldShow = LayoutService.shouldShowHomepageComponent(
          'component-id',
          layoutConfig,
        );
        if (!shouldShow) {
          return const SizedBox.shrink();
        }
        // Render component
        return YourComponent();
      },
      loading: () => YourComponent(), // Show while loading
      error: (_, __) => const SizedBox.shrink(),
    );
  },
),
```

### Pattern 2: Skip Fixed Components in Dynamic Rendering

```dart
// In dynamic_home_content.dart or similar
final enabledComponents = LayoutService.getEnabledComponents(
  layoutConfig.pageLayout.homepage,
);

// Filter out fixed components
final filteredComponents = enabledComponents.where((c) =>
    c.id != 'promo-app-1' && c.id != 'promo-app-2').toList();

// Render filtered components
```

### Pattern 3: Handle Multiple Fixed Components in Row

```dart
Consumer(
  builder: (context, ref, child) {
    final layoutAsync = ref.watch(layoutConfigProvider);
    return layoutAsync.when(
      data: (layoutConfig) {
        final showApp1 = LayoutService.shouldShowHomepageComponent(
          'promo-app-1',
          layoutConfig,
        );
        final showApp2 = LayoutService.shouldShowHomepageComponent(
          'promo-app-2',
          layoutConfig,
        );

        // If both disabled, hide row
        if (!showApp1 && !showApp2) {
          return const SizedBox.shrink();
        }

        // Show row with enabled apps
        return Row(
          children: [
            if (showApp1) Expanded(child: Component1()),
            if (showApp1 && showApp2) SizedBox(width: spacing),
            if (showApp2) Expanded(child: Component2()),
          ],
        );
      },
      // ... loading/error states
    );
  },
),
```

---

## 📝 Admin Panel Configuration

### Fixed Components (Cannot Be Reordered)

In `layout-management-form.tsx`:
```typescript
const FIXED_HOMEPAGE_COMPONENTS: ComponentId[] = [
  "promo-app-1",  // Fixed top row left
  "promo-app-2",  // Fixed top row right
  "how-to-earn-follow-us",  // Fixed second row right
]
```

**Admin Behavior:**
- ✅ Can enable/disable
- ✅ Can add badges
- ❌ Cannot drag/reorder
- ❌ Order field is ignored

### Draggable Components (Can Be Reordered)

```typescript
const DEFAULT_HOMEPAGE_COMPONENTS: ComponentId[] = [
  "promo-app-3",
  "promo-app-4",
  // ... other components
]
```

**Admin Behavior:**
- ✅ Can enable/disable
- ✅ Can drag/reorder
- ✅ Can add badges and headings
- ✅ Order field determines display order

---

## ✅ Compliance Checklist

When making UI changes to Home page:

- [ ] **Fixed components** (promo-app-1, promo-app-2, wallet) always render first
- [ ] **Fixed components** check admin enable/disable state using `LayoutService.shouldShowHomepageComponent()`
- [ ] **Dynamic content** skips fixed components (promo-app-1, promo-app-2) to avoid duplicates
- [ ] **Dynamic content** respects admin panel order using `LayoutService.getEnabledComponents()`
- [ ] **No hardcoded component positions** (except fixed ones)
- [ ] **All tap handlers, navigation, and logic unchanged** (UI only changes)
- [ ] **Badge system** works with admin panel configuration
- [ ] **Special pairing rules** (jackpot + 2 cards) still work
- [ ] **Loading states** show components (or placeholders) while layout config loads
- [ ] **Error states** gracefully handle missing layout config

---

## 🚨 Critical Warnings

### ⚠️ Never Remove Skip Logic

**In `dynamic_home_content.dart`:**
```dart
// CRITICAL: This must always be present
if (current.id == 'promo-app-1' || current.id == 'promo-app-2') {
  i++;
  continue; // Skip - already shown at top
}
```

**Without this:** Components appear twice (once fixed, once dynamic).

### ⚠️ Always Check Enable/Disable

**Never hardcode component visibility:**
```dart
// ❌ WRONG - Ignores admin settings
ExternalApp1Card()

// ✅ CORRECT - Respects admin settings
if (LayoutService.shouldShowHomepageComponent('promo-app-1', layoutConfig)) {
  ExternalApp1Card()
}
```

### ⚠️ Maintain Backward Compatibility

**Handle null layout config:**
```dart
layoutAsync.when(
  data: (layoutConfig) {
    // Default to showing if config is null
    final shouldShow = layoutConfig == null || 
      LayoutService.shouldShowHomepageComponent('component-id', layoutConfig);
    // ...
  },
  loading: () => /* Show component while loading */,
  error: (_, __) => /* Show component on error or hide */,
)
```

---

## 📱 Component ID Reference

| Component ID | Display Name | Position | Admin Control |
|------------|--------------|-----------|---------------|
| `promo-app-1` | Scratch & Earn | **Fixed** Top Left | Enable/Disable only |
| `promo-app-2` | Fruit Match | **Fixed** Top Right | Enable/Disable only |
| `how-to-earn-follow-us` | Watch & Follow buttons | **Fixed** Second Row Right | Enable/Disable only |
| `promo-app-3` | Promotion App 3 | Dynamic (admin order) | Full control |
| `promo-app-4` | Promotion App 4 | Dynamic (admin order) | Full control |
| `gemee-jackpot` | Lucky Bonus | Dynamic (admin order) | Full control |
| `tic-tac-toe` | Catch Coins | Dynamic (admin order) | Full control |
| `math-quiz` | General Quiz | Dynamic (admin order) | Full control |
| `adjoe` | Play Games | Dynamic (admin order) | Full control |
| `more-apps` | More Apps | Dynamic (admin order) | Full control |
| `review-offers` | Review Offers | Dynamic (admin order) | Full control |
| `rate-us` | Rate Us | Dynamic (admin order) | Full control |

---

## 🔄 Migration Notes

### For Existing Layouts:

If admin panel has `promo-app-1` or `promo-app-2` configured with specific order:
- **Order is ignored** - They always appear at top
- **Enable/disable is respected** - Can hide them via admin
- **Badge configuration is respected** - Badges still work

### For New Layouts:

- Admins can still add `promo-app-1` and `promo-app-2` to layout config
- They will appear in admin panel UI
- But they will always render at top (if enabled)
- Order field in admin panel is ignored for these two

---

## 🎯 Summary

**Fixed Components (Always Top):**
- `promo-app-1`, `promo-app-2` → Top row (horizontal)
- Wallet → Second row left
- `how-to-earn-follow-us` → Second row right

**Dynamic Components (Admin Controlled):**
- All other components → Below fixed rows
- Order, enable/disable, badges controlled by admin
- `promo-app-1` and `promo-app-2` skipped in dynamic rendering

**Compliance:**
- ✅ Check enable/disable for fixed components
- ✅ Skip fixed components in dynamic content
- ✅ Respect admin order for dynamic components
- ✅ Maintain all existing functionality
- ✅ Handle loading and error states gracefully

---

## 📚 Related Files

- **App:** `lib/pages/home_page.dart` - Main home page
- **App:** `lib/components/home/dynamic_home_content.dart` - Dynamic content renderer
- **App:** `lib/services/layout_service.dart` - Layout service utilities
- **Admin:** `server_cashflex/src/components/layout-management-form.tsx` - Admin panel form
- **Admin:** `server_cashflex/src/app/api/admin/layouts/route.ts` - Layout API

---

## 💡 Quick Reference

**Check if component should show:**
```dart
LayoutService.shouldShowHomepageComponent('component-id', layoutConfig)
```

**Get enabled components in order:**
```dart
LayoutService.getEnabledComponents(layoutConfig.pageLayout.homepage)
```

**Find component config:**
```dart
LayoutService.findComponentConfig('component-id', layoutConfig.pageLayout.homepage)
```

**Skip fixed components:**
```dart
if (component.id == 'promo-app-1' || component.id == 'promo-app-2') {
  continue; // Skip
}
```
