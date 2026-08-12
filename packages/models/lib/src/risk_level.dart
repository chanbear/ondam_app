/// How dangerous a piece of content (a message, a document) appears to be.
/// Distinct from [ReliabilityLevel], which describes how confident the AI is
/// in its own analysis — not how risky the analyzed content is.
enum RiskLevel { safe, caution, dangerous }
