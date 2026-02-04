import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'config.dart';

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
    String errorMessage = "Error: ${response.code} - ${response.message}";
    
    // Check if user cancelled
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      errorMessage = "Payment cancelled by user";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showPaymentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("UPI Test Mode Info"),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "⚠️ Razorpay Test Mode Limitations:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text("• UPI is NOT fully supported in test mode"),
              Text("• Use Cards, Netbanking, or Wallets for testing"),
              SizedBox(height: 15),
              Text(
                "Test Cards (All work):",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text("Card: 4111 1111 1111 1111"),
              Text("CVV: Any 3 digits"),
              Text("Expiry: Any future date"),
              SizedBox(height: 15),
              Text(
                "For Real UPI Testing:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text("1. Switch to Live Mode in Razorpay Dashboard"),
              Text("2. Complete KYC verification"),
              Text("3. Use actual UPI ID"),
              SizedBox(height: 15),
              Text(
                "To Cancel Payment:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text("• Tap the back button in payment screen"),
              Text("• Or use device back button"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
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
      // Call your Node.js backend to create order
      // URL is configured in lib/config.dart
      // Change it there when switching between emulator and real device
      
      final response = await http.post(
        Uri.parse(AppConfig.createOrderUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': 50000}), // 500 INR in paise
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Configure options for order-based payment with UPI support
        var options = {
          'key': data['key_id'],
          'amount': data['amount'], // Amount in paise
          'currency': data['currency'],
          'order_id': data['order_id'],
          'name': 'Volume Master',
          'description': 'Premium Subscription - Monthly',
          'prefill': {
            'contact': '9123456789',
            'email': 'test@razorpay.com'
          },
          'theme': {
            'color': '#FF6B6B' 
          },
          // Allow retry on payment failure
          'retry': {
            'enabled': true,
            'max_count': 3
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
                  const SizedBox(height: 10),
                  // Info button
                  TextButton.icon(
                    onPressed: _showPaymentInfo,
                    icon: const Icon(Icons.info_outline, color: Colors.white70, size: 18),
                    label: const Text(
                      "Payment Test Info & UPI Limitations",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 5),
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
