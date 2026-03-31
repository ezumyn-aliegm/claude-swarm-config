# Changelog

## [1.1.0] - 2026-03-31

### Added
- Enforcement hooks system with 8 shell hooks + 3 prompt-based hooks
- `enforce-tdd.sh` — blocks implementation code during test-writing phases
- `enforce-test-before-fix.sh` — requires failing test before bug fixes in Phase 5
- `enforce-phase-gate.sh` — blocks code changes during approval gates
- `enforce-no-direct-impl.sh` — prevents coordinator from writing code directly
- `enforce-research-first.sh` — blocks implementation agents without research brief
- `enforce-regression.sh` — warns about targeted tests needing full regression
- `update-task-state.sh` — tracks agent invocations for DA coverage
- Prompt-based hooks: DA coverage check, state update check, agent output review
- `settings.json` with full hook configuration
- Updated install script to copy hooks and settings

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
