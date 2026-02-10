import React, { useState, useEffect } from "react";
import {
  getProfitLoss,
  createProfitLoss,
  updateProfitLoss,
  ProfitAndLossData,
} from "./api";
import Button from "../../components/ui/button/Button";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface ProfitLossFormProps {
  periodId: number;
  onSave?: () => void;
  canUpdate?: boolean;
}

const ProfitLossForm: React.FC<ProfitLossFormProps> = ({
  periodId,
  onSave,
  canUpdate = true,
}) => {
  const [formData, setFormData] = useState({
    interest_on_loans: "",
    interest_on_bank_ac: "",
    return_on_investment: "",
    miscellaneous_income: "",
    interest_on_deposits: "",
    interest_on_borrowings: "",
    establishment_contingencies: "",
    provisions: "",
    net_profit: "",
  });
  const [totals, setTotals] = useState({
    total_income: 0,
    total_expenses: 0,
  });
  const [loading, setLoading] = useState(false);
  const [existingId, setExistingId] = useState<number | null>(null);

  const isReadOnly = !canUpdate && existingId !== null;

  useEffect(() => {
    loadData();
  }, [periodId]);

  useEffect(() => {
    calculateTotals();
  }, [formData]);

  const loadData = async () => {
    try {
      const data = await getProfitLoss(periodId);
      if (data) {
        setExistingId(data.id);
        setFormData({
          interest_on_loans: data.interest_on_loans.toString(),
          interest_on_bank_ac: data.interest_on_bank_ac.toString(),
          return_on_investment: data.return_on_investment.toString(),
          miscellaneous_income: data.miscellaneous_income.toString(),
          interest_on_deposits: data.interest_on_deposits.toString(),
          interest_on_borrowings: data.interest_on_borrowings.toString(),
          establishment_contingencies: data.establishment_contingencies.toString(),
          provisions: data.provisions.toString(),
          net_profit: data.net_profit.toString(),
        });
      }
    } catch (error) {
      console.error("Error loading profit & loss:", error);
    }
  };

  const calculateTotals = () => {
    const income =
      parseFloat(formData.interest_on_loans) +
      parseFloat(formData.interest_on_bank_ac) +
      parseFloat(formData.return_on_investment) +
      parseFloat(formData.miscellaneous_income);
    const expenses =
      parseFloat(formData.interest_on_deposits) +
      parseFloat(formData.interest_on_borrowings) +
      parseFloat(formData.establishment_contingencies) +
      parseFloat(formData.provisions);

    setTotals({
      total_income: isNaN(income) ? 0 : income,
      total_expenses: isNaN(expenses) ? 0 : expenses,
    });
  };

  const handleChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const data = {
      interest_on_loans: parseFloat(formData.interest_on_loans) || 0,
      interest_on_bank_ac: parseFloat(formData.interest_on_bank_ac) || 0,
      return_on_investment: parseFloat(formData.return_on_investment) || 0,
      miscellaneous_income: parseFloat(formData.miscellaneous_income) || 0,
      interest_on_deposits: parseFloat(formData.interest_on_deposits) || 0,
      interest_on_borrowings: parseFloat(formData.interest_on_borrowings) || 0,
      establishment_contingencies:
        parseFloat(formData.establishment_contingencies) || 0,
      provisions: parseFloat(formData.provisions) || 0,
      net_profit: parseFloat(formData.net_profit) || 0,
    };

    setLoading(true);
    try {
      if (existingId) {
        await updateProfitLoss(existingId, data);
        toast.success("Profit & Loss updated successfully!");
      } else {
        await createProfitLoss(periodId, data);
        toast.success("Profit & Loss created successfully!");
      }
      await loadData();
      onSave?.();
    } catch (error: any) {
      console.error("Error saving profit & loss:", error);
      if (error.response?.data) {
        Object.values(error.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(error.message || "Failed to save profit & loss");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />
      <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
        Profit & Loss Statement
      </h3>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Income Section */}
        <div className="space-y-4">
          <h4 className="text-lg font-medium text-gray-800 dark:text-gray-200">
            Income
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="interest_on_loans">Interest on Loans *</Label>
              <Input
                id="interest_on_loans"
                type="number"
                step="0.01"
                value={formData.interest_on_loans}
                onChange={(e) =>
                  handleChange("interest_on_loans", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="interest_on_bank_ac">Interest on Bank A/c *</Label>
              <Input
                id="interest_on_bank_ac"
                type="number"
                step="0.01"
                value={formData.interest_on_bank_ac}
                onChange={(e) =>
                  handleChange("interest_on_bank_ac", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="return_on_investment">Return on Investment *</Label>
              <Input
                id="return_on_investment"
                type="number"
                step="0.01"
                value={formData.return_on_investment}
                onChange={(e) =>
                  handleChange("return_on_investment", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="miscellaneous_income">Miscellaneous Income *</Label>
              <Input
                id="miscellaneous_income"
                type="number"
                step="0.01"
                value={formData.miscellaneous_income}
                onChange={(e) =>
                  handleChange("miscellaneous_income", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>
          </div>
          <div>
            <Label>Total Income (Calculated)</Label>
            <Input
              type="text"
              value={`₹${totals.total_income.toLocaleString("en-IN", {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              })}`}
              disabled
              className="bg-gray-100 dark:bg-gray-700"
            />
          </div>
        </div>

        {/* Expenses Section */}
        <div className="space-y-4">
          <h4 className="text-lg font-medium text-gray-800 dark:text-gray-200">
            Expenses
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="interest_on_deposits">Interest on Deposits *</Label>
              <Input
                id="interest_on_deposits"
                type="number"
                step="0.01"
                value={formData.interest_on_deposits}
                onChange={(e) =>
                  handleChange("interest_on_deposits", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="interest_on_borrowings">Interest on Borrowings *</Label>
              <Input
                id="interest_on_borrowings"
                type="number"
                step="0.01"
                value={formData.interest_on_borrowings}
                onChange={(e) =>
                  handleChange("interest_on_borrowings", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="establishment_contingencies">
                Establishment & Contingencies *
              </Label>
              <Input
                id="establishment_contingencies"
                type="number"
                step="0.01"
                value={formData.establishment_contingencies}
                onChange={(e) =>
                  handleChange("establishment_contingencies", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="provisions">Provisions *</Label>
              <Input
                id="provisions"
                type="number"
                step="0.01"
                value={formData.provisions}
                onChange={(e) => handleChange("provisions", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>
          </div>
          <div>
            <Label>Total Expenses (Calculated)</Label>
            <Input
              type="text"
              value={`₹${totals.total_expenses.toLocaleString("en-IN", {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2,
              })}`}
              disabled
              className="bg-gray-100 dark:bg-gray-700"
            />
          </div>
        </div>

        {/* Net Profit */}
        <div>
          <Label htmlFor="net_profit">Net Profit *</Label>
          <Input
            id="net_profit"
            type="number"
            step="0.01"
            value={formData.net_profit}
            onChange={(e) => handleChange("net_profit", e.target.value)}
            required
            disabled={loading || isReadOnly}
          />
        </div>

        <div className="flex justify-end">
          {!isReadOnly && (
            <Button type="submit" disabled={loading}>
              {loading ? "Saving..." : existingId ? "Update" : "Save"}
            </Button>
          )}
        </div>
      </form>
    </div>
  );
};

export default ProfitLossForm;
