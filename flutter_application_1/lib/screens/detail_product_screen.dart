import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class DetailProductScreen extends StatefulWidget {
  final String id;

  const DetailProductScreen({
    super.key,
    required this.id,
  });

  @override
  State<DetailProductScreen> createState() => _DetailProductScreenState();
}

class _DetailProductScreenState extends State<DetailProductScreen> {
  Product? _product;
  bool _loading = true;
  bool _failed = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  // Bab 9: GET /products/{id}
  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    Product? result;
    bool failed = false;

    try {
      result = await context
          .read<ProductProvider>()
          .fetchProduct(int.parse(widget.id));
    } catch (_) {
      failed = true;
    }

    if (!mounted) return;

    setState(() {
      _product = result;
      _failed = failed;
      _loading = false;
    });
  }

  // Membuka halaman Edit dan menerima hasilnya.
  Future<void> _edit() async {
    final product = _product;
    if (product == null) return;

    final updated = await context.push<Product>(
      '/edit/${product.id}',
      extra: product,
    );

    if (!mounted) return;

    if (updated != null) {
      setState(() => _product = updated);
    }
  }

  // Bab 9: DELETE /products/{id}
  Future<void> _delete() async {
    final product = _product;
    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text(
          'Apakah kamu yakin ingin menghapus "${product.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => dialogContext.pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 44),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await context
        .read<ProductProvider>()
        .deleteProduct(product.id);

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result == null
              ? 'Gagal menghapus produk.'
              : 'Permintaan DELETE berhasil. '
                  'Data DummyJSON tidak berubah permanen.',
        ),
      ),
    );

    if (result != null) {
      router.pop();
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Produk')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_failed || product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Produk')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_outlined,
                    size: 40,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal memuat detail produk.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _fetch,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _content(context, product),
    );
  }

  // ----------------------------------------------------------
  // KONTEN
  // ----------------------------------------------------------

  Widget _content(BuildContext context, Product product) {
    final textTheme = Theme.of(context).textTheme;
    final tint = AppColors.tintFor(product.id);
    final hasDiscount = product.discountPercentage > 0;

    final images = product.images.isNotEmpty
        ? product.images
        : product.thumbnail.isNotEmpty
            ? [product.thumbnail]
            : <String>[];

    final infoItems = <_InfoItem>[
      _InfoItem(Icons.qr_code_2_rounded, 'SKU', product.sku),
      _InfoItem(Icons.scale_outlined, 'Berat', '${product.weight}'),
      _InfoItem(
        Icons.straighten_rounded,
        'Dimensi',
        '${product.dimensions.width} x '
            '${product.dimensions.height} x '
            '${product.dimensions.depth}',
      ),
      _InfoItem(
        Icons.verified_user_outlined,
        'Garansi',
        product.warrantyInformation,
      ),
      _InfoItem(
        Icons.local_shipping_outlined,
        'Pengiriman',
        product.shippingInformation,
      ),
      _InfoItem(
        Icons.assignment_return_outlined,
        'Kebijakan retur',
        product.returnPolicy,
      ),
      _InfoItem(
        Icons.inventory_2_outlined,
        'Minimum order',
        '${product.minimumOrderQuantity}',
      ),
    ].where((e) => e.value.trim().isNotEmpty).toList();

    return CustomScrollView(
      slivers: [
        // Galeri gambar produk dari API.
        SliverAppBar(
          pinned: true,
          expandedHeight: 360,
          backgroundColor: tint,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(6),
            child: PastelIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Kembali',
              onTap: _back,
            ),
          ),
          // Aksi Edit dan Hapus berada di bagian atas halaman.
          actions: [
            PastelIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Edit produk',
              onTap: _edit,
            ),
            const SizedBox(width: 8),
            PastelIconButton(
              icon: Icons.delete_outline,
              tooltip: 'Hapus produk',
              iconColor: AppColors.danger,
              onTap: _delete,
            ),
            const SizedBox(width: 14),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: _gallery(context, images, tint),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(
                      icon: Icons.category_outlined,
                      text: product.category,
                      color: AppColors.pink,
                    ),
                    if (product.brand.isNotEmpty)
                      _Pill(
                        icon: Icons.sell_outlined,
                        text: product.brand,
                        color: AppColors.lavender,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(product.title, style: textTheme.headlineSmall),
                const SizedBox(height: 14),

                // Harga dan diskon.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Harga',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.end,
                              spacing: 10,
                              children: [
                                Text(
                                  '\$${product.finalPrice.toStringAsFixed(2)}',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: AppColors.accent,
                                  ),
                                ),
                                if (hasDiscount)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.inkSoft,
                                        decoration:
                                            TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '-${product.discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Rating, stok, dan status.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Stars(rating: product.rating, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            product.rating.toStringAsFixed(2),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Pill(
                      icon: Icons.inventory_2_outlined,
                      text: 'Stok: ${product.stock}',
                      color: product.stock > 0
                          ? AppColors.mint
                          : const Color(0xFFF0D3D6),
                    ),
                    if (product.availabilityStatus.isNotEmpty)
                      _Pill(
                        icon: Icons.check_circle_outline_rounded,
                        text: product.availabilityStatus,
                        color: AppColors.sky,
                      ),
                  ],
                ),

                const SizedBox(height: 24),
                const _SectionTitle('Deskripsi Produk'),
                const SizedBox(height: 10),
                Text(
                  product.description.isEmpty
                      ? 'Tidak ada deskripsi produk.'
                      : product.description,
                  style: textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: AppColors.ink.withValues(alpha: 0.85),
                  ),
                ),

                if (product.tags.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _SectionTitle('Tag Produk'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: product.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lavenderSoft,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.lavender),
                            ),
                            child: Text(
                              '#$tag',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],

                if (infoItems.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  const _SectionTitle('Informasi Tambahan'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: AppDecor.card(radius: 22),
                    child: Column(
                      children: [
                        for (var i = 0; i < infoItems.length; i++) ...[
                          if (i > 0) const Divider(indent: 64),
                          _infoRow(infoItems[i], i),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 26),
                _SectionTitle('Ulasan (${product.reviews.length})'),
                const SizedBox(height: 12),

                if (product.reviews.isEmpty)
                  const Text(
                    'Belum ada ulasan untuk produk ini.',
                    style: TextStyle(color: AppColors.inkSoft),
                  )
                else
                  ...product.reviews.map(_reviewCard),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gallery(BuildContext context, List<String> images, Color tint) {
    final topInset = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: tint),
        Padding(
          padding: EdgeInsets.only(top: topInset, bottom: 52),
          child: images.isEmpty
              ? const Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    size: 56,
                    color: AppColors.accent,
                  ),
                )
              : PageView.builder(
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _imageIndex = i),
                  itemBuilder: (context, index) => CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
        ),
        // Sudut atas melengkung untuk konten di bawah galeri.
        Positioned(
          left: 0,
          right: 0,
          bottom: -1,
          height: 28,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),
        if (images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < images.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _imageIndex ? 20 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == _imageIndex
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _infoRow(_InfoItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.tints[index % AppColors.tints.length],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 19, color: AppColors.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(Review review) {
    final name = review.reviewerName.isEmpty ? 'Pengguna' : review.reviewerName;
    final date = review.date.length >= 10
        ? review.date.substring(0, 10)
        : review.date;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.lavender,
                child: Text(
                  name.characters.first.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _Stars(rating: review.rating.toDouble(), size: 14),
                        if (date.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// KOMPONEN KECIL
// ============================================================

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem(this.icon, this.label, this.value);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.pinkDeep,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    this.icon,
  });

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.ink),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = rating - i;
        final icon = value >= 0.75
            ? Icons.star_rounded
            : value >= 0.25
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return Icon(icon, size: size, color: AppColors.star);
      }),
    );
  }
}