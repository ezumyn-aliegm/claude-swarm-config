# Backlog

Last groomed: 2026-03-28 (after TASK-002)

## P2 (Minor)

### BL-001: Button hover states inconsistent on Safari
- **Source:** TASK-002, Phase 5 (qa-user)
- **Filed:** 2026-03-29
- **Context:** Safari renders the hover transition with a 50ms delay compared to Chrome. Functional but feels sluggish.
- **Affected files:** `src/components/Button/Button.module.css`

### BL-002: Profile page missing empty state for bio field
- **Source:** TASK-002, Phase 5 (qa-user)
- **Filed:** 2026-03-29
- **Context:** When user has no bio, the field shows blank space instead of placeholder text.
- **Affected files:** `src/pages/Profile/Profile.tsx`

## P3 (Trivial)

### BL-003: Console warning about deprecated React lifecycle method
- **Source:** TASK-001, Phase 4 (reviewer)
- **Filed:** 2026-03-28
- **Context:** `componentWillMount` warning from third-party date picker library. Not our code.
- **Affected files:** `node_modules/react-datepicker` (upstream fix needed)

### BL-004: Tooltip z-index overlaps with modal backdrop on narrow screens
- **Source:** TASK-002, Phase 5 (browser-qa-tester)
- **Filed:** 2026-03-29
- **Context:** Only reproducible at viewport widths below 400px while a modal is open. Edge case.
- **Affected files:** `src/components/Tooltip/Tooltip.module.css`
