
const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
app.use(express.json({ limit: '2mb' }));

// Koneksi MySQL melalui Docker
const db = mysql.createPool({
  host: process.env.MYSQLHOST || 'mysql',
  port: Number(process.env.MYSQLPORT || 3306),
  user: process.env.MYSQLUSER,
  password: process.env.MYSQLPASSWORD,
  database: process.env.MYSQLDATABASE || 'pastel_shop',
  waitForConnections: true,
  connectionLimit: 10,
});

// Semua kolom produk DummyJSON
const FIELDS = `
  id, title, description, category, price,
  brand, stock, thumbnail, rating,
  discount_percentage AS discountPercentage,
  tags, sku, weight, dimensions,
  warranty_information AS warrantyInformation,
  shipping_information AS shippingInformation,
  availability_status AS availabilityStatus,
  reviews,
  return_policy AS returnPolicy,
  minimum_order_quantity AS minimumOrderQuantity,
  meta, images
`;

const columns = {
  title: 'title',
  description: 'description',
  category: 'category',
  price: 'price',
  brand: 'brand',
  stock: 'stock',
  thumbnail: 'thumbnail',
  rating: 'rating',
  discountPercentage: 'discount_percentage',
  tags: 'tags',
  sku: 'sku',
  weight: 'weight',
  dimensions: 'dimensions',
  warrantyInformation: 'warranty_information',
  shippingInformation: 'shipping_information',
  availabilityStatus: 'availability_status',
  reviews: 'reviews',
  returnPolicy: 'return_policy',
  minimumOrderQuantity: 'minimum_order_quantity',
  meta: 'meta',
  images: 'images',
};

const textFields = new Set([
  'title', 'description', 'category', 'brand',
  'thumbnail', 'sku', 'warrantyInformation',
  'shippingInformation', 'availabilityStatus',
  'returnPolicy',
]);

const integerFields = new Set([
  'stock', 'weight', 'minimumOrderQuantity',
]);

const numberFields = new Set([
  'price', 'rating', 'discountPercentage',
]);

const jsonFields = new Set([
  'tags', 'dimensions', 'reviews', 'meta', 'images',
]);

function parseJson(value, fallback) {
  if (value == null) return fallback;

  if (Buffer.isBuffer(value)) {
    value = value.toString('utf8');
  }

  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch (_) {
      return fallback;
    }
  }

  return value;
}

// Ubah data MySQL menjadi format DummyJSON
function formatProduct(row) {
  const tags = parseJson(row.tags, []);
  const reviews = parseJson(row.reviews, []);
  const images = parseJson(row.images, []);
  const dimensions = parseJson(row.dimensions, {});
  const meta = parseJson(row.meta, {});

  return {
    id: Number(row.id),
    title: row.title ?? '',
    description: row.description ?? '',
    category: row.category ?? '',
    price: Number(row.price ?? 0),
    brand: row.brand ?? '',
    stock: Number(row.stock ?? 0),
    thumbnail: row.thumbnail ?? '',

    rating: Number(row.rating ?? 0),
    discountPercentage: Number(
      row.discountPercentage ?? 0
    ),

    tags: Array.isArray(tags) ? tags : [],
    sku: row.sku ?? '',
    weight: Number(row.weight ?? 0),

    dimensions:
      dimensions &&
      typeof dimensions === 'object' &&
      !Array.isArray(dimensions)
        ? dimensions
        : {},

    warrantyInformation: row.warrantyInformation ?? '',
    shippingInformation: row.shippingInformation ?? '',
    availabilityStatus: row.availabilityStatus ?? '',

    reviews: Array.isArray(reviews) ? reviews : [],
    returnPolicy: row.returnPolicy ?? '',
    minimumOrderQuantity: Number(
      row.minimumOrderQuantity ?? 1
    ),

    meta:
      meta &&
      typeof meta === 'object' &&
      !Array.isArray(meta)
        ? meta
        : {},

    images: Array.isArray(images) ? images : [],
  };
}

function badRequest(message) {
  const error = new Error(message);
  error.status = 400;
  return error;
}

