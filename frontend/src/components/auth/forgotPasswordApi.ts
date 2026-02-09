import { createApiUrl } from '../../access/access.ts';

// Types for the forgot password API
interface OtpResponse {
  success: boolean;
  message?: string;
  error?: string;
}

interface VerifyOtpResponse {
  success: boolean;
  message?: string;
  error?: string;
}

interface ResetPasswordResponse {
  success: boolean;
  message?: string;
  error?: string;
}

export const sendOtp = async (email: string): Promise<OtpResponse> => {
  try {
    const response = await fetch(createApiUrl('/sendotp/'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email }),
    });
    const data = await response.json();
    return response.ok
      ? { success: true, message: data.message }
      : { success: false, error: data.message || "Failed to send OTP" };
  } catch (err: any) {
    return { success: false, error: err.message };
  }
};

export const verifyOtp = async (email: string, otp: string): Promise<VerifyOtpResponse> => {
  try {
    const response = await fetch(createApiUrl('/verifyotp/'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, otp }),
    });

    const data = await response.json();

    if (!response.ok || data.error) {
      return {
        success: false,
        error: data.error || data.message || "OTP verification failed",
      };
    }

    return {
      success: true,
      message: data.message || "OTP verified successfully",
    };
  } catch (err: any) {
    return { success: false, error: err.message || "Network error" };
  }
};

export const resetPassword = async (
  email: string,
  _otp: string,
  new_password: string,
  confirm_password: string
): Promise<ResetPasswordResponse> => {
  try {
    const response = await fetch(createApiUrl('/resetpassword/'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email,
        new_password,
        confirm_password
      }),
    });

    const data = await response.json();

    return response.ok
      ? { success: true, message: data.message }
      : { success: false, error: data.error || "Reset failed" };
  } catch (err: any) {
    return { success: false, error: err.message };
  }
};

// Export types for use in other components
export type { OtpResponse, VerifyOtpResponse, ResetPasswordResponse };
