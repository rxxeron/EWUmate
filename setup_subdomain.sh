#!/bin/bash

echo "🌐 Setting up subdomain for admin panel"
echo "========================================"
echo ""
echo "This will configure admin.rxxeron.me for your admin panel"
echo ""

cd /workspaces/EWUmate
git checkout gh-pages

# Create CNAME file with subdomain
echo "admin.rxxeron.me" > CNAME

# Add .nojekyll if not exists
touch .nojekyll

echo "✅ CNAME file created with: admin.rxxeron.me"
echo ""
echo "📤 Committing and pushing..."
git add CNAME .nojekyll
git commit -m "Configure subdomain for admin panel"
git push origin gh-pages

echo ""
echo "✅ Pushed to GitHub!"
echo ""
echo "📋 Now configure DNS:"
echo "--------------------"
echo "1. Go to your domain registrar (where you bought rxxeron.me)"
echo "2. Add a CNAME record:"
echo "   Host: admin"
echo "   Points to: rxxeron.github.io"
echo "   TTL: 3600 (or default)"
echo ""
echo "3. Wait 10-60 minutes for DNS to propagate"
echo ""
echo "4. Access your admin panel at:"
echo "   https://admin.rxxeron.me"
echo ""

git checkout main
