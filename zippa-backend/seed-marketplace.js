const db = require('./src/config/database');

async function seedCategories() {
    console.log('🌱 Seeding marketplace categories...');
    try {
        const categories = [
            ['Groceries', 'shopping_basket_rounded'],
            ['Pharmacy', 'medical_services_rounded'],
            ['Food', 'restaurant_rounded'],
            ['Electronics', 'devices_rounded'],
            ['Others', 'more_horiz_rounded']
        ];

        for (const [name, icon] of categories) {
            await db.query(
                'INSERT INTO vendor_categories (name, icon_name) VALUES ($1, $2) ON CONFLICT (name) DO NOTHING',
                [name, icon]
            );
            console.log(`✅ Category: ${name}`);
        }

        console.log('🎉 Seeding complete!');
    } catch (err) {
        console.error('❌ Seeding failed:', err.message);
    } finally {
        process.exit();
    }
}

seedCategories();
