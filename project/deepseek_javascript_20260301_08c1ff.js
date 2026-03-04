const express = require('express');
const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();

const app = express();
app.use(express.json({ limit: '2mb' }));

const PORT = process.env.PORT || 3000;
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'app.db');

function initDb() {
  const db = new sqlite3.Database(DB_PATH);
  db.serialize(() => {
    db.run(
      `CREATE TABLE IF NOT EXISTS customers (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        email TEXT,
        type TEXT,
        address TEXT,
        notes TEXT
      )`
    );
    db.run(
      `CREATE TABLE IF NOT EXISTS records (
        id TEXT PRIMARY KEY,
        customerId TEXT,
        date TEXT,
        serviceType TEXT,
        quantity INTEGER,
        unitPrice REAL,
        amount REAL,
        paid INTEGER,
        invoiceIssued INTEGER,
        createdAt TEXT
      )`
    );
    db.run(
      `CREATE TABLE IF NOT EXISTS service_types (
        name TEXT PRIMARY KEY,
        price REAL
      )`
    );
    db.run(
      `CREATE TABLE IF NOT EXISTS recharge_records (
        id TEXT PRIMARY KEY,
        customerId TEXT,
        type TEXT,
        amount REAL,
        date TEXT,
        serviceType TEXT,
        quantity INTEGER,
        unitPrice REAL,
        notes TEXT,
        createdAt TEXT
      )`
    );
    db.get('SELECT COUNT(1) as cnt FROM service_types', [], (err, row) => {
      if (!err && row && row.cnt === 0) {
        const defaults = [
          ['正面一张', 30],
          ['正反面各一张', 50],
          ['正反面加细节', 60],
          ['3D正面一张', 60],
          ['3D正反面加细节', 100],
          ['3D正反各一张', 80]
        ];
        const stmt = db.prepare('INSERT INTO service_types (name, price) VALUES (?, ?)');
        defaults.forEach(d => stmt.run(d[0], d[1]));
        stmt.finalize();
      }
    });
  });
  return db;
}

app.get('/api/data', (req, res) => {
  const db = initDb();
  db.serialize(() => {
    db.all('SELECT * FROM customers', [], (errC, customers = []) => {
      if (errC) {
        db.close();
        return res.status(500).json({ error: 'read_customers_failed' });
      }
      db.all('SELECT * FROM records', [], (errR, records = []) => {
        if (errR) {
          db.close();
          return res.status(500).json({ error: 'read_records_failed' });
        }
        db.all('SELECT * FROM service_types', [], (errS, serviceTypes = []) => {
          if (errS) {
            db.close();
            return res.status(500).json({ error: 'read_service_types_failed' });
          }
          db.all('SELECT * FROM recharge_records', [], (errRR, rechargeRecords = []) => {
            db.close();
            if (errRR) {
              return res.status(500).json({ error: 'read_recharge_records_failed' });
            }
            const normalizedRecords = records.map(r => ({
              ...r,
              paid: !!r.paid,
              invoiceIssued: !!r.invoiceIssued,
            }));
            res.json({
              customers,
              records: normalizedRecords,
              serviceTypes,
              rechargeRecords,
              timestamp: new Date().toISOString()
            });
          });
        });
      });
    });
  });
});

