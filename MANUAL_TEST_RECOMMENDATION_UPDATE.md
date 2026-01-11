# Quick Test: Manual Detection Save & Recommendation Update

## Problem
Your detection server at `http://172.20.10.3:5000` is not running or not accessible.

**Error logs:**
```
Connection closed while receiving data, uri=http://172.20.10.3:5000/latest_detection
```

This means:
- ❌ No detections fetched from server
- ❌ No detections saved to database
- ❌ Nothing to update with recommendation

---

## Quick Solution: Manual Test

### Step 1: Directly insert a detection in Supabase

Go to **Supabase Console** → **SQL Editor** and run:

```sql
INSERT INTO detections (label, confidence, solution, timestamp)
VALUES ('Powdery Mildew', 0.87, '', NOW())
RETURNING id, label, confidence, solution, timestamp;
```

You should see output like:
```
id: 123
label: "Powdery Mildew"
confidence: 0.87
solution: ""
timestamp: 2026-01-11 10:30:00
```

Copy the **ID number** (e.g., 123)

---

### Step 2: Run the app and click "Get Recommendation"

```bash
flutter run
```

1. Navigate to the screen with the recommendation button
2. Click "Get Recommendation"
3. Wait for AI to generate recommendation

---

### Step 3: Check the logs

Look for these messages:
```
🔍 Updating last detection for "Powdery Mildew" with recommendation
✅ Found detection ID: 123
✅✅ CONFIRMED: Detection 123 successfully updated in database!
```

---

### Step 4: Verify in Supabase

Go back to SQL Editor and run:

```sql
SELECT id, label, confidence, solution, updated_at 
FROM detections 
WHERE id = 123;
```

You should see:
```
id: 123
label: "Powdery Mildew"
confidence: 0.87
solution: "Apply fungicide XYZ..." (NOW FILLED!)
updated_at: 2026-01-11 10:35:00 (NOW UPDATED!)
```

If you see the `solution` field filled, then ✅ **the update is working!**

---

## If Update Still Doesn't Work

The logs will show one of these:

### Error 1: "No detections found in database at all"
- **Cause:** Your manual INSERT didn't work
- **Solution:** Check if the INSERT query executed successfully in Supabase

### Error 2: "No exact match for label"
- **This is OK** - the code will use the latest detection instead
- Check logs for "Found latest detection with different label"

### Error 3: "UPDATE VERIFICATION FAILED"
- **Cause:** Supabase RLS policy blocks UPDATE
- **Solution:** Run this in SQL Editor to allow updates:
```sql
CREATE POLICY "Enable update for all users" ON detections
FOR UPDATE USING (true) WITH CHECK (true);
```

---

## Fix Your Detection Server (Longer Term)

Your detection server needs to be running and accessible at:
```
http://172.20.10.3:5000/latest_detection
```

**Check:**
1. Is your detection server running on that IP/port?
2. Can you access it from your phone/emulator?
3. Is the firewall blocking the port?
4. Check `.env` file for correct `DETECTION_SERVER_URL`

Once the server is running:
- App will fetch detections automatically
- Detections will save to database
- You can update with recommendations

---

## What to Do Now

1. ✅ Manually insert a detection in Supabase
2. ✅ Click "Get Recommendation" in the app
3. ✅ Check logs for "CONFIRMED" message
4. ✅ Verify the record updated in Supabase

Once this works, we know the **database update logic is correct** and the issue is just the detection server connection.

---

## Need Help?

Share:
1. Output from manual SQL INSERT
2. Logs when you click "Get Recommendation"
3. Output from the verification SQL query

I can then tell you exactly what's wrong! 🔍