function getId(req) {
  const id = Number(req.params.id);

  if (!Number.isSafeInteger(id) || id < 1) {
    throw badRequest('ID produk tidak valid');
  }

  return id;
}

// Validasi data CREATE / UPDATE / PATCH
function validateProduct(body, full = false) {
  if (
    !body ||
    typeof body !== 'object' ||
    Array.isArray(body)
  ) {
    throw badRequest('Data produk tidak valid');
  }

  const data = {};

  for (const [field, column] of Object.entries(columns)) {
    if (!Object.prototype.hasOwnProperty.call(body, field)) {
      continue;
    }

    const value = body[field];

    if (textFields.has(field)) {
      if (typeof value !== 'string') {
        throw badRequest(`${field} harus berupa teks`);
      }

      data[column] = value.trim();

      if (field === 'title' && !data[column]) {
        throw badRequest('Nama produk wajib diisi');
      }

      continue;
    }

    if (integerFields.has(field)) {
      const min =
        field === 'minimumOrderQuantity' ? 1 : 0;

      if (!Number.isSafeInteger(value) || value < min) {
        throw badRequest(`${field} tidak valid`);
      }

      data[column] = value;
      continue;
    }

    if (numberFields.has(field)) {
      if (
        typeof value !== 'number' ||
        !Number.isFinite(value) ||
        value < 0
      ) {
        throw badRequest(`${field} tidak valid`);
      }

      if (field === 'rating' && value > 5) {
        throw badRequest('Rating harus antara 0 dan 5');
      }

      if (field === 'discountPercentage' && value > 100) {
        throw badRequest('Diskon harus antara 0 dan 100');
      }

      data[column] = value;
      continue;
    }

    if (jsonFields.has(field)) {
      if (
        ['tags', 'reviews', 'images'].includes(field)
      ) {
        if (!Array.isArray(value)) {
          throw badRequest(`${field} harus berupa array`);
        }
      } else if (
        value === null ||
        typeof value !== 'object' ||
        Array.isArray(value)
      ) {
        throw badRequest(`${field} harus berupa objek`);
      }

      data[column] = JSON.stringify(value);
    }
  }

  if (
    full &&
    (!data.title || data.price === undefined)
  ) {
    throw badRequest('Nama dan harga wajib diisi');
  }

  if (Object.keys(data).length === 0) {
    throw badRequest('Tidak ada data untuk disimpan');
  }

  return data;
}

function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

async function findProduct(id, connection = db) {
  const [rows] = await connection.execute(
    `SELECT ${FIELDS} FROM products WHERE id = ?`,
    [id]
  );

  return rows.length ? formatProduct(rows[0]) : null;
}

// Pagination, sorting dan filtering
async function listProducts(req, res, where = '', params = []) {
  const rawLimit = Number(req.query.limit);
  const rawSkip = Number(req.query.skip);

  const limit =
    Number.isFinite(rawLimit) && rawLimit > 0
      ? Math.min(Math.floor(rawLimit), 100)
      : 30;

  const skip =
    Number.isFinite(rawSkip) && rawSkip >= 0
      ? Math.floor(rawSkip)
      : 0;

  const sortOptions = [
    'id', 'title', 'price', 'rating', 'stock',
  ];

  const sortBy = sortOptions.includes(req.query.sortBy)
    ? req.query.sortBy
    : 'id';

  const order =
    String(req.query.order).toLowerCase() === 'desc'
      ? 'DESC'
      : 'ASC';

  const [counts] = await db.execute(
    `SELECT COUNT(*) AS total FROM products ${where}`,
    params
  );

  const [rows] = await db.execute(
    `SELECT ${FIELDS}
     FROM products ${where}
     ORDER BY ${sortBy} ${order}, id ASC
     LIMIT ? OFFSET ?`,
    [...params, limit, skip]
  );

  res.json({
    products: rows.map(formatProduct),
    total: Number(counts[0].total),
    skip,
    limit,
  });
}

// ================= HEALTH =================

app.get('/health', asyncHandler(async (req, res) => {
  await db.query('SELECT 1');

  res.json({
    status: 'ok',
    app: 'Pastel.Shop Backend',
    database: 'connected',
    engine: 'mysql',
  });
}));

// ================= READ ALL =================

