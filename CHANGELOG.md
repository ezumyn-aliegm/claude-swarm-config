# Changelog

## [1.0.0] - 2026-03-31

### Added
- Initial release
- 11 specialized agents: researcher, architect, ux-designer, ui-designer, frontend-dev, implementer, tester, reviewer, qa-user, devils-advocate, browser-qa-tester
- Coordinator prompt with 8-phase workflow (Phase 0-7)
- TDD enforcement (Red, Green, Refactor)
- Structured devil's advocate with category rotation matrix
- Task triage matrix (type x size -> phases)
- Project state management (GitHub Projects/Issues or local file-based fallback)
- Versioned artifacts per phase transition
- Tiered regression testing (affected-path per fix, full suite at exit)
- P0/P1/P2/P3 severity level definitions
- Gate-specific review checklists (3 focused questions per gate)
- Re-triage protocol for mid-flight task reclassification
- Time guidelines per phase per size with 2x overage alerts
- Backlog management with grooming every 10 tasks
- Retro phase with active experiments
- Progressive disclosure in delivery summaries (3 levels)
- Shell aliases for different permission modes
- Install script
- Example project state files
