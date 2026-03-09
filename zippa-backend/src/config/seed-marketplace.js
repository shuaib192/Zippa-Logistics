const { Pool } = require('pg');
const path = require('path');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: path.join(__dirname, '../../.env') });

const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT) || 5432,
    user: process.env.DB_USER || 'zippa_admin',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'zippa_logistics',
});

async function seedMarketplace() {
    console.log('🌱 Seeding Glovo-style Marketplace data...');
    try {
        const passwordHash = await bcrypt.hash('password123', 10);

        // 1. Get Categories
        const catRes = await pool.query('SELECT id, name FROM vendor_categories');
        const categories = {};
        catRes.rows.forEach(c => categories[c.name] = c.id);

        if (Object.keys(categories).length === 0) {
            console.error('❌ No categories found. Run migration first.');
            return;
        }

        // 2. Create Mock Vendors with Banners
        const vendors = [
            { 
                name: 'ShopRite Lagos', phone: '2348001112221', category: 'Groceries', business: 'ShopRite Supermarket', 
                lat: 6.5967, lng: 3.3421,
                banner: 'https://images.unsplash.com/photo-1534723452862-4c874018d66d',
                products: [
                    { 
                        name: 'Fresh Bakery Bread', price: 1200, desc: 'Large farmhouse white bread, baked fresh daily.',
                        image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff',
                        gallery: ['https://images.unsplash.com/photo-1533130064222-786cf7471923', 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73']
                    },
                    { 
                        name: 'Premium Farm Milk', price: 2100, desc: '1L fresh whole milk from local dairy farms.',
                        image: 'https://images.unsplash.com/photo-1550583724-125581fe2f4d',
                        gallery: ['https://images.unsplash.com/photo-1563636619-e910bd29339e']
                    }
                ]
            },
            { 
                name: 'MedPlus Pharmacy', phone: '2348001112222', category: 'Pharmacy', business: 'MedPlus Health', 
                lat: 6.4253, lng: 3.4095,
                banner: 'https://images.unsplash.com/photo-1586015555751-63bb77f4322a',
                products: [
                    { 
                        name: 'Vitamin C 1000mg', price: 3500, desc: 'Immune system booster, 30 tablets per pack.',
                        image: 'https://images.unsplash.com/photo-1616671285410-0985226bc781',
                        gallery: ['https://images.unsplash.com/photo-1584308666744-24d5c474f2ae']
                    },
                    { 
                        name: 'First Aid Kit', price: 8500, desc: 'Complete emergency first aid kit for home and travel.',
                        image: 'https://images.unsplash.com/photo-1603398938378-e54eab446f91',
                        gallery: ['https://images.unsplash.com/photo-1583947215259-38e31be8751f']
                    }
                ]
            },
            { 
                name: 'Chicken Republic', phone: '2348001112223', category: 'Restaurants', business: 'Chicken Republic Fast Food', 
                lat: 6.5000, lng: 3.3500,
                banner: 'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b',
                products: [
                    { 
                        name: 'Refuel Max Meal', price: 4500, desc: 'Spicy fried chicken, jollof rice, and a cold drink.',
                        image: 'https://images.unsplash.com/photo-1562967914-608f82629710',
                        gallery: ['https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec']
                    },
                    { 
                        name: 'Crunchy Chicken Burger', price: 3200, desc: 'Double-breaded chicken breast with fresh lettuce and mayo.',
                        image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
                        gallery: ['https://images.unsplash.com/photo-1550547660-d9450f859349']
                    }
                ]
            },
            { 
                name: 'Coca-Cola Depot', phone: '2348001112224', category: 'Drinks', business: 'Lagos Drinks Hub', 
                lat: 6.5500, lng: 3.3700,
                banner: 'https://images.unsplash.com/photo-1491295240217-101185012574',
                products: [
                    { 
                        name: 'Coke Zero 50cl x 12', price: 3600, desc: 'Pack of 12 sugar-free Coca-Cola bottles.',
                        image: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97',
                        gallery: ['https://images.unsplash.com/photo-1554866585-cd94860890b7']
                    }
                ]
            },
            { 
                name: 'Zippa Fashion Hub', phone: '2348001112225', category: 'Fashion', business: 'Zippa Boutique', 
                lat: 6.4500, lng: 3.3900,
                banner: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8',
                products: [
                    { 
                        name: 'Casual Cotton Tee', price: 7500, desc: '100% organic cotton t-shirt in various colors.',
                        image: 'https://images.unsplash.com/photo-1521572267360-ee0c2909d518',
                        gallery: ['https://images.unsplash.com/photo-1562157873-818bc0726f68']
                    }
                ]
            }
        ];

        for (const v of vendors) {
            // Create User
            const userRes = await pool.query(
                `INSERT INTO users (email, phone, password_hash, full_name, role, kyc_status) 
                 VALUES ($1, $2, $3, $4, 'vendor', 'verified') 
                 ON CONFLICT (phone) DO UPDATE SET full_name = $4 RETURNING id`,
                [`${v.name.toLowerCase().replace(/ /g, '')}@example.com`, v.phone, passwordHash, v.name]
            );
            const userId = userRes.rows[0].id;

            // Create Profile
            await pool.query(
                `INSERT INTO user_profiles (user_id, business_name, business_address, business_category_id, latitude, longitude, banner_url) 
                 VALUES ($1, $2, $3, $4, $5, $6, $7) 
                 ON CONFLICT (user_id) DO UPDATE SET banner_url = $7, latitude = $5, longitude = $6`,
                [userId, v.business, `123 ${v.category} Street, Lagos`, categories[v.category], v.lat, v.lng, v.banner]
            );

            // Create Wallet
            await pool.query(
                'INSERT INTO wallets (user_id, balance) VALUES ($1, 0) ON CONFLICT (user_id) DO NOTHING',
                [userId]
            );

            // 3. Create Mock Products for this vendor
            for (const p of v.products) {
                await pool.query(
                    `INSERT INTO products (vendor_id, category_id, name, description, price, is_available, image_url, image_urls) 
                     VALUES ($1, $2, $3, $4, $5, true, $6, $7)
                     ON CONFLICT (vendor_id, name) DO UPDATE SET description = $4, price = $5, image_url = $6, image_urls = $7`,
                    [userId, categories[v.category], p.name, p.desc, p.price, p.image, JSON.stringify(p.gallery)]
                );
            }
            console.log(`✅ Seeded Vendor: ${v.name} with banner and rich products`);
        }

        console.log('\n🚀 Marketplace seeding complete!');
    } catch (err) {
        console.error('❌ Seeding failed:', err.message);
    } finally {
        await pool.end();
    }
}

seedMarketplace();
