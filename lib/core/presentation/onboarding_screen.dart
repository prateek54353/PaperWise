import 'package:flutter/material.dart';
import 'package:paperwise_pdf_maker/core/theme/app_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _currentVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _currentVersion = packageInfo.version;
      });
    }
  }

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'What\'s New',
      description: 'Discover the latest features and improvements in PaperWise.',
      icon: Icons.update,
      color: paperWiseBrandSeed,
      isUpdatePage: true,
    ),
    OnboardingPage(
      title: 'Welcome to PaperWise',
      description: 'Your personal document scanner. Scan, organize, and share PDFs with ease.',
      icon: Icons.document_scanner,
      color: paperWiseBrandSeed,
    ),
    OnboardingPage(
      title: 'Scan Documents',
      description: 'Use your camera to scan papers, receipts, or any document. Apply filters to enhance quality.',
      icon: Icons.camera_alt,
      color: paperWiseBrandSeed,
    ),
    OnboardingPage(
      title: 'Organize PDFs',
      description: 'Create real folders, move PDFs, rename, merge, split, and share. Batch operations stay available.',
      icon: Icons.folder_open,
      color: paperWiseBrandSeed,
    ),
    OnboardingPage(
      title: 'Join Our Community',
      description: 'Connect with other users, get support, and stay updated on new features.',
      icon: Icons.people,
      color: paperWiseBrandSeed,
      isCommunityPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    await prefs.setBool('onboarding_completed', true);
    await prefs.setString('last_seen_version', packageInfo.version);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    if (page.isUpdatePage) {
      return _buildUpdatePage();
    }
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (page.isCommunityPage) ...[
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CommunityButton(
                  icon: Icons.discord,
                  label: 'Discord',
                  color: const Color(0xFF5865F2),
                  onTap: () => _launchUrl('https://discord.gg/HsqzDNSDqg'),
                ),
                _CommunityButton(
                  icon: Icons.telegram,
                  label: 'Telegram',
                  color: const Color(0xFF0088cc),
                  onTap: () => _launchUrl('https://t.me/paperwiseofficial'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUpdatePage() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.update,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'PaperWise v$_currentVersion',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'What\'s New',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _UpdateFeature(
                  icon: Icons.search,
                  title: 'Search PDFs',
                  description: 'Quickly find your documents',
                ),
                const SizedBox(height: 6),
                const _UpdateFeature(
                  icon: Icons.sort,
                  title: 'Sort by Date/Name',
                  description: 'Organize your library',
                ),
                const SizedBox(height: 6),
                const _UpdateFeature(
                  icon: Icons.image,
                  title: 'PDF Thumbnails',
                  description: 'Visual previews in library',
                ),
                const SizedBox(height: 6),
                const _UpdateFeature(
                  icon: Icons.school,
                  title: 'Onboarding',
                  description: 'Better first-time experience',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildPageIndicator(index == _currentPage),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currentPage == _pages.length - 1
                  ? _completeOnboarding
                  : () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
              child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
            ),
          ),
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text('Back'),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isCommunityPage;
  final bool isUpdatePage;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isCommunityPage = false,
    this.isUpdatePage = false,
  });
}

/// Check if onboarding should be shown
Future<bool> shouldShowOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();
  final lastSeenVersion = prefs.getString('last_seen_version');
  
  // Show onboarding if never completed OR if version has changed
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  return !onboardingCompleted || lastSeenVersion != packageInfo.version;
}

class _UpdateFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _UpdateFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommunityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CommunityButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
