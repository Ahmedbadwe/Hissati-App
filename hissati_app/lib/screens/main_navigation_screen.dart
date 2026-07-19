import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/app_user.dart';
import '../models/tutor_offer.dart';
import '../models/parent_request.dart';
import '../controllers/feed_controller.dart';
import '../controllers/filter_controller.dart';
import '../services/auth_service.dart';
import '../widgets/filter_header.dart';
import 'create_post_screen.dart';

/// Main app shell with 3 tabs: Home feed, Create post, and Profile.
class MainNavigationScreen extends StatefulWidget {
  final AppUser currentUser;

  const MainNavigationScreen({super.key, required this.currentUser});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeFeedTab(currentUser: widget.currentUser),
          CreatePostScreen(currentUser: widget.currentUser),
          _ProfileTab(currentUser: widget.currentUser),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'إعلان جديد',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 – Home Feed
// ─────────────────────────────────────────────────────────────────────────────

class _HomeFeedTab extends StatefulWidget {
  final AppUser currentUser;
  const _HomeFeedTab({required this.currentUser});

  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<_HomeFeedTab> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FilterController>(
          create: (_) => FilterController(),
        ),
        ChangeNotifierProxyProvider<FilterController, FeedController>(
          create: (ctx) => FeedController(
            filterController: ctx.read<FilterController>(),
            isTutorViewer: widget.currentUser.role == UserRole.tutor,
          ),
          update: (_, filterCtrl, previous) =>
              previous ??
              FeedController(
                filterController: filterCtrl,
                isTutorViewer: widget.currentUser.role == UserRole.tutor,
              ),
        ),
      ],
      child: _HomeFeedContent(currentUser: widget.currentUser),
    );
  }
}

class _HomeFeedContent extends StatefulWidget {
  final AppUser currentUser;
  const _HomeFeedContent({required this.currentUser});

  @override
  State<_HomeFeedContent> createState() => _HomeFeedContentState();
}

class _HomeFeedContentState extends State<_HomeFeedContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FeedController>().initAndLoad();
    });
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.watch<FeedController>();
    final isTutor = widget.currentUser.role == UserRole.tutor;

    return SafeArea(
      child: Column(
        children: [
          const FilterHeader(),
          Expanded(child: _buildBody(feed, isTutor)),
        ],
      ),
    );
  }

  Widget _buildBody(FeedController feed, bool isTutor) {
    switch (feed.status) {
      case FeedStatus.idle:
      case FeedStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case FeedStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feed.errorMessage ?? 'حدث خطأ',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => feed.initAndLoad(),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );

      case FeedStatus.loaded:
        if (isTutor) {
          return _buildParentRequestsList(feed.parentRequests);
        } else {
          return _buildTutorOffersList(feed.tutorOffers);
        }
    }
  }

  // ── Parent sees tutor_offers ─────────────────────────────────────────

  Widget _buildTutorOffersList(List<TutorOffer> offers) {
    if (offers.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتائج في هذه المنطقة',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return _PostCard(
          title: offer.tutorName,
          chips: [
            if (offer.subject != null) offer.subject!,
            if (offer.eduLevel != null) offer.eduLevel!,
          ],
          priceLabel:
              'خصوصي: ${offer.pricePrivate ?? '-'} جنيه',
          distance: offer.distanceKm,
          phone: offer.tutorPhone,
        );
      },
    );
  }

  // ── Tutor sees parent_requests ───────────────────────────────────────

  Widget _buildParentRequestsList(List<ParentRequest> requests) {
    if (requests.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد نتائج في هذه المنطقة',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return _PostCard(
          title: req.parentName,
          chips: [
            if (req.subject != null) req.subject!,
            if (req.eduLevel != null) req.eduLevel!,
          ],
          priceLabel:
              'الميزانية: ${req.maxBudget ?? '-'} جنيه',
          distance: req.distanceKm,
          phone: req.parentPhone,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Post Card
// ─────────────────────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final String title;
  final List<String> chips;
  final String priceLabel;
  final double? distance;
  final String phone;

  const _PostCard({
    required this.title,
    required this.chips,
    required this.priceLabel,
    this.distance,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name & distance
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (distance != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${distance!.toStringAsFixed(1)} كم',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Chips (subject + level)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: chips
                  .map(
                    (c) => Chip(
                      label: Text(c, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              priceLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launchPhone(phone),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('اتصال'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => _launchWhatsApp(phone),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 18),
                        SizedBox(width: 6),
                        Text('واتساب'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    // Strip leading '+' for wa.me format.
    final cleaned = phone.replaceAll('+', '');
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 – Profile
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileTab extends StatelessWidget {
  final AppUser currentUser;
  const _ProfileTab({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final roleLabel =
        currentUser.role == UserRole.tutor ? 'مدرس' : 'ولي أمر';

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 52,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                currentUser.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                currentUser.phoneNumber,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => AuthService.instance.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                    side: BorderSide(color: Colors.red.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
    );
  }
}
