-- ========================================================
-- SAJURIYA TESTER - CLEAN & RELATIONAL SCHEMA
-- ========================================================

-- 0. CLEAN SLATE
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.complete_test_assignment(UUID, TEXT) CASCADE;
DROP FUNCTION IF EXISTS public.create_app_listing(UUID, TEXT, TEXT, TEXT, TEXT) CASCADE;

DROP TABLE IF EXISTS public.app_reviews CASCADE;
DROP TABLE IF EXISTS public.karma_transactions CASCADE;
DROP TABLE IF EXISTS public.onboarding_proofs CASCADE;
DROP TABLE IF EXISTS public.test_assignments CASCADE;
DROP TABLE IF EXISTS public.apps CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABLES

-- PROFILES
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    credits INTEGER DEFAULT 0 NOT NULL,
    reputation_score INTEGER DEFAULT 0 NOT NULL,
    role TEXT DEFAULT 'developer' CHECK (role IN ('developer', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- APPS
CREATE TABLE public.apps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    developer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    app_name TEXT NOT NULL,
    package_name TEXT NOT NULL UNIQUE,
    playstore_url TEXT NOT NULL,
    app_icon TEXT,
    description TEXT,
    reward_credits INTEGER DEFAULT 10 NOT NULL,
    required_test_days INTEGER DEFAULT 14 NOT NULL,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- TEST ASSIGNMENTS
CREATE TABLE public.test_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    developer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    app_id UUID REFERENCES public.apps(id) ON DELETE CASCADE NOT NULL,
    is_completed BOOLEAN DEFAULT false NOT NULL,
    test_status TEXT DEFAULT 'in_progress' CHECK (test_status IN ('in_progress', 'completed', 'disputed')),
    screenshot_url TEXT,
    start_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(developer_id, app_id)
);

-- KARMA TRANSACTIONS
CREATE TABLE public.karma_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    amount INTEGER NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('credit', 'debit')),
    reason TEXT NOT NULL,
    reference_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. FUNCTIONS & RPCs

-- TRIGGER: Auto-create Profile
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'User'),
    COALESCE(new.raw_user_meta_data->>'avatar_url', new.raw_user_meta_data->>'picture')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- RPC: Complete Test
CREATE OR REPLACE FUNCTION public.complete_test_assignment(
    p_assignment_id UUID,
    p_screenshot_url TEXT
)
RETURNS VOID AS $$
DECLARE
    v_developer_id UUID;
    v_reward INTEGER;
    v_app_id UUID;
    v_start_date TIMESTAMP WITH TIME ZONE;
    v_required_days INTEGER;
    v_days_elapsed INTEGER;
