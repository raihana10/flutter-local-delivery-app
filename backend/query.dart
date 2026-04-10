import 'dart:convert';
import 'dart:io';

main() async {
  final envFile = File('.env');
  final lines = envFile.readAsLinesSync();
  String url = '';
  String key = '';
  for(var l in lines){
    if(l.startsWith('SUPABASE_URL=')) url = l.split('=')[1];
    if(l.startsWith('SUPABASE_ANON_KEY=')) key = l.split('=')[1];
  }
  
  // We want to see what 'timeline' actually contains.
  final req = await HttpClient().getUrl(Uri.parse('$url/rest/v1/timeline?select=*,livreur(*)&limit=1'));
  req.headers.add('apikey', key);
  req.headers.add('Authorization', 'Bearer $key');
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  print(body);
}
