import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class LocationData {
  final Map<String, Region> regions;

  LocationData({required this.regions});

  factory LocationData.fromJson(Map<String, dynamic> json) {
    final regions = (json as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        Region.fromJson(value as Map<String, dynamic>),
      ),
    );
    return LocationData(regions: regions);
  }

  static Future<LocationData> loadFromAsset() async {
    final String jsonString = await rootBundle.loadString('assets/data/philippine_locations.json');
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);
    return LocationData.fromJson(jsonData);
  }

  List<String> getAllMunicipalities() {
    final municipalities = <String>{};
    for (var region in regions.values) {
      for (var province in region.provinceList.values) {
        municipalities.addAll(province.municipalityList.keys);
      }
    }
    return municipalities.toList()..sort();
  }

  List<String> getMunicipalitiesForProvince(String province) {
    final municipalities = <String>{};
    for (var region in regions.values) {
      for (var provinceEntry in region.provinceList.entries) {
        if (provinceEntry.key.toLowerCase() == province.toLowerCase()) {
          municipalities.addAll(provinceEntry.value.municipalityList.keys);
        }
      }
    }
    return municipalities.toList()..sort();
  }

  List<String> getBarangaysForMunicipality(String municipality) {
    for (var region in regions.values) {
      for (var province in region.provinceList.values) {
        if (province.municipalityList.containsKey(municipality)) {
          return province.municipalityList[municipality]!.barangayList..sort();
        }
      }
    }
    return [];
  }

  List<String> getAllProvinces() {
    final provinces = <String>{};
    for (var region in regions.values) {
      provinces.addAll(region.provinceList.keys);
    }
    return provinces.toList()..sort();
  }

  String? getProvinceForMunicipality(String municipality) {
    for (var region in regions.values) {
      for (var province in region.provinceList.entries) {
        if (province.value.municipalityList.containsKey(municipality)) {
          return province.key;
        }
      }
    }
    return null;
  }

  String getDefaultProvince() {
    return "Rizal"; // Default to Rizal as per requirement
  }
}

class Region {
  final String regionName;
  final Map<String, Province> provinceList;

  Region({required this.regionName, required this.provinceList});

  factory Region.fromJson(Map<String, dynamic> json) {
    final provinceList = (json['province_list'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        Province.fromJson(value as Map<String, dynamic>),
      ),
    );
    return Region(
      regionName: json['region_name'] as String,
      provinceList: provinceList,
    );
  }
}

class Province {
  final Map<String, Municipality> municipalityList;

  Province({required this.municipalityList});

  factory Province.fromJson(Map<String, dynamic> json) {
    final municipalityList = (json['municipality_list'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(
        key,
        Municipality.fromJson(value as Map<String, dynamic>),
      ),
    );
    return Province(municipalityList: municipalityList);
  }
}

class Municipality {
  final List<String> barangayList;

  Municipality({required this.barangayList});

  factory Municipality.fromJson(Map<String, dynamic> json) {
    final barangayList = (json['barangay_list'] as List<dynamic>).cast<String>();
    return Municipality(barangayList: barangayList);
  }
}