import { createApiUrl } from '../../access/access.ts';

// Types for the registration API
interface UserData {
  first_name: string;
  last_name: string;
  email: string;
  username: string;
  password: string;
  password_confirm: string;
  role: string;
}

interface ApiResponse {
  success: boolean;
  status?: string;
  message?: string;
  data?: any;
  error?: string;
  details?: any;
}

// Register a new user
export const registerUser = async (userData: UserData): Promise<ApiResponse> => {
  try {
    console.log('Attempting to register user with data:', userData);
    console.log('API URL:', createApiUrl('api/register/'));
    
    const response = await fetch(createApiUrl('api/register/'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(userData),
    });

    console.log('Response status:', response.status);
    console.log('Response headers:', response.headers);

    const data = await response.json();
    console.log('Response data:', data);

    if (response.ok && data.status === 'success') {
      return {
        success: true,
        data: data,
        message: data.message || 'User registered successfully'
      };
    } else {
      return {
        success: false,
        error: data.message || 'Registration failed',
        details: data.message
      };
    }
  } catch (error: any) {
    console.error('Registration API Error:', error);
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
export type { UserData, ApiResponse };
