import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;
import '../models/product_model.dart';
import '../services/api_service_products.dart';

class ProductProvider extends ChangeNotifier {
  final ApiServiceProducts _api = ApiServiceProducts();

  // DATA DARI MYSQL
  List<Product> _products = [];
  List<Category> _categories = [];
  List<String> _categoryList = [];

  // STATUS
  bool _loading = false;
  String? _error;

  // PAGINATION
  int _total = 0;
  int _skip = 0;
  int _limit = 30;

  // FILTER, SEARCH, SORT
  String _selectedCategory = '';
  String _query = '';
  String _sortBy = '';
  String _order = 'asc';
  bool _compact = false;

  // ==========================================================
  // GETTERS
  // ==========================================================

  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<String> get categoryList => _categoryList;

  bool get loading => _loading;
  String? get error => _error;

  int get total => _total;
  int get skip => _skip;
  int get limit => _limit;

  String get selectedCategory => _selectedCategory;
  String get query => _query;
  bool get compact => _compact;

  int get page => _skip ~/ _limit;

  int get totalPages =>
      _total == 0 ? 1 : (_total / _limit).ceil();

  bool get hasPrev => _skip > 0;
  bool get hasNext => _skip + _limit < _total;

  // ==========================================================
  // ERROR HANDLING
  // ==========================================================

  String _msg(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout) {
        return 'Tidak dapat terhubung ke backend Pastel.Shop. '
            'Pastikan Docker aktif dan alamat API sudah benar.';
      }

