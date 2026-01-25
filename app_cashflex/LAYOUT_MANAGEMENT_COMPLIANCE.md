# Layout Management System - Compliance Guide

## 🎯 Overview

The Cash Flex app uses a **dynamic layout management system** controlled via the admin panel. This document ensures all UI changes remain compliant with the admin-controlled layout system.

---

## 📋 Current Home Page Structure

### Fixed Layout (Always Rendered - Not Admin Controlled)

1. **Top Bar** - Profile picture + Welcome text
2. **TOP ROW - Featured Games** (Fixed Position)
   - `promo-app-1` (Scratch & Earn) - Left side
   - `promo-app-2` (Fruit Match) - Right side
   - **Always displayed** regardless of admin panel settings
   - **Position:** Always at top (after welcome bar)
   - **Layout:** Horizontal row, side-by-side

3. **SECOND ROW - Wallet + Quick Actions** (Fixed Position)
   - **Left Side (50% width):** Wallet card (`home-wallet-card`)
   - **Right Side (50% width):** 
     - Watch & Earn button (top)
     - Follow & Earn button (bottom)
   - **Component ID:** `how-to-earn-follow-us`
   - **Position:** Always second row (after featured games)

### Dynamic Layout (Admin Controlled)

**Below the fixed rows**, components are rendered based on admin panel configuration:

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

## 🔧 Implementation Rules

### Rule 1: Fixed Components Must Always Render

**Components that are ALWAYS shown (not admin-controlled):**
- Top bar (profile + welcome)
- `promo-app-1` (Scratch & Earn) - Top row left
- `promo-app-2` (Fruit Match) - Top row right
- Wallet card - Second row left
- `how-to-earn-follow-us` - Second row right (if enabled in admin)

**Implementation:**
```dart
// In home_page.dart - Always render these BEFORE DynamicHomeContent
- ExternalApp1Card(isFeatured: true, height: 140) // promo-app-1
- ExternalApp2Card(isFeatured: true, height: 140) // promo-app-2
- HomeWalletCard // Wallet
- Watch & Earn + Follow & Earn buttons // how-to-earn-follow-us
```

### Rule 2: Skip Fixed Components in Dynamic Content

**In `dynamic_home_content.dart`:**
```dart
// Skip promo-app-1 and promo-app-2 in dynamic rendering
if (current.id == 'promo-app-1' || current.id == 'promo-app-2') {
  i++;
  continue; // Skip - already shown at top
}
```

### Rule 3: Respect Admin Panel Enable/Disable

**Fixed components can still be disabled:**
- If `promo-app-1` is disabled in admin → Don't show in top row
- If `promo-app-2` is disabled in admin → Don't show in top row
- If `how-to-earn-follow-us` is disabled → Don't show Watch & Follow buttons

