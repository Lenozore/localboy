# Flutter Map Migration Guide

## Overview
We've replaced Google Maps with **OpenStreetMap** (using `flutter_map` package) to eliminate costs and API key dependencies.

## What Changed

### Dependencies
- ❌ Removed: `google_maps_flutter: ^2.5.0`
- ✅ Added: `flutter_map: ^6.1.0`
- ✅ Kept: `geolocator` and `geocoding` (works with OpenStreetMap)

### Configuration
- ❌ Removed: Google Maps API key from `AndroidManifest.xml`
- ✅ Benefit: No paid API costs

## Migration Steps

### 1. Update Flutter Dependencies
```bash
cd localboy-frontend
flutter pub get

cd ../localboy-driver
flutter pub get
```

### 2. Replace GoogleMap Widget with FlutterMap

**Before (Google Maps):**
```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(15.3, 73.8),
    zoom: 15,
  ),
  markers: markers,
  onMapCreated: (controller) {},
)
```

**After (OpenStreetMap):**
```dart
import 'package:flutter_map/flutter_map.dart';

FlutterMap(
  options: MapOptions(
    initialCenter: const LatLng(15.3, 73.8),
    initialZoom: 13.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.localboy.app',
    ),
    MarkerLayer(
      markers: markers,
    ),
  ],
)
```

### 3. Update Markers

**Before:**
```dart
Set<Marker> markers = {
  Marker(
    markerId: MarkerId('marker1'),
    position: LatLng(15.3, 73.8),
    infoWindow: InfoWindow(title: 'Location'),
  ),
};
```

**After:**
```dart
List<Marker> markers = [
  Marker(
    point: const LatLng(15.3, 73.8),
    width: 80.0,
    height: 80.0,
    child: Tooltip(
      message: 'Location',
      child: Icon(Icons.location_on, color: Colors.red),
    ),
  ),
];
```

### 4. Update Geocoding (Address ↔ Coordinates)

**Remains the same:**
```dart
import 'package:geocoding/geocoding.dart';

// Get coordinates from address
List<Location> locations = await locationFromAddress('123 Main St');

// Get address from coordinates
List<Placemark> placemarks = await placemarkFromCoordinates(15.3, 73.8);
```

### 5. Current Maps Widget Files to Update

Search and update these files:
- `lib/screens/*` - Any screens with maps
- `lib/widgets/*` - Map-related widgets

Find all `GoogleMap` references:
```bash
grep -r "GoogleMap\|google_maps_flutter" lib/
```

## Key Differences

| Feature | Google Maps | OpenStreetMap (flutter_map) |
|---------|-------------|---------------------------|
| Cost | Paid (requires API key) | FREE |
| Attribution | Optional | Required (must show OSM attribution) |
| Layers | Limited | Very customizable |
| Offline Maps | Via Google | Via Libil |
| Markers | Marker widget | MarkerLayer |
| Polylines | Polyline widget | PolylineLayer |
| Polygons | Polygon widget | PolygonLayer |

## Attribution Requirement

OpenStreetMap requires attribution in your UI. Add this to map screens:

```dart
Text(
  '© OpenStreetMap contributors',
  style: Theme.of(context).textTheme.caption,
)
```

## Useful Resources

- [flutter_map docs](https://github.com/fleaflet/flutter_map)
- [OpenStreetMap tile servers](https://wiki.openstreetmap.org/wiki/Tile_servers)
- [Alternative tile layers](https://wiki.openstreetmap.org/wiki/Tiles)

## Testing

After migration, test:
- [ ] Maps load correctly
- [ ] Markers display at correct locations
- [ ] Zoom/pan functionality works
- [ ] Address search/geocoding works
- [ ] Performance is acceptable
