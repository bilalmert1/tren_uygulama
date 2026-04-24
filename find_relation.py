import urllib.request
import json
import urllib.parse

query = '''[out:json];
(
  relation["route"="train"]["name"~"Başkentray"];
  relation["route"="train"]["network"~"Başkentray"];
);
out body;'''
url = 'https://overpass-api.de/api/interpreter?data=' + urllib.parse.quote(query)
req = urllib.request.Request(url, headers={'User-Agent': 'Antigravity/1.0'})
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode('utf-8'))
        for element in data['elements']:
            tags = element.get('tags', {})
            print(f"Found: {tags.get('name')} | ID: {element['id']} | Network: {tags.get('network')}")
except Exception as e:
    print('Error:', e)
