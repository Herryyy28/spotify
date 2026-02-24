import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/player_provider.dart';

/// Statistics screen showing user listening insights and analytics
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final userProvider = context.read<UserProvider>();
    final analyticsProvider = context.read<AnalyticsProvider>();

    if (userProvider.user != null) {
      await analyticsProvider.loadUserStatistics(userProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Your Stats',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1DB954).withOpacity(0.3),
                      const Color(0xFF121212),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF1DB954),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Top Songs'),
                  Tab(text: 'Insights'),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: Consumer<AnalyticsProvider>(
              builder: (context, analyticsProvider, child) {
                if (analyticsProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1DB954),
                    ),
                  );
                }

                if (analyticsProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.white38,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          analyticsProvider.error!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStatistics,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1DB954),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(analyticsProvider),
                    _buildTopSongsTab(analyticsProvider),
                    _buildInsightsTab(analyticsProvider),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AnalyticsProvider analyticsProvider) {
    final stats = analyticsProvider.userStats;

    if (stats == null) {
      return _buildEmptyState('No statistics available yet');
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: const Color(0xFF1DB954),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Songs Played',
                  stats.totalSongsPlayed.toString(),
                  Icons.music_note,
                  const Color(0xFF1DB954),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Hours Listened',
                  stats.totalListeningHours.toString(),
                  Icons.access_time,
                  const Color(0xFF1ED760),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Top Artists
          _buildSectionHeader('Top Artists'),
          const SizedBox(height: 12),
          ...stats.topArtists.asMap().entries.map((entry) {
            return _buildTopItem(
              entry.key + 1,
              entry.value,
              '',
              Icons.person,
            );
          }),
          const SizedBox(height: 24),

          // Top Genres
          _buildSectionHeader('Top Genres'),
          const SizedBox(height: 12),
          ...stats.topGenres.asMap().entries.map((entry) {
            return _buildTopItem(
              entry.key + 1,
              entry.value,
              '',
              Icons.category,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopSongsTab(AnalyticsProvider analyticsProvider) {
    final topSongs = analyticsProvider.topSongs;

    if (topSongs.isEmpty) {
      return _buildEmptyState('No top songs yet');
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: const Color(0xFF1DB954),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: topSongs.length,
        itemBuilder: (context, index) {
          final song = topSongs[index];
          return ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          index < 3 ? const Color(0xFF1DB954) : Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    image: song.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(song.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: song.imageUrl.isEmpty
                        ? const LinearGradient(
                            colors: [Color(0xFF535353), Color(0xFF282828)],
                          )
                        : null,
                  ),
                ),
              ],
            ),
            title: Text(
              song.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              song.artist,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Icon(
              Icons.play_arrow,
              color: Colors.white.withOpacity(0.7),
            ),
            onTap: () {
              // Play song
              context.read<PlayerProvider>().playSong(song);
            },
          );
        },
      ),
    );
  }

  Widget _buildInsightsTab(AnalyticsProvider analyticsProvider) {
    final patterns = analyticsProvider.listeningPatterns;

    if (patterns == null) {
      return _buildEmptyState('No insights available yet');
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      color: const Color(0xFF1DB954),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Peak Listening Time
          _buildInsightCard(
            'Peak Listening Time',
            patterns.peakHourFormatted,
            'You listen to music most at ${patterns.peakHourFormatted}',
            Icons.schedule,
            const Color(0xFF1DB954),
          ),
          const SizedBox(height: 16),

          // Peak Day
          _buildInsightCard(
            'Most Active Day',
            patterns.peakDayName,
            'You listen to music most on ${patterns.peakDayName}',
            Icons.calendar_today,
            const Color(0xFF1ED760),
          ),
          const SizedBox(height: 24),

          // Hourly Distribution
          _buildSectionHeader('Listening by Hour'),
          const SizedBox(height: 12),
          _buildHourlyChart(patterns.hourlyDistribution),
          const SizedBox(height: 24),

          // Weekly Distribution
          _buildSectionHeader('Listening by Day'),
          const SizedBox(height: 12),
          _buildWeeklyChart(patterns.weekdayDistribution),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTopItem(int rank, String name, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? const Color(0xFF1DB954)
                  : Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(List<int> distribution) {
    final maxValue = distribution.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(24, (index) {
          final value = distribution[index];
          final height = maxValue > 0 ? (value / maxValue) * 120 : 0.0;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF1DB954),
                        const Color(0xFF1DB954).withOpacity(0.5),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (index % 6 == 0)
                  Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWeeklyChart(List<int> distribution) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxValue = distribution.reduce((a, b) => a > b ? a : b);

    return Column(
      children: List.generate(7, (index) {
        final value = distribution[index];
        final width = maxValue > 0 ? (value / maxValue) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  days[index],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: width,
                      child: Container(
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1DB954),
                              Color(0xFF1ED760),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start listening to see your stats',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: const Color(0xFF121212),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
