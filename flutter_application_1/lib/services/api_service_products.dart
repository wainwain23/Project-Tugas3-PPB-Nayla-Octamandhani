import 'package:dio/dio.dart';
import '../models/product_model.dart';

class ApiServiceProducts {
  // Backend Pastel.Shop menggunakan Node.js Express + MySQL.
  //
  // Emulator Android:
  // http://10.0.2.2:3001
  //
  // HP Android fisik melalui USB:
  // adb reverse tcp:3001 tcp:3001
  // Gunakan --dart-define=API_BASE_URL=http://127.0.0.1:3001

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://10.0.2.2:3001',
      ),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // ============================================================
  // READ - Menampilkan daftar produk dari database MySQL
  // ============================================================

  Future<ProductsResponse> getAllProducts({
    int limit = 30,
    int skip = 0,
    String? select,
    String? sortBy,
    String? order,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };

    if (sortBy != null && sortBy.isNotEmpty) {
      params['sortBy'] = sortBy;
      params['order'] = order ?? 'asc';
    }

    final response = await _dio.get(
      '/products',
      queryParameters: params,
    );

    return ProductsResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // READ DETAIL - Menampilkan detail satu produk
  // ============================================================

  Future<Product> getProduct(int id) async {
    final response = await _dio.get('/products/$id');

    return Product.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // SEARCH - Mencari produk berdasarkan kata kunci
  // ============================================================

  Future<ProductsResponse> searchProducts(
    String query, {
    int limit = 30,
    int skip = 0,
    String? select,
    String? sortBy,
    String? order,
  }) async {
    final params = <String, dynamic>{
      'q': query,
      'limit': limit,
      'skip': skip,
    };

    if (sortBy != null && sortBy.isNotEmpty) {
      params['sortBy'] = sortBy;
      params['order'] = order ?? 'asc';
    }

    final response = await _dio.get(
      '/products/search',
      queryParameters: params,
    );

    return ProductsResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // PAGINATION - Menampilkan produk per halaman
  // ============================================================

  Future<ProductsResponse> getProductsPaginated({
    int limit = 10,
    int skip = 0,
    String? select,
  }) async {
    final response = await _dio.get(
      '/products',
      queryParameters: {
        'limit': limit,
        'skip': skip,
      },
    );

    return ProductsResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // SORT - Mengurutkan produk
  // ============================================================

  Future<ProductsResponse> sortProducts(
    String sortBy,
    String order, {
    int limit = 30,
    int skip = 0,
  }) async {
    final response = await _dio.get(
      '/products',
      queryParameters: {
        'sortBy': sortBy,
        'order': order,
        'limit': limit,
        'skip': skip,
      },
    );

    return ProductsResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // CATEGORY - Mengambil semua kategori
  // ============================================================

  Future<List<Category>> getCategories() async {
    final response = await _dio.get(
      '/products/categories',
    );

    return (response.data as List)
        .map(
          (item) => Category.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  // ============================================================
  // CATEGORY LIST - Mengambil daftar nama kategori
  // ============================================================

  Future<List<String>> getCategoryList() async {
    final response = await _dio.get(
      '/products/category-list',
    );

    return (response.data as List)
        .map((item) => item.toString())
        .toList();
  }

  // ============================================================
  // FILTER - Menampilkan produk berdasarkan kategori
  // ============================================================

  Future<ProductsResponse> getProductsByCategory(
    String category, {
    int limit = 30,
    int skip = 0,
    String? select,
    String? sortBy,
    String? order,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'skip': skip,
    };

    if (sortBy != null && sortBy.isNotEmpty) {
      params['sortBy'] = sortBy;
      params['order'] = order ?? 'asc';
    }

    final encodedCategory = Uri.encodeComponent(category);

    final response = await _dio.get(
      '/products/category/$encodedCategory',
      queryParameters: params,
    );

    return ProductsResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // CREATE - Menambah produk baru ke MySQL
  // ============================================================

  Future<Product> addProduct(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/products/add',
      data: data,
    );

    return Product.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // UPDATE - Mengedit produk di MySQL
  // ============================================================

  Future<Product> updateProduct(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put(
      '/products/$id',
      data: data,
    );

    return Product.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // PATCH - Mengedit sebagian data produk di MySQL
  // ============================================================

  Future<Product> patchProduct(
    int id,
    Map<String, dynamic> partialData,
  ) async {
    final response = await _dio.patch(
      '/products/$id',
      data: partialData,
    );

    return Product.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ============================================================
  // UPLOAD - Mengunggah gambar produk (multipart/form-data)
  // Membutuhkan route POST /products/upload di backend Express.
  // Respons yang diharapkan: {"url": "http://.../uploads/xxx.jpg"}
  // ============================================================

  Future<String> uploadImage(String filePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/products/upload',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    final url = (data is Map
            ? (data['url'] ?? data['imageUrl'] ?? data['thumbnail'])
            : null)
        ?.toString();

    if (url == null || url.isEmpty) {
      throw Exception('Respons upload tidak berisi URL gambar.');
    }

    // Jika backend mengirim path relatif, jadikan URL lengkap.
    if (url.startsWith('/')) {
      return '${_dio.options.baseUrl}$url';
    }

    return url;
  }

  // ============================================================
  // DELETE - Menghapus produk permanen dari MySQL
  // ============================================================

  Future<Product> deleteProduct(int id) async {
    final response = await _dio.delete(
      '/products/$id',
    );

    return Product.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }
}