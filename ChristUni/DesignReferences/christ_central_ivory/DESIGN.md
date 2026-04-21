```markdown
# Design System Specification: Academic Elegance

## 1. Overview & Creative North Star: "The Scholarly Sanctuary"
The objective of this design system is to transcend the utility of a standard student portal and create a digital environment that feels like a premium, quiet study hall. We are moving away from "App-like" interfaces toward a **"High-End Editorial"** experience.

**Creative North Star: The Scholarly Sanctuary**
This system is defined by breathing room, intentional asymmetry, and a "paper-on-stone" tactile feel. We reject the "boxed-in" nature of traditional mobile apps. Instead, we use expansive white space and tonal depth to guide the student’s eye. The interface shouldn’t feel like a tool; it should feel like a curated academic journal—authoritative, calm, and sophisticated.

---

## 2. Colors: Tonal Depth & The University Legacy
We use a "Darkish White" palette. By avoiding pure #FFFFFF for backgrounds, we reduce eye strain and allow our "Crisp White" cards to physically pop from the screen.

### The Palette
*   **Surface Foundation:** `surface` (#f9f9fe) – The base "off-white" for all screens.
*   **The Academic Primary:** `primary` (#001e40) – A deep, regal navy representing Christ University’s authority.
*   **The Golden Accent:** `secondary` (#735c00) – Used sparingly for "Gold Standard" moments: achievements, high-priority notifications, or active states.
*   **Tonal Accents:** `tertiary` (#381300) – A deep burnt umber used for warmth in editorial headlines.

### The "No-Line" Rule
**Explicit Instruction:** 1px solid borders are strictly prohibited for sectioning. 
Boundaries must be defined by background color shifts. To separate a header from a body, transition from `surface` to `surface-container-low`. We define space through mass and tone, not outlines.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of fine stationery:
1.  **Level 0 (Base):** `surface` (#f9f9fe)
2.  **Level 1 (Sectioning):** `surface-container-low` (#f3f3f8)
3.  **Level 2 (The "Crisp Card"):** `surface-container-lowest` (#ffffff) - This is your primary interaction surface.
4.  **Level 3 (Elevated Content):** `surface-bright` (#f9f9fe) - For floating headers or modals.

### The "Glass & Gradient" Rule
For primary actions, use a subtle "Soul Gradient" transitioning from `primary` (#001e40) to `primary_container` (#003366). For floating navigation bars, use `surface_container_lowest` at 80% opacity with a `20px` backdrop blur to create a frosted-glass effect that feels integrated into the environment.

---

## 3. Typography: Editorial Authority
We utilize a pairing of **Manrope** (for structural headlines) and **Inter** (for high-legibility body text). This creates a "New York Times meets Apple" aesthetic.

*   **Display (Manrope):** `display-lg` (3.5rem). Use this for "Hero" moments like a student’s GPA or a "Good Morning" greeting. Use tight letter-spacing (-0.02em).
*   **Headline (Manrope):** `headline-sm` (1.5rem). Used for card titles. It should feel bold and intentional.
*   **Body (Inter):** `body-md` (0.875rem). Our workhorse. Use `on_surface_variant` (#43474f) for secondary body text to maintain a soft contrast.
*   **Label (Inter):** `label-sm` (0.6875rem). All-caps with +0.05em tracking for secondary metadata (e.g., "ATTENDANCE" or "CLASSROOM").

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows are often "dirty." In this system, we use light and tone.

*   **The Layering Principle:** To create a card, place a `surface-container-lowest` (#ffffff) shape on a `surface` (#f9f9fe) background. This 2-point hex difference creates a "natural" lift.
*   **Ambient Shadows:** If a card represents a critical action (like an upcoming Exam), apply a shadow:
    *   **Blur:** 24px | **Y-Offset:** 8px | **Opacity:** 4% | **Color:** `primary` (#001e40). 
    *   *Note: Using a navy-tinted shadow makes the element feel like it belongs to the university brand.*
*   **The "Ghost Border" Fallback:** If accessibility requires a border, use `outline_variant` at 15% opacity. It should be felt, not seen.

---

## 5. Components: Intentional Primitives

### Cards (The Student Portfolio)
*   **Style:** `surface-container-lowest` (#ffffff) with `xl` (1.5rem) corner radius.
*   **Rule:** No dividers. Use 24px of internal padding and 16px of vertical spacing between content blocks to create "Visual Columns."

### Buttons (The Primary Action)
*   **Primary:** `primary` (#001e40) fill with `on_primary` (#ffffff) text. Corner radius: `full`.
*   **Secondary:** `surface-container-high` (#e8e8ed) fill with `primary` text. No border.

### Inputs (The Inquiry)
*   **Style:** Minimalist underline or soft-tinted box. Use `surface-container-highest` (#e2e2e7) as the fill. 
*   **Focus State:** Shift background to `surface-container-lowest` and add a 1px "Ghost Border" of `primary`.

### Navigation (The Floating Dock)
Instead of a standard bottom tab bar, use a floating dock style. 
*   **Fill:** `surface_container_lowest` (80% opacity) + Backdrop Blur.
*   **Active State:** A `secondary` (Gold) dot indicator below the icon, rather than changing the icon color entirely.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** embrace asymmetry. Align a "Headline" to the left and a "See All" label to the far right with significant white space between them.
*   **Do** use `primary_fixed_dim` (#a7c8ff) for subtle background tints on academic alerts.
*   **Do** use the `lg` (1rem) and `xl` (1.5rem) radius for almost everything; it communicates modern approachability.

### Don’t:
*   **Don't** use pure black (#000000). Always use `on_surface` (#1a1c1f) for text to keep the "Editorial" softness.
*   **Don't** use lines to separate list items. Use an 8px vertical gap and a slight tonal shift on tap.
*   **Don't** overcrowd. If a screen feels full, it’s a failure of the system. Move content into a secondary "drill-down" layer.

---

## 7. Signature Interaction: The Soft Entry
All card transitions should use a **Cubic Bezier (0.2, 0, 0, 1.0)** "Ease-Out" motion. Elements should not "pop" in; they should slide up 10px while fading from 0% to 100% opacity, mimicking the grace of a physical page turn.```