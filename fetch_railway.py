import urllib.request
import json
import urllib.parse

relation_id = 14118633

query = f'''[out:json];
relation({relation_id});
out geom;'''

url = 'https://overpass-api.de/api/interpreter?data=' + urllib.parse.quote(query)
req = urllib.request.Request(url, headers={'User-Agent': 'Antigravity/1.0'})

try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode('utf-8'))
    
    if not data['elements']:
        print("No elements found.")
        exit(1)

    relation = data['elements'][0]
    ways_geom = []
    
    for member in relation.get('members', []):
        if member['type'] == 'way' and 'geometry' in member:
            ways_geom.append([(p['lat'], p['lon']) for p in member['geometry']])

    if not ways_geom:
        print("No ways in relation.")
        exit(1)

    # Correct Stitching: 
    # Start with the way that is closest to Kayas (the beginning)
    # Kayaş station is at approx (39.9134, 32.9657)
    kayas_coords = (39.913427, 32.965733)
    
    def dist(p1, p2):
        return (p1[0]-p2[0])**2 + (p1[1]-p2[1])**2

    # Find the starting way
    start_way_idx = -1
    min_d = float('inf')
    reverse_start = False
    
    for i, w in enumerate(ways_geom):
        d_start = dist(w[0], kayas_coords)
        d_end = dist(w[-1], kayas_coords)
        if d_start < min_d:
            min_d = d_start
            start_way_idx = i
            reverse_start = False
        if d_end < min_d:
            min_d = d_end
            start_way_idx = i
            reverse_start = True

    ordered_ways = []
    current_path = ways_geom[start_way_idx]
    if reverse_start:
        current_path.reverse()
    
    ordered_ways.append(current_path)
    used_indices = {start_way_idx}

    # Greedy stitching
    while len(used_indices) < len(ways_geom):
        last_pt = ordered_ways[-1][-1]
        best_next = -1
        best_dist = float('inf')
        should_reverse = False
        
        for i, w in enumerate(ways_geom):
            if i in used_indices: continue
            
            d_start = dist(last_pt, w[0])
            d_end = dist(last_pt, w[-1])
            
            if d_start < best_dist:
                best_dist = d_start
                best_next = i
                should_reverse = False
            if d_end < best_dist:
                best_dist = d_end
                best_next = i
                should_reverse = True
        
        if best_next != -1:
            next_way = ways_geom[best_next]
            if should_reverse:
                next_way.reverse()
            ordered_ways.append(next_way)
            used_indices.add(best_next)
        else:
            break

    full_path = []
    for w in ordered_ways:
        if not full_path:
            full_path.extend(w)
        else:
            # Avoid duplicate connector point
            full_path.extend(w[1:])

    print(f'Stitched {len(full_path)} points from {len(ordered_ways)} ways.')
    
    with open('final_path.json', 'w') as f:
        json.dump(full_path, f)
        
except Exception as e:
    print('Error:', e)
