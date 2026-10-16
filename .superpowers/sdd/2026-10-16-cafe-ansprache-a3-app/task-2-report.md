# Task 2 Report
Implemented lib/features/cafe/voice_segments.dart (VoiceLang, VoiceSegment, splitSegments) and cafe_voice.dart (GuestVoiceProfile, profileFor), test/features/cafe/voice_segments_test.dart (brief tests + empty/punctuation-only + all four profiles).
TDD: first RED run failed on missing implementation (compile error; initially also wrong package name nihongo vs nihongo_app, fixed in test). After implementing, 'gemischter Satz' failed (RED, real): ". Jetzt du." kept the leading "." after the ja segment. Fix: strip leading punctuation of a German segment that directly follows a ja segment. GREEN: 7/7.
Analyze: no new messages (1 pre-existing info in word_decomposition.dart). Full suite: +904 -8 (the 8 known mining_packs/ja failures).
Concern: stripping rule only applies right after a ja segment; German-only text keeps its punctuation as required.
