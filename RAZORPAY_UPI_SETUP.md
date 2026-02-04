# Razorpay UPI Mobile Testing Guide

## Changes Made

### 1. API Server (api/server.js)
- ✅ Added `/create-order` endpoint for creating Razorpay orders
- Orders work better with UPI payments on mobile compared to subscriptions
- Supports one-time payments which is ideal for testing

### 2. Flutter App (lib/subscription_page.dart)
- ✅ Updated to use `order_id` instead of `subscription_id`
- ✅ Enabled UPI payment method explicitly
- ✅ Added support for multiple payment methods (UPI, Card, Net Banking, Wallet)
- ✅ Improved payment flow configuration for mobile devices

### 3. Configuration (lib/config.dart)
- ✅ Created centralized config for easy switching between emulator and real device
- Default: `10.0.2.2` for Android Emulator
- For real device: Update to your PC's IP address

## Setup Instructions

### Step 1: Configure Razorpay Keys
Make sure you have a `.env` file in the `api/` folder:
```
RAZORPAY_KEY_ID=rzp_test_your_key_here
RAZORPAY_KEY_SECRET=your_secret_here
```

### Step 2: Start the Backend Server
```bash
cd api
npm install
npm start
```
Server will run on `http://0.0.0.0:3000`

### Step 3: Configure Network URL

#### For Android Emulator:
No changes needed. The default config uses `10.0.2.2:3000`

#### For Real Android Device:
1. Find your PC's IP address:
   - Windows: Run `ipconfig` in Command Prompt
   - Look for "IPv4 Address" (e.g., 192.168.1.5)
   
2. Update `lib/config.dart`:
   ```dart
   static const String baseUrl = 'http://YOUR_PC_IP:3000';
   // Example: 'http://192.168.1.5:3000'
   ```

3. **Important**: Make sure your PC and phone are on the same WiFi network!

### Step 4: Run the Flutter App
```bash
flutter run
```

### Step 5: Test Payment
1. Open the app
2. Tap "Go Premium" button
3. Tap "Subscribe Now"
4. Select UPI as payment method
5. Use Razorpay test UPI ID: `success@razorpay`
6. Complete the payment

## Test UPI IDs (Razorpay Test Mode)

| UPI ID | Result |
|--------|--------|
| `success@razorpay` | Payment succeeds |
| `failure@razorpay` | Payment fails |

## Troubleshooting

### Issue: "Backend API Failed" or Connection Error
**Solution**: 
- For Emulator: Ensure backend is running and URL is `http://10.0.2.2:3000/create-order`
- For Real Device: 
  - Check PC and phone are on same WiFi
  - Verify PC's IP address in config.dart
  - Check Windows Firewall allows port 3000

### Issue: UPI not showing up in payment options
**Solution**:
- This code now explicitly enables UPI in the payment configuration
- Make sure you're using the updated code with `order_id` (not `subscription_id`)

### Issue: Payment succeeds but nothing happens
**Solution**:
- Check console logs in the app
- Verify the payment handlers in subscription_page.dart
- Success handler shows a SnackBar with payment ID

## Network Firewall Rule (Windows)

If real device can't connect, allow port 3000:
```powershell
# Run as Administrator
netsh advfirewall firewall add rule name="Node API Server" dir=in action=allow protocol=TCP localport=3000
```

## Testing Checklist

- [ ] Backend server is running on port 3000
- [ ] .env file has valid Razorpay test keys
- [ ] For real device: Updated config.dart with PC's IP
- [ ] PC and phone on same WiFi network
- [ ] Windows Firewall allows port 3000
- [ ] App successfully calls `/create-order` endpoint
- [ ] UPI option appears in payment methods
- [ ] Test payment with `success@razorpay` works

## Key Differences: Orders vs Subscriptions

| Feature | Subscriptions | Orders |
|---------|--------------|--------|
| Payment Type | Recurring | One-time |
| UPI Support | Limited | Full |
| Mobile Support | Average | Excellent |
| Testing | Complex | Simple |
| Best For | Recurring billing | One-time payments, testing |

This implementation now uses **Orders** for better UPI compatibility on mobile devices!
