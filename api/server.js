const express = require('express');
const Razorpay = require('razorpay');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(express.static('public'));
app.use(express.json());
app.use(cors());

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET
});

app.post('/create-subscription', async (req, res) => {
    try {
        // Create a dummy plan for testing purposes
        const plan = await razorpay.plans.create({
            period: "monthly",
            interval: 1,
            item: {
                name: "Premium Subscription",
                amount: 50000, // Amount in paise (500 INR)
                currency: "INR",
                description: "Access to premium features"
            }
        });

        // Create a Subscription
        const subscription = await razorpay.subscriptions.create({
            plan_id: plan.id,
            total_count: 12,
            quantity: 1,
            customer_notify: 1,
        });

        res.json({
            subscription_id: subscription.id,
            key_id: process.env.RAZORPAY_KEY_ID
        });
    } catch (error) {
        console.error("Error creating subscription:", error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/', (req, res) => {
    res.send('Razorpay Server is Running');
});

const PORT = 3000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
});
