import React, { useState, useEffect } from "react";
import {
  getTradingAccount,
  createTradingAccount,
  updateTradingAccount,
  getProfitLoss,
  createProfitLoss,
  updateProfitLoss,
  getBalanceSheet,
  createBalanceSheet,
  updateBalanceSheet,
  getOperationalMetrics,
  createOperationalMetrics,
  updateOperationalMetrics,
  calculateRatios,
} from "../FinancialStatements/api";
import Input from "../../components/form/input/InputField";
import Label from "../../components/form/Label";
import { ChevronDown, ChevronUp, RefreshCw } from "lucide-react";
import { toast } from "react-toastify";

interface PeriodDataEditFormProps {
  periodId: number;
  onSuccess?: () => void;
}

const PeriodDataEditForm: React.FC<PeriodDataEditFormProps> = ({
  periodId,
  onSuccess,
}) => {
  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(true);
  const [openSection, setOpenSection] = useState<string>("trading");

  // Trading Account
  const [ta, setTa] = useState({
    opening_stock: "",
    purchases: "",
    trade_charges: "",
    sales: "",
    closing_stock: "",
  });
  const [taId, setTaId] = useState<number | null>(null);

  // Profit & Loss
  const [pl, setPl] = useState({
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
  const [plId, setPlId] = useState<number | null>(null);

  // Balance Sheet
  const [bs, setBs] = useState({
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
  const [bsId, setBsId] = useState<number | null>(null);

  // Operational Metrics
  const [staffCount, setStaffCount] = useState("");
  const [omId, setOmId] = useState<number | null>(null);

  useEffect(() => {
    loadAll();
  }, [periodId]);

  const loadAll = async () => {
    setLoadingData(true);
    try {
      const [taData, plData, bsData, omData] = await Promise.all([
        getTradingAccount(periodId),
        getProfitLoss(periodId),
        getBalanceSheet(periodId),
        getOperationalMetrics(periodId),
      ]);

      if (taData) {
        setTaId(taData.id);
        setTa({
          opening_stock: taData.opening_stock.toString(),
          purchases: taData.purchases.toString(),
          trade_charges: taData.trade_charges.toString(),
          sales: taData.sales.toString(),
          closing_stock: taData.closing_stock.toString(),
        });
      } else setTaId(null);

      if (plData) {
        setPlId(plData.id);
        setPl({
          interest_on_loans: plData.interest_on_loans.toString(),
          interest_on_bank_ac: plData.interest_on_bank_ac.toString(),
          return_on_investment: plData.return_on_investment.toString(),
          miscellaneous_income: plData.miscellaneous_income.toString(),
          interest_on_deposits: plData.interest_on_deposits.toString(),
          interest_on_borrowings: plData.interest_on_borrowings.toString(),
          establishment_contingencies: plData.establishment_contingencies.toString(),
          provisions: plData.provisions.toString(),
          net_profit: plData.net_profit.toString(),
        });
      } else setPlId(null);

      if (bsData) {
        setBsId(bsData.id);
        setBs({
          share_capital: bsData.share_capital.toString(),
          deposits: bsData.deposits.toString(),
          borrowings: bsData.borrowings.toString(),
          reserves_statutory_free: bsData.reserves_statutory_free.toString(),
          undistributed_profit: bsData.undistributed_profit.toString(),
          provisions: bsData.provisions.toString(),
          other_liabilities: bsData.other_liabilities.toString(),
          cash_in_hand: bsData.cash_in_hand.toString(),
          cash_at_bank: bsData.cash_at_bank.toString(),
          investments: bsData.investments.toString(),
          loans_advances: bsData.loans_advances.toString(),
          fixed_assets: bsData.fixed_assets.toString(),
          other_assets: bsData.other_assets.toString(),
          stock_in_trade: bsData.stock_in_trade.toString(),
        });
      } else setBsId(null);

      if (omData) {
        setOmId(omData.id);
        setStaffCount(omData.staff_count.toString());
      } else {
        setOmId(null);
        setStaffCount("1");
      }
    } catch (e) {
      console.error("Error loading period data:", e);
    } finally {
      setLoadingData(false);
    }
  };

  const update = (set: React.Dispatch<React.SetStateAction<any>>, field: string, value: string) => {
    set((prev: Record<string, string>) => ({ ...prev, [field]: value }));
  };

  const totalLiabilities = () => {
    const v = (k: keyof typeof bs) => parseFloat(bs[k]) || 0;
    return v("share_capital") + v("deposits") + v("borrowings") + v("reserves_statutory_free") + v("undistributed_profit") + v("provisions") + v("other_liabilities");
  };
  const totalAssets = () => {
    const v = (k: keyof typeof bs) => parseFloat(bs[k]) || 0;
    return v("cash_in_hand") + v("cash_at_bank") + v("investments") + v("loans_advances") + v("fixed_assets") + v("other_assets") + v("stock_in_trade");
  };
  const balanceDiff = () => Math.abs(totalLiabilities() - totalAssets());
  // UI-only indicator; do NOT block updates based on this.
  const isBalanced = balanceDiff() < 0.01;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const sc = parseInt(staffCount, 10);
    if (!staffCount || isNaN(sc) || sc < 1) return;

    setLoading(true);
    try {
      if (!isBalanced) {
        toast.warning(
          `Balance Sheet is not balanced (Δ ${balanceDiff().toFixed(2)}). Saving anyway.`
        );
      }
      const taPayload = {
        opening_stock: parseFloat(ta.opening_stock) || 0,
        purchases: parseFloat(ta.purchases) || 0,
        trade_charges: parseFloat(ta.trade_charges) || 0,
        sales: parseFloat(ta.sales) || 0,
        closing_stock: parseFloat(ta.closing_stock) || 0,
      };
      if (taId) await updateTradingAccount(taId, taPayload);
      else await createTradingAccount(periodId, taPayload);

      const plPayload = {
        interest_on_loans: parseFloat(pl.interest_on_loans) || 0,
        interest_on_bank_ac: parseFloat(pl.interest_on_bank_ac) || 0,
        return_on_investment: parseFloat(pl.return_on_investment) || 0,
        miscellaneous_income: parseFloat(pl.miscellaneous_income) || 0,
        interest_on_deposits: parseFloat(pl.interest_on_deposits) || 0,
        interest_on_borrowings: parseFloat(pl.interest_on_borrowings) || 0,
        establishment_contingencies: parseFloat(pl.establishment_contingencies) || 0,
        provisions: parseFloat(pl.provisions) || 0,
        net_profit: parseFloat(pl.net_profit) || 0,
      };
      if (plId) await updateProfitLoss(plId, plPayload);
      else await createProfitLoss(periodId, plPayload);

      const bsPayload = {
        share_capital: parseFloat(bs.share_capital) || 0,
        deposits: parseFloat(bs.deposits) || 0,
        borrowings: parseFloat(bs.borrowings) || 0,
        reserves_statutory_free: parseFloat(bs.reserves_statutory_free) || 0,
        undistributed_profit: parseFloat(bs.undistributed_profit) || 0,
        provisions: parseFloat(bs.provisions) || 0,
        other_liabilities: parseFloat(bs.other_liabilities) || 0,
        cash_in_hand: parseFloat(bs.cash_in_hand) || 0,
        cash_at_bank: parseFloat(bs.cash_at_bank) || 0,
        investments: parseFloat(bs.investments) || 0,
        loans_advances: parseFloat(bs.loans_advances) || 0,
        fixed_assets: parseFloat(bs.fixed_assets) || 0,
        other_assets: parseFloat(bs.other_assets) || 0,
        stock_in_trade: parseFloat(bs.stock_in_trade) || 0,
      };
      if (bsId) await updateBalanceSheet(bsId, bsPayload);
      else await createBalanceSheet(periodId, bsPayload);

      const omPayload = { staff_count: sc };
      if (omId) await updateOperationalMetrics(omId, omPayload);
      else await createOperationalMetrics(periodId, omPayload);

      await calculateRatios(periodId);
      onSuccess?.();
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.message || "Update failed";
      toast.error(msg);
    } finally {
      setLoading(false);
    }
  };

  if (loadingData) {
    return (
      <div className="flex items-center justify-center py-12 text-gray-500 dark:text-gray-400">
        Loading period data…
      </div>
    );
  }

  const Section: React.FC<{
    id: string;
    title: string;
    children: React.ReactNode;
  }> = ({ id, title, children }) => {
    const isOpen = openSection === id;
    return (
      <div className="border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden">
        <button
          type="button"
          onClick={() => setOpenSection(isOpen ? "" : id)}
          className="w-full flex items-center justify-between px-4 py-3 bg-gray-50 dark:bg-gray-800 text-left font-medium text-gray-900 dark:text-white"
        >
          {title}
          {isOpen ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
        </button>
        {isOpen && <div className="p-4 bg-white dark:bg-gray-900">{children}</div>}
      </div>
    );
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <Section id="trading" title="Trading Account">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {(["opening_stock", "purchases", "trade_charges", "sales", "closing_stock"] as const).map((f) => (
            <div key={f}>
              <Label htmlFor={f}>{f.replace(/_/g, " ")}</Label>
              <Input
                id={f}
                type="number"
                step="0.01"
                value={ta[f]}
                onChange={(e) => update(setTa, f, e.target.value)}
                disabled={loading}
              />
            </div>
          ))}
        </div>
      </Section>

      <Section id="profitloss" title="Profit & Loss">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {(
            [
              "interest_on_loans",
              "interest_on_bank_ac",
              "return_on_investment",
              "miscellaneous_income",
              "interest_on_deposits",
              "interest_on_borrowings",
              "establishment_contingencies",
              "provisions",
              "net_profit",
            ] as const
          ).map((f) => (
            <div key={f}>
              <Label htmlFor={f}>{f.replace(/_/g, " ")}</Label>
              <Input
                id={f}
                type="number"
                step="0.01"
                value={pl[f]}
                onChange={(e) => update(setPl, f, e.target.value)}
                disabled={loading}
              />
            </div>
          ))}
        </div>
      </Section>

      <Section id="balancesheet" title="Balance Sheet">
        <div className="space-y-4">
          <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300">Liabilities</h4>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {(
              [
                "share_capital",
                "deposits",
                "borrowings",
                "reserves_statutory_free",
                "undistributed_profit",
                "provisions",
                "other_liabilities",
              ] as const
            ).map((f) => (
              <div key={f}>
                <Label htmlFor={f}>{f.replace(/_/g, " ")}</Label>
                <Input
                  id={f}
                  type="number"
                  step="0.01"
                  value={bs[f]}
                  onChange={(e) => update(setBs, f, e.target.value)}
                  disabled={loading}
                />
              </div>
            ))}
          </div>
          <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 mt-4">Assets</h4>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {(
              [
                "cash_in_hand",
                "cash_at_bank",
                "investments",
                "loans_advances",
                "fixed_assets",
                "other_assets",
                "stock_in_trade",
              ] as const
            ).map((f) => (
              <div key={f}>
                <Label htmlFor={f}>{f.replace(/_/g, " ")}</Label>
                <Input
                  id={f}
                  type="number"
                  step="0.01"
                  value={bs[f]}
                  onChange={(e) => update(setBs, f, e.target.value)}
                  disabled={loading}
                />
              </div>
            ))}
          </div>
          <p className={`text-sm ${isBalanced ? "text-green-600 dark:text-green-400" : "text-red-600 dark:text-red-400"}`}>
            {isBalanced
              ? "Liabilities = Assets"
              : `Assets not equal to Liabilities. Liabilities ${totalLiabilities().toFixed(2)} vs Assets ${totalAssets().toFixed(2)} (Δ ${balanceDiff().toFixed(2)})`}
          </p>
        </div>
      </Section>

      <Section id="operational" title="Operational Metrics">
        <div>
          <Label htmlFor="staff_count">Staff count</Label>
          <Input
            id="staff_count"
            type="number"
            min={1}
            value={staffCount}
            onChange={(e) => setStaffCount(e.target.value)}
            disabled={loading}
          />
        </div>
      </Section>

      <div className="flex justify-end pt-4">
        <button
          type="submit"
          disabled={loading || !staffCount || parseInt(staffCount, 10) < 1}
          className="flex items-center gap-2 px-5 py-2.5 bg-blue-600 hover:bg-blue-700 dark:bg-blue-500 dark:hover:bg-blue-600 text-white rounded-lg font-medium disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
          {loading ? "Updating…" : "Update data & recalculate ratios"}
        </button>
      </div>
    </form>
  );
};

export default PeriodDataEditForm;
