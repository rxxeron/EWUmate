const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');

// ----------------------------------------------------
// ⚠️ CREDENTIALS ⚠️
// ----------------------------------------------------
const FIREBASE_SERVICE_KEY_PATH = './service-accounts.json';
const SUPABASE_URL = 'https://jwygjihrbwxhehijldiz.supabase.co';
const SUPABASE_SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp3eWdqaWhyYnd4aGVoaWpsZGl6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTEwNDE3NCwiZXhwIjoyMDg2NjgwMTc0fQ.Fv42T-rcWRz2nqiScYFxBBGc_h55yoa_t1rbEm6qhcc';

async function migrateUsers() {
    console.log("🚀 Starting User Migration...");

    // Init Firebase
    const serviceAccount = require(FIREBASE_SERVICE_KEY_PATH);
    if (admin.apps.length === 0) {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
    }

    // Init Supabase
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: {
            autoRefreshToken: false,
            persistSession: false
        }
    });

    // 1. Get ALL Firebase Users
    console.log("📥 Fetching users from Firebase...");
    let firebaseUsers = [];
    let nextPageToken;
    do {
        const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
        listUsersResult.users.forEach((userRecord) => {
            firebaseUsers.push(userRecord.toJSON());
        });
        nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    console.log(`Found ${firebaseUsers.length} users in Firebase.`);

    // 2. Import to Supabase
    console.log("📤 Importing to Supabase...");

    // NOTE: Firebase uses SCRYPT by default.
    // We need the hash config from Firebase Project Settings -> Users & Permissions -> Password Hash Parameters
    // But usually we can't get salt/rounds easily via Admin SDK unless we export.
    // Wait! listUsers() DOES return passwordHash and passwordSalt if the user has a passwordProvider!

    for (const user of firebaseUsers) {
        // Only migrate password users for now. Social users need to re-login.
        const isPasswordUser = user.providerData.some(p => p.providerId === 'password');

        if (isPasswordUser && user.passwordHash && user.passwordSalt) {
            console.log(`Migrating ${user.email} (Password User)...`);

            // Note: Supabase doesn't natively support importing raw SCRYPT hashes via public API easily.
            // However, we can create the user without a password and ask them to reset, OR use a raw SQL query if we had access.
            // BUT! We can just create them with a temporary password or simply create them so they exist, and trigger a password reset.
            // OR, if we use the Supabase CLI, we can use `supabase auth import`.

            // Strategy: Create user. If we can't set the hash, we set 'verified' to true so they can use "Forgot Password".
            // Or even better: Supabase Admin API createUser allows setting `password`. We don't have the plain text password.

            // Fallback: Create user with `email_confirm: true`. User must reset password.
            // This is the safest programmatic way without direct DB access or CLI import command.

            try {
                const { data, error } = await supabase.auth.admin.createUser({
                    email: user.email,
                    email_confirm: true,
                    user_metadata: {
                        displayName: user.displayName,
                        photoURL: user.photoUrl,
                        migratedFromFirebase: true
                    }
                });

                if (error) {
                    console.error(`   Failed to create ${user.email}: ${error.message}`);
                } else {
                    console.log(`   ✅ Created ${user.email} (ID: ${data.user.id})`);
                }
            } catch (e) {
                console.error(`   Ex: ${user.email}`, e.message);
            }

        } else {
            console.log(`Skipping ${user.email} (No password hash or Social provider)`);
            // Social users will just sign in again with Google and it should link/create if email matches.
        }
    }

    console.log("\nMigration script finished.");
    console.log("⚠️ Note: Imported users will need to reset their password via 'Forgot Password' email,");
    console.log("   UNLESS we use the CLI 'supabase auth import' command with the hash parameters.");
}

migrateUsers();
