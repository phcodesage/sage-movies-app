/// Canonical registry of the studios we can brand, backed by the PNGs bundled
/// in assets/studios/.
///
/// [companyId] feeds `/api/movies/studio/{id}`, which is a TMDB *company*
/// discover endpoint. Passing a *network* id to it returns confident garbage
/// (49 is HBO the network, but company 49 is an unrelated Spanish label), so
/// [networkId] is used for MATCHING ONLY and must never reach that endpoint.
///
/// A wrong [companyId] is worse than none: null degrades to a title search,
/// while a wrong id returns a plausible-looking but unrelated catalogue.
class StudioEntry {
  final String key;
  final String displayName;
  final String asset;

  /// TMDB production-company id. Null when unverified — see note above.
  final int? companyId;

  /// TMDB network id, for matching `networks[]` on TV titles. Never a discover argument.
  final int? networkId;

  /// Lowercase substrings matched against production-company / network names.
  final List<String> aliases;

  const StudioEntry({
    required this.key,
    required this.displayName,
    required this.asset,
    required this.aliases,
    this.companyId,
    this.networkId,
  });
}

class StudioCatalog {
  StudioCatalog._();

  static const List<StudioEntry> entries = [
    StudioEntry(
      key: 'marvel',
      displayName: 'Marvel',
      asset: 'assets/studios/marvel.png',
      companyId: 420,
      aliases: ['marvel studios', 'marvel entertainment', 'marvel'],
    ),
    StudioEntry(
      key: 'disney',
      displayName: 'Disney',
      asset: 'assets/studios/disney.png',
      companyId: 2,
      aliases: [
        'walt disney animation studios',
        'walt disney pictures',
        'walt disney',
        'disneytoon studios',
        'pixar',
        'disney+',
        'disney',
      ],
    ),
    StudioEntry(
      key: 'warner',
      displayName: 'Warner Bros',
      asset: 'assets/studios/warner.png',
      companyId: 174,
      aliases: [
        'warner brothers',
        'warner bros',
        'new line cinema',
        'castle rock entertainment',
        'castle rock',
        'warner',
      ],
    ),
    StudioEntry(
      key: 'universal',
      displayName: 'Universal',
      asset: 'assets/studios/universal.png',
      companyId: 33,
      aliases: ['universal pictures', 'universal animation', 'universal'],
    ),
    StudioEntry(
      key: 'sony',
      displayName: 'Sony',
      asset: 'assets/studios/sony.png',
      companyId: 34,
      aliases: [
        'sony pictures animation',
        'sony pictures',
        'columbia pictures',
        'screen gems',
        'tristar',
        'sony',
      ],
    ),
    StudioEntry(
      key: 'paramount',
      displayName: 'Paramount',
      asset: 'assets/studios/paramount.png',
      companyId: 4,
      aliases: ['paramount pictures', 'paramount animation', 'paramount+', 'paramount'],
    ),
    StudioEntry(
      key: 'a24',
      displayName: 'A24',
      asset: 'assets/studios/a24.png',
      companyId: 41077,
      aliases: ['a24'],
    ),
    StudioEntry(
      key: 'hbo',
      displayName: 'HBO',
      asset: 'assets/studios/hbo.png',
      companyId: 3268,
      networkId: 49,
      aliases: ['home box office', 'hbo films', 'hbo'],
    ),
    StudioEntry(
      key: 'netflix',
      displayName: 'Netflix',
      asset: 'assets/studios/netflix.png',
      companyId: 178464,
      networkId: 213,
      aliases: ['netflix animation', 'netflix'],
    ),
    StudioEntry(
      key: 'prime',
      displayName: 'Prime Video',
      asset: 'assets/studios/prime.png',
      companyId: 20580,
      networkId: 1024,
      aliases: ['amazon mgm studios', 'amazon studios', 'prime video', 'amazon'],
    ),
    StudioEntry(
      key: 'appletv',
      displayName: 'Apple TV+',
      asset: 'assets/studios/appletv.png',
      companyId: 194232,
      networkId: 2552,
      aliases: ['apple studios', 'apple tv+', 'apple tv', 'apple'],
    ),
    // companyId unverified — every candidate id probed returned an unrelated
    // catalogue. Resolve against /api/movies/studio/{id} before filling in.
    StudioEntry(
      key: 'max',
      displayName: 'Max',
      asset: 'assets/studios/max.png',
      networkId: 3186,
      aliases: ['hbo max', 'max originals'],
    ),
    StudioEntry(
      key: 'hulu',
      displayName: 'Hulu',
      asset: 'assets/studios/hulu.png',
      networkId: 453,
      aliases: ['hulu originals', 'hulu'],
    ),
    StudioEntry(
      key: 'vivamax',
      displayName: 'Vivamax',
      asset: 'assets/studios/vivamax.png',
      aliases: ['vivamax', 'viva communications', 'viva films', 'viva'],
    ),
  ];

  static final Map<String, StudioEntry> _byKey = {
    for (final e in entries) e.key: e,
  };

  /// Aliases sorted longest-first so 'walt disney pictures' wins over 'disney'.
  static final List<MapEntry<String, StudioEntry>> _aliasIndex = () {
    final list = <MapEntry<String, StudioEntry>>[
      for (final e in entries)
        for (final a in e.aliases) MapEntry(a, e),
    ];
    list.sort((a, b) => b.key.length.compareTo(a.key.length));
    return list;
  }();

  static StudioEntry? byKey(String? key) => key == null ? null : _byKey[key];

  static StudioEntry? matchByName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final needle = name.toLowerCase();
    for (final pair in _aliasIndex) {
      if (needle.contains(pair.key)) return pair.value;
    }
    return null;
  }

  static StudioEntry? matchByNetworkId(int? id) {
    if (id == null) return null;
    for (final e in entries) {
      if (e.networkId == id) return e;
    }
    return null;
  }
}
