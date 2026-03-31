# TASK-001: Fix auth redirect loop on expired sessions

## Classification
- **Type:** Bug fix
- **Size:** S
- **Phase:** 7
- **Status:** done
- **Created:** 2026-03-28
- **Updated:** 2026-03-28
- **Branch:** fix/task-001-auth-redirect
- **PR:** #47

## Description
Users reported being stuck in an infinite redirect loop when their session token expires while on a protected page. The app redirects to /login, which detects a stale token, tries to redirect to the original page, which redirects back to /login.

## Artifacts
- Research Brief: artifacts/TASK-001-research-brief-v1.md
- Delivery Summary: artifacts/TASK-001-delivery-summary.md

## Phase Log
| Phase | Started | Completed | Notes |
|-------|---------|-----------|-------|
| 0 - Triage | 2026-03-28 10:00 | 2026-03-28 10:01 | Bug fix/S |
| 1 - Understand | 2026-03-28 10:01 | 2026-03-28 10:04 | Impact: auth middleware, 3 route guards |
| 3 - Red | 2026-03-28 10:04 | 2026-03-28 10:08 | 4 failing tests (2 unit, 2 integration) |
| 3.5 - Green | 2026-03-28 10:08 | 2026-03-28 10:15 | All 4 tests passing |
| 4 - Refactor | 2026-03-28 10:15 | 2026-03-28 10:18 | Reviewer: clean. Architect: approved. |
| 6 - Deliver | 2026-03-28 10:18 | 2026-03-28 10:20 | Shipped. PR #47 merged. |

## DA Challenge Summary
| Phase | Category | Concern | Blocking? | Disposition |
|-------|----------|---------|-----------|-------------|
| 1 | edge cases | What about concurrent tab sessions with different token states? | advisory | acknowledged — logged as BL-005, out of scope for this fix |
| 3.5 | correctness | The fix clears the token before redirect — does this break "remember me" functionality? | advisory | addressed — verified remember-me uses a separate persistent cookie |
