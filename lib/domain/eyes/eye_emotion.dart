/// Baseline character mood used by both behaviour and rendering.
///
/// A mood is a parameter profile, not a pre-recorded animation. The legacy
/// `EyeEmotion` name remains the public scene-content type for compatibility.
enum EyeEmotion { neutral, happy, sleepy, curious, annoyed, surprised }

typedef EyeMood = EyeEmotion;
