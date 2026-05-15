import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../data/mock_data.dart';
import '../college/college_details_screen.dart';
import '../../providers/user_score_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cutoff_provider.dart';
import '../../providers/compare_provider.dart';
import '../../models/college_model.dart';
import '../compare/compare_screen.dart';

class PredictionResultsScreen extends StatefulWidget {
  const PredictionResultsScreen({super.key});

  @override
  State<PredictionResultsScreen> createState() =>
      _PredictionResultsScreenState();
}

class _PredictionResultsScreenState
    extends State<PredictionResultsScreen> with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _chanceFilter = 'All'; // All | High | Medium | Low
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0: _chanceFilter = 'All'; break;
          case 1: _chanceFilter = 'High'; break;
          case 2: _chanceFilter = 'Medium'; break;
          case 3: _chanceFilter = 'Low'; break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scoreProvider   = Provider.of<UserScoreProvider>(context);
    final cutoffProvider  = Provider.of<CutoffProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final compareProvider  = Provider.of<CompareProvider>(context);
    final theme = Theme.of(context);

    final userScore     = scoreProvider.score.getTotalScore(false);
    final category      = scoreProvider.score.category;
    final domainSubject = scoreProvider.score.domainSubject;

    // Build predictions from real data
    List<PredictionResult> predictions = [];
    if (!cutoffProvider.isLoading) {
      predictions = cutoffProvider.getPredictionsForStudent(
        userScore: userScore,
        category: category,
        domainSubject: domainSubject,
      );
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      predictions = predictions
          .where((p) =>
              p.collegeName.toLowerCase().contains(q) ||
              p.programName.toLowerCase().contains(q))
          .toList();
    }

    // Apply chance filter
    if (_chanceFilter != 'All') {
      predictions =
          predictions.where((p) => p.chance == _chanceFilter).toList();
    }

    // Helper: find CollegeModel for a college name (for logo/details nav)
    CollegeModel? findCollegeModel(String name) {
      try {
        return MockData.colleges
            .firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
      } catch (_) {
        return null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'College Predictions',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelStyle:
              GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: '✅ High'),
            Tab(text: '⚡ Medium'),
            Tab(text: '❌ Low'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Info banner ───────────────────────────────────────────────
          Container(
            color: theme.colorScheme.primary.withOpacity(0.06),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(LucideIcons.info,
                    size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Score: ${userScore.toStringAsFixed(0)} • Subject: $domainSubject • Category: $category',
                    style: GoogleFonts.outfit(
                        fontSize: 12, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ── Search bar ────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                hintText: 'Search college or program…',
                hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: GoogleFonts.outfit(fontSize: 14),
            ),
          ),

          // ── Results list ──────────────────────────────────────────────
          Expanded(
            child: cutoffProvider.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                            color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text('Loading cutoff data…',
                            style: GoogleFonts.outfit(color: Colors.grey)),
                      ],
                    ),
                  )
                : predictions.isEmpty
                    ? _buildEmpty(context)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: predictions.length,
                        itemBuilder: (context, index) {
                          final p = predictions[index];
                          final college = findCollegeModel(p.collegeName);
                          final isInCompare = college != null
                              ? compareProvider.isInCompare(college.id)
                              : false;
                          return _buildCard(
                            context,
                            p,
                            college,
                            isInCompare,
                            wishlistProvider,
                            compareProvider,
                            theme,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: compareProvider.count == 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompareScreen(
                    college1: compareProvider.compareList[0],
                    college2: compareProvider.compareList[1],
                  ),
                ),
              ),
              backgroundColor: Colors.orange,
              icon: const Icon(LucideIcons.arrowLeftRight,
                  color: Colors.white),
              label: Text('Compare Now',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            )
          : null,
    );
  }

  // ── Card ────────────────────────────────────────────────────────────────
  Widget _buildCard(
    BuildContext context,
    PredictionResult p,
    CollegeModel? college,
    bool isInCompare,
    WishlistProvider wishlistProvider,
    CompareProvider compareProvider,
    ThemeData theme,
  ) {
    final chanceColor = p.chance == 'High'
        ? Colors.green
        : p.chance == 'Medium'
            ? Colors.orange
            : Colors.red;

    final chanceIcon = p.chance == 'High'
        ? LucideIcons.checkCircle2
        : p.chance == 'Medium'
            ? LucideIcons.alertCircle
            : LucideIcons.xCircle;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: college != null
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CollegeDetailsScreen(college: college)),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Logo + name + actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: college != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              college.logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                  LucideIcons.building2,
                                  color: Colors.grey,
                                  size: 22),
                            ),
                          )
                        : const Icon(LucideIcons.building2,
                            color: Colors.grey, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.collegeName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.programName,
                          style: GoogleFonts.outfit(
                              fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Wishlist + compare icons
                  if (college != null)
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.heart,
                            size: 20,
                            color: wishlistProvider.isInWishlist(college.id)
                                ? Colors.red
                                : Colors.grey.shade400,
                          ),
                          onPressed: () {
                            final was = wishlistProvider
                                .isInWishlist(college.id);
                            wishlistProvider.toggleWishlist(college);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(was
                                    ? '${college.name} removed'
                                    : '${college.name} added to wishlist'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(height: 4),
                        IconButton(
                          icon: Icon(
                            isInCompare
                                ? LucideIcons.checkCircle2
                                : LucideIcons.plusCircle,
                            size: 18,
                            color: isInCompare
                                ? Colors.orange
                                : Colors.grey.shade400,
                          ),
                          onPressed: () {
                            if (!isInCompare &&
                                compareProvider.count >= 2) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'You can only compare 2 colleges at a time.')),
                              );
                              return;
                            }
                            compareProvider.toggleCompare(college);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Row 2: Cutoff vs your score + chance badge
              Row(
                children: [
                  // Round 1 cutoff
                  _buildMetric(
                    'Round 1 Cutoff 2025',
                    p.cutoffScore.toStringAsFixed(0),
                    LucideIcons.shieldCheck,
                    Colors.green,
                    theme,
                  ),
                  const SizedBox(width: 12),
                  // Your score
                  _buildMetric(
                    'Your Score',
                    p.userScore.toStringAsFixed(0),
                    LucideIcons.user,
                    theme.colorScheme.primary,
                    theme,
                  ),
                  const Spacer(),
                  // Chance badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: chanceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: chanceColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(chanceIcon,
                            size: 14, color: chanceColor),
                        const SizedBox(width: 4),
                        Text(
                          '${p.chance} Chance',
                          style: GoogleFonts.outfit(
                            color: chanceColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color,
      ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('No matching colleges found',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Try changing your domain subject\nor adjusting your score',
            style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.arrowLeft),
            label: const Text('Go Back & Adjust'),
          ),
        ],
      ),
    );
  }
}
