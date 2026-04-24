import json
import math

with open('final_path.json', 'r') as f:
    raw_points = json.load(f)

# Unique points while preserving order
points = []
seen = set()
for p in raw_points:
    tp = (round(p[0], 7), round(p[1], 7))
    if tp not in seen:
        points.append(tp)
        seen.add(tp)

stations = [
    (39.913427, 32.965733), (39.916883, 32.950734), (39.922501, 32.932175),
    (39.925907, 32.923281), (39.931551, 32.911275), (39.937516, 32.894731),
    (39.939860, 32.882919), (39.933394, 32.876150), (39.928904, 32.868185),
    (39.929097, 32.857802), (39.934823, 32.843533), (39.945130, 32.826066),
    (39.944176, 32.812730), (39.940203, 32.795917), (39.934429, 32.778448),
    (39.931573, 32.749863), (39.932394, 32.704497), (39.942371, 32.688254),
    (39.949280, 32.662698), (39.951879, 32.648922), (39.955755, 32.630402),
    (39.958793, 32.612221), (39.961557, 32.598724), (39.964648, 32.583918)
]

def dist(p1, p2):
    return (p1[0]-p2[0])**2 + (p1[1]-p2[1])**2

start_dist = dist(points[0], stations[0])
end_dist = dist(points[-1], stations[0])
if end_dist < start_dist:
    points.reverse()

# Find nearest point to Kayas
s1_idx = min(range(len(points)), key=lambda i: dist(points[i], stations[0]))
# Find nearest point to Sincan
s2_idx = min(range(len(points)), key=lambda i: dist(points[i], stations[-1]))

# Extend the start and end by a few points to cover the labels as requested
# We'll go 5 points further back from Kayas and 5 points further forward from Sincan
start_clip = max(0, min(s1_idx, s2_idx) - 5)
end_clip = min(len(points) - 1, max(s1_idx, s2_idx) + 5)

final_points = points[start_clip : end_clip + 1]
if s1_idx > s2_idx:
    final_points.reverse()

# Map station indices
station_indices = []
for s in stations:
    idx = min(range(len(final_points)), key=lambda i: dist(final_points[i], s))
    station_indices.append(idx)

# Save as Dart file
with open('lib/data/baskentray_route.dart', 'w', encoding='utf-8') as f:
    f.write("import 'package:latlong2/latlong.dart';\n\n")
    f.write("class BaskentrayRoute {\n")
    f.write("  static const List<LatLng> points = [\n")
    for p in final_points:
        f.write(f"    LatLng({p[0]}, {p[1]}),\n")
    f.write("  ];\n\n")
    f.write("  static const List<int> stationIndices = {0};\n".format(station_indices))
    f.write("}\n")

print(f"Final extended path has {len(final_points)} points. Station indices: {station_indices}")
