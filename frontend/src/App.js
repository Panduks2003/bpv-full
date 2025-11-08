import React from "react";
import { BrowserRouter as Router } from "react-router-dom";
import { AuthProvider, ScalabilityProvider, ConditionalNavbar, Footer, ScrollToTop, UnifiedToastProvider } from "./common";
import AppRoutes from "./routes";
import "./assets/App.css";


function App() {
  return (
    <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <ScalabilityProvider>
        <AuthProvider>
          <UnifiedToastProvider>
            <div className="min-h-screen bg-gray-50">
              <ScrollToTop />
              <ConditionalNavbar />
              <AppRoutes />
              <Footer />
            </div>
          </UnifiedToastProvider>
        </AuthProvider>
      </ScalabilityProvider>
    </Router>
  );
}

export default App;
