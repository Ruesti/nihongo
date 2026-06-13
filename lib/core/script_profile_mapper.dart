import 'dart:convert';

import 'package:nihongo_app/core/db/learning_db.dart';
import 'package:nihongo_app/core/script_profile.dart';

ScriptProfile profileFromRow(ScriptProfileRow row) => ScriptProfile(
      id: row.id,
      scriptType: ScriptType.values.byName(row.scriptType),
      direction: Direction.values.byName(row.direction),
      decomposability: Decomposability.values.byName(row.decomposability),
      positionalForms: row.positionalForms,
      toneSystem: ToneSystem.values.byName(row.toneSystem),
      needsScriptTrack: row.needsScriptTrack,
      transliteration: row.transliteration,
      inputMethods: (jsonDecode(row.inputMethodsJson) as List<dynamic>)
          .map((s) => InputMethod.values.byName(s as String))
          .toList(),
    );
