// lib/features/Settings/UpdateBillingAddress.dart

import 'dart:convert';
import 'package:astrologer_app/core/config/theme_config.dart';
import 'package:astrologer_app/model/LocationModel.dart';
import 'package:astrologer_app/service/apiClient.dart';
import 'package:astrologer_app/service/apiService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UpdateBillingAddress extends StatefulWidget {
  const UpdateBillingAddress({super.key});

  @override
  State<UpdateBillingAddress> createState() => _UpdateBillingAddressState();
}

class _UpdateBillingAddressState extends State<UpdateBillingAddress> {
  final _addressCtrl = TextEditingController();
  final _nameCtrl    = TextEditingController();
  final _pincodeCtrl = TextEditingController();

  bool _loading    = true;
  bool _submitting = false;

  // ── Location lists ──────────────────────────────────────────────────────
  List<LocationItem> _states   = [];
  List<LocationItem> _cities   = [];
  bool _statesLoading = false;
  bool _citiesLoading = false;

  LocationItem? _selectedState;
  LocationItem? _selectedCity;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _nameCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  // ── Load states + existing profile data together ──────────────────────
// In _UpdateBillingAddressState

String _indiaId = ''; // will be set after fetching countries

Future<void> _init() async {
  setState(() => _loading = true);
  try {
    // Step 1: Get countries to find India's ID
    final countryRes = await ApiService().getCountryList();
    final india = countryRes.results.firstWhere(
      (c) => c.name.toLowerCase() == 'india',
      orElse: () => countryRes.results.first,
    );
    _indiaId = india.id;

    // Step 2: Get states of India
    final stateRes = await ApiService().getStateList(_indiaId);
    _states = stateRes.results;

    // Step 3: Load profile and pre-fill
    final profileRes = await ApiService().get_astrologer_profile();
    if (profileRes.results.isNotEmpty) {
      final a = profileRes.results.first;
      _addressCtrl.text = a.address;
      _nameCtrl.text    = a.displayname;
      _pincodeCtrl.text = a.pincode;

      if (a.stateId.isNotEmpty) {
        try {
          _selectedState = _states.firstWhere((s) => s.id == a.stateId);
        } catch (_) {
          _selectedState = null;
        }
        if (_selectedState != null) {
          await _loadCities(_selectedState!.id, preSelectId: a.cityId);
        }
      }
    }
  } catch (e) {
    debugPrint('❌ init error: $e');
  }
  if (mounted) setState(() => _loading = false);
}

Future<void> _loadCities(String stateId, {String preSelectId = ''}) async {
  setState(() { _citiesLoading = true; _cities = []; _selectedCity = null; });
  try {
    final res = await ApiService().getCityList(_indiaId, stateId);
    _cities = res.results;
    if (preSelectId.isNotEmpty) {
      try {
        _selectedCity = _cities.firstWhere((c) => c.id == preSelectId);
      } catch (_) {
        _selectedCity = null;
      }
    }
  } catch (e) {
    debugPrint('❌ cities load error: $e');
  }
  if (mounted) setState(() => _citiesLoading = false);
}

