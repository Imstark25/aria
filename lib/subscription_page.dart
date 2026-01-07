import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late Razorpay _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful: ${response.paymentId}")),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${response.code} - ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  Future<void> _startPayment() async {
    setState(() => _isLoading = true);

    try {
      // 1. Call your Node.js backend to create order/subscription
      // Use 10.0.2.2 for Android Emulator to access localhost of the host machine
      // Use localhost or your IP if running on real device/web
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/create-subscription'), 
        // Note: For real device, replace 10.0.2.2 with your PC's IP address (e.g. 192.168.1.5)
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        var options = {
          'key': data['key_id'],
          'subscription_id': data['subscription_id'],
          'name': 'Demo App',
          'description': 'Monthly Premium Subscription',
          'prefill': {
            'contact': '9123456789',
            'email': 'test@razorpay.com'
          },
          'theme': {
            'color': '#FF6B6B' 
          }
        };

        _razorpay.open(options);
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Backend API Failed: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Premium Plan"),
        backgroundColor: Colors.transparent,
        elevation: 0,
         iconTheme: const IconThemeData(color: Colors.white),
           titleTextStyle: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
      body: Stack(
        children: [
          // Background (Reusing same style as main)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
               gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
               ),
            ),
          ),
          
          Center(
            child: _buildGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                     child: Chip(
                       label: Text("MOST POPULAR", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                       backgroundColor: Color(0xFFFF6B6B),
                       padding: EdgeInsets.zero,
                       visualDensity: VisualDensity.compact,
                     ),
                  ),
                  const Text(
                    "Premium Plan",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text("₹500", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
                   const Text("/month", style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 30),
                  
                  _buildFeature(Icons.check, "Unlimited Access"),
                  _buildFeature(Icons.check, "4K Streaming"),
                  _buildFeature(Icons.check, "Ad-free Experience"),
                  _buildFeature(Icons.check, "Offline Downloads"),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Subscribe Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                   const SizedBox(height: 15),
                  const Text(
                    "Cancel anytime. Terms apply.",
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(30),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
