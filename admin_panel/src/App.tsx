import { HashRouter, Routes, Route } from 'react-router-dom';
import { AuthGuard } from './components/AuthGuard';
import { Layout } from './components/Layout';
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { ActiveSemester } from './pages/ActiveSemester';
import { Notifications } from './pages/Notifications';
import { UsersList } from './pages/UsersList';
import { CoursesList } from './pages/CoursesList';
import { Settings } from './pages/Settings';
import { UserDetails } from './pages/UserDetails';
import { AcademicData } from './pages/AcademicData';
import { FileParser } from './pages/FileParser';
import { Feedbacks } from './pages/Feedbacks';

import { CalendarEditor } from './pages/CalendarEditor';
import { DataQuality } from './pages/DataQuality';

function App() {
  return (
    <HashRouter>
      <Routes>
        <Route path='/login' element={<Login />} />

        <Route element={<AuthGuard />}>
          <Route element={<Layout />}>
            <Route path='/' element={<Dashboard />} />
            <Route path='/active-semester' element={<ActiveSemester />} />
            <Route path='/notifications' element={<Notifications />} />
            <Route path='/users' element={<UsersList />} />
            <Route path='/users/:id' element={<UserDetails />} />
            <Route path='/courses' element={<CoursesList />} />
            <Route path='/academic-data' element={<AcademicData />} />
            <Route path='/parser' element={<FileParser />} />

            <Route path='/calendar-editor' element={<CalendarEditor />} />
            <Route path='/settings' element={<Settings />} />
            <Route path='/feedbacks' element={<Feedbacks />} />
            <Route path='/data-quality' element={<DataQuality />} />
          </Route>
        </Route>
      </Routes>
    </HashRouter>
  );
}

export default App;
