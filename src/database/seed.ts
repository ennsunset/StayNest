// src/database/seed.ts
//
// Run: npx ts-node -r tsconfig-paths/register src/database/seed.ts
//
// Creates an owner, 4 hostels near KNUST with rooms and beds.
// All prices in pesewas (D1).

import 'dotenv/config';
import { DataSource } from 'typeorm';
import * as argon2 from 'argon2';

const ds = new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432', 10),
  username: process.env.DB_USERNAME || 'staynest',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'staynest',
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  logging: false,
});

async function seed() {
  await ds.initialize();
  const q = ds.query.bind(ds);

  console.log('Seeding...');

  // ── Owner user ────────────────────────────────────
  const ownerHash = await argon2.hash('Owner1234!', { type: argon2.argon2id });

  const [owner] = await q(
    `INSERT INTO users (full_name, email, password_hash, role)
     VALUES ($1, $2, $3, 'OWNER')
     ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
     RETURNING id`,
    ['Royal Palms Management', 'owner@royalpalms.com', ownerHash],
  );
  const ownerId = owner.id;
  console.log(`  Owner: ${ownerId}`);

  // ── Amenity IDs ───────────────────────────────────
  const amenities = await q(`SELECT id, name FROM amenities`);
  const amenityId = (name: string) => amenities.find((a: any) => a.name === name)?.id;

  // ── Hostels ───────────────────────────────────────
  const hostels = [
    {
      name: 'Royal Palms Hostel',
      address: '12 University Road, Ayeduase',
      city: 'Kumasi',
      lat: 6.6745, lng: -1.5716,
      gender: 'MIXED',
      amenities: ['WiFi', 'Backup Power', 'Security', 'Water Supply'],
      rooms: [
        { num: '101', type: '1-in-a-room', price: 550000, beds: ['Bed A'], ac: true, bath: true },
        { num: '102', type: '2-in-a-room', price: 320000, beds: ['Bed A', 'Bed B'], ac: false, bath: false },
        { num: '103', type: '2-in-a-room', price: 320000, beds: ['Bed A', 'Bed B'], ac: false, bath: false },
        { num: '104', type: '3-in-a-room', price: 250000, beds: ['Bed A', 'Bed B', 'Bed C'], ac: false, bath: false },
        { num: '201', type: '1-in-a-room', price: 550000, beds: ['Bed A'], ac: true, bath: true },
        { num: '202', type: '2-in-a-room', price: 320000, beds: ['Bed A', 'Bed B'], ac: false, bath: false },
      ],
    },
    {
      name: 'Elite Residency',
      address: '5 Bomso Lane',
      city: 'Kumasi',
      lat: 6.6801, lng: -1.5678,
      gender: 'FEMALE_ONLY',
      amenities: ['WiFi', 'Air Conditioning', 'Security', 'Laundry'],
      rooms: [
        { num: '101', type: '1-in-a-room', price: 650000, beds: ['Bed A'], ac: true, bath: true },
        { num: '102', type: '1-in-a-room', price: 650000, beds: ['Bed A'], ac: true, bath: true },
        { num: '201', type: '2-in-a-room', price: 420000, beds: ['Bed A', 'Bed B'], ac: true, bath: false },
        { num: '202', type: '2-in-a-room', price: 420000, beds: ['Bed A', 'Bed B'], ac: true, bath: false },
      ],
    },
    {
      name: 'Campus View Lodge',
      address: '8 Gate Road, Ayeduase',
      city: 'Kumasi',
      lat: 6.6720, lng: -1.5740,
      gender: 'MIXED',
      amenities: ['WiFi', 'Laundry'],
      rooms: [
        { num: '101', type: '3-in-a-room', price: 200000, beds: ['Bed A', 'Bed B', 'Bed C'], ac: false, bath: false },
        { num: '102', type: '3-in-a-room', price: 200000, beds: ['Bed A', 'Bed B', 'Bed C'], ac: false, bath: false },
        { num: '201', type: '4-in-a-room', price: 160000, beds: ['Bed A', 'Bed B', 'Bed C', 'Bed D'], ac: false, bath: false },
      ],
    },
    {
      name: 'Prestige Hall',
      address: '22 Engineering Road',
      city: 'Kumasi',
      lat: 6.6760, lng: -1.5690,
      gender: 'MALE_ONLY',
      amenities: ['WiFi', 'Backup Power', 'Security', 'Air Conditioning', 'Water Supply'],
      rooms: [
        { num: '101', type: '1-in-a-room', price: 700000, beds: ['Bed A'], ac: true, bath: true },
        { num: '102', type: '2-in-a-room', price: 450000, beds: ['Bed A', 'Bed B'], ac: true, bath: true },
        { num: '201', type: '2-in-a-room', price: 450000, beds: ['Bed A', 'Bed B'], ac: true, bath: true },
        { num: '202', type: '1-in-a-room', price: 700000, beds: ['Bed A'], ac: true, bath: true },
        { num: '301', type: '2-in-a-room', price: 450000, beds: ['Bed A', 'Bed B'], ac: true, bath: false },
      ],
    },
  ];

  for (const h of hostels) {
    // Insert hostel
    const [hostel] = await q(
      `INSERT INTO hostels (owner_id, name, description, address, city, status, verified, gender_policy, location)
       VALUES ($1, $2, $3, $4, $5, 'ACTIVE', true, $6, ST_SetSRID(ST_MakePoint($7, $8), 4326))
       ON CONFLICT DO NOTHING
       RETURNING id`,
      [
        ownerId, h.name,
        `A quality student hostel in ${h.city} with great amenities and proximity to campus.`,
        h.address, h.city, h.gender, h.lng, h.lat,
      ],
    );

    if (!hostel) {
      console.log(`  Skipping ${h.name} (already exists)`);
      continue;
    }

    const hostelId = hostel.id;
    console.log(`  Hostel: ${h.name} (${hostelId})`);

    // Link amenities
    for (const aName of h.amenities) {
      const aId = amenityId(aName);
      if (aId) {
        await q(
          `INSERT INTO hostel_amenities (hostel_id, amenity_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`,
          [hostelId, aId],
        );
      }
    }

    // Building (one per hostel for simplicity)
    const [building] = await q(
      `INSERT INTO buildings (hostel_id, name) VALUES ($1, $2) RETURNING id`,
      [hostelId, 'Main Block'],
    );

    // Floors — derive from room numbers
    const floorNums = [...new Set(h.rooms.map((r) => r.num[0]))];
    const floorMap: Record<string, string> = {};

    for (const fn of floorNums) {
      const label = fn === '0' ? 'Ground Floor' : `Floor ${fn}`;
      const [floor] = await q(
        `INSERT INTO floors (building_id, label, sort_order) VALUES ($1, $2, $3) RETURNING id`,
        [building.id, label, parseInt(fn)],
      );
      floorMap[fn] = floor.id;
    }

    // Rooms and beds
    for (const r of h.rooms) {
      const floorId = floorMap[r.num[0]];
      const [room] = await q(
        `INSERT INTO rooms (floor_id, number, type, price_pesewas, has_ac, has_private_bath)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
        [floorId, r.num, r.type, r.price, r.ac, r.bath],
      );

      for (const bedLabel of r.beds) {
        await q(
          `INSERT INTO beds (room_id, label, status) VALUES ($1, $2, 'AVAILABLE')`,
          [room.id, bedLabel],
        );
      }
    }
  }

  // Mark some beds as occupied for realism
  await q(`
    UPDATE beds SET status = 'OCCUPIED'
    WHERE id IN (
      SELECT id FROM beds WHERE status = 'AVAILABLE'
      ORDER BY random() LIMIT 8
    )
  `);

  console.log('Done! 4 hostels seeded with rooms, beds, and amenities.');
  await ds.destroy();
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
