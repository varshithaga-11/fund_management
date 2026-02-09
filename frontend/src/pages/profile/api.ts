import { createApiUrl, getAuthHeaders } from '../../access/access.ts';
import { jwtDecode } from 'jwt-decode';
import axios from 'axios';

// const token = localStorage.getItem('access_token');
// interface JwtPayload { user_id: string }
// const decoded = jwtDecode<JwtPayload>(token as string);
// const userId = decoded.user_id;
// console.log('Decoded user ID:', userId);
interface JwtPayload {
  user_id: string;
}


const getUserIdFromToken = (): string | null => {
  const token = localStorage.getItem('access');
  if (!token) return null;
  try {
    return jwtDecode<JwtPayload>(token).user_id;
  } catch {
    return null;
  }
};
const userId = getUserIdFromToken();
if (!userId) throw new Error('User is not logged in');

export const getUserProfile = async () => {
  const userId = getUserIdFromToken();
  if (!userId) throw new Error('User is not logged in');

  const url = createApiUrl(`api/profile/${userId}/`);
  const headers = await getAuthHeaders();
  const response = await axios.get(url, { headers });
  return response.data;
};

export const updateUserProfile = async (data: any) => {
  const userId = getUserIdFromToken();
  if (!userId) throw new Error('User is not logged in');

  const url = createApiUrl(`api/profile/${userId}/`);
  const headers = await getAuthHeaders();
  const response = await axios.put(url, data, { headers });
  return response.data;
};
