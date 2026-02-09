import React, { useEffect, useState } from "react";
import { getUserById, updateUser, UserRegister } from "./api";
import Button from "../../components/ui/button/Button";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import Select from "../../components/form/Select";

interface EditUserProps {
  userId: number;
  isOpen: boolean;
  onClose: () => void;
  onUpdated: () => void;
}

const EditUser: React.FC<EditUserProps> = ({ userId, isOpen, onClose, onUpdated }) => {
  const [userData, setUserData] = useState<Partial<UserRegister>>({});
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");

  useEffect(() => {
    if (!isOpen) return;

    setLoading(true);
    setError("");
    getUserById(userId)
      .then((data) => setUserData(data))
      .catch(() => setError("Failed to load user data"))
      .finally(() => setLoading(false));
  }, [isOpen, userId]);

  const handleChange = (field: keyof UserRegister, value: any) => {
    setUserData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (password || confirmPassword) {
      if (password !== confirmPassword) {
        toast.error("Passwords do not match");
        return;
      }
      if (password.length < 6) {
        toast.error("Password must be at least 6 characters");
        return;
      }
    }

    setSaving(true);
    try {
      const updateData: Partial<UserRegister> & { password?: string } = {
        username: userData.username!,
        email: userData.email!,
        role: userData.role!,
        first_name: userData.first_name,
        last_name: userData.last_name,
        is_active: userData.is_active,
      };

      if (password) {
        updateData.password = password;
      }

      await updateUser(userId, updateData);

      setPassword("");
      setConfirmPassword("");

      toast.success("User updated successfully!");

      // Delay modal close for better UX
      setTimeout(() => {
        onUpdated();
        onClose();
      }, 1500);
    } catch (err: any) {
      console.error("Error updating user:", err);

      if (err.response?.data) {
        const errors = err.response.data;
        Object.values(errors).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(err.message || "Failed to update user");
      }
    } finally {
      setSaving(false);
    }
  };

  if (!isOpen) return null;

  if (loading) {
    return (
      <div className="fixed inset-0 flex items-center justify-center bg-white/50 backdrop-blur-sm z-50">
        <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow-md text-black dark:text-white">
          Loading user data...
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-white/50 backdrop-blur-sm flex items-center justify-center z-50 ">
      <ToastContainer
          position="bottom-right"
          autoClose={3000}
          hideProgressBar={false}
          newestOnTop
          closeOnClick
          rtl={false}
          pauseOnFocusLoss
          draggable
          pauseOnHover
          theme="light"
          className="z-[99999]"
        />
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-lg p-6 w-full max-w-md max-h-[90vh] overflow-auto relative mt-24">
        {/* Close button */}
        <button
          onClick={onClose}
          className="absolute top-3 right-3 w-10 h-10 flex items-center justify-center rounded-full 
                    text-gray-500 hover:text-gray-800 dark:hover:text-gray-200 text-4xl font-bold"
        >
          ×
        </button>

        <h2 className="text-2xl font-bold mb-4 text-gray-900 dark:text-white">
          Edit User
        </h2>

        {error && <p className="text-red-600 mb-2">{error}</p>}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Username */}
          <div>
            <Label htmlFor="username">Username *</Label>
            <Input
              id="username"
              type="text"
              value={userData.username || ""}
              onChange={(e) => handleChange("username", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          {/* Email */}
          <div>
            <Label htmlFor="email">Email *</Label>
            <Input
              id="email"
              type="email"
              value={userData.email || ""}
              onChange={(e) => handleChange("email", e.target.value)}
              required
              disabled={saving}
            />
          </div>

          {/* First Name */}
          <div>
            <Label htmlFor="firstName">First Name</Label>
            <Input
              id="firstName"
              type="text"
              value={userData.first_name || ""}
              onChange={(e) => handleChange("first_name", e.target.value)}
              disabled={saving}
            />
          </div>

          {/* Last Name */}
          <div>
            <Label htmlFor="lastName">Last Name</Label>
            <Input
              id="lastName"
              type="text"
              value={userData.last_name || ""}
              onChange={(e) => handleChange("last_name", e.target.value)}
              disabled={saving}
            />
          </div>

          {/* Role */}
          <div>
            <Label htmlFor="role">Role</Label>
            <Select
              value={userData.role || "employee"}
              onChange={(val) => handleChange("role", val)}
              options={[
                { value: "master", label: "Master" },
                { value: "admin", label: "Admin" },
                { value: "employee", label: "Employee" },
              ]}
              className="w-full"
              disabled={saving}
            />
          </div>


          {/* Password */}
          <div>
            <Label htmlFor="password">New Password (optional)</Label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              disabled={saving}
              placeholder="Leave blank to keep current password"
            />
          </div>

          <div>
            <Label htmlFor="confirmPassword">Confirm New Password</Label>
            <Input
              id="confirmPassword"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              disabled={saving}
              placeholder="Confirm new password"
            />
          </div>

          {/* Active */}
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="isActive"
              checked={!!userData.is_active}
              onChange={() => handleChange("is_active", !userData.is_active)}
              className="w-4 h-4"
              disabled={saving}
            />
            <Label htmlFor="isActive" className="cursor-pointer">
              Active
            </Label>
          </div>

          {/* Buttons */}
          <div className="flex justify-end gap-2">
            <Button type="button" variant="outline" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button type="submit" disabled={saving}>
              {saving ? "Saving..." : "Save"}
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default EditUser;
