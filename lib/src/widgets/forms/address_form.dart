import 'package:flutter/material.dart';
// REMOVED: // REMOVED: import 'package:google_fonts/google_fonts.dart';
import '../../services/location_service.dart';
import '../../config/theme.dart';
import 'dropdown_field.dart';
import 'custom_text_field.dart';

class AddressForm extends StatefulWidget {
  final String? region;
  final String? province;
  final String? municipality;
  final String? barangay;
  final String? streetAddress;
  final Function(String?) onRegionChanged;
  final Function(String?) onProvinceChanged;
  final Function(String?) onMunicipalityChanged;
  final Function(String?) onBarangayChanged;
  final Function(String) onStreetAddressChanged;
  final bool enabled;
  final bool isRequired;
  final Map<String, FocusNode>? focusNodes;
  final bool showValidation;

  const AddressForm({
    Key? key,
    this.region,
    this.province,
    this.municipality,
    this.barangay,
    this.streetAddress,
    required this.onRegionChanged,
    required this.onProvinceChanged,
    required this.onMunicipalityChanged,
    required this.onBarangayChanged,
    required this.onStreetAddressChanged,
    this.enabled = true,
    this.isRequired = true,
    this.focusNodes,
    this.showValidation = false,
  }) : super(key: key);

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  bool _hasAttemptedSubmit = false;
  List<String> _regions = [];
  List<String> _provinces = [];
  List<String> _municipalities = [];
  List<String> _barangays = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  static const String defaultRegion = 'REGION IV-A';
  static const String defaultProvince = 'RIZAL';
  static const String defaultMunicipality = 'BINANGONAN';

  @override
  void initState() {
    super.initState();
    _initializeLocationData();
  }

  Future<void> _initializeLocationData() async {
    try {
      await LocationService.initialize();
      setState(() {
        _regions = LocationService.getRegions();
        _isLoading = false;
      });

      // Initialize with default values or existing values
      String currentRegion = widget.region ?? defaultRegion;
      widget.onRegionChanged(currentRegion);

      setState(() {
        _provinces = LocationService.getProvinces(currentRegion);
      });

      String currentProvince = widget.province ?? defaultProvince;
      widget.onProvinceChanged(currentProvince);

      setState(() {
        _municipalities = LocationService.getMunicipalities(currentProvince);
      });

      String currentMunicipality = widget.municipality ?? defaultMunicipality;
      widget.onMunicipalityChanged(currentMunicipality);

      setState(() {
        _barangays =
            LocationService.getBarangays(currentMunicipality, currentProvince);
      });

      // Validate initial state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_formKey.currentState != null) {
          _formKey.currentState!.validate();
        }
      });
    } catch (e) {
      debugPrint('Error initializing location data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?)? validator,
    required IconData icon,
    String? focusKey,
    required bool isRequired,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownField(
              label: label,
              value: value,
              items: items,
              onChanged: widget.enabled ? onChanged : null,
              validator: _hasAttemptedSubmit ? validator : null,
              icon: icon,
              isExpanded: true,
              isRequired: isRequired,
              focusNode: focusKey != null && widget.focusNodes != null
                  ? widget.focusNodes![focusKey]
                  : null,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _hasAttemptedSubmit || widget.showValidation
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                _buildDropdown(
                  label: 'Region',
                  value: widget.region,
                  items: _regions,
                  onChanged: (value) {
                    widget.onRegionChanged(value);
                    if (value != null) {
                      setState(() {
                        _provinces = LocationService.getProvinces(value);
                        _municipalities = [];
                        _barangays = [];
                      });
                    }
                  },
                  validator: widget.isRequired
                      ? (value) =>
                          value?.isEmpty ?? true ? 'Region is required' : null
                      : null,
                  icon: Icons.location_on,
                  focusKey: 'region',
                  isRequired: widget.isRequired,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Province',
                  value: widget.province,
                  items: _provinces,
                  onChanged: (value) {
                    widget.onProvinceChanged(value);
                    if (value != null) {
                      setState(() {
                        _municipalities =
                            LocationService.getMunicipalities(value);
                        _barangays = [];
                      });
                    }
                  },
                  validator: widget.isRequired
                      ? (value) =>
                          value?.isEmpty ?? true ? 'Province is required' : null
                      : null,
                  icon: Icons.location_city,
                  focusKey: 'province',
                  isRequired: widget.isRequired,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Municipality/City',
                  value: widget.municipality,
                  items: _municipalities,
                  onChanged: (value) {
                    widget.onMunicipalityChanged(value);
                    if (value != null && widget.province != null) {
                      setState(() {
                        _barangays = LocationService.getBarangays(
                            value, widget.province!);
                      });
                    }
                  },
                  validator: widget.isRequired
                      ? (value) => value?.isEmpty ?? true
                          ? 'Municipality/City is required'
                          : null
                      : null,
                  icon: Icons.location_city,
                  focusKey: 'municipality',
                  isRequired: widget.isRequired,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Barangay',
                  value: widget.barangay,
                  items: _barangays,
                  onChanged: widget.onBarangayChanged,
                  validator: widget.isRequired
                      ? (value) =>
                          value?.isEmpty ?? true ? 'Barangay is required' : null
                      : null,
                  icon: Icons.location_city,
                  focusKey: 'barangay',
                  isRequired: widget.isRequired,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Street Address',
                  value: widget.streetAddress ?? '',
                  onChanged: widget.onStreetAddressChanged,
                  validator: widget.isRequired
                      ? (value) => value?.isEmpty ?? true
                          ? 'Street Address is required'
                          : null
                      : null,
                  enabled: widget.enabled,
                  prefixIcon: Icons.home,
                  focusNode: widget.focusNodes?['streetAddress'],
                  isRequired: widget.isRequired,
                  showValidation: _hasAttemptedSubmit || widget.showValidation,
                ),
              ],
            ),
        ],
      ),
    );
  }
}