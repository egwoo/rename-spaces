# Spaces Renamer Overlay

## Background / Overview
Build a SIP-safe macOS menu bar app that lets you label Spaces and visually replaces the “Desktop 1/2/3” labels in Mission Control via an accessibility-based overlay.

## Goals
- Provide a menu bar UI to rename Spaces by index.
- Persist names between launches.
- Show custom labels aligned over Mission Control’s spaces bar when Mission Control is open.
- Target macOS 14.6.1; package as a normal `.app` bundle (side-loaded).

## Non-Goals
- Modifying system/private Space names in the Dock process.
- App Store distribution.
- Multi-user sync or iCloud sync (for now).

## Implementation Plan

### Phase 1: Core model + tests
[x] Scaffold Swift package with core module and app target.
[x] Add `SpaceNameStore` + `SpaceLabelParser` (index extraction) and persistence interface.
[x] Write XCTest coverage for name mapping, trimming/clearing, and label parsing.

### Phase 2: Menu bar UI
[x] Add SwiftUI menu bar app with editable list of space names.
[x] Wire UI to persistence + observable store.
[x] Add minimal settings (space count default + reset all).

### Phase 3: Mission Control overlay
[x] Add Accessibility permission check + helper to prompt user.
[x] Implement Dock AX traversal to find “Desktop N” label frames.
[x] Render overlay window with custom labels aligned to frames.
[x] Poll for Mission Control visibility and update/clear overlay appropriately.

### Phase 4: Packaging + docs
[x] Add build script to produce `.app` bundle.
[x] Document manual test steps and permissions.

## Open Questions
- Final typography/opacity to best match Mission Control.
- Default space count when none observed yet.

## Decision Log
- 2026-01-27: Use accessibility-based overlay (no SIP changes).
- 2026-01-27: Dock AX tree on 14.6.1 does not expose Mission Control labels; switch to heuristic overlay positioning (no OCR).
