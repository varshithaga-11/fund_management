import React, { useState, useEffect } from "react";
import {
  getTradingAccount,
  createTradingAccount,
  updateTradingAccount,
  TradingAccountData,
} from "./api";
import Button from "../../components/ui/button/Button";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface TradingAccountFormProps {
  periodId: number;
  onSave?: () => void;
}

const TradingAccountForm: React.FC<TradingAccountFormProps> = ({
  periodId,
  onSave,
}) => {
  const [formData, setFormData] = useState({
    opening_stock: "",
    purchases: "",
    trade_charges: "",
    sales: "",
    closing_stock: "",
  });
  const [grossProfit, setGrossProfit] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);
  const [existingId, setExistingId] = useState<number | null>(null);

  useEffect(() => {
    loadData();
  }, [periodId]);

  useEffect(() => {
    calculateGrossProfit();
  }, [formData]);

  const loadData = async () => {
    try {
      const data = await getTradingAccount(periodId);
      if (data) {
        setExistingId(data.id);
        setFormData({
          opening_stock: data.opening_stock.toString(),
          purchases: data.purchases.toString(),
          trade_charges: data.trade_charges.toString(),
          sales: data.sales.toString(),
          closing_stock: data.closing_stock.toString(),
        });
        setGrossProfit(data.gross_profit);
      }
    } catch (error) {
      console.error("Error loading trading account:", error);
    }
  };

  const calculateGrossProfit = () => {
    const opening = parseFloat(formData.opening_stock) || 0;
    const purchases = parseFloat(formData.purchases) || 0;
    const charges = parseFloat(formData.trade_charges) || 0;
    const sales = parseFloat(formData.sales) || 0;
    const closing = parseFloat(formData.closing_stock) || 0;

    const calculated = sales + closing - (opening + purchases + charges);
    setGrossProfit(isNaN(calculated) ? null : calculated);
  };

  const handleChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const data = {
      opening_stock: parseFloat(formData.opening_stock) || 0,
      purchases: parseFloat(formData.purchases) || 0,
      trade_charges: parseFloat(formData.trade_charges) || 0,
      sales: parseFloat(formData.sales) || 0,
      closing_stock: parseFloat(formData.closing_stock) || 0,
    };

    setLoading(true);
    try {
      if (existingId) {
        await updateTradingAccount(existingId, data);
        toast.success("Trading Account updated successfully!");
      } else {
        await createTradingAccount(periodId, data);
        toast.success("Trading Account created successfully!");
      }
      await loadData();
      onSave?.();
    } catch (error: any) {
      console.error("Error saving trading account:", error);
      if (error.response?.data) {
        Object.values(error.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(error.message || "Failed to save trading account");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />
      <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
        Trading Account
      </h3>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <Label htmlFor="opening_stock">Opening Stock *</Label>
            <Input
              id="opening_stock"
              type="number"
              step="0.01"
              value={formData.opening_stock}
              onChange={(e) => handleChange("opening_stock", e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div>
            <Label htmlFor="purchases">Purchases *</Label>
            <Input
              id="purchases"
              type="number"
              step="0.01"
              value={formData.purchases}
              onChange={(e) => handleChange("purchases", e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div>
            <Label htmlFor="trade_charges">Trade Charges *</Label>
            <Input
              id="trade_charges"
              type="number"
              step="0.01"
              value={formData.trade_charges}
              onChange={(e) => handleChange("trade_charges", e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div>
            <Label htmlFor="sales">Sales *</Label>
            <Input
              id="sales"
              type="number"
              step="0.01"
              value={formData.sales}
              onChange={(e) => handleChange("sales", e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div>
            <Label htmlFor="closing_stock">Closing Stock *</Label>
            <Input
              id="closing_stock"
              type="number"
              step="0.01"
              value={formData.closing_stock}
              onChange={(e) => handleChange("closing_stock", e.target.value)}
              required
              disabled={loading}
            />
          </div>

          <div>
            <Label htmlFor="gross_profit">Gross Profit (Calculated)</Label>
            <Input
              id="gross_profit"
              type="text"
              value={
                grossProfit !== null
                  ? `₹${grossProfit.toLocaleString("en-IN", {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 2,
                    })}`
                  : ""
              }
              disabled
              className="bg-gray-100 dark:bg-gray-700"
            />
          </div>
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

export default TradingAccountForm;