**Implementation:**
```dart
// Check admin config before rendering fixed components
final shouldShowApp1 = LayoutService.shouldShowHomepageComponent(
  'promo-app-1',
  layoutConfig,
);
if (shouldShowApp1) {
  // Show ExternalApp1Card
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

## 📝 Required Code Changes

### File: `lib/pages/home_page.dart`

**Current Implementation:**
```dart
// TOP ROW - Featured Games: Scratch & Earn + Fruit Match
Padding(
  padding: AppTheme.paddingHorizontalMedium,
  child: Row(
    children: [
      Expanded(child: ExternalApp1Card(isFeatured: true, height: 140)),
      SizedBox(width: AppTheme.spacingMediumSmall),
      Expanded(child: ExternalApp2Card(isFeatured: true, height: 140)),
    ],
  ),
),
```

**Compliant Implementation (Check Admin Config):**
```dart
// TOP ROW - Featured Games: Scratch & Earn + Fruit Match
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

        // If both disabled, don't show row
        if (!showApp1 && !showApp2) {
          return const SizedBox.shrink();
        }

        // Show row with enabled apps
        return Padding(
          padding: AppTheme.paddingHorizontalMedium,
          child: Row(
            children: [
              if (showApp1)
                Expanded(
                  child: ExternalApp1Card(isFeatured: true, height: 140),
                ),
              if (showApp1 && showApp2)
                SizedBox(width: AppTheme.spacingMediumSmall),
              if (showApp2)
                Expanded(
                  child: ExternalApp2Card(isFeatured: true, height: 140),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  },
),
```

### File: `lib/components/home/dynamic_home_content.dart`

**Already Compliant:**
- ✅ Skips `promo-app-1` and `promo-app-2` in dynamic rendering
- ✅ Respects admin panel order for other components
- ✅ Handles special pairing rules

**No changes needed** - Already skips fixed components.

---

## 🎨 Admin Panel Behavior

### What Admins Can Control:

1. **Enable/Disable `promo-app-1`** (Scratch & Earn)
   - If disabled → Not shown in top row
   - If enabled → Always shown at top left

2. **Enable/Disable `promo-app-2`** (Fruit Match)
   - If disabled → Not shown in top row
   - If enabled → Always shown at top right

3. **Enable/Disable `how-to-earn-follow-us`**
   - If disabled → Watch & Earn + Follow & Earn buttons hidden
   - If enabled → Always shown in second row right

4. **Order of Other Components**
   - `promo-app-3`, `promo-app-4`, `gemee-jackpot`, etc.
   - Order in admin panel determines display order
   - Can add headings between components

5. **Badges and Styling**
   - Can add badges to any component
   - Can configure badge variants (hot, new, popular, etc.)

### What Admins CANNOT Control:

- ❌ Position of `promo-app-1` and `promo-app-2` (always top row)
- ❌ Position of Wallet card (always second row left)
- ❌ Position of Watch & Follow buttons (always second row right)
- ❌ Layout structure (horizontal row for featured games, etc.)

---

## ✅ Compliance Checklist

When making UI changes to Home page:

- [ ] Fixed components (promo-app-1, promo-app-2, wallet) always render first
- [ ] Fixed components check admin enable/disable state
- [ ] Dynamic content skips fixed components (promo-app-1, promo-app-2)
- [ ] Dynamic content respects admin panel order
- [ ] No hardcoded component positions (except fixed ones)
- [ ] All tap handlers, navigation, and logic unchanged
- [ ] Badge system works with admin panel configuration
- [ ] Special pairing rules (jackpot + 2 cards) still work

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

## 🚨 Important Notes

1. **Never remove the skip logic** in `dynamic_home_content.dart`
   - Without it, promo-app-1 and promo-app-2 would appear twice

2. **Always check enable/disable** before rendering fixed components
   - Admins should be able to hide featured games if needed

3. **Maintain backward compatibility**
   - Old layouts without promo-app-1/promo-app-2 should still work
   - Default to showing them if layout config is null

4. **Test with different admin configurations**
   - Enable/disable various components
   - Change order of dynamic components
   - Verify fixed components always appear in correct position

---

## 📱 Component ID Reference

| Component ID | Display Name | Position | Admin Control |
|------------|--------------|-----------|---------------|
| `promo-app-1` | Scratch & Earn | Fixed Top Left | Enable/Disable only |
| `promo-app-2` | Fruit Match | Fixed Top Right | Enable/Disable only |
| `how-to-earn-follow-us` | Watch & Follow buttons | Fixed Second Row Right | Enable/Disable only |
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

## 🎯 Summary

**Fixed Components (Always Top):**
- promo-app-1, promo-app-2 → Top row (horizontal)
- Wallet → Second row left
- Watch & Follow → Second row right

**Dynamic Components (Admin Controlled):**
- All other components → Below fixed rows
- Order, enable/disable, badges controlled by admin
- promo-app-1 and promo-app-2 skipped in dynamic rendering

**Compliance:**
- ✅ Check enable/disable for fixed components
- ✅ Skip fixed components in dynamic content
- ✅ Respect admin order for dynamic components
- ✅ Maintain all existing functionality
