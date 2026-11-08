import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _brand;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _desc;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _title = TextEditingController(text: p.title);
    _brand = TextEditingController(text: p.brand);
    _category = TextEditingController(text: p.category);
    _price = TextEditingController(text: p.price.toString());
    _stock = TextEditingController(text: p.stock.toString());
    _desc = TextEditingController(text: p.description);
  }

  @override
  void dispose() {
    for (final c in [_title, _brand, _category, _price, _stock, _desc]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save({required bool partial}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final prov = context.read<ProductProvider>();

    final price = double.parse(_price.text.replaceAll(',', '.'));
    final stock = int.parse(_stock.text);
    final p = widget.product;

    final Product updated;
    final bool ok;
    if (partial) {
      // PATCH: hanya kirim price & stock
      updated = p.copyWith(price: price, stock: stock);
      ok = await prov.patchProduct(p.id, {'price': price, 'stock': stock});
    } else {
      // PUT: kirim data lengkap (toJson)
      updated = p.copyWith(
        title: _title.text.trim(),
        brand: _brand.text.trim(),
        category: _category.text.trim(),
        price: price,
        stock: stock,
        description: _desc.text.trim(),
      );
      ok = await prov.updateProduct(p.id, updated);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    messenger.showSnackBar(SnackBar(
        content: Text(ok
            ? 'Berhasil ${partial ? 'PATCH' : 'PUT'} (mock, data server tidak berubah)'
            : 'Gagal menyimpan: ${prov.error}')));
    if (ok) router.pop(updated); // kirim hasil ke halaman detail
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    return Scaffold(
      appBar: AppBar(title: Text('Edit Produk #${p.id}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Ringkasan produk yang sedang diedit.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.pink, AppColors.lavender],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: p.thumbnail.isEmpty
                        ? const Icon(
                            Icons.image_not_supported_outlined,
                            color: AppColors.inkSoft,
                          )
                        : Padding(
                            padding: const EdgeInsets.all(6),
                            child: CachedNetworkImage(
                              imageUrl: p.thumbnail,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID #${p.id} • ${p.category}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            SectionCard(
              title: 'Informasi produk',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  TextFormField(
                    controller: _title,
                    textInputAction: TextInputAction.next,
                    decoration: pastelField(
                      label: 'Title',
                      icon: Icons.shopping_bag_outlined,
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _brand,
                    textInputAction: TextInputAction.next,
                    decoration: pastelField(
                      label: 'Brand',
                      icon: Icons.sell_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _category,
                    textInputAction: TextInputAction.next,
                    decoration: pastelField(
                      label: 'Category',
                      icon: Icons.category_outlined,
                    ),
                    validator: _required,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SectionCard(
              title: 'Harga & stok',
              icon: Icons.payments_outlined,
              tint: AppColors.mint,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: pastelField(
                        label: 'Price',
                        prefixText: '\$ ',
                      ),
                      validator: (v) =>
                          double.tryParse((v ?? '').replaceAll(',', '.')) ==
                                  null
                              ? 'Masukkan angka'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: pastelField(label: 'Stock'),
                      validator: (v) => int.tryParse(v ?? '') == null
                          ? 'Masukkan angka'
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            SectionCard(
              title: 'Deskripsi',
              icon: Icons.notes_rounded,
              tint: AppColors.lavender,
              child: TextFormField(
                controller: _desc,
                maxLines: 4,
                decoration: pastelField(label: 'Description'),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _saving ? null : () => _save(partial: false),
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan (PUT - full)'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : () => _save(partial: true),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Simpan sebagian (PATCH: price & stock)'),
            ),
          ],
        ),
      ),
    );
  }
}