class CatalogQuery {
  final String search;
  final String sortField;
  final bool ascending;
  final bool includeDeleted;
  final int page;
  final int size;
  final Map<String, String> filters;
  const CatalogQuery({
    this.search = '',
    this.sortField = '',
    this.ascending = true,
    this.includeDeleted = false,
    this.page = 1,
    this.size = 10,
    this.filters = const {},
  });

  factory CatalogQuery.fromParams(Map<String, String> params) {
    final sort = (params['sort'] ?? '').split(',');
    final page = int.tryParse(params['page'] ?? '') ?? 1;
    final size = int.tryParse(params['size'] ?? '') ?? 10;
    return CatalogQuery(
      search: params['search'] ?? '',
      sortField: sort.first,
      ascending: sort.length < 2 || sort[1] != 'desc',
      includeDeleted: params['includeDeleted'] == 'true',
      page: page < 1 ? 1 : page,
      size: const [10, 25, 50].contains(size) ? size : 10,
      filters: Map.of(params)..removeWhere(
        (key, _) => const [
          'search',
          'sort',
          'includeDeleted',
          'page',
          'size',
        ].contains(key),
      ),
    );
  }
  Map<String, String> toParams() => {
    ...filters,
    if (search.isNotEmpty) 'search': search,
    if (sortField.isNotEmpty)
      'sort': '$sortField,${ascending ? 'asc' : 'desc'}',
    if (includeDeleted) 'includeDeleted': 'true',
    if (page > 1) 'page': '$page',
    if (size != 10) 'size': '$size',
  };
  CatalogQuery copyWith({
    String? search,
    String? sortField,
    bool? ascending,
    bool? includeDeleted,
    int? page,
    int? size,
    Map<String, String>? filters,
  }) => CatalogQuery(
    search: search ?? this.search,
    sortField: sortField ?? this.sortField,
    ascending: ascending ?? this.ascending,
    includeDeleted: includeDeleted ?? this.includeDeleted,
    page: page ?? 1,
    size: size ?? this.size,
    filters: filters ?? this.filters,
  );
}
