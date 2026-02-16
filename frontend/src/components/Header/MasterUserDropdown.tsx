import { useState, useEffect } from "react";
import { Dropdown } from "../ui/dropdown/Dropdown";
import { Link, useNavigate } from "react-router-dom";
import { getUserProfile } from "../../pages/profile/api";

interface UserProfile {
  username: string;
  email: string;
  first_name: string;
  last_name: string;
}

export default function MasterUserDropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const navigate = useNavigate();

  const [userProfile, setUserProfile] = useState<UserProfile>({
    username: '',
    email: '',
    first_name: '',
    last_name: ''
  });

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const latestProfile = await getUserProfile();
        setUserProfile({
          first_name: latestProfile.first_name || '',
          username: latestProfile.username || 'User',
          email: latestProfile.email || '',
          last_name: latestProfile.last_name || '',
        });
      } catch (error) {
        console.error('Failed to load user profile:', error);
      }
    };

    fetchProfile();
  }, []);

  function toggleDropdown() { setIsOpen(!isOpen); }
  function closeDropdown() { setIsOpen(false); }

  const handleLogout = () => {
    localStorage.removeItem("access");
    localStorage.removeItem("refresh");
    localStorage.removeItem("userRole");
    navigate("/");
  };

  return (
    <div className="relative">
      <button
        onClick={toggleDropdown}
        className="flex items-center text-gray-700 dropdown-toggle dark:text-gray-400"
      >
        <span className="mr-3 overflow-hidden rounded-full h-11 w-11">
          <img src="/images/user/download.jpeg" alt="User" />
        </span>
        <span className="block mr-1 font-medium text-theme-sm">{userProfile.first_name || userProfile.username || 'User'}</span>
        <svg
          className={`stroke-gray-500 dark:stroke-gray-400 transition-transform duration-200 ${isOpen ? "rotate-180" : ""}`}
          width="18"
          height="20"
          viewBox="0 0 18 20"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          <path
            d="M4.3125 8.65625L9 13.3437L13.6875 8.65625"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </button>

      <Dropdown
        isOpen={isOpen}
        onClose={closeDropdown}
        className="absolute right-0 mt-[17px] flex w-[260px] flex-col rounded-2xl border border-gray-200 bg-white p-3 shadow-theme-lg dark:border-gray-800 dark:bg-gray-dark"
      >
        <div>
          <span className="block font-medium text-gray-700 text-theme-sm dark:text-gray-400">
            {userProfile.username}
          </span>
          <span className="mt-0.5 block text-theme-xs text-gray-500 dark:text-gray-400">
            {userProfile.email}
          </span>
        </div>

        {/* Profile Link */}
        <Link
          to="/profile"
          className="flex items-center gap-3 px-3 py-2 mt-3 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300"
          onClick={closeDropdown}
        >
          <svg className="fill-gray-500 group-hover:fill-gray-700 dark:group-hover:fill-gray-300" width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path fillRule="evenodd" clipRule="evenodd" d="M11.9997 2.19336C12.3392 2.19336 12.6644 2.32742 12.9038 2.56608C13.1432 2.80475 13.2792 3.12901 13.2792 3.46743V4.92211C13.2792 5.06824 13.3102 5.21295 13.3703 5.34795C13.4305 5.48294 13.5186 5.60557 13.6297 5.70881C13.7408 5.81204 13.8726 5.89387 14.0177 5.94958C14.1627 6.0053 14.3181 6.03376 14.475 6.03334H17.7289C18.6655 6.03917 19.5636 6.41627 20.2259 7.08182C20.8883 7.74737 21.2604 8.64654 21.2604 9.58162V17.7618C21.2604 18.6969 20.8883 19.596 20.2259 20.2616C19.5636 20.9272 18.6655 21.3042 17.7289 21.3101H6.27042C5.33385 21.3042 4.43573 20.9272 3.77341 20.2616C3.11109 19.596 2.73902 18.6969 2.73902 17.7618V9.58162C2.73902 8.64654 3.11109 7.74737 3.77341 7.08182C4.43573 6.41627 5.33385 6.03917 6.27042 6.03334H9.52433C9.68121 6.03376 9.83656 6.0053 9.98166 5.94958C10.1268 5.89387 10.2585 5.81204 10.3696 5.70881C10.4807 5.60557 10.5689 5.48294 10.629 5.34795C10.6892 5.21295 10.7201 5.06824 10.7201 4.92211V3.46743C10.7201 3.12901 10.8561 2.80475 11.0956 2.56608C11.335 2.32742 11.6601 2.19336 11.9997 2.19336ZM16.3262 12.0163C16.3262 14.8021 14.3809 17.0607 11.9813 17.0607C9.58166 17.0607 7.63636 14.8021 7.63636 12.0163L16.3262 12.0163ZM14.8778 12.0165H9.08472C9.08472 9.83785 10.3813 8.07185 11.9813 8.07185C13.5812 8.07185 14.8778 9.83785 14.8778 12.0165Z" fill="" />
          </svg>
          My Profile
        </Link>

        {/* Sign Out Button */}
        <button
          onClick={handleLogout}
          className="flex w-full items-center gap-3 px-3 py-2 mt-3 font-medium text-gray-700 rounded-lg group text-theme-sm hover:bg-gray-100 hover:text-gray-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-gray-300 transition-colors text-left"
        >
          <svg
            className="fill-gray-500 group-hover:fill-gray-700 dark:group-hover:fill-gray-300"
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              fillRule="evenodd"
              clipRule="evenodd"
              d="M15.1007 19.247C14.6865 19.247 14.3507 18.9112 14.3507 18.497L14.3507 14.245H12.8507V18.497C12.8507 19.7396 13.8581 20.747 15.1007 20.747H18.5007C19.7434 20.747 20.7507 19.7396 20.7507 18.497L20.7507 5.49609C20.7507 4.25345 19.7433 3.24609 18.5007 3.24609H15.1007C13.8581 3.24609 12.8507 4.25345 12.8507 5.49609V9.74501L14.3507 9.74501V5.49609C14.3507 5.08188 14.6865 4.74609 15.1007 4.74609L18.5007 4.74609C18.9149 4.74609 19.2507 5.08188 19.2507 5.49609L19.2507 18.497C19.2507 18.9112 18.9149 19.247 18.5007 19.247H15.1007ZM3.25073 11.9984C3.25073 12.2144 3.34204 12.4091 3.48817 12.546L8.09483 17.1556C8.38763 17.4485 8.86251 17.4487 9.15549 17.1559C9.44848 16.8631 9.44863 16.3882 9.15583 16.0952L5.81116 12.7484L16.0007 12.7484C16.4149 12.7484 16.7507 12.4127 16.7507 11.9984C16.7507 11.5842 16.4149 11.2484 16.0007 11.2484L5.81528 11.2484L9.15585 7.90554C9.44864 7.61255 9.44847 7.13767 9.15547 6.84488C8.86248 6.55209 8.3876 6.55226 8.09481 6.84525L3.52309 11.4202C3.35673 11.5577 3.25073 11.7657 3.25073 11.9984Z"
              fill=""
            />
          </svg>
          Sign Out
        </button>
      </Dropdown>
    </div>
  );
}