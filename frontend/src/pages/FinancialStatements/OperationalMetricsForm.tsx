import React, { useState, useEffect } from "react";
import {
  getOperationalMetrics,
  createOperationalMetrics,
  updateOperationalMetrics,
  OperationalMetricsData,
} from "./api";
import Button from "../../components/ui/button/Button";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface OperationalMetricsFormProps {
  periodId: number;
  onSave?: () => void;
}

const OperationalMetricsForm: React.FC<OperationalMetricsFormProps> = ({
  periodId,
  onSave,
}) => {
  const [staffCount, setStaffCount] = useState("");
  const [loading, setLoading] = useState(false);
  const [existingId, setExistingId] = useState<number | null>(null);

  useEffect(() => {
    loadData();
  }, [periodId]);

  const loadData = async () => {
    try {
      const data = await getOperationalMetrics(periodId);
      if (data) {
        setExistingId(data.id);
        setStaffCount(data.staff_count.toString());
      }
    } catch (error) {
      console.error("Error loading operational metrics:", error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!staffCount || parseInt(staffCount) <= 0) {
      toast.error("Staff count must be greater than 0");
      return;
    }

    const data = {
      staff_count: parseInt(staffCount),
    };

    setLoading(true);
    try {
      if (existingId) {
        await updateOperationalMetrics(existingId, data);
        toast.success("Operational Metrics updated successfully!");
      } else {
        await createOperationalMetrics(periodId, data);
        toast.success("Operational Metrics created successfully!");
      }
      await loadData();
      onSave?.();
    } catch (error: any) {
      console.error("Error saving operational metrics:", error);
      if (error.response?.data) {
        Object.values(error.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(error.message || "Failed to save operational metrics");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />
      <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
        Operational Metrics
      </h3>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <Label htmlFor="staff_count">Number of Staff *</Label>
          <Input
            id="staff_count"
            type="number"
            min="1"
            value={staffCount}
            onChange={(e) => setStaffCount(e.target.value)}
            required
            disabled={loading}
            placeholder="Enter number of staff members"
          />
        </div>

        <div className="flex justify-end">
          <Button type="submit" disabled={loading}>
            {loading ? "Saving..." : existingId ? "Update" : "Save"}
          </Button>
        </div>
      </form>
    </div>
  );
};

export default OperationalMetricsForm;
