# UPI Payment Testing Guide

## ⚠️ Important: Razorpay Test Mode Limitations

### Why UPI Is Not Showing Up

**Razorpay's test mode does NOT fully support UPI payments.** This is a limitation of Razorpay's sandbox environment, not your code.

### What Works in Test Mode:

✅ **Credit/Debit Cards**
- Test Card: `4111 1111 1111 1111`
- CVV: Any 3 digits (e.g., `123`)
- Expiry: Any future date (e.g., `12/25`)
- Name: Any name

✅ **Netbanking**
- Select any bank
- Use test credentials provided by Razorpay

✅ **Wallets**
- Paytm, PhonePe, Google Pay (test mode)

❌ **UPI (Limited in Test Mode)**
- UPI does not appear or work properly in Razorpay test mode
- This is by design from Razorpay

---

## How to Enable Real UPI Testing

### Option 1: Switch to Live Mode (Recommended for Production)

1. **Complete KYC** on Razorpay Dashboard
   - Go to https://dashboard.razorpay.com
   - Settings → Account Details
   - Complete business verification

2. **Activate Live Mode**
   - Generate Live API keys
   - Update `.env` file with live keys:
     ```
     RAZORPAY_KEY_ID=rzp_live_your_key
     RAZORPAY_KEY_SECRET=your_live_secret
     ```

3. **Test with Small Amount**
   - Use real UPI ID
   - Test with ₹1 or ₹10
   - You'll be charged actual money

### Option 2: Use Razorpay's Payment Links (Test Mode)

Create a payment link from Razorpay Dashboard that supports UPI in test mode:
1. Dashboard → Payment Links
2. Create new link
3. This may show UPI option in test mode

---

## Current Implementation Features

### ✅ What's Working Now:

1. **Order-based payments** (better than subscriptions for mobile)
2. **Multiple payment methods** (Cards, Wallets, Netbanking)
3. **Payment cancellation** - Use back button in payment screen
4. **Error handling** - Shows proper error messages
5. **Backend API** - `/create-order` endpoint working
6. **Network configuration** - Set up for your real device

### 🔧 Payment Cancellation:

Users can cancel payment by:
- Tapping the back arrow (←) in the Razorpay payment screen
- Using device back button
- Closing the modal
- Error handler will show "Payment cancelled by user"

---

## Testing Instructions (Test Mode)

### Test with Credit Card:

1. Open app → Tap "Go Premium"
2. Tap "Subscribe Now"
3. Select **Cards**
4. Enter:
   ```
   Card Number: 4111 1111 1111 1111
   CVV: 123
   Expiry: 12/25
   Name: Test User
   ```
5. Payment will succeed in test mode

### Test Cancellation:

1. Open payment screen
2. Tap back arrow (←) at top left
3. App will show "Payment cancelled by user"

---

## Alternative: Direct UPI Intent (Advanced)

If you need UPI testing immediately, you can implement direct UPI intent:

```dart
// This would bypass Razorpay and directly open UPI apps
// But you lose Razorpay's payment tracking and verification
```

This requires additional implementation and is not recommended for production.

---

## Recommendation

**For Testing**: Use the test card method provided above. It fully validates your payment flow.

**For Production**: Complete Razorpay KYC and switch to live mode when ready to launch.

---

## Summary

✅ Your implementation is **correct**  
✅ Backend is **working properly**  
✅ Network configuration is **set up**  
❌ UPI not showing because **Razorpay test mode doesn't support it**

**Solution**: Use test cards for now, enable live mode for real UPI later.
