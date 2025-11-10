# Admin Portal Access Guide

## 🔐 Step 1: Create Your Admin Account

### Via Firebase Console (5 minutes)

1. **Open Firebase Console:** https://console.firebase.google.com
2. **Select project:** itracelink-8c4ea
3. **Go to Firestore Database**

4. **Create admin collection:**
   - Click "Start collection"
   - Collection ID: `admins`
   - Click "Next"

5. **Add your admin document:**
   - Document ID: **Your email** (e.g., `kazerenoir49@gmail.com`)
   - Add fields:
     ```
     email: "kazerenoir49@gmail.com"
     name: "Your Name"
     role: "super_admin"
     isActive: true
     createdAt: (Use server timestamp)
     permissions: ["verify_users", "manage_users", "view_reports"]
     ```
   - Click "Save"

6. **Create Authentication account:**
   - Go to **Authentication** → **Users**
   - Click "Add user"
   - Email: Same as above (e.g., kazerenoir49@gmail.com)
   - Password: **Choose a strong password**
   - Click "Add user"

---

## 🌐 Step 2: Access Admin Portal

### Option A: Direct URL (When app is running)
```
http://localhost:53183/admin
```

### Option B: Via Browser DevTools
1. Open your app in Chrome
2. Press F12 (open DevTools)
3. In Console, type:
   ```javascript
   window.location.href = '/admin'
   ```
4. Press Enter

---

## 📋 Step 3: Login and Verify Users

1. **Login** with your admin credentials
2. You'll see the **Admin Dashboard**
3. **Pending tab** shows unverified users
4. For each user, you can:
   - ✅ **Verify** - Click green "Verify" button
   - ❌ **Reject** - Click red "Reject" button
5. **Verified tab** shows all verified users

---

## 🎯 Quick Setup Summary

```bash
# 1. Open app in Chrome
flutter run -d chrome

# 2. Create admin in Firebase Console
# 3. Navigate to: http://localhost:53183/admin
# 4. Login and start verifying!
```

---

## 🔒 Security Notes

- Only emails in the `admins` collection can access admin portal
- Regular users trying to access will be denied
- Always use strong passwords
- Don't share admin credentials

---

## 📊 Admin Capabilities

### Super Admin Can:
- ✅ Verify/reject any user
- ✅ View all users (pending & verified)
- ✅ See user details (email, phone, type, registration date)
- ✅ Track verification history
- 🔄 More features coming in Phase 2

---

## ⚡ Quick Test

**Test Account (for development):**
```
Email: admin@itracelink.com
Password: Admin123! (Set this in Firebase Auth)

Add this to Firestore → admins collection
```

---

## 🐛 Troubleshooting

**"Access denied"?**
- Check email matches exactly in both Auth and Firestore
- Check `isActive` is `true` in Firestore
- Check you're logging in with correct password

**Can't see pending users?**
- Make sure test users have `isVerified: false`
- Check Firestore rules allow admins to read users collection

**Page won't load?**
- Make sure app is running (`flutter run -d chrome`)
- Check URL is correct: `/admin` route
- Check Firebase is initialized (no errors in console)

---

## 📞 Next Steps

After creating your admin account:
1. Test verifying your test account (kazerenoir49@gmail.com)
2. Create more test users with different user types
3. Practice verifying them
4. Ready for production use!
