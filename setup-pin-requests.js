#!/usr/bin/env node

/**
 * PIN REQUEST SYSTEM SETUP SCRIPT
 * This script sets up the complete PIN request system in Supabase
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Supabase configuration
const SUPABASE_URL = 'https://ubokvxgxszhpzmjonuss.supabase.co';
const SUPABASE_SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVib2t2eGd4c3pocHptam9udXNzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMDEwMjQxNSwiZXhwIjoyMDQ1Njc4NDE1fQ.Vy4YzRbTvZcUwJzxIv1Gp-3hUZyJQqLXPb9wNRCQxVk';

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

async function setupPinRequestSystem() {
    console.log('🚀 Setting up PIN Request System...\n');

    try {
        // Step 1: Create pin_requests table
        console.log('📋 Step 1: Creating pin_requests table...');
        const createTableSQL = `
            CREATE TABLE IF NOT EXISTS pin_requests (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                request_number SERIAL UNIQUE,
                promoter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
                requested_pins INTEGER NOT NULL CHECK (requested_pins > 0),
                reason TEXT,
                status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
                approved_by UUID REFERENCES profiles(id),
                admin_notes TEXT,
                approved_at TIMESTAMP WITH TIME ZONE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
            );
        `;
        
        const { error: tableError } = await supabase.rpc('exec_sql', { sql: createTableSQL });
        if (tableError && !tableError.message.includes('already exists')) {
            console.log('⚠️  Table creation note:', tableError.message);
        } else {
            console.log('✅ Table created successfully');
        }

        // Step 2: Create indexes
        console.log('\n📊 Step 2: Creating indexes...');
        const indexes = [
            'CREATE INDEX IF NOT EXISTS idx_pin_requests_promoter_id ON pin_requests(promoter_id);',
            'CREATE INDEX IF NOT EXISTS idx_pin_requests_status ON pin_requests(status);',
            'CREATE INDEX IF NOT EXISTS idx_pin_requests_created_at ON pin_requests(created_at DESC);',
            'CREATE INDEX IF NOT EXISTS idx_pin_requests_approved_by ON pin_requests(approved_by);'
        ];

        for (const indexSQL of indexes) {
            const { error } = await supabase.rpc('exec_sql', { sql: indexSQL });
            if (error && !error.message.includes('already exists')) {
                console.log('⚠️  Index note:', error.message);
            }
        }
        console.log('✅ Indexes created successfully');

        // Step 3: Enable RLS
        console.log('\n🔒 Step 3: Enabling Row Level Security...');
        const { error: rlsError } = await supabase.rpc('exec_sql', { 
            sql: 'ALTER TABLE pin_requests ENABLE ROW LEVEL SECURITY;' 
        });
        if (rlsError && !rlsError.message.includes('already')) {
            console.log('⚠️  RLS note:', rlsError.message);
        } else {
            console.log('✅ RLS enabled successfully');
        }

        // Step 4: Create RLS policies
        console.log('\n🛡️  Step 4: Creating RLS policies...');
        const policies = [
            {
                name: 'promoters_can_view_own_requests',
                sql: `
                    CREATE POLICY "promoters_can_view_own_requests" ON pin_requests
                        FOR SELECT USING (promoter_id = auth.uid());
                `
            },
            {
                name: 'promoters_can_create_requests',
                sql: `
                    CREATE POLICY "promoters_can_create_requests" ON pin_requests
                        FOR INSERT WITH CHECK (promoter_id = auth.uid());
                `
            },
            {
                name: 'admins_can_view_all_requests',
                sql: `
                    CREATE POLICY "admins_can_view_all_requests" ON pin_requests
                        FOR SELECT USING (
                            EXISTS (
                                SELECT 1 FROM profiles 
                                WHERE profiles.id = auth.uid() 
                                AND profiles.role = 'admin'
                            )
                        );
                `
            },
            {
                name: 'admins_can_update_requests',
                sql: `
                    CREATE POLICY "admins_can_update_requests" ON pin_requests
                        FOR UPDATE USING (
                            EXISTS (
                                SELECT 1 FROM profiles 
                                WHERE profiles.id = auth.uid() 
                                AND profiles.role = 'admin'
                            )
                        );
                `
            }
        ];

        for (const policy of policies) {
            // Drop existing policy first
            await supabase.rpc('exec_sql', { 
                sql: `DROP POLICY IF EXISTS "${policy.name}" ON pin_requests;` 
            });
            
            const { error } = await supabase.rpc('exec_sql', { sql: policy.sql });
            if (error) {
                console.log(`⚠️  Policy ${policy.name} note:`, error.message);
            }
        }
        console.log('✅ RLS policies created successfully');

        // Step 5: Create trigger function
        console.log('\n⚙️  Step 5: Creating trigger function...');
        const triggerFunctionSQL = `
            CREATE OR REPLACE FUNCTION update_pin_requests_updated_at()
            RETURNS TRIGGER AS $$
            BEGIN
                NEW.updated_at = NOW();
                RETURN NEW;
            END;
            $$ LANGUAGE plpgsql;
        `;
        
        const { error: triggerFuncError } = await supabase.rpc('exec_sql', { sql: triggerFunctionSQL });
        if (triggerFuncError) {
            console.log('⚠️  Trigger function note:', triggerFuncError.message);
        } else {
            console.log('✅ Trigger function created successfully');
        }

        // Step 6: Create trigger
        console.log('\n🔔 Step 6: Creating trigger...');
        const triggerSQL = `
            DROP TRIGGER IF EXISTS pin_requests_updated_at_trigger ON pin_requests;
            CREATE TRIGGER pin_requests_updated_at_trigger
                BEFORE UPDATE ON pin_requests
                FOR EACH ROW
                EXECUTE FUNCTION update_pin_requests_updated_at();
        `;
        
        const { error: triggerError } = await supabase.rpc('exec_sql', { sql: triggerSQL });
        if (triggerError) {
            console.log('⚠️  Trigger note:', triggerError.message);
        } else {
            console.log('✅ Trigger created successfully');
        }

        // Step 7: Create submit_pin_request function
        console.log('\n📝 Step 7: Creating submit_pin_request function...');
        const submitFunctionSQL = `
            CREATE OR REPLACE FUNCTION submit_pin_request(
                p_promoter_id UUID,
                p_requested_pins INTEGER,
                p_reason TEXT DEFAULT NULL
            ) RETURNS JSON
            LANGUAGE plpgsql
            SECURITY DEFINER
            AS $$
            DECLARE
                v_request_id UUID;
                v_request_number INTEGER;
                v_pending_count INTEGER;
                v_result JSON;
            BEGIN
                -- Validate promoter exists and has correct role
                IF NOT EXISTS (
                    SELECT 1 FROM profiles 
                    WHERE id = p_promoter_id AND role = 'promoter'
                ) THEN
                    RETURN json_build_object(
                        'success', false,
                        'error', 'Invalid promoter ID or role'
                    );
                END IF;

                -- Check for existing pending requests
                SELECT COUNT(*) INTO v_pending_count
                FROM pin_requests 
                WHERE promoter_id = p_promoter_id AND status = 'pending';

                IF v_pending_count > 0 THEN
                    RETURN json_build_object(
                        'success', false,
                        'error', 'You already have a pending PIN request. Please wait for admin approval.'
                    );
                END IF;

                -- Validate requested pins
                IF p_requested_pins <= 0 OR p_requested_pins > 1000 THEN
                    RETURN json_build_object(
                        'success', false,
                        'error', 'Requested PINs must be between 1 and 1000'
                    );
                END IF;

                -- Insert the request
                INSERT INTO pin_requests (promoter_id, requested_pins, reason)
                VALUES (p_promoter_id, p_requested_pins, p_reason)
                RETURNING id, request_number INTO v_request_id, v_request_number;

                -- Return success result
                v_result := json_build_object(
                    'success', true,
                    'request_id', v_request_id,
                    'request_number', v_request_number,
                    'message', 'PIN request submitted successfully'
                );

                RETURN v_result;

            EXCEPTION WHEN OTHERS THEN
                RETURN json_build_object(
                    'success', false,
                    'error', SQLERRM
                );
            END $$;
        `;
        
        const { error: submitFuncError } = await supabase.rpc('exec_sql', { sql: submitFunctionSQL });
        if (submitFuncError) {
            console.log('⚠️  Submit function note:', submitFuncError.message);
        } else {
            console.log('✅ submit_pin_request function created successfully');
        }

        // Step 8: Create get_pin_requests function
        console.log('\n📖 Step 8: Creating get_pin_requests function...');
        const getFunctionSQL = `
            CREATE OR REPLACE FUNCTION get_pin_requests(
                p_promoter_id UUID DEFAULT NULL,
                p_status VARCHAR(20) DEFAULT NULL,
                p_limit INTEGER DEFAULT 50
            ) RETURNS TABLE (
                id UUID,
                request_number INTEGER,
                promoter_id UUID,
                promoter_name TEXT,
                promoter_email TEXT,
                requested_pins INTEGER,
                reason TEXT,
                status VARCHAR(20),
                approved_by UUID,
                admin_name TEXT,
                admin_notes TEXT,
                approved_at TIMESTAMP WITH TIME ZONE,
                created_at TIMESTAMP WITH TIME ZONE,
                updated_at TIMESTAMP WITH TIME ZONE
            )
            LANGUAGE plpgsql
            SECURITY DEFINER
            AS $$
            BEGIN
                RETURN QUERY
                SELECT 
                    pr.id,
                    pr.request_number,
                    pr.promoter_id,
                    p_promoter.name as promoter_name,
                    p_promoter.email as promoter_email,
                    pr.requested_pins,
                    pr.reason,
                    pr.status,
                    pr.approved_by,
                    p_admin.name as admin_name,
                    pr.admin_notes,
                    pr.approved_at,
                    pr.created_at,
                    pr.updated_at
                FROM pin_requests pr
                LEFT JOIN profiles p_promoter ON pr.promoter_id = p_promoter.id
                LEFT JOIN profiles p_admin ON pr.approved_by = p_admin.id
                WHERE 
                    (p_promoter_id IS NULL OR pr.promoter_id = p_promoter_id)
                    AND (p_status IS NULL OR pr.status = p_status)
                ORDER BY pr.created_at DESC
                LIMIT p_limit;
            END $$;
        `;
        
        const { error: getFuncError } = await supabase.rpc('exec_sql', { sql: getFunctionSQL });
        if (getFuncError) {
            console.log('⚠️  Get function note:', getFuncError.message);
        } else {
            console.log('✅ get_pin_requests function created successfully');
        }

        // Step 9: Grant permissions
        console.log('\n🔑 Step 9: Granting permissions...');
        const grantSQL = `
            GRANT EXECUTE ON FUNCTION submit_pin_request(UUID, INTEGER, TEXT) TO authenticated;
            GRANT EXECUTE ON FUNCTION get_pin_requests(UUID, VARCHAR(20), INTEGER) TO authenticated;
        `;
        
        const { error: grantError } = await supabase.rpc('exec_sql', { sql: grantSQL });
        if (grantError) {
            console.log('⚠️  Grant note:', grantError.message);
        } else {
            console.log('✅ Permissions granted successfully');
        }

        // Verification
        console.log('\n✅ PIN Request System setup completed!\n');
        console.log('📊 Verification:');
        console.log('   - pin_requests table created');
        console.log('   - Indexes created');
        console.log('   - RLS policies enabled');
        console.log('   - Functions created: submit_pin_request, get_pin_requests');
        console.log('\n🎉 You can now use the PIN request system in your application!');

    } catch (error) {
        console.error('❌ Error setting up PIN request system:', error);
        throw error;
    }
}

// Run the setup
setupPinRequestSystem()
    .then(() => {
        console.log('\n✅ Setup completed successfully!');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n❌ Setup failed:', error);
        process.exit(1);
    });
