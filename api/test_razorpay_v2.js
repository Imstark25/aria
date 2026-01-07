const Razorpay = require('razorpay');
require('dotenv').config();

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
});

async function testRazorpay() {
    try {
        console.log("Key ID:", process.env.RAZORPAY_KEY_ID);
        // console.log("Key Secret:", process.env.RAZORPAY_KEY_SECRET); // Don't log secret

        console.log("1. Testing Authentication (Fetch Orders)...");
        try {
            // Try fetching orders instead of payments, sometimes easier for empty accounts
            const orders = await razorpay.orders.all({ count: 1 });
            console.log("   Auth Success! Orders found:", orders.count);
        } catch (e) {
            console.log("   Auth Check Failed (Orders):", e.error ? e.error.description : e.message);
        }

        console.log("2. Testing Plan Creation...");
        const plan = await razorpay.plans.create({
            period: "monthly",
            interval: 1,
            item: {
                name: "Test Plan " + Date.now(),
                amount: 50000,
                currency: "INR",
                description: "Test Description"
            }
        });
        console.log("   Plan Created:", plan.id);

        console.log("3. Testing Subscription Creation...");
        const sub = await razorpay.subscriptions.create({
            plan_id: plan.id,
            total_count: 6,
            quantity: 1,
            customer_notify: 0
        });
        console.log("   Subscription Created:", sub.id);

    } catch (error) {
        console.error("CRITICAL ERROR:", JSON.stringify(error, null, 2));
    }
}

testRazorpay();