  // ── Submit ─────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_addressCtrl.text.trim().isEmpty) {
      _showSnack('Please enter your address', error: true); return;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter name for invoice', error: true); return;
    }
    if (_pincodeCtrl.text.trim().length != 6) {
      _showSnack('Enter a valid 6-digit pincode', error: true); return;
    }
    if (_selectedState == null || _selectedState!.id.isEmpty) {
      _showSnack('Please select state', error: true); return;
    }
    if (_selectedCity == null || _selectedCity!.id.isEmpty) {
      _showSnack('Please select city', error: true); return;
    }

    setState(() => _submitting = true);
    try {
      final body = {
        'address'    : _addressCtrl.text.trim(),
        'displayname': _nameCtrl.text.trim(),
        'pincode'    : _pincodeCtrl.text.trim(),
        'state_id'   : _selectedState!.id,      // save ID to schema
        'city_id'    : _selectedCity!.id,        // save ID to schema
        // also save plain text for display
        'city'       : _selectedCity!.name,
        'state'      : _selectedState!.name,
      };

      final res  = await ApiClient().post(
        'astrologer_api/profile_update',
        body,
        isAuthRequired: true,
      );
      if (!mounted) return;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() => _submitting = false);

      if (res.statusCode == 200 && json['status'] == true) {
        _showSnack('✅ Billing address updated successfully!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.of(context).pop();
      } else {
        _showSnack(
          json['message']?.toString() ?? 'Update failed.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack('Network error. Please try again.', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content        : Text(msg),
      backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      behavior       : SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c      = context.colors;
    final isDark = context.isDark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          title: const Text('Update Billing Address',
              style: TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── Dark card ──────────────────────────────────────────
                    Container(
                      width     : double.infinity,
                      decoration: BoxDecoration(
                        color       : isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFF2D2D44),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                      child: Column(
                        children: [
                          // Close button
                          Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 30, height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Icon
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color       : Colors.orange.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                size: 36, color: Colors.orange),
                          ),
                          const SizedBox(height: 16),

                          const Text('Add Your Address',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text(
                            'Please share your address for invoice\nand compliance purposes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color   : Colors.white.withOpacity(0.65),
                              fontSize: 13,
                              height  : 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Address
                          _DarkField(
                            controller: _addressCtrl,
                            hint      : 'Enter your full address *',
                            maxLines  : 2,
                          ),
                          const SizedBox(height: 12),

                          // Invoice name
                          _DarkField(
                            controller: _nameCtrl,
                            hint      : 'Enter Name for invoice *',
                          ),
                          const SizedBox(height: 12),

                          // Pincode
                          _DarkField(
                            controller     : _pincodeCtrl,
                            hint           : 'Pincode *',
                            keyboardType   : TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── State dropdown ─────────────────────────────
                          _statesLoading
                              ? const Center(child: CircularProgressIndicator(
                                  color: Colors.orange, strokeWidth: 2))
                              : _DarkDropdown(
                                  hint    : 'Select State *',
                                  value   : _selectedState,
                                  items   : _states,
                                  onChanged: (item) {
                                    setState(() {
                                      _selectedState = item;
                                      _selectedCity  = null;
                                      _cities        = [];
                                    });
                                    if (item != null) {
                                      _loadCities(item.id);
                                    }
                                  },
                                ),
                          const SizedBox(height: 12),

                          // ── City dropdown ──────────────────────────────
                          _citiesLoading
                              ? const Center(child: CircularProgressIndicator(
                                  color: Colors.orange, strokeWidth: 2))
                              : _DarkDropdown(
                                  hint    : _selectedState == null
                                      ? 'Select State first'
                                      : 'Select City *',
                                  value   : _selectedCity,
                                  items   : _cities,
                                  onChanged: _selectedState == null
                                      ? null
                                      : (item) {
                                          setState(() => _selectedCity = item);
                                        },
                                ),
                          const SizedBox(height: 24),

                          // Submit
                          SizedBox(
                            width : double.infinity,
                            height: 50,
                            child : ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryYellow,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor: Colors.grey.shade400,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black),
                                    )
                                  : const Text('Submit',
                                      style: TextStyle(
                                          fontSize  : 16,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Info note
                    Container(
                      padding   : const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color       : AppTheme.primaryYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border      : Border.all(
                            color: AppTheme.primaryYellow.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This address will be used on all your invoices '
                              'and for GST compliance purposes.',
                              style: TextStyle(
                                fontSize: 12,
                                color   : c.subText,
                                height  : 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Dark text field ────────────────────────────────────────────────────────────
class _DarkField extends StatefulWidget {
  final TextEditingController     controller;
  final String                    hint;
  final int                       maxLines;
  final TextInputType?            keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const _DarkField({
    required this.controller,
    required this.hint,
    this.maxLines       = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<_DarkField> createState() => _DarkFieldState();
}

class _DarkFieldState extends State<_DarkField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller     : widget.controller,
      maxLines       : widget.maxLines,
      keyboardType   : widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      style          : const TextStyle(color: Colors.white, fontSize: 14),
      decoration     : InputDecoration(
        hintText      : widget.hint,
        hintStyle     : TextStyle(
            color: Colors.white.withOpacity(0.45), fontSize: 13),
        filled        : true,
        fillColor     : Colors.white.withOpacity(0.08),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide  : BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide  : BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide  : const BorderSide(
              color: AppTheme.primaryYellow, width: 1.5),
        ),
      ),
    );
  }
}

// ── Dark dropdown ─────────────────────────────────────────────────────────────
class _DarkDropdown extends StatelessWidget {
  final String                        hint;
  final LocationItem?                 value;
  final List<LocationItem>            items;
  final ValueChanged<LocationItem?>?  onChanged;

  const _DarkDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color       : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border      : Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LocationItem>(
          isExpanded  : true,
          value       : value,
          hint        : Text(hint,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45), fontSize: 13)),
          dropdownColor: const Color(0xFF2D2D44),
          iconEnabledColor : Colors.white54,
          iconDisabledColor: Colors.white24,
          style       : const TextStyle(color: Colors.white, fontSize: 14),
          onChanged   : onChanged,
          items       : items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item.name,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          )).toList(),
        ),
      ),
    );
  }
}