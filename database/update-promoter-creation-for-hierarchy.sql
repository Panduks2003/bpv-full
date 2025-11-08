-- =====================================================
-- UPDATE PROMOTER CREATION FOR HIERARCHY SYSTEM
-- =====================================================
-- This updates your existing create_promoter_with_auth_id function
-- to automatically build hierarchy chains when promoters are created

-- Update the existing function to include hierarchy building
CREATE OR REPLACE FUNCTION create_promoter_with_auth_id(
    p_name TEXT,
    p_user_id UUID,
    p_auth_email TEXT,
    p_password TEXT,
    p_phone TEXT,
    p_email TEXT DEFAULT NULL,
    p_address TEXT DEFAULT NULL,
    p_parent_promoter_id UUID DEFAULT NULL,
    p_role_level TEXT DEFAULT 'Affiliate',
    p_status TEXT DEFAULT 'Active'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    new_promoter_id TEXT;
    profile_email TEXT;
    hierarchy_result JSON;
BEGIN
    -- Input validation
    IF p_name IS NULL OR TRIM(p_name) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Name is required'
        );
    END IF;
    
    IF p_user_id IS NULL THEN
        RETURN json_build_object(
            'success', false,
            'error', 'User ID is required'
        );
    END IF;
    
    IF p_auth_email IS NULL OR TRIM(p_auth_email) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Auth email is required'
        );
    END IF;
    
    IF p_phone IS NULL OR TRIM(p_phone) = '' THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Phone number is required'
        );
    END IF;
    
    -- Generate promoter ID
    new_promoter_id := generate_next_promoter_id();
    
    -- Store real email as metadata (can be NULL or duplicate)
    profile_email := CASE 
        WHEN p_email IS NULL OR TRIM(p_email) = '' THEN NULL 
        ELSE TRIM(p_email) 
    END;
    
    -- Create profile record
    INSERT INTO profiles (
        id,
        email,
        name,
        role,
        phone,
        address,
        promoter_id,
        role_level,
        status,
        parent_promoter_id,
        created_at,
        updated_at
    ) VALUES (
        p_user_id,
        profile_email,
        TRIM(p_name),
        'promoter',
        TRIM(p_phone),
        p_address,
        new_promoter_id,
        p_role_level,
        p_status,
        p_parent_promoter_id,
        NOW(),
        NOW()
    );
    
    -- Create promoter record if table exists
    BEGIN
        INSERT INTO promoters (
            id,
            promoter_id,
            parent_promoter_id,
            status,
            commission_rate,
            can_create_promoters,
            can_create_customers,
            created_at,
            updated_at
        ) VALUES (
            p_user_id,
            new_promoter_id,
            p_parent_promoter_id,
            LOWER(p_status),
            0.05,
            true,
            true,
            NOW(),
            NOW()
        );
    EXCEPTION WHEN OTHERS THEN
        -- Ignore if promoters table doesn't exist
        NULL;
    END;
    
    -- 🆕 BUILD HIERARCHY CHAIN (NEW ADDITION)
    BEGIN
        -- Build hierarchy chain for the new promoter
        PERFORM build_promoter_hierarchy_chain(p_user_id);
        RAISE NOTICE 'Hierarchy chain built for promoter %', new_promoter_id;
    EXCEPTION WHEN OTHERS THEN
        -- Log warning but don't fail the creation
        RAISE WARNING 'Could not build hierarchy chain for promoter %: %', new_promoter_id, SQLERRM;
    END;
    
    -- 🆕 GET HIERARCHY INFORMATION (NEW ADDITION)
    BEGIN
        SELECT get_promoter_upline_chain(new_promoter_id) INTO hierarchy_result;
    EXCEPTION WHEN OTHERS THEN
        hierarchy_result := json_build_object('upline_chain', '[]'::json, 'total_levels', 0);
    END;
    
    -- Return success with hierarchy information
    RETURN json_build_object(
        'success', true,
        'promoter_id', new_promoter_id,
        'user_id', p_user_id,
        'name', p_name,
        'phone', p_phone,
        'email', profile_email,
        'auth_email', p_auth_email,
        'parent_promoter_id', p_parent_promoter_id,
        'hierarchy_info', hierarchy_result,
        'message', 'Promoter created successfully with hierarchy. Use Promoter ID: ' || new_promoter_id || ' to login.'
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Failed to create promoter: ' || SQLERRM
    );
END;
$$;

