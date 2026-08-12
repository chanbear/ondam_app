/// User-facing confidence in an AI analysis result — "높음/보통/낮음" per
/// ui-spec.md. Never derived from or equal to a raw model confidence score;
/// the mapping from raw score to this enum happens in the Senior app's
/// `analysis` feature (domain layer), not here.
enum ReliabilityLevel { high, medium, low }
