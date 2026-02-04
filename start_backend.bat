@echo off
echo ========================================
echo  Razorpay Test API Server Setup
echo ========================================
echo.

cd api

echo Checking for .env file...
if not exist .env (
    echo.
    echo WARNING: .env file not found!
    echo.
    echo Please create a .env file in the api folder with:
    echo RAZORPAY_KEY_ID=rzp_test_your_key_here
    echo RAZORPAY_KEY_SECRET=your_secret_here
    echo.
    pause
    exit /b 1
)

echo .env file found!
echo.

echo Installing dependencies...
call npm install
echo.

echo Starting server on http://0.0.0.0:3000
echo.
echo ========================================
echo  Server Information
echo ========================================
echo For Android Emulator: Use http://10.0.2.2:3000
echo For Real Device: Find your IP with 'ipconfig'
echo.

ipconfig | findstr /i "IPv4"

echo.
echo Update lib/config.dart with the IP address above
echo if testing on a real device!
echo ========================================
echo.

call npm start
