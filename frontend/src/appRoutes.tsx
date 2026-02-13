// gkghb

import { Route, Routes } from "react-router-dom";
import { lazy, Suspense } from "react";
const SignIn = lazy(() => import("./pages/AuthPages/SignIn"));
const SignUp = lazy(() => import("./pages/AuthPages/SignUp"));
const MasterDashboard = lazy(() => import("./pages/Dashboard/index"));
// const AdminPage = lazy(() => import("./pages/Master/Adminpage"));
// const CompanyList = lazy(() => import("./pages/Master/Companypage"));
const NotFound = lazy(() => import("./pages/OtherPage/NotFound"));
const UserProfiles = lazy(() => import("./pages/UserProfiles"));
const Videos = lazy(() => import("./pages/UiElements/Videos"));
const Images = lazy(() => import("./pages/UiElements/Images"));
const Alerts = lazy(() => import("./pages/UiElements/Alerts"));
const Badges = lazy(() => import("./pages/UiElements/Badges"));
const Avatars = lazy(() => import("./pages/UiElements/Avatars"));
const Buttons = lazy(() => import("./pages/UiElements/Buttons"));
const LineChart = lazy(() => import("./pages/Charts/LineChart"));
const BarChart = lazy(() => import("./pages/Charts/BarChart"));
const Calendar = lazy(() => import("./pages/Calendar"));
const MasterLayout = lazy(() => import("./layout/MasterLayout/MasterLayout"));
const Blank = lazy(() => import("./pages/Blank"));

import CompanyPage from "./pages/Companies/Company";
const FinancialPeriodPage = lazy(() => import("./pages/FinancialStatements/FinancialPeriodPage"));
const UploadDataPage = lazy(() => import("./pages/FinancialStatements/UploadDataPage"));
const StatementColumnsConfigPage = lazy(
  () => import("./pages/FinancialStatements/StatementColumnsConfigPage")
);
const RatioDashboard = lazy(() => import("./pages/RatioAnalysis/RatioDashboard"));
const ProductivityAnalysis = lazy(() => import("./pages/RatioAnalysis/ProductivityAnalysis"));
const InterpretationPanel = lazy(() => import("./pages/RatioAnalysis/InterpretationPanel"));
const RatioBenchmarksPage = lazy(() => import("./pages/RatioAnalysis/RatioBenchmarksPage"));
const CompanyRatioAnalysis = lazy(() => import("./pages/CompanyRatioAnalysis"));
const PeriodComparison = lazy(() => import("./pages/PeriodComparison"));


import UserManagementPage from "./pages/UserManagement";

const LoadingSpinner = () => (
  <div className="flex items-center justify-center min-h-screen">
    <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
  </div>
);

// interface RoutesComponentProps {
//     hasPreloaderShown: boolean;
// }

// export function appRoutes({ hasPreloaderShown }: RoutesComponentProps) {

export function appRoutes() {
  return (

    <Suspense fallback={<LoadingSpinner />}>

      <Routes>
        {/* Dashboard Layout */}
        <Route element={<MasterLayout />}>

          <Route path="master/master-dashboard" element={<MasterDashboard />} />

          <Route path="companies" element={<CompanyPage />} />

          {/* Financial Statements */}
          <Route path="upload-data" element={<UploadDataPage />} />
          <Route path="financial-statements/:periodId" element={<FinancialPeriodPage />} />
          <Route path="statement-columns" element={<StatementColumnsConfigPage />} />

          {/* Ratio Analysis */}
          <Route path="ratio-benchmarks" element={<RatioBenchmarksPage />} />
          <Route path="ratio-analysis/:periodId" element={<RatioDashboard />} />
          <Route path="productivity-analysis/:periodId" element={<ProductivityAnalysis />} />
          <Route path="interpretation/:periodId" element={<InterpretationPanel />} />
          <Route path="company-ratio-analysis" element={<CompanyRatioAnalysis />} />
          <Route path="period-comparison" element={<PeriodComparison />} />
          <Route path="user-management" element={<UserManagementPage />} />

          {/* Others Page */}
          <Route path="/profile" element={<UserProfiles />} />
          <Route path="/calendar" element={<Calendar />} />
          <Route path="/blank" element={<Blank />} />

          {/* Forms */}
          {/* <Route path="/form-elements" element={<FormElements />} /> */}

          {/* Tables */}
          {/* <Route path="/basic-tables" element={<BasicTables />} /> */}

          {/* Ui Elements */}
          <Route path="/alerts" element={<Alerts />} />
          <Route path="/avatars" element={<Avatars />} />
          <Route path="/badge" element={<Badges />} />
          <Route path="/buttons" element={<Buttons />} />
          <Route path="/images" element={<Images />} />
          <Route path="/videos" element={<Videos />} />

          {/* Charts */}
          <Route path="/line-chart" element={<LineChart />} />
          <Route path="/bar-chart" element={<BarChart />} />
        </Route>


        {/* Admin Management */}
        {/* Create Admin */}

        {/* Tables */}

        {/* Admin Management */}
        {/* Create Admin */}

        {/* Tables */}
        {/* <Route path="basic-tables" element={<BasicTables />} /> */}

        {/* Ui Elements */}
        <Route path="alerts" element={<Alerts />} />
        <Route path="avatars" element={<Avatars />} />
        <Route path="badge" element={<Badges />} />
        <Route path="buttons" element={<Buttons />} />
        <Route path="images" element={<Images />} />
        <Route path="videos" element={<Videos />} />

        {/* Charts */}
        <Route path="/line-chart" element={<LineChart />} />
        <Route path="/bar-chart" element={<BarChart />} />

        {/* Auth Routes */}
        <Route path="/" element={<SignIn />} />
        <Route path="/signup" element={<SignUp />} />

        {/* Fallback Route */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Suspense>

  );
}