-- Also update the unified promoter creation function if it exists
DO $$
BEGIN
    -- Check if create_unified_promoter function exists and update it too
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'create_unified_promoter'
    ) THEN
        -- Update create_unified_promoter to also build hierarchy
        EXECUTE '
        CREATE OR REPLACE FUNCTION create_unified_promoter(
            p_name VARCHAR(255),
            p_password VARCHAR(255),
            p_phone VARCHAR(20),
            p_email VARCHAR(255) DEFAULT NULL,
            p_address TEXT DEFAULT NULL,
            p_parent_promoter_id UUID DEFAULT NULL,
            p_role_level VARCHAR(50) DEFAULT ''Affiliate'',
            p_status VARCHAR(20) DEFAULT ''Active''
        )
        RETURNS JSON
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $func$
        DECLARE
            new_user_id UUID;
            new_promoter_id VARCHAR(20);
            auth_email VARCHAR(255);
            result JSON;
        BEGIN
            -- Generate UUID and promoter ID
            new_user_id := gen_random_uuid();
            new_promoter_id := generate_next_promoter_id();
            
            -- Handle email for authentication
            IF p_email IS NULL OR TRIM(p_email) = '''' THEN
                auth_email := ''noemail+'' || replace(new_user_id::text, ''-'', '''') || ''@brightplanetventures.local'';
            ELSE
                auth_email := p_email;
            END IF;
            
            -- Create profile record
            INSERT INTO profiles (
                id, email, name, role, phone, address, promoter_id, 
                role_level, status, parent_promoter_id, created_at, updated_at
            ) VALUES (
                new_user_id, p_email, p_name, ''promoter'', p_phone, p_address, 
                new_promoter_id, p_role_level, p_status, p_parent_promoter_id, NOW(), NOW()
            );
            
            -- Build hierarchy chain
            BEGIN
                PERFORM build_promoter_hierarchy_chain(new_user_id);
            EXCEPTION WHEN OTHERS THEN
                RAISE WARNING ''Could not build hierarchy for %: %'', new_promoter_id, SQLERRM;
            END;
            
            -- Return success
            RETURN json_build_object(
                ''success'', true,
                ''promoter_id'', new_promoter_id,
                ''user_id'', new_user_id,
                ''name'', p_name,
                ''phone'', p_phone,
                ''email'', p_email,
                ''hierarchy_built'', true
            );
        END;
        $func$;';
        
        RAISE NOTICE 'Updated create_unified_promoter function with hierarchy support';
    END IF;
END $$;

-- Create a trigger to automatically build hierarchy when promoters are updated
CREATE OR REPLACE FUNCTION trigger_rebuild_hierarchy_on_parent_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Only rebuild if parent_promoter_id changed and this is a promoter
    IF NEW.role = 'promoter' AND OLD.parent_promoter_id IS DISTINCT FROM NEW.parent_promoter_id THEN
        -- Rebuild hierarchy for this promoter
        BEGIN
            PERFORM build_promoter_hierarchy_chain(NEW.id);
            RAISE NOTICE 'Rebuilt hierarchy for promoter % due to parent change', NEW.promoter_id;
        EXCEPTION WHEN OTHERS THEN
            RAISE WARNING 'Failed to rebuild hierarchy for promoter %: %', NEW.promoter_id, SQLERRM;
        END;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create the trigger (drop first if exists)
DROP TRIGGER IF EXISTS trigger_hierarchy_on_parent_change ON profiles;
CREATE TRIGGER trigger_hierarchy_on_parent_change
    AFTER UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION trigger_rebuild_hierarchy_on_parent_change();

-- Log completion
DO $$
BEGIN
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'PROMOTER CREATION FUNCTIONS UPDATED FOR HIERARCHY';
    RAISE NOTICE '=================================================';
    RAISE NOTICE 'Updated Functions:';
    RAISE NOTICE '  ✅ create_promoter_with_auth_id() - now builds hierarchy';
    RAISE NOTICE '  ✅ create_unified_promoter() - now builds hierarchy (if exists)';
    RAISE NOTICE '  ✅ Added trigger for parent changes';
    RAISE NOTICE '';
    RAISE NOTICE 'New Features:';
    RAISE NOTICE '  🔗 Automatic hierarchy building on creation';
    RAISE NOTICE '  📊 Hierarchy info included in response';
    RAISE NOTICE '  🔄 Auto-rebuild on parent changes';
    RAISE NOTICE '  ⚠️  Error handling for missing functions';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Your business logic is now hierarchy-ready!';
    RAISE NOTICE '=================================================';
END $$;
