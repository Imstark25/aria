const Razorpay = require('razorpay');
require('dotenv').config();

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
});

async function testRazorpay() {
    try {
        console.log("Testing authentication...");
        // Fetch payments to test auth (limit 1)
        const payments = await razorpay.payments.all({ count: 1 });
        console.log("Authentication successful. Payments found:", payments.count);

        console.log("Testing Plan Creation...");
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
        console.log("Plan created successfully:", plan.id);

        console.log("Testing Subscription Creation...");
        const sub = await razorpay.subscriptions.create({
            plan_id: plan.id,
            total_count: 6,
            quantity: 1,
            customer_notify: 0
        });
        console.log("Subscription created successfully:", sub.id);

    } catch (error) {
        console.error("Razorpay Error:", error);
    }
}

testRazorpay();
