import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/colors.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/user_provider.dart';
import '../main_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<String> _selectedGenres = {};
  final Set<String> _selectedArtists = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const List<_Genre> _genres = [
    _Genre('Pop', Icons.music_note_rounded, Color(0xFFFF6B9D)),
    _Genre('Hip Hop', Icons.album_rounded, Color(0xFF8B5CF6)),
    _Genre('Rock', Icons.music_note_rounded, Color(0xFFEF4444)),
    _Genre('Electronic', Icons.graphic_eq_rounded, Color(0xFF06B6D4)),
    _Genre('R&B', Icons.piano_rounded, Color(0xFFF59E0B)),
    _Genre('Jazz', Icons.music_note_rounded, Color(0xFF10B981)),
    _Genre('Classical', Icons.library_music_rounded, Color(0xFF3B82F6)),
    _Genre('Latin', Icons.queue_music_rounded, Color(0xFFFF7043)),
    _Genre('Country', Icons.headphones_rounded, Color(0xFF84CC16)),
    _Genre('Indie', Icons.radio_rounded, Color(0xFFEC4899)),
    _Genre('K-Pop', Icons.star_rounded, Color(0xFFF97316)),
    _Genre('Metal', Icons.flash_on_rounded, Color(0xFF6B7280)),
  ];

  static const List<_Artist> _artists = [
    _Artist('The Weeknd', '83M listeners'),
    _Artist('Taylor Swift', '91M listeners'),
    _Artist('Drake', '79M listeners'),
    _Artist('Billie Eilish', '64M listeners'),
    _Artist('Bad Bunny', '70M listeners'),
    _Artist('Ariana Grande', '68M listeners'),
    _Artist('Ed Sheeran', '75M listeners'),
    _Artist('Post Malone', '55M listeners'),
    _Artist('Olivia Rodrigo', '48M listeners'),
    _Artist('Dua Lipa', '58M listeners'),
    _Artist('Harry Styles', '52M listeners'),
    _Artist('BTS', '60M listeners'),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _fadeController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _fadeController.forward();
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    await prefs.setStringList('preferred_genres', _selectedGenres.toList());
    await prefs.setStringList('preferred_artists', _selectedArtists.toList());

    if (!mounted) return;

    // Seed recommendations
    if (context.mounted) {
      try {
        final recProvider = Provider.of<RecommendationProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user?.uid ?? 'unknown';
        recProvider.loadRecommendations(userId);
      } catch (_) {}
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.2,
                colors: [Color(0xFF1a1a2e), Colors.black],
              ),
            ),
          ),

          // Page content
          FadeTransition(
            opacity: _fadeAnimation,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _WelcomePage(onNext: _nextPage),
                _GenrePage(
                  genres: _genres,
                  selected: _selectedGenres,
                  onToggle: (g) => setState(() {
                    if (_selectedGenres.contains(g)) {
                      _selectedGenres.remove(g);
                    } else {
                      _selectedGenres.add(g);
                    }
                  }),
                  onNext: _nextPage,
                ),
                _ArtistPage(
                  artists: _artists,
                  selected: _selectedArtists,
                  onToggle: (a) => setState(() {
                    if (_selectedArtists.contains(a)) {
                      _selectedArtists.remove(a);
                    } else {
                      _selectedArtists.add(a);
                    }
                  }),
                  onComplete: _complete,
                ),
              ],
            ),
          ),

          // Bottom page indicators
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppColors.primary : Colors.grey[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.neonPurple],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 40),
            const Text(
              'Welcome to\nHarmony Music',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Let\'s personalize your music experience.\nTell us what you love.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _GenrePage extends StatelessWidget {
  final List<_Genre> genres;
  final Set<String> selected;
  final void Function(String) onToggle;
  final VoidCallback onNext;

  const _GenrePage({
    required this.genres,
    required this.selected,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick your genres',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select at least 3 genres to get great recommendations',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: genres.length,
                itemBuilder: (_, i) {
                  final genre = genres[i];
                  final isSelected = selected.contains(genre.name);
                  return GestureDetector(
                    onTap: () => onToggle(genre.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? genre.color.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? genre.color : Colors.white.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: genre.color.withValues(alpha: 0.4), blurRadius: 16)]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(genre.icon, color: Colors.white, size: 28),
                          const SizedBox(height: 6),
                          Text(
                            genre.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: selected.length >= 1 ? onNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[800],
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                selected.isEmpty
                    ? 'Select genres to continue'
                    : 'Continue (${selected.length} selected)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtistPage extends StatelessWidget {
  final List<_Artist> artists;
  final Set<String> selected;
  final void Function(String) onToggle;
  final VoidCallback onComplete;

  const _ArtistPage({
    required this.artists,
    required this.selected,
    required this.onToggle,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Follow artists',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Follow artists you love to see their latest releases',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: artists.length,
                itemBuilder: (_, i) {
                  final artist = artists[i];
                  final isSelected = selected.contains(artist.name);
                  return GestureDetector(
                    onTap: () => onToggle(artist.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                              )]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.07),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.neonPurple.withValues(alpha: 0.6),
                                          AppColors.primary.withValues(alpha: 0.6),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        artist.name[0],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      artist.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            FilledButton(
              onPressed: onComplete,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                selected.isEmpty ? 'Skip' : 'Let\'s Go! (${selected.length} selected)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Genre {
  final String name;
  final IconData icon;
  final Color color;
  const _Genre(this.name, this.icon, this.color);
}

class _Artist {
  final String name;
  final String listeners;
  const _Artist(this.name, this.listeners);
}
