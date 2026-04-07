// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gradebook_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GradebookEntry _$GradebookEntryFromJson(Map<String, dynamic> json) =>
    _GradebookEntry(
      id: (json['id'] as num).toInt(),
      studentId: json['student_id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
      section: json['section'] as String?,
      scores: (json['scores'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num?)?.toDouble()),
      ),
      calculatedGrade: (json['calculated_grade'] as num).toDouble(),
      outcomes: (json['outcomes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num?)?.toDouble()),
      ),
    );

Map<String, dynamic> _$GradebookEntryToJson(_GradebookEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'name': instance.name,
      'email': instance.email,
      'section': instance.section,
      'scores': instance.scores,
      'calculated_grade': instance.calculatedGrade,
      'outcomes': instance.outcomes,
    };
