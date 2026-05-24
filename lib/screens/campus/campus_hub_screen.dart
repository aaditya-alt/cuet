import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────

class PgListing {
  final int id;
  final String name;
  final String area;
  final String? fullAddress;
  final String campusZone;
  final String gender;
  final int rentMin;
  final int rentMax;
  final int? deposit;
  final List<String> roomTypes;
  final List<String> amenities;
  final bool mealsIncluded;
  final double? rating;
  final int reviewCount;
  final String? contactPhone;
  final String? nearestMetro;
  final int? walkingMinsToMetro;
  final String? description;
  final bool isVerified;
  final List<String> images;
  List<PgCollegeDistance> nearbyColleges;

  PgListing({
    required this.id,
    required this.name,
    required this.area,
    this.fullAddress,
    required this.campusZone,
    required this.gender,
    required this.rentMin,
    required this.rentMax,
    this.deposit,
    required this.roomTypes,
    required this.amenities,
    required this.mealsIncluded,
    this.rating,
    required this.reviewCount,
    this.contactPhone,
    this.nearestMetro,
    this.walkingMinsToMetro,
    this.description,
    required this.isVerified,
    required this.images,
    this.nearbyColleges = const [],
  });

  factory PgListing.fromJson(Map<String, dynamic> j) => PgListing(
    id: j['id'] as int,
    name: j['name'] as String? ?? '',
    area: j['area'] as String? ?? '',
    fullAddress: j['full_address'] as String?,
    campusZone: j['campus_zone'] as String? ?? 'Off Campus',
    gender: j['gender'] as String? ?? 'Co-Ed',
    rentMin: j['rent_min'] as int? ?? 0,
    rentMax: j['rent_max'] as int? ?? 0,
    deposit: j['deposit'] as int?,
    roomTypes: List<String>.from(j['room_types'] ?? []),
    amenities: List<String>.from(j['amenities'] ?? []),
    mealsIncluded: j['meals_included'] as bool? ?? false,
    rating: (j['rating'] as num?)?.toDouble(),
    reviewCount: j['review_count'] as int? ?? 0,
    contactPhone: j['contact_phone'] as String?,
    nearestMetro: j['nearest_metro'] as String?,
    walkingMinsToMetro: j['walking_mins_to_metro'] as int?,
    description: j['description'] as String?,
    isVerified: j['is_verified'] as bool? ?? false,
    images: List<String>.from(j['images'] ?? []),
  );
}

class PgCollegeDistance {
  final String collegeName;
  final int? distanceMins;
  final String distanceType;

  PgCollegeDistance({
    required this.collegeName,
    this.distanceMins,
    required this.distanceType,
  });

