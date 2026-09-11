# Nocrim project instructions

## Story editing and implementation

- The user-facing story master is `녹림전생_통합설정집.md` in the project root (document ID `NOCRIM-STORY-MASTER`). Read it for narrative, character, setting, event, or ending changes. It is a single portable Markdown document intended for editing in ordinary Chat and later returning to this workspace.
- The user's latest explicit request takes precedence. A newly supplied edited master or replacement section must be compared with the local master and current Godot code. Unchanged implementation appendix text is a baseline, not evidence that later proposed changes have already shipped.
- `현재 구현` records a verified baseline; `기획 기준` guides writing; `확장 초안` is not authorized implementation by itself; `반영 요청` is intended implementation when the user asks to apply the document. Directly edited prose also expresses change intent when supplied with an apply request. Do not require the user to encode conditions or tag every paragraph.
- Preserve stable character, region, event, ending IDs when renaming display text. Review prerequisites, exclusions, affordable fallback choices, event order, recruitment/release, defeat/recapture, ending priorities, resource effects, UI text fit, and saved-game compatibility for affected changes.
- Make unambiguous authorized changes without repeated approval. Ask only about material conflicting intent; continue independent work. Do not implement all draft expansions merely because the user requests one section.
- Implement narrative data in `godot/data/world.json`, presentation text in `godot/scripts/story.gd`, and required behavior in the relevant Godot scripts. Do not silently treat prose changes as mechanically implemented rules. Validate at the scope appropriate to the change.
- Update the master change log with actual applied scope, relevant files, validation, save compatibility, and remaining work. Mark `반영 완료` only after actual implementation and verification. Never regenerate the entire master from code over user-authored edits. Preserve unaffected sections when merging partial Chat revisions.
- Other design documents are historical/supporting references; when they conflict with the master, inspect current code and user intent and record the discrepancy.

## Delivery

- The test entry point is root `play.bat`. Keep it working with the Godot source and bundled local engine. Do not produce ZIP releases by default.
- Ren'Py sources and tooling have been removed; do not restore them for new work.
- Preserve unrelated user files, particularly `웹소설_창작_마스터팩_v2.0`.
- Do not store API keys or secrets in the story master or source. Document editing alone does not automatically synchronize from another Chat or execute game changes.
