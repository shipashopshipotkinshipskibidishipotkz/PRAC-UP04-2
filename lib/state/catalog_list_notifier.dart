import 'package:flutter/foundation.dart';
import '../core/api_exceptions.dart';
import '../core/request_cancellation.dart';
import '../models/catalog_query.dart';
import '../models/entity_kind.dart';
import '../models/library_entity.dart';
import '../models/page_result.dart';
import '../repositories/library_repository.dart';

enum CatalogStatus { loading, data, empty, error }

class CatalogListNotifier extends ChangeNotifier {
  final LibraryRepository repository;
  final EntityKind kind;
  PageResult<LibraryEntity> result = PageResult.empty();
  CatalogStatus status = CatalogStatus.loading;
  String? error;
  RequestCancellation? _request;
  bool _disposed = false;
  CatalogListNotifier(this.repository, this.kind);
  void cancelPending() {
    _request?.cancel();
  }

  Future<void> load(CatalogQuery query) async {
    cancelPending();
    final request = RequestCancellation();
    _request = request;
    status = CatalogStatus.loading;
    error = null;
    result = PageResult.empty();
    notifyListeners();
    try {
      final page = await repository.find(kind, query, cancellation: request);
      if (_disposed || request.isCancelled || !identical(_request, request)) {
        return;
      }
      result = page;
      status = page.items.isEmpty ? CatalogStatus.empty : CatalogStatus.data;
    } on RequestCancelledException {
      return;
    } catch (exception) {
      if (_disposed || request.isCancelled || !identical(_request, request)) {
        return;
      }
      error =
          exception is ApiException
              ? exception.message
              : 'Не удалось загрузить данные. Попробуйте ещё раз.';
      status = CatalogStatus.error;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cancelPending();
    super.dispose();
  }
}
