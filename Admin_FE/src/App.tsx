import { lazy, Suspense, useEffect, useState } from 'react';
import { BrowserRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { AdminLayout } from './components/AdminLayout';
import { getCurrentUser, restoreSession } from './lib/api';

const Login = lazy(() => import('./pages/Login'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Incidents = lazy(() => import('./pages/Incidents'));
const IncidentDetail = lazy(() => import('./pages/IncidentDetail'));
const Assignments = lazy(() => import('./pages/Assignments'));
const Users = lazy(() => import('./pages/Users'));
const ChatAssistant = lazy(() => import('./pages/ChatAssistant'));
const Catalog = lazy(() => import('./pages/Catalog'));
const Departments = lazy(() => import('./pages/Departments'));
const Areas = lazy(() => import('./pages/Areas'));
const SystemConfig = lazy(() => import('./pages/SystemConfig'));
const ChangePassword = lazy(() => import('./pages/ChangePassword'));
const ManualReview = lazy(() => import('./pages/ManualReview'));
const NotificationCenter = lazy(() => import('./pages/NotificationCenter'));
const AiPerformance = lazy(() => import('./pages/AiPerformance'));
const EmergencyGuides = lazy(() => import('./pages/EmergencyGuides'));
const EmergencyContacts = lazy(() => import('./pages/EmergencyContacts'));
const CitizenFeedbacks = lazy(() => import('./pages/CitizenFeedbacks'));
const InterestedAreas = lazy(() => import('./pages/InterestedAreas'));
const FloodMonitoring = lazy(() => import('./pages/FloodMonitoring'));
const OfficerPerformance = lazy(() => import('./pages/OfficerPerformance'));
const OfficerOperations = lazy(() => import('./pages/OfficerOperations'));

function LoadingScreen() {
  return <main className="loading-screen"><span className="spinner"/><p>Đang tải dữ liệu…</p></main>;
}

function Protected() {
  const [state, setState] = useState<'loading'|'ok'|'no'>('loading');
  const location = useLocation();
  useEffect(() => { void restoreSession().then(ok => setState(ok ? 'ok' : 'no')); }, []);
  if (state === 'loading') return <LoadingScreen/>;
  if (state === 'no') return <Navigate to="/login" replace/>;
  if (getCurrentUser()?.must_change_password && location.pathname !== '/change-password') return <Navigate to="/change-password" replace/>;
  return <AdminLayout/>;
}

export default function App() {
  return <BrowserRouter><Suspense fallback={<LoadingScreen/>}><Routes>
    <Route path="/login" element={<Login/>}/>
    <Route element={<Protected/>}>
      <Route index element={<Dashboard/>}/>
      <Route path="change-password" element={<ChangePassword/>}/>
      <Route path="incidents" element={<Incidents/>}/>
      <Route path="flood-points" element={<FloodMonitoring/>}/>
      <Route path="manual-review" element={<ManualReview/>}/>
      <Route path="incidents/:id" element={<IncidentDetail/>}/>
      <Route path="assignments" element={<Assignments/>}/>
      <Route path="ai-performance" element={<AiPerformance/>}/>
      <Route path="notification-center" element={<NotificationCenter/>}/>
      <Route path="users" element={<Users/>}/>
      <Route path="chat-assistant" element={<ChatAssistant/>}/>
      <Route path="officer-performance" element={<OfficerPerformance/>}/>
      <Route path="officer-operations" element={<OfficerOperations/>}/>
      <Route path="catalog" element={<Catalog/>}/>
      <Route path="departments" element={<Departments/>}/>
      <Route path="areas" element={<Areas/>}/>
      <Route path="interested-areas" element={<InterestedAreas/>}/>
      <Route path="system" element={<SystemConfig/>}/>
      <Route path="emergency-guides" element={<EmergencyGuides/>}/>
      <Route path="emergency-contacts" element={<EmergencyContacts/>}/>
      <Route path="citizen-feedbacks" element={<CitizenFeedbacks/>}/>
    </Route>
    <Route path="*" element={<Navigate to="/" replace/>}/>
  </Routes></Suspense></BrowserRouter>;
}
