import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sagemovies/models/movie.dart';
import 'package:sagemovies/screens/details_screen.dart';
import 'package:sagemovies/services/api_service.dart';
import 'package:sagemovies/widgets/poster_tile.dart';
import 'package:sagemovies/widgets/section_row.dart'; // Reuse for related movies

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
  List<Movie> _relatedMovies = [];
  bool _isSearching = false;
  Timer? _debounce;
  String _lastQuery = '';
  String? _selectedLetter;

  final List<String> _suggestions = [
    'Action', 'Romance', 'Comedy', 'Horror', 'Sci-Fi', 'Drama', 'Anime', 'Adventure'
  ];

  final Map<String, int> _genreIds = {
    'Action': 28,
    'Adventure': 12,
    'Animation': 16,
    'Comedy': 35,
    'Crime': 80,
    'Documentary': 99,
    'Drama': 18,
    'Family': 10751,
    'Fantasy': 14,
    'History': 36,
    'Horror': 27,
    'Music': 10402,
    'Mystery': 9648,
    'Romance': 10749,
    'Sci-Fi': 878,
    'TV Movie': 10770,
    'Thriller': 53,
    'War': 10752,
    'Western': 37,
  };

  final List<String> _letters = List.generate(26, (index) => String.fromCharCode(65 + index));

  @override
  void initState() {
    super.initState();
    _loadRelatedMovies();
  }

  Future<void> _loadRelatedMovies() async {
    try {
      final movies = await ApiService.fetchTrending();
      if (mounted) setState(() => _relatedMovies = movies);
    } catch (_) {}
  }

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
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim() != _lastQuery) {
        _performSearch(query);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    _lastQuery = query.trim();
    _selectedLetter = null; // Reset filter on new search
    
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

  Future<void> _performGenreSearch(String genre) async {
    _controller.text = genre; // Show selected genre in search bar
    _lastQuery = genre;
    _selectedLetter = null;
    
    if (mounted) {
      setState(() {
        _isSearching = true;
        _results = []; // Clear previous results immediately
        _filteredResults = [];
      });
    }

    try {
      List<Movie> results;
      if (genre == 'Anime') {
        results = await ApiService.fetchAnimeCollection();
      } else if (_genreIds.containsKey(genre)) {
        results = await ApiService.fetchMoviesByGenre(_genreIds[genre]!);
      } else {
        // Fallback to text search if not mapped
        results = await ApiService.search(genre);
      }
      
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

  void _onSuggestionTap(String suggestion) {
    _focusNode.unfocus();
    _performGenreSearch(suggestion);
  }

  void _openDetails(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DetailsScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Custom dark theme background
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildSuggestions(),
            if (_results.isNotEmpty) _buildAZFilter(),
            if (_isSearching)
              const LinearProgressIndicator(color: Colors.red, backgroundColor: Colors.transparent),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBody(),
                    const SizedBox(height: 24),
                    if (_relatedMovies.isNotEmpty) 
                      SectionRow(
                        title: 'Related Movies', 
                        movies: _relatedMovies, 
                        onTap: _openDetails
                      ),
                    const SizedBox(height: 32),
                  ],
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2B2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: Colors.red,
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.white54),
          hintText: 'Search movies, shows, genres...',
          hintStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white54),
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

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _suggestions.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(s),
              backgroundColor: const Color(0xFF333333),
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide.none,
              onPressed: () => _onSuggestionTap(s),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildAZFilter() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _letters.length + 1, // +1 for "All" reset
        itemBuilder: (context, index) {
          if (index == 0) {
             return _buildFilterChip('All', _selectedLetter == null, () => _filterByLetter(null));
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : const Color(0xFF333333),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching && _results.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    if (_controller.text.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.manage_search, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                'Explore movies & TV shows',
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredResults.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No results found',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return _buildResultsGrid();
  }

  Widget _buildResultsGrid() {
    // GridView inside SingleChildScrollView needs shrinkWrap and disable scroll
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.55, // Adjusted for title text
      ),
      itemCount: _filteredResults.length,
      itemBuilder: (context, i) {
        final movie = _filteredResults[i];
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
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
