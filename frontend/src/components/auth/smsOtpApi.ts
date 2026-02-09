import { jwtDecode } from 'jwt-decode';
import { createApiUrl } from '../../access/api.ts';

// Types for the SMS OTP API
interface SendOTPData {
  phone_number: string;
}

interface VerifyOTPData {
  phone_number: string;
  otp: string;
}

interface ApiResponse {
  success: boolean;
  status?: string;
  message?: string;
  data?: any;
  error?: string;
  details?: any;
}

interface SMSOTPResponse extends ApiResponse {
  phone_number?: string;
  access_token?: string;
  refresh_token?: string;
  user?: {
    id: number;
    username: string;
    role: string;
    phone_number: string;
  };
  remaining_attempts?: number;
  userRole?: string;
}

// Send OTP to phone number
export const sendSMSOTP = async (otpData: SendOTPData): Promise<SMSOTPResponse> => {
  try {
    console.log('Attempting to send OTP with data:', otpData);
    console.log('API URL:', createApiUrl('/sms-otp/send/'));
    
    const response = await fetch(createApiUrl('/sms-otp/send/'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(otpData),
    });

    console.log('Response status:', response.status);
    console.log('Response headers:', response.headers);

    const data = await response.json();
    console.log('Response data:', data);

    if (response.ok) {
      return {
        success: true,
        data: data,
        message: data.message || 'OTP sent successfully',
        phone_number: data.phone_number
      };
    } else {
      return {
        success: false,
        error: data.error || 'Failed to send OTP',
        details: data.error
      };
    }
  } catch (error: any) {
    console.error('Send OTP API Error:', error);
    console.error('Error details:', {
      name: error.name,
      message: error.message,
      stack: error.stack
    });
    return {
      success: false,
      error: `Network error occurred: ${error.message}`,
      details: error.message
    };
  }
};

// Verify OTP and get authentication tokens
export const verifySMSOTP = async (verifyData: VerifyOTPData): Promise<SMSOTPResponse> => {
  try {
    console.log('Attempting to verify OTP with data:', verifyData);
    console.log('API URL:', createApiUrl('/sms-otp/verify/'));
    
    const response = await fetch(createApiUrl('/sms-otp/verify/'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(verifyData),
    });

    console.log('Response status:', response.status);
    console.log('Response headers:', response.headers);

    const data = await response.json();
    console.log('Response data:', data);

    if (response.ok) {
      // Store tokens in localStorage using same keys as signin
      // Updated to handle nested tokens structure
      const accessToken = data.tokens?.access || data.access_token;
      const refreshToken = data.tokens?.refresh || data.refresh_token;
      
      if (accessToken) {
        localStorage.setItem('access', accessToken);
        console.log('Access token stored in localStorage');
      }
      if (refreshToken) {
        localStorage.setItem('refresh', refreshToken);
        console.log('Refresh token stored in localStorage');
      }
      
      // Decode JWT to get user role (same as signin)
      let userRole = 'admin'; // default to admin
      if (accessToken) {
        try {
          const decodedToken = jwtDecode<{ role: string }>(accessToken);
          userRole = decodedToken.role;
          console.log('Decoded user role from JWT:', userRole);
        } catch (error) {
          console.error('Error decoding JWT:', error);
          // fallback to user data role if JWT decode fails
          userRole = data.user?.role || 'admin';
        }
      }

      return {
        success: true,
        data: data,
        message: data.message || 'OTP verified successfully',
        access_token: accessToken,
        refresh_token: refreshToken,
        user: data.user,
        userRole: userRole
      };
    } else {
      return {
        success: false,
        error: data.error || 'Failed to verify OTP',
        details: data.error,
        remaining_attempts: data.remaining_attempts
      };
    }
  } catch (error: any) {
    console.error('Verify OTP API Error:', error);
    console.error('Error details:', {
      name: error.name,
      message: error.message,
      stack: error.stack
    });
    return {
      success: false,
      error: `Network error occurred: ${error.message}`,
      details: error.message
    };
  }
};

// Check OTP status (optional - for debugging)
export const checkOTPStatus = async (phone_number: string): Promise<ApiResponse> => {
  try {
    console.log('Checking OTP status for phone:', phone_number);
    console.log('API URL:', createApiUrl(`/sms-otp/status/?phone_number=${encodeURIComponent(phone_number)}`));
    
    const response = await fetch(createApiUrl(`/sms-otp/status/?phone_number=${encodeURIComponent(phone_number)}`), {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    console.log('Response status:', response.status);
    
    const data = await response.json();
    console.log('OTP Status data:', data);

    if (response.ok) {
      return {
        success: true,
        data: data,
        message: 'OTP status retrieved successfully'
      };
    } else {
      return {
        success: false,
        error: data.error || 'Failed to check OTP status',
        details: data.error
      };
    }
  } catch (error: any) {
    console.error('Check OTP Status API Error:', error);
    console.error('Error details:', {
      name: error.name,
      message: error.message,
      stack: error.stack
    });
    return {
      success: false,
      error: `Network error occurred: ${error.message}`,
      details: error.message
    };
  }
};

// Export types for use in other components
export type { SendOTPData, VerifyOTPData, ApiResponse, SMSOTPResponse };
