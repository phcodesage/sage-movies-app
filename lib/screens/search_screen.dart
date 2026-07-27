import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/services/api_service.dart';
import 'package:sagemovies/widgets/poster_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Movie> _results = [];
  List<Movie> _filteredResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  String _lastQuery = '';
  String? _selectedLetter;

  final List<Map<String, String>> _popularPlatforms = [
    {'name': 'Vivamax', 'asset': 'assets/studios/vivamax.png'},
    {'name': 'Netflix', 'asset': 'assets/studios/netflix.png'},
    {'name': 'Disney+', 'asset': 'assets/studios/disney.png'},
    {'name': 'Prime Video', 'asset': 'assets/studios/prime.png'},
    {'name': 'Apple TV+', 'asset': 'assets/studios/appletv.png'},
    {'name': 'HBO Max', 'asset': 'assets/studios/hbo.png'},
    {'name': 'Paramount+', 'asset': 'assets/studios/paramount.png'},
    {'name': 'Hulu', 'asset': 'assets/studios/hulu.png'},
  ];

  final List<String> _genres = [
    'Action', 'Romance', 'Comedy', 'Horror', 'Sci-Fi', 'Drama', 'Anime', 'Adventure'
  ];

  final List<String> _letters = List.generate(26, (index) => String.fromCharCode(65 + index));

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim() != _lastQuery) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    _lastQuery = query.trim();
    _selectedLetter = null;

    if (_lastQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _filteredResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      final results = await ApiService.search(_lastQuery);
      final validResults = results.where((m) => m.posterUrl.isNotEmpty).toList();

      if (mounted) {
        setState(() {
          _results = validResults;
          _filteredResults = validResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _filterByLetter(String? letter) {
    setState(() {
      _selectedLetter = letter;
      if (letter == null) {
        _filteredResults = _results;
      } else {
        _filteredResults = _results.where((m) => m.title.toUpperCase().startsWith(letter)).toList();
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    _onSearchChanged('');
    _focusNode.requestFocus();
  }

  void _onPlatformTap(String platformName) {
    _controller.text = platformName;
    _focusNode.unfocus();
    _performSearch(platformName);
  }

  void _openDetails(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildPlatformChips(),
            if (_results.isNotEmpty) _buildAZFilter(),
            if (_isSearching)
              const LinearProgressIndicator(color: Color(0xFFE50914), backgroundColor: Colors.transparent),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _buildBody(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        cursorColor: const Color(0xFFE50914),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Color(0xFFE50914)),
          hintText: 'Search movies, TV shows, Vivamax, Netflix...',
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          border: InputBorder.none,
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
        ),
        onChanged: (v) {
          setState(() {});
          _onSearchChanged(v);
        },
      ),
    );
  }

  Widget _buildPlatformChips() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _popularPlatforms.length,
        itemBuilder: (context, i) {
          final platform = _popularPlatforms[i];
          final name = platform['name']!;
          final asset = platform['asset']!;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _onPlatformTap(name),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      asset,
                      width: 18,
                      height: 18,
                      errorBuilder: (context, error, stack) =>
                          const Icon(Icons.movie_filter, size: 16, color: Color(0xFFE50914)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAZFilter() {
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _letters.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildFilterChip('ALL', _selectedLetter == null, () => _filterByLetter(null));
          }
          final letter = _letters[index - 1];
          return _buildFilterChip(letter, _selectedLetter == letter, () => _filterByLetter(letter));
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE50914) : const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFFE50914) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching && _results.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)),
        ),
      );
    }

    if (_controller.text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(Icons.travel_explore, size: 56, color: Colors.white24),
                  SizedBox(height: 12),
                  Text(
                    'Search titles, genres, or studio platforms',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'BROWSE GENRES',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _genres.map((g) {
                return ActionChip(
                  label: Text(g),
                  backgroundColor: const Color(0xFF1E1E24),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Colors.white12),
                  onPressed: () => _onPlatformTap(g),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    if (_filteredResults.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No matching titles or platform catalog found',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ),
      );
    }

    // Group results into Web-parity sections
    final platformMatches = _filteredResults.where((m) => m.relevanceScore == 110).toList();
    final exactMatches = _filteredResults.where((m) => m.relevanceScore == 100).toList();
    final startsWith = _filteredResults.where((m) => m.relevanceScore == 90).toList();
    final otherResults = _filteredResults.where((m) => m.relevanceScore < 90).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (platformMatches.isNotEmpty)
          _buildResultSection('ORIGINATING PLATFORM MATCHES', platformMatches, isHighPriority: true),
        if (exactMatches.isNotEmpty)
          _buildResultSection('EXACT MATCHES', exactMatches, isHighPriority: true),
        if (startsWith.isNotEmpty)
          _buildResultSection('STARTS WITH', startsWith),
        if (otherResults.isNotEmpty)
          _buildResultSection(
            (platformMatches.isEmpty && exactMatches.isEmpty && startsWith.isEmpty)
                ? 'SEARCH RESULTS'
                : 'RELATED RESULTS',
            otherResults,
          ),
      ],
    );
  }

  Widget _buildResultSection(String title, List<Movie> movies, {bool isHighPriority = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: isHighPriority ? const Color(0xFFE50914) : Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isHighPriority ? const Color(0xFFE50914) : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.55,
          ),
          itemCount: movies.length,
          itemBuilder: (context, i) {
            final movie = movies[i];
            return GestureDetector(
              onTap: () => _openDetails(movie),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PosterTile(movie: movie),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