BEGIN
    -- 1. Get assignment details and verify ownership
    SELECT developer_id, app_id, start_date 
    INTO v_developer_id, v_app_id, v_start_date 
    FROM public.test_assignments 
    WHERE id = p_assignment_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Assignment not found';
    END IF;

    -- SECURITY: Verify that the caller is the owner of the assignment
    IF v_developer_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: You are not the tester for this assignment';
    END IF;

    -- 2. Check if already completed to prevent double reward
    IF EXISTS (SELECT 1 FROM public.test_assignments WHERE id = p_assignment_id AND is_completed = true) THEN
        RAISE EXCEPTION 'This test assignment is already completed';
    END IF;

    -- 3. Get app details (reward and required duration)
    SELECT reward_credits, required_test_days 
    INTO v_reward, v_required_days 
    FROM public.apps 
    WHERE id = v_app_id;

    -- 4. SERVER-SIDE VALIDATION: Enforce minimum testing duration
    -- Calculate days elapsed. EXTRACT(DAY) gives full days.
    v_days_elapsed := EXTRACT(DAY FROM (now() - v_start_date));
    
    IF v_days_elapsed < v_required_days THEN
        RAISE EXCEPTION 'Verification Rejected: You must test this app for at least % days. Only % full days have passed.', v_required_days, v_days_elapsed;
    END IF;

    -- 5. Mark as completed
    UPDATE public.test_assignments
    SET is_completed = true, 
        test_status = 'completed', 
        screenshot_url = p_screenshot_url, 
        completed_at = now()
    WHERE id = p_assignment_id;

    -- 6. Award Karma credits to user profile
    UPDATE public.profiles SET credits = credits + v_reward WHERE id = v_developer_id;

    -- 7. Log the transaction for audit trail
    INSERT INTO public.karma_transactions (user_id, amount, type, reason, reference_id)
    VALUES (v_developer_id, v_reward, 'credit', 'Completed Testing', p_assignment_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: Create App Listing (10 Karma)
CREATE OR REPLACE FUNCTION public.create_app_listing(
    p_developer_id UUID,
    p_app_name TEXT,
    p_package_name TEXT,
    p_playstore_url TEXT,
    p_app_icon TEXT
)
RETURNS UUID AS $$
DECLARE
    v_balance INTEGER;
    v_app_id UUID;
    v_cost INTEGER := 10;
BEGIN
    SELECT credits INTO v_balance FROM public.profiles WHERE id = p_developer_id;
    IF v_balance < v_cost THEN
        RAISE EXCEPTION 'Insufficient Credits';
    END IF;

    UPDATE public.profiles SET credits = credits - v_cost WHERE id = p_developer_id;

    INSERT INTO public.apps (developer_id, app_name, package_name, playstore_url, app_icon)
    VALUES (p_developer_id, p_app_name, p_package_name, p_playstore_url, p_app_icon)
    RETURNING id INTO v_app_id;

    INSERT INTO public.karma_transactions (user_id, amount, type, reason, reference_id)
    VALUES (p_developer_id, v_cost, 'debit', 'Listed App', v_app_id);

    RETURN v_app_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RLS POLICIES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.test_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.karma_transactions ENABLE ROW LEVEL SECURITY;

-- PROFILES
DROP POLICY IF EXISTS "Profiles viewable by all" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own non-sensitive profile fields" ON profiles;
CREATE POLICY "Profiles viewable by all" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own non-sensitive profile fields" ON profiles 
FOR UPDATE 
TO authenticated
USING (auth.uid() = id)
WITH CHECK (
    auth.uid() = id 
    AND (
        -- Protect sensitive columns from being changed by the user
        credits = (SELECT p.credits FROM public.profiles p WHERE p.id = auth.uid())
        AND 
        role = (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid())
    )
);

-- APPS
DROP POLICY IF EXISTS "Apps viewable by all" ON apps;
DROP POLICY IF EXISTS "Developers manage own apps" ON apps;
CREATE POLICY "Apps viewable by all" ON apps FOR SELECT USING (true);
CREATE POLICY "Developers manage own apps" ON apps FOR ALL USING (auth.uid() = developer_id);

-- TEST ASSIGNMENTS
DROP POLICY IF EXISTS "Developers view own assignments" ON test_assignments;
DROP POLICY IF EXISTS "Developers join tests" ON test_assignments;
DROP POLICY IF EXISTS "Developers update own assignments" ON test_assignments;
CREATE POLICY "Developers view own assignments" ON test_assignments FOR SELECT USING (auth.uid() = developer_id);
CREATE POLICY "Developers join tests" ON test_assignments FOR INSERT WITH CHECK (auth.uid() = developer_id);
CREATE POLICY "Developers update own assignments" ON test_assignments FOR UPDATE USING (auth.uid() = developer_id);

-- KARMA TRANSACTIONS
DROP POLICY IF EXISTS "Users view own transactions" ON karma_transactions;
CREATE POLICY "Users view own transactions" ON karma_transactions FOR SELECT USING (auth.uid() = user_id);

-- 5. INDEXES
CREATE INDEX IF NOT EXISTS idx_profiles_name ON profiles (full_name);
CREATE INDEX IF NOT EXISTS idx_apps_name ON apps (app_name);
CREATE INDEX IF NOT EXISTS idx_test_assignments_developer ON test_assignments (developer_id);
CREATE INDEX IF NOT EXISTS idx_karma_tx_user ON karma_transactions (user_id);
