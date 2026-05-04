---
name: Zenith Archive
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c6c5d4'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#908f9d'
  outline-variant: '#454652'
  surface-tint: '#bcc2ff'
  primary: '#bcc2ff'
  on-primary: '#152383'
  primary-container: '#283593'
  on-primary-container: '#9aa5ff'
  inverse-primary: '#4955b3'
  secondary: '#a2d3a4'
  on-secondary: '#0a3817'
  secondary-container: '#24502c'
  on-secondary-container: '#91c193'
  tertiary: '#ffb59e'
  on-tertiary: '#54200f'
  tertiary-container: '#682f1d'
  on-tertiary-container: '#e8977e'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#dfe0ff'
  primary-fixed-dim: '#bcc2ff'
  on-primary-fixed: '#000c62'
  on-primary-fixed-variant: '#303c9a'
  secondary-fixed: '#bdefbe'
  secondary-fixed-dim: '#a2d3a4'
  on-secondary-fixed: '#002109'
  on-secondary-fixed-variant: '#24502c'
  tertiary-fixed: '#ffdbd0'
  tertiary-fixed-dim: '#ffb59e'
  on-tertiary-fixed: '#390c01'
  on-tertiary-fixed-variant: '#713623'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 57px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  title-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  label-md:
    fontFamily: workSans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  margin-desktop: 24px
  gutter: 16px
  container-padding: 28px
---

## Brand & Style

The design system is anchored in the concept of "Digital Stoicism." It transforms a personal media library from a chaotic list into a curated sanctuary. The brand personality is scholarly yet contemporary, prioritizing clarity over decoration to evoke a sense of calm and control.

By blending **Material 3** principles with **Minimalism**, the system achieves an "offline-first" feel—suggesting that the content is locally owned, permanent, and accessible without distraction. The aesthetic avoids the loud, algorithm-driven visuals of streaming services, opting instead for a deliberate, archival quality that rewards long-term organization.

## Colors

This design system utilizes a high-contrast palette to ensure legibility across varied lighting conditions. The **Deep Indigo** primary color provides a stable, structural foundation, while the **Soft Emerald** secondary color is reserved for positive actions and success states, reflecting growth and collection.

In Dark Mode, surfaces use deep charcoal tones rather than pure black to maintain Material 3 tonal elevation visibility. In Light Mode, the system uses stark whites with cool grey accents to mimic a clean gallery environment. Functional colors (error, warning) are desaturated to maintain the minimalist harmony.

## Typography

The typography system relies on **Inter** for its modern, neutral characteristics and exceptional readability at varying scales. It is used for all primary UI elements and body copy to maintain a systematic, utilitarian feel.

**Work Sans** is introduced as a secondary label font for metadata and technical details (e.g., file sizes, release years, ISBNs) because its slightly wider apertures provide a grounded, professional contrast to the verticality of Inter. Typographic hierarchy is enforced through weight and color rather than excessive size shifts, keeping the interface "quiet."

## Layout & Spacing

This design system employs a **fluid grid** model based on an 8px rhythmic increment. The layout philosophy prioritizes generous margins and "breathing room" to reinforce the minimalist aesthetic. 

Content is organized into logical clusters using surface containers. On mobile devices, a single-column layout with 16px margins is standard, while tablet and desktop views expand into multi-column masonry grids for media cards. Spacing between unrelated sections is intentionally large (32px-48px) to reduce visual noise and guide the user's focus toward one category of media at a time.

## Elevation & Depth

Visual hierarchy in this design system is conveyed through **Tonal Layers** rather than heavy shadows, adhering to modern Material 3 standards. 

1.  **Level 0 (Base):** The main background color.
2.  **Level 1 (Surface):** Used for large cards and navigation bars.
3.  **Level 2 (Surface Container):** Used for nested elements or active states.
4.  **Level 3 (Floating):** Reserved exclusively for the Floating Action Button (FAB) and Modals.

Shadows are used sparingly and are extremely diffused (ambient), with a 10% opacity of the Primary color to give a subtle "lift" without breaking the flat, clean aesthetic.

## Shapes

The defining characteristic of this design system is the **large rounded corner (28dp)**. This radius is applied to all primary containers, including media cards, bottom sheets, and modal dialogues. 

Small UI elements like buttons, input fields, and chips use a smaller, proportional radius (12px) to maintain a cohesive language without appearing overly "bubbly." The extreme roundness of the main containers creates a friendly, tactile feel that softens the high-contrast color palette and technical nature of content management.

## Components

### Floating Action Button (FAB)
The FAB is the most prominent element, utilizing a **Large FAB** spec (96x96dp) with a 28dp radius. It should use the Primary Deep Indigo color in Light mode and the Secondary Soft Emerald in Dark mode to ensure it remains the focal point for adding new content.

### Media Cards
Cards are the heart of the system. They feature a 28dp corner radius, no borders, and use Level 1 Surface tonal elevation. Text metadata is placed below the image container to keep the visual "shelving" clean and mimic physical media.

### Lists & Inputs
Lists use high-contrast dividers (1px) with significant vertical padding (16dp). Input fields are "Filled" style with a 12dp top-corner radius and a heavy bottom indicator line, providing a stable, "heavy" feel for data entry.

### Navigation
The Bottom Navigation bar uses the Material 3 "Pill" indicator for active states, utilizing the Soft Emerald color at 20% opacity to highlight the selection without overwhelming the Deep Indigo icons.