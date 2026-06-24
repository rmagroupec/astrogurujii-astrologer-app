// lib/core/widgets/LocationPickerWidget.dart
//
// Reusable widget used by BOTH CompleteProfileScreen & UpdateBillingAddress.
// Handles: country list → find India → states → cities → pre-select from IDs.
//
// Usage:
//   LocationPickerWidget(
//     initialStateId: a.stateId,
//     initialCityId : a.cityId,
//     onChanged     : (state, city) {
//       _selectedState = state;
//       _selectedCity  = city;
//     },
//   )

import 'dart:convert';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:astrologer_app/model/LocationModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:flutter/material.dart';

typedef LocationChanged = void Function(
    LocationItem? state, LocationItem? city);

class LocationPickerWidget extends StatefulWidget {
  final String          initialStateId;
  final String          initialCityId;
  final LocationChanged onChanged;

  const LocationPickerWidget({
    super.key,
    this.initialStateId = '',
    this.initialCityId  = '',
    required this.onChanged,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final _client = ApiClient();

  String             _indiaId       = '';
  List<LocationItem> _states        = [];
  List<LocationItem> _cities        = [];
  LocationItem?      _selectedState;
  LocationItem?      _selectedCity;

  bool _loadingStates = true;
  bool _loadingCities = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  // ── Step 1: find India, then load states ──────────────────────────────────
  Future<void> _loadStates() async {
    setState(() { _loadingStates = true; _error = null; });
    try {
      // Get country list to find India's ID
      final cRes = await _client.post(
        'astrologer_api/location_list',
        {'countries_id': '0', 'states_id': '0'},
        isAuthRequired: false,
      );
      final cData = LocationResponse.fromJson(jsonDecode(cRes.body));

      LocationItem? india;
      try {
        india = cData.results.firstWhere(
          (c) => c.name.toLowerCase().contains('india'),
        );
      } catch (_) {
        if (cData.results.isNotEmpty) india = cData.results.first;
      }

      if (india == null) {
        setState(() { _loadingStates = false; _error = 'Could not find India'; });
        return;
      }
      _indiaId = india.id;

      // Get states of India
      final sRes = await _client.post(
        'astrologer_api/location_list',
        {'countries_id': _indiaId, 'states_id': '0'},
        isAuthRequired: false,
      );
      final sData = LocationResponse.fromJson(jsonDecode(sRes.body));
      _states = sData.results;

      // Pre-select state if initialStateId given
      if (widget.initialStateId.isNotEmpty) {
        try {
          _selectedState = _states.firstWhere(
            (s) => s.id == widget.initialStateId,
          );
        } catch (_) {
          _selectedState = null;
        }

        // Load cities for pre-selected state
        if (_selectedState != null) {
          await _loadCities(
            _selectedState!.id,
            preSelectId: widget.initialCityId,
            notify: false,
          );
        }
      }

      // Notify parent of initial selection
      widget.onChanged(_selectedState, _selectedCity);
    } catch (e) {
      debugPrint('❌ LocationPicker _loadStates: $e');
      setState(() => _error = 'Failed to load states');
    } finally {
      if (mounted) setState(() => _loadingStates = false);
    }
  }

  // ── Step 2: load cities for a given state ─────────────────────────────────
  Future<void> _loadCities(
    String stateId, {
    String preSelectId = '',
    bool notify = true,
  }) async {
    if (mounted) setState(() { _loadingCities = true; _cities = []; _selectedCity = null; });
    try {
      final res = await _client.post(
        'astrologer_api/location_list',
        {'countries_id': _indiaId, 'states_id': stateId},
        isAuthRequired: false,
      );
      final data = LocationResponse.fromJson(jsonDecode(res.body));
      _cities = data.results;

      if (preSelectId.isNotEmpty) {
        try {
          _selectedCity = _cities.firstWhere((c) => c.id == preSelectId);
        } catch (_) {
          _selectedCity = null;
        }
      }

      if (notify && mounted) widget.onChanged(_selectedState, _selectedCity);
    } catch (e) {
      debugPrint('❌ LocationPicker _loadCities: $e');
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(8)),
        child: Row(children: [
          Icon(Icons.error_outline, color: AppTheme.accentRed, size: 16),
          SizedBox(width: FigmaSize.w(6)),
          Text(_error!,
              style: TextStyle(color: AppTheme.accentRed,
                  fontSize: FigmaSize.w(12))),
          SizedBox(width: FigmaSize.w(8)),
          GestureDetector(
            onTap: _loadStates,
            child: Text('Retry',
                style: TextStyle(
                    color     : AppTheme.primaryYellow,
                    fontSize  : FigmaSize.w(12),
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── State dropdown ─────────────────────────────────────────────────
        _SectionLabel(text: 'State', c: c),
        _loadingStates
            ? _Loader(color: AppTheme.primaryYellow)
            : _Dropdown(
                hint     : 'Select State',
                value    : _selectedState,
                items    : _states,
                c        : c,
                isDark   : isDark,
                onChanged: (item) {
                  setState(() {
                    _selectedState = item;
                    _selectedCity  = null;
                    _cities        = [];
                  });
                  widget.onChanged(_selectedState, null);
                  if (item != null) _loadCities(item.id);
                },
              ),

        SizedBox(height: FigmaSize.h(14)),

        // ── City dropdown ──────────────────────────────────────────────────
        _SectionLabel(text: 'City / Town', c: c),
        _loadingCities
            ? _Loader(color: AppTheme.primaryYellow)
            : _Dropdown(
                hint     : _selectedState == null
                    ? 'Select State first'
                    : 'Select City',
                value    : _selectedCity,
                items    : _cities,
                c        : c,
                isDark   : isDark,
                enabled  : _selectedState != null,
                onChanged: _selectedState == null
                    ? null
                    : (item) {
                        setState(() => _selectedCity = item);
                        widget.onChanged(_selectedState, _selectedCity);
                      },
              ),
      ],
    );
  }
}

// ── Shared label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String    text;
  final AppColors c;
  const _SectionLabel({required this.text, required this.c});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: FigmaSize.h(6)),
        child: Text(text,
            style: TextStyle(
                fontSize  : FigmaSize.w(12),
                fontWeight: FontWeight.w600,
                color     : c.text)),
      );
}

// ── Loading spinner ───────────────────────────────────────────────────────────
class _Loader extends StatelessWidget {
  final Color color;
  const _Loader({required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: FigmaSize.h(10)),
        child: Row(children: [
          SizedBox(
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          SizedBox(width: FigmaSize.w(8)),
          Text('Loading...',
              style: TextStyle(
                  fontSize: FigmaSize.w(12),
                  color   : context.colors.subText)),
        ]),
      );
}

// ── Generic dropdown ──────────────────────────────────────────────────────────
class _Dropdown extends StatelessWidget {
  final String                       hint;
  final LocationItem?                value;
  final List<LocationItem>           items;
  final AppColors                    c;
  final bool                         isDark;
  final bool                         enabled;
  final ValueChanged<LocationItem?>? onChanged;

  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.c,
    required this.isDark,
    this.enabled  = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : EdgeInsets.symmetric(horizontal: FigmaSize.w(12)),
      decoration: BoxDecoration(
        color       : enabled ? c.surface : c.toggleBg,
        border      : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LocationItem>(
          isExpanded   : true,
          value        : value,
          dropdownColor: c.surface,
          hint         : Text(hint,
              style: TextStyle(
                  fontSize: FigmaSize.w(12),
                  color   : c.subText)),
          style        : TextStyle(
              fontSize: FigmaSize.w(12),
              color   : enabled ? c.text : c.subText),
          iconEnabledColor : enabled ? c.text : c.subText,
          iconDisabledColor: c.subText.withOpacity(0.4),
          onChanged    : enabled ? onChanged : null,
          items        : items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(
              item.name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: FigmaSize.w(12), color: c.text),
            ),
          )).toList(),
        ),
      ),
    );
  }
}