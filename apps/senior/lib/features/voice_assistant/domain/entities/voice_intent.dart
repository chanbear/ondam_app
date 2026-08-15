/// A recognized voice command, mapped to one of the small set of onboard
/// features the voice assistant can trigger in this phase
/// (technical-decisions.md §5-2 OPEN QUESTIONS 10 DECIDED — client keyword
/// matching only, no server AI). `welfare_center` isn't wired here because
/// that feature doesn't exist yet (still `.gitkeep`-only).
enum VoiceIntent { documentScan, messageCheck, emergencyHelp, unrecognized }
