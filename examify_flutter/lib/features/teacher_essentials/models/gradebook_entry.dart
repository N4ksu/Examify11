import 'package:freezed_annotation/freezed_annotation.dart';

part 'gradebook_entry.freezed.dart';
part 'gradebook_entry.g.dart';

@freezed
abstract class GradebookEntry with _$GradebookEntry {
  const factory GradebookEntry({
    required int id,
    @JsonKey(name: 'student_id') String? studentId,
    required String name,
    String? email,
    String? section,
    required Map<String, double?> scores, // assessment title -> score
    @JsonKey(name: 'calculated_grade') required double calculatedGrade,
    @JsonKey(name: 'outcomes') Map<String, double?>? outcomes,
  }) = _GradebookEntry;

  factory GradebookEntry.fromJson(Map<String, dynamic> json) =>
      _$GradebookEntryFromJson(json);
}