app.get('/products', asyncHandler(async (req, res) => {
  await listProducts(req, res);
}));

// ================= SEARCH =================

app.get('/products/search', asyncHandler(async (req, res) => {
  const q = String(req.query.q || '').trim();

  if (!q) {
    return listProducts(req, res);
  }

  await listProducts(
    req,
    res,
    'WHERE title LIKE ? OR description LIKE ?',
    [`%${q}%`, `%${q}%`]
  );
}));

// ================= CATEGORIES =================

app.get('/products/categories', asyncHandler(async (req, res) => {
  const [rows] = await db.execute(
    `SELECT DISTINCT category
     FROM products
     WHERE category <> ''
     ORDER BY category`
  );

  res.json(
    rows.map(row => ({
      slug: row.category,
      name: row.category,
      url:
        `/products/category/${encodeURIComponent(row.category)}`,
    }))
  );
}));

app.get('/products/category-list', asyncHandler(async (req, res) => {
  const [rows] = await db.execute(
    `SELECT DISTINCT category
     FROM products
     WHERE category <> ''
     ORDER BY category`
  );

  res.json(rows.map(row => row.category));
}));

// ================= FILTER CATEGORY =================

app.get('/products/category/:category', asyncHandler(
  async (req, res) => {
    await listProducts(
      req,
      res,
      'WHERE category = ?',
      [req.params.category]
    );
  }
));

// ================= READ DETAIL =================

app.get('/products/:id', asyncHandler(async (req, res) => {
  const product = await findProduct(getId(req));

  if (!product) {
    return res.status(404).json({
      message: 'Produk tidak ditemukan',
    });
  }

  res.json(product);
}));

// ================= CREATE =================

async function createProduct(req, res) {
  const data = validateProduct(req.body, true);

  const keys = Object.keys(data);
  const values = Object.values(data);
  const placeholders = keys.map(() => '?').join(', ');

  const [result] = await db.execute(
    `INSERT INTO products (${keys.join(', ')})
     VALUES (${placeholders})`,
    values
  );

  const product = await findProduct(result.insertId);
  res.status(201).json(product);
}

app.post('/products/add', asyncHandler(createProduct));
app.post('/products', asyncHandler(createProduct));

// ================= PUT / PATCH =================

async function updateProduct(req, res, full) {
  const id = getId(req);
  const data = validateProduct(req.body, full);

  const existing = await findProduct(id);

  if (!existing) {
    return res.status(404).json({
      message: 'Produk tidak ditemukan',
    });
  }

  const keys = Object.keys(data);
  const values = Object.values(data);
  const setters = keys.map(key => `${key} = ?`).join(', ');

  await db.execute(
    `UPDATE products SET ${setters} WHERE id = ?`,
    [...values, id]
  );

  res.json(await findProduct(id));
}

app.put('/products/:id', asyncHandler(
  (req, res) => updateProduct(req, res, true)
));

app.patch('/products/:id', asyncHandler(
  (req, res) => updateProduct(req, res, false)
));

// ================= DELETE =================

app.delete('/products/:id', asyncHandler(async (req, res) => {
  const id = getId(req);
  const connection = await db.getConnection();

  try {
    await connection.beginTransaction();

    const [rows] = await connection.execute(
      `SELECT ${FIELDS}
       FROM products WHERE id = ? FOR UPDATE`,
      [id]
    );

    if (rows.length === 0) {
      await connection.rollback();

      return res.status(404).json({
        message: 'Produk tidak ditemukan',
      });
    }

    await connection.execute(
      'DELETE FROM products WHERE id = ?',
      [id]
    );

    await connection.commit();

    res.json({
      ...formatProduct(rows[0]),
      isDeleted: true,
      deletedOn: new Date().toISOString(),
    });
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}));

// ================= ERROR HANDLER =================

app.use((err, req, res, next) => {
  console.error(err);

  res.status(err.status || 500).json({
    message: err.status
      ? err.message
      : 'Terjadi kesalahan pada server',
  });
});

// ================= SERVER =================

const PORT = Number(process.env.PORT || 3000);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Pastel.Shop MySQL API berjalan di port ${PORT}`);
});
