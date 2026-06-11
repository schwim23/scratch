# Scratch — feature backlog

## 🎯 Core experience (v1.1 — shipped)

### ✅ Silence-triggered auto-stop
Detect when the user stops speaking for N seconds (configurable, default 4s) and
auto-finalize into the review sheet. Removes the friction of reaching back to hit
stop — huge for capture-while-walking or hands-busy moments.
*Implementation:* `SilenceGate` (pure, unit-tested) fed by mic levels + transcript
activity inside `RecorderEngine`; longer grace period (10s) before any speech is
detected so it never cuts off someone gathering their thoughts. Settings sheet
(gear in library) for toggle + duration.

### ✅ Quick-capture: Action button, Siri, deep link, widgets
Zero-friction entry into recording:
- `StartRecordingIntent` App Intent + App Shortcut → bindable to the iPhone
  **Action button** (Settings → Action Button → Shortcut → "New Take") and Siri
- `scratch://record` URL scheme for automations
- Lock-screen accessory widget and iOS 18 Control Center **control widget**
  (`ScratchWidgets` extension target)

### ✅ Instant re-record
"Redo" on the review screen discards the take and immediately starts a fresh one —
for when you stumble and just want to go again.

## 🤖 AI layer (next)

### LLM post-processing on save
Background pass over the transcript after save:
- generate a better title than first-words
- extract action items, surface as a badge on the note row
- auto-tag (idea / task / meeting / personal)

*Notes:* needs a privacy decision — Apple's on-device foundation models keep the
"nothing leaves your phone" story; Claude API gives better quality but must be
opt-in with a key. Pairs with exposing notes as an **MCP resource** so other
agents can query them.

### "Clean it up" one-tap action
Button on the review screen that sends the raw transcript to Claude and returns a
lightly cleaned version — fixes filler words, run-ons, false starts while
preserving voice. Opt-in, non-destructive (original kept alongside).

### Smart (semantic) search
Embeddings over transcripts so "find the note where I talked about the Uber pitch
deck" works even if the recording said "the presentation for the ads team."
*Notes:* start with `NLEmbedding`/NaturalLanguage on-device sentence embeddings +
cosine ranking blended with the existing full-text match; no server required.

## Later / ideas
- iCloud sync (CloudKit flip — blocked on paid developer account)
- Apple Watch capture
- App Store release: privacy policy, screenshots, review pass
