import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/college_model.dart';
import '../../providers/compare_provider.dart';
import '../../data/mock_data.dart';

class CompareScreen extends StatefulWidget {
  final CollegeModel? college1;
  final CollegeModel? college2;

  const CompareScreen({super.key, this.college1, this.college2});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  CollegeModel? _college1;
  CollegeModel? _college2;

  @override
  void initState() {
    super.initState();
    final compareProvider = Provider.of<CompareProvider>(context, listen: false);
    
    // Initialize colleges: use widget constructor first, fallback to provider list
    _college1 = widget.college1;
    _college2 = widget.college2;

    if (_college1 == null && compareProvider.compareList.isNotEmpty) {
      _college1 = compareProvider.compareList[0];
    }
    if (_college2 == null && compareProvider.compareList.length > 1) {
      _college2 = compareProvider.compareList[1];
    }
  }

  void _showCollegeSelector(int slot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CollegeSearchSheet(
        excludeId: slot == 1 ? _college2?.id : _college1?.id,
        onSelected: (college) {
          setState(() {
            if (slot == 1) {
              _college1 = college;
            } else {
              _college2 = college;
            }
          });
          // Sync back to CompareProvider if appropriate
          final compareProvider = Provider.of<CompareProvider>(context, listen: false);
          compareProvider.clearCompare();
          if (_college1 != null) compareProvider.toggleCompare(_college1!);
          if (_college2 != null) compareProvider.toggleCompare(_college2!);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E14) : const Color(0xFFF4F6FF),
      appBar: AppBar(
        title: Text(
          'Compare Colleges',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: 'Reset Comparison',
            onPressed: () {
              setState(() {
                _college1 = null;
                _college2 = null;
              });
              Provider.of<CompareProvider>(context, listen: false).clearCompare();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Interactive Selectors
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSelectorSlot(1, _college1, theme, isDark)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'VS',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildSelectorSlot(2, _college2, theme, isDark)),
              ],
            ),
            const SizedBox(height: 32),

            // Comparison Results Table
            if (_college1 != null && _college2 != null) ...[
              _buildComparisonSection(theme, 'General Info', [
                _buildComparisonRow('Campus', _college1!.campus, _college2!.campus),
                _buildComparisonRow('Type', _college1!.type, _college2!.type),
                _buildComparisonRow('NIRF 2025', '#${_college1!.nirfRanking}', '#${_college2!.nirfRanking}'),
              ]),
              const SizedBox(height: 24),
              _buildComparisonSection(theme, 'Placements', [
                _buildComparisonRow(
                  'Highest Package', 
                  _college1!.placementInfo?.highestPackage ?? 'N/A', 
                  _college2!.placementInfo?.highestPackage ?? 'N/A',
                  highlightHigher: true,
                ),
                _buildComparisonRow(
                  'Average Package', 
                  _college1!.placementInfo?.averagePackage ?? 'N/A', 
                  _college2!.placementInfo?.averagePackage ?? 'N/A',
                  highlightHigher: true,
                ),
                _buildComparisonRow(
                  'Placement %', 
                  _college1!.placementInfo?.placementPercentage != null ? '${_college1!.placementInfo!.placementPercentage}%' : 'N/A', 
                  _college2!.placementInfo?.placementPercentage != null ? '${_college2!.placementInfo!.placementPercentage}%' : 'N/A',
                  highlightHigher: true,
                ),
              ]),
              const SizedBox(height: 24),
              _buildComparisonSection(theme, 'Facilities', [
                _buildComparisonRow('Hostel Fee', _college1!.hostelInfo?.fee ?? 'N/A', _college2!.hostelInfo?.fee ?? 'N/A'),
                _buildComparisonRow('Metro Connectivity', _college1!.nearbyMetro.split(',').first, _college2!.nearbyMetro.split(',').first),
              ]),
              const SizedBox(height: 40),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.gitCompare,
                        size: 64,
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select Two Colleges to Compare',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the slots above to choose colleges.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorSlot(int slot, CollegeModel? college, ThemeData theme, bool isDark) {
    if (college == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showCollegeSelector(slot),
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.plusCircle,
                  color: theme.colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'Select College',
                  style: GoogleFonts.outfit(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Image.network(
              college.logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                LucideIcons.building,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            college.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _showCollegeSelector(slot),
            icon: const Icon(LucideIcons.edit2, size: 12),
            label: Text(
              'Change',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(ThemeData theme, String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: rows,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonRow(
    String label, 
    String val1, 
    String val2, 
    {bool highlightHigher = false}
  ) {
    bool isHigher1 = false;
    bool isHigher2 = false;

    if (highlightHigher) {
      double? num1 = _parsePackageValue(val1);
      double? num2 = _parsePackageValue(val2);
      if (num1 != null && num2 != null) {
        if (num1 > num2) {
          isHigher1 = true;
        } else if (num2 > num1) {
          isHigher2 = true;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  val1,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold,
                    color: isHigher1 ? Colors.green : null,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  val2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 15, 
                    fontWeight: FontWeight.bold,
                    color: isHigher2 ? Colors.green : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double? _parsePackageValue(String package) {
    try {
      final cleaned = package.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }
}

class _CollegeSearchSheet extends StatefulWidget {
  final String? excludeId;
  final ValueChanged<CollegeModel> onSelected;

  const _CollegeSearchSheet({required this.onSelected, this.excludeId});

  @override
  State<_CollegeSearchSheet> createState() => _CollegeSearchSheetState();
}

class _CollegeSearchSheetState extends State<_CollegeSearchSheet> {
  String _searchQuery = '';
  List<CollegeModel> _filteredColleges = [];

  @override
  void initState() {
    super.initState();
    _filter();
  }

  void _filter() {
    setState(() {
      _filteredColleges = MockData.colleges.where((c) {
        if (c.id == widget.excludeId) return false;
        final matchSearch = _searchQuery.isEmpty || 
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.campus.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161C24) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select College',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) {
              _searchQuery = v;
              _filter();
            },
            decoration: InputDecoration(
              hintText: 'Search college name or campus...',
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _filteredColleges.isEmpty
                ? Center(
                    child: Text(
                      'No colleges found',
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredColleges.length,
                    itemBuilder: (context, index) {
                      final college = _filteredColleges[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        leading: Container(
                          height: 44,
                          width: 44,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Image.network(
                            college.logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              LucideIcons.building,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                        ),
                        title: Text(
                          college.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        subtitle: Text(
                          '${college.campus} • NIRF #${college.nirfRanking}',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () {
                          widget.onSelected(college);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
