import { useState } from "react";
import { useNavigate } from "react-router";
import Label from "../form/Label";
import Input from "../form/input/InputField";
import Button from "../ui/button/Button";
import { sendSMSOTP, verifySMSOTP } from "./smsOtpApi";
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

export default function SMSOTPForm() {
  const [step, setStep] = useState<'phone' | 'otp'>('phone');
  const [phoneNumber, setPhoneNumber] = useState("");
  const [otp, setOtp] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [maskedPhone, setMaskedPhone] = useState("");
  const [remainingAttempts, setRemainingAttempts] = useState<number | null>(null);
  const navigate = useNavigate();

  const handleSendOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!phoneNumber) {
      toast.error("Please enter your phone number");
      return;
    }

    // Basic phone number validation
    if (!phoneNumber.startsWith('+')) {
      toast.error("Please enter phone number with country code (e.g., +919876543210)");
      return;
    }

    setIsLoading(true);
    
    try {
      const result = await sendSMSOTP({ phone_number: phoneNumber });
      
      if (result.success) {
        toast.success(result.message || 'OTP sent successfully! Check your phone.');
        setMaskedPhone(result.phone_number || phoneNumber);
        setStep('otp');
      } else {
        toast.error(result.error || 'Failed to send OTP');
      }
    } catch (error) {
      toast.error('Network error. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!otp) {
      toast.error("Please enter the OTP");
      return;
    }

    if (otp.length !== 6) {
      toast.error("OTP must be 6 digits");
      return;
    }

    setIsLoading(true);
    
    try {
      const result = await verifySMSOTP({ 
        phone_number: phoneNumber, 
        otp: otp 
      });
      
      if (result.success) {
        toast.success(result.message || 'Login successful! Redirecting...');
        
        // Redirect based on user role (same logic as SignInForm)
        if(result.userRole === 'reconciliation') {
          setTimeout(() => {
            navigate("/admin/master-dashboard");
          }, 1000);
        } else {
          setTimeout(() => {
            navigate("/admin/master-dashboard");
          }, 1000);
        }
      } else {
        toast.error(result.error || 'Invalid OTP');
        
        // Show remaining attempts if available
        if (result.remaining_attempts !== undefined) {
          setRemainingAttempts(result.remaining_attempts);
          if (result.remaining_attempts === 0) {
            toast.error('Maximum attempts exceeded. Please request a new OTP.');
            setStep('phone');
            setOtp('');
          }
        }
      }
    } catch (error) {
      toast.error('Network error. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleBackToPhone = () => {
    setStep('phone');
    setOtp('');
    setRemainingAttempts(null);
  };

  const handleResendOTP = async () => {
    setIsLoading(true);
    try {
      const result = await sendSMSOTP({ phone_number: phoneNumber });
      
      if (result.success) {
        toast.success(result.message || 'New OTP sent successfully!');
        setOtp('');
        setRemainingAttempts(null);
      } else {
        toast.error(result.error || 'Failed to resend OTP');
      }
    } catch (error) {
      toast.error('Network error. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div>
          <h2 className="mt-6 text-center text-3xl font-extrabold text-gray-900">
            {step === 'phone' ? 'SMS Authentication' : 'Verify OTP'}
          </h2>
          <p className="mt-2 text-center text-sm text-gray-600">
            {step === 'phone' 
              ? 'Enter your authorized mobile number to receive OTP' 
              : `Enter the 6-digit code sent to ${maskedPhone}`
            }
          </p>
        </div>

        <div className="mt-8 space-y-6">
          {step === 'phone' ? (
            <form onSubmit={handleSendOTP} className="space-y-6">
              <div>
                <Label htmlFor="phone">Mobile Number</Label>
                <Input
                  id="phone"
                  type="tel"
                  value={phoneNumber}
                  onChange={(e) => setPhoneNumber(e.target.value)}
                  placeholder="+919876543210"
                  className="mt-1"
                  required
                />
                <p className="mt-1 text-xs text-gray-500">
                  Include country code (e.g., +91 for India)
                </p>
              </div>

              <Button
                type="submit"
                variant="primary"
                size="md"
                className="w-full"
                disabled={isLoading}
              >
                {isLoading ? (
                  <div className="flex items-center justify-center">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Sending OTP...
                  </div>
                ) : (
                  'Send OTP'
                )}
              </Button>
            </form>
          ) : (
            <form onSubmit={handleVerifyOTP} className="space-y-6">
              <div>
                <Label htmlFor="otp">Enter OTP</Label>
                <Input
                  id="otp"
                  type="text"
                  value={otp}
                  onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                  placeholder="123456"
                  className="mt-1 text-center text-2xl tracking-widest"
                  required
                />
                {remainingAttempts !== null && (
                  <p className="mt-1 text-xs text-orange-600">
                    {remainingAttempts} attempts remaining
                  </p>
                )}
              </div>

              <Button
                type="submit"
                variant="primary"
                size="md"
                className="w-full"
                disabled={isLoading || otp.length !== 6}
              >
                {isLoading ? (
                  <div className="flex items-center justify-center">
                    <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Verifying...
                  </div>
                ) : (
                  'Verify OTP'
                )}
              </Button>

              <div className="flex space-x-4">
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="flex-1"
                  onClick={handleBackToPhone}
                  disabled={isLoading}
                >
                  Change Number
                </Button>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="flex-1"
                  onClick={handleResendOTP}
                  disabled={isLoading}
                >
                  Resend OTP
                </Button>
              </div>
            </form>
          )}

          <div className="text-center">
            <p className="text-sm text-gray-600">
              Having trouble? Contact support
            </p>
          </div>
        </div>
      </div>
      
      <ToastContainer
        position="top-right"
        autoClose={5000}
        hideProgressBar={false}
        newestOnTop={false}
        closeOnClick
        rtl={false}
        pauseOnFocusLoss
        draggable
        pauseOnHover
      />
    </div>
  );
}
