import 'dart:convert';
import 'models.dart';
import 'rules.dart';

String selectedContext({required Map<String,dynamic> profile,required bool useProfile,
  required List<PersonalDocument> documents}) {
  final parts=<String>[];
  if(useProfile && profile['confirmed']==true) {
    parts.add('User-confirmed profile:\n${jsonEncode(profile)}');
  }
  for(final d in documents.where((d)=>d.selected && d.confirmed)) {
    parts.add('User-confirmed document ${d.id} (${d.kind}):\n${d.text}');
  }
  return maskPrivateText(parts.join('\n\n'));
}
