class BookQuery {
  final String search;
  final int? genreId;
  final int? publisherId;
  final int? yearFrom;
  final int? yearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const BookQuery({
    this.search = '',
    this.genreId,
    this.publisherId,
    this.yearFrom,
    this.yearTo,
    this.sortField = 'title',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  BookQuery copyWith({
    String? search,
    Object? genreId = _unset,
    Object? publisherId = _unset,
    Object? yearFrom = _unset,
    Object? yearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return BookQuery(
      search: search ?? this.search,
      genreId: genreId == _unset ? this.genreId : genreId as int?,
      publisherId: publisherId == _unset ? this.publisherId : publisherId as int?,
      yearFrom: yearFrom == _unset ? this.yearFrom : yearFrom as int?,
      yearTo: yearTo == _unset ? this.yearTo : yearTo as int?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (search.isNotEmpty) params['search'] = search;
    if (genreId != null) params['genreId'] = genreId.toString();
    if (publisherId != null) params['publisherId'] = publisherId.toString();
    if (yearFrom != null) params['yearFrom'] = yearFrom.toString();
    if (yearTo != null) params['yearTo'] = yearTo.toString();
    params['sort'] = '$sortField,${sortAscending ? "asc" : "desc"}';
    if (page > 1) params['page'] = page.toString();
    if (size != 10) params['size'] = size.toString();
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory BookQuery.fromQueryParams(Map<String, dynamic> params) {
    final sortStr = params['sort']?.toString() ?? 'title,asc';
    final sortParts = sortStr.split(',');
    return BookQuery(
      search: params['search']?.toString() ?? '',
      genreId: int.tryParse(params['genreId']?.toString() ?? ''),
      publisherId: int.tryParse(params['publisherId']?.toString() ?? ''),
      yearFrom: int.tryParse(params['yearFrom']?.toString() ?? ''),
      yearTo: int.tryParse(params['yearTo']?.toString() ?? ''),
      sortField: sortParts[0],
      sortAscending: sortParts.length > 1 && sortParts[1] == 'asc',
      page: int.tryParse(params['page']?.toString() ?? '1') ?? 1,
      size: int.tryParse(params['size']?.toString() ?? '10') ?? 10,
      includeDeleted: params['includeDeleted']?.toString() == 'true',
    );
  }
}