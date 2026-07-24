# Explicit MVI Trace Extension

Read this file only when the user explicitly requests MVI Trace, chain recording, debug replay, or flow visualization. Trace is an independent task and must not be an incidental output of normal MVI initialization.

Confirm these facts before implementation:

| Area | Required confirmation |
| --- | --- |
| Scope | Which Features, Intents, or async feedback paths require recording? |
| Build | Is Trace enabled only in Debug builds? |
| Medium | Logs, files, an in-memory panel, or remote diagnostics? |
| Data | Which fields may be recorded, which are sensitive, and how are they redacted? |
| Lifecycle | Where is Trace registered and closed, how long are files retained, and what is the failure fallback? |

Invariants:

- Do not modify fixed `core/MVI.ts` or make the default MVI path depend on Trace.
- Trace must not read or mutate MVI State, select Plans, or change `side/fork/chain` dispatch results.
- Register Trace only for user-authorized Features and build variants. Unauthorized modules must contain no Trace import or initialization.
- Present the file list and registration/cleanup plan first. Ask when scope, medium, or privacy rules are unclear.