  factory PgCollegeDistance.fromJson(Map<String, dynamic> j) =>
      PgCollegeDistance(
        collegeName: j['college_name'] as String? ?? '',
        distanceMins: j['distance_mins'] as int?,
        distanceType: j['distance_type'] as String? ?? 'walk',
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SIMPLIFIED DU METRO MAP  (only DU-relevant stations)
// ─────────────────────────────────────────────────────────────────────────────

class _MetroStation {
  final String name;
  final String line;
  final Color lineColor;
  final List<String> nearbyColleges;

  const _MetroStation({
    required this.name,
    required this.line,
    required this.lineColor,
    this.nearbyColleges = const [],
  });
}

const List<_MetroStation> _duMetroStations = [
  _MetroStation(
    name: 'Vishwa Vidyalaya',
    line: 'Yellow Line',
    lineColor: Color(0xFFFFB300),
    nearbyColleges: [
      'Hindu College',
      'Miranda House',
      'St. Stephen\'s College',
      'Hansraj College',
      'Shri Ram College of Commerce',
      'Kirori Mal College',
    ],
  ),
  _MetroStation(
    name: 'Civil Lines',
    line: 'Yellow Line',
    lineColor: Color(0xFFFFB300),
    nearbyColleges: ['Indraprastha College for Women'],
  ),
  _MetroStation(
    name: 'GTB Nagar',
    line: 'Yellow Line',
    lineColor: Color(0xFFFFB300),
    nearbyColleges: ['Ramjas College', 'SGTB Khalsa College'],
  ),
  _MetroStation(
    name: 'Durgabai Deshmukh South Campus',
    line: 'Pink Line',
    lineColor: Color(0xFFE91E8C),
    nearbyColleges: [
      'Lady Shri Ram College for Women',
      'Maitreyi College',
      'Atma Ram Sanatan Dharma College',
      'Sri Venkateswara College',
      'Aryabhatta College',
      'Ram Lal Anand College',
    ],
  ),
  _MetroStation(
    name: 'Green Park',
    line: 'Yellow Line',
    lineColor: Color(0xFFFFB300),
    nearbyColleges: ['Gargi College'],
  ),
  _MetroStation(
    name: 'Hauz Khas',
    line: 'Yellow Line',
    lineColor: Color(0xFFFFB300),
    nearbyColleges: ['Kamala Nehru College', 'Institute of Home Economics'],
  ),
  _MetroStation(
    name: 'Malviya Nagar',
    line: 'Yellow Line',
    lineColor: Color(0xFFFFB300),
    nearbyColleges: [
      'Shaheed Bhagat Singh College',
      'College of Vocational Studies',
    ],
  ),
  _MetroStation(
    name: 'Lajpat Nagar',
    line: 'Violet Line',
    lineColor: Color(0xFF9C27B0),
    nearbyColleges: ['Lady Shri Ram College for Women', 'P.G.D.A.V. College'],
  ),
  _MetroStation(
    name: 'Moolchand',
    line: 'Violet Line',
    lineColor: Color(0xFF9C27B0),
    nearbyColleges: ['Lady Shri Ram College for Women'],
  ),
  _MetroStation(
    name: 'Govind Puri',
    line: 'Violet Line',
    lineColor: Color(0xFF9C27B0),
    nearbyColleges: [
      'Deshbandhu College',
      'Acharya Narendra Dev College',
      'Ramanujan College',
    ],
  ),
  _MetroStation(
    name: 'Netaji Subhash Place',
    line: 'Red Line',
    lineColor: Color(0xFFE53935),
    nearbyColleges: [
      'Sri Guru Gobind Singh College of Commerce',
      'Keshav Mahavidyalaya',
    ],
  ),
  _MetroStation(
    name: 'Rohini East',
    line: 'Red Line',
    lineColor: Color(0xFFE53935),
    nearbyColleges: ['Shaheed Sukhdev College of Business Studies'],
  ),
  _MetroStation(
    name: 'Dwarka Mor',
    line: 'Blue Line',
    lineColor: Color(0xFF1565C0),
    nearbyColleges: [
      'Bhaskaracharya College of Applied Sciences',
      'Deen Dayal Upadhyaya College',
    ],
  ),
  _MetroStation(
    name: 'Lok Kalyan Marg',
    line: 'Yellow Line',
    lineColor: Color(0xFFFFB300),
    nearbyColleges: ['Jesus and Mary College'],
  ),
  _MetroStation(
    name: 'Karol Bagh',
    line: 'Blue Line',
    lineColor: Color(0xFF1565C0),
    nearbyColleges: [
      'Janki Devi Memorial College',
      'Sri Guru Nanak Dev Khalsa College',
    ],
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CampusHubScreen extends StatefulWidget {
  const CampusHubScreen({super.key});

  @override
  State<CampusHubScreen> createState() => _CampusHubScreenState();
}

class _CampusHubScreenState extends State<CampusHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Metro tab
  _MetroStation? _selectedStation;

  // PG tab
  List<PgListing> _pgListings = [];
  bool _pgLoading = true;
  String? _pgError;
  String _pgCampusFilter = 'All';
  String _pgGenderFilter = 'All';
  String _pgSearchQuery = '';
  final TextEditingController _pgSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedStation = _duMetroStations.first;
    _fetchPgListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pgSearchCtrl.dispose();
    super.dispose();
  }

  // ── Data fetch ─────────────────────────────────────────────────────────────

  Future<void> _fetchPgListings() async {
    setState(() {
      _pgLoading = true;
      _pgError = null;
    });
    try {
      final client = Supabase.instance.client;

      // Fetch PGs
      final pgRes = await client
          .from('du_pg_listings')
          .select()
          .eq('is_active', true)
          .order('rating', ascending: false);

      final listings = (pgRes as List)
          .map((r) => PgListing.fromJson(r))
          .toList();

      // Fetch all college associations in one query
      final mapRes = await client
          .from('du_pg_college_map')
          .select('pg_id, college_name, distance_mins, distance_type');

      final Map<int, List<PgCollegeDistance>> assocMap = {};
      for (final row in mapRes as List) {
        final pgId = row['pg_id'] as int;
        assocMap.putIfAbsent(pgId, () => []);
        assocMap[pgId]!.add(PgCollegeDistance.fromJson(row));
      }

      for (final pg in listings) {
        pg.nearbyColleges = assocMap[pg.id] ?? [];
        pg.nearbyColleges.sort(
          (a, b) => (a.distanceMins ?? 999).compareTo(b.distanceMins ?? 999),
        );
      }

      if (mounted) {
        setState(() {
          _pgListings = listings;
          _pgLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pgError = 'Could not load PG listings: $e';
          _pgLoading = false;
        });
      }
    }
  }

  List<PgListing> get _filteredPg {
    return _pgListings.where((pg) {
      final campusOk =
          _pgCampusFilter == 'All' ||
          pg.campusZone.toLowerCase().contains(_pgCampusFilter.toLowerCase());
      final genderOk =
          _pgGenderFilter == 'All' ||
          pg.gender == _pgGenderFilter ||
          pg.gender == 'Co-Ed';
      final q = _pgSearchQuery.toLowerCase();
      final searchOk =
          q.isEmpty ||
          pg.name.toLowerCase().contains(q) ||
          pg.area.toLowerCase().contains(q) ||
          pg.nearbyColleges.any((c) => c.collegeName.toLowerCase().contains(q));
      return campusOk && genderOk && searchOk;
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF080C12)
          : const Color(0xFFF2F4F8),
      appBar: _buildAppBar(theme, isDark),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMetroTab(theme, isDark), _buildPgTab(theme, isDark)],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0E1318) : Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Campus Hub',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
          Text(
            'Transit & Accommodation Guide',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 2.5, color: theme.colorScheme.primary),
          insets: const EdgeInsets.symmetric(horizontal: 20),
        ),
        labelStyle: GoogleFonts.dmSans(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 13),
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(text: '🚇  Metro Guide'),
          Tab(text: '🏠  PG & Stays'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1 — METRO
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMetroTab(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Station selector header
        Container(
          color: isDark ? const Color(0xFF0E1318) : Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a metro station',
                style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _duMetroStations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final st = _duMetroStations[i];
                    final isSel = _selectedStation?.name == st.name;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStation = st),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? st.lineColor
                              : st.lineColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: st.lineColor.withOpacity(isSel ? 1 : 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSel ? Colors.white : st.lineColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              st.name,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSel
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Station detail
        Expanded(
          child: _selectedStation == null
              ? const Center(child: Text('Select a station'))
              : _buildStationDetail(_selectedStation!, theme, isDark),
        ),
      ],
    );
  }

  Widget _buildStationDetail(
    _MetroStation station,
    ThemeData theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [station.lineColor, station.lineColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: station.lineColor.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.train,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            station.line,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${station.nearbyColleges.length} colleges nearby',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Colleges accessible from this station',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
          const SizedBox(height: 12),

          ...station.nearbyColleges.asMap().entries.map((entry) {
            final i = entry.key;
            final college = entry.value;
            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + i * 40),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141920) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: station.lineColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.building2,
                      color: station.lineColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      college,
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0D1117),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Accessible',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // All-lines legend
          Text(
            'All DU Metro Lines',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0D1117),
            ),
          ),
          const SizedBox(height: 12),
          _buildLineLegend(isDark),
        ],
      ),
    );
  }

  Widget _buildLineLegend(bool isDark) {
    final lines = {
      'Yellow Line': const Color(0xFFFFB300),
      'Pink Line': const Color(0xFFE91E8C),
      'Violet Line': const Color(0xFF9C27B0),
      'Red Line': const Color(0xFFE53935),
      'Blue Line': const Color(0xFF1565C0),
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: lines.entries.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: e.value.withOpacity(0.1),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: e.value.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: e.value,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                e.key,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: e.value,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2 — PG LISTINGS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPgTab(ThemeData theme, bool isDark) {
    return Column(
      children: [
        // Search + filters
        Container(
          color: isDark ? const Color(0xFF0E1318) : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _pgSearchCtrl,
                onChanged: (v) => setState(() => _pgSearchQuery = v),
                style: GoogleFonts.dmSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by PG name, area or college…',
                  hintStyle: GoogleFonts.dmSans(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    size: 18,
                    color: Colors.grey,
                  ),
                  suffixIcon: _pgSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            _pgSearchCtrl.clear();
                            setState(() => _pgSearchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF141920)
                      : Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              // Filter chips row
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All Zones',
                            isSelected: _pgCampusFilter == 'All',
                            onTap: () =>
                                setState(() => _pgCampusFilter = 'All'),
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'North Campus',
                            isSelected: _pgCampusFilter == 'North',
                            onTap: () =>
                                setState(() => _pgCampusFilter = 'North'),
                            color: Colors.indigo,
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'South Campus',
                            isSelected: _pgCampusFilter == 'South',
                            onTap: () =>
                                setState(() => _pgCampusFilter = 'South'),
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            height: 20,
                            child: VerticalDivider(width: 1),
                          ),
                          const SizedBox(width: 12),
                          _FilterChip(
                            label: 'All',
                            isSelected: _pgGenderFilter == 'All',
                            onTap: () =>
                                setState(() => _pgGenderFilter = 'All'),
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Girls',
                            isSelected: _pgGenderFilter == 'Girls',
                            onTap: () =>
                                setState(() => _pgGenderFilter = 'Girls'),
                            color: Colors.pink,
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'Boys',
                            isSelected: _pgGenderFilter == 'Boys',
                            onTap: () =>
                                setState(() => _pgGenderFilter = 'Boys'),
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Results count
        if (!_pgLoading && _pgError == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredPg.length} listings found',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  color: Colors.grey,
                  onPressed: _fetchPgListings,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

        // Content
        Expanded(
          child: _pgLoading
              ? _buildPgShimmer(isDark)
              : _pgError != null
              ? _buildErrorState(_pgError!, isDark)
              : _filteredPg.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: _fetchPgListings,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filteredPg.length,
                    itemBuilder: (ctx, i) => _PgCard(
                      pg: _filteredPg[i],
                      isDark: isDark,
                      theme: theme,
                      onTap: () =>
                          _showPgDetail(context, _filteredPg[i], isDark, theme),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPgShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 180,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchPgListings,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No PGs match your filters',
            style: GoogleFonts.dmSans(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() {
              _pgCampusFilter = 'All';
              _pgGenderFilter = 'All';
              _pgSearchQuery = '';
              _pgSearchCtrl.clear();
            }),
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  // ── PG Detail Bottom Sheet ─────────────────────────────────────────────────

  void _showPgDetail(
    BuildContext context,
    PgListing pg,
    bool isDark,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PgDetailSheet(pg: pg, isDark: isDark, theme: theme),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PG CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _PgCard extends StatelessWidget {
  final PgListing pg;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onTap;

  const _PgCard({
    required this.pg,
    required this.isDark,
    required this.theme,
    required this.onTap,
  });

  Color get _genderColor {
    switch (pg.gender) {
      case 'Girls':
        return Colors.pink;
      case 'Boys':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  Color get _campusColor {
    if (pg.campusZone.contains('North')) return Colors.indigo;
    if (pg.campusZone.contains('South')) return Colors.teal;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141920) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _campusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      LucideIcons.home,
                      color: _campusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pg.name,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0D1117),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pg.isVerified)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  LucideIcons.badgeCheck,
                                  size: 12,
                                  color: Colors.blue,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 11,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              pg.area,
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tags row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Badge(label: pg.gender, color: _genderColor),
                  _Badge(label: pg.campusZone, color: _campusColor),
                  if (pg.mealsIncluded)
                    _Badge(label: 'Meals ✓', color: Colors.green),
                  if (pg.nearestMetro != null)
                    _Badge(
                      label: '🚇 ${pg.walkingMinsToMetro ?? '?'} min',
                      color: Colors.blueGrey,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  // Rent
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${_formatNum(pg.rentMin)} – ₹${_formatNum(pg.rentMax)}',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 16,
                            color: _campusColor,
                          ),
                        ),
                        Text(
                          'per month',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rating
                  if (pg.rating != null)
                    Row(
                      children: [
                        Icon(
                          LucideIcons.star,
                          size: 13,
                          color: Colors.amber.shade600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          pg.rating!.toStringAsFixed(1),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          ' (${pg.reviewCount})',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(width: 12),
                  // Arrow
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),

            // Nearby colleges strip
            if (pg.nearbyColleges.isNotEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Near:',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: pg.nearbyColleges
                            .take(4)
                            .map(
                              (c) => Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${c.collegeName.split(' ').take(3).join(' ')}${c.distanceMins != null ? ' · ${c.distanceMins}m' : ''}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return n.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PG DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _PgDetailSheet extends StatelessWidget {
  final PgListing pg;
  final bool isDark;
  final ThemeData theme;

  const _PgDetailSheet({
    required this.pg,
    required this.isDark,
    required this.theme,
  });

  Color get _campusColor {
    if (pg.campusZone.contains('North')) return Colors.indigo;
    if (pg.campusZone.contains('South')) return Colors.teal;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0E1318) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  // Name + verified
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pg.name,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 24,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0D1117),
                          ),
                        ),
                      ),
                      if (pg.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.badgeCheck,
                                size: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.mapPin, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pg.fullAddress ?? pg.area,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Rent card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _campusColor.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _campusColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₹${pg.rentMin.toString()} – ₹${pg.rentMax.toString()}',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 22,
                                  color: _campusColor,
                                ),
                              ),
                              Text(
                                'per month · Deposit ₹${pg.deposit?.toString() ?? 'Negotiable'}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (pg.rating != null)
                          Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.star,
                                    size: 16,
                                    color: Colors.amber.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pg.rating!.toStringAsFixed(1),
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${pg.reviewCount} reviews',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Room types
                  _SectionHeader(title: 'Room Types'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: pg.roomTypes
                        .map((r) => _Badge(label: r, color: _campusColor))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // Amenities
                  _SectionHeader(title: 'Amenities'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pg.amenities
                        .map((a) => _AmenityChip(label: a, isDark: isDark))
                        .toList(),
                  ),

                  const SizedBox(height: 20),

                  // Metro info
                  if (pg.nearestMetro != null) ...[
                    _SectionHeader(title: 'Metro Access'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.train,
                            color: Colors.blueAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              pg.nearestMetro!,
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Text(
                            '${pg.walkingMinsToMetro ?? '?'} min walk',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Nearby colleges
                  if (pg.nearbyColleges.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Nearby Colleges (${pg.nearbyColleges.length})',
                    ),
                    const SizedBox(height: 10),
                    ...pg.nearbyColleges.map(
                      (c) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.building2,
                              size: 14,
                              color: _campusColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.collegeName,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (c.distanceMins != null)
                              Text(
                                '${c.distanceMins} min ${c.distanceType}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  if (pg.description?.isNotEmpty == true) ...[
                    _SectionHeader(title: 'About'),
                    const SizedBox(height: 10),
                    Text(
                      pg.description!,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Contact button
                  if (pg.contactPhone != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.phone, size: 16),
                        label: Text(
                          'Contact: ${pg.contactPhone}',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _AmenityChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          color: isDark ? Colors.white70 : Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.3,
      ),
    );
  }
}
