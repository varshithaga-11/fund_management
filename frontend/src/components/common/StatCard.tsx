import { ReactNode } from "react";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  className?: string;
  trend?: {
    value: number;
    direction: "up" | "down" | "neutral";
  };
}

export default function StatCard({ title, value, icon, className, trend }: StatCardProps) {
  const getTrendColor = () => {
    if (!trend) return "";
    switch (trend.direction) {
      case "up":
        return "text-emerald-600 dark:text-emerald-400";
      case "down":
        return "text-red-600 dark:text-red-400";
      default:
        return "text-amber-600 dark:text-amber-400";
    }
  };

  const getTrendIcon = () => {
    if (!trend) return null;
    if (trend.direction === "up") {
      return <span className="text-lg">↑</span>;
    } else if (trend.direction === "down") {
      return <span className="text-lg">↓</span>;
    }
    return <span className="text-lg">→</span>;
  };

  return (
    <div
      className={`group relative overflow-hidden rounded-2xl border border-gray-200 dark:border-gray-700 bg-gradient-to-br from-white to-gray-50 dark:from-gray-900 dark:to-gray-800 p-6 shadow-sm hover:shadow-lg transition-all duration-300 hover:-translate-y-1 ${className}`}
    >
      {/* Decorative background */}
      <div className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
        <div className="absolute -top-40 -right-40 w-80 h-80 rounded-full bg-gradient-to-br from-blue-400/10 to-blue-600/5 dark:from-blue-600/10 dark:to-blue-800/5 blur-3xl" />
      </div>

      <div className="relative z-10 flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-2">
            {title}
          </p>
          <div className="flex items-baseline gap-2">
            <h2 className="text-4xl font-black text-gray-900 dark:text-white">
              {value}
            </h2>
            {trend && (
              <span className={`flex items-center gap-1 text-sm font-bold ${getTrendColor()}`}>
                {getTrendIcon()}
                {Math.abs(trend.value)}%
              </span>
            )}
          </div>
        </div>
        <div className="ml-4 flex-shrink-0 transform group-hover:scale-110 transition-transform duration-300">
          <div className="flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-100 to-blue-50 dark:from-blue-900/40 dark:to-blue-800/40">
            <div className="text-2xl opacity-80 group-hover:opacity-100 transition-opacity">
              {icon}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
