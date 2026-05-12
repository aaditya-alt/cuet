import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/college_model.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';

class WishlistTab extends StatefulWidget {
  const WishlistTab({super.key});

  @override
  State<WishlistTab> createState() => _WishlistTabState();
}

class _WishlistTabState extends State<WishlistTab> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Preference List'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.download),
            label: const Text('Export PDF'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Drag and drop to reorder your college preferences for CSAS counselling.',
                      style: GoogleFonts.outfit(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Consumer<WishlistProvider>(
              builder: (context, wishlistProvider, child) {
                final wishlist = wishlistProvider.wishlist;
                if (wishlist.isEmpty) {
                  return Center(
                    child: Text(
                      'Your wishlist is empty',
                      style: GoogleFonts.outfit(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }
                return ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: wishlist.length,
                  onReorder: wishlistProvider.reorderWishlist,
                  itemBuilder: (context, index) {
                    final college = wishlist[index];
                return Card(
                  key: ValueKey(college.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      college.name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${college.campus} • ${college.courses.first.courseName}',
                      style: GoogleFonts.outfit(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(LucideIcons.trash2, color: Colors.red),
                      onPressed: () {
                        wishlistProvider.toggleWishlist(college);
                      },
                    ),
                  ),
                );
              },
            );
           },
          ),
         ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(LucideIcons.save),
        label: Text('Save Preferences', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
