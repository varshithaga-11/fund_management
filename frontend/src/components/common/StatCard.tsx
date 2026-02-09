import { ReactNode } from "react";

interface StatCardProps {
  title: string;
  value: string | number;
  icon: ReactNode;
  className?: string;
}

export default function StatCard({ title, value, icon, className }: StatCardProps) {
  return (
    <div
      className={`shadow-md rounded-2xl border bg-white dark:bg-gray-900 p-6 flex items-center justify-between hover:shadow-lg transition ${className}`}
    >
      <div className="flex flex-col">
        <p className="text-base font-semibold text-gray-800 dark:text-gray-200">
          {title}
        </p>
        <h2 className="text-3xl font-bold mt-1 text-gray-900 dark:text-white">
          {value}
        </h2>
      </div>
      <div className="ml-4 flex-shrink-0">{icon}</div>
    </div>
  );
}
