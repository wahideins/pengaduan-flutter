import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart' as geo;

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();
  LatLng? _pickedLocation;

  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    // 🔍 Batasi pencarian hanya di Jawa Timur
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=$query'
      '&format=json'
      '&addressdetails=1'
      '&limit=5'
      '&viewbox=111.0,-9.0,115.0,-6.5'
      '&bounded=1'
    );

    try {
      final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _searchResults = data.map((item) {
            return {
              'display_name': item['display_name'],
              'lat': double.parse(item['lat']),
              'lon': double.parse(item['lon']),
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _moveToLocation(LatLng location) {
    _mapController.move(location, 15);
    setState(() {
      _pickedLocation = location;
      _searchResults = []; // tutup daftar setelah dipilih
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi di Peta')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(-7.8169, 112.0114), // sekitar Kediri
              initialZoom: 9,
              onTap: (tapPos, latlng) {
                setState(() => _pickedLocation = latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.uts',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 50,
                      height: 50,
                      point: _pickedLocation!,
                      child: const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
                    ),
                  ],
                ),
            ],
          ),

          // 🔍 Kolom pencarian
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _searchLocation,
                    decoration: InputDecoration(
                      hintText: 'Cari lokasi di Jawa Timur...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : (_searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchResults = []);
                                  },
                                )
                              : null),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),

                // 🔽 Daftar hasil pencarian
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined,
                              color: Colors.blueAccent),
                          title: Text(item['display_name']),
                          onTap: () {
                            final loc = LatLng(item['lat'], item['lon']);
                            _moveToLocation(loc);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),

      // Tombol konfirmasi
      floatingActionButton: _pickedLocation != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                final lat = _pickedLocation!.latitude;
                final lng = _pickedLocation!.longitude;

                final placemarks = await geo.placemarkFromCoordinates(lat, lng);
                String alamat = 'Alamat tidak ditemukan';
                if (placemarks.isNotEmpty) {
                  final place = placemarks.first;
                  final jalan = place.street ?? '';
                  final kelurahan = place.subLocality ?? '';
                  final kecamatan = place.locality ?? '';
                  const kota = 'Kediri';
                  const negara = 'Indonesia';

                  alamat = '$jalan, $kelurahan, $kecamatan, $kota, $negara';
                }

                Navigator.pop(context, alamat);
              },

              label: const Text('Gunakan Lokasi Ini'),
              icon: const Icon(Icons.check),
            )
          : null,
    );
  }
}
