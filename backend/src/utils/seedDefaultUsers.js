const { User, Billboard } = require('../models');

const defaultUsers = [
  {
    email: 'admin@smartads.cm',
    fullName: 'System Administrator',
    password: 'Password123!',
    role: 'ADMIN',
    accountStatus: 'ACTIVE',
    phoneNumber: '+237 670000001'
  },
  {
    email: 'kelly@gmail.com',
    fullName: 'Kelly Admin',
    password: 'Password123!',
    role: 'ADMIN',
    accountStatus: 'ACTIVE',
    phoneNumber: '+237 670000009'
  },
  {
    email: 'advertiser@smartads.cm',
    fullName: 'Demo Advertiser',
    password: 'Password123!',
    role: 'ADVERTISER',
    accountStatus: 'ACTIVE',
    phoneNumber: '+237 670000002'
  },
  {
    email: 'owner@smartads.cm',
    fullName: 'Demo Billboard Owner',
    password: 'Password123!',
    role: 'BILLBOARD_OWNER',
    accountStatus: 'ACTIVE',
    phoneNumber: '+237 670000003'
  }
];

const seedDefaultUsers = async () => {
  if (process.env.NODE_ENV === 'test') return;

  try {
    console.log('🌱 Checking / Seeding default test accounts...');

    let ownerUser = null;
    let adminUser = null;

    for (const userData of defaultUsers) {
      let existing = await User.findOne({ where: { email: userData.email } });
      if (!existing) {
        existing = await User.create(userData);
        console.log(`✅ Seeded account: ${userData.email} (${userData.role})`);
      } else {
        // Ensure account status is ACTIVE and role is correct
        let updated = false;
        if (existing.role !== userData.role) {
          existing.role = userData.role;
          updated = true;
        }
        if (existing.accountStatus !== userData.accountStatus) {
          existing.accountStatus = userData.accountStatus;
          updated = true;
        }
        if (updated) {
          await existing.save();
        }
      }

      if (userData.role === 'BILLBOARD_OWNER' && !ownerUser) {
        ownerUser = existing;
      }
      if (userData.role === 'ADMIN' && !adminUser) {
        adminUser = existing;
      }
    }

    // Seed sample digital billboards
    const { seedBillboards } = require('./seedBillboards');
    await seedBillboards();

    console.log('✅ Default users & seed data are ready in database.');
  } catch (err) {
    console.warn(`⚠️ Notice during user/data seeding: ${err.message}`);
  }
};

module.exports = { seedDefaultUsers, defaultUsers };