app.post('/api/data', (req, res) => {
  const payload = req.body || {};
  const customers = Array.isArray(payload.customers) ? payload.customers : [];
  const records = Array.isArray(payload.records) ? payload.records : [];
  const serviceTypes = Array.isArray(payload.serviceTypes) ? payload.serviceTypes : [];
  const rechargeRecords = Array.isArray(payload.rechargeRecords) ? payload.rechargeRecords : [];

  const db = initDb();
  db.serialize(() => {
    db.run('BEGIN');
    db.run('DELETE FROM customers');
    db.run('DELETE FROM records');
    db.run('DELETE FROM service_types');
    db.run('DELETE FROM recharge_records');

    const insertCustomer = db.prepare(
      'INSERT INTO customers (id, name, phone, email, type, address, notes) VALUES (?, ?, ?, ?, ?, ?, ?)'
    );
    customers.forEach(c => {
      insertCustomer.run(
        c.id,
        c.name || null,
        c.phone || null,
        c.email || null,
        c.type || null,
        c.address || null,
        c.notes || null
      );
    });
    insertCustomer.finalize();

    const insertRecord = db.prepare(
      'INSERT INTO records (id, customerId, date, serviceType, quantity, unitPrice, amount, paid, invoiceIssued, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );
    records.forEach(r => {
      insertRecord.run(
        r.id,
        r.customerId || null,
        r.date || null,
        r.serviceType || null,
        Number.isFinite(r.quantity) ? r.quantity : null,
        Number.isFinite(r.unitPrice) ? r.unitPrice : null,
        Number.isFinite(r.amount) ? r.amount : null,
        r.paid ? 1 : 0,
        r.invoiceIssued ? 1 : 0,
        r.createdAt || null
      );
    });
    insertRecord.finalize();

    const insertServiceType = db.prepare(
      'INSERT INTO service_types (name, price) VALUES (?, ?)'
    );
    serviceTypes.forEach(s => {
      insertServiceType.run(s.name, Number.isFinite(s.price) ? s.price : null);
    });
    insertServiceType.finalize();

    const insertRecharge = db.prepare(
      'INSERT INTO recharge_records (id, customerId, type, amount, date, serviceType, quantity, unitPrice, notes, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    );
    rechargeRecords.forEach(rr => {
      insertRecharge.run(
        rr.id,
        rr.customerId || null,
        rr.type || null,
        Number.isFinite(rr.amount) ? rr.amount : null,
        rr.date || null,
        rr.serviceType || null,
        Number.isFinite(rr.quantity) ? rr.quantity : null,
        Number.isFinite(rr.unitPrice) ? rr.unitPrice : null,
        rr.notes || null,
        rr.createdAt || null
      );
    });
    insertRecharge.finalize();

    db.run('COMMIT', err => {
      db.close();
      if (err) return res.status(500).json({ error: 'write_failed' });
      res.json({ ok: true, timestamp: new Date().toISOString() });
    });
  });
});

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

app.listen(PORT, () => {
  console.log(`server on ${PORT} using sqlite storage`);
});

// Customers CRUD
app.get('/api/customers', (req, res) => {
  const db = initDb();
  db.all('SELECT * FROM customers', [], (err, rows = []) => {
    db.close();
    if (err) return res.status(500).json({ error: 'read_customers_failed' });
    res.json(rows);
  });
});

app.post('/api/customers', (req, res) => {
  const c = req.body || {};
  const db = initDb();
  const stmt = db.prepare('INSERT INTO customers (id, name, phone, email, type, address, notes) VALUES (?, ?, ?, ?, ?, ?, ?)');
  stmt.run(c.id, c.name || null, c.phone || null, c.email || null, c.type || null, c.address || null, c.notes || null, err => {
    stmt.finalize();
    db.close();
    if (err) return res.status(500).json({ error: 'create_customer_failed' });
    res.json({ ok: true });
  });
});

app.put('/api/customers/:id', (req, res) => {
  const id = req.params.id;
  const c = req.body || {};
  const db = initDb();
  const stmt = db.prepare('UPDATE customers SET name = ?, phone = ?, email = ?, type = ?, address = ?, notes = ? WHERE id = ?');
  stmt.run(c.name || null, c.phone || null, c.email || null, c.type || null, c.address || null, c.notes || null, id, err => {
    stmt.finalize();
    db.close();
    if (err) return res.status(500).json({ error: 'update_customer_failed' });
    res.json({ ok: true });
  });
});

app.delete('/api/customers/:id', (req, res) => {
  const id = req.params.id;
  const db = initDb();
  db.serialize(() => {
    db.run('BEGIN');
    db.run('DELETE FROM customers WHERE id = ?', [id]);
    db.run('DELETE FROM records WHERE customerId = ?', [id]);
    db.run('DELETE FROM recharge_records WHERE customerId = ?', [id]);
    db.run('COMMIT', err => {
      db.close();
      if (err) return res.status(500).json({ error: 'delete_customer_failed' });
      res.json({ ok: true });
    });
  });
});

// Business records CRUD
app.get('/api/records', (req, res) => {
  const db = initDb();
  db.all('SELECT * FROM records', [], (err, rows = []) => {
    db.close();
    if (err) return res.status(500).json({ error: 'read_records_failed' });
    const normalized = rows.map(r => ({ ...r, paid: !!r.paid, invoiceIssued: !!r.invoiceIssued }));
    res.json(normalized);
  });
});

app.post('/api/records', (req, res) => {
  const r = req.body || {};
  const db = initDb();
  const stmt = db.prepare('INSERT INTO records (id, customerId, date, serviceType, quantity, unitPrice, amount, paid, invoiceIssued, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  stmt.run(
    r.id,
    r.customerId || null,
    r.date || null,
    r.serviceType || null,
    Number.isFinite(r.quantity) ? r.quantity : null,
    Number.isFinite(r.unitPrice) ? r.unitPrice : null,
    Number.isFinite(r.amount) ? r.amount : null,
    r.paid ? 1 : 0,
    r.invoiceIssued ? 1 : 0,
    r.createdAt || null,
    err => {
      stmt.finalize();
      db.close();
      if (err) return res.status(500).json({ error: 'create_record_failed' });
      res.json({ ok: true });
    }
  );
});

app.post('/api/records/bulk', (req, res) => {
  const list = Array.isArray(req.body) ? req.body : [];
  const db = initDb();
  db.serialize(() => {
    db.run('BEGIN');
    const stmt = db.prepare('INSERT INTO records (id, customerId, date, serviceType, quantity, unitPrice, amount, paid, invoiceIssued, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    list.forEach(r => {
      stmt.run(
        r.id,
        r.customerId || null,
        r.date || null,
        r.serviceType || null,
        Number.isFinite(r.quantity) ? r.quantity : null,
        Number.isFinite(r.unitPrice) ? r.unitPrice : null,
        Number.isFinite(r.amount) ? r.amount : null,
        r.paid ? 1 : 0,
        r.invoiceIssued ? 1 : 0,
        r.createdAt || null
      );
    });
    stmt.finalize();
    db.run('COMMIT', err => {
      db.close();
      if (err) return res.status(500).json({ error: 'bulk_create_records_failed' });
      res.json({ ok: true, count: list.length });
    });
  });
});

app.put('/api/records/:id', (req, res) => {
  const id = req.params.id;
  const r = req.body || {};
  const db = initDb();
  const stmt = db.prepare('UPDATE records SET customerId = ?, date = ?, serviceType = ?, quantity = ?, unitPrice = ?, amount = ?, paid = ?, invoiceIssued = ?, createdAt = ? WHERE id = ?');
  stmt.run(
    r.customerId || null,
    r.date || null,
    r.serviceType || null,
    Number.isFinite(r.quantity) ? r.quantity : null,
    Number.isFinite(r.unitPrice) ? r.unitPrice : null,
    Number.isFinite(r.amount) ? r.amount : null,
    r.paid ? 1 : 0,
    r.invoiceIssued ? 1 : 0,
    r.createdAt || null,
    id,
    err => {
      stmt.finalize();
      db.close();
      if (err) return res.status(500).json({ error: 'update_record_failed' });
      res.json({ ok: true });
    }
  );
});

app.delete('/api/records/:id', (req, res) => {
  const id = req.params.id;
  const db = initDb();
  db.run('DELETE FROM records WHERE id = ?', [id], err => {
    db.close();
    if (err) return res.status(500).json({ error: 'delete_record_failed' });
    res.json({ ok: true });
  });
});

// Service types CRUD (使用下划线，与前端一致)
app.get('/api/service_types', (req, res) => {
  const db = initDb();
  db.all('SELECT * FROM service_types', [], (err, rows = []) => {
    db.close();
    if (err) return res.status(500).json({ error: 'read_service_types_failed' });
    res.json(rows);
  });
});

app.post('/api/service_types', (req, res) => {
  const s = req.body || {};
  const db = initDb();
  const stmt = db.prepare('INSERT INTO service_types (name, price) VALUES (?, ?)');
  stmt.run(s.name, Number.isFinite(s.price) ? s.price : null, err => {
    stmt.finalize();
    db.close();
    if (err) return res.status(500).json({ error: 'create_service_type_failed' });
    res.json({ ok: true });
  });
});

app.delete('/api/service_types/:name', (req, res) => {
  const name = req.params.name;
  const db = initDb();
  db.run('DELETE FROM service_types WHERE name = ?', [name], err => {
    db.close();
    if (err) return res.status(500).json({ error: 'delete_service_type_failed' });
    res.json({ ok: true });
  });
});

// Recharge records CRUD (统一为 recharge_records)
app.get('/api/recharge_records', (req, res) => {
  const db = initDb();
  const customerId = req.query.customerId;
  const sql = customerId ? 'SELECT * FROM recharge_records WHERE customerId = ?' : 'SELECT * FROM recharge_records';
  const params = customerId ? [customerId] : [];
  db.all(sql, params, (err, rows = []) => {
    db.close();
    if (err) return res.status(500).json({ error: 'read_recharges_failed' });
    res.json(rows);
  });
});

app.post('/api/recharge_records', (req, res) => {
  const rr = req.body || {};
  const db = initDb();
  const stmt = db.prepare('INSERT INTO recharge_records (id, customerId, type, amount, date, serviceType, quantity, unitPrice, notes, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
  stmt.run(
    rr.id,
    rr.customerId || null,
    rr.type || null,
    Number.isFinite(rr.amount) ? rr.amount : null,
    rr.date || null,
    rr.serviceType || null,
    Number.isFinite(rr.quantity) ? rr.quantity : null,
    Number.isFinite(rr.unitPrice) ? rr.unitPrice : null,
    rr.notes || null,
    rr.createdAt || null,
    err => {
      stmt.finalize();
      db.close();
      if (err) return res.status(500).json({ error: 'create_recharge_failed' });
      res.json({ ok: true });
    }
  );
});

app.post('/api/recharge_records/bulk', (req, res) => {
  const list = Array.isArray(req.body) ? req.body : [];
  const db = initDb();
  db.serialize(() => {
    db.run('BEGIN');
    const stmt = db.prepare('INSERT INTO recharge_records (id, customerId, type, amount, date, serviceType, quantity, unitPrice, notes, createdAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
    list.forEach(rr => {
      stmt.run(
        rr.id,
        rr.customerId || null,
        rr.type || null,
        Number.isFinite(rr.amount) ? rr.amount : null,
        rr.date || null,
        rr.serviceType || null,
        Number.isFinite(rr.quantity) ? rr.quantity : null,
        Number.isFinite(rr.unitPrice) ? rr.unitPrice : null,
        rr.notes || null,
        rr.createdAt || null
      );
    });
    stmt.finalize();
    db.run('COMMIT', err => {
      db.close();
      if (err) return res.status(500).json({ error: 'bulk_create_recharges_failed' });
      res.json({ ok: true, count: list.length });
    });
  });
});

app.put('/api/recharge_records/:id', (req, res) => {
  const id = req.params.id;
  const rr = req.body || {};
  const db = initDb();
  const stmt = db.prepare('UPDATE recharge_records SET customerId = ?, type = ?, amount = ?, date = ?, serviceType = ?, quantity = ?, unitPrice = ?, notes = ?, createdAt = ? WHERE id = ?');
  stmt.run(
    rr.customerId || null,
    rr.type || null,
    Number.isFinite(rr.amount) ? rr.amount : null,
    rr.date || null,
    rr.serviceType || null,
    Number.isFinite(rr.quantity) ? rr.quantity : null,
    Number.isFinite(rr.unitPrice) ? rr.unitPrice : null,
    rr.notes || null,
    rr.createdAt || null,
    id,
    err => {
      stmt.finalize();
      db.close();
      if (err) return res.status(500).json({ error: 'update_recharge_failed' });
      res.json({ ok: true });
    }
  );
});

app.delete('/api/recharge_records/:id', (req, res) => {
  const id = req.params.id;
  const db = initDb();
  db.run('DELETE FROM recharge_records WHERE id = ?', [id], err => {
    db.close();
    if (err) return res.status(500).json({ error: 'delete_recharge_failed' });
    res.json({ ok: true });
  });
});