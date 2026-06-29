-- 1. Enable Realtime on the supabase_realtime publication for all relevant tables
-- Each check is wrapped dynamically using EXECUTE so that PostgreSQL does not compile
-- statements for tables that do not exist in the database.

-- Check and add 'users' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'users'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE users';
    END IF;
  END IF;
END $$;

-- Check and add 'profiles' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'profiles'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE profiles';
    END IF;
  END IF;
END $$;

-- Check and add 'exams' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'exams') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'exams'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE exams';
    END IF;
  END IF;
END $$;

-- Check and add 'exam_submissions' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'exam_submissions') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'exam_submissions'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE exam_submissions';
    END IF;
  END IF;
END $$;

-- Check and add 'exam_answers' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'exam_answers') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'exam_answers'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE exam_answers';
    END IF;
  END IF;
END $$;

-- Check and add 'assignments' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assignments') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'assignments'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE assignments';
    END IF;
  END IF;
END $$;

-- Check and add 'broadcast_assignments' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'broadcast_assignments') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'broadcast_assignments'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE broadcast_assignments';
    END IF;
  END IF;
END $$;

-- Check and add 'online_sessions' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'online_sessions') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'online_sessions'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE online_sessions';
    END IF;
  END IF;
END $$;

-- Check and add 'chat_messages' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'chat_messages') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages';
    END IF;
  END IF;
END $$;

-- Check and add 'subject_messages' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'subject_messages') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'subject_messages'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE subject_messages';
    END IF;
  END IF;
END $$;

-- Check and add 'polls' table
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'polls') THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'polls'
    ) THEN
      EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE polls';
    END IF;
  END IF;
END $$;

-- 2. Set replica identity to FULL for tables where we need to compare old vs new records in realtime
-- Wrapped in dynamic EXECUTE checks so it only runs on existing tables.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'exams') THEN
    EXECUTE 'ALTER TABLE exams REPLICA IDENTITY FULL';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'exam_submissions') THEN
    EXECUTE 'ALTER TABLE exam_submissions REPLICA IDENTITY FULL';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'assignments') THEN
    EXECUTE 'ALTER TABLE assignments REPLICA IDENTITY FULL';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'online_sessions') THEN
    EXECUTE 'ALTER TABLE online_sessions REPLICA IDENTITY FULL';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'chat_messages') THEN
    EXECUTE 'ALTER TABLE chat_messages REPLICA IDENTITY FULL';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'subject_messages') THEN
    EXECUTE 'ALTER TABLE subject_messages REPLICA IDENTITY FULL';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'polls') THEN
    EXECUTE 'ALTER TABLE polls REPLICA IDENTITY FULL';
  END IF;
END $$;

-- Print completion message
DO $$
BEGIN
  RAISE NOTICE 'Realtime replication and Replica Identities configured dynamically and safely!';
END $$;
