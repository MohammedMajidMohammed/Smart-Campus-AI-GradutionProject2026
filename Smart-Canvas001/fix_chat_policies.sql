-- Ensure chat_rooms table exists with proper structure
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL, -- 'private_admin_prof', 'college_group', etc.
    target_id TEXT NOT NULL, -- professor_id or college_id
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure chat_messages table exists
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    sender_name TEXT NOT NULL,
    content TEXT,
    attachment_url TEXT,
    attachment_type TEXT DEFAULT 'text',
    attachment_name TEXT,
    is_edited BOOLEAN DEFAULT FALSE,
    edited_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Policies for chat_rooms
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to manage rooms') THEN
        CREATE POLICY "Allow authenticated users to manage rooms" ON chat_rooms 
        FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;

-- Policies for chat_messages
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow authenticated users to manage messages') THEN
        CREATE POLICY "Allow authenticated users to manage messages" ON chat_messages 
        FOR ALL TO authenticated USING (true) WITH CHECK (true);
    END IF;
END $$;
