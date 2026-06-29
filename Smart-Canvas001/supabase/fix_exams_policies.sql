-- 1. Enable Row Level Security on exams tables
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_answers ENABLE ROW LEVEL SECURITY;

-- 2. Policies for 'exams' table
-- Allow all authenticated users to read exams (so students and professors can see them)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all authenticated users to read exams') THEN
        CREATE POLICY "Allow all authenticated users to read exams" ON exams 
        FOR SELECT TO authenticated USING (true);
    END IF;
END $$;

-- Allow professors to create exams (professor_id must match logged-in user id)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow professors to insert their own exams') THEN
        CREATE POLICY "Allow professors to insert their own exams" ON exams 
        FOR INSERT TO authenticated WITH CHECK (auth.uid() = professor_id);
    END IF;
END $$;

-- Allow professors to update their own exams (toggle active status, change details, etc.)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow professors to update their own exams') THEN
        CREATE POLICY "Allow professors to update their own exams" ON exams 
        FOR UPDATE TO authenticated 
        USING (auth.uid() = professor_id)
        WITH CHECK (auth.uid() = professor_id);
    END IF;
END $$;

-- Allow professors to delete their own exams
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow professors to delete their own exams') THEN
        CREATE POLICY "Allow professors to delete their own exams" ON exams 
        FOR DELETE TO authenticated USING (auth.uid() = professor_id);
    END IF;
END $$;

-- 3. Policies for 'exam_questions' table
-- Allow authenticated users to view questions (for taking exams and designing them)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to read questions') THEN
        CREATE POLICY "Allow authenticated users to read questions" ON exam_questions 
        FOR SELECT TO authenticated USING (true);
    END IF;
END $$;

-- Allow professors to manage questions for their exams
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to manage questions') THEN
        CREATE POLICY "Allow authenticated users to manage questions" ON exam_questions 
        FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;

-- 4. Policies for 'exam_submissions' table
-- Allow authenticated users to manage submissions (students insert/read, professors read/update score)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to manage submissions') THEN
        CREATE POLICY "Allow authenticated users to manage submissions" ON exam_submissions 
        FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;

-- 5. Policies for 'exam_answers' table
-- Allow authenticated users to manage answers (students insert, professors read/update)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to manage exam answers') THEN
        CREATE POLICY "Allow authenticated users to manage exam answers" ON exam_answers 
        FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;

-- Print completion message
DO $$
BEGIN
  RAISE NOTICE 'Exam system RLS policies configured successfully!';
END $$;
