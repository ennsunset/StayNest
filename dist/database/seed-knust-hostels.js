"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const typeorm_1 = require("typeorm");
const argon2 = require("argon2");
const ds = new typeorm_1.DataSource({
    type: 'postgres',
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '5432', 10),
    username: process.env.DB_USERNAME || 'staynest',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'staynest',
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    logging: false,
});
function randInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}
function randPrice(min, max) {
    return Math.round(randInt(min, max) / 10000) * 10000;
}
function slugify(name) {
    return name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}
const PRICING = {
    premium: { single: [450000, 550000], double: [320000, 380000], quad: [180000, 220000] },
    standard: { single: [380000, 450000], double: [250000, 320000], quad: [150000, 200000] },
    budget: { single: [300000, 380000], double: [200000, 280000], quad: [120000, 170000] },
};
const HOSTELS = [
    { name: 'Providence Hostel', address: 'Ayeduase, near KNUST', lat: 6.6721, lng: -1.5652,
        gender: 'MIXED', desc: 'Award-winning hostel with world-class facilities, 5 minutes walk from KNUST Ayeduase gate.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Laundry', 'Water Supply', 'Study Room'],
        config: 'doubles_singles', quality: 'premium' },
    { name: 'Westend Hostel', address: 'Ayeduase, near KNUST', lat: 6.6735, lng: -1.5648,
        gender: 'MIXED', desc: 'Large hostel close to Ayeduase gate. Spacious rooms and receptive management.',
        amenities: ['WiFi', 'Security', 'Water Supply', 'Study Room'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Beacon Hostel', address: 'Ayeduase, near KNUST', lat: 6.6728, lng: -1.5660,
        gender: 'MIXED', desc: 'Well-known hostel with recently renovated rooms close to KNUST campus.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Wagyingo Hostel', address: 'Ayeduase, near KNUST', lat: 6.6718, lng: -1.5645,
        gender: 'MIXED', desc: 'Fairly new hostel that has quickly become a favourite. 5 minutes from Ayeduase gate.',
        amenities: ['WiFi', 'Security', 'Water Supply', 'Study Room'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Anarosa Hostel', address: 'Ayeduase, near KNUST', lat: 6.6730, lng: -1.5655,
        gender: 'FEMALE_ONLY', desc: 'Modern hostel close to Ayeduase gate and Art faculty. Nicely tiled and well-organised.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Laundry', 'Water Supply', 'Study Room'],
        config: 'doubles_singles', quality: 'premium' },
    { name: 'Nyberg Hostel', address: 'Ayeduase, near KNUST', lat: 6.6740, lng: -1.5643,
        gender: 'MIXED', desc: 'Notable private hostel at Ayeduase. Reliable and well-established.',
        amenities: ['WiFi', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Nana Adoma Hostel', address: 'Ayeduase, near KNUST', lat: 6.6725, lng: -1.5638,
        gender: 'MIXED', desc: 'Well-known and established hostel. Affordable with good facilities.',
        amenities: ['Security', 'Water Supply'],
        config: 'doubles_quads', quality: 'budget' },
    { name: 'Crystal Rose Hostel', address: 'Ayeduase, near KNUST', lat: 6.6715, lng: -1.5670,
        gender: 'MIXED', desc: 'Peaceful environment with Wi-Fi, restaurant, laundry services, and standby generator.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Laundry', 'Water Supply', 'Study Room', 'Kitchen'],
        config: 'doubles_singles', quality: 'premium' },
    { name: 'The Best Hostel', address: 'Ayeduase, near KNUST', lat: 6.6738, lng: -1.5658,
        gender: 'MIXED', desc: 'Quality service with comfortable and spacious rooms. Affordable rates.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Rising Sun Hostel', address: 'Ayeduase, near KNUST', lat: 6.6710, lng: -1.5665,
        gender: 'MIXED', desc: 'Comfortable place with TV room and spacious rooms for students.',
        amenities: ['WiFi', 'Security', 'Water Supply', 'Study Room'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Nevada Hostel', address: 'Ayeduase New Site, near KNUST', lat: 6.6695, lng: -1.5680,
        gender: 'MIXED', desc: 'Clean and spacious rooms in a quiet, serene environment. Beautiful building.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Laundry', 'Water Supply', 'Study Room'],
        config: 'doubles_singles', quality: 'premium' },
    { name: 'Glory Be to God Hostel', address: 'Ayeduase New Site, near KNUST', lat: 6.6688, lng: -1.5675,
        gender: 'MIXED', desc: 'On the main Ayeduase road. TV room and standby generator. Convenient.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Johannes Hostel', address: 'Ayeduase New Site, near KNUST', lat: 6.6682, lng: -1.5688,
        gender: 'MALE_ONLY', desc: 'Style and comfort near the new Art faculty. TV room and table tennis.',
        amenities: ['WiFi', 'Security', 'Water Supply', 'Study Room'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Amen Hostel', address: 'Ayeduase North, near KNUST', lat: 6.6755, lng: -1.5635,
        gender: 'MIXED', desc: 'Popular hostel on the north side of Ayeduase. Well-maintained.',
        amenities: ['WiFi', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Amen INN', address: 'Ayeduase North, near KNUST', lat: 6.6758, lng: -1.5630,
        gender: 'MIXED', desc: 'Part of the Amen hostel family. 9 minutes walk to campus.',
        amenities: ['Security', 'Water Supply'],
        config: 'doubles_quads', quality: 'budget' },
    { name: 'Casa Maria Hostel', address: 'Ayeduase North, near KNUST', lat: 6.6750, lng: -1.5640,
        gender: 'FEMALE_ONLY', desc: 'About 8 minutes walk to campus. Clean environment, good management.',
        amenities: ['WiFi', 'Security', 'Water Supply', 'Study Room'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Amen Hostel Annex', address: 'Ayeduase South, near KNUST', lat: 6.6700, lng: -1.5650,
        gender: 'MIXED', desc: 'Annex to the main Amen Hostel. 9 minutes walk to campus.',
        amenities: ['WiFi', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Asabek Hostel', address: 'Ayeduase South, near KNUST', lat: 6.6692, lng: -1.5655,
        gender: 'MIXED', desc: 'South side of Ayeduase. About 11 minutes walk to campus.',
        amenities: ['Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Shepherdsville Residence', address: 'Ayeduase-Kotei Road, near KNUST', lat: 6.6705, lng: -1.5700,
        gender: 'MIXED', desc: 'High-end off-campus hostel. Known for the best service in its category.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Laundry', 'Water Supply', 'Study Room', 'Kitchen'],
        config: 'doubles_singles', quality: 'premium' },
    { name: 'White House Hostel', address: 'Bomso, near KNUST', lat: 6.6770, lng: -1.5750,
        gender: 'MIXED', desc: 'Very popular. Close to KNUST engineering gate. Well-designed, spacious rooms.',
        amenities: ['WiFi', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Ultimate Hostel', address: 'Bomso, near KNUST', lat: 6.6765, lng: -1.5760,
        gender: 'MIXED', desc: 'Formerly Evandi Hostel. Basketball court, spacious rooms near Bomso gate.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Laundry', 'Water Supply', 'Study Room'],
        config: 'doubles_singles', quality: 'premium' },
    { name: 'Standard Hostel', address: 'Bomso, near KNUST', lat: 6.6775, lng: -1.5755,
        gender: 'MIXED', desc: '24-hour water supply, balcony rooms, laundry services, daily campus shuttle.',
        amenities: ['WiFi', 'Security', 'Laundry', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Blue Ark Hostel', address: 'Bomso, near KNUST', lat: 6.6772, lng: -1.5745,
        gender: 'MIXED', desc: 'Bomso area, about 7 minutes walk to campus. Quiet environment.',
        amenities: ['WiFi', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Nyame Mireku Hostel', address: 'Kotei, near KNUST', lat: 6.6680, lng: -1.5720,
        gender: 'MIXED', desc: 'Two blocks: apartment-style and standard rooms. Great balcony views.',
        amenities: ['WiFi', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Peace Hostel', address: 'Kotei, near KNUST', lat: 6.6675, lng: -1.5715,
        gender: 'MIXED', desc: 'Small cosy hostel off Kotei road. Each room has its own ECG meter.',
        amenities: ['Security', 'Water Supply'],
        config: 'doubles_quads', quality: 'budget' },
    { name: 'Gaza Hostel', address: 'Kentinkrono, near KNUST', lat: 6.6940, lng: -1.5555,
        gender: 'MIXED', desc: 'One of the most popular hostels. Clean, spacious, well-decorated. Multiple buildings.',
        amenities: ['WiFi', 'Backup Power', 'Security', 'Water Supply', 'Kitchen'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Achiba Hostel', address: 'Kentinkrono, near KNUST', lat: 6.6935, lng: -1.5560,
        gender: 'MIXED', desc: 'About 6 minutes drive to campus. Affordable rates.',
        amenities: ['Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Destiny View Hostel', address: 'Kentinkrono, near KNUST', lat: 6.6930, lng: -1.5550,
        gender: 'MIXED', desc: 'About 9 minutes drive to campus. Quiet with decent facilities.',
        amenities: ['WiFi', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
    { name: 'Think Jesus Hostel', address: 'Ahinsan, near KNUST', lat: 6.6800, lng: -1.5800,
        gender: 'MIXED', desc: 'Ahinsan area, about 7 minutes drive to campus. Budget-friendly.',
        amenities: ['Security', 'Water Supply'],
        config: 'doubles_quads', quality: 'budget' },
    { name: 'Anglican Hostel', address: 'Gaza/Kentinkrono, near KNUST', lat: 6.6925, lng: -1.5565,
        gender: 'MIXED', desc: 'Gaza area near Kentinkrono. About 5 minutes drive to campus.',
        amenities: ['WiFi', 'Security', 'Water Supply'],
        config: 'doubles_only', quality: 'standard' },
];
async function seed() {
    await ds.initialize();
    const q = ds.query.bind(ds);
    console.log('Seeding 30 KNUST hostels...\n');
    const amenities = await q(`SELECT id, name FROM amenities`);
    const amenityId = (name) => amenities.find((a) => a.name === name)?.id;
    const ownerHash = await argon2.hash('Owner1234!', { type: argon2.argon2id });
    const superHash = await argon2.hash('Super1234!', { type: argon2.argon2id });
    const [superOwner] = await q(`INSERT INTO users (full_name, email, password_hash, role, email_verified, phone_verified, id_verified, profile_completed)
     VALUES ($1, $2, $3, 'OWNER', true, true, true, true)
     ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
     RETURNING id`, ['StayNest Admin', 'super@staynest.com', superHash]);
    console.log(`Super-owner: super@staynest.com / Super1234! (${superOwner.id})\n`);
    let count = 0;
    let totalBeds = 0;
    for (const h of HOSTELS) {
        const slug = slugify(h.name);
        const ownerEmail = `owner@${slug}.com`;
        const [ow] = await q(`INSERT INTO users (full_name, email, password_hash, role, email_verified, phone_verified, id_verified, profile_completed)
       VALUES ($1, $2, $3, 'OWNER', true, true, true, true)
       ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
       RETURNING id`, [`${h.name} Management`, ownerEmail, ownerHash]);
        const [hostel] = await q(`INSERT INTO hostels (owner_id, name, description, address, city, status, verified, gender_policy, location, university, latitude, longitude)
       VALUES ($1, $2, $3, $4, $5, 'ACTIVE', true, $6, ST_SetSRID(ST_MakePoint($7, $8), 4326), 'KNUST', $9, $10)
       ON CONFLICT DO NOTHING
       RETURNING id`, [ow.id, h.name, h.desc, h.address, 'Kumasi', h.gender, h.lng, h.lat, h.lat, h.lng]);
        if (!hostel) {
            console.log(`  Skipping ${h.name} (already exists)`);
            continue;
        }
        const hostelId = hostel.id;
        for (const aName of h.amenities) {
            const aId = amenityId(aName);
            if (aId) {
                await q(`INSERT INTO hostel_amenities (hostel_id, amenity_id) VALUES ($1, $2) ON CONFLICT DO NOTHING`, [hostelId, aId]);
            }
        }
        const buildingCount = h.quality === 'premium' ? randInt(2, 3) : randInt(1, 2);
        for (let b = 0; b < buildingCount; b++) {
            const bName = buildingCount === 1 ? 'Main Block' : `Block ${String.fromCharCode(65 + b)}`;
            const [building] = await q(`INSERT INTO buildings (hostel_id, name) VALUES ($1, $2) RETURNING id`, [hostelId, bName]);
            const floorCount = h.quality === 'premium' ? randInt(3, 4) : randInt(2, 3);
            for (let f = 0; f < floorCount; f++) {
                const label = f === 0 ? 'Ground Floor' : `Floor ${f}`;
                const [floor] = await q(`INSERT INTO floors (building_id, label, sort_order) VALUES ($1, $2, $3) RETURNING id`, [building.id, label, f]);
                const roomsPerFloor = h.quality === 'premium' ? randInt(4, 6) : randInt(5, 8);
                for (let r = 0; r < roomsPerFloor; r++) {
                    let roomType;
                    let bedCount;
                    let priceRange;
                    if (h.config === 'doubles_only') {
                        roomType = '2-in-a-room';
                        bedCount = 2;
                        priceRange = PRICING[h.quality].double;
                    }
                    else if (h.config === 'doubles_singles') {
                        if (r % 3 === 0) {
                            roomType = '1-in-a-room';
                            bedCount = 1;
                            priceRange = PRICING[h.quality].single;
                        }
                        else {
                            roomType = '2-in-a-room';
                            bedCount = 2;
                            priceRange = PRICING[h.quality].double;
                        }
                    }
                    else {
                        if (r % 3 === 0) {
                            roomType = '4-in-a-room';
                            bedCount = 4;
                            priceRange = PRICING[h.quality].quad;
                        }
                        else {
                            roomType = '2-in-a-room';
                            bedCount = 2;
                            priceRange = PRICING[h.quality].double;
                        }
                    }
                    const price = randPrice(priceRange[0], priceRange[1]);
                    const roomNum = `${b + 1}${f}${String(r + 1).padStart(2, '0')}`;
                    const hasAC = h.quality === 'premium' && roomType === '1-in-a-room';
                    const hasBath = roomType === '1-in-a-room';
                    const [room] = await q(`INSERT INTO rooms (floor_id, number, type, price_pesewas, has_ac, has_private_bath, description)
             VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`, [floor.id, roomNum, roomType, price, hasAC, hasBath, `${roomType} in ${h.name}`]);
                    for (let bed = 0; bed < bedCount; bed++) {
                        const bedLabel = bedCount === 1 ? 'Bed A' : `Bed ${String.fromCharCode(65 + bed)}`;
                        const status = Math.random() < 0.25 ? 'OCCUPIED' : 'AVAILABLE';
                        await q(`INSERT INTO beds (room_id, label, status) VALUES ($1, $2, $3)`, [room.id, bedLabel, status]);
                        totalBeds++;
                    }
                }
            }
        }
        count++;
        console.log(`  [${count}/30] ${h.name} (${h.address})`);
    }
    console.log(`\nDone! ${count} hostels, ${totalBeds} beds seeded.`);
    console.log('\nAll owners use password: Owner1234!');
    console.log('Super-owner: super@staynest.com / Super1234!');
    await ds.destroy();
}
seed().catch((err) => {
    console.error('Seed failed:', err);
    process.exit(1);
});
//# sourceMappingURL=seed-knust-hostels.js.map