import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kwrmyanmar/core/ai_service.dart';
import 'package:kwrmyanmar/core/models.dart';
import 'package:kwrmyanmar/core/context.dart';

void main(){
  for(final provider in providers.where((p)=>p.id!='custom')){
    test('${provider.id}: native endpoint, auth, request and response',() async {
      final ai=AiService(client:MockClient((request) async {
        final body=jsonDecode(request.body) as Map<String,dynamic>;
        expect(request.url.scheme,'https');
        expect(request.url.query,isEmpty);
        if(provider.id=='gemini'){
          expect(request.headers['x-goog-api-key'],'TEST_KEY');
          expect(request.url.path,endsWith('models/test-model:generateContent'));
          expect(body['systemInstruction']['parts'][0]['text'],'policy');
          expect(body['contents'][0]['parts'][0]['text'],'question');
          return http.Response(jsonEncode({'candidates':[{'content':{'parts':[{'thought':true,'text':'hidden'},{'text':'အဖြေ'}]}}]}),200,encoding:utf8);
        }
        if(provider.id=='claude'){
          expect(request.headers['x-api-key'],'TEST_KEY');expect(request.headers['anthropic-version'],'2023-06-01');
          expect(request.url.path,endsWith('/messages'));expect(body['system'],'policy');
          expect(body['messages'][0]['content'],'question');
          return http.Response(jsonEncode({'content':[{'type':'text','text':'အဖြေ'}]}),200,encoding:utf8);
        }
        expect(request.headers['Authorization'],'Bearer TEST_KEY');
        if(provider.id=='openai'){
          expect(request.url.path,endsWith('/responses'));expect(body['store'],false);expect(body['instructions'],'policy');
          expect(body['input'][0]['content'],'question');
          return http.Response(jsonEncode({'output':[{'type':'message','content':[{'type':'output_text','text':'အဖြေ'}]}]}),200,encoding:utf8);
        }
        expect(request.url.path,endsWith('/chat/completions'));expect(body['messages'][0],{'role':'system','content':'policy'});
        expect(body['messages'][1]['content'],'question');
        return http.Response(jsonEncode({'choices':[{'message':{'content':'အဖြေ'}}]}),200,encoding:utf8);
      }));
      expect(await ai.chat(provider:provider,base:provider.baseUrl,key:'TEST_KEY',model:'test-model',system:'policy',messages:[{'role':'user','content':'question'}]),'အဖြေ');
      ai.close();
    });
  }
  test('Gemini model pagination filters non-chat models',() async {
    var pages=0;
    final ai=AiService(client:MockClient((request) async {
      pages++;
      if(pages==1){expect(request.url.queryParameters['pageToken'],isNull);return http.Response(jsonEncode({'models':[{'name':'models/embed-only','supportedGenerationMethods':['embedContent']},{'name':'models/chat-a','supportedGenerationMethods':['generateContent']}],'nextPageToken':'next'}),200,encoding:utf8);}
      expect(request.url.queryParameters['pageToken'],'next');return http.Response(jsonEncode({'models':[{'name':'models/chat-b','supportedGenerationMethods':['generateContent']}]}),200,encoding:utf8);
    }));
    expect(await ai.listModels(providers.first,providers.first.baseUrl,'TEST_KEY'),['chat-a','chat-b']);expect(pages,2);ai.close();
  });
  test('Claude model pagination follows last_id',() async {
    var pages=0;final p=providers.firstWhere((p)=>p.id=='claude');
    final ai=AiService(client:MockClient((request) async {pages++;return http.Response(jsonEncode(pages==1?{'data':[{'id':'claude-a'}],'has_more':true,'last_id':'claude-a'}:{'data':[{'id':'claude-b'}],'has_more':false}),200,encoding:utf8);}));
    expect(await ai.listModels(p,p.baseUrl,'TEST_KEY'),['claude-a','claude-b']);expect(pages,2);ai.close();
  });
  test('provider errors hide the API key',() async {
    final ai=AiService(client:MockClient((_) async=>http.Response(jsonEncode({'error':{'message':'bad TEST_KEY'}}),401)));
    await expectLater(ai.listModels(providers.first,providers.first.baseUrl,'TEST_KEY'),throwsA(isA<AiFailure>().having((e)=>e.message,'message',allOf(contains('HTTP 401'),isNot(contains('TEST_KEY'))))));ai.close();
  });
  test('custom endpoints reject key URLs and plain HTTP',(){
    final ai=AiService();
    for(final url in ['http://example.com','https://example.com?key=abc','https://user:pass@example.com']){expect(()=>ai.endpoint(url,'models'),throwsA(isA<AiFailure>()));}
    ai.close();
  });
  test('unknown source ID or malformed answer fails closed',(){
    expect(AiAnswer.parse('{"answer":"x","questions":[],"steps":[],"source_ids":["invented"]}',{'real'}).validated,false);
    expect(AiAnswer.parse('plain text',{'real'}).validated,false);
    expect(AiAnswer.parse('{"answer":"x","questions":[],"steps":[]}',{'real'}).validated,false);
    expect(AiAnswer.parse('{"answer":"x","questions":[],"steps":[],"source_ids":["real"]}',{'real'}).validated,true);
  });
  test('only selected, confirmed facts enter provider context',(){
    const docs=[PersonalDocument(id:'a',name:'a',kind:'contract',text:'ALLOWED MA1234567',created:'now',selected:true,confirmed:true),PersonalDocument(id:'b',name:'b',kind:'contract',text:'UNCONFIRMED',created:'now',selected:true),PersonalDocument(id:'c',name:'c',kind:'contract',text:'DESELECTED',created:'now',confirmed:true)];
    final text=selectedContext(profile:{'secret':'PROFILE','confirmed':true},useProfile:false,documents:docs);
    expect(text,contains('ALLOWED'));expect(text,isNot(contains('PROFILE')));expect(text,isNot(contains('UNCONFIRMED')));expect(text,isNot(contains('DESELECTED')));expect(text,isNot(contains('MA1234567')));
    expect(selectedContext(profile:{'secret':'PROFILE'},useProfile:true,documents:[]),isEmpty);
  });
}
