#!/bin/bash

echo "🔐 Setting up Admin Password for Supabase"
echo "=========================================="
echo ""

# Prompt for password
read -sp "Enter your admin password (won't be shown): " ADMIN_PASSWORD
echo ""
read -sp "Confirm password: " ADMIN_PASSWORD_CONFIRM
echo ""
echo ""

# Check if passwords match
if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]; then
    echo "❌ Passwords don't match!"
    exit 1
fi

# Check password length
if [ ${#ADMIN_PASSWORD} -lt 8 ]; then
    echo "❌ Password must be at least 8 characters!"
    exit 1
fi

echo "📤 Setting ADMIN_PASSWORD in Supabase..."
cd /workspaces/EWUmate

# Set the secret
supabase secrets set ADMIN_PASSWORD="$ADMIN_PASSWORD"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Admin password set successfully!"
    echo ""
    echo "🎯 You can now access your admin panel at:"
    echo "   https://admin.rxxeron.me"
    echo ""
    echo "🔑 Login with the password you just set"
else
    echo ""
    echo "❌ Failed to set password. Make sure you're logged in to Supabase:"
    echo "   supabase login"
fi
