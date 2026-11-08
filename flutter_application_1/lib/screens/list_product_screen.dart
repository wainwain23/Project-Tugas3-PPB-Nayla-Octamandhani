import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class ListProductScreen extends StatefulWidget {
  const ListProductScreen({super.key});

  @override
  State<ListProductScreen> createState() => _ListProductScreenState();
}

class _ListProductScreenState extends State<ListProductScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // Tinggi area search + kategori yang menempel di bawah AppBar.
  static const double _bottomHeight = 112;

  static const Map<String, List<String>> _sortOptions = {
    'default': ['Bawaan', '', 'asc'],
    'price_asc': ['Harga termurah', 'price', 'asc'],
    'price_desc': ['Harga termahal', 'price', 'desc'],
    'title_asc': ['Nama A-Z', 'title', 'asc'],
    'title_desc': ['Nama Z-A', 'title', 'desc'],
    'rating_desc': ['Rating tertinggi', 'rating', 'desc'],
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // Pencarian melalui GET /products/search?q=...
  void _submitSearch() {
    FocusScope.of(context).unfocus();
    context.read<ProductProvider>().searchProducts(_searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add'),
        tooltip: 'Tambah produk',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah'),
      ),
      bottomNavigationBar: _PaginationBar(
        page: provider.page,
        totalPages: provider.totalPages,
        enabledPrev: provider.hasPrev && !provider.loading,
        enabledNext: provider.hasNext && !provider.loading,
        onPrev: () async {
          await context.read<ProductProvider>().prevPage();
          _toTop();
        },
        onNext: () async {
          await context.read<ProductProvider>().nextPage();
          _toTop();
        },
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            toolbarHeight: 68,
            titleSpacing: 20,
            backgroundColor: AppColors.background,
            title: _brandHeader(),
            actions: [
              _sortMenu(),
              const SizedBox(width: 16),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(_bottomHeight),
              child: SizedBox(
                height: _bottomHeight,
                child: Column(
                  children: [
                    _searchBar(),
                    _categoryBar(provider),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _infoRow(provider)),
          _buildProducts(provider),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------

  Widget _brandHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.pink, AppColors.lavender],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.local_mall_rounded,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 12),
        const Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pastel.Shop',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Temukan produk favoritmu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sortMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Urutkan produk',
      offset: const Offset(0, 48),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onSelected: (key) {
        final option = _sortOptions[key]!;
        context.read<ProductProvider>().sortProducts(option[1], option[2]);
      },
      itemBuilder: (context) {
        return _sortOptions.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Text(entry.value[0]),
          );
        }).toList();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: const Icon(Icons.sort_rounded, color: AppColors.ink),
      ),
    );
  }

  // ----------------------------------------------------------
  // SEARCH
  // ----------------------------------------------------------

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        height: 52,
        decoration: AppDecor.card(radius: 18),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: AppColors.pinkDeep),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitSearch(),
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Cari produk...',
                  hintStyle: TextStyle(color: Color(0xFFB8ADB4)),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchCtrl,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  tooltip: 'Hapus pencarian',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.inkSoft,
                  ),
                  onPressed: () {
                    _searchCtrl.clear();
                    context.read<ProductProvider>().searchProducts('');
                  },
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: FilledButton(
                onPressed: _submitSearch,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Cari'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // KATEGORI (GET /products/categories)
  // ----------------------------------------------------------

  Widget _categoryBar(ProductProvider provider) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'Semua',
            selected: provider.selectedCategory == '',
            onTap: () => _selectCategory(''),
          ),
          ...provider.categories.map(
            (category) => _CategoryChip(
              label: category.name,
              selected: provider.selectedCategory == category.slug,
              onTap: () => _selectCategory(category.slug),
            ),
          ),
        ],
      ),
    );
  }

  void _selectCategory(String slug) {
    _searchCtrl.clear();
    context.read<ProductProvider>().filterByCategory(slug);
  }

  // ----------------------------------------------------------
  // INFO TOTAL + MODE TAMPILAN
  // ----------------------------------------------------------

  Widget _infoRow(ProductProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Total: '),
                  TextSpan(
                    text: '${provider.total}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent,
                    ),
                  ),
                  const TextSpan(text: ' produk'),
                ],
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // SELECT: mode ringkas
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.grid_view_rounded, size: 18),
                tooltip: 'Tampilan grid',
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.view_agenda_rounded, size: 18),
                tooltip: 'Mode ringkas',
              ),
            ],
            selected: {provider.compact},
            onSelectionChanged: (selection) {
              context.read<ProductProvider>().setCompact(selection.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? AppColors.pink
                    : Colors.white;
              }),
              foregroundColor: const WidgetStatePropertyAll(AppColors.ink),
              side: const WidgetStatePropertyAll(
                BorderSide(color: AppColors.line),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // DAFTAR PRODUK
  // ----------------------------------------------------------

  Widget _buildProducts(ProductProvider provider) {
    if (provider.loading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _StateMessage(
          icon: Icons.wifi_off_rounded,
          message: provider.error!,
          actionLabel: 'Coba lagi',
          onAction: () => context.read<ProductProvider>().reload(),
        ),
      );
    }

    if (provider.products.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _StateMessage(
          icon: Icons.search_off_rounded,
          message: 'Produk tidak ditemukan.',
        ),
      );
    }

    final products = provider.products;

    if (provider.compact) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        sliver: SliverList.separated(
          itemCount: products.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _ProductRow(product: products[index]),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 210,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          mainAxisExtent: 270,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) =>
            _ProductCard(product: products[index]),
      ),
    );
  }
}

// ============================================================
// KOMPONEN
// ============================================================

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.pink,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? AppColors.pinkDeep : AppColors.line,
        ),
        shape: const StadiumBorder(),
        labelStyle: TextStyle(
          fontSize: 13,
          color: AppColors.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
        onSelected: (isSelected) {
          if (!isSelected) return;
          onTap();
        },
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url, this.padding = 10});

  final String url;
  final double padding;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.inkSoft,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.tintFor(product.id);
    final hasDiscount = product.discountPercentage > 0;
    final subtitle =
        product.brand.isEmpty ? product.category : product.brand;

    return Container(
      decoration: AppDecor.card(radius: 22),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/detail/${product.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: tint.withValues(alpha: 0.55),
                      child: _ProductImage(url: product.thumbnail),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '-${product.discountPercentage.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (product.rating > 0)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppColors.star,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                product.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              '\$${product.finalPrice.toStringAsFixed(2)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          if (hasDiscount) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 1),
                                child: Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.inkSoft,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Baris ringkas untuk "Mode ringkas".
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.tintFor(product.id);

    return Container(
      decoration: AppDecor.card(radius: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/detail/${product.id}'),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 60,
                    height: 60,
                    color: tint.withValues(alpha: 0.55),
                    child: _ProductImage(url: product.thumbnail, padding: 4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '\$${product.finalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              child: Icon(icon, size: 40, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, height: 1.4),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Pagination menggunakan limit dan skip.
class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.enabledPrev,
    required this.enabledNext,
    required this.onPrev,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final bool enabledPrev;
  final bool enabledNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A9A5B6E),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PageButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Sebelumnya',
                onTap: enabledPrev ? onPrev : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lavenderSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Hal. ${page + 1} / $totalPages',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
              _PageButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Berikutnya',
                onTap: enabledNext ? onNext : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        backgroundColor: AppColors.pink,
        foregroundColor: AppColors.ink,
        disabledBackgroundColor: const Color(0xFFF1EBE8),
        disabledForegroundColor: const Color(0xFFC9BFC4),
      ),
    );
  }
}