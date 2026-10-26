class AuthorQuery {
  final String search;
  final String? country;
  final int? birthYearFrom;
  final int? birthYearTo;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const AuthorQuery({
    this.search = '',
    this.country,
    this.birthYearFrom,
    this.birthYearTo,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  AuthorQuery copyWith({
    String? search,
    Object? country = _unset,
    Object? birthYearFrom = _unset,
    Object? birthYearTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AuthorQuery(
      search: search ?? this.search,
      country: country == _unset ? this.country : country as String?,
      birthYearFrom: birthYearFrom == _unset ? this.birthYearFrom : birthYearFrom as int?,
      birthYearTo: birthYearTo == _unset ? this.birthYearTo : birthYearTo as int?,
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
    if (country != null) params['country'] = country!;
    if (birthYearFrom != null) params['birthYearFrom'] = birthYearFrom.toString();
    if (birthYearTo != null) params['birthYearTo'] = birthYearTo.toString();
    params['sort'] = '$sortField,${sortAscending ? "asc" : "desc"}';
    if (page > 1) params['page'] = page.toString();
    if (size != 10) params['size'] = size.toString();
    if (includeDeleted) params['includeDeleted'] = 'true';
    return params;
  }

  factory AuthorQuery.fromQueryParams(Map<String, dynamic> params) {
    final sortStr = params['sort']?.toString() ?? 'lastName,asc';
    final sortParts = sortStr.split(',');
    return AuthorQuery(
      search: params['search']?.toString() ?? '',
      country: params['country']?.toString(),
      birthYearFrom: int.tryParse(params['birthYearFrom']?.toString() ?? ''),
      birthYearTo: int.tryParse(params['birthYearTo']?.toString() ?? ''),
      sortField: sortParts[0],
      sortAscending: sortParts.length > 1 && sortParts[1] == 'asc',
      page: int.tryParse(params['page']?.toString() ?? '1') ?? 1,
      size: int.tryParse(params['size']?.toString() ?? '10') ?? 10,
      includeDeleted: params['includeDeleted']?.toString() == 'true',
    );
  }
}