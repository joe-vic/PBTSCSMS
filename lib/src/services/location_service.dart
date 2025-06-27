import 'dart:convert';
import 'package:flutter/services.dart';

class LocationService {
  static Map<String, dynamic>? _locationData;
  
  static Future<void> initialize() async {
    if (_locationData != null) return;
    
    final String jsonString = await rootBundle.loadString('assets/data/philippine_locations.json');
    _locationData = json.decode(jsonString);
  }
  
  static List<String> getRegions() {
    if (_locationData == null) return [];
    final Set<String> uniqueRegions = {};
    _locationData!.forEach((key, value) {
      uniqueRegions.add(value['region_name'] as String);
    });
    return uniqueRegions.toList()..sort();
  }
  
  static List<String> getProvinces(String region) {
    if (_locationData == null) return [];
    
    String? regionCode = _getRegionCode(region);
    if (regionCode == null) return [];
    
    final Set<String> uniqueProvinces = {};
    final provinces = _locationData![regionCode]['province_list'].keys;
    uniqueProvinces.addAll(provinces.cast<String>());
    return uniqueProvinces.toList()..sort();
  }
  
  static List<String> getMunicipalities(String province) {
    if (_locationData == null) return [];
    
    final Set<String> uniqueMunicipalities = {};
    for (var regionCode in _locationData!.keys) {
      final provinceList = _locationData![regionCode]['province_list'];
      if (provinceList.containsKey(province)) {
        final municipalities = provinceList[province]['municipality_list'].keys;
        uniqueMunicipalities.addAll(municipalities.cast<String>());
        break;
      }
    }
    return uniqueMunicipalities.toList()..sort();
  }
  
  static List<String> getBarangays(String municipality, String province) {
    if (_locationData == null) return [];
    
    final Set<String> uniqueBarangays = {};
    for (var regionCode in _locationData!.keys) {
      final provinceList = _locationData![regionCode]['province_list'];
      if (provinceList.containsKey(province)) {
        final municipalityList = provinceList[province]['municipality_list'];
        if (municipalityList.containsKey(municipality)) {
          final barangays = municipalityList[municipality]['barangay_list'];
          uniqueBarangays.addAll(barangays.cast<String>());
          break;
        }
      }
    }
    return uniqueBarangays.toList()..sort();
  }
  
  static String? _getRegionCode(String regionName) {
    for (var entry in _locationData!.entries) {
      if (entry.value['region_name'] == regionName) {
        return entry.key;
      }
    }
    return null;
  }
  
  static String? getRegionForProvince(String province) {
    if (_locationData == null) return null;
    
    for (var regionCode in _locationData!.keys) {
      final provinceList = _locationData![regionCode]['province_list'];
      if (provinceList.containsKey(province)) {
        return _locationData![regionCode]['region_name'];
      }
    }
    return null;
  }
} 