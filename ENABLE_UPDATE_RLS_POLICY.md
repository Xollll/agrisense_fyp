# Fix: Enable UPDATE Permission in Supabase RLS

## The Problem
Your Supabase `detections` table doesn't have an **UPDATE policy**, so the app cannot update the `solution` field.

---

## The Fix: Add UPDATE Policy to Supabase

### Step 1: Go to Supabase Console
1. Open: https://supabase.com/dashboard
2. Select your project
3. Go to: **SQL Editor** (left sidebar)

### Step 2: Run This SQL Query

Copy and paste this **exactly as is**:

```sql
-- Create UPDATE policy for detections table
CREATE POLICY "Enable update for all users" ON public.detections
FOR UPDATE
USING (true)
WITH CHECK (true);
```

Then click **Run** button (or press Ctrl+Enter)

---

## Verify the Policy Was Created

Run this query to confirm:

```sql
-- Check all policies on detections table
SELECT * FROM pg_policies 
WHERE tablename = 'detections';
```

You should see output showing:
- `policyname: Enable update for all users`
- `cmd: UPDATE`
- `qual: true`
- `with_check: true`

---

## Test It Now

### Step 1: Go back to your app
```bash
flutter run
```

### Step 2: Click "Get Recommendation"

### Step 3: Check logs for:
```
✅ Direct update executed without error
✅✅ CONFIRMED: Detection updated in database!
```

If you see "CONFIRMED" → ✅ **It's working!**

---

## If You Still Get "solution field is still empty"

Try this alternative policy (more permissive):

```sql
-- Drop old policy first (if needed)
DROP POLICY IF EXISTS "Enable update for all users" ON public.detections;

-- Create new policy
CREATE POLICY "Enable unrestricted updates" ON public.detections
FOR UPDATE USING (true) WITH CHECK (true);
```

Then test the app again.

---

## Complete RLS Setup (Optional - Recommended)

If you want all operations to work (INSERT, SELECT, UPDATE, DELETE), run:

```sql
-- Allow all INSERT operations
CREATE POLICY "Enable insert for all users" ON public.detections
FOR INSERT WITH CHECK (true);

-- Allow all SELECT operations
CREATE POLICY "Enable select for all users" ON public.detections
FOR SELECT USING (true);

-- Allow all UPDATE operations
CREATE POLICY "Enable update for all users" ON public.detections
FOR UPDATE USING (true) WITH CHECK (true);

-- Allow all DELETE operations
CREATE POLICY "Enable delete for all users" ON public.detections
FOR DELETE USING (true);
```

Run these **one by one** or all together.

---

## What This Does

- **INSERT**: Allows saving new detections ✅ (already working)
- **SELECT**: Allows reading detections ✅ (already working)
- **UPDATE**: Allows updating `solution` field ❌ (THIS WAS MISSING)
- **DELETE**: Allows deleting detections

---

## After Adding the Policy

Your app will be able to:
1. ✅ Save detections automatically
2. ✅ Update with recommendation when you click the button
3. ✅ View all detections in history
4. ✅ Delete detections from history

---

## Quick Checklist

- [ ] Opened Supabase Console
- [ ] Went to SQL Editor
- [ ] Copied the UPDATE policy SQL
- [ ] Ran the SQL query
- [ ] Verified the policy exists
- [ ] Ran the app
- [ ] Clicked "Get Recommendation"
- [ ] Saw "CONFIRMED" in logs

Once you see "CONFIRMED", **everything is working!** 🎉
