import 'package:cuet/providers/du_community_service.dart';
import '../../providers/du_tracker_provider.dart';
import '../../providers/du_campus_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/notification_service.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/du_preference_service.dart';
import '../../models/du_models.dart';
import '../../data/mock_data.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _activeCategory = 'communications';
  String _activePanel = 'notifications';

  // Notification Form Controllers
  final _notifyFormKey = GlobalKey<FormState>();
  final _mainTextController = TextEditingController();
  final _subTextController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublishingNotification = false;

  // Guide Form Controllers
  final _guideFormKey = GlobalKey<FormState>();
  final _guideTitleController = TextEditingController();
  final _guideContentController = TextEditingController();
  String _selectedCategory = 'CSAS Guide';
  bool _isPublishingGuide = false;

  // Users Tab Variables & Controllers
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoadingUsers = false;
  final _searchController = TextEditingController();

  // Banner Form Controllers
  final _bannerFormKey = GlobalKey<FormState>();
  final _bannerTitleController = TextEditingController();
  final _bannerSubtitleController = TextEditingController();
  final _bannerActionUrlController = TextEditingController();
  final _bannerBgColorController = TextEditingController(text: '#3498FF');
  bool _isPublishingBanner = false;

  // Timeline Form Controllers
  final _timelineFormKey = GlobalKey<FormState>();
  final _timelineTitleController = TextEditingController();
  final _timelineDateController = TextEditingController();
  final _timelineTimeController = TextEditingController();
  final _timelineDescController = TextEditingController();
  final _timelineSortController = TextEditingController(text: '0');
  bool _isPublishingTimeline = false;

  // CSAS Tracker Deadline Controllers
  final _trackerP1Controller = TextEditingController(
    text: '2026-06-15 23:59:59',
  );
  final _trackerP2Controller = TextEditingController(
    text: '2026-07-05 23:59:59',
  );
  final _trackerP3Controller = TextEditingController(
    text: '2026-07-20 23:59:59',
  );
  bool _isSavingDeadlines = false;

  // Campus Hub Form Controllers
  final _campusFormKey = GlobalKey<FormState>();
  final _campusCollegeNameController = TextEditingController();
  final _campusNearestMetroController = TextEditingController();
  final _campusWalkingDistanceController = TextEditingController(text: '10');
  final _campusRickshawFareController = TextEditingController(text: '10');
  final _campusPgRentController = TextEditingController(text: '10000');
  final _campusDescriptionController = TextEditingController();
  String _campusSelectedType = 'North';
  String _campusSelectedLine = 'Yellow';
  double _campusSelectedSafety = 4.8;
  bool _isPublishingCampusGuide = false;

  // PG Accommodation Form Controllers & State
  final _pgFormKey = GlobalKey<FormState>();
  final _pgNameController = TextEditingController();
  final _pgAreaController = TextEditingController();
  final _pgAddressController = TextEditingController();
  final _pgMinRentController = TextEditingController();
  final _pgMaxRentController = TextEditingController();
  final _pgDepositController = TextEditingController();
  final _pgContactPhoneController = TextEditingController();
  final _pgContactEmailController = TextEditingController();
  final _pgMapsUrlController = TextEditingController();
  final _pgNearestMetroController = TextEditingController();
  final _pgMetroMinsController = TextEditingController();
  final _pgDescriptionController = TextEditingController();
  final _pgImagesController = TextEditingController();

  String _pgSelectedCampusZone = 'North Campus';
  String _pgSelectedGender = 'Co-Ed';
  bool _pgMealsIncluded = false;
  bool _pgIsVerified = false;
  bool _pgIsActive = true;
  double _pgRating = 4.5;
  int _pgReviewCount = 0;

  final Set<String> _pgSelectedRoomTypes = {'Single', 'Double'};
  final Set<String> _pgSelectedAmenities = {'Wi-Fi', 'CCTV', 'RO Water'};

  List<Map<String, dynamic>> _pgNearbyColleges = [];
  int? _editingPgId;
  bool _isSavingPg = false;
  bool _isLoadingPgs = false;
  List<Map<String, dynamic>> _allPgs = [];
  bool _isShowingPgs = false;

  // Preference sheets tab variables
  List<DuPreferenceSheet> _adminSheets = [];
  bool _isLoadingSheets = false;

  // Chat Mod tab variables
  List<CommunityMessage> _adminMessages = [];
  String _selectedModChannel = 'All';
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _fetchUsers();
    _fetchPremiumFlag();
    _fetchPreferenceSheets();
    _fetchCommunityMessages();
    _fetchAdminPgs();
    Provider.of<DuCampusService>(context, listen: false).fetchGuides();
  }

  bool _premiumEnabled = false; // remote state
  bool _isLoading = true;

  Future<void> _fetchPremiumFlag() async {
    try {
      final res = await Supabase.instance.client
          .from('admin')
          .select('premium_enabled')
          .eq('id', 1)
          .single();
      setState(() {
        _premiumEnabled = res['premium_enabled'] as bool;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePremiumFlag(bool value) async {
    try {
      await Supabase.instance.client
          .from('admin')
          .update({'premium_enabled': value})
          .eq('id', 1);
      setState(() => _premiumEnabled = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'Premium features tab enabled system-wide! 👑'
                  : 'Premium features tab disabled system-wide!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // revert on failure
      setState(() => _premiumEnabled = !value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update. Please try again.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mainTextController.dispose();
    _subTextController.dispose();
    _descriptionController.dispose();
    _guideTitleController.dispose();
    _guideContentController.dispose();
    _bannerTitleController.dispose();
    _bannerSubtitleController.dispose();
    _bannerActionUrlController.dispose();
    _bannerBgColorController.dispose();
    _timelineTitleController.dispose();
    _timelineDateController.dispose();
    _timelineTimeController.dispose();
    _timelineDescController.dispose();
    _timelineSortController.dispose();
    _trackerP1Controller.dispose();
    _trackerP2Controller.dispose();
    _trackerP3Controller.dispose();
    _campusCollegeNameController.dispose();
    _campusNearestMetroController.dispose();
    _campusWalkingDistanceController.dispose();
    _campusRickshawFareController.dispose();
    _campusPgRentController.dispose();
    _campusDescriptionController.dispose();
    _pgNameController.dispose();
    _pgAreaController.dispose();
    _pgAddressController.dispose();
    _pgMinRentController.dispose();
    _pgMaxRentController.dispose();
    _pgDepositController.dispose();
    _pgContactPhoneController.dispose();
    _pgContactEmailController.dispose();
    _pgMapsUrlController.dispose();
    _pgNearestMetroController.dispose();
    _pgMetroMinsController.dispose();
    _pgDescriptionController.dispose();
    _pgImagesController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminSignOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_admin_logged_in', false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out of Admin Portal'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoadingUsers = true);

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .order('created_at', ascending: false);

      if (response != null && response is List) {
        if (mounted) {
          setState(() {
            _users = List<Map<String, dynamic>>.from(response);
            _filteredUsers = _users;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching registered users: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to fetch user list: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  void _filterUsers(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        final phone = (user['phone'] ?? '').toString();
        final course = (user['course'] ?? '').toString().toLowerCase();
        return name.contains(q) ||
            email.contains(q) ||
            phone.contains(q) ||
            course.contains(q);
      }).toList();
    });
  }

  // ─── Fetch all PGs for admin list ─────────────────────────────────────────
  Future<void> _fetchAdminPgs() async {
    if (!mounted) return;
    setState(() => _isLoadingPgs = true);
    try {
      final res = await Supabase.instance.client
          .from('du_pg_listings')
          .select()
          .order('id', ascending: false);
      if (mounted) {
        setState(() {
          _allPgs = List<Map<String, dynamic>>.from(res);
          _isLoadingPgs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPgs = false);
      debugPrint('fetchAdminPgs error: $e');
    }
  }

  // ─── Clear PG form ────────────────────────────────────────────────────────
  void _clearPgForm() {
    setState(() => _editingPgId = null);
    _pgNameController.clear();
    _pgAreaController.clear();
    _pgAddressController.clear();
    _pgMinRentController.clear();
    _pgMaxRentController.clear();
    _pgDepositController.clear();
    _pgContactPhoneController.clear();
    _pgContactEmailController.clear();
    _pgMapsUrlController.clear();
    _pgNearestMetroController.clear();
    _pgMetroMinsController.clear();
    _pgDescriptionController.clear();
    _pgImagesController.clear();
    _pgSelectedCampusZone = 'North Campus';
    _pgSelectedGender = 'Co-Ed';
    _pgMealsIncluded = false;
    _pgIsVerified = false;
    _pgIsActive = true;
    _pgRating = 4.5;
    _pgReviewCount = 0;
    _pgSelectedRoomTypes
      ..clear()
      ..addAll({'Single', 'Double'});
    _pgSelectedAmenities
      ..clear()
      ..addAll({'Wi-Fi', 'CCTV', 'RO Water'});
    _pgNearbyColleges = [];
  }

  // ─── Populate form for edit ───────────────────────────────────────────────
  void _populatePgForm(Map<String, dynamic> pg) {
    setState(() {
      _editingPgId = pg['id'] as int;
      _pgNameController.text = pg['name'] ?? '';
      _pgAreaController.text = pg['area'] ?? '';
      _pgAddressController.text = pg['full_address'] ?? '';
      _pgMinRentController.text = (pg['rent_min'] ?? '').toString();
      _pgMaxRentController.text = (pg['rent_max'] ?? '').toString();
      _pgDepositController.text = (pg['deposit'] ?? '').toString();
      _pgContactPhoneController.text = pg['contact_phone'] ?? '';
      _pgContactEmailController.text = pg['contact_email'] ?? '';
      _pgMapsUrlController.text = pg['maps_url'] ?? '';
      _pgNearestMetroController.text = pg['nearest_metro'] ?? '';
      _pgMetroMinsController.text = (pg['walking_mins_to_metro'] ?? '')
          .toString();
      _pgDescriptionController.text = pg['description'] ?? '';
      _pgImagesController.text = (pg['images'] as List<dynamic>? ?? []).join(
        ', ',
      );
      _pgSelectedCampusZone = pg['campus_zone'] ?? 'North Campus';
      _pgSelectedGender = pg['gender'] ?? 'Co-Ed';
      _pgMealsIncluded = pg['meals_included'] ?? false;
      _pgIsVerified = pg['is_verified'] ?? false;
      _pgIsActive = pg['is_active'] ?? true;
      _pgRating = (pg['rating'] as num?)?.toDouble() ?? 4.5;
      _pgReviewCount = pg['review_count'] ?? 0;
      _pgSelectedRoomTypes
        ..clear()
        ..addAll(List<String>.from(pg['room_types'] ?? []));
      _pgSelectedAmenities
        ..clear()
        ..addAll(List<String>.from(pg['amenities'] ?? []));
    });
    // Scroll to form top (handled by SingleChildScrollView naturally)
  }

  // ─── Save PG (insert or update) ───────────────────────────────────────────
  Future<void> _savePg() async {
    if (!_pgFormKey.currentState!.validate()) return;
    setState(() => _isSavingPg = true);

    final images = _pgImagesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final payload = {
      'name': _pgNameController.text.trim(),
      'area': _pgAreaController.text.trim(),
      'full_address': _pgAddressController.text.trim().isEmpty
          ? null
          : _pgAddressController.text.trim(),
      'campus_zone': _pgSelectedCampusZone,
      'gender': _pgSelectedGender,
      'rent_min': int.tryParse(_pgMinRentController.text) ?? 0,
      'rent_max': int.tryParse(_pgMaxRentController.text) ?? 0,
      'deposit': _pgDepositController.text.trim().isEmpty
          ? null
          : int.tryParse(_pgDepositController.text),
      'room_types': _pgSelectedRoomTypes.toList(),
      'amenities': _pgSelectedAmenities.toList(),
      'meals_included': _pgMealsIncluded,
      'rating': _pgRating,
      'review_count': _pgReviewCount,
      'contact_phone': _pgContactPhoneController.text.trim().isEmpty
          ? null
          : _pgContactPhoneController.text.trim(),
      'contact_email': _pgContactEmailController.text.trim().isEmpty
          ? null
          : _pgContactEmailController.text.trim(),
      'maps_url': _pgMapsUrlController.text.trim().isEmpty
          ? null
          : _pgMapsUrlController.text.trim(),
      'nearest_metro': _pgNearestMetroController.text.trim().isEmpty
          ? null
          : _pgNearestMetroController.text.trim(),
      'walking_mins_to_metro': _pgMetroMinsController.text.trim().isEmpty
          ? null
          : int.tryParse(_pgMetroMinsController.text),
      'description': _pgDescriptionController.text.trim().isEmpty
          ? null
          : _pgDescriptionController.text.trim(),
      'images': images,
      'is_verified': _pgIsVerified,
      'is_active': _pgIsActive,
    };

    try {
      int pgId;
      if (_editingPgId != null) {
        await Supabase.instance.client
            .from('du_pg_listings')
            .update(payload)
            .eq('id', _editingPgId!);
        pgId = _editingPgId!;
      } else {
        final res = await Supabase.instance.client
            .from('du_pg_listings')
            .insert(payload)
            .select('id')
            .single();
        pgId = res['id'] as int;
      }

      // Save nearby college associations
      if (_pgNearbyColleges.isNotEmpty) {
        // Delete old associations first
        await Supabase.instance.client
            .from('du_pg_college_map')
            .delete()
            .eq('pg_id', pgId);

        // Insert new ones
        final associations = _pgNearbyColleges
            .where((c) => (c['college_name'] as String?)?.isNotEmpty == true)
            .map(
              (c) => {
                'pg_id': pgId,
                'college_name': c['college_name'],
                'distance_mins': c['distance_mins'],
                'distance_type': c['distance_type'] ?? 'walk',
              },
            )
            .toList();

        if (associations.isNotEmpty) {
          await Supabase.instance.client
              .from('du_pg_college_map')
              .insert(associations);
        }
      }

      if (mounted) {
        _showSuccessDialog(
          _editingPgId != null ? 'PG Updated!' : 'PG Added!',
          _editingPgId != null
              ? 'The PG listing has been updated successfully.'
              : 'New PG listing is now live for students.',
        );
        _clearPgForm();
        await _fetchAdminPgs();
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Save failed: $e');
    } finally {
      if (mounted) setState(() => _isSavingPg = false);
    }
  }

  // ─── Delete PG ────────────────────────────────────────────────────────────
  Future<void> _deletePg(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(LucideIcons.alertTriangle, color: Colors.red, size: 24),
            SizedBox(width: 10),
            Text('Delete PG?'),
          ],
        ),
        content: Text(
          'Permanently delete "$name" and all its college associations?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // College map rows deleted via CASCADE in schema
      await Supabase.instance.client
          .from('du_pg_listings')
          .delete()
          .eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PG deleted successfully.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _fetchAdminPgs();
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Delete failed: $e');
    }
  }

  Future<void> _publishNotification() async {
    if (_notifyFormKey.currentState!.validate()) {
      setState(() => _isPublishingNotification = true);

      try {
        final client = Supabase.instance.client;

        await client.from('notifications').insert({
          'main_text': _mainTextController.text.trim(),
          'sub_text': _subTextController.text.trim(),
          'description': _descriptionController.text.trim(),
        });

        // Trigger local notification provider reload instantly
        if (mounted) {
          Provider.of<NotificationService>(
            context,
            listen: false,
          ).fetchNotifications();

          _mainTextController.clear();
          _subTextController.clear();
          _descriptionController.clear();

          _showSuccessDialog(
            'Notification Published!',
            'Your announcement was broadcasted successfully to all users.',
          );
        }
      } catch (e) {
        debugPrint('Error publishing notification: $e');
        if (mounted) {
          _showErrorSnackBar('Publishing Failed: ${e.toString()}');
        }
      } finally {
        if (mounted) setState(() => _isPublishingNotification = false);
      }
    }
  }

  Future<void> _publishGuide() async {
    if (_guideFormKey.currentState!.validate()) {
      setState(() => _isPublishingGuide = true);

      try {
        final client = Supabase.instance.client;

        await client.from('updates').insert({
          'title': _guideTitleController.text.trim(),
          'content': _guideContentController.text.trim(),
          'category': _selectedCategory,
        });

        if (mounted) {
          _guideTitleController.clear();
          _guideContentController.clear();

          _showSuccessDialog(
            'CSAS Guide / Update Posted!',
            'The new counselling guide / update is now dynamic inside the app.',
          );
        }
      } catch (e) {
        debugPrint('Error posting guide update: $e');
        if (mounted) {
          // Check if table is missing
          if (e.toString().contains(
            'relation "public.updates" does not exist',
          )) {
            _showSqlMissingDialog();
          } else {
            _showErrorSnackBar('Guide Publishing Failed: ${e.toString()}');
          }
        }
      } finally {
        if (mounted) setState(() => _isPublishingGuide = false);
      }
    }
  }

  void _showSuccessDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(content, style: GoogleFonts.outfit()),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Great'),
          ),
        ],
      ),
    );
  }

  void _showSqlMissingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(
              LucideIcons.alertTriangle,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Missing Table "updates"',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'To make guides dynamic, you need to create the "public.updates" table in your Supabase SQL editor.\n\nSql command is documented in the implementation_plan.md artifact.',
          style: GoogleFonts.outfit(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E14)
          : const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'DUVerse Admin Portal 👑',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: Colors.red),
            onPressed: _handleAdminSignOut,
            tooltip: 'Sign Out Admin',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          // ── Tier 1: Main Category Segments ──────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161C24) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  _buildCategorySegment(
                    label: 'COMMUNS',
                    icon: LucideIcons.messageSquare,
                    category: 'communications',
                    defaultPanel: 'notifications',
                    theme: theme,
                  ),
                  _buildCategorySegment(
                    label: 'ACADEMICS',
                    icon: LucideIcons.bookOpen,
                    category: 'academics',
                    defaultPanel: 'study_material',
                    theme: theme,
                  ),
                  _buildCategorySegment(
                    label: 'CORE SYSTEM',
                    icon: LucideIcons.settings,
                    category: 'system',
                    defaultPanel: 'timeline',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Tier 2: Sub-Panel Chips ──────────────────────────────────────
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _buildSubPanelChips(theme),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Selected Dashboard Panel Content ──────────────────────────────
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF0D121B) : const Color(0xFFFAF9FF),
              child: _buildSelectedPanel(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySegment({
    required String label,
    required IconData icon,
    required String category,
    required String defaultPanel,
    required ThemeData theme,
  }) {
    final isSelected = _activeCategory == category;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeCategory = category;
            _activePanel = defaultPanel;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSubPanelChips(ThemeData theme) {
    if (_activeCategory == 'communications') {
      return [
        _buildChip(
          label: 'Announcements Publisher',
          icon: LucideIcons.bell,
          panel: 'notifications',
          theme: theme,
        ),
        _buildChip(
          label: 'Dashboard Banners',
          icon: LucideIcons.image,
          panel: 'banners',
          theme: theme,
        ),
        _buildChip(
          label: 'Community Chats Moderator',
          icon: LucideIcons.messageSquare,
          panel: 'forums',
          theme: theme,
        ),
      ];
    } else if (_activeCategory == 'academics') {
      return [
        _buildChip(
          label: 'Study Guides Panel',
          icon: LucideIcons.bookOpen,
          panel: 'study_material',
          theme: theme,
        ),
        _buildChip(
          label: 'Preference Sheets Auditor',
          icon: LucideIcons.listOrdered,
          panel: 'preference_sheets',
          theme: theme,
        ),
      ];
    } else {
      return [
        _buildChip(
          label: 'CSAS Timeline Planner',
          icon: LucideIcons.calendar,
          panel: 'timeline',
          theme: theme,
        ),
        _buildChip(
          label: 'Campus guides Moderator',
          icon: LucideIcons.mapPin,
          panel: 'campus_guides',
          theme: theme,
        ),
        _buildChip(
          label: 'System configurations',
          icon: LucideIcons.sliders,
          panel: 'config',
          theme: theme,
        ),
        _buildChip(
          label: 'Student Directory',
          icon: LucideIcons.users,
          panel: 'users',
          theme: theme,
        ),
      ];
    }
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required String panel,
    required ThemeData theme,
  }) {
    final isSelected = _activePanel == panel;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.white : theme.colorScheme.primary,
        ),
        label: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
          ),
        ),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.cardColor,
        onSelected: (val) {
          if (val) setState(() => _activePanel = panel);
        },
      ),
    );
  }

  Widget _buildSelectedPanel(ThemeData theme) {
    switch (_activePanel) {
      case 'notifications':
        return _buildAnnouncementsTab(theme);
      case 'banners':
        return _buildBannersTab(theme);
      case 'forums':
        return _buildChatModTab(theme);
      case 'study_material':
        return _buildGuideTab(theme);
      case 'preference_sheets':
        return _buildPreferenceSheetsTab(theme);
      case 'timeline':
        return _buildTimelineTab(theme);
      case 'campus_guides':
        return _buildCampusHubModTab(theme);
      case 'config':
        return _buildConfigTab(theme);
      case 'users':
        return _buildUsersTab(theme);
      default:
        return _buildAnnouncementsTab(theme);
    }
  }

  Widget _buildAnnouncementsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _notifyFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Publish Announcements',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sends a dynamic notification with local read tracking to all users.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _mainTextController,
              label: 'Title (main_text)',
              hint: 'E.g. Round 2 Allocation lists are out!',
              icon: LucideIcons.heading,
              validator: (val) => val!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _subTextController,
              label: 'Short Summary (sub_text)',
              hint: 'A quick 1-sentence recap shown in lists.',
              icon: LucideIcons.fileText,
              validator: (val) => val!.isEmpty ? 'Summary is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _descriptionController,
              label: 'Full Description (description)',
              hint: 'Complete, multi-paragraph markdown announcement text...',
              icon: LucideIcons.alignLeft,
              maxLines: 5,
              validator: (val) =>
                  val!.isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isPublishingNotification
                  ? null
                  : _publishNotification,
              icon: const Icon(LucideIcons.send),
              label: Text(
                'Publish Announcement',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _guideFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Post CSAS Guides & Updates',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Publishes structured items for dynamic guides or official alerts.',
              style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(LucideIcons.tag, size: 20),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'CSAS Guide',
                  child: Text('CSAS Guide (Dynamic Steps)'),
                ),
                DropdownMenuItem(
                  value: 'Alert',
                  child: Text('Important Alert (Red Highlights)'),
                ),
                DropdownMenuItem(
                  value: 'General Update',
                  child: Text('General counselling updates'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _guideTitleController,
              label: 'Title',
              hint: 'E.g. Phase II Choice filling rules',
              icon: LucideIcons.heading,
              validator: (val) => val!.isEmpty ? 'Title is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _guideContentController,
              label: 'Content Body',
              hint: 'Detailed steps, guidelines, or checklists for students...',
              icon: LucideIcons.alignLeft,
              maxLines: 6,
              validator: (val) =>
                  val!.isEmpty ? 'Content body is required' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isPublishingGuide ? null : _publishGuide,
              icon: const Icon(LucideIcons.filePlus),
              label: Text(
                'Publish Update Card',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        // Summary Stats and Search Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Users',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_users.length} Total',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _filterUsers,
                style: GoogleFonts.outfit(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, email, phone, or course...',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _filterUsers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0A0E14)
                      : const Color(0xFFF8F9FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // User List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchUsers,
            child: _isLoadingUsers && _users.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? _buildEmptyUsersState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final name = user['name'] ?? 'Anonymous';
                      final email = user['email'] ?? 'No email';
                      final phone = user['phone'] != null
                          ? user['phone'].toString()
                          : 'No phone';
                      final course = user['course'] ?? 'Not specified';
                      final createdAt = user['created_at'] != null
                          ? DateTime.tryParse(user['created_at']) ??
                                DateTime.now()
                          : DateTime.now();

                      final initials = name.isNotEmpty
                          ? name.substring(0, 1).toUpperCase()
                          : 'A';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // User Avatar Circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    initials,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Registered on ${_formatDate(createdAt)}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Course Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    course,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            // Contact details
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.mail,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    email,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.copy,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: email),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Email copied to clipboard',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.phone,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    phone,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.copy,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: phone),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Phone number copied to clipboard',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyUsersState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.users,
                  size: 64,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Registered Students',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh or check if students have completed registration in the signup page.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.outfit(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Icon(icon, size: 20),
        ),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildBannersTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Push Dashboard Banner',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _bannerFormKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _bannerTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Banner Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerSubtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Subtitle (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerActionUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Action URL (Optional Deep Link)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bannerBgColorController,
                      decoration: const InputDecoration(
                        labelText: 'Background Hex Color (e.g. #FF5555)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishingBanner ? null : _publishBanner,
                        icon: _isPublishingBanner
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(LucideIcons.send),
                        label: Text(
                          _isPublishingBanner
                              ? 'Publishing...'
                              : 'Publish Banner',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _publishBanner() async {
    if (!_bannerFormKey.currentState!.validate()) return;
    setState(() => _isPublishingBanner = true);
    try {
      await Supabase.instance.client.from('dashboard_banners').insert({
        'title': _bannerTitleController.text,
        'subtitle': _bannerSubtitleController.text,
        'action_url': _bannerActionUrlController.text,
        'bg_color': _bannerBgColorController.text,
      });
      _bannerTitleController.clear();
      _bannerSubtitleController.clear();
      _bannerActionUrlController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Banner published!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isPublishingBanner = false);
    }
  }

  Future<void> _toggleEventField(int id, String field, bool newValue) async {
    try {
      await Supabase.instance.client
          .from('csas_timeline')
          .update({field: newValue})
          .eq('id', id);
      await _loadTimelineEvents();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  // ── Paste these controllers & state variables in your admin State class ──────

  // Timeline

  final _tlTitleController = TextEditingController();
  final _tlDateController = TextEditingController();
  final _tlTimeController = TextEditingController();
  final _tlDescController = TextEditingController();
  final _tlSortController = TextEditingController(text: '0');
  final _tlLinkUrlController = TextEditingController();
  final _tlLinkLabelController = TextEditingController();
  String _tlCategory = 'General';
  String _tlIconName = 'calendar';
  bool _tlIsImportant = false;

  int? _editingEventId; // null = creating new, non-null = editing existing
  List<Map<String, dynamic>> _allTimelineEvents = [];
  bool _loadingTimelineEvents = true;

  Future<void> _loadTimelineEvents() async {
    setState(() => _loadingTimelineEvents = true);
    try {
      final res = await Supabase.instance.client
          .from('csas_timeline')
          .select()
          .order('sort_order');
      setState(() {
        _allTimelineEvents = List<Map<String, dynamic>>.from(res);
        _loadingTimelineEvents = false;
      });
    } catch (e) {
      setState(() => _loadingTimelineEvents = false);
    }
  }

  void _populateFormForEdit(Map<String, dynamic> event) {
    setState(() {
      _editingEventId = event['id'] as int;
      _tlTitleController.text = event['title'] ?? '';
      _tlDateController.text = event['event_date'] ?? '';
      _tlTimeController.text = event['event_time'] ?? '';
      _tlDescController.text = event['description'] ?? '';
      _tlSortController.text = (event['sort_order'] ?? 0).toString();
      _tlLinkUrlController.text = event['link_url'] ?? '';
      _tlLinkLabelController.text = event['link_label'] ?? '';
      _tlCategory = event['category'] ?? 'General';
      _tlIconName = event['icon_name'] ?? 'calendar';
      _tlIsImportant = event['is_important'] ?? false;
    });
  }

  void _clearTimelineForm() {
    setState(() => _editingEventId = null);
    _tlTitleController.clear();
    _tlDateController.clear();
    _tlTimeController.clear();
    _tlDescController.clear();
    _tlSortController.text = '0';
    _tlLinkUrlController.clear();
    _tlLinkLabelController.clear();
    _tlCategory = 'General';
    _tlIconName = 'calendar';
    _tlIsImportant = false;
  }

  Future<void> _saveTimelineEvent() async {
    if (!_timelineFormKey.currentState!.validate()) return;
    setState(() => _isPublishingTimeline = true);

    final payload = {
      'title': _tlTitleController.text.trim(),
      'event_date': _tlDateController.text.trim(),
      'event_time': _tlTimeController.text.trim(),
      'description': _tlDescController.text.trim(),
      'sort_order': int.tryParse(_tlSortController.text) ?? 0,
      'category': _tlCategory,
      'icon_name': _tlIconName,
      'is_important': _tlIsImportant,
      'link_url': _tlLinkUrlController.text.trim().isEmpty
          ? null
          : _tlLinkUrlController.text.trim(),
      'link_label': _tlLinkLabelController.text.trim().isEmpty
          ? null
          : _tlLinkLabelController.text.trim(),
      'is_active': true,
    };

    try {
      if (_editingEventId != null) {
        await Supabase.instance.client
            .from('csas_timeline')
            .update(payload)
            .eq('id', _editingEventId!);
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Event updated!'),
              backgroundColor: Colors.green,
            ),
          );
      } else {
        await Supabase.instance.client.from('csas_timeline').insert({
          ...payload,
          'is_completed': false,
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Event added!'),
              backgroundColor: Colors.green,
            ),
          );
      }
      _clearTimelineForm();
      await _loadTimelineEvents();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isPublishingTimeline = false);
    }
  }

  Future<void> _deleteTimelineEvent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This will permanently remove the timeline event.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Supabase.instance.client
          .from('csas_timeline')
          .delete()
          .eq('id', id);
      await _loadTimelineEvents();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Widget _buildTimelineTab(ThemeData theme) {
    const categories = [
      'General',
      'Registration',
      'Choice Filling',
      'Allotment',
      'Fees',
    ];
    const icons = [
      'calendar',
      'user-plus',
      'credit-card',
      'list-ordered',
      'lock',
      'eye',
      'award',
      'banknote',
      'refresh-cw',
      'flag',
      'check-circle-2',
      'file-text',
      'alert-triangle',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── FORM SECTION ──────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                _editingEventId != null
                    ? LucideIcons.edit3
                    : LucideIcons.calendarPlus,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                _editingEventId != null
                    ? 'Edit Event #$_editingEventId'
                    : 'Add Timeline Event',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_editingEventId != null)
                TextButton.icon(
                  onPressed: _clearTimelineForm,
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: const Text('Cancel Edit'),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _timelineFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _tlTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Date + Time
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tlDateController,
                            decoration: const InputDecoration(
                              labelText: 'Date (e.g. 28 May 2026) *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.calendar, size: 16),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _tlTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Time (e.g. 11:00 AM)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.clock, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: _tlDescController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category + Sort Order
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _tlCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _tlCategory = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _tlSortController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Sort Order',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Icon
                    DropdownButtonFormField<String>(
                      value: _tlIconName,
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        border: OutlineInputBorder(),
                      ),
                      items: icons
                          .map(
                            (ic) =>
                                DropdownMenuItem(value: ic, child: Text(ic)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _tlIconName = v!),
                    ),
                    const SizedBox(height: 14),

                    // Link URL + Label
                    TextFormField(
                      controller: _tlLinkUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Action Link URL (optional)',
                        hintText: 'https://admission.uod.ac.in',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.link, size: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _tlLinkLabelController,
                      decoration: const InputDecoration(
                        labelText: 'Link Button Label (optional)',
                        hintText: 'Apply Now',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Is Important toggle
                    SwitchListTile(
                      title: Text(
                        'Mark as Important',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Shows red badge on student timeline',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      value: _tlIsImportant,
                      activeColor: Colors.red,
                      onChanged: (v) => setState(() => _tlIsImportant = v),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isPublishingTimeline
                            ? null
                            : _saveTimelineEvent,
                        icon: _isPublishingTimeline
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _editingEventId != null
                                    ? LucideIcons.save
                                    : LucideIcons.calendarPlus,
                              ),
                        label: Text(
                          _isPublishingTimeline
                              ? 'Saving...'
                              : _editingEventId != null
                              ? 'Update Event'
                              : 'Add Event',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── EVENTS LIST ───────────────────────────────────────────────────
          Row(
            children: [
              Text(
                'All Events (${_allTimelineEvents.length})',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: _loadTimelineEvents,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_loadingTimelineEvents)
            const Center(child: CircularProgressIndicator())
          else if (_allTimelineEvents.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No events yet. Add one above.',
                  style: GoogleFonts.outfit(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allTimelineEvents.length,
              itemBuilder: (ctx, i) {
                final e = _allTimelineEvents[i];
                final id = e['id'] as int;
                final isCompleted = e['is_completed'] as bool? ?? false;
                final isActive = e['is_active'] as bool? ?? true;
                final isImportant = e['is_important'] as bool? ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e['title'] ?? '',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${e['event_date'] ?? ''}'
                                    '${(e['event_time'] ?? '').isNotEmpty ? '  ·  ${e['event_time']}' : ''}'
                                    '  ·  Sort: ${e['sort_order'] ?? 0}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit
                            IconButton(
                              icon: const Icon(
                                LucideIcons.edit3,
                                size: 18,
                                color: Colors.blue,
                              ),
                              onPressed: () => _populateFormForEdit(e),
                              tooltip: 'Edit',
                            ),
                            // Delete
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                size: 18,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteTimelineEvent(id),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),

                        // Badges
                        Wrap(
                          spacing: 8,
                          children: [
                            _AdminBadge(
                              e['category'] ?? 'General',
                              Colors.blue,
                            ),
                            if (isImportant)
                              _AdminBadge('Important', Colors.red),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Toggles
                        Row(
                          children: [
                            // Completed toggle
                            _ToggleChip(
                              label: 'Completed',
                              value: isCompleted,
                              activeColor: Colors.green,
                              onChanged: (v) =>
                                  _toggleEventField(id, 'is_completed', v),
                            ),
                            const SizedBox(width: 10),
                            // Active/Draft toggle
                            _ToggleChip(
                              label: isActive ? 'Live' : 'Draft',
                              value: isActive,
                              activeColor: Colors.blue,
                              onChanged: (v) =>
                                  _toggleEventField(id, 'is_active', v),
                            ),
                          ],
                        ),

                        // Link info
                        if ((e['link_url'] ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.link,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    e['link_url'] ?? '',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Small helper widgets ──────────────────────────────────────────────────────

  Widget _AdminBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _publishTimelineEvent() async {
    if (!_timelineFormKey.currentState!.validate()) return;
    setState(() => _isPublishingTimeline = true);
    try {
      await Supabase.instance.client.from('csas_timeline').insert({
        'title': _timelineTitleController.text,
        'event_date': _timelineDateController.text,
        'event_time': _timelineTimeController.text,
        'description': _timelineDescController.text,
        'sort_order': int.tryParse(_timelineSortController.text) ?? 0,
        'is_completed': false,
      });
      _timelineTitleController.clear();
      _timelineDateController.clear();
      _timelineTimeController.clear();
      _timelineDescController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Timeline event added!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isPublishingTimeline = false);
    }
  }

  Widget _buildConfigTab(ThemeData theme) {
    final appSettings = Provider.of<AppSettingsProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Configurations',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Toggle system-wide feature flags and access controls locally and remotely.',
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161C24) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.crown,
                    color: Colors.amber,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable Premium Features Tab',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When turned on, the "Premium" tab is visible in the bottom navigation bar for all users.',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _premiumEnabled,
                  activeColor: theme.colorScheme.primary,
                  onChanged: _updatePremiumFlag,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchPreferenceSheets() async {
    if (!mounted) return;
    setState(() => _isLoadingSheets = true);
    try {
      final sheets = await Provider.of<DuPreferenceService>(
        context,
        listen: false,
      ).fetchAllSheetsForAdmin();
      if (mounted) {
        setState(() {
          _adminSheets = sheets;
          _isLoadingSheets = false;
        });
      }
    } catch (e) {
      debugPrint('Admin error fetching sheets: $e');
      if (mounted) {
        // Fallback to local storage sheets so admin can test offline/local fallback!
        final localService = Provider.of<DuPreferenceService>(
          context,
          listen: false,
        );
        await localService.loadLocalSheets();
        setState(() {
          _adminSheets = localService.localSheets;
          _isLoadingSheets = false;
        });
      }
    }
  }

  void _confirmDeleteSheet(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'Delete Report?',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this student\'s preference sheet report?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );
              await Provider.of<DuPreferenceService>(
                context,
                listen: false,
              ).deleteSheet(id, fromSupabaseOnly: true);
              if (mounted) {
                Navigator.pop(context);
                _fetchPreferenceSheets();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewGeneratedSheet(DuPreferenceSheet sheet) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sheet.userName,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            sheet.userEmail,
                            style: GoogleFonts.outfit(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: sheet.sheetData.length,
                    itemBuilder: (context, index) {
                      final item = sheet.sheetData[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161C24)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index < 3
                                    ? theme.colorScheme.primary
                                    : Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.outfit(
                                  color: index < 3
                                      ? Colors.white
                                      : theme.textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['collegeName'] ?? '',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['programName'] ?? '',
                                    style: GoogleFonts.outfit(
                                      color: theme.colorScheme.secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySheetsState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.listOrdered,
                  size: 64,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Generated Sheets Yet',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh. Once students generate preference sheets in the app, their customized reports will appear here in real-time!',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.grey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceSheetsTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Student Preference Sheet Reports',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_adminSheets.length} Generated',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchPreferenceSheets,
            child: _isLoadingSheets && _adminSheets.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _adminSheets.isEmpty
                ? _buildEmptySheetsState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _adminSheets.length,
                    itemBuilder: (context, index) {
                      final sheet = _adminSheets[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sheet.userName,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        sheet.userEmail,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDate(sheet.createdAt!),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                _buildSheetBadge(
                                  'Campus',
                                  sheet.campusPreference,
                                  Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                _buildSheetBadge(
                                  'Priority',
                                  sheet.priorityFactor,
                                  Colors.blue,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Target Courses:',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: sheet.targetCourses.map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    c,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _viewGeneratedSheet(sheet),
                                    icon: const Icon(LucideIcons.eye, size: 16),
                                    label: const Text('View Full List'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _confirmDeleteSheet(sheet.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _fetchCommunityMessages() async {
    if (!mounted) return;
    setState(() => _isLoadingMessages = true);
    try {
      final messages = await Provider.of<DuCommunityService>(
        context,
        listen: false,
      ).fetchAllMessagesForAdmin();
      if (mounted) {
        setState(() {
          _adminMessages = messages;
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Admin error fetching messages: $e');
      if (mounted) {
        setState(() => _isLoadingMessages = false);
      }
    }
  }

  void _confirmDeleteMessage(CommunityMessage msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(LucideIcons.alertTriangle, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Remove Message?'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete this message by "${msg.userName}" from the Community Hub?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );
              await Provider.of<DuCommunityService>(
                context,
                listen: false,
              ).deleteMessage(msg.id, msg.channel);
              if (mounted) {
                Navigator.pop(context);
                _fetchCommunityMessages();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Color _getChannelColor(String channel) {
    switch (channel) {
      case 'general':
        return Colors.indigo;
      case 'commerce':
        return Colors.green;
      case 'science':
        return Colors.orange;
      case 'humanities':
        return Colors.pink;
      default:
        return Colors.blue;
    }
  }

  Widget _buildChatModTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    final filteredMessages = _adminMessages.where((msg) {
      if (_selectedModChannel == 'All') return true;
      return msg.channel == _selectedModChannel.toLowerCase();
    }).toList();

    return Column(
      children: [
        // Channel filter header
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF161C24) : Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Moderation Hub',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              DropdownButton<String>(
                value: _selectedModChannel,
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(16),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                items: ['All', 'General', 'Commerce', 'Science', 'Humanities']
                    .map((ch) {
                      return DropdownMenuItem<String>(
                        value: ch,
                        child: Text(ch),
                      );
                    })
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedModChannel = val);
                  }
                },
              ),
            ],
          ),
        ),

        // Messages Mod List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchCommunityMessages,
            child: _isLoadingMessages && filteredMessages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredMessages.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.messageSquare,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Messages Found',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No messages match the active channel filter, or no messages have been generated yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filteredMessages.length,
                    itemBuilder: (context, index) {
                      final msg = filteredMessages[index];
                      final badgeColor = _getChannelColor(msg.channel);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            msg.userName,
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              msg.channel.toUpperCase(),
                                              style: GoogleFonts.outfit(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: badgeColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        msg.userEmail,
                                        style: GoogleFonts.outfit(
                                          fontSize: 11,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _confirmDeleteMessage(msg),
                                  tooltip: 'Delete and Moderate Message',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF161C24)
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                msg.message,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                _formatDate(msg.createdAt),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REPLACE _buildCampusHubModTab with this method
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCampusHubModTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    // Available options
    const campusZones = ['North Campus', 'South Campus', 'Off Campus'];
    const genders = ['Co-Ed', 'Girls', 'Boys'];
    const roomTypeOptions = ['Single', 'Double', 'Triple', 'Quadruple'];
    const amenityOptions = [
      'Wi-Fi',
      'AC',
      'Meals',
      'CCTV',
      'Laundry',
      'Gym',
      'RO Water',
      'Geyser',
      'Inverter',
      'Parking',
      'Medical Room',
      'Security',
    ];
    const duColleges = [
      'Shri Ram College of Commerce',
      'Hindu College',
      'Miranda House',
      'Lady Shri Ram College for Women',
      'Hansraj College',
      'Kirori Mal College',
      'Ramjas College',
      'St. Stephen\'s College',
      'Indraprastha College for Women',
      'Sri Guru Tegh Bahadur Khalsa College',
      'Maitreyi College',
      'Atma Ram Sanatan Dharma College',
      'Sri Venkateswara College',
      'Gargi College',
      'Kamala Nehru College',
      'Lady Irwin College',
      'Daulat Ram College',
      'Acharya Narendra Dev College',
      'Deshbandhu College',
      'Ramanujan College',
      'Shaheed Bhagat Singh College',
      'College of Vocational Studies',
      'P.G.D.A.V. College',
      'Shaheed Sukhdev College of Business Studies',
      'Sri Guru Gobind Singh College of Commerce',
      'Keshav Mahavidyalaya',
      'Jesus and Mary College',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                _editingPgId != null
                    ? LucideIcons.edit3
                    : LucideIcons.plusCircle,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _editingPgId != null
                      ? 'Edit PG Listing #$_editingPgId'
                      : 'Add New PG Listing',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_editingPgId != null)
                TextButton.icon(
                  onPressed: _clearPgForm,
                  icon: const Icon(LucideIcons.x, size: 14),
                  label: const Text('Cancel Edit'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Manage PG listings shown to students in the Campus Hub screen.',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // ── FORM CARD ───────────────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _pgFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic Info ─────────────────────────────────────────
                    _AdminSectionLabel('Basic Information'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _pgNameController,
                      decoration: const InputDecoration(
                        labelText: 'PG Name *',
                        hintText: 'e.g. Saksham Boys PG',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.home, size: 18),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pgAreaController,
                            decoration: const InputDecoration(
                              labelText: 'Area / Locality *',
                              hintText: 'e.g. Kamla Nagar',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _pgSelectedCampusZone,
                            decoration: const InputDecoration(
                              labelText: 'Campus Zone *',
                              border: OutlineInputBorder(),
                            ),
                            items: campusZones
                                .map(
                                  (z) => DropdownMenuItem(
                                    value: z,
                                    child: Text(
                                      z,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _pgSelectedCampusZone = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pgAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Full Address',
                        hintText: 'e.g. A-12, Vijay Nagar, Delhi 110009',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _pgSelectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.users, size: 18),
                      ),
                      items: genders
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _pgSelectedGender = v!),
                    ),

                    const SizedBox(height: 20),

                    // ── Rent & Deposit ─────────────────────────────────────
                    _AdminSectionLabel('Rent & Financial'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pgMinRentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Rent (₹) *',
                              hintText: '8000',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pgMaxRentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Rent (₹) *',
                              hintText: '14000',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                                (v == null || v.isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pgDepositController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Deposit (₹)',
                              hintText: '20000',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Room Types ─────────────────────────────────────────
                    _AdminSectionLabel('Room Types Available'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: roomTypeOptions.map((rt) {
                        final sel = _pgSelectedRoomTypes.contains(rt);
                        return FilterChip(
                          label: Text(rt),
                          selected: sel,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _pgSelectedRoomTypes.add(rt);
                            } else {
                              _pgSelectedRoomTypes.remove(rt);
                            }
                          }),
                          selectedColor: theme.colorScheme.primary.withOpacity(
                            0.15,
                          ),
                          checkmarkColor: theme.colorScheme.primary,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Amenities ──────────────────────────────────────────
                    _AdminSectionLabel('Amenities'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: amenityOptions.map((a) {
                        final sel = _pgSelectedAmenities.contains(a);
                        return FilterChip(
                          label: Text(a, style: const TextStyle(fontSize: 12)),
                          selected: sel,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _pgSelectedAmenities.add(a);
                            } else {
                              _pgSelectedAmenities.remove(a);
                            }
                          }),
                          selectedColor: Colors.green.withOpacity(0.15),
                          checkmarkColor: Colors.green,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Metro & Contact ────────────────────────────────────
                    _AdminSectionLabel('Metro & Contact'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _pgNearestMetroController,
                            decoration: const InputDecoration(
                              labelText: 'Nearest Metro Station',
                              hintText: 'Vishwa Vidyalaya',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.train, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pgMetroMinsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Walk (mins)',
                              hintText: '5',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _pgContactPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone',
                              hintText: '+91-9876543210',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.phone, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pgContactEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(LucideIcons.mail, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pgMapsUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Google Maps URL',
                        hintText: 'https://maps.google.com/...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.mapPin, size: 18),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Description & Images ───────────────────────────────
                    _AdminSectionLabel('Description & Images'),
                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _pgDescriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText:
                            'Describe the PG — location benefits, food quality, security...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _pgImagesController,
                      decoration: const InputDecoration(
                        labelText: 'Image URLs (comma-separated)',
                        hintText: 'https://example.com/img1.jpg, https://...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(LucideIcons.image, size: 18),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Ratings & Flags ────────────────────────────────────
                    _AdminSectionLabel('Rating & Flags'),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rating: ${_pgRating.toStringAsFixed(1)} ⭐',
                                style: GoogleFonts.outfit(fontSize: 13),
                              ),
                              Slider(
                                value: _pgRating,
                                min: 1.0,
                                max: 5.0,
                                divisions: 8,
                                label: _pgRating.toStringAsFixed(1),
                                onChanged: (v) => setState(() => _pgRating = v),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _pgReviewCount.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Review Count',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) =>
                                _pgReviewCount = int.tryParse(v) ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: Text(
                              'Meals Included',
                              style: GoogleFonts.outfit(fontSize: 13),
                            ),
                            value: _pgMealsIncluded,
                            onChanged: (v) =>
                                setState(() => _pgMealsIncluded = v),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: SwitchListTile(
                            title: Text(
                              'Verified ✓',
                              style: GoogleFonts.outfit(fontSize: 13),
                            ),
                            value: _pgIsVerified,
                            activeColor: Colors.blue,
                            onChanged: (v) => setState(() => _pgIsVerified = v),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: SwitchListTile(
                            title: Text(
                              'Active',
                              style: GoogleFonts.outfit(fontSize: 13),
                            ),
                            value: _pgIsActive,
                            activeColor: Colors.green,
                            onChanged: (v) => setState(() => _pgIsActive = v),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Nearby Colleges (association) ──────────────────────
                    _AdminSectionLabel('Nearby Colleges'),
                    const SizedBox(height: 4),
                    Text(
                      'Link colleges to this PG with walking/rickshaw distance.',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // College association rows
                    ..._pgNearbyColleges.asMap().entries.map((entry) {
                      final i = entry.key;
                      final col = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            // College dropdown
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: col['college_name'] as String?,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'College',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: duColleges
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () =>
                                      _pgNearbyColleges[i]['college_name'] = v,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Distance
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                initialValue: (col['distance_mins'] ?? '')
                                    .toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Mins',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (v) =>
                                    _pgNearbyColleges[i]['distance_mins'] =
                                        int.tryParse(v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Type dropdown
                            SizedBox(
                              width: 90,
                              child: DropdownButtonFormField<String>(
                                value:
                                    col['distance_type'] as String? ?? 'walk',
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: ['walk', 'rickshaw', 'auto']
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          t,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setState(
                                  () =>
                                      _pgNearbyColleges[i]['distance_type'] = v,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Remove
                            IconButton(
                              icon: const Icon(
                                LucideIcons.x,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  setState(() => _pgNearbyColleges.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add college button
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _pgNearbyColleges.add({
                          'college_name': duColleges.first,
                          'distance_mins': 10,
                          'distance_type': 'walk',
                        });
                      }),
                      icon: const Icon(LucideIcons.plusCircle, size: 16),
                      label: const Text('Add Nearby College'),
                    ),

                    const SizedBox(height: 24),

                    // ── Submit ─────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingPg ? null : _savePg,
                        icon: _isSavingPg
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _editingPgId != null
                                    ? LucideIcons.save
                                    : LucideIcons.plusCircle,
                              ),
                        label: Text(
                          _isSavingPg
                              ? 'Saving...'
                              : _editingPgId != null
                              ? 'Update PG Listing'
                              : 'Publish PG Listing',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // ── EXISTING PG LISTINGS ────────────────────────────────────────────
          Row(
            children: [
              Text(
                'All PG Listings (${_allPgs.length})',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: _fetchAdminPgs,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),

          _isLoadingPgs
              ? const Center(child: CircularProgressIndicator())
              : _allPgs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No PG listings yet.\nAdd one above to get started.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _allPgs.length,
                  itemBuilder: (ctx, i) {
                    final pg = _allPgs[i];
                    final id = pg['id'] as int;
                    final isActive = pg['is_active'] as bool? ?? true;
                    final isVerified = pg['is_verified'] as bool? ?? false;
                    final gender = pg['gender'] ?? 'Co-Ed';
                    final genderColor = gender == 'Girls'
                        ? Colors.pink
                        : gender == 'Boys'
                        ? Colors.blue
                        : Colors.teal;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            pg['name'] ?? '',
                                            style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (isVerified) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              LucideIcons.badgeCheck,
                                              size: 14,
                                              color: Colors.blue,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${pg['area']} · ${pg['campus_zone']}  ·  ₹${pg['rent_min']} – ₹${pg['rent_max']}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Edit
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.edit3,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _populatePgForm(pg),
                                  tooltip: 'Edit',
                                ),
                                // Delete
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      _deletePg(id, pg['name'] ?? ''),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              children: [
                                _AdminBadge(gender, genderColor),
                                _AdminBadge(
                                  isActive ? 'Live' : 'Draft',
                                  isActive ? Colors.green : Colors.grey,
                                ),
                                if (pg['meals_included'] == true)
                                  _AdminBadge('Meals ✓', Colors.orange),
                                if (pg['nearest_metro'] != null)
                                  _AdminBadge(
                                    '🚇 ${pg['nearest_metro']}',
                                    Colors.blueGrey,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

// ─── Small section label helper ───────────────────────────────────────────
Widget _AdminSectionLabel(String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  final void Function(bool) onChanged;

  const _ToggleChip({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: value ? activeColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 12,
              color: value ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
