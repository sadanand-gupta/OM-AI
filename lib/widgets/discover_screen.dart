import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:om_ai/constants/app_colors.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  double _scrollOffset = 0.0;
  String _selectedCategory = 'For You';
  int _currentPage = 0;
  bool _isFavorited = false;
  bool _isLoading = true;

  // Data for different categories
  final Map<String, List<Map<String, String>>> _categoryContent = {
    'For You': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800',
        'title': 'Apple challenges India\'s global revenue penalty rule',
        'description':
            'Apple has filed a legal challenge in the Delhi High Court against India\'s competition law provisions that allow penalties to be calculated on a company\'s global revenue.',
        'author': 'urbanxplorer',
        'gradient': '0xFF9C9155',
        'border': '0xFFE8D84B',
      },
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
        'title': 'India to seek five more S-400 squadrons from Russia',
        'description':
            'India is expected to push for five additional squadrons of Russia\'s S-400 air defense system during the upcoming summit between Prime Minister Narendra Modi and President Vladimir Putin.',
        'author': 'aaronmut',
        'gradient': '0xFF6B9BB5',
        'border': '0xFF7DD3E8',
      },
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
        'title': 'The Future of AI in Software Development',
        'description':
            'Explore how artificial intelligence is reshaping the landscape of software engineering, from automated code generation to intelligent testing frameworks.',
        'author': 'techtrends',
        'gradient': '0xFF1A237E',
        'border': '0xFF536DFE',
      },
    ],
    'Top Stories': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=800',
        'title': 'Global Markets Rally on Economic Data',
        'description':
            'Stock markets around the world surged today following better-than-expected economic indicators from major economies.',
        'author': 'marketwatch',
        'gradient': '0xFF2D5A4F',
        'border': '0xFF4CAF50',
      },
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=800',
        'title': 'New Climate Agreement Reached at Summit',
        'description':
            'World leaders have agreed on a landmark climate deal that aims to reduce global carbon emissions by 50% within the next decade.',
        'author': 'greenworld',
        'gradient': '0xFF5D4E37',
        'border': '0xFFFFD700',
      },
    ],
    'Tech & Science': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800',
        'title': 'The Future of AI in Software Development',
        'description':
            'Explore how artificial intelligence is reshaping the landscape of software engineering, from automated code generation to intelligent testing frameworks.',
        'author': 'techtrends',
        'gradient': '0xFF1A237E',
        'border': '0xFF536DFE',
      },
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800',
        'title': 'Quantum Computing Breakthrough Announced',
        'description':
            'Scientists have achieved a major milestone in quantum computing, demonstrating stable qubits at room temperature for the first time.',
        'author': 'sciencedaily',
        'gradient': '0xFF4A148C',
        'border': '0xFFE040FB',
      },
    ],
    'Tech': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=800',
        'title': 'New Smartphone Features Transform Photography',
        'description':
            'Latest flagship devices introduce revolutionary camera technology that rivals professional equipment.',
        'author': 'gadgetreview',
        'gradient': '0xFF263238',
        'border': '0xFF00BCD4',
      },
    ],
    'Finance': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800',
        'title': 'Cryptocurrency Market Sees Major Shift',
        'description':
            'Bitcoin and Ethereum reach new milestones as institutional investors show renewed interest in digital assets.',
        'author': 'cryptonews',
        'gradient': '0xFF1B5E20',
        'border': '0xFF4CAF50',
      },
    ],
    'Gaming': [
      {
        'imageUrl':
            'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800',
        'title': 'Next-Gen Gaming Console Wars Heat Up',
        'description':
            'Major gaming companies announce their latest hardware with unprecedented processing power and immersive features.',
        'author': 'gamersunite',
        'gradient': '0xFF880E4F',
        'border': '0xFFFF1744',
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    // show skeleton for 400 milliseconds
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _currentPage = 0;
    });
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _categoryContent[_selectedCategory] ?? [];

    // show skeleton while loading
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: _buildSkeletonDiscover()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                _buildHeader(context),

                const SizedBox(height: 80), // Space for fixed category tabs
                // Content Feed with PageView for snap scrolling
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: items.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildPageCard(
                        imageUrl: item['imageUrl']!,
                        title: item['title']!,
                        description: item['description']!,
                        author: item['author']!,
                        gradientColor: int.parse(item['gradient']!),
                        borderColor: int.parse(item['border']!),
                        index: index,
                      );
                    },
                  ),
                ),
              ],
            ),

            // Fixed Category Tabs with fade effect
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background,
                      AppColors.background.withOpacity(0.95),
                      AppColors.background.withOpacity(0.8),
                      AppColors.background.withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.5, 0.8, 1.0],
                  ),
                ),
                child: _buildCategoryTabs(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New: lightweight skeleton layout (replace with skeletonizer widgets later if desired)
  Widget _buildSkeletonDiscover() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header skeleton
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 140,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 100,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // category tabs skeleton
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (_, __) => Container(
              width: 110,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: 5,
          ),
        ),

        const SizedBox(height: 16),

        // content skeleton (simulating vertical pages)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Container(
                  height: 380,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.iconDark,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Title
          Text(
            'Discover',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),

          const Spacer(),

          // Favorite Icon (made clickable)
          GestureDetector(
            onTap: () {
              setState(() => _isFavorited = !_isFavorited);
              final message = _isFavorited
                  ? 'Added to favorites'
                  : 'Removed from favorites';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _isFavorited ? Icons.favorite : Icons.favorite_outline,
                      key: ValueKey<bool>(_isFavorited),
                      color: _isFavorited
                          ? AppColors.tealAccent
                          : AppColors.iconDark,
                      size: 24,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.tealAccent,
                        shape: BoxShape.circle,
                        // hide the small dot when favorited (optional)
                        // You can conditionally hide it if you prefer:
                        // color: _isFavorited ? Colors.transparent : AppColors.tealAccent
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildCategoryChip('For You'),
          const SizedBox(width: 8),
          _buildCategoryChip('Top Stories'),
          const SizedBox(width: 8),
          _buildCategoryChip('Tech & Science'),
          const SizedBox(width: 8),
          _buildCategoryChip('Tech'),
          const SizedBox(width: 8),
          _buildCategoryChip('Finance'),
          const SizedBox(width: 8),
          _buildCategoryChip('Gaming'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _onCategoryChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.tealAccent.withOpacity(0.15)
              : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: AppColors.tealAccent, width: 1.5)
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.tealAccent : AppColors.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildPageCard({
    required String imageUrl,
    required String title,
    required String description,
    required String author,
    required int gradientColor,
    required int borderColor,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        double opacity = 1.0;

        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          opacity = (1 - (value.abs() * 0.5)).clamp(0.5, 1.0);
        }

        return Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Story Image
                    Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Border Effect
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Color(borderColor), width: 6),
                      ),
                    ),

                    // Content Overlay
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(gradientColor).withOpacity(0.85),
                              Color(gradientColor).withOpacity(0.95),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              description,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.5,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                // Profile Icon
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.person_outline,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Author Name
                                Text(
                                  author,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                // Bookmark Button
                                GestureDetector(
                                  onTap: () {
                                    // Handle bookmark action
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Saved: $title'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.bookmark_outline,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Save',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
