import React, { useState, useEffect } from "react";
import {
  getBalanceSheet,
  createBalanceSheet,
  updateBalanceSheet,
  BalanceSheetData,
} from "./api";
import Button from "../../components/ui/button/Button";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";

interface BalanceSheetFormProps {
  periodId: number;
  onSave?: () => void;
  canUpdate?: boolean;
}

const BalanceSheetForm: React.FC<BalanceSheetFormProps> = ({
  periodId,
  onSave,
  canUpdate = true,
}) => {
  const [formData, setFormData] = useState({
    share_capital: "",
    deposits: "",
    borrowings: "",
    reserves_statutory_free: "",
    undistributed_profit: "",
    provisions: "",
    other_liabilities: "",
    cash_in_hand: "",
    cash_at_bank: "",
    investments: "",
    loans_advances: "",
    fixed_assets: "",
    other_assets: "",
    stock_in_trade: "",
  });
  const [calculated, setCalculated] = useState({
    working_fund: 0,
    own_funds: 0,
    total_liabilities: 0,
    total_assets: 0,
  });
  const [loading, setLoading] = useState(false);
  const [existingId, setExistingId] = useState<number | null>(null);

  const isReadOnly = !canUpdate && existingId !== null;

  useEffect(() => {
    loadData();
  }, [periodId]);

  useEffect(() => {
    calculateValues();
  }, [formData]);

  const loadData = async () => {
    try {
      const data = await getBalanceSheet(periodId);
      if (data) {
        setExistingId(data.id);
        setFormData({
          share_capital: data.share_capital.toString(),
          deposits: data.deposits.toString(),
          borrowings: data.borrowings.toString(),
          reserves_statutory_free: data.reserves_statutory_free.toString(),
          undistributed_profit: data.undistributed_profit.toString(),
          provisions: data.provisions.toString(),
          other_liabilities: data.other_liabilities.toString(),
          cash_in_hand: data.cash_in_hand.toString(),
          cash_at_bank: data.cash_at_bank.toString(),
          investments: data.investments.toString(),
          loans_advances: data.loans_advances.toString(),
          fixed_assets: data.fixed_assets.toString(),
          other_assets: data.other_assets.toString(),
          stock_in_trade: data.stock_in_trade.toString(),
        });
      }
    } catch (error) {
      console.error("Error loading balance sheet:", error);
    }
  };

  const calculateValues = () => {
    const shareCapital = parseFloat(formData.share_capital) || 0;
    const deposits = parseFloat(formData.deposits) || 0;
    const borrowings = parseFloat(formData.borrowings) || 0;
    const reserves = parseFloat(formData.reserves_statutory_free) || 0;
    const udp = parseFloat(formData.undistributed_profit) || 0;
    const provisions = parseFloat(formData.provisions) || 0;
    const otherLiabilities = parseFloat(formData.other_liabilities) || 0;

    const cashInHand = parseFloat(formData.cash_in_hand) || 0;
    const cashAtBank = parseFloat(formData.cash_at_bank) || 0;
    const investments = parseFloat(formData.investments) || 0;
    const loans = parseFloat(formData.loans_advances) || 0;
    const fixedAssets = parseFloat(formData.fixed_assets) || 0;
    const otherAssets = parseFloat(formData.other_assets) || 0;
    const stock = parseFloat(formData.stock_in_trade) || 0;

    const workingFund = shareCapital + deposits + borrowings + reserves + udp;
    const ownFunds = shareCapital + reserves + udp;
    const totalLiabilities =
      shareCapital +
      deposits +
      borrowings +
      reserves +
      udp +
      provisions +
      otherLiabilities;
    const totalAssets =
      cashInHand +
      cashAtBank +
      investments +
      loans +
      fixedAssets +
      otherAssets +
      stock;

    setCalculated({
      working_fund: workingFund,
      own_funds: ownFunds,
      total_liabilities: totalLiabilities,
      total_assets: totalAssets,
    });
  };

  const handleChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validate balance
    if (
      Math.abs(calculated.total_liabilities - calculated.total_assets) > 0.01
    ) {
      toast.error(
        `Balance Sheet must balance! Liabilities: ₹${calculated.total_liabilities.toLocaleString()}, Assets: ₹${calculated.total_assets.toLocaleString()}`
      );
      return;
    }

    const data = {
      share_capital: parseFloat(formData.share_capital) || 0,
      deposits: parseFloat(formData.deposits) || 0,
      borrowings: parseFloat(formData.borrowings) || 0,
      reserves_statutory_free: parseFloat(formData.reserves_statutory_free) || 0,
      undistributed_profit: parseFloat(formData.undistributed_profit) || 0,
      provisions: parseFloat(formData.provisions) || 0,
      other_liabilities: parseFloat(formData.other_liabilities) || 0,
      cash_in_hand: parseFloat(formData.cash_in_hand) || 0,
      cash_at_bank: parseFloat(formData.cash_at_bank) || 0,
      investments: parseFloat(formData.investments) || 0,
      loans_advances: parseFloat(formData.loans_advances) || 0,
      fixed_assets: parseFloat(formData.fixed_assets) || 0,
      other_assets: parseFloat(formData.other_assets) || 0,
      stock_in_trade: parseFloat(formData.stock_in_trade) || 0,
    };

    setLoading(true);
    try {
      if (existingId) {
        await updateBalanceSheet(existingId, data);
        toast.success("Balance Sheet updated successfully!");
      } else {
        await createBalanceSheet(periodId, data);
        toast.success("Balance Sheet created successfully!");
      }
      await loadData();
      onSave?.();
    } catch (error: any) {
      console.error("Error saving balance sheet:", error);
      if (error.response?.data) {
        Object.values(error.response.data).forEach((msg: any) => {
          toast.error(Array.isArray(msg) ? msg[0] : msg);
        });
      } else {
        toast.error(error.message || "Failed to save balance sheet");
      }
    } finally {
      setLoading(false);
    }
  };

  const isBalanced =
    Math.abs(calculated.total_liabilities - calculated.total_assets) < 0.01;

  return (
    <div className="space-y-6">
      <ToastContainer position="bottom-right" autoClose={3000} />
      <h3 className="text-xl font-semibold text-gray-900 dark:text-white">
        Balance Sheet
      </h3>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Liabilities Section */}
        <div className="space-y-4">
          <h4 className="text-lg font-medium text-gray-800 dark:text-gray-200">
            Liabilities (Sources of Funds)
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="share_capital">Share Capital *</Label>
              <Input
                id="share_capital"
                type="number"
                step="0.01"
                value={formData.share_capital}
                onChange={(e) => handleChange("share_capital", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="deposits">Deposits *</Label>
              <Input
                id="deposits"
                type="number"
                step="0.01"
                value={formData.deposits}
                onChange={(e) => handleChange("deposits", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="borrowings">Borrowings *</Label>
              <Input
                id="borrowings"
                type="number"
                step="0.01"
                value={formData.borrowings}
                onChange={(e) => handleChange("borrowings", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="reserves_statutory_free">
                Statutory & Free Reserves *
              </Label>
              <Input
                id="reserves_statutory_free"
                type="number"
                step="0.01"
                value={formData.reserves_statutory_free}
                onChange={(e) =>
                  handleChange("reserves_statutory_free", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="undistributed_profit">
                Undistributed Profit (UDP) *
              </Label>
              <Input
                id="undistributed_profit"
                type="number"
                step="0.01"
                value={formData.undistributed_profit}
                onChange={(e) =>
                  handleChange("undistributed_profit", e.target.value)
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

            <div>
              <Label htmlFor="other_liabilities">Other Liabilities *</Label>
              <Input
                id="other_liabilities"
                type="number"
                step="0.01"
                value={formData.other_liabilities}
                onChange={(e) =>
                  handleChange("other_liabilities", e.target.value)
                }
                required
                disabled={loading || isReadOnly}
              />
            </div>
          </div>
        </div>

        {/* Assets Section */}
        <div className="space-y-4">
          <h4 className="text-lg font-medium text-gray-800 dark:text-gray-200">
            Assets (Application of Funds)
          </h4>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="cash_in_hand">Cash in Hand *</Label>
              <Input
                id="cash_in_hand"
                type="number"
                step="0.01"
                value={formData.cash_in_hand}
                onChange={(e) => handleChange("cash_in_hand", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="cash_at_bank">Cash at Bank *</Label>
              <Input
                id="cash_at_bank"
                type="number"
                step="0.01"
                value={formData.cash_at_bank}
                onChange={(e) => handleChange("cash_at_bank", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="investments">Investments *</Label>
              <Input
                id="investments"
                type="number"
                step="0.01"
                value={formData.investments}
                onChange={(e) => handleChange("investments", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="loans_advances">Loans & Advances *</Label>
              <Input
                id="loans_advances"
                type="number"
                step="0.01"
                value={formData.loans_advances}
                onChange={(e) => handleChange("loans_advances", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="fixed_assets">Fixed Assets *</Label>
              <Input
                id="fixed_assets"
                type="number"
                step="0.01"
                value={formData.fixed_assets}
                onChange={(e) => handleChange("fixed_assets", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="other_assets">Other Assets *</Label>
              <Input
                id="other_assets"
                type="number"
                step="0.01"
                value={formData.other_assets}
                onChange={(e) => handleChange("other_assets", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>

            <div>
              <Label htmlFor="stock_in_trade">Stock in Trade *</Label>
              <Input
                id="stock_in_trade"
                type="number"
                step="0.01"
                value={formData.stock_in_trade}
                onChange={(e) => handleChange("stock_in_trade", e.target.value)}
                required
                disabled={loading || isReadOnly}
              />
            </div>
          </div>
        </div>

        {/* Calculated Values */}
        <div className="space-y-2 p-4 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Working Fund (Calculated)</Label>
              <Input
                type="text"
                value={`₹${calculated.working_fund.toLocaleString("en-IN", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}`}
                disabled
                className="bg-gray-100 dark:bg-gray-700"
              />
            </div>

            <div>
              <Label>Own Funds (Calculated)</Label>
              <Input
                type="text"
                value={`₹${calculated.own_funds.toLocaleString("en-IN", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}`}
                disabled
                className="bg-gray-100 dark:bg-gray-700"
              />
            </div>

            <div>
              <Label>Total Liabilities</Label>
              <Input
                type="text"
                value={`₹${calculated.total_liabilities.toLocaleString("en-IN", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}`}
                disabled
                className={`${
                  isBalanced
                    ? "bg-green-50 dark:bg-green-900/20"
                    : "bg-red-50 dark:bg-red-900/20"
                }`}
              />
            </div>

            <div>
              <Label>Total Assets</Label>
              <Input
                type="text"
                value={`₹${calculated.total_assets.toLocaleString("en-IN", {
                  minimumFractionDigits: 2,
                  maximumFractionDigits: 2,
                })}`}
                disabled
                className={`${
                  isBalanced
                    ? "bg-green-50 dark:bg-green-900/20"
                    : "bg-red-50 dark:bg-red-900/20"
                }`}
              />
            </div>
          </div>

          {!isBalanced && (
            <p className="text-sm text-red-600 dark:text-red-400">
              Balance Sheet is not balanced! Please check your entries.
            </p>
          )}
        </div>

        <div className="flex justify-end">
          {!isReadOnly && (
            <Button type="submit" disabled={loading || !isBalanced}>
              {loading ? "Saving..." : existingId ? "Update" : "Save"}
            </Button>
          )}
        </div>
      </form>
    </div>
  );
};

export default BalanceSheetForm;
