import { BrowserRouter as Router } from "react-router-dom";
import { ScrollToTop } from "./components/common/ScrollToTop";
import { appRoutes } from "./appRoutes";
// import { NotificationProvider } from "./context/NotificationContext";
import { LanguageProvider } from "./components/Context/LanguageContext";

export default function App() {
  return (
    <LanguageProvider>
      {/* <NotificationProvider> */}
        <Router>
          <ScrollToTop />
          {appRoutes()}
        </Router>
      {/* </NotificationProvider> */}
    </LanguageProvider>
  );
}
