#!/bin/bash

# =====================================================
# PROMOTER ID AUTHENTICATION SYSTEM DEPLOYMENT
# =====================================================
# This script helps deploy the new Promoter ID authentication system

set -e  # Exit on any error

echo "🚀 Starting Promoter ID Authentication System Deployment"
echo "========================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "revamp-promoter-auth-system.sql" ]; then
    print_error "revamp-promoter-auth-system.sql not found in current directory"
    print_info "Please run this script from the project root directory"
    exit 1
fi

print_info "Found required files in current directory"

# Step 1: Database Migration
echo ""
echo "📊 Step 1: Database Migration"
echo "=============================="

print_warning "IMPORTANT: This will modify your database schema and data!"
print_warning "Please ensure you have a backup before proceeding."
echo ""

read -p "Do you want to proceed with database migration? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Database migration skipped by user"
else
    print_info "Please run the following SQL script in your database:"
    print_info "psql -d your_database_name -f revamp-promoter-auth-system.sql"
    print_info ""
    print_info "Or execute it manually in your database management tool"
    echo ""
    read -p "Press Enter when database migration is complete..."
    print_status "Database migration marked as complete"
fi

# Step 2: Frontend Dependencies
echo ""
echo "📦 Step 2: Frontend Dependencies"
echo "================================="

if [ -d "frontend" ]; then
    print_info "Checking frontend dependencies..."
    
    cd frontend
    
    # Check if package.json exists
    if [ -f "package.json" ]; then
        print_info "Installing/updating frontend dependencies..."
        npm install
        print_status "Frontend dependencies updated"
    else
        print_warning "package.json not found in frontend directory"
    fi
    
    cd ..
else
    print_warning "Frontend directory not found"
fi

# Step 3: File Verification
echo ""
echo "📁 Step 3: File Verification"
echo "============================="

# Check if all required files exist
files_to_check=(
    "revamp-promoter-auth-system.sql"
    "frontend/src/common/components/PromoterIDLoginPage.js"
    "frontend/src/common/services/authService.js"
    "frontend/src/components/UnifiedPromoterForm.js"
    "PROMOTER-ID-AUTH-SYSTEM-GUIDE.md"
)

all_files_exist=true

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        print_status "Found: $file"
    else
        print_error "Missing: $file"
        all_files_exist=false
    fi
done

if [ "$all_files_exist" = true ]; then
    print_status "All required files are present"
else
    print_error "Some files are missing. Please ensure all files are created."
    exit 1
fi

# Step 4: Configuration Updates
echo ""
echo "⚙️  Step 4: Configuration Updates"
echo "=================================="

print_info "Please update your frontend routing to use the new login page:"
print_info ""
print_info "1. Import the new login component:"
print_info "   import PromoterIDLoginPage from './common/components/PromoterIDLoginPage';"
print_info ""
print_info "2. Update your route configuration:"
print_info "   <Route path=\"/login\" element={<PromoterIDLoginPage />} />"
print_info ""
print_info "3. Update any existing login links to point to the new system"

echo ""
read -p "Have you updated the frontend routing? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Frontend routing updated"
else
    print_warning "Please update frontend routing before testing"
fi

# Step 5: Testing Instructions
echo ""
echo "🧪 Step 5: Testing Instructions"
echo "==============================="

print_info "To test the new system:"
print_info ""
print_info "1. Database Testing:"
print_info "   SELECT * FROM profiles WHERE role = 'promoter' LIMIT 5;"
print_info "   SELECT authenticate_promoter_by_id_only('BPVP01', 'test_password');"
print_info ""
print_info "2. Frontend Testing:"
print_info "   - Start your development server"
print_info "   - Navigate to /login"
print_info "   - Test Promoter ID login with existing promoter"
print_info "   - Test admin interface for creating new promoters"
print_info ""
print_info "3. Create Test Promoter:"
print_info "   SELECT create_promoter_with_id_auth("
print_info "     'Test User',"
print_info "     'test@example.com',"
print_info "     'password123',"
print_info "     '9876543210'"
print_info "   );"

# Step 6: Deployment Checklist
echo ""
echo "📋 Step 6: Deployment Checklist"
echo "================================"

checklist=(
    "Database migration executed successfully"
    "All database functions created (create_promoter_with_id_auth, authenticate_promoter_by_id_only)"
    "Frontend dependencies installed"
    "New login page integrated into routing"
    "Admin promoter creation form updated"
    "Authentication service updated"
    "Existing promoters tested with new system"
    "New promoter creation tested"
    "Login flow tested end-to-end"
)

echo ""
print_info "Please verify the following items:"
for item in "${checklist[@]}"; do
    echo "  ☐ $item"
done

# Step 7: Rollback Instructions
echo ""
echo "🔄 Step 7: Rollback Instructions"
echo "================================="

print_warning "If you need to rollback:"
print_info ""
print_info "1. Database Rollback:"
print_info "   - Restore from backup before migration"
print_info "   - Or manually revert schema changes"
print_info ""
print_info "2. Frontend Rollback:"
print_info "   - Revert to previous login component"
print_info "   - Restore original authService.js"
print_info "   - Update routing back to old system"

# Final Summary
echo ""
echo "🎉 Deployment Summary"
echo "===================="

print_status "Promoter ID Authentication System deployment preparation complete!"
print_info ""
print_info "Key Features Implemented:"
print_info "✅ Promoter ID-only authentication (BPVP01, BPVP02, etc.)"
print_info "✅ Email/phone as metadata only (can duplicate)"
print_info "✅ Unique placeholder emails for Supabase auth"
print_info "✅ Clean database with no AUTH_MISSING entries"
print_info "✅ Updated frontend components and forms"
print_info ""
print_info "Next Steps:"
print_info "1. Complete database migration"
print_info "2. Update frontend routing"
print_info "3. Test thoroughly in development"
print_info "4. Deploy to production when ready"
print_info ""
print_info "Documentation: See PROMOTER-ID-AUTH-SYSTEM-GUIDE.md for complete details"

echo ""
print_status "Deployment script completed successfully! 🚀"
echo "========================================================"
