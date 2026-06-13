import 'package:nihongo_app/core/ladder/rung_defs.dart';

class ErrorSpan {
  final String languageId;
  final RefType refType;
  final String refId;
  final String? errorText;
  final String? correction;

  const ErrorSpan({
    required this.languageId,
    required this.refType,
    required this.refId,
    this.errorText,
    this.correction,
  });
}
