import { jwtDecode } from 'jwt-decode';
import { createApiUrl } from '../../access/access.ts';

interface LoginCredentials {
  username: string;
  password: string;
}

interface LoginResponse {
  success: boolean;
  data?: any;
  message?: string;
  error?: string;
  details?: any;
  userRole?: string;
}

const loginUser = async (credentials: LoginCredentials): Promise<LoginResponse> => {
  try {
    const response = await fetch(createApiUrl('api/login/'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(credentials),
    });

    const data = await response.json();

    if (response.ok && data.tokens && data.tokens.access) {
      localStorage.setItem('access', data.tokens.access);
      localStorage.setItem('refresh', data.tokens.refresh);
      const userRole = data.tokens.userRole || jwtDecode<{ role: string }>(data.tokens.access).role;
      localStorage.setItem('userRole', userRole);

      return {
        success: true,
        data: data,
        message: data.message || 'Login successful',
        userRole: userRole,

      };
    } else {
      return {
        success: false,
        error: data.message || 'Invalid credentials',
        details: data
      };
    }

  } catch (error: unknown) {
    console.error('Login API Error:', error);
    return {
      success: false,
      error: 'Network error occurred',
      details: error instanceof Error ? error.message : String(error)
    };
  }
};



export default loginUser;