import 'dart:convert';
import 'dart:io';

void main() async {
  print('Fetching railway data from Overpass API...');
  
  // Bounding box for Ankara Sincan to Kayaş: 39.85, 32.55, 39.98, 32.95
  final query = """
  [out:json];
  (
    way["railway"="rail"](39.85, 32.55, 39.98, 32.95);
  );
  out geom;
  """;

  final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}');
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  
  if (response.statusCode != 200) {
    print('Failed with status ${response.statusCode}');
    print(await response.transform(utf8.decoder).join());
    return;
  }
  
  final responseBody = await response.transform(utf8.decoder).join();
  final data = json.decode(responseBody);
  
  print('Got ${data['elements'].length} ways.');
  // OSRM routing on railways is not natively supported by public APIs.
  // Instead, since it's just a visual improvement, we will use a simple routing or dump the ways.
  // Wait, I can't easily order them without a routing algorithm.
  
  // Let's just output the raw ways as separate polylines for now to see if it covers the track.
  // Or better, we can just save all these ways into a dart file as a list of polylines.
  
  final buffer = StringBuffer();
  buffer.writeln("import 'package:latlong2/latlong.dart';");
  buffer.writeln("class RailwayData {");
  buffer.writeln("  static final List<List<LatLng>> paths = [");
  
  for (var element in data['elements']) {
    if (element['type'] == 'way' && element['geometry'] != null) {
      buffer.writeln("    [");
      for (var node in element['geometry']) {
        buffer.writeln("      LatLng(${node['lat']}, ${node['lon']}),");
      }
      buffer.writeln("    ],");
    }
  }
  
  buffer.writeln("  ];");
  buffer.writeln("}");
  
  await File('lib/models/railway_data.dart').writeAsString(buffer.toString());
  print('Done!');
}