      final status = error.response?.statusCode;
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      return 'Gagal menghubungi backend'
          '${status == null ? "." : " (HTTP $status)."}';
    }

    return 'Terjadi kesalahan: $error';
  }

  // ==========================================================
  // INITIALIZATION
  // ==========================================================

  Future<void> init() async {
    await Future.wait([
      fetchCategories(),
      fetchProducts(),
    ]);
  }

  // ==========================================================
  // READ - MENAMPILKAN PRODUK MYSQL
  // ==========================================================

  Future<void> fetchProducts({
    int limit = 30,
    int skip = 0,
  }) async {
    _query = '';
    _selectedCategory = '';
    _sortBy = '';
    _order = 'asc';

    _limit = limit > 0 ? limit.clamp(1, 100).toInt() : 30;
    _skip = skip < 0 ? 0 : skip;

    await reload();
  }

  // ==========================================================
  // READ - KATEGORI
  // ==========================================================
  Future<void> fetchCategories() async {
    // Kategori untuk filter pada halaman utama.
    try {
      final categoryList = await _api.getCategoryList();

      _categoryList = categoryList;
      notifyListeners();

      debugPrint(
        'Berhasil memuat ${categoryList.length} kategori',
      );
    } catch (e) {
      debugPrint('Gagal memuat category-list: $e');
    }

    // Kategori berbentuk objek untuk form Tambah Produk.
    try {
      final categories = await _api.getCategories();

      _categories = categories;

      if (_categoryList.isEmpty) {
        _categoryList = categories
            .map((category) => category.slug)
            .toList();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Gagal memuat categories: $e');
    }
  }


  // ==========================================================
  // SEARCH - MENCARI PRODUK
  // ==========================================================

  Future<void> searchProducts(String query) async {
    if (query.trim().isEmpty) {
      await fetchProducts(limit: _limit);
      return;
    }

    _query = query.trim();
    _selectedCategory = '';
    _skip = 0;

    await reload();
  }

  // ==========================================================
  // FILTER - BERDASARKAN KATEGORI
  // ==========================================================

  Future<void> filterByCategory(String category) async {
    if (category.isEmpty) {
      await fetchProducts(limit: _limit);
      return;
    }

    _selectedCategory = category;
    _query = '';
    _skip = 0;

    await reload();
  }

  // ==========================================================
  // SORT - MENGURUTKAN PRODUK
  // ==========================================================

  Future<void> sortProducts(
    String sortBy,
    String order,
  ) async {
    _sortBy = sortBy;
    _order = order;
    _skip = 0;

    await reload();
  }

  // ==========================================================
  // COMPACT MODE
  // ==========================================================

  Future<void> setCompact(bool value) async {
    _compact = value;
    _skip = 0;

    await reload();
  }

  // ==========================================================
  // PAGINATION - HALAMAN BERIKUTNYA
  // ==========================================================

  Future<void> nextPage() async {
    if (!hasNext || _loading) return;

    _skip += _limit;
    await reload();
  }

  // ==========================================================
  // PAGINATION - HALAMAN SEBELUMNYA
  // ==========================================================

  Future<void> prevPage() async {
    if (!hasPrev || _loading) return;

    _skip -= _limit;

    if (_skip < 0) {
      _skip = 0;
    }

    await reload();
  }

  // ==========================================================
  // RELOAD - MENGAMBIL ULANG DATA DARI MYSQL
  // ==========================================================

  Future<void> reload() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final select = _compact ? 'title,price' : null;

      final sort = _sortBy.isEmpty ? null : _sortBy;

      Future<ProductsResponse> getData() {
        if (_query.isNotEmpty) {
          return _api.searchProducts(
            _query,
            limit: _limit,
            skip: _skip,
            select: select,
            sortBy: sort,
            order: _order,
          );
        }

        if (_selectedCategory.isNotEmpty) {
          return _api.getProductsByCategory(
            _selectedCategory,
            limit: _limit,
            skip: _skip,
            select: select,
            sortBy: sort,
            order: _order,
          );
        }

        return _api.getAllProducts(
          limit: _limit,
          skip: _skip,
          select: select,
          sortBy: sort,
          order: _order,
        );
      }

      var response = await getData();

      // Jika halaman terakhir menjadi kosong setelah DELETE,
      // arahkan ke halaman terakhir yang masih memiliki data.
      if (_skip > 0 &&
          response.products.isEmpty &&
          response.total < _skip + 1) {
        if (response.total == 0) {
          _skip = 0;
        } else {
          _skip = ((response.total - 1) ~/ _limit) * _limit;
        }

        response = await getData();
      }

      _products = response.products;
      _total = response.total;
    } catch (e) {
      _error = _msg(e);
      debugPrint('Gagal memuat produk: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ==========================================================
  // READ DETAIL - SATU PRODUK
  // ==========================================================

  Future<Product> fetchProduct(int id) async {
    return await _api.getProduct(id);
  }

  // ==========================================================
  // CREATE - TAMBAH PRODUK KE MYSQL
  // ==========================================================

  Future<Product?> addProduct(
    Map<String, dynamic> data,
  ) async {
    try {
      _error = null;

      // Kirim POST ke backend.
      final result = await _api.addProduct(data);

      // Kembali ke halaman awal agar produk mudah dicari.
      _query = '';
      _selectedCategory = '';
      _skip = 0;

      // Ambil ulang data agar jumlah produk sesuai MySQL.
      await reload();

      return result;
    } catch (e) {
      _error = _msg(e);
      notifyListeners();
      return null;
    }
  }

  // ==========================================================
  // UPDATE - EDIT PRODUK DI MYSQL
  // ==========================================================

  Future<bool> updateProduct(
    int id,
    Product updated,
  ) async {
    try {
      _error = null;

      await _api.updateProduct(
        id,
        updated.toJson(),
      );

      // Ambil ulang produk yang sudah diperbarui.
      await reload();

      return true;
    } catch (e) {
      _error = _msg(e);
      notifyListeners();
      return false;
    }
  }

  // ==========================================================
  // PATCH - EDIT SEBAGIAN DATA PRODUK
  // ==========================================================

  Future<bool> patchProduct(
    int id,
    Map<String, dynamic> partial,
  ) async {
    try {
      _error = null;

      await _api.patchProduct(
        id,
        partial,
      );

      await reload();

      return true;
    } catch (e) {
      _error = _msg(e);
      notifyListeners();
      return false;
    }
  }

  // ==========================================================
  // UPLOAD - UNGGAH GAMBAR PRODUK
  // ==========================================================

  String? _uploadError;
  String? get uploadError => _uploadError;

  /// Mengembalikan URL gambar, atau null jika gagal
  /// (pesan kesalahan ada di [uploadError]).
  Future<String?> uploadImage(String filePath) async {
    try {
      _uploadError = null;
      return await _api.uploadImage(filePath);
    } catch (e) {
      _uploadError = _msg(e);
      return null;
    }
  }

  // ==========================================================
  // DELETE - HAPUS PRODUK DARI MYSQL
  // ==========================================================

  Future<Product?> deleteProduct(int id) async {
    try {
      _error = null;

      // Hapus produk secara permanen melalui backend.
      final result = await _api.deleteProduct(id);

      // Perbarui daftar produk dan jumlah total dari MySQL.
      await reload();

      return result;
    } catch (e) {
      _error = _msg(e);
      notifyListeners();
      return null;
    }
  }
}