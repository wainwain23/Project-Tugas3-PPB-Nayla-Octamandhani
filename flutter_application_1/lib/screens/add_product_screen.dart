
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Informasi utama
  final _title = TextEditingController();
  final _brand = TextEditingController();
  final _category = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();

  // Rating dan diskon
  final _rating = TextEditingController();
  final _discount = TextEditingController();

  // Detail produk
  final _sku = TextEditingController();
  final _tags = TextEditingController();
  final _weight = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _depth = TextEditingController();
  final _minimumOrder = TextEditingController(text: '1');

  // Pengiriman dan garansi
  final _warranty = TextEditingController();
  final _shipping = TextEditingController();
  final _returnPolicy = TextEditingController();

  // Gambar dan metadata
  final _extraImages = TextEditingController();
  final _barcode = TextEditingController();
  final _qrCode = TextEditingController();

  // Ulasan
  final _reviewerName = TextEditingController();
  final _reviewerEmail = TextEditingController();
  final _reviewRating = TextEditingController();
  final _reviewComment = TextEditingController();

  String _categorySlug = '';
  String _availability = 'Otomatis';
  bool _saving = false;

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    final controllers = <TextEditingController>[
      _title,
      _brand,
      _category,
      _price,
      _stock,
      _description,
      _imageUrl,
      _rating,
      _discount,
      _sku,
      _tags,
      _weight,
      _width,
      _height,
      _depth,
      _minimumOrder,
      _warranty,
      _shipping,
      _returnPolicy,
      _extraImages,
      _barcode,
      _qrCode,
      _reviewerName,
      _reviewerEmail,
      _reviewRating,
      _reviewComment,
    ];

    for (final controller in controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // =====================================================
  // VALIDASI
  // =====================================================

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kolom ini wajib diisi';
    }
    return null;
  }

  String? _validateNumber(
    String? value, {
    double min = 0,
    double? max,
    bool integer = false,
    bool required = false,
  }) {
    final text = (value ?? '').trim().replaceAll(',', '.');

    if (text.isEmpty) {
      return required ? 'Kolom ini wajib diisi' : null;
    }

    if (integer) {
      final number = int.tryParse(text);

      if (number == null ||
          number < min ||
          (max != null && number > max) ||
          number > 2147483647) {
        return 'Masukkan angka bulat yang valid';
      }

      return null;
    }

    final number = double.tryParse(text);

    if (number == null ||
        !number.isFinite ||
        number < min ||
        (max != null && number > max)) {
      return 'Masukkan angka yang valid';
    }

    return null;
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String? _validateUrl(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) return null;

    if (!_isValidUrl(text)) {
      return 'Masukkan URL http atau https yang valid';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();

    if (text.isEmpty) return null;

    final emailPattern = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailPattern.hasMatch(text)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  List<String> _splitTags(String value) {
    return value
        .split(RegExp(r'[,;\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _splitImages(String value) {
    return value
        .split(RegExp(r'[;\n]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _validateImages(String? value) {
    for (final url in _splitImages(value ?? '')) {
      if (!_isValidUrl(url)) {
        return 'Ada URL gambar yang tidak valid';
      }
    }

    return null;
  }

  double _toDouble(TextEditingController controller) {
    return double.parse(
      controller.text.trim().replaceAll(',', '.'),
    );
  }

  int _toInt(TextEditingController controller) {
    return int.parse(controller.text.trim());
  }

  bool get _hasReview {
    return [
      _reviewerName,
      _reviewerEmail,
      _reviewRating,
      _reviewComment,
    ].any((controller) => controller.text.trim().isNotEmpty);
  }

  // =====================================================
  // WIDGET INPUT
  // =====================================================

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String hint = '',
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        validator: validator,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: pastelField(
          label: label,
          hint: hint,
          icon: icon,
          prefixText: prefixText,
        ).copyWith(
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  // =====================================================
  // PILIH KATEGORI
  // =====================================================

  Future<void> _chooseCategory() async {
    final categories =
        context.read<ProductProvider>().categories;

    if (categories.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.sizeOf(sheetContext).height * 0.65,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20,
              ),
              children: [
                const Text(
                  'Pilih Kategori',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                for (final category in categories)
                  ListTile(
                    title: Text(category.name),
                    trailing: category.slug == _categorySlug
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accent,
                          )
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext)
                          .pop(category.slug);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) return;

    final selectedCategory = categories.firstWhere(
      (item) => item.slug == selected,
    );

    setState(() {
      _categorySlug = selectedCategory.slug;
      _category.text = selectedCategory.name;
    });
  }

  // =====================================================
  // SIMPAN PRODUK KE MYSQL
  // =====================================================

  Future<void> _submit() async {
    if (_saving) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    final provider = context.read<ProductProvider>();

    try {
      final price = _toDouble(_price);

      final stock = _stock.text.trim().isEmpty
          ? 0
          : _toInt(_stock);

      final category = _categorySlug.isNotEmpty
          ? _categorySlug
          : _category.text.trim();

      final now = DateTime.now().toUtc().toIso8601String();

      // Gabungkan gambar utama dan gambar tambahan
      final imageUrls = <String>{
  if (_imageUrl.text.trim().isNotEmpty)
    _imageUrl.text.trim(),
  ..._splitImages(_extraImages.text),
}.toList();

      final thumbnail = _imageUrl.text.trim().isNotEmpty
          ? _imageUrl.text.trim()
          : (imageUrls.isNotEmpty ? imageUrls.first : '');

      // Status stok otomatis
      final availabilityStatus = _availability == 'Otomatis'
          ? (stock == 0
              ? 'Out of Stock'
              : stock <= 10
                  ? 'Low Stock'
                  : 'In Stock')
          : _availability;

      // Payload JSON untuk backend
      final data = <String, dynamic>{
        'title': _title.text.trim(),
        'brand': _brand.text.trim(),
        'category': category,
        'price': price,
        'stock': stock,
        'description': _description.text.trim(),
        'thumbnail': thumbnail,

        'tags': _splitTags(_tags.text),
        'images': imageUrls,

        'minimumOrderQuantity': _toInt(_minimumOrder),
        'availabilityStatus': availabilityStatus,

        'meta': <String, dynamic>{
          'createdAt': now,
          'updatedAt': now,
          if (_barcode.text.trim().isNotEmpty)
            'barcode': _barcode.text.trim(),
          if (_qrCode.text.trim().isNotEmpty)
            'qrCode': _qrCode.text.trim(),
        },
      };

      // Rating produk
      if (_rating.text.trim().isNotEmpty) {
        data['rating'] = _toDouble(_rating);
      }

      // Diskon
      if (_discount.text.trim().isNotEmpty) {
        data['discountPercentage'] = _toDouble(_discount);
      }

      // SKU
      if (_sku.text.trim().isNotEmpty) {
        data['sku'] = _sku.text.trim();
      }

      // Berat
      if (_weight.text.trim().isNotEmpty) {
        data['weight'] = _toInt(_weight);
      }

      // Dimensi
      final hasDimensions = [
        _width,
        _height,
        _depth,
      ].any((controller) {
        return controller.text.trim().isNotEmpty;
      });

      if (hasDimensions) {
        data['dimensions'] = <String, dynamic>{
          'width': _width.text.trim().isEmpty
              ? 0.0
              : _toDouble(_width),
          'height': _height.text.trim().isEmpty
              ? 0.0
              : _toDouble(_height),
          'depth': _depth.text.trim().isEmpty
              ? 0.0
              : _toDouble(_depth),
        };
      }

      // Informasi garansi
      if (_warranty.text.trim().isNotEmpty) {
        data['warrantyInformation'] =
            _warranty.text.trim();
      }

      // Informasi pengiriman
      if (_shipping.text.trim().isNotEmpty) {
        data['shippingInformation'] =
            _shipping.text.trim();
      }

      // Kebijakan pengembalian
      if (_returnPolicy.text.trim().isNotEmpty) {
        data['returnPolicy'] =
            _returnPolicy.text.trim();
      }

      // Ulasan hanya dikirim jika benar-benar diisi
      if (_hasReview) {
        data['reviews'] = [
          <String, dynamic>{
            'rating': _toInt(_reviewRating),
            'comment': _reviewComment.text.trim(),
            'date': now,
            'reviewerName': _reviewerName.text.trim(),
            'reviewerEmail': _reviewerEmail.text.trim(),
          },
        ];
      }

      final result = await provider.addProduct(data);

      if (!mounted) return;

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menambahkan produk: '
              '${provider.error ?? 'Terjadi kesalahan.'}',
            ),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Produk berhasil ditambahkan. ID: ${result.id}',
          ),
        ),
      );

      context.pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan produk: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =====================================================
  // PRATINJAU GAMBAR
  // =====================================================

  Widget _imagePreview() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _imageUrl,
      builder: (context, value, child) {
        final url = value.text.trim();

        return Container(
          height: 180,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.lavenderSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.line,
            ),
          ),
          child: _isValidUrl(url)
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (context, imageUrl) =>
                      const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, imageUrl, error) =>
                      const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: AppColors.inkSoft,
                    ),
                  ),
                )
              : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: AppColors.pinkDeep,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Pratinjau gambar produk',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  // =====================================================
  // BANNER
  // =====================================================

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.pink,
            AppColors.lavender,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.add_shopping_cart_rounded,
              size: 34,
              color: AppColors.accent,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Tambah Produk Baru',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Lengkapi informasi produk untuk '
            'ditampilkan di katalog Pastel.Shop.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // HALAMAN
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final categories =
        context.watch<ProductProvider>().categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tambah Produk'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          children: [
            _banner(),

            const SizedBox(height: 22),

            // INFORMASI PRODUK
            SectionCard(
              title: 'Informasi Produk',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  _field(
                    controller: _title,
                    label: 'Nama Produk',
                    hint: 'Contoh: Lipstik Pink Pastel',
                    icon: Icons.shopping_bag_outlined,
                    validator: _required,
                  ),
                  _field(
                    controller: _brand,
                    label: 'Merek',
                    hint: 'Contoh: Pastel Beauty',
                    icon: Icons.sell_outlined,
                  ),
                  _field(
                    controller: _category,
                    label: 'Kategori',
                    hint: categories.isNotEmpty
                        ? 'Pilih kategori'
                        : 'Contoh: beauty',
                    icon: Icons.category_outlined,
                    readOnly: categories.isNotEmpty,
                    onTap: categories.isNotEmpty
                        ? _chooseCategory
                        : null,
                    suffixIcon: categories.isNotEmpty
                        ? const Icon(
                            Icons.keyboard_arrow_down_rounded,
                          )
                        : null,
                    validator: _required,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // HARGA DAN STOK
            SectionCard(
              title: 'Harga dan Stok',
              icon: Icons.payments_outlined,
              tint: AppColors.mint,
              child: Column(
                children: [
                  _field(
                    controller: _price,
                    label: 'Harga Produk',
                    hint: 'Contoh: 12.99',
                    icon: Icons.attach_money_rounded,
                    prefixText: '\$ ',
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => _validateNumber(
                      value,
                      required: true,
                    ),
                  ),
                  _field(
                    controller: _stock,
                    label: 'Jumlah Stok',
                    hint: 'Contoh: 25',
                    icon: Icons.inventory_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNumber(
                      value,
                      integer: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // RATING DAN DISKON
            SectionCard(
              title: 'Rating dan Diskon',
              icon: Icons.star_outline_rounded,
              tint: AppColors.peach,
              child: Column(
                children: [
                  _field(
                    controller: _rating,
                    label: 'Rating Produk (0–5)',
                    hint: 'Contoh: 4.5',
                    icon: Icons.star_border_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => _validateNumber(
                      value,
                      min: 0,
                      max: 5,
                    ),
                  ),
                  _field(
                    controller: _discount,
                    label: 'Diskon (%)',
                    hint: 'Contoh: 10.48',
                    icon: Icons.percent_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) => _validateNumber(
                      value,
                      min: 0,
                      max: 100,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DETAIL PRODUK
            SectionCard(
              title: 'Detail Produk',
              icon: Icons.info_outline_rounded,
              tint: AppColors.lavender,
              child: Column(
                children: [
                  _field(
                    controller: _sku,
                    label: 'SKU',
                    hint: 'Contoh: BEA-PAS-LIP-001',
                    icon: Icons.qr_code_rounded,
                  ),
                  _field(
                    controller: _tags,
                    label: 'Tags',
                    hint: 'Contoh: beauty, lipstick, pink',
                    icon: Icons.sell_outlined,
                  ),
                  _field(
                    controller: _weight,
                    label: 'Berat',
                    hint: 'Contoh: 2',
                    icon: Icons.scale_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNumber(
                      value,
                      integer: true,
                    ),
                  ),
                  _field(
                    controller: _minimumOrder,
                    label: 'Minimum Order',
                    hint: 'Contoh: 1',
                    icon: Icons.shopping_cart_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNumber(
                      value,
                      min: 1,
                      integer: true,
                      required: true,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DIMENSI PRODUK
            SectionCard(
              title: 'Dimensi Produk',
              icon: Icons.straighten_rounded,
              tint: AppColors.mint,
              child: Column(
                children: [
                  _field(
                    controller: _width,
                    label: 'Lebar (width)',
                    hint: 'Contoh: 15.14',
                    icon: Icons.straighten_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                  _field(
                    controller: _height,
                    label: 'Tinggi (height)',
                    hint: 'Contoh: 13.08',
                    icon: Icons.height_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                  _field(
                    controller: _depth,
                    label: 'Kedalaman (depth)',
                    hint: 'Contoh: 22.99',
                    icon: Icons.straighten_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validateNumber,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // PENGIRIMAN DAN GARANSI
            SectionCard(
              title: 'Pengiriman dan Garansi',
              icon: Icons.local_shipping_outlined,
              tint: AppColors.peach,
              child: Column(
                children: [
                  _field(
                    controller: _warranty,
                    label: 'Informasi Garansi',
                    hint: 'Contoh: 1 month warranty',
                    icon: Icons.verified_user_outlined,
                  ),
                  _field(
                    controller: _shipping,
                    label: 'Informasi Pengiriman',
                    hint: 'Contoh: Ships in 3-5 business days',
                    icon: Icons.local_shipping_outlined,
                  ),
                  _field(
                    controller: _returnPolicy,
                    label: 'Kebijakan Pengembalian',
                    hint: 'Contoh: 7 days return policy',
                    icon: Icons.keyboard_return_rounded,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _availability,
                    isExpanded: true,
                    decoration: pastelField(
                      label: 'Status Ketersediaan',
                      hint: 'Pilih status',
                      icon: Icons.inventory_2_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Otomatis',
                        child: Text('Otomatis dari stok'),
                      ),
                      DropdownMenuItem(
                        value: 'In Stock',
                        child: Text('In Stock'),
                      ),
                      DropdownMenuItem(
                        value: 'Low Stock',
                        child: Text('Low Stock'),
                      ),
                      DropdownMenuItem(
                        value: 'Out of Stock',
                        child: Text('Out of Stock'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _availability = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // GAMBAR PRODUK
            SectionCard(
              title: 'Gambar Produk',
              icon: Icons.image_outlined,
              tint: AppColors.lavender,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imagePreview(),
                  const SizedBox(height: 14),
                  _field(
                    controller: _imageUrl,
                    label: 'URL Gambar Utama',
                    hint: 'https://contoh.com/gambar.jpg',
                    icon: Icons.link_rounded,
                    keyboardType: TextInputType.url,
                    validator: _validateUrl,
                  ),
                  _field(
                    controller: _extraImages,
                    label: 'URL Gambar Tambahan',
                    hint: 'Satu URL per baris',
                    icon: Icons.collections_outlined,
                    keyboardType: TextInputType.multiline,
                    maxLines: 3,
                    validator: _validateImages,
                  ),
                  const Text(
                    'Gunakan URL gambar yang bisa diakses. '
                    'Gambar utama ditampilkan di katalog.',
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // METADATA PRODUK
            SectionCard(
              title: 'Metadata Produk',
              icon: Icons.qr_code_2_rounded,
              tint: AppColors.mint,
              child: Column(
                children: [
                  _field(
                    controller: _barcode,
                    label: 'Barcode (Opsional)',
                    hint: 'Contoh: 5784719087687',
                    icon: Icons.qr_code_scanner_rounded,
                  ),
                  _field(
                    controller: _qrCode,
                    label: 'URL QR Code (Opsional)',
                    hint: 'https://contoh.com/qr.png',
                    icon: Icons.qr_code_rounded,
                    keyboardType: TextInputType.url,
                    validator: _validateUrl,
                  ),
                  const Text(
                    'Tanggal dibuat dan diperbarui '
                    'diisi otomatis.',
                    style: TextStyle(
                      color: AppColors.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DESKRIPSI PRODUK
            SectionCard(
              title: 'Deskripsi Produk',
              icon: Icons.notes_rounded,
              tint: AppColors.peach,
              child: _field(
                controller: _description,
                label: 'Deskripsi',
                hint: 'Jelaskan informasi produk...',
                icon: Icons.description_outlined,
                maxLines: 4,
              ),
            ),

            const SizedBox(height: 16),

            // ULASAN AWAL
            SectionCard(
              title: 'Ulasan Awal (Opsional)',
              icon: Icons.rate_review_outlined,
              tint: AppColors.lavender,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Untuk produk baru, ulasan boleh kosong. '
                      'Isi hanya jika sudah ada ulasan '
                      'dari pembeli.',
                      style: TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  _field(
                    controller: _reviewerName,
                    label: 'Nama Pengulas',
                    hint: 'Nama pembeli',
                    icon: Icons.person_outline_rounded,
                    validator: (value) =>
                        _hasReview ? _required(value) : null,
                  ),
                  _field(
                    controller: _reviewerEmail,
                    label: 'Email Pengulas',
                    hint: 'nama@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  _field(
                    controller: _reviewRating,
                    label: 'Rating Ulasan (1–5)',
                    hint: 'Contoh: 5',
                    icon: Icons.star_outline_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) => _validateNumber(
                      value,
                      min: 1,
                      max: 5,
                      integer: true,
                      required: _hasReview,
                    ),
                  ),
                  _field(
                    controller: _reviewComment,
                    label: 'Komentar Ulasan',
                    hint: 'Komentar pembeli...',
                    icon: Icons.comment_outlined,
                    maxLines: 3,
                    validator: (value) =>
                        _hasReview ? _required(value) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // TOMBOL SIMPAN
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: AppColors.line,
              ),
            ),
          ),
          child: FilledButton.icon(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.check_circle_outline_rounded,
                  ),
            label: Text(
              _saving
                  ? 'Menyimpan...'
                  : 'Simpan Produk',
            ),
          ),
        ),
      ),
    );
  }
}
