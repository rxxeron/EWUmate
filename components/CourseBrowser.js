import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, FlatList, TextInput, TouchableOpacity, ActivityIndicator, Alert, Modal, ScrollView } from 'react-native';
import { db, auth } from '../firebaseConfig';
import { collection, getDocs, doc, updateDoc, arrayUnion, arrayRemove, getDoc } from 'firebase/firestore';
import { Ionicons } from '@expo/vector-icons';
import { GRADE_SCALE } from '../utils/grade-helper';
import { differenceInDays, parseISO, isAfter, isBefore, addDays } from 'date-fns';
import { COURSE_CATALOG } from '../utils/course-catalog';

const SEMESTERS = [
  { label: 'Spring 2026', value: 'Spring2026' },
  { label: 'Fall 2025', value: 'Fall2025' },
  { label: 'Summer 2025', value: 'Summer2025' }
];

const CURRENT_SEMESTER = 'Spring2026';

export default function CourseBrowser({ visible, onClose }) {
  const [selectedSemester, setSelectedSemester] = useState(SEMESTERS[0].value);
  const [courses, setCourses] = useState([]);
  const [filteredCourses, setFilteredCourses] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  
  // User State
  const [enrolledIds, setEnrolledIds] = useState([]);
  const [completedIds, setCompletedIds] = useState([]);
  const [showSemesterPicker, setShowSemesterPicker] = useState(false);

  // Grade Input State
  const [showGradeModal, setShowGradeModal] = useState(false);
  const [selectedCourse, setSelectedCourse] = useState(null);
  const [inputGrade, setInputGrade] = useState('A+');
  const [inputCredits, setInputCredits] = useState('3.0');
  const [gradeSubmissionOpen, setGradeSubmissionOpen] = useState(false);
  const [catalog, setCatalog] = useState(COURSE_CATALOG);

  useEffect(() => {
    if (visible) {
        fetchUserData();
        fetchCourses();
        fetchCatalog(); // Fetch fresh catalog
        if (selectedSemester === CURRENT_SEMESTER) {
            checkSubmissionWindow();
        }
    }
  }, [visible, selectedSemester]);

  const fetchCatalog = async () => {
      try {
          const docRef = doc(db, 'metadata', 'courses');
          const snap = await getDoc(docRef);
          if (snap.exists() && snap.data().catalog) {
              setCatalog(snap.data().catalog);
          }
      } catch (e) {
          // Fallback to imported COURSE_CATALOG
      }
  };

  const checkSubmissionWindow = async () => {
      // Check if current date is within 5 days after last grade submission
      // Fetch 'calendar_Spring2026' -> 'CALENDAR_META' -> 'lastGradeSubmissionDate'
      // For now, defaults to FALSE unless we find the doc.
      try {
          const docRef = doc(db, `calendar_${CURRENT_SEMESTER}`, 'CALENDAR_META');
          const snap = await getDoc(docRef);
          if (snap.exists() && snap.data().lastGradeSubmissionDate) {
              const lastDate = parseISO(snap.data().lastGradeSubmissionDate);
              const now = new Date();
              const diff = differenceInDays(now, lastDate);
              // Open if now > lastDate AND now <= lastDate + 5 days
              if (isAfter(now, lastDate) && diff <= 5) {
                  setGradeSubmissionOpen(true);
                  return;
              }
          }
      } catch(e) { console.log('Error checking grade window', e); }
      setGradeSubmissionOpen(false);
  };

  useEffect(() => {
    filterCourses();
  }, [searchQuery, courses]);

  const fetchUserData = async () => {
    try {
      const user = auth.currentUser;
      if (!user) return;
      const userDoc = await getDoc(doc(db, 'users', user.uid));
      if (userDoc.exists()) {
        const data = userDoc.data();
        setEnrolledIds(data.enrolledSections || []);
        setCompletedIds(data.completedCourses || []);
      }
    } catch (error) {
      console.log("Error fetching user data", error);
    }
  };

  const fetchCourses = async () => {
    setLoading(true);
    try {
      const colRef = collection(db, `courses_${selectedSemester}`);
      const snapshot = await getDocs(colRef);
      const fetched = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setCourses(fetched);
    } catch (error) {
       console.log("Error fetching courses", error);
       setCourses([]);
    } finally {
      setLoading(false);
    }
  };

  const filterCourses = () => {
    if (!searchQuery) {
      setFilteredCourses(courses);
    } else {
      const q = searchQuery.toLowerCase();
      const filtered = courses.filter(c => 
        (c.courseName && c.courseName.toLowerCase().includes(q)) || 
        (c.docId && c.docId.toLowerCase().includes(q)) ||
        (c.faculty && c.faculty.toLowerCase().includes(q))
      );
      setFilteredCourses(filtered);
    }
  };

  const handleToggleStatus = async (courseId, type, courseObj = null) => {
     const user = auth.currentUser;
     if (!user) return;

     const userRef = doc(db, 'users', user.uid);
     const isEnrolled = enrolledIds.includes(courseId);
     const isCompleted = completedIds.includes(courseId);

     try {
         if (type === 'enrolled') {
             if (selectedSemester !== CURRENT_SEMESTER) {
                 Alert.alert("Restriction", "You can only enroll in the current semester.");
                 return;
             }

             if (isEnrolled) {
                 await updateDoc(userRef, { enrolledSections: arrayRemove(courseId) });
                 setEnrolledIds(prev => prev.filter(id => id !== courseId));
             } else {
                 if (enrolledIds.length >= 5) {
                     Alert.alert("Enrollment Limit", "You can only enroll in a maximum of 5 courses per semester.");
                     return;
                 }

                 await updateDoc(userRef, { 
                     enrolledSections: arrayUnion(courseId),
                     completedCourses: arrayRemove(courseId)
                 });
                 setEnrolledIds(prev => [...prev, courseId]);
                 setCompletedIds(prev => prev.filter(id => id !== courseId));
             }
         } else if (type === 'completed') {
             if (isCompleted) {
                 // Remove from completed list AND remove result
                 // Note: Removing from array of objects 'academicResults' via arrayRemove requires Exact Object Match
                 // which is hard. Easier to read, filter, write back.
                 // For now, just removing ID from completedCourses. 
                 // (TODO: Clean up academicResults too).
                 await updateDoc(userRef, { completedCourses: arrayRemove(courseId) });
                 setCompletedIds(prev => prev.filter(id => id !== courseId));
             } else {
                 // Open Grade Modal instead of direct update
                 const target = courseObj || courses.find(c => c.id === courseId);
                 setSelectedCourse(target);
                 setInputGrade('A+');

                 // Lookup credits from Catalog
                 let defaultCredits = '3.0';
                 if (target) {
                     // Try code or extract from docId like Spring2026_CSE101_1 -> CSE101
                     const code = target.code || (target.docId ? target.docId.split('_')[1] : "");
                     const cleanCode = code.replace(/\s+/g, '').toUpperCase(); 
                     const match = catalog.find(c => c.code.replace(/\s+/g, '').toUpperCase() === cleanCode);
                     if (match) defaultCredits = String(match.credits);
                 }

                 setInputCredits(target?.credits || defaultCredits);
                 setShowGradeModal(true);
             }
         }
     } catch (error) {
         Alert.alert("Error", "Could not update course status.");
     }
  };

  const saveGrade = async () => {
      if (!selectedCourse) return;
      try {
          const user = auth.currentUser;
          const userRef = doc(db, 'users', user.uid);
          
          const resultEntry = {
              courseId: selectedCourse.id,
              courseCode: selectedCourse.code || selectedCourse.docId?.split('_')[1] || "UNKNOWN", 
              courseName: selectedCourse.courseName,
              semesterId: selectedSemester,
              credits: inputCredits,
              grade: inputGrade,
              point: GRADE_SCALE[inputGrade] || 0.0,
              timestamp: new Date().toISOString()
          };

          await updateDoc(userRef, { 
              completedCourses: arrayUnion(selectedCourse.id),
              enrolledSections: arrayRemove(selectedCourse.id),
              academicResults: arrayUnion(resultEntry)
          });
          
          setCompletedIds(prev => [...prev, selectedCourse.id]);
          setEnrolledIds(prev => prev.filter(id => id !== selectedCourse.id));
          setShowGradeModal(false);
          Alert.alert("Success", "Grade saved to Academic Record.");

      } catch (e) {
          Alert.alert("Error", "Failed to save grade: " + e.message);
      }
  };

  const renderItem = ({ item }) => {
    const isEnrolled = enrolledIds.includes(item.id);
    const isCompleted = completedIds.includes(item.id);
    const displayCode = item.code || item.docId;

    // Logic for Buttons
    const canEnroll = selectedSemester === CURRENT_SEMESTER;
    const canComplete = selectedSemester !== CURRENT_SEMESTER || gradeSubmissionOpen;

    return (
      <View style={styles.card}>
        <View style={styles.cardInfo}>
          <Text style={styles.courseCode}>{displayCode}</Text>
          <Text style={styles.courseName}>{item.courseName}</Text>
          <Text style={styles.details}>{item.day || "TBA"} {item.startTime}-{item.endTime} | {item.room}</Text>
        </View>
        <View style={styles.actions}>
           {canComplete && (
               <TouchableOpacity 
                style={[styles.actionBtn, isCompleted && styles.completedBtn]}
                onPress={() => handleToggleStatus(item.id, 'completed', item)}
               >
                <Text style={[styles.btnText, isCompleted && styles.activeBtnText]}>
                    {isCompleted ? '✓ Done' : 'Complete'}
                </Text>
               </TouchableOpacity>
           )}
           
           {canEnroll && (
               <TouchableOpacity 
                style={[styles.actionBtn, isEnrolled && styles.enrolledBtn]}
                onPress={() => handleToggleStatus(item.id, 'enrolled', item)}
               >
                <Text style={[styles.btnText, isEnrolled && styles.activeBtnText]}>
                    {isEnrolled ? '✓ Enrolled' : 'Enroll'}
                </Text>
               </TouchableOpacity>
           )}
        </View>
      </View>
    );
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
        <View style={styles.container}>
            <View style={styles.header}>
                <Text style={styles.title}>Browse Courses</Text>
                <TouchableOpacity onPress={onClose} style={styles.closeBtn}>
                     <Ionicons name="close" size={24} color="#333" />
                </TouchableOpacity>
            </View>

            <View style={styles.controls}>
                <TouchableOpacity style={styles.semesterSelector} onPress={() => setShowSemesterPicker(true)}>
                    <Text style={styles.semesterText}>{SEMESTERS.find(s => s.value === selectedSemester)?.label} ▼</Text>
                </TouchableOpacity>
                 <TextInput 
                    style={styles.searchInput}
                    placeholder="Search..."
                    value={searchQuery}
                    onChangeText={setSearchQuery}
                />
            </View>

            {loading ? (
                <ActivityIndicator size="large" color="#4F46E5" style={{marginTop: 50}} />
            ) : (
                <FlatList 
                    data={filteredCourses}
                    keyExtractor={item => item.id}
                    renderItem={renderItem}
                    contentContainerStyle={styles.listContent}
                    ListEmptyComponent={
                        <Text style={styles.emptyText}>No courses found.</Text>
                    }
                />
            )}

            {showGradeModal && (
                <View style={styles.pickerOverlay}>
                    <View style={styles.pickerContent}>
                        <Text style={styles.modalTitle}>Enter Grade</Text>
                        <Text style={styles.modalSubtitle}>{selectedCourse?.courseName}</Text>
                        
                        <View style={styles.inputGroup}>
                            <Text style={styles.label}>Credits:</Text>
                            <TextInput 
                                style={styles.input}
                                value={inputCredits}
                                onChangeText={setInputCredits}
                                keyboardType="numeric"
                            />
                        </View>

                        <View style={styles.inputGroup}>
                            <Text style={styles.label}>Grade:</Text>
                            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.gradeScroll}>
                                {Object.keys(GRADE_SCALE).map(g => (
                                    <TouchableOpacity 
                                        key={g} 
                                        style={[styles.gradeChip, inputGrade === g && styles.activeGradeChip]}
                                        onPress={() => setInputGrade(g)}
                                    >
                                        <Text style={[styles.gradeText, inputGrade === g && styles.activeGradeText]}>{g}</Text>
                                    </TouchableOpacity>
                                ))}
                            </ScrollView>
                        </View>

                        <TouchableOpacity style={styles.saveBtn} onPress={saveGrade}>
                            <Text style={styles.saveText}>Save Result</Text>
                        </TouchableOpacity>
                        
                        <TouchableOpacity style={styles.cancelBtn} onPress={() => setShowGradeModal(false)}>
                            <Text style={styles.cancelText}>Cancel</Text>
                        </TouchableOpacity>
                    </View>
                </View>
            )}

            {showSemesterPicker && (
                 <View style={styles.pickerOverlay}>
                    <View style={styles.pickerContent}>
                        {SEMESTERS.map(sem => (
                            <TouchableOpacity 
                                key={sem.value} 
                                style={styles.pickerItem}
                                onPress={() => {
                                    setSelectedSemester(sem.value);
                                    setShowSemesterPicker(false);
                                }}
                            >
                                <Text style={styles.pickerText}>{sem.label}</Text>
                            </TouchableOpacity>
                        ))} 
                        <TouchableOpacity style={styles.cancelBtn} onPress={() => setShowSemesterPicker(false)}>
                            <Text style={styles.cancelText}>Cancel</Text>
                        </TouchableOpacity>
                    </View>
                 </View>
            )}
        </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F3F4F6',
  },
  header: {
    padding: 16,
    backgroundColor: '#fff',
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  title: {
    fontSize: 20,
    fontWeight: 'bold',
  },
  closeBtn: {
      padding: 4,
  },
  controls: {
      flexDirection: 'row',
      padding: 12,
      gap: 10,
      backgroundColor: '#fff',
  },
  semesterSelector: {
    padding: 12,
    backgroundColor: '#F0F9FF',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#BAE6FD',
    justifyContent: 'center',
  },
  semesterText: {
    color: '#0284C7',
    fontWeight: '600',
  },
  searchInput: {
    flex: 1,
    backgroundColor: '#F3F4F6',
    borderRadius: 8,
    paddingHorizontal: 12,
    fontSize: 16,
  },
  listContent: {
    padding: 16,
  },
  card: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 16,
    marginBottom: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  cardInfo: { flex: 1, marginRight: 10 },
  courseCode: { fontSize: 14, color: '#666', fontWeight: '600' },
  courseName: { fontSize: 16, fontWeight: 'bold', color: '#333' },
  details: { fontSize: 12, color: '#999' },
  actions: { gap: 8 },
  actionBtn: {
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#eee',
    alignItems: 'center',
    minWidth: 80,
  },
  completedBtn: { backgroundColor: '#D1FAE5', borderColor: '#10B981' },
  enrolledBtn: { backgroundColor: '#DBEAFE', borderColor: '#3B82F6' },
  btnText: { fontSize: 12, color: '#666' },
  activeBtnText: { color: '#000', fontWeight: 'bold' },
  emptyText: { textAlign: 'center', marginTop: 30, color: '#999' },
  pickerOverlay: {
      position: 'absolute', top: 0, bottom: 0, left: 0, right: 0,
      backgroundColor: 'rgba(0,0,0,0.5)',
      justifyContent: 'center', alignItems: 'center'
  },
  pickerContent: {
      backgroundColor: '#fff', borderRadius: 12, width: '80%', padding: 20
  },
  pickerItem: { paddingVertical: 15, borderBottomWidth: 1, borderBottomColor: '#eee' },
  pickerText: { textAlign: 'center', fontSize: 16 },
  cancelBtn: { marginTop: 10, padding: 10 },
  cancelText: { textAlign: 'center', color: 'red' },
  modalTitle: { fontSize: 18, fontWeight: 'bold', marginBottom: 4, textAlign: 'center' },
  modalSubtitle: { fontSize: 14, color: '#666', marginBottom: 16, textAlign: 'center' },
  inputGroup: { marginBottom: 16 },
  label: { fontSize: 14, fontWeight: '600', marginBottom: 6 },
  input: { borderWidth: 1, borderColor: '#ddd', borderRadius: 8, padding: 10, fontSize: 16 },
  gradeScroll: { flexDirection: 'row' },
  gradeChip: { 
      paddingHorizontal: 16, paddingVertical: 8, borderRadius: 20, 
      backgroundColor: '#f3f4f6', marginRight: 8, borderWidth: 1, borderColor: '#e5e7eb' 
  },
  activeGradeChip: { backgroundColor: '#4F46E5', borderColor: '#4338ca' },
  gradeText: { fontWeight: '600', color: '#4b5563' },
  activeGradeText: { color: '#fff' },
  saveBtn: { backgroundColor: '#4F46E5', padding: 14, borderRadius: 8, marginTop: 8 },
  saveText: { color: '#fff', textAlign: 'center', fontWeight: 'bold', fontSize: 16 },
});

