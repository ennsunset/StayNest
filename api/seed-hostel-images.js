#!/usr/bin/env node

/**
 * seed-hostel-images.js
 *
 * Usage:
 *   1. Create a folder with 15-20 hostel/dorm photos (JPEG/PNG/WebP, <5MB each)
 *   2. node seed-hostel-images.js ./path/to/photos
 *
 * What it does:
 *   - Logs in as super-owner (super@staynest.com)
 *   - Fetches all hostels with empty image_urls
 *   - For each hostel, picks 3-5 random images from the folder
 *   - Uploads each via POST /media/upload (Sharp generates sm/md/lg WebP)
 *   - Updates hostel image_urls in Postgres
 *
 * Requirements: Node 18+, API running at localhost:3000
 */

const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const API = 'https://staynest-bvyf.onrender.com/api/v1';
const SUPER_EMAIL = 'super@staynest.com';
const SUPER_PASS = 'Super1234!';

const pool = new Pool({
  host: 'ep-floral-rain-b26mx9gu-pooler.c-6.eu-central-1.aws.neon.tech',
  port: 5432,
  user: 'neondb_owner',
  password: 'npg_hVwjk0B9EcQy',
  database: 'neondb', ssl: { rejectUnauthorized: false },
});

async function login() {
  const res = await fetch(`${API}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: SUPER_EMAIL, password: SUPER_PASS }),
  });
  if (!res.ok) throw new Error(`Login failed: ${res.status}`);
  const data = await res.json();
  return data.tokens?.accessToken || data.accessToken;
}

async function uploadImage(filePath, token) {
  const FormData = require('form-data');
  const form = new FormData();
  form.append('file', fs.createReadStream(filePath));

  const http = require('https');
  return new Promise((resolve, reject) => {
    const url = new URL(`${API}/media/upload?folder=hostels`);
    const req = http.request({
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: 'POST',
      headers: {
        ...form.getHeaders(),
        Authorization: `Bearer ${token}`,
      },
    }, (res) => {
      let body = '';
      res.on('data', (c) => body += c);
      res.on('end', () => {
        if (res.statusCode >= 400) return reject(new Error(`Upload ${res.statusCode}: ${body}`));
        try {
          const data = JSON.parse(body);
          resolve(data.url || data.key);
        } catch (e) { reject(new Error(`Parse error: ${body}`)); }
      });
    });
    req.on('error', reject);
    form.pipe(req);
  });
}

function shuffle(arr) {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

async function main() {
  const photosDir = process.argv[2];
  if (!photosDir) {
    console.error('Usage: node seed-hostel-images.js ./path/to/photos');
    process.exit(1);
  }

  const absDir = path.resolve(photosDir);
  if (!fs.existsSync(absDir)) {
    console.error(`Directory not found: ${absDir}`);
    process.exit(1);
  }

  const validExts = ['.jpg', '.jpeg', '.png', '.webp'];
  const allImages = fs.readdirSync(absDir)
    .filter(f => validExts.includes(path.extname(f).toLowerCase()))
    .map(f => path.join(absDir, f));

  if (allImages.length < 3) {
    console.error(`Need at least 3 images, found ${allImages.length}`);
    process.exit(1);
  }

  console.log(`Found ${allImages.length} images in ${absDir}`);

  // Login
  console.log('Logging in as super-owner...');
  const token = await login();
  console.log('Logged in.');

  // Get hostels with no images
  const { rows: hostels } = await pool.query(
    `SELECT id, name FROM hostels WHERE deleted_at IS NULL AND (image_urls IS NULL OR array_length(image_urls, 1) IS NULL OR array_length(image_urls, 1) = 0) ORDER BY name`
  );

  if (hostels.length === 0) {
    console.log('All hostels already have images. Nothing to do.');
    process.exit(0);
  }

  console.log(`${hostels.length} hostels need images.\n`);

  let successCount = 0;
  let failCount = 0;

  for (const hostel of hostels) {
    const numImages = 3 + Math.floor(Math.random() * 3); // 3-5 images per hostel
    const picked = shuffle(allImages).slice(0, Math.min(numImages, allImages.length));

    console.log(`[${hostel.name}] Uploading ${picked.length} images...`);

    const urls = [];
    for (const imgPath of picked) {
      try {
        const url = await uploadImage(imgPath, token);
        urls.push(url);
        process.stdout.write('.');
      } catch (err) {
        console.error(`\n  Failed: ${err.message}`);
      }
    }
    console.log('');

    if (urls.length > 0) {
      await pool.query(
        `UPDATE hostels SET image_urls = $1 WHERE id = $2`,
        [urls, hostel.id]
      );
      console.log(`  Saved ${urls.length} images.\n`);
      successCount++;
    } else {
      console.log(`  No images uploaded.\n`);
      failCount++;
    }
  }

  console.log(`\nDone. ${successCount} hostels updated, ${failCount} failed.`);
  await pool.end();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
